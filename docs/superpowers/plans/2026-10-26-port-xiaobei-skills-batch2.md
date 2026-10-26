# xiaobei 技能移植 EvoFlow — 批次 2（平台运营）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 21 个平台运营技能（7 expert + 7 hunter + 3 publish + wxwork-moments + expert-video + 4 公共补充）移植到 EvoFlow `skills/public/`，relay/会话依赖按自用约定落地并优雅降级。

**Architecture:** 沿批次 0+1 模式：近原样拷贝 + 清洗配方；薄壳技能（exec `../platform-runtime/scripts/cli.mjs`）在 EvoFlow 同级布局下路径天然成立；relay（`relay.openclaw-for-business.com` + `OFB_KEY`）保留为外部依赖，缺凭据时技能自身 fail-fast 引导；`business_knowledge.md` 复用 `$EVOFLOW_MEDIA_WS/business_knowledge.md`（存在才用）。

**Tech Stack:** Bash（Git Bash）、Python 3、Node.js（platform-runtime cli.mjs / bgm / deck-render）、camoufox-cli、ffmpeg。

**Spec:** `docs/superpowers/specs/2026-10-26-xiaobei-skills-port-design.md`（§3 映射、§4 批次表、§4.1 批次 0+1 实测记录）

**调查报告要点（本计划的依赖事实来源）:** 21 个技能的传输分类——camoufox 直连：expert-douyin（session `douyin`）、expert-wx-channel（session `wechat-channel`）、wx-mp-hunter；platform-runtime 薄壳：expert-kuaishou/tiktok/twitter、tiktok/kuaishou/x/weibo-hunter、weibo-publish；crew `_shared`：douyin/xhs-hunter（live CLI）、zhihu-publish + expert-wx-channel（browser_publish_text.py）、expert-douyin（relay-sign.ts）；纯 HTTP relay：expert-wx-mp 发布、wxwork-moments、expert-xhs 签名。

## Global Constraints

沿批次 0+1 全部约束（分支 feat/port-xiaobei-skills、清洗配方、commit 规范、同步到 `~/.evoflow/skills/public/`），另有批次 2 特有：

- **relay 保留**：`OFB_KEY`/`RELAY_BASE_URL`/`WXWORK_CORP_ID`/`WXWORK_CORP_SECRET` 不伪造、不硬编码；缺失时技能 fail-fast 即为正确行为，环境前置注明「缺凭据时哪些子命令不可用」
- **`~/.openclaw/...` 登录态路径保留**（spec §4.1 决策：与 xiaobei 共享平台会话）
- **`business_knowledge.md` 引用改写**：「工作区根的 business_knowledge.md」→「`$EVOFLOW_MEDIA_WS/business_knowledge.md`（存在才用；缺失时按技能内指引要求用户提供业务事实）」
- **`data-xiaobei-*` DOM 标记保留**（expert-douyin 发布脚本的内部选择器，非基建引用）
- **冒烟只做零成本命令**（`--help`、`--check`、只读查询）；禁止真实发布/生成/登录
- 本机已知密钥存量：`AWK_API_KEY`（在 `/e/xiaobei-data/daemon.env`）；`OFB_KEY`、`WXWORK_CORP_*`、`DASHSCOPE_API_KEY`、`MINIMAX_API_KEY`、`VOLC_*` 均未配置——相关技能受限为已知状态，不是移植缺陷
- 清洗配方（同批次 0+1）：删 `metadata.openclaw`、删 crew/DECLARED_SKILLS/openclaw 段落、「crew/main agent」→「EvoFlow agent」、加环境前置段（按技能实际依赖取行）、技能名与交叉引用原样保留

## 同步与验收命令（所有任务通用，同批次 0+1）

```bash
cp -r "E:/EvoFlow/skills/public/<name>/" "/c/Users/yebin/.evoflow/skills/public/"
curl -s http://localhost:8012/api/skills | grep -o "<name>"
```

---

### Task 1: 密钥桥 — .env.xiaobei-keys + start-dev.bat 注入

**Files:**
- Create: `E:/EvoFlow/.env.xiaobei-keys`（本地 git-ignored，不入 git）
- Modify: `E:/EvoFlow/start-dev.bat`（本地未跟踪）
- Modify: `.gitignore`（追加忽略行，入 git）

**Interfaces:**
- Produces: gateway 进程环境含 `AWK_API_KEY` 等；后续所有任务的密钥前置

- [ ] **Step 1: 建密钥文件**

从 `/e/xiaobei-data/daemon.env` 复制已知存量密钥（本机仅 `AWK_API_KEY` 一行）到 `E:/EvoFlow/.env.xiaobei-keys`，格式每行 `KEY=VALUE`，`#` 开头为注释。文件头注释注明：「xiaobei 技能密钥本地桥（git-ignored）。缺失项（OFB_KEY、WXWORK_CORP_ID/SECRET、DASHSCOPE_API_KEY、MINIMAX_API_KEY、VOLC_*）待用户补配——补配后相关技能自动解锁。」

