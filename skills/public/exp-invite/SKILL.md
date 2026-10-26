---
name: exp-invite
description: >
  Invite a qualified customer into the experience group when they want to
  understand the product form further after seeing demo materials. The invite
  control message is sent through the awada relay, and the customer status is
  updated to exp_invited (in $EVOFLOW_MEDIA_WS/db/customer.db) to prevent
  duplicate invitations.
---

# exp-invite

> 技能目前为示例。启用前需根据实际业务调整。

## 环境前置（EvoFlow）

- `EVOFLOW_MEDIA_WS`：客户库位于 `$EVOFLOW_MEDIA_WS/db/customer.db`（由 customer-db 技能建档维护）；未设置时脚本报错退出（fail-fast），须先 `export EVOFLOW_MEDIA_WS`（如 `E:/xiaobei-data/workspace-main`）
- `AWADA_KEY`：awada relay 出站凭据（`X-Awada-Key` header）；未设置时脚本报错退出（fail-fast）。EvoFlow 下凭据写入 `.env.xiaobei-keys` 后重启 start-dev 生效
- `AWADA_LANE`（可选）：relay lane 参数；未设置时沿用服务器默认 lane
- `RELAY_BASE_URL`（可选）：relay 网关基址，缺省 `https://relay.openclaw-for-business.com`
- `sqlite3` 与 `curl`：需在 PATH 中

## 客户标识提取规则
此处需要同时传入两个标识符，各自职责不同（两个标识符均由对话取得，见 customer-db 技能「两个重要标识符」段）：

```bash
skills/public/exp-invite/scripts/invite.sh \
  --peer "<peer>" \
  --user-id-external "<user_id_external>"
```

- `--peer`：数据库主键，用于 DB 查询和写库。**由 agent 在对话中向用户询问并确认取得**（xiaobei 的 `[CustomerDB].peer` 渠道自动注入钩子在 EvoFlow 不存在）：首次为某客户建档前先向用户确认该客户的标识，之后同一客户始终沿用同一 `peer`
- `--user-id-external`：渠道用户外部 ID，用于 awada 平台路由邀请动作。**从消息上下文取（若渠道提供了外部用户 ID），或由用户自报**（xiaobei 的 Sender 块自动注入在 EvoFlow 不存在）

## 行为规则

### 主动邀请限制
对于 `business_status` 不为 `free` 的用户（如 `exp_invited`、`subs`、`club`）：
- **不要主动邀请**他们进入体验群
- 应回到主流程 3.7，继续主动引导

### 允许再次邀请的情况
如果客户**明确要求**再次拉入群或再次 invite，可以使用 `--force` 参数强制发送邀请：
- 客户可能忘记接受之前的邀请
- 客户可能主动退出后想重新加入

```bash
skills/public/exp-invite/scripts/invite.sh \
  --peer "<peer>" \
  --user-id-external "<user_id_external>" \
  --force
```

### business_status 更新规则
- 若 `business_status` 为空或 `free`：更新为 `exp_invited`
- 若已有值（`exp_invited`/`subs`/`club`）且使用 `--force`：**不更新** business_status，仅发送邀请

### 邀请消息格式
邀请消息是 awada 控制消息，不是自然语言：

```text
/invite//<user_external_id>//风暴眼（wiseflow情报小站）
```

脚本把该控制消息作为文本 payload 经 relay 网关 `POST /api/v1/awada/outbound?lane=`（`X-Awada-Key` header）发送，由 relay 侧 awada 通道转为拉群动作。

## 返回约定
- 成功：打印 relay outbound stream ID（如 `1234-0`），exit 0
- 已邀请过且未指定 `--force`：输出 `ALREADY_INVITED`，并以非 0 状态退出（exit 10）
- 路径/凭据缺失：ERROR 提示缺什么、写哪里（`.env.xiaobei-keys`），exit 1
- relay 请求失败：错误描述打印到 stderr，库状态保持不变（不标 `exp_invited`），exit 1

## 当前体验群名称
- `风暴眼（wiseflow情报小站）`
