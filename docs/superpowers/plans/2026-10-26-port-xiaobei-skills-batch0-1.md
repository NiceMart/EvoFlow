# xiaobei 技能移植 EvoFlow — 批次 0+1（地基 + 纯方法论）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 xiaobei 的地基层（_shared、platform-runtime、published-track、smart-search）与 7 个纯方法论技能移植到 EvoFlow `skills/public/`，薄适配层落地并逐技能验收。

**Architecture:** 近乎原样拷贝技能目录（SKILL.md + 脚本），唯一的代码级改动是 published-track 的 ROOT 解析加 `EVOFLOW_MEDIA_WS` 环境变量回落；SKILL.md 统一执行「清洗配方」。仓库 `skills/public/` 为版本化源，同步拷贝到 `~/.evoflow/skills/public/` 使运行实例生效。

**Tech Stack:** Bash（Git Bash on Windows）、Python 3、Node.js（platform-runtime）、camoufox-cli（外部依赖，已装）、sqlite3 CLI。

**Spec:** `docs/superpowers/specs/2026-10-26-xiaobei-skills-port-design.md`（批次映射、清洗规则、环境变量约定的完整依据）

## Global Constraints

- 工作分支：`feat/port-xiaobei-skills`（所有提交在此分支）
- 平台数据根环境变量：`EVOFLOW_MEDIA_WS=E:\xiaobei-data\workspace-main`（写入 start-dev.bat，不入 git）
- `PYTHONUTF8=1`（Windows 中文脚本防坑）
- 技能源头目录：`/e/xiaobei-app/crews/`（main 与 content-producer）与 `/e/xiaobei-app/skills/`（smart-search）
- **保留全部技能名与交叉引用**，不改名
- 提交信息用中文、`feat(skills):` / `chore(skills):` 前缀，结尾加 `Co-Authored-By: Claude <noreply@anthropic.com>`
- 同步目标：`~/.evoflow/skills/public/`（运行实例技能根，loader 读这里，见 `backend/app/gateway/routers/skills.py:37`）

## 清洗配方（每个移植任务必做，对每份 SKILL.md 执行）

1. **删 openclaw frontmatter**。示例（council），before → after：

```yaml
# before                                # after
---                                     ---
name: council                           name: council
description: 召集四方视角……              description: 召集四方视角……
metadata:                               (metadata 块整体删除)
  openclaw:
    emoji: 🏛️
---                                     ---
```

2. **删 crew/openclaw 段落**：正文里「DECLARED_SKILLS」「对内/对外 crew」「openclaw 运行时」「crews/<id>」相关的段落或表格整段删除；行内措辞「crew / main agent」→「EvoFlow agent」。
3. **加环境前置段**（插在正文第一个二级标题之前；技能实际用不到的行删除）：

```markdown
## 环境前置（EvoFlow）

- `camoufox-cli`：`command -v camoufox-cli` 应可用；或用 `CAMOUFOX_CLI` 环境变量显式指定
- `ffmpeg` / `ffprobe`：`command -v ffmpeg`（仅视频类技能需要）
- Python：`python3` 可用，且 `PYTHONUTF8=1`
- 平台数据根：`EVOFLOW_MEDIA_WS`（published-track 库、平台 cookie 等相对路径的基准目录；未设置时回落到技能目录上方三级，即沿用 xiaobei 布局）
```

4. **交叉引用不动**：正文引用的其他技能名（如 expert-bd、douyin-hunter）原样保留。

## 同步与验收命令（所有任务通用）

```bash
# 移植后同步到运行实例
cp -r "E:/EvoFlow/skills/public/<name>" "/c/Users/yebin/.evoflow/skills/public/"

# 验证运行实例已加载（gateway :8012；若 /api/skills 404 则试 /v1/skills）
curl -s http://localhost:8012/api/skills | grep -o "<name>"
```

---

### Task 1: 环境前置 — start-dev.bat 注入环境变量

