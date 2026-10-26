#!/usr/bin/env node
/**
 * send.mjs — Proactive awada message sender (HTTP gateway transport)
 *
 * Usage:
 *   node scripts/send.mjs \
 *     --user-id-external "黄子奇ᐪᒻ" \
 *     --text "您好，昨天咱们聊过专业版的事，不知道今天方便看看吗？"
 *
 * 走 relay 网关 POST /api/v1/awada/outbound?lane=<lane>（契约见 docs/AWADA-CLIENT-TRANSPORT.md §3）。
 * 配置从环境变量读取（xiaobei 原读渠道配置文件的等价迁移）：
 *   AWADA_KEY        relay 出站凭据（X-Awada-Key header），未设置时 fail-fast exit 1
 *   AWADA_LANE       relay lane 参数（可选，未设置沿用服务器默认 lane）
 *   RELAY_BASE_URL   relay 网关基址（可选，缺省 https://relay.openclaw-for-business.com）
 * EvoFlow 下凭据写入 .env.xiaobei-keys 后重启 start-dev 生效。
 * channel_id 和 tenant_id 固定为 "0"（私聊）。platform 由 relay 按 lane 绑定推导，客户端不发。
 * 成功：打印 streamId（exit 0）；失败：打印错误到 stderr（exit 1）。
 */

const DEFAULT_RELAY_BASE_URL = "https://relay.openclaw-for-business.com";

// ── Arg parsing ──────────────────────────────────────────────────────────────

function getArg(name) {
  const idx = process.argv.indexOf(name);
  if (idx === -1 || idx >= process.argv.length - 1) return null;
  return process.argv[idx + 1];
}

const userIdExternal = getArg("--user-id-external");
const text = getArg("--text");

if (!userIdExternal || !text) {
  console.error("Usage: node send.mjs --user-id-external <id> --text <message>");
  process.exit(1);
}

// ── Load awada relay config from env ─────────────────────────────────────────

const awadaKey = process.env.AWADA_KEY || "";
const lane = process.env.AWADA_LANE || "";
const relayBaseUrl = process.env.RELAY_BASE_URL || DEFAULT_RELAY_BASE_URL;

if (!awadaKey) {
  console.error(
    "❌ AWADA_KEY is not set — awada relay credential (X-Awada-Key header). " +
      "Write it into .env.xiaobei-keys (e.g. AWADA_KEY=...) and restart start-dev."
  );
  process.exit(1);
}

// ── POST /outbound ───────────────────────────────────────────────────────────
// platform 由 relay 按 lane 绑定推导，客户端不发；channel_id / user_id_external 必填。
// AWADA_LANE 未设置时不带 lane 参数，沿用服务器默认 lane。

const laneParam = lane ? `?lane=${encodeURIComponent(lane)}` : "";
const url = `${relayBaseUrl.replace(/\/+$/, "")}/api/v1/awada/outbound${laneParam}`;
const body = {
  payload: [{ type: "text", text }],
  meta: {
    channel_id: "0",
    user_id_external: userIdExternal,
    tenant_id: "0",
  },
};

try {
  const res = await fetch(url, {
    method: "POST",
    headers: { "X-Awada-Key": awadaKey, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    let detail = `${res.status} ${res.statusText}`;
    try {
      const errBody = await res.json();
      if (errBody?.error?.code || errBody?.error?.message) {
        detail = `${res.status}: ${errBody.error.code ?? ""} ${errBody.error.message ?? ""}`.trim();
      }
    } catch {
      // non-json error body
    }
    console.error(`❌ outbound POST failed: ${detail}`);
    process.exit(1);
  }
  const json = await res.json();
  const streamId = json?.data?.streamId ?? "";
  console.log(streamId);
} catch (err) {
  console.error(`❌ outbound POST error: ${err.message}`);
  process.exit(1);
}