- [ ] **Step 2: start-dev.bat 注入**

在 Task 1（批次0）插入的 `set "PYTHONUTF8=1"` 行之后加：

```bat
rem xiaobei 技能密钥桥（git-ignored 的 .env.xiaobei-keys，存在才加载）
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~dp0.env.xiaobei-keys") do set "%%a=%%b"
```

- [ ] **Step 3: .gitignore 追加**

```gitignore
# xiaobei 技能密钥本地桥
.env.xiaobei-keys
```

- [ ] **Step 4: 验证**

`git check-ignore E:/EvoFlow/.env.xiaobei-keys` 命中；`cmd //c "for /f ..." ` 语法在 Git Bash 不可直接测——验证方式：新开 `cmd //c start-dev.bat` 之外，改为在当前 Git Bash `set -a; source <(sed 's/^/export /' E:/EvoFlow/.env.xiaobei-keys); echo ${AWK_API_KEY:+SET}`（预期 `SET`，不打印值）。bat 侧语法由 Task 13 验收门用真实重启验证。

- [ ] **Step 5: Commit**

```bash
git add .gitignore
git commit -m "chore(skills): 密钥桥 .env.xiaobei-keys 忽略规则（批次2）"
```

（commit 信息附 `Co-Authored-By: Claude <noreply@anthropic.com>` 尾注，下同）

---

### Task 2: 公共四件 — video-review / bgm-library / awk-img-gen / aigc-video-gen

**Files:**
- Create: `skills/public/video-review/`、`skills/public/bgm-library/`（排除 node_modules）、`skills/public/awk-img-gen/`、`skills/public/aigc-video-gen/`（自 `/e/xiaobei-app/skills/` 同名目录）
- Modify: 四份 SKILL.md（清洗配方）

**Interfaces:**
- Consumes: `AWK_API_KEY`（Task 1）、ffmpeg/ffprobe、node（bgm）
- Produces: `video-review`（成片自检闸门，后续 expert-video/aigc-video-gen 必跑）、`awk-img-gen`/`aigc-video-gen`（expert-design/expert-douyin 交叉引用的生图/生视频入口）、`bgm-library`（ccMixter BGM）

- [ ] **Step 1: 拷贝（bgm 排除 node_modules）**

```bash
for s in video-review awk-img-gen aigc-video-gen; do
  cp -r "/e/xiaobei-app/skills/$s" "E:/EvoFlow/skills/public/$s"
done
SRC=/e/xiaobei-app/skills/bgm-library; DST=E:/EvoFlow/skills/public/bgm-library
mkdir -p "$DST"
cp -r "$SRC"/{SKILL.md,bgm-library.sh,package.json,package-lock.json,scripts} "$DST/"
ls "$DST"   # 无 node_modules
```

- [ ] **Step 2: bgm-library 重建依赖**

```bash
cd E:/EvoFlow/skills/public/bgm-library && npm ci 2>&1 | tail -2 && node -e "import('./scripts/bgm.js').then(()=>console.log('BGM-OK')).catch(e=>{console.error(String(e).slice(0,200));process.exit(1)})"
```

Expected: 安装成功 + `BGM-OK`（若 bgm.js 是 CLI 入口无导出，改用 `node scripts/bgm.js --help` 验证零成本执行）。

- [ ] **Step 3: 四份 SKILL.md 清洗 + 密钥前置**

按清洗配方处理；环境前置按实际依赖：
- video-review：python3 + ffmpeg/ffprobe 行
- bgm-library：node 行（无密钥）
- awk-img-gen：python3 行 + 「`AWK_API_KEY`（plan 模式）或 `WORKSPACE_ID`+`MODELSTUDIO_API_KEY`/`DASHSCOPE_API_KEY`（workspace 模式）；缺失时 exit 1 给配置指引」
- aigc-video-gen：python3 + ffmpeg 行 + 「密钥回落链：`MINIMAX_API_KEY` > `VOLC_SEEDANCE_API_KEY` > `WORKSPACE_ID`+`MODELSTUDIO_API_KEY`/`DASHSCOPE_API_KEY` > `AWK_API_KEY`；全缺时 exit 2 建议改用 pexels/pixabay-footage」

- [ ] **Step 4: 残留检查 + 冒烟**

```bash
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/{video-review,bgm-library,awk-img-gen,aigc-video-gen} || echo CLEAN
bash E:/EvoFlow/skills/public/awk-img-gen/awk-img-gen.sh --help 2>&1 | head -5 || python3 E:/EvoFlow/skills/public/awk-img-gen/scripts/gen.py --help 2>&1 | head -5
ls E:/EvoFlow/skills/public/bgm-library/scripts/
```

