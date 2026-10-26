# xiaobei 技能移植 EvoFlow — 批次 3（商业闭环）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 移植最后一批技能（expert-bd/osbi/ir、sales-cs 五件套）并把「每日复盘」落为 EvoFlow 定时任务，完成整个移植工程。

**Architecture:** 沿批次 0-2 模式（拷贝 + 清洗配方 + 环境变量适配）。批次 3 特有：三个 record 库（bd/info/ir）从「上 5 级工作区推导」改为 `$EVOFLOW_MEDIA_WS/db/` fail-fast 约定；sales-cs 四件套从独立 crew 降为单 agent 技能（peer 标识改用户供给、DECLARED_SKILLS 沙箱降为文档、awada 配置从 openclaw.json 迁 env）；每日复盘用 EvoFlow automation API 落地。

**Tech Stack:** Bash（Git Bash）、Python 3、Node.js（rss-reader）、sqlite3（.tools/）、EvoFlow automation API。

**Spec:** `docs/superpowers/specs/2026-10-26-xiaobei-skills-port-design.md`（§3 映射 #10/#12/#15、§4 批次表、§4.1/4.2 先例记录）

**调查报告:** `E:/EvoFlow/.superpowers/sdd/batch3-survey.md`（本计划的依赖事实来源；执行期被删则从 git 外的会话记录重建）

## Global Constraints

沿批次 0-2 全部约束（分支 feat/port-xiaobei-skills、清洗配方、commit 规范 + Co-Authored-By、同步 `cp -r <src>/ /c/Users/yebin/.evoflow/skills/public/`、零成本冒烟、计划外编辑申报制），批次 3 特有：

- **record 库路径约定**：bd_record/info_record/ir_record 三库统一定位 `$EVOFLOW_MEDIA_WS/db/<name>.db`——脚本内「上 5 级 WORKSPACE_DIR」推导改为 `${EVOFLOW_MEDIA_WS:?ERROR: EVOFLOW_MEDIA_WS is not set}` fail-fast（bash）或 `os.environ["EVOFLOW_MEDIA_WS"]`（py，缺省 raise SystemExit），与 9fb44a92/1cfcc6f5 已审模式一致；**不新建目录式回落**
- **customer-db 特例**：`./db/customer.db`（cwd 相对）→ `$EVOFLOW_MEDIA_WS/db/customer.db`；schema.sql（源 crews/sales-cs/db/schema.sql）随技能入库
- **peer 标识改写**：customer-db/exp-invite 的 `[CustomerDB] peer`/`Sender.id` openclaw 钩子假设 → 改写为「peer 由用户提供（对话中询问），user_id_external 取渠道用户标识或用户自报」——写入 SKILL.md 环境前置与相关步骤
- **awada 配置迁移**：proactive-send/exp-invite 的 openclaw.json channels.awada 读取 → env：`AWADA_KEY`、`AWADA_LANE`、`RELAY_BASE_URL`（沿用批次约定名）；`.env.xiaobei-keys` 待补清单追加这三个
- **demo-send 门控**：openclaw `message` sendAttachment 工具 EvoFlow 无等价——SKILL.md 环境前置声明「附件发送能力当前不可用，本技能仅指导物料准备与话术」，正文流程保留
- **DECLARED_SKILLS/DENIED_SKILLS/ALLOWED_COMMANDS**：安全沙箱机制无单 agent 等价——机制段落删除，安全姿态一句话保留
- **scheduling.md 改写**（osbi/ir）：IT-engineer crew + HEARTBEAT/MEMORY 注册 → 「用 EvoFlow 网页端『定时任务』页（或 POST /api/automation/tasks）建每日任务，prompt 引用本技能」
- **sales-cs-manager 范围收缩**：sales-cs-review 保留（feedback/ 重指 `$EVOFLOW_MEDIA_WS/feedback/`）；sales-cs-enablement 的渠道检查与 workspace 软链在单 agent 下失效——SKILL.md 显式标注失效部分并给替代指引（business_knowledge 已在 $EVOFLOW_MEDIA_WS 共享，无需软链）
- relay/`~/.openclaw` 会话路径按批次 2 同约定保留；business_knowledge 引用按标准改写；冒烟零成本

