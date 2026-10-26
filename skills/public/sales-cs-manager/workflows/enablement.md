# Sales-CS 启用（Enablement）

> ⚠️ 本 workflow 源自 xiaobei 的独立对外 crew 启用流程（渠道选择 -> 派工配置 -> workspace 文档完善 -> 业务知识软链）。EvoFlow 单 agent 架构下不适用——客户资料库与业务知识已按 EVOFLOW_MEDIA_WS 约定共享，无需 crew 化；渠道绑定当前经 `.env.xiaobei-keys` 的 `AWADA_*` 配置 + relay 完成。**仅保留 Step 1 的渠道状态只读检查**，其余步骤仅存档参考，勿执行。

**依赖**：`sales-cs-enablement`（渠道只读检查）。

---

## Step 1 · 检查 awada 渠道是否已配置（保留可用）

```bash
sales-cs-enablement check-channel
```

退出码：`0` -> 已配置 awada 渠道；`1` / `2` -> 未配置或配置文件不存在。

> ⚠️ 渠道绑定当前经 `.env.xiaobei-keys` 的 `AWADA_*` 配置 + relay，awada 渠道未配置时本检查不可用（配置文件不存在，退出码 `2`）。此时不要进入后续启用步骤，向用户说明需先配置 `AWADA_*`。

---

## 以下步骤已失效（存档参考，勿执行）

- **渠道选项讲解与用户选择**：EvoFlow 渠道经 `.env.xiaobei-keys` + relay 配置，无需本流程讲解选项。
- **派工完成启用与基础配置**（spawn IT engineer 合入 `openclaw.json`、重启 Gateway）：EvoFlow 单 agent 架构下无派工与 Gateway 重启概念，不适用。
- **完善 workspace 文档**（填写称呼、话术、角色边界占位）：无独立 crew workspace，不适用；客服话术与手册直接维护在 `$EVOFLOW_MEDIA_WS/` 业务知识文档中（见 Review workflow）。
- **软链 business_knowledge.md + business_knowledge/**：单 agent 下无需软链，脚本保留仅作参考，勿执行。

## 错误处理（仅 Step 1 适用）

| 情况 | 处理 |
|------|------|
| `check-channel` 退出码 `2`（配置文件不存在） | 向用户说明 awada 渠道未配置，需先在 `.env.xiaobei-keys` 配置 `AWADA_*`；不进入任何后续步骤 |
| `check-channel` 退出码 `1`（未配置或解析失败） | 输出 JSON 给用户核对；不修改任何配置文件 |
