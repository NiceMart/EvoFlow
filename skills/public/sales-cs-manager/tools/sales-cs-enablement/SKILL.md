---
name: sales-cs-enablement
description: >
  sales-cs 启用的机械操作工具：awada 渠道配置只读检查（check-channel）。
  业务知识软链（link）在 EvoFlow 单 agent 架构下不适用，脚本保留仅作参考。
  完整说明见 sales-cs-manager 包内 Enablement workflow。
---

# sales-cs-enablement 工具说明书

> ⚠️ EvoFlow 单 agent 架构下仅 `check-channel` 的只读检查可用；`link`（业务知识软链）不适用——业务知识已按 EVOFLOW_MEDIA_WS 约定共享，无需软链，脚本保留仅作参考，勿执行。

## 命令

```bash
sales-cs-enablement check-channel
sales-cs-enablement link        # EvoFlow 下勿执行（见上方标注）
```

## check-channel

检查 `~/.openclaw/openclaw.json` 的 `channels.awada` 是否已配置（段存在且非空即视为已配置）。

> ⚠️ 渠道绑定当前经 `.env.xiaobei-keys` 的 `AWADA_*` 配置 + relay，awada 渠道未配置时本检查不可用（配置文件不存在，退出码 `2`）。

- 输出：JSON 状态到 stdout（`configured` / `awada` / `path`）
- 退出码：`0` 已配置；`1` 未配置或解析失败；`2` 配置文件不存在
- 环境变量 `OPENCLAW_JSON` 可覆盖配置文件路径

## link（EvoFlow 下勿执行）

把 main agent workspace 的 `business_knowledge.md`（单文件正文）和 `business_knowledge/`（支撑材料文件夹）软链到 sales-cs workspace 同名位置。以下为源行为存档：

- 源解析：优先 `~/.openclaw/workspace-main/`；`.md` 不存在时从仓库模板 `crews/main/business_knowledge.md` 复制一份到 main workspace；文件夹不存在时在仓库创建空目录
- 目标：`~/.openclaw/workspace-sales-cs/` 下的同名条目
- 目标已存在且是软链 -> 覆盖重建；已存在且是真实文件/目录 -> **报错拒绝覆盖**（退出码 1），防误删数据，需人工确认后处理
- 退出码：`0` 成功；`1` 目标为非软链或其他错误
- 环境变量 `MAIN_WORKSPACE` / `SALES_CS_WORKSPACE` / `REPO_MAIN` 可覆盖三个路径

## 注意事项

- wrapper 是子命令分发器：`check-channel` 转发诊断脚本 `check_awada_channel.py`，`link` 转发主入口 `symlink_business_knowledge.py`。agent 一律走 PATH 调用，不要拼脚本路径。
- `check-channel` 只读：不创建、不修改、不删除任何文件。