Expected: `CLEAN`；awk-img-gen usage 或缺密钥的明确指引（exit 1 属预期）；bgm scripts 目录含 bgm.js + downloader.js。

Expected: `CLEAN`；bgm scripts 目录含 bgm.js + downloader.js。

- [ ] **Step 5: 同步 + Commit**

```bash
for s in video-review bgm-library awk-img-gen aigc-video-gen; do cp -r "E:/EvoFlow/skills/public/$s/" "/c/Users/yebin/.evoflow/skills/public/"; done
git add skills/public/video-review skills/public/bgm-library skills/public/awk-img-gen skills/public/aigc-video-gen
git commit -m "feat(skills): 移植公共四件 video-review/bgm-library/awk-img-gen/aigc-video-gen（批次2）"
```

注意：`git add` 前确认 bgm-library 的 node_modules 已被全局 `node_modules/` 忽略规则或本地规则排除（`git check-ignore skills/public/bgm-library/node_modules`；未忽略则先在本任务补 `.gitignore` 行 `skills/public/bgm-library/node_modules/`）。

---

### Task 3: hunter 薄壳五件 — tiktok/kuaishou/x/weibo-hunter + weibo-publish

**Files:**
- Create: `skills/public/{tiktok-hunter,kuaishou-hunter,x-hunter,weibo-hunter,weibo-publish}/`（自 `/e/xiaobei-app/crews/main/skills/` 同名目录，各 2-4 文件）
- Modify: 五份 SKILL.md（清洗配方）

**Interfaces:**
- Consumes: `../platform-runtime/scripts/cli.mjs`（批次 0 已移植，同级布局 `skills/public/<name>/../platform-runtime/` 成立）
- Produces: platform 采集/发布薄壳；x-hunter 会话名 `twitter`（登录/导出流程见 platform-runtime/references/login.md，保持原引用）

- [ ] **Step 1: 拷贝 + 清洗**

```bash
for s in tiktok-hunter kuaishou-hunter x-hunter weibo-hunter weibo-publish; do
  cp -r "/e/xiaobei-app/crews/main/skills/$s" "E:/EvoFlow/skills/public/$s"
done
```

五份 SKILL.md 按清洗配方处理（各仅 1 处 openclaw 文档性残留，正文按配方）；环境前置：camoufox-cli 行 + 「平台会话经由 platform-runtime 持久化（首次使用需按 login.md 走登录/导出）」。

- [ ] **Step 2: 薄壳路径核验**

```bash
head -12 E:/EvoFlow/skills/public/tiktok-hunter/tiktok-hunter.sh
ls E:/EvoFlow/skills/public/platform-runtime/scripts/cli.mjs
```

Expected: wrapper 内相对路径 `../platform-runtime/scripts/cli.mjs`；目标存在。五个 wrapper 逐一 `head` 核对。

- [ ] **Step 3: 零成本冒烟（--help 直穿 cli.mjs）**

```bash
bash E:/EvoFlow/skills/public/tiktok-hunter/tiktok-hunter.sh --help 2>&1 | head -5
```

Expected: cli.mjs 帮助输出或平台子命令帮助（不拉起浏览器、不写会话）。若 --help 触发真实登录流程则改验 `node E:/EvoFlow/skills/public/platform-runtime/scripts/cli.mjs --help` 并在报告注明。

- [ ] **Step 4: 残留检查 + 同步 + Commit**

```bash
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/{tiktok-hunter,kuaishou-hunter,x-hunter,weibo-hunter,weibo-publish} || echo CLEAN
for s in tiktok-hunter kuaishou-hunter x-hunter weibo-hunter weibo-publish; do cp -r "E:/EvoFlow/skills/public/$s/" "/c/Users/yebin/.evoflow/skills/public/"; done
git add skills/public/tiktok-hunter skills/public/kuaishou-hunter skills/public/x-hunter skills/public/weibo-hunter skills/public/weibo-publish
git commit -m "feat(skills): 移植 hunter 薄壳四件与 weibo-publish（批次2）"
```

---

### Task 4: douyin-hunter + xhs-hunter

**Files:**
- Create: `skills/public/douyin-hunter/`（58K）、`skills/public/xhs-hunter/`（46K）（自 `/e/xiaobei-app/crews/main/skills/`）
- Modify: 两份 SKILL.md（清洗配方）

**Interfaces:**
- Consumes: `../_shared/douyin_live_cli.py`、`../_shared/xhs_live_cli.py`、`../_shared/douyin_utils/`（批次 0 已移植）、会话 `~/.openclaw/logins/xhs-pc-local.json`（共享决策）
- Produces: 抖音/小红书内容采集（live 子命令 `--access read` 只读）

- [ ] **Step 1: 拷贝 + 清洗**