**Files:**
- Modify: `E:/EvoFlow/start-dev.bat`（本地未跟踪文件，不入 git）

**Interfaces:**
- Produces: gateway 进程环境含 `EVOFLOW_MEDIA_WS`、`PYTHONUTF8`，后续所有脚本任务依赖

- [ ] **Step 1: 编辑 start-dev.bat**

在 `chcp 65001 >nul` 之后、`cd /d "%~dp0"` 之前插入：

```bat
rem xiaobei 技能移植：平台数据根（published-track 库 / 平台 cookie 基准目录）
set "EVOFLOW_MEDIA_WS=E:\xiaobei-data\workspace-main"
set "PYTHONUTF8=1"
```

- [ ] **Step 2: 验证后端进程能拿到变量**

重启 start-dev.bat 的 backend 窗口，然后在任意 gateway 可达的 shell 里确认技能列表接口可用：

```bash
curl -s http://localhost:8012/api/skills -o /dev/null -w "%{http_code}"
```

Expected: `200`（若 404 改试 `/v1/skills`，下同；把生效前缀记下来供后续任务用）

---

### Task 2: _shared 共享库复制

**Files:**
- Create: `skills/public/_shared/`（自 `/e/xiaobei-app/crews/main/skills/_shared` 整目录拷贝）

**Interfaces:**
- Produces: `_shared/*.py`（asr.py、aigc_common.py、bailian_media.py 等）；后续 expert-*/hunter 技能脚本按 `<技能目录>/../_shared/xxx.py` 相对引用

- [ ] **Step 1: 拷贝**

```bash
cp -r /e/xiaobei-app/crews/main/skills/_shared E:/EvoFlow/skills/public/_shared
```

- [ ] **Step 2: 语法验证**

```bash
cd E:/EvoFlow/skills/public/_shared && PYTHONUTF8=1 python3 -m py_compile *.py && echo OK
```

Expected: `OK`（导入失败/依赖缺失不在此步报错——py_compile 只查语法）

- [ ] **Step 3: 确认无 SKILL.md**

`ls E:/EvoFlow/skills/public/_shared/SKILL.md` 应不存在（纯库目录，不是技能，loader 会跳过）。若存在则说明拷错源，重查。

- [ ] **Step 4: Commit**

```bash
git add skills/public/_shared
git commit -m "feat(skills): 移植 _shared 共享 Python 库（批次0）"
```

---

### Task 3: platform-runtime 复制 + 本地重建依赖

**Files:**
- Create: `skills/public/platform-runtime/`（自 `/e/xiaobei-app/crews/main/skills/platform-runtime`，**排除 node_modules**）
- Modify: `.gitignore`（追加 node_modules 忽略）

**Interfaces:**
- Consumes: `.runtime/catbus-cli.tgz`（捆绑包，随拷贝保留）
- Produces: 可用的 platform-runtime 运行库（catbus-cli、wreq-js），批次 2 的 expert-*/publish 技能脚本依赖

- [ ] **Step 1: 按白名单拷贝（不含 node_modules）**

```bash
SRC=/e/xiaobei-app/crews/main/skills/platform-runtime
DST=E:/EvoFlow/skills/public/platform-runtime
mkdir -p "$DST"
cp -r "$SRC"/{SKILL.md,package.json,package-lock.json,platforms.json,runtime-profile.json,references,scripts,.runtime} "$DST/"
ls "$DST"
```

Expected: 列表含 `.runtime`、`scripts`、`references` 等且**无** `node_modules`

- [ ] **Step 2: 检查 catbus-cli.tgz 体积，决定是否入 git**

```bash
du -sh E:/EvoFlow/skills/public/platform-runtime/.runtime/catbus-cli.tgz
```

- 若 < 50MB：照常入 git（步骤 5 直接 add）。
- 若 ≥ 50MB：在 `.gitignore` 追加一行 `skills/public/platform-runtime/.runtime/`，并在 SKILL.md 清洗时把「.runtime 由安装包提供」写入环境前置（产品化阶段再解决大文件分发；自用阶段本地保留文件即可）。

