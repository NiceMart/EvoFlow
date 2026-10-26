---
name: sales-cs-manager
description: 对外销售客服管理专家。承接客服复盘升级（客户反馈扫描、话术/客服手册调整建议与落地）与启用前检查（awada 渠道状态只读检查）。EvoFlow 单 agent 架构下无独立对外 crew，业务知识与客户资料库已按 EVOFLOW_MEDIA_WS 约定共享，无需 crew 化。不涉及商务获客（走 expert-bd）、投资人关系（走 expert-ir）、开源情报（走 expert-osbi）。
---

# sales-cs 管理（sales-cs-manager）

## 环境前置（EvoFlow）

- `EVOFLOW_MEDIA_WS`：须先 export（如 `E:/xiaobei-data/workspace-main`）。`sales-cs-review` 未检测到该环境变量时 fail-fast 报错退出。
- feedback 目录：客户反馈历史位于 `$EVOFLOW_MEDIA_WS/feedback/`（`.md` 文件）。目录不存在时工具输出 `total: 0` 与说明（只读扫描，不建目录）。
- Python 3：`python3` 可用且 `PYTHONUTF8=1`。

## 预设 Workflow

| 场景 | Workflow | 什么时候触发 |
|------|----------|-------------|
| sales-cs 复盘与升级 | [Review](workflows/review.md) | 用户想复盘客服反馈 / 调整客服话术 / 改客服手册；或定期检查客户反馈 |
| sales-cs 启用 | [Enablement](workflows/enablement.md) | 仅渠道状态只读检查可用；其余启用步骤在 EvoFlow 单 agent 架构下不适用 |

> ⚠️ 本技能源自 xiaobei 的 sales-cs 独立 crew 管理。EvoFlow 单 agent 架构下不适用——客户资料库与业务知识已按 EVOFLOW_MEDIA_WS 约定共享，无需 crew 化。Review workflow（反馈扫描 + 升级建议）保留可用；Enablement workflow 仅保留渠道只读检查，其余步骤已标注失效。

## 资源命名约定

- Tools、Workflows 等名称是 `sales-cs-manager` 技能包内的逻辑资源名，不是 Agent Workspace 路径，也不要拼成相对路径执行。
- 只有工具清单中明确列出的 wrapper 名称可以直接作为 shell 命令调用；其余 Tool 名称仅用于定位对应说明。

零散操作（只想查下渠道状态、只想扫下反馈）直接用下面的工具。

## 工具清单

| 工具 | 用途 | 命令 |
|------|------|------|
| `sales-cs-review` | 扫描 `$EVOFLOW_MEDIA_WS/feedback/` 的客户反馈，输出结构化摘要 | `sales-cs-review [--since YYYY-MM-DD]` |
| `sales-cs-enablement` | awada 渠道配置只读检查 | `sales-cs-enablement check-channel` |

> ⚠️ `sales-cs-enablement link`（业务知识软链）在 EvoFlow 单 agent 架构下不适用——业务知识已按 EVOFLOW_MEDIA_WS 约定共享，无需软链。脚本保留仅作参考，勿执行。

配置类操作（渠道绑定、`AWADA_*` 密钥配置）在 EvoFlow 经 `.env.xiaobei-keys` 的 `AWADA_*` 配置 + relay 完成，无需派工执行。

## 核心治理边界

- **业务知识单点维护**：`business_knowledge.md` + `business_knowledge/` 在 `$EVOFLOW_MEDIA_WS/` 维护，客服话术与手册的调整都改这里，不另建副本。
- **反馈只读**：`$EVOFLOW_MEDIA_WS/feedback/` 是客户反馈历史，只用于复盘，不修改、不删除。
- **调整先确认**：对外话术影响真实客户对话，任何调整先呈现建议给用户确认，再落地。

## 边界

- 商业情报 / 市场研究 -> `expert-osbi`；潜客探索筛选 / 评论区互动 / 客户联络 -> `expert-bd`。
- 投资人发掘 / 融资跟进 -> `expert-ir`。
- 客户资料（业务状态、联系方式）读写 -> `customer-db`（`$EVOFLOW_MEDIA_WS/db/customer.db`）。