```bash
cp -r /e/xiaobei-app/crews/main/skills/douyin-hunter E:/EvoFlow/skills/public/douyin-hunter
cp -r /e/xiaobei-app/crews/main/skills/xhs-hunter E:/EvoFlow/skills/public/xhs-hunter
```

两份 SKILL.md 按清洗配方处理（douyin-hunter 的 douyin-login 工具子目录一并拷贝、其 SKILL.md 同样清洗）；环境前置：camoufox-cli 行 + 「抖音 live/IM 会话存于 `~/.openclaw/douyin-im/`；小红书 PC 会话存于 `~/.openclaw/logins/xhs-pc-local.json`（与 xiaobei 共享）」。

- [ ] **Step 2: 依赖链核验**

```bash
head -8 E:/EvoFlow/skills/public/douyin-hunter/douyin-hunter.sh
ls E:/EvoFlow/skills/public/_shared/douyin_live_cli.py E:/EvoFlow/skills/public/_shared/xhs_live_cli.py E:/EvoFlow/skills/public/_shared/douyin_utils/ 2>&1 | head -5
PYTHONUTF8=1 python3 -m py_compile E:/EvoFlow/skills/public/douyin-hunter/scripts/douyin_hunter.py E:/EvoFlow/skills/public/xhs-hunter/scripts/xhs_hunter.py && echo PY-OK
```

Expected: wrapper 引用 `../_shared/...`；文件存在；`PY-OK`。若 py_compile 报第三方导入错误，记录（py_compile 仅语法层不该报）。

- [ ] **Step 3: 零成本冒烟**

```bash
bash E:/EvoFlow/skills/public/douyin-hunter/douyin-hunter.sh --help 2>&1 | head -5
bash E:/EvoFlow/skills/public/xhs-hunter/xhs-hunter.sh --help 2>&1 | head -5
```

Expected: 各自 usage 输出，无 traceback（无会话时报缺会话的引导信息也算过）。

- [ ] **Step 4: 残留检查 + 同步 + Commit**

```bash
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/{douyin-hunter,xhs-hunter} || echo CLEAN
cp -r E:/EvoFlow/skills/public/douyin-hunter/ /c/Users/yebin/.evoflow/skills/public/
cp -r E:/EvoFlow/skills/public/xhs-hunter/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/douyin-hunter skills/public/xhs-hunter
git commit -m "feat(skills): 移植 douyin-hunter 与 xhs-hunter（批次2，live CLI + 独立会话）"
```

---

### Task 5: wx-mp-hunter（容器依赖标注）

**Files:**
- Create: `skills/public/wx-mp-hunter/`（73K，自 `/e/xiaobei-app/crews/main/skills/`）
- Modify: SKILL.md（清洗配方 + 容器前置）

**Interfaces:**
- Consumes: camoufox-cli；`WX_BIZ_CONTAINER`/`WX_BIZ_USER_DIR`/`WX_BIZ_KEYS_FILE`/`WX_BIZ_DB_KEY_NAME`/`WX_BIZ_XWECHAT_ROOT`（Linux 微信容器 `mimicwx-linux`，本机未配置）
- Produces: 公众号 biz 消息抓取（容器就绪时可用）

- [ ] **Step 1: 拷贝 + 清洗 + 容器前置**

```bash
cp -r /e/xiaobei-app/crews/main/skills/wx-mp-hunter E:/EvoFlow/skills/public/wx-mp-hunter
```

SKILL.md 按清洗配方处理；环境前置加：「`WX_BIZ_*` 五个变量指向 Linux 微信容器（mimicwx-linux，`/home/wechat/.xwechat/`）；变量缺失或容器未运行时本技能不可用——属预期限制，不视为移植缺陷」。

- [ ] **Step 2: 残留检查 + 语法验证 + 同步 + Commit**

```bash
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/wx-mp-hunter || echo CLEAN
PYTHONUTF8=1 python3 -m py_compile E:/EvoFlow/skills/public/wx-mp-hunter/scripts/wx_mp_hunter.py && echo PY-OK
cp -r E:/EvoFlow/skills/public/wx-mp-hunter/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/wx-mp-hunter
git commit -m "feat(skills): 移植 wx-mp-hunter（批次2，标注容器依赖）"
```

---

### Task 6: zhihu-publish + wxwork-moments

**Files:**
- Create: `skills/public/zhihu-publish/`（13K）、`skills/public/wxwork-moments/`（29K）（自 `/e/xiaobei-app/crews/main/skills/`）
- Modify: 两份 SKILL.md（清洗配方 + relay/凭据前置）

**Interfaces:**
- Consumes: zhihu-publish → `../_shared/browser_publish_text.py zhihu`（批次 0 已移植）；wxwork-moments → 纯 HTTPS relay
- Produces: 知乎文章/回答发布（camoufox session `zhihu`）；朋友圈发布（relay）

