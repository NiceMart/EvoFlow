#!/bin/bash
# Send awada invite control message via relay outbound, then update customer
# status to exp_invited in $EVOFLOW_MEDIA_WS/db/customer.db.
# --peer: DB primary key (asked from the user in conversation, see customer-db skill),
#         used for all DB operations.
# --user-id-external: raw awada user ID (from message context or user),
#         used for the invite routing message.
# --force: force invite even if business_status is not 'free' (for re-invite requests).
# Config (env; xiaobei 原读渠道配置文件的等价迁移):
#   EVOFLOW_MEDIA_WS  客户库根（$EVOFLOW_MEDIA_WS/db/customer.db），未设置 fail-fast
#   AWADA_KEY         relay 出站凭据（X-Awada-Key header），未设置 fail-fast
#   AWADA_LANE        relay lane 参数（可选，未设置沿用服务器默认 lane）
#   RELAY_BASE_URL    relay 网关基址（可选，缺省 https://relay.openclaw-for-business.com）
set -euo pipefail

if [ -z "${EVOFLOW_MEDIA_WS:-}" ]; then
  echo "ERROR: EVOFLOW_MEDIA_WS is not set (e.g. export EVOFLOW_MEDIA_WS=E:/xiaobei-data/workspace-main)" >&2
  exit 1
fi
DB_FILE="$EVOFLOW_MEDIA_WS/db/customer.db"

RELAY_BASE_URL="${RELAY_BASE_URL:-https://relay.openclaw-for-business.com}"

PEER=""
USER_ID_EXTERNAL=""
GROUP_NAME="风暴眼（wiseflow情报小站）"
FORCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --peer)
      PEER="${2:-}"
      shift 2
      ;;
    --user-id-external)
      USER_ID_EXTERNAL="${2:-}"
      shift 2
      ;;
    --group-name)
      GROUP_NAME="${2:-}"
      shift 2
      ;;
    --force)
      FORCE="1"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$PEER" ]; then
  echo "❌ --peer is required (ask the user in conversation; see customer-db skill)" >&2
  exit 1
fi

if [ -z "$USER_ID_EXTERNAL" ]; then
  echo "❌ --user-id-external is required (from message context or user)" >&2
  exit 1
fi

if [ -z "${AWADA_KEY:-}" ]; then
  echo "ERROR: AWADA_KEY is not set (awada relay credential, X-Awada-Key header; write it into .env.xiaobei-keys and restart start-dev)" >&2
  exit 1
fi

if [ ! -f "$DB_FILE" ]; then
  echo "❌ Database not found: $DB_FILE (initialize: sqlite3 \"\$EVOFLOW_MEDIA_WS/db/customer.db\" < skills/public/customer-db/db/schema.sql)" >&2
  exit 1
fi

sql_quote() {
  printf '%s' "$1" | sed "s/'/''/g"
}

existing_status="$(sqlite3 "$DB_FILE" "SELECT business_status FROM cs_record WHERE peer = '$(sql_quote "$PEER")'" || true)"

if [ -z "$existing_status" ]; then
  sqlite3 "$DB_FILE" "INSERT INTO cs_record (peer, business_status, purpose, prompt_source) VALUES ('$(sql_quote "$PEER")', 'free', '', '')"
  existing_status="free"
fi

# Block auto-invite for non-free users, unless --force is specified
if [ "$existing_status" != "free" ] && [ -z "$FORCE" ]; then
  echo "ALREADY_INVITED"
  exit 10
fi

# Send invite control message via relay outbound.
# xiaobei 原形是把控制消息 printf 到 stdout、由 awada-channel 钩子转成拉群动作；
# EvoFlow 无渠道钩子，改为直接 POST relay outbound（同 proactive-send 的 transport）。
# 写库（标 exp_invited）放在 POST 成功之后：POST 失败时库保持原状态，重试不误判 ALREADY_INVITED。
json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

INVITE_TEXT="$(printf '/invite//%s//%s' "$USER_ID_EXTERNAL" "$GROUP_NAME")"
LANE_PARAM=""
if [ -n "${AWADA_LANE:-}" ]; then
  LANE_PARAM="?lane=$(printf '%s' "$AWADA_LANE" | sed 's/ /%20/g')"
fi
URL="${RELAY_BASE_URL%/}/api/v1/awada/outbound${LANE_PARAM}"
BODY="{\"payload\":[{\"type\":\"text\",\"text\":\"$(json_escape "$INVITE_TEXT")\"}],\"meta\":{\"channel_id\":\"0\",\"user_id_external\":\"$(json_escape "$USER_ID_EXTERNAL")\",\"tenant_id\":\"0\"}}"

RESP="$(curl -sS -w '\n%{http_code}' -X POST "$URL" \
  -H "X-Awada-Key: $AWADA_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY")"
HTTP_CODE="$(printf '%s' "$RESP" | tail -n 1)"
RESP_BODY="$(printf '%s' "$RESP" | sed '$d')"

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
  echo "❌ outbound POST failed: HTTP $HTTP_CODE: $RESP_BODY" >&2
  exit 1
fi

# Only update business_status to exp_invited if current status is free or empty
# For exp_invited/subs/club users with --force, don't change business_status
if [ "$existing_status" = "free" ] || [ -z "$existing_status" ]; then
  sqlite3 "$DB_FILE" "UPDATE cs_record SET business_status = 'exp_invited' WHERE peer = '$(sql_quote "$PEER")'"
fi

STREAM_ID="$(printf '%s' "$RESP_BODY" | sed -n 's/.*"streamId"[: ]*"\([^"]*\)".*/\1/p')"
if [ -n "$STREAM_ID" ]; then
  echo "$STREAM_ID"
else
  echo "$RESP_BODY"
fi
