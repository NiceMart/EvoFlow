#!/usr/bin/env bash
# info-record.sh — info-record 工具 wrapper（子命令分发）
# 让 agent 用 `info-record.sh <子命令> [参数...]` 调用，零子脚本路径拼接。
# 每个子命令 exec 转发到 scripts/ 下对应脚本，不改语义。
# 子脚本的库路径来自 EVOFLOW_MEDIA_WS（未设置时子脚本 fail-fast）。
set -euo pipefail
SELF="${BASH_SOURCE[0]}"
# 只解析软链一层，定位真实脚本目录（不 readlink -f 继续展开）。
if [ -L "$SELF" ]; then
  _target="$(readlink "$SELF")"
  case "$_target" in
    /*) SELF="$_target" ;;
    *)  SELF="$(cd "$(dirname "$SELF")" && pwd)/$_target" ;;
  esac
fi
SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"

cmd="${1:-}"
if [ $# -gt 0 ]; then shift; fi

case "$cmd" in
  init-db)          exec bash "$SCRIPT_DIR/scripts/init-db.sh" "$@" ;;
  check-content)    exec bash "$SCRIPT_DIR/scripts/check-content.sh" "$@" ;;
  record-content)   exec bash "$SCRIPT_DIR/scripts/record-content.sh" "$@" ;;
  query-today)      exec bash "$SCRIPT_DIR/scripts/query-today.sh" "$@" ;;
  *)
    cat >&2 <<'USAGE'
用法: info-record <子命令> [参数...]

子命令:
  init-db            初始化 db/info_record.db（幂等）
  check-content      内容去重检查（--source）
  record-content     记录采集内容（--source --source-type --title --author --publish-date --content）
  query-today        查询今日采集的全部记录（JSON 数组）
USAGE
    exit 1
    ;;
esac