- [ ] **Step 1: 拷贝 + 清洗 + 凭据前置**

```bash
cp -r /e/xiaobei-app/crews/main/skills/zhihu-publish E:/EvoFlow/skills/public/zhihu-publish
cp -r /e/xiaobei-app/crews/main/skills/wxwork-moments E:/EvoFlow/skills/public/wxwork-moments
```

清洗按配方；环境前置：
- zhihu-publish：camoufox-cli 行 + 「持久化 session `zhihu`（首次发布前需按原流程登录一次）」
- wxwork-moments：「需 `RELAY_BASE_URL`（默认 relay.openclaw-for-business.com）+ `OFB_KEY` + `WXWORK_CORP_ID` + `WXWORK_CORP_SECRET`（凭据由 relay 服务端校验与剥离）；`OFB_KEY` 未配置时本技能不可用——写入 `.env.xiaobei-keys` 后自动解锁」

- [ ] **Step 2: 依赖核验 + 零成本冒烟**

```bash
ls E:/EvoFlow/skills/public/_shared/browser_publish_text.py && echo ZH-DEP-OK
bash E:/EvoFlow/skills/public/zhihu-publish/zhihu-publish.sh --help 2>&1 | head -5
bash E:/EvoFlow/skills/public/wxwork-moments/*.sh --help 2>&1 | head -5 || ls E:/EvoFlow/skills/public/wxwork-moments/
```

Expected: ZH-DEP-OK；两技能 usage 或缺凭据的明确报错（不 traceback）。

- [ ] **Step 3: 残留检查 + 同步 + Commit**

```bash
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/{zhihu-publish,wxwork-moments} || echo CLEAN
cp -r E:/EvoFlow/skills/public/zhihu-publish/ /c/Users/yebin/.evoflow/skills/public/
cp -r E:/EvoFlow/skills/public/wxwork-moments/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/zhihu-publish skills/public/wxwork-moments
git commit -m "feat(skills): 移植 zhihu-publish 与 wxwork-moments（批次2，relay 凭据前置）"
```

---

### Task 7: expert 三胞胎 — expert-kuaishou / expert-tiktok / expert-twitter

**Files:**
- Create: `skills/public/{expert-kuaishou,expert-tiktok,expert-twitter}/`（各 ~40-51K，自 `/e/xiaobei-app/crews/main/skills/`）
- Modify: 三份 SKILL.md + 各自 workflows/ 内文档（清洗配方）

**Interfaces:**
- Consumes: platform-runtime `cli.mjs`/`style-profile.py`（批次 0）；`$EVOFLOW_MEDIA_WS/business_knowledge.md`（轻引用）
- Produces: 快手/TikTok/X 三平台运营专家（publish/engagement/style-profiler 全走薄壳）

- [ ] **Step 1: 拷贝 + 清洗**

```bash
for s in expert-kuaishou expert-tiktok expert-twitter; do
  cp -r "/e/xiaobei-app/crews/main/skills/$s" "E:/EvoFlow/skills/public/$s"
done
```

