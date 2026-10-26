---
name: demo-send
description: >
  Guide demo material preparation and delivery wording for a free-status
  customer when they ask about concrete usage, want to understand the product
  form, or need a first visual reference before deeper sales qualification.
  EvoFlow currently has no attachment-send tool — the actual file delivery is
  done manually by the user.
---

# demo-send

> 技能目前为示例。启用前需根据实际业务调整。

## 环境前置（EvoFlow）

**能力门控**：EvoFlow 当前无附件发送工具（xiaobei 的 `message sendAttachment` 等价物），本技能当前仅指导物料准备与发送话术；附件实际发送由用户手动完成。下文保留 xiaobei 原工具调用示例作参考——**当前不要调用**，改为把文件名告知用户、请其手动接收/自取。

## 用途
当客户属于 `free` 状态，且提出具体使用问题、想先看看产品形态、或需要一个直观参考时，发送 demo 材料。

## 调用方式（xiaobei 原形，当前不可用）

xiaobei 使用 `message` 工具发送预存在微信网盘中的 demo 文件：

```
message(action="sendAttachment", file_name="<文件名>")
```

> **错误示例**（禁止使用）：
> ```
> message(action="sendAttachment", filename="...", filePath="...")
> ```
> 参数名必须是 `file_name`（带下划线），不得传 `filePath` 或 `filename`。`file_name` 对应微信网盘中已存的文件名，不是本地路径。

**可用文件**：
- `wiseflow5x.mp4` — 小贝（xiaobei）系统演示视频

**示例**：
```
message(action="sendAttachment", file_name="wiseflow5x.mp4")
```

## 完整发送流程（EvoFlow 当前形态）

1. 向客户说明即将提供演示视频 `wiseflow5x.mp4`，请客户留意接收（**附件实际发送由用户手动完成**，本 turn 不做任何附件发送工具调用）
2. 同一 turn 统一输出完整回复：说明已安排发送 demo + 追问客户的具体需求或应用场景 + 提醒官网/GitHub 主页获取最新信息

> **重要**：不要拆成多条内容相近的消息（包括"我先给您发一份..."之类的开场单独成条），话术一次性输出。

## 发送后必须做的事
demo 交付（用户手动发送）后，**必须立刻追问客户的具体需求或应用场景**，不得只发完就结束。
