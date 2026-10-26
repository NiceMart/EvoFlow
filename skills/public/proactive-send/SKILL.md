---
name: proactive-send
description: >
  向 awada 客户主动发送消息。在正常对话流程之外直接 POST 到 relay 网关 outbound 端点，无需等待客户发起对话。
---

# 主动发送（proactive-send）

本技能让 sales-cs 在特定业务场景下主动向客户发送消息，而非等待客户发起对话。

---

## 环境前置（EvoFlow）

- `AWADA_KEY`：awada relay 出站凭据（`X-Awada-Key` header）；未设置时脚本报错退出（fail-fast，exit 1）。EvoFlow 下凭据写入 `.env.xiaobei-keys` 后重启 start-dev 生效
- `AWADA_LANE`（可选）：relay lane 参数；未设置时沿用服务器默认 lane
- `RELAY_BASE_URL`（可选）：relay 网关基址，缺省 `https://relay.openclaw-for-business.com`

## 使用方法

```bash
proactive-send \
  --user-id-external "<user_id_external>" \
  --text "<消息内容>"
```

### 参数说明

| 参数 | 必填 | 说明 |
|------|------|------|
| `--user-id-external` | 是 | 客户的 awada 用户标识（渠道用户外部 ID）：从消息上下文取（若渠道提供了外部用户 ID），或由用户自报 |
| `--text` | 是 | 发送给客户的消息文本 |

`AWADA_KEY` / `AWADA_LANE` / `RELAY_BASE_URL` 从环境变量读取。`channel_id` / `tenant_id` 固定为 `"0"`（私聊）。`platform` 不配——relay 按 lane 绑定推导。

### 返回值

- 成功：打印 relay outbound stream ID（如 `1234-0`），exit 0
- 失败：打印错误描述到 stderr，exit 1（含 `AWADA_KEY` 未配置的 fail-fast）

---

## 注意事项

- 本技能仅提供消息发送能力，**何时使用、发给谁、发什么内容**由调用场景决定
- 请勿在正常对话流程中调用——会破坏对话自然性
- 消息内容应简短、自然、克制
- 走 relay 网关 HTTP 传输：`POST {RELAY_BASE_URL%/}/api/v1/awada/outbound?lane=<lane>`，header 带 `X-Awada-Key: $AWADA_KEY` 与 `Content-Type: application/json`，body 为 `{"payload":[{"type":"text","text":"<消息>"}],"meta":{"channel_id":"0","user_id_external":"<用户>","tenant_id":"0"}}`，不直连 Redis