SKILL.md 与 workflows/*.md 按清洗配方处理；`business_knowledge.md` 引用按 Global Constraints 改写；环境前置：camoufox-cli 行 + platform-runtime 行 + business_knowledge 行。

- [ ] **Step 2: 薄壳路径核验 + 残留检查**

```bash
grep -rhoE '\.\./\.\./platform-runtime[^ ]*' E:/EvoFlow/skills/public/expert-kuaishou/ | head -2
ls E:/EvoFlow/skills/public/platform-runtime/scripts/cli.mjs E:/EvoFlow/skills/public/platform-runtime/scripts/style-profile.py
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/expert-{kuaishou,tiktok,twitter} || echo CLEAN
```

Expected: 相对路径 `../../../platform-runtime`（expert 深一层，`skills/public/expert-*/tools/*/`→ 上三级 = `skills/public/`）或同义——以实际脚本为准逐个核验目标存在；`CLEAN`。

- [ ] **Step 3: 同步 + Commit**

```bash
for s in expert-kuaishou expert-tiktok expert-twitter; do cp -r "E:/EvoFlow/skills/public/$s/" "/c/Users/yebin/.evoflow/skills/public/"; done
git add skills/public/expert-kuaishou skills/public/expert-tiktok skills/public/expert-twitter
git commit -m "feat(skills): 移植 expert-kuaishou/tiktok/twitter 三胞胎（批次2）"
```

---

### Task 8: expert-douyin

**Files:**
- Create: `skills/public/expert-douyin/`（375K，自 `/e/xiaobei-app/crews/main/skills/`）
- Modify: SKILL.md + workflows/（清洗配方）；计划外脚本编辑须申报

**Interfaces:**
- Consumes: `CAMOUFOX_CLI`（session `douyin`，`--persistent`）、crew `_shared/relay-sign.ts`（批次 0）、`~/.camoufox-cli/publications/douyin-video.json` 状态、published-track
- Produces: 抖音运营专家（video_publish/note_publish/engagement/style-profiler）

- [ ] **Step 1: 拷贝 + 清洗**

```bash
cp -r /e/xiaobei-app/crews/main/skills/expert-douyin E:/EvoFlow/skills/public/expert-douyin
```

SKILL.md 与 workflows/ 清洗按配方；`data-xiaobei-*` DOM 标记保留（Global Constraints）；business_knowledge 引用按约定改写；环境前置：CAMOUFOX_CLI 行 + OFB_KEY 行（fetch-retro-data 的 relay 签名，缺失时该子命令不可用）+ published-track 行。

- [ ] **Step 2: 路径与语法核验**

```bash
ls E:/EvoFlow/skills/public/_shared/relay-sign.ts
grep -rn "relay-sign" E:/EvoFlow/skills/public/expert-douyin/tools/ | head -3
PYTHONUTF8=1 python3 -m py_compile E:/EvoFlow/skills/public/expert-douyin/tools/_shared/publish_browser.py E:/EvoFlow/skills/public/expert-douyin/tools/douyin-publish/scripts/video_publish.py && echo PY-OK
```

Expected: relay-sign.ts 存在于 `_shared`；`PY-OK`。若 video_publish.py 的相对导入指向 `../../_shared` 等层级，逐条核验目标真实存在。

- [ ] **Step 3: 残留检查 + 同步 + Commit**

```bash
grep -rn "DECLARED_SKILLS\|openclaw" E:/EvoFlow/skills/public/expert-douyin --include="*.md" | grep -v data-xiaobei || echo CLEAN
cp -r E:/EvoFlow/skills/public/expert-douyin/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-douyin
git commit -m "feat(skills): 移植 expert-douyin（批次2，camoufox 会话 + relay 签名）"
```

---

### Task 9: expert-wx-channel

**Files:**
- Create: `skills/public/expert-wx-channel/`（247K，自 `/e/xiaobei-app/crews/main/skills/`）
- Modify: SKILL.md + workflows/（清洗配方）

**Interfaces:**
- Consumes: `../_shared/browser_publish_text.py wechat-channel`（批次 0）、camoufox session `wechat-channel`（wujie shadow-root DOM）、published-track
- Produces: 视频号运营专家

- [ ] **Step 1: 拷贝 + 清洗**

```bash
cp -r /e/xiaobei-app/crews/main/skills/expert-wx-channel E:/EvoFlow/skills/public/expert-wx-channel
```

清洗按配方；business_knowledge 引用按约定改写（survey 显示 wx-channel 未列 heavy 依赖，如实处理）；环境前置：CAMOUFOX_CLI 行（session `wechat-channel`，headless，wujie shadow-root）+ published-track 行。

- [ ] **Step 2: 依赖核验 + 残留检查**

```bash
grep -rn "browser_publish_text" E:/EvoFlow/skills/public/expert-wx-channel/ | head -2
ls E:/EvoFlow/skills/public/_shared/browser_publish_text.py
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/expert-wx-channel || echo CLEAN
```

- [ ] **Step 3: 同步 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/expert-wx-channel/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-wx-channel
git commit -m "feat(skills): 移植 expert-wx-channel（批次2，browser_publish_text 发布）"
```

---

### Task 10: expert-wx-mp

**Files:**
- Create: `skills/public/expert-wx-mp/`（260K，自 `/e/xiaobei-app/crews/main/skills/`）
- Modify: SKILL.md + workflows/（清洗配方）

**Interfaces:**
- Consumes: relay `POST {RELAY_BASE_URL}/api/v1/wx-mp/publish`（`OFB_KEY`）、camoufox 会话（engagement 探测）、published-track（5 处）、`$EVOFLOW_MEDIA_WS/business_knowledge.md`（载重）
- Produces: 公众号运营专家（写作/排版/发布/互动/风格画像/文言主题）；**小绿书（图片消息）能力在内**

- [ ] **Step 1: 拷贝 + 清洗 + 参数化默认作者**

```bash
cp -r /e/xiaobei-app/crews/main/skills/expert-wx-mp E:/EvoFlow/skills/public/expert-wx-mp
```

清洗按配方；business_knowledge 引用按约定改写（这是载重依赖——改写文本明确「缺失时先向用户收集业务事实再进入写作流」）；**默认作者 "xiaobei" 参数化**：workflows 中出现的默认作者改写为「默认作者取 `$EVOFLOW_AUTHOR` 环境变量，未设置时向用户询问」；环境前置：RELAY_BASE_URL/OFB_KEY 行（发布子命令依赖，缺失不可用）+ camoufox 行 + published-track 行。

- [ ] **Step 2: 依赖核验 + 残留检查**

```bash
grep -rn "RELAY_BASE_URL\|relay.openclaw-for-business.com" E:/EvoFlow/skills/public/expert-wx-mp/tools/wx-mp-publisher/ | head -3
PYTHONUTF8=1 python3 -m py_compile E:/EvoFlow/skills/public/expert-wx-mp/tools/wx-mp-publisher/scripts/*.py 2>/dev/null || echo "无独立 py 或语法见报告"
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/expert-wx-mp || echo CLEAN
```

Expected: relay 引用如实保留（环境前置已声明其条件性）；`CLEAN`。

- [ ] **Step 3: 同步 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/expert-wx-mp/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-wx-mp
git commit -m "feat(skills): 移植 expert-wx-mp（批次2，relay 发布 + business_knowledge 载重 + 作者参数化）"
```

---

### Task 11: expert-xhs

**Files:**
- Create: `skills/public/expert-xhs/`（507K，44 文件，自 `/e/xiaobei-app/crews/main/skills/`）
- Modify: SKILL.md + workflows/ + tools/ 内各 SKILL.md（清洗配方）

**Interfaces:**
- Consumes: xhs 直连 HTTP（自有 xhs_utils/xhs_creator）、relay 签名（OFB_KEY）、`~/.openclaw/logins/xhs-creator-local.json` 与 `xhs-pc-local.json`（0600，共享决策）、published-track（6 处）、`$EVOFLOW_MEDIA_WS/business_knowledge.md`（载重）
- Produces: 小红书运营专家（xhs-publish/engagement/pugongying/qianfan/style-profiler）

- [ ] **Step 1: 拷贝 + 清洗**

```bash
cp -r /e/xiaobei-app/crews/main/skills/expert-xhs E:/EvoFlow/skills/public/expert-xhs
```

SKILL.md 与 workflows/、tools/ 下文档清洗按配方；business_knowledge 引用按约定改写（载重，同 Task 10 措辞）；环境前置：OFB_KEY/RELAY_BASE_URL 行（publish 签名依赖）+ 会话文件行（`~/.openclaw/logins/xhs-creator-local.json` 等，与 xiaobei 共享）+ published-track 行。

- [ ] **Step 2: 语法核验 + 残留检查**

```bash
PYTHONUTF8=1 python3 -m py_compile $(find E:/EvoFlow/skills/public/expert-xhs -name "*.py" | head -20) && echo PY-OK
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/expert-xhs || echo CLEAN
```

Expected: `PY-OK`（如个别脚本确缺第三方依赖导入，py_compile 层不该报——报了就查）；`CLEAN`。

- [ ] **Step 3: 同步 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/expert-xhs/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-xhs
git commit -m "feat(skills): 移植 expert-xhs（批次2，直连 HTTP + relay 签名 + 会话共享）"
```

---

### Task 12: expert-video

**Files:**
- Create: `skills/public/expert-video/`（655K 排除 node_modules，自 `/e/xiaobei-app/crews/content-producer/skills/expert-video`）
- Modify: SKILL.md + tools/*/SKILL.md（清洗配方）；计划外脚本编辑（ASR 路径改链）须申报