- [ ] **Step 3: 本地重建 node_modules**

```bash
cd E:/EvoFlow/skills/public/platform-runtime && node scripts/install-runtime.mjs
```

Expected: 无报错退出，`node_modules/catbus-cli`、`node_modules/wreq-js` 出现

- [ ] **Step 4: 冒烟验证运行库可加载**

```bash
cd E:/EvoFlow/skills/public/platform-runtime && node -e "import('catbus-cli').then(()=>console.log('OK')).catch(e=>{console.error(e);process.exit(1)})"
```

Expected: `OK`

- [ ] **Step 5: .gitignore 追加 + Commit**

`.gitignore` 追加：

```gitignore
# platform-runtime 本地依赖（install-runtime.mjs 重建）
skills/public/platform-runtime/node_modules/
```

```bash
git add .gitignore skills/public/platform-runtime
git commit -m "feat(skills): 移植 platform-runtime 运行库（批次0，node_modules 本地重建）"
```

---

### Task 4: published-track 移植 + ROOT 适配

**Files:**
- Create: `skills/public/published-track/`（自 `/e/xiaobei-app/crews/main/skills/published-track` 整目录拷贝）
- Modify: `skills/public/published-track/scripts/*.sh`（10 个文件的 ROOT 解析）、`scripts/platform-status.py`（同逻辑）、`SKILL.md`（清洗配方）

**Interfaces:**
- Consumes: `EVOFLOW_MEDIA_WS`（Task 1）、`_shared`（无需）、`sqlite3` CLI
- Produces: `published-track.sh` 子命令（init-db / record / query / update-metrics / check-published 等），库文件落在 `$EVOFLOW_MEDIA_WS/db/published_track.db`；批次 1 的 content-calibrator 与批次 3 的复盘定时任务依赖

- [ ] **Step 1: 拷贝**

```bash
cp -r /e/xiaobei-app/crews/main/skills/published-track E:/EvoFlow/skills/public/published-track
```

- [ ] **Step 2: ROOT 解析适配（.sh）**

对 10 个脚本把

```bash
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
```

替换为

```bash
ROOT="${EVOFLOW_MEDIA_WS:-$(cd "$(dirname "$0")/../../.." && pwd)}"
```

批量执行（`&` 在 sed 替换串里要转义）：

```bash
cd E:/EvoFlow/skills/public/published-track/scripts
sed -i 's|ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"|ROOT="${EVOFLOW_MEDIA_WS:-$(cd "$(dirname "$0")/../../.." \&\& pwd)"|g' *.sh
grep -c 'EVOFLOW_MEDIA_WS' *.sh
```

Expected: check-published.sh、init-db.sh、migrate-v2.sh、migrate-v3.sh、query-pending.sh、query.sh、record.sh、set-distribute-status.sh、update-metrics.sh 各计 1（validate_content.py 若含同类模式同样处理）

- [ ] **Step 3: platform-status.py 同逻辑适配**

先看它的根目录解析（形如 `Path(__file__).resolve().parents[2]` 或 `../../..`）：

```bash
grep -n '\.\./\.\./\.\.\|parents\[' E:/EvoFlow/skills/public/published-track/scripts/platform-status.py
```

把解析行改为环境变量优先，例如原行为 `ROOT = Path(__file__).resolve().parents[2]` 时改为：

```python
import os
ROOT = Path(os.environ.get("EVOFLOW_MEDIA_WS") or Path(__file__).resolve().parents[2])
```

（保持原行其余逻辑不动，只包一层环境变量回落。）

- [ ] **Step 4: SKILL.md 清洗**

按 Global Constraints 的「清洗配方」处理 `skills/public/published-track/SKILL.md`，注意保留所有子命令文档与相对路径说明（`./db/published_track.db` 的描述改为「`$EVOFLOW_MEDIA_WS/db/published_track.db`，未设变量时回落到技能目录上方三级」）。

