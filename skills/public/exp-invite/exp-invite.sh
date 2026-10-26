#!/usr/bin/env bash
# exp-invite — 体验群邀请 wrapper
# 让 agent 用 `exp-invite <cmd>` 走 PATH，零路径拼接。
# 转发到 scripts/invite.sh（真业务脚本）。
set -euo pipefail
SELF="${BASH_SOURCE[0]}"
# 只解析 ~/.evoflow/bin 软链一层（bin/<skill> -> <workspace>/skills/<skill>/<skill>.sh），
# 不 readlink -f 继续展开 workspace 内 skills/<skill> 指向仓库模板的软链。
# invite.sh 不再推导 workspace 根（库路径走 $EVOFLOW_MEDIA_WS 约定），无路径折叠问题；
# 保留一层软链解析使 SCRIPT_DIR 命中真实技能目录。
if [ -L "$SELF" ]; then
  _target="$(readlink "$SELF")"
  case "$_target" in
    /*) SELF="$_target" ;;
    *)  SELF="$(cd "$(dirname "$SELF")" && pwd)/$_target" ;;
  esac
fi
SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"
exec "$SCRIPT_DIR/scripts/invite.sh" "$@"