**Interfaces:**
- Consumes: 公共 `_shared/asr.py` 路由（原走 `OPENCLAW_STATE_DIR/~/.openclaw/skills/_shared`，需按 viral-chaser 先例改链到 `skills/public/_shared`）、`VOLC_ASR_*` 或 `WORKSPACE_ID`+`MODELSTUDIO_API_KEY`/`DASHSCOPE_API_KEY` 或 `AWK_API_KEY`、ffmpeg、deck-render（node，重建依赖）
- Produces: 视频制作专家（video-producer 25 脚本 + deck-render + liveportrait）；video-review 为强制自检闸门

- [ ] **Step 1: 白名单拷贝（排除 node_modules）**

```bash
SRC=/e/xiaobei-app/crews/content-producer/skills/expert-video
DST=E:/EvoFlow/skills/public/expert-video
mkdir -p "$DST"
cp -r "$SRC"/{SKILL.md,references,tools,workflows} "$DST/" 2>/dev/null || cp -r "$SRC"/* "$DST"/
# 若 tools/deck-render 等被整拷带出 node_modules，删除：
find "$DST" -type d -name node_modules | while read -r d; do echo "removing $d"; rm -rf "$d"; done
du -sh "$DST"
```

Expected: 655K 量级（非 399M）。

- [ ] **Step 2: deck-render 重建依赖**

```bash
cd E:/EvoFlow/skills/public/expert-video/tools/deck-render && npm ci 2>&1 | tail -2
ls node_modules/@google/genai >/dev/null && echo DECK-DEPS-OK
```

若 npm ci 因平台差异失败，改 `npm install` 并记录。Expected: `DECK-DEPS-OK`。

- [ ] **Step 3: ASR 路径改链（计划外编辑，申报）**