---

### Task 1: expert-bd

**Files:**
- Create: `skills/public/expert-bd/`（~81KB, 29 files，自 `/e/xiaobei-app/crews/main/skills/expert-bd`）
- Modify: SKILL.md + workflows/*.md + tools/*/SKILL.md（清洗配方）；bd-record 库路径脚本（计划外编辑申报）

**Interfaces:**
- Consumes: platform-runtime `cli.mjs`（6 个薄壳 wrapper，`../../../platform-runtime` 同批 2 expert 三胞胎层级）、`_shared/douyin_live_cli.py|xhs_live_cli.py`（--access write）、relay 信封（douyin-im im_wire.py:52、douyin-interact web.request）、`~/.openclaw/douyin-im`/`douyin-api` 会话（共享约定）
- Produces: 商务拓展专家（潜客探索/互动/直播互动 + bd_record 客户探索记录库 `$EVOFLOW_MEDIA_WS/db/bd_record.db`）

- [ ] **Step 1: 拷贝 + 清洗**

```bash
cp -r /e/xiaobei-app/crews/main/skills/expert-bd E:/EvoFlow/skills/public/expert-bd
```

SKILL.md、workflows/*.md、11 个 tools/*/SKILL.md 按清洗配方处理；环境前置：relay 行（douyin-im/interact 依赖）+ camoufox/会话行（`~/.openclaw/douyin-im`、`~/.openclaw/douyin-api/session.json`，共享）+ platform-runtime 行 + bd-record 库行（`$EVOFLOW_MEDIA_WS/db/bd_record.db`）。

- [ ] **Step 2: bd-record 库路径适配（计划外编辑，逐处申报）**

定位 WORKSPACE_DIR 推导（survey 指出 tools/bd-record/scripts/record-creator.sh:8 的 5 级向上）：

```bash
grep -rn '\.\./\.\./\.\./\.\./\.\.\|WORKSPACE_DIR' E:/EvoFlow/skills/public/expert-bd/tools/bd-record/ | head -10
```

把每个「上 5 级 + /db」推导改为 `${EVOFLOW_MEDIA_WS:?ERROR: EVOFLOW_MEDIA_WS is not set}/db`（bash）或 py 的 `os.environ["EVOFLOW_MEDIA_WS"]` + SystemExit，保持其余逻辑不动；沿用 9fb44a92 的 ERROR 文案形态。

- [ ] **Step 3: 语法与链路核验 + 冒烟**

```bash
PYTHONUTF8=1 python3 -m py_compile $(find E:/EvoFlow/skills/public/expert-bd -name "*.py") && echo PY-OK
bash -n E:/EvoFlow/skills/public/expert-bd/tools/*/[a-z]*.sh 2>/dev/null || true
ls E:/EvoFlow/skills/public/platform-runtime/scripts/cli.mjs E:/EvoFlow/skills/public/_shared/douyin_live_cli.py E:/EvoFlow/skills/public/_shared/xhs_live_cli.py
bash E:/EvoFlow/skills/public/expert-bd/tools/bd-record/bd-record.sh --help 2>&1 | head -5
```

Expected: PY-OK；三依赖存在；bd-record usage 或缺 env 的明确 ERROR（fail-fast 生效即过）。

- [ ] **Step 4: 残留检查 + 同步 + Commit**

```bash
grep -rn "DECLARED_SKILLS\|metadata:" E:/EvoFlow/skills/public/expert-bd --include="*.md" | head -5
grep -rn "openclaw\|crew" E:/EvoFlow/skills/public/expert-bd --include="*.md" | head -8
```

人工核对第二条的每个命中：relay 域名与 `~/.openclaw` 会话路径为声明保留项，其余 openclaw/crew 措辞必须已在清洗中清除——有漏网就回 Step 1 补清洗再继续。

```bash
cp -r E:/EvoFlow/skills/public/expert-bd/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-bd
git commit -m "feat(skills): 移植 expert-bd（批次3，bd_record 库入 EVOFLOW_MEDIA_WS 约定）"
```