- [ ] **Step 5: 冒烟 — 复用现有库**

```bash
export EVOFLOW_MEDIA_WS="E:/xiaobei-data/workspace-main"
ls "$EVOFLOW_MEDIA_WS/db/published_track.db"   # 已有库，应存在
bash E:/EvoFlow/skills/public/published-track/scripts/query.sh --limit 3 2>/dev/null || \
  bash E:/EvoFlow/skills/public/published-track/published-track.sh query --limit 3
```

Expected: 输出 JSON 记录（或空集合法 JSON），**不是**报错。若脚本入口参数不同，`bash published-track.sh --help` 先看用法再选只读子命令。验证库文件没有被新建到 EvoFlow 仓库目录：

```bash
ls E:/EvoFlow/db/ 2>&1
```

Expected: `No such file or directory`（证明 ROOT 适配生效）

- [ ] **Step 6: 同步到运行实例 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/published-track /c/Users/yebin/.evoflow/skills/public/
git add skills/public/published-track
git commit -m "feat(skills): 移植 published-track 并适配 EVOFLOW_MEDIA_WS 根解析（批次0）"
```

---

### Task 5: smart-search 移植 + 清洗

**Files:**
- Create: `skills/public/smart-search/`（自 `/e/xiaobei-app/skills/smart-search` 整目录拷贝，26 个文件）
- Modify: `skills/public/smart-search/SKILL.md`（清洗配方）

**Interfaces:**
- Consumes: `camoufox-cli`（PATH 或 `CAMOUFOX_CLI`）、camoufox 持久化 profile（由 camoufox-cli 自管理，本机已有）
- Produces: 浏览器搜索/读页入口；批次 2/3 的 hunter、expert-osbi 依赖其 site-catalog 与 sites/*.md

- [ ] **Step 1: 拷贝**

```bash
cp -r /e/xiaobei-app/skills/smart-search E:/EvoFlow/skills/public/smart-search
ls E:/EvoFlow/skills/public/smart-search
```

Expected: 含 `SKILL.md`、`site-catalog.json`、`sites/`

- [ ] **Step 2: SKILL.md 清洗**

按「清洗配方」执行；`sites/*.md` 与 `site-catalog.json` 是数据文件不动。清洗时保留对 hunter 技能的路由表（douyin/xhs/tiktok/kuaishou/x/weibo/wx-mp-hunter 优先级说明）——批次 2 移植这些技能后该路由才有意义，现在原样保留。

- [ ] **Step 3: 冒烟 — 真实搜索一次**

```bash
grep -m3 -B1 -A4 "搜索\|search" E:/EvoFlow/skills/public/smart-search/SKILL.md
```

确认清洗后的 SKILL.md 仍保留搜索工作流说明，且 `site-catalog.json`、`sites/` 完整（26 个文件计数不减）。

随后**由 agent 实测**（本任务的人工/agent 验收点）：在 EvoFlow 会话里让 agent 按 SKILL.md 指引对某站点执行一次搜索，确认 camoufox 会话拉起并返回真实结果。若无 camoufox 输出，先查 `command -v camoufox-cli`。

- [ ] **Step 4: 同步到运行实例 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/smart-search /c/Users/yebin/.evoflow/skills/public/
git add skills/public/smart-search
git commit -m "feat(skills): 移植 smart-search 浏览器搜索技能（批次0）"
```

---

### Task 6: 批次 0 验收清单

**Files:** 无新文件（验收门）

- [ ] **Step 1: 运行实例可见 4 个新条目**

```bash
curl -s http://localhost:8012/api/skills | grep -oE '"(published-track|smart-search)"' | sort -u
ls /c/Users/yebin/.evoflow/skills/public/ | grep -E '^(published-track|smart-search|platform-runtime|_shared)$'
```

Expected: 两条命令都命中（`_shared`/`platform-runtime` 无 SKILL.md 的话 loader 不列为技能，文件存在即可）

- [ ] **Step 2: published-track 读写闭环**

```bash
export EVOFLOW_MEDIA_WS="E:/xiaobei-data/workspace-main"
bash E:/EvoFlow/skills/public/published-track/scripts/check-published.sh --platform wx-mp --source-folder smoke-test-nonexist
```

Expected: 合法 JSON（`{"exists":...}` 或记录状态），退出码 0/1 均可，不得 traceback

---

### Task 7: council + viral-chaser 移植

**Files:**
- Create: `skills/public/council/`（自 `/e/xiaobei-app/crews/main/skills/council`）
- Create: `skills/public/viral-chaser/`（自 `/e/xiaobei-app/crews/main/skills/viral-chaser`，42K）
- Modify: 两份 SKILL.md（清洗配方）

**Interfaces:**
- Produces: `council`（四方视角辩论方法论）、`viral-chaser`（爆款拆解）；正文若引用 `published-track`/hunter 技能名，保留

- [ ] **Step 1: 拷贝 + 清洗**

```bash
cp -r /e/xiaobei-app/crews/main/skills/council E:/EvoFlow/skills/public/council
cp -r /e/xiaobei-app/crews/main/skills/viral-chaser E:/EvoFlow/skills/public/viral-chaser
```

对两份 SKILL.md 执行清洗配方（council 的 metadata.openclaw 删除见配方示例；viral-chaser 若引用 camoufox/hunter 则保留引用并加环境前置段）。

- [ ] **Step 2: 残留检查**

```bash
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/council E:/EvoFlow/skills/public/viral-chaser || echo CLEAN
```

Expected: `CLEAN`（正文如有保留价值的「crew」上下文句子已改写为 EvoFlow agent 语境）

- [ ] **Step 3: agent 实测（验收点）**

在 EvoFlow 会话让 agent 用 council 对一个模糊商业问题跑一次四方视角辩论，产出结构应含战略家/质疑者/务实者/风控者四段。

- [ ] **Step 4: 同步 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/{council,viral-chaser} /c/Users/yebin/.evoflow/skills/public/
git add skills/public/council skills/public/viral-chaser
git commit -m "feat(skills): 移植 council 与 viral-chaser 方法论技能（批次1）"
```

---

### Task 8: pitch-deck + talking-head-cut + video-edit 移植

**Files:**
- Create: `skills/public/pitch-deck/`、`skills/public/talking-head-cut/`、`skills/public/video-edit/`（自 `/e/xiaobei-app/crews/main/skills/` 同名目录）
- Modify: 三份 SKILL.md（清洗配方）

**Interfaces:**
- Consumes: `ffmpeg/ffprobe`（talking-head-cut、video-edit）；pitch-deck 为 HTML 产出型，无外部依赖

- [ ] **Step 1: 拷贝 + 清洗**

```bash
for s in pitch-deck talking-head-cut video-edit; do
  cp -r "/e/xiaobei-app/crews/main/skills/$s" "E:/EvoFlow/skills/public/$s"
done
```

三份 SKILL.md 执行清洗配方（视频类保留 ffmpeg/camoufox 环境前置）。

- [ ] **Step 2: 依赖检查 + 残留检查**

```bash
command -v ffmpeg && command -v ffprobe   # 应都可用
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/{pitch-deck,talking-head-cut,video-edit} || echo CLEAN
```

- [ ] **Step 3: agent 实测（验收点）**

让 agent 用 video-edit 对任一本地短视频做一次抽段（如取前 5 秒），确认产物文件生成；pitch-deck 生成一页测试 HTML。

- [ ] **Step 4: 同步 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/{pitch-deck,talking-head-cut,video-edit} /c/Users/yebin/.evoflow/skills/public/
git add skills/public/pitch-deck skills/public/talking-head-cut skills/public/video-edit
git commit -m "feat(skills): 移植 pitch-deck/talking-head-cut/video-edit（批次1）"
```

---

### Task 9: expert-design 移植

**Files:**
- Create: `skills/public/expert-design/`（自 `/e/xiaobei-app/crews/content-producer/skills/expert-design`，304K，注意源在 content-producer crew）
- Modify: `SKILL.md`（清洗配方）

**Interfaces:**
- Produces: 平面设计方法论（含 tools/design-full）；后续海报/封面任务调用

- [ ] **Step 1: 拷贝 + 清洗 + 残留检查**

```bash
cp -r /e/xiaobei-app/crews/content-producer/skills/expert-design E:/EvoFlow/skills/public/expert-design
# 按「清洗配方」处理 SKILL.md 后：
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/expert-design || echo CLEAN
```

- [ ] **Step 2: agent 实测（验收点）**

让 agent 用 expert-design 产出一张简单图文海报设计稿，确认方法论被正确触发。

- [ ] **Step 3: 同步 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/expert-design /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-design
git commit -m "feat(skills): 移植 expert-design（批次1，源自 content-producer）"
```

---

### Task 10: content-calibrator 移植 + 与 published-track 联测

**Files:**
- Create: `skills/public/content-calibrator/`（自 `/e/xiaobei-app/crews/main/skills/content-calibrator`）
- Modify: `SKILL.md`（清洗配方）

**Interfaces:**
- Consumes: `published-track`（Task 4 的 `$EVOFLOW_MEDIA_WS/db/published_track.db`）
- Produces: DNA 表现评估能力；批次 3 的每日复盘定时任务以它为核心

- [ ] **Step 1: 拷贝 + 清洗**

```bash
cp -r /e/xiaobei-app/crews/main/skills/content-calibrator E:/EvoFlow/skills/public/content-calibrator
# 按「清洗配方」处理；正文引用 published-track 命令的部分原样保留
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/content-calibrator || echo CLEAN
```

- [ ] **Step 2: 联测 — 用真实库跑一次评估**

```bash
export EVOFLOW_MEDIA_WS="E:/xiaobei-data/workspace-main"
ls "$EVOFLOW_MEDIA_WS/db/published_track.db" && echo DB-OK
```

随后由 agent 实测：让 agent 按 content-calibrator 的 SKILL.md 对库中最近记录跑一次表现评估。库为空/记录少时允许产出「数据不足」结论——只要流程走通、不 traceback 即通过。

- [ ] **Step 3: 同步 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/content-calibrator /c/Users/yebin/.evoflow/skills/public/
git add skills/public/content-calibrator
git commit -m "feat(skills): 移植 content-calibrator 并联测 published-track（批次1）"
```

---

### Task 11: 批次 0+1 总验收

**Files:** 无新文件（验收门）

- [ ] **Step 1: 运行实例技能清单**

```bash
curl -s http://localhost:8012/api/skills | grep -oE '"(council|viral-chaser|pitch-deck|talking-head-cut|video-edit|expert-design|content-calibrator)"' | sort -u
```

Expected: 7 个全部命中

- [ ] **Step 2: 残留总检**

```bash
grep -rln "DECLARED_SKILLS" E:/EvoFlow/skills/public/ || echo ALL-CLEAN
grep -rln "metadata:" E:/EvoFlow/skills/public/{council,viral-chaser,pitch-deck,talking-head-cut,video-edit,expert-design,content-calibrator,published-track,smart-search}/*/SKILL.md E:/EvoFlow/skills/public/*/SKILL.md 2>/dev/null | head
```

Expected: `ALL-CLEAN`；第二条无 openclaw metadata 残留

- [ ] **Step 3: 收尾记录**

在 spec 文档（`docs/superpowers/specs/2026-10-26-xiaobei-skills-port-design.md`）第 4 节批次表标注批次 0/1 完成状态与实测中发现的问题清单，提交：

```bash
git add docs/superpowers/specs/2026-10-26-xiaobei-skills-port-design.md
git commit -m "docs(spec): 批次0+1 移植完成记录"
```