定位 expert-video 内引用公共 `_shared/asr.py` 的解析逻辑（survey 指出经 `OPENCLAW_STATE_DIR`/`~/.openclaw/skills/_shared`）：

```bash
grep -rn "OPENCLAW_STATE_DIR\|skills/_shared\|\.openclaw" E:/EvoFlow/skills/public/expert-video --include="*.py" --include="*.mjs" --include="*.ts" | head -10
```

按 viral-chaser `transcriber.ts` 先例改链：`EVOFLOW_ASR_SCRIPT` 环境变量优先 → 仓库相对 `../../_shared/asr.py`（按脚本实际深度核算）→ `~/.evoflow/skills/public/_shared/asr.py`。每处改动在报告中申报（文件:行 + 前后形态）。同样处理 volc_asr/bailian_asr 的伴生引用（与 asr.py 同目录）。

- [ ] **Step 4: SKILL.md 清洗 + 语法核验 + 残留检查**

SKILL.md 与 tools 文档按清洗配方；环境前置：ffmpeg 行 + python3 行 + ASR 密钥链行（`VOLC_ASR_*` 或 `WORKSPACE_ID`+`MODELSTUDIO_API_KEY`/`DASHSCOPE_API_KEY` 或 `AWK_API_KEY`；缺失时 exit 2 引导）+ video-review 强制闸门说明 + deck-render 行（node）；crew AGENTS.md 的乙方角色引用删除（角色文本已内联）。

```bash
PYTHONUTF8=1 python3 -m py_compile $(find E:/EvoFlow/skills/public/expert-video/tools/video-producer -name "*.py") && echo PY-OK
grep -rn "openclaw\|DECLARED_SKILLS\|crew" E:/EvoFlow/skills/public/expert-video --include="*.md" || echo CLEAN
```

- [ ] **Step 5: 同步 + Commit**

```bash
cp -r E:/EvoFlow/skills/public/expert-video/ /c/Users/yebin/.evoflow/skills/public/
git add skills/public/expert-video
git commit -m "feat(skills): 移植 expert-video（批次2，deck-render 重建 + ASR 路径改链）"
```

（`.gitignore` 如需 expert-video node_modules 忽略行，在本次一并追加并申报。）

---

### Task 13: 批次 2 验收门

**Files:** 无新文件（验收门）

- [ ] **Step 1: 运行实例可见全部新技能**

```bash
curl -s http://localhost:8012/api/skills > /tmp/skills.json
for n in video-review bgm-library awk-img-gen aigc-video-gen tiktok-hunter kuaishou-hunter x-hunter weibo-hunter weibo-publish douyin-hunter xhs-hunter wx-mp-hunter zhihu-publish wxwork-moments expert-kuaishou expert-tiktok expert-twitter expert-douyin expert-wx-channel expert-wx-mp expert-xhs expert-video; do
  grep -q "\"$n\"" /tmp/skills.json && echo "OK  $n" || echo "MISS $n"
done
```

Expected: 22 行全 OK（含 Task 1 之外的 21 技能；若某项 MISS 查同步目录）。

- [ ] **Step 2: 残留总检**

```bash
grep -rln "DECLARED_SKILLS" E:/EvoFlow/skills/public/ || echo ALL-CLEAN
grep -rn "metadata:" E:/EvoFlow/skills/public/{video-review,bgm-library,awk-img-gen,aigc-video-gen,tiktok-hunter,kuaishou-hunter,x-hunter,weibo-hunter,weibo-publish,douyin-hunter,xhs-hunter,wx-mp-hunter,zhihu-publish,wxwork-moments,expert-kuaishou,expert-tiktok,expert-twitter,expert-douyin,expert-wx-channel,expert-wx-mp,expert-xhs,expert-video}/SKILL.md 2>/dev/null | head
```

Expected: `ALL-CLEAN`；第二条无 openclaw metadata 残留（各 SKILL.md 顶层）。

- [ ] **Step 3: 受限能力清单产出**

基于 Task 1 的 `.env.xiaobei-keys` 实际内容，列出批次 2 中因缺密钥受限的技能及所需变量（预期：`OFB_KEY` 缺失 → expert-wx-mp 发布/wxwork-moments/expert-xhs 发布签名/expert-douyin fetch-retro-data 受限；`WX_BIZ_*` 缺失 → wx-mp-hunter 不可用；ASR/生图密钥视 `.env` 现状）。写入报告，供用户决定是否补配。

- [ ] **Step 4: 收尾记录**

spec §4 批次表标注批次 2 状态 + §4.1 追加实测记录（受限清单、计划外编辑汇总、发现的问题），提交：

```bash
git add docs/superpowers/specs/2026-10-26-xiaobei-skills-port-design.md
git commit -m "docs(spec): 批次2 移植完成记录"
```
