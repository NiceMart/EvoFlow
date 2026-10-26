#!/usr/bin/env bash
# rss-reader.sh — rss-reader 顶层 wrapper（薄转发）
# 让 agent 用 `rss-reader.sh <feed_url>` 调用，零内部脚本路径拼接。
# 内部转发到 scripts/fetch-rss.mjs；wrapper 自身只是 exec 转发，不改语义。
set -euo pipefail
SELF="${BASH_SOURCE[0]}"
# 解析软链定位真实脚本目录。
while [ -L "$SELF" ]; do SELF="$(readlink -f "$SELF")"; done
SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"
exec node "$SCRIPT_DIR/scripts/fetch-rss.mjs" "$@"