（commit 附 `Co-Authored-By: Claude <noreply@anthropic.com>`，下同）

---

### Task 2: expert-osbi

**Files:**
- Create: `skills/public/expert-osbi/`（源 ~10 files + rss-reader；自 `/e/xiaobei-app/crews/main/skills/expert-osbi`）
- Modify: SKILL.md + workflows/*.md（清洗）；scheduling.md（EvoFlow 定时任务改写）；rss-reader 依赖重建

**Interfaces:**
- Consumes: 无 relay/camoufox/platform-runtime 依赖（纯 HTTP + node）
- Produces: 开源情报专家（info_record 库 `$EVOFLOW_MEDIA_WS/db/info_record.db` + RSS 订阅阅读）

- [ ] **Step 1: 拷贝（rss-reader 排除 vendored node_modules）+ 清洗**

```bash
cp -r /e/xiaobei-app/crews/main/skills/expert-osbi E:/EvoFlow/skills/public/expert-osbi
find E:/EvoFlow/skills/public/expert-osbi -type d -name node_modules -exec rm -rf {} + 
ls /e/xiaobei-app/crews/main/skills/expert-osbi/tools/rss-reader/ 2>/dev/null || find /e/xiaobei-app/crews/main/skills/expert-osbi -name "fetch-rss.mjs" -o -name "package.json" | head -5
```

清洗按配方；**scheduling.md 改写**为：删除 IT-engineer/HEARTBEAT/MEMORY 注册段，替换为「每日情报任务用 EvoFlow 网页端『定时任务』页创建（或 `POST /api/automation/tasks`，cron 如 `0 8 * * *`），prompt 引用本技能的情报收集流程」；环境前置：node 行 + info-record 库行。

- [ ] **Step 2: rss-reader 依赖重建**

```bash
RD=$(find E:/EvoFlow/skills/public/expert-osbi -type d -name "rss-reader" | head -1); echo "$RD"
ls "$RD"
```

若含 package.json + package-lock.json：`cd "$RD" && npm ci 2>&1 | tail -2`，并核 `git check-ignore "$RD/node_modules"`（未忽略则本任务补 `.gitignore` 行并申报）。
若无 package.json（纯 vendored）：把 vendored node_modules 原样拷回（磁盘保留、git 忽略），在 SKILL.md 环境前置注明「rss-reader 依赖为 vendored，随安装包分发；本机重建需手工 npm install rss-parser xml2js」——并在报告申报该决定。

```bash
node "$RD/scripts/fetch-rss.mjs" --help 2>&1 | head -5 || node "$RD/fetch-rss.mjs" --help 2>&1 | head -5
```

Expected: usage 或无订阅配置的明确提示（零成本）。

- [ ] **Step 3: info-record 库路径适配 + 残留检查 + 同步 + Commit**

```bash
grep -rn '\.\./\.\./\.\./\.\./\.\.\|WORKSPACE_DIR' E:/EvoFlow/skills/public/expert-osbi/ | head -6
# 同 Task 1 Step 2 模式适配为 $EVOFLOW_MEDIA_WS/db
grep -rn "DECLARED_SKILLS\|metadata:\|HEARTBEAT" E:/EvoFlow/skills/public/expert-osbi --include="*.md" | head -5
cp -r E:/EvoFlow/skills/public/expert-osbi/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-osbi
git commit -m "feat(skills): 移植 expert-osbi（批次3，info_record 库 + scheduling 改 EvoFlow 定时任务）"
```

---

### Task 3: expert-ir

**Files:**
- Create: `skills/public/expert-ir/`（~56KB, 22 files，自 `/e/xiaobei-app/crews/main/skills/expert-ir`）
- Modify: SKILL.md + workflows/*.md（清洗；business_knowledge ×2；scheduling.md 改写）

**Interfaces:**
- Consumes: `$EVOFLOW_MEDIA_WS/business_knowledge.md`（SKILL.md:56、investor-pipeline.md:47）、council 交叉引用（批次 1 已移植，保留）
- Produces: 投资人关系专家（ir_record 库 `$EVOFLOW_MEDIA_WS/db/ir_record.db` + 融资流水线）

- [ ] **Step 1: 拷贝 + 清洗 + scheduling 改写**

```bash
cp -r /e/xiaobei-app/crews/main/skills/expert-ir E:/EvoFlow/skills/public/expert-ir
```

清洗按配方；business_knowledge 两处按标准改写；council 交叉引用原样保留；scheduling.md 同 Task 2 改写（EvoFlow 定时任务页）；环境前置：ir-record 库行。

- [ ] **Step 2: ir-record 库路径适配 + 核验 + 残留 + 同步 + Commit**

```bash
grep -rn '\.\./\.\./\.\./\.\./\.\.\|WORKSPACE_DIR' E:/EvoFlow/skills/public/expert-ir/ | head -6
# 同 Task 1 Step 2 模式适配
PYTHONUTF8=1 python3 -m py_compile $(find E:/EvoFlow/skills/public/expert-ir -name "*.py") && echo PY-OK
grep -rn "DECLARED_SKILLS\|metadata:\|HEARTBEAT" E:/EvoFlow/skills/public/expert-ir --include="*.md" | head -5
cp -r E:/EvoFlow/skills/public/expert-ir/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-ir
git commit -m "feat(skills): 移植 expert-ir（批次3，ir_record 库 + scheduling 改 EvoFlow 定时任务）"
```

---

### Task 4: customer-db（peer 标识改写 + 库路径钉死）

**Files:**
- Create: `skills/public/customer-db/`（12KB, 8 files + schema.sql，自 `/e/xiaobei-app/crews/sales-cs/skills/customer-db`；schema 自 `/e/xiaobei-app/crews/sales-cs/db/schema.sql`）
- Modify: SKILL.md + 7 个 follow-up 脚本（库路径 + peer 改写）

**Interfaces:**
- Consumes: sqlite3（.tools/）；`$EVOFLOW_MEDIA_WS/db/customer.db`
- Produces: 客户资料库（cs_record 表 PK peer；business_status free/exp_invited/club/subs）；exp-invite（Task 5）写它的 business_status

- [ ] **Step 1: 拷贝 + schema 入库 + 清洗**

```bash
cp -r /e/xiaobei-app/crews/sales-cs/skills/customer-db E:/EvoFlow/skills/public/customer-db
mkdir -p E:/EvoFlow/skills/public/customer-db/db
cp /e/xiaobei-app/crews/sales-cs/db/schema.sql E:/EvoFlow/skills/public/customer-db/db/schema.sql
```

SKILL.md 清洗按配方 + **两类改写**：
1. 库路径：`./db/customer.db`（cwd 相对）→ `$EVOFLOW_MEDIA_WS/db/customer.db`；7 个 follow-up 脚本内的 `./db/` 引用逐处改为 `${EVOFLOW_MEDIA_WS:?...}/db/customer.db`（bash fail-fast 形态），逐处申报 file:line
2. peer 标识：SKILL.md「两个重要标识符」段改写为——「`peer`：客户标识，由 agent 在对话中向用户询问确认（xiaobei 的渠道自动注入钩子在 EvoFlow 不存在）；`user_id_external`：渠道用户外部 ID，从消息上下文取或用户自报」。初始化步骤改为用入库的 schema.sql：`sqlite3 "$EVOFLOW_MEDIA_WS/db/customer.db" < skills/public/customer-db/db/schema.sql`（幂等说明保留）
3. DECLARED_SKILLS/DENIED_SKILLS 机制段删除，安全姿态一句话保留

- [ ] **Step 2: 冒烟（真实建库到 $EVOFLOW_MEDIA_WS）**

```bash
export EVOFLOW_MEDIA_WS="E:/xiaobei-data/workspace-main"
export PATH="/e/EvoFlow/.tools/sqlite3:$PATH"
mkdir -p "$EVOFLOW_MEDIA_WS/db"
sqlite3 "$EVOFLOW_MEDIA_WS/db/customer.db" < E:/EvoFlow/skills/public/customer-db/db/schema.sql && echo SCHEMA-OK
sqlite3 "$EVOFLOW_MEDIA_WS/db/customer.db" ".tables"
```

Expected: `SCHEMA-OK`；列出 cs_record 等表。

- [ ] **Step 3: 残留检查 + 同步 + Commit**

```bash
grep -rn "DECLARED_SKILLS\|DENIED_SKILLS\|metadata:" E:/EvoFlow/skills/public/customer-db --include="*.md" | head -5
grep -rn '\./db/' E:/EvoFlow/skills/public/customer-db/ | head -5   # 应 0 命中（已全部改写）
cp -r E:/EvoFlow/skills/public/customer-db/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/customer-db
git commit -m "feat(skills): 移植 customer-db（批次3，库钉 EVOFLOW_MEDIA_WS 约定 + peer 用户供给 + schema 入库）"
```

---

### Task 5: demo-send + exp-invite + proactive-send

**Files:**
- Create: `skills/public/demo-send/`（1 file）、`skills/public/exp-invite/`（5KB）、`skills/public/proactive-send/`（6KB）（自 `/e/xiaobei-app/crews/sales-cs/skills/` 同名目录）
- Modify: 三份 SKILL.md（清洗 + 门控/env 迁移）；exp-invite 的 invite.sh、proactive-send 的 send.mjs（计划外编辑申报）

**Interfaces:**
- Consumes: customer-db（Task 4，`$EVOFLOW_MEDIA_WS/db/customer.db` 写 business_status）；relay awada 出站通道
- Produces: 演示物料发送（门控）、体验邀请（写库 + relay）、主动触达（relay）；新增 env 约定 `AWADA_KEY`/`AWADA_LANE`

- [ ] **Step 1: 拷贝 + 清洗 + 门控/env 迁移**

```bash
for s in demo-send exp-invite proactive-send; do
  cp -r "/e/xiaobei-app/crews/sales-cs/skills/$s" "E:/EvoFlow/skills/public/$s"
done
```

清洗按配方。**三种差异化处理**：
1. **demo-send**：环境前置声明「EvoFlow 当前无附件发送工具（xiaobei 的 message sendAttachment 等价物），本技能当前仅指导物料准备与发送话术；附件实际发送由用户手动完成」；正文 wiseflow5x.mp4 流程保留
2. **exp-invite**：invite.sh 的 relay/awada 配置读法改 env——`AWADA_KEY`（X-Awada-Key）、`AWADA_LANE`（lane 参数，缺省沿用源默认值）、`RELAY_BASE_URL`（缺省 relay.openclaw-for-business.com）；缺 `AWADA_KEY` 时 fail-fast ERROR（同 9fb44a92 文案形态）；写 customer-db 的路径确认与 Task 4 一致；SKILL.md「两个重要标识符」段按 Task 4 同款 peer 改写
3. **proactive-send**：send.mjs 读 `~/.openclaw/openclaw.json channels.awada` 的段改为读 env `AWADA_KEY`/`AWADA_LANE`/`RELAY_BASE_URL`（缺 AWADA_KEY exit 1 + 指引写 .env.xiaobei-keys）；channel_id/tenant_id 固定值保留；SKILL.md 配置段同步改写

- [ ] **Step 2: 语法 + 零成本冒烟**

```bash
bash -n E:/EvoFlow/skills/public/exp-invite/invite.sh && node --check E:/EvoFlow/skills/public/proactive-send/send.mjs && echo SYNTAX-OK
bash E:/EvoFlow/skills/public/exp-invite/invite.sh 2>&1 | head -3        # 缺参/缺 env 的明确 ERROR
node E:/EvoFlow/skills/public/proactive-send/send.mjs 2>&1 | head -3     # 缺 AWADA_KEY 的明确 exit 1
```

Expected: SYNTAX-OK；两个 fail-fast 报错均清晰指向缺什么、写哪里。**禁止真实发送**。

- [ ] **Step 3: 残留检查 + 同步 + Commit**

```bash
grep -rn "DECLARED_SKILLS\|DENIED_SKILLS\|metadata:\|openclaw.json" E:/EvoFlow/skills/public/{demo-send,exp-invite,proactive-send} | head -8
cp -r E:/EvoFlow/skills/public/{demo-send,exp-invite,proactive-send}/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/demo-send skills/public/exp-invite skills/public/proactive-send
git commit -m "feat(skills): 移植 sales-cs 三件（批次3，demo-send 门控 + awada 配置迁移 env）"
```

---

### Task 6: sales-cs-manager（范围收缩）

**Files:**
- Create: `skills/public/sales-cs-manager/`（~25KB, 11 files，自 `/e/xiaobei-app/crews/main/skills/sales-cs-manager`）
- Modify: SKILL.md + workflows/review.md（清洗 + 失效部分标注）；scan_feedback.py 路径重指（计划外编辑申报）

**Interfaces:**
- Consumes: `$EVOFLOW_MEDIA_WS/feedback/`（review 输入目录）；expert-bd/expert-ir 交叉引用（批次 3 已移植，保留）
- Produces: 对外客服管理（review 评审循环可用；enablement 大部分失效并显式标注）

- [ ] **Step 1: 拷贝 + 清洗 + 失效标注**

```bash
cp -r /e/xiaobei-app/crews/main/skills/sales-cs-manager E:/EvoFlow/skills/public/sales-cs-manager
```

清洗按配方 + **范围收缩改写**（SKILL.md 顶部与相关 workflow 段）：
- 「spawn IT engineer」「编辑 DECLARED_SKILLS/SOUL.md/IDENTITY.md」「openclaw.json 渠道绑定」「workspace 软链」等段落整段删除或标注「（EvoFlow 单 agent 架构下不适用——客户资料库与业务知识已按 EVOFLOW_MEDIA_WS 约定共享，无需 crew 化）」
- sales-cs-review 保留：scan_feedback.py 的 feedback 目录改为 `$EVOFLOW_MEDIA_WS/feedback/`（env fail-fast），逐处申报
- sales-cs-enablement 保留 check_awada_channel 的只读检查能力但标注「渠道绑定当前经 .env.xiaobei-keys 的 AWADA_* 配置 + relay，awada 渠道未配置时本检查不可用」；symlink_business_knowledge.py 标注「单 agent 下无需软链，脚本保留仅作参考，勿执行」
- 环境前置：feedback 目录行 + EVOFLOW_MEDIA_WS 行

- [ ] **Step 2: 核验 + 残留 + 同步 + Commit**

```bash
PYTHONUTF8=1 python3 -m py_compile $(find E:/EvoFlow/skills/public/sales-cs-manager -name "*.py") && echo PY-OK
grep -rn "DECLARED_SKILLS\|SOUL.md\|IDENTITY.md" E:/EvoFlow/skills/public/sales-cs-manager --include="*.md" | head -5
cp -r E:/EvoFlow/skills/public/sales-cs-manager/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/sales-cs-manager
git commit -m "feat(skills): 移植 sales-cs-manager（批次3，review 重指 EVOFLOW_MEDIA_WS，enablement 失效部分标注）"
```

---

### Task 7: 每日复盘定时任务落地

**Files:**
- Create: `docs/superpowers/specs/` 内不新增——本任务产出为运行实例里的 automation 任务 + spec §4.3 记录
- Modify: spec 文档（记录任务 ID 与 cron）

**Interfaces:**
- Consumes: 已移植的 published-track/content-calibrator；运行中网关 `POST /api/automation/tasks`（automation_scheduler.py:341）
- Produces: 每日 `0 9 * * *` 复盘任务（存 `~/.evoflow/tasks/automations/` TOML，用户可在网页「定时任务」页调整）

- [ ] **Step 1: 创建 automation 任务**

```bash
curl -s -X POST http://localhost:8012/api/automation/tasks -H "Content-Type: application/json" -d '{
  "name": "每日内容复盘",
  "prompt": "执行每日内容复盘：1) 运行 published-track 的指标刷新与查询（published-track 技能，库在 $EVOFLOW_MEDIA_WS/db/published_track.db）；2) 用 content-calibrator 技能对近期发布内容做 DNA 表现评估；3) 输出结构化复盘报告（表现摘要/异常项/明日建议），若数据不足则输出数据不足说明与补数建议。",
  "schedule_type": "recurring",
  "cron_expr": "0 9 * * *",
  "max_duration_minutes": 30
}' | head -c 600
```

若 API 要求 `workspace`/`agent_code` 等必填字段，先用 `curl -s http://localhost:8012/api/automation/tasks -X POST -d '{}' -H "Content-Type: application/json"` 看校验报错补齐（只读探测用 OPTIONS/GET 列表接口亦可：`curl -s http://localhost:8012/api/automation/tasks | head -c 400`）。Expected: 返回含 task_id 的 JSON。

- [ ] **Step 2: 验证任务登记**

```bash
curl -s http://localhost:8012/api/automation/tasks | python -c "import json,sys; d=json.load(sys.stdin); print(json.dumps([t for t in (d if isinstance(d,list) else d.get('tasks',d.get('items',[]))) if '复盘' in str(t.get('name',''))], ensure_ascii=False)[:400])"
ls /c/Users/yebin/.evoflow/tasks/automations/ 2>/dev/null | head -3
```

Expected: 列表含「每日内容复盘」+ TOML 文件出现。**不手动触发执行**（首次执行留给用户在定时任务页点「运行」观察，避免消耗会话）。

- [ ] **Step 3: spec 记录 + Commit**

spec §4 批次 3 行状态更新 + 新增 §4.3：automation 任务 ID/cron/落地方式/用户调整入口（定时任务页）。提交：

```bash
git add docs/superpowers/specs/2026-10-26-xiaobei-skills-port-design.md
git commit -m "docs(spec): 批次3 移植完成记录 + 每日复盘任务落地"
```

---

### Task 8: 批次 3 验收门

**Files:** 无新文件（验收门）

- [ ] **Step 1: 运行实例可见全部新技能**

```bash
curl -s http://localhost:8012/api/skills > /tmp/skills3.json
for n in expert-bd expert-osbi expert-ir customer-db demo-send exp-invite proactive-send sales-cs-manager; do
  grep -q "\"$n\"" /tmp/skills3.json && echo "OK  $n" || echo "MISS $n"
done
```

Expected: 8 行全 OK。

- [ ] **Step 2: 残留总检**

```bash
grep -rln "DECLARED_SKILLS\|DENIED_SKILLS" E:/EvoFlow/skills/public/{expert-bd,expert-osbi,expert-ir,customer-db,demo-send,exp-invite,proactive-send,sales-cs-manager} || echo ALL-CLEAN
grep -rn "metadata:" E:/EvoFlow/skills/public/{expert-bd,expert-osbi,expert-ir,customer-db,demo-send,exp-invite,proactive-send,sales-cs-manager}/SKILL.md 2>/dev/null | head -3
```

Expected: ALL-CLEAN；第二条无 openclaw metadata。

- [ ] **Step 3: 受限能力清单更新**

在 spec §4.3 追加批次 3 受限清单：
- `AWADA_KEY`/`AWADA_LANE` 未配置 → exp-invite 邀请发送、proactive-send 主动触达不可用（写 `.env.xiaobei-keys` + 重启解锁）
- relay `OFB_KEY` 未配置 → expert-bd 的 douyin-im/interact 请求类子命令受限（同批次 2 口径）
- demo-send 附件发送能力需 EvoFlow 侧等价工具（产品化项）
- customer-db 的 peer 标识由用户在对话中供给（渠道自动映射为产品化项）
- 每日复盘任务已登记未手动首跑（用户在定时任务页点「运行」观察）

- [ ] **Step 4: spec 终稿**

§4 批次表批次 3 状态置「已完成」；文档尾部加「移植工程完成」一行（批次 0/1/2/3 完成、批次 4 取消）。提交：

```bash
git add docs/superpowers/specs/2026-10-26-xiaobei-skills-port-design.md
git commit -m "docs(spec): 批次3 验收记录与移植工程完成标记"
```
