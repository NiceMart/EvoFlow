# xiaobei 自媒体运营技能移植 EvoFlow — 设计文档

日期：2026-10-26
状态：已与需求方确认（方案 A：技能栈直移 + 薄适配层）

## 1. 背景与目标

xiaobei（OpenClaw 体系，运行时工作区 `E:\xiaobei-data\workspace-<agent>\skills\`，技能源头 `E:\xiaobei-app\crews\`）沉淀了一套自媒体运营技能。需求方要求把以下 17 项能力移植到 EvoFlow 的技能体系（`E:/EvoFlow/skills/public/`）：

1. 微信公众号文章写作、排版与推送
2. 小红书/小绿书图文创作与发布
3. 图文海报生成
4. 视频生成与多平台分发（视频号、抖音、小红书、快手、TikTok）
5. Twitter/X、微博、知乎等平台发文
6. 微信朋友圈内容发布（企业微信接口）
7. 爆款视频追爆分析、仿写与再创作
8. 赛道头部账号 DNA 级复刻（小红书、视频号、抖音、公众号）
9. 已发布作品数据监控与每日定时复盘
10. 自媒体评论区获客
11. 7×24 小时智能客服（售前接待）
12. 社交媒体找潜客/市场调研
13. 信息搜集与情报（多平台信源，免 key 纯免费路线）
14. 「四声分析」战略研判（= council 四方视角辩论）
15. 产品 deck/PPT、投资/IR 材料
16. 网站设计与制作、ICP 备案材料
17. （支撑能力）全平台内容采集层

**定位**：先自用后产品化——移植时不硬编码本机路径，但暂不做安装包/跨平台适配。

## 2. 总体方案（方案 A：技能栈直移 + 薄适配层）

xiaobei 技能本就是 SKILL.md + 脚本的标准 Agent Skills 结构，与 EvoFlow `skills/public/` 格式天然兼容。移植 = 近乎原样拷贝 + 一层薄适配，不重写方法论，不把平台脚本改写为 agent-browser。

否决的备选：
- 方案 B（方法论重写为 agent-browser 原生）：工作量 5–10 倍，CDP 指纹被平台风控风险大；
- 方案 C（经 openclaw 网关桥接）：双系统耦合，不可持续。

**浏览器层策略（混合）**：方法论类技能直搬；平台操作脚本继续调用 `camoufox-cli`（反检测 Firefox，本机已有安装与平台登录态）。

## 3. 需求 → 源技能映射

| # | 需求 | 源技能 | 说明 |
|---|------|--------|------|
| 1 | 公众号 | `expert-wx-mp` | 含 wx-mp-publisher、generate-wenyan-theme、wechat-style-profiler、wx-mp-engagement；小绿书在 expert-wx-mp 内 |
| 2 | 小红书/小绿书 | `expert-xhs` | 含 xhs-publish / xhs-pugongying / xhs-qianfan |
| 3 | 海报 | `expert-design` + 公共 `awk-img-gen` | expert-design 在 content-producer crew |
| 4 | 视频生成分发 | `expert-video`、`expert-douyin/kuaishou/tiktok/wx-channel`（发布工具）+ 公共 `aigc-video-gen` | |
| 5 | X/微博/知乎发文 | `expert-twitter`、`weibo-publish`、`zhihu-publish`、`x-hunter`、`weibo-hunter` | |
| 6 | 朋友圈 | `wxwork-moments` | |
| 7 | 追爆分析 | `viral-chaser` | |
| 8 | DNA 复刻 | 各 expert-* 内置 style-profiler 工具 | 随 expert-* 一并搬，无需单独动作 |
| 9 | 数据监控/复盘 | `published-track` + `content-calibrator` | 另挂 EvoFlow 定时任务，见 §5.3 |
| 10 | 评论区获客 | `expert-bd` | 含 douyin-interact、xhs-im 等互动工具 |
| 11 | 智能客服 | `sales-cs` crew 四件套（customer-db/demo-send/exp-invite/proactive-send）+ `sales-cs-manager` | |
| 12 | 潜客/调研 | `expert-bd` + `expert-osbi` | |
| 13 | 信源情报 | `smart-search` + 各 `*-hunter` + `expert-osbi` | cookie 登录态免 key |
| 14 | 四声分析 | `council` | 四方视角结构化辩论 |
| 15 | deck/IR | `pitch-deck` + `expert-ir` | |
| 16 | ~~网站/ICP~~ | ~~`icp-filing`、`icp-exemption`、`seo`~~ | **已取消（2026-10-27，随批次 4 取消）**——原注：网站设计与制作无独立技能，xiaobei 靠 awada 建站插件 + expert-design 承载 |
| 17 | 采集层 | `douyin/xhs/tiktok/kuaishou-hunter`、`wx-mp-hunter` | |

另有 `talking-head-cut`、`video-edit`、`platform-runtime`、`_shared`（共享 Python 库）随批移植。合计约 **33 个技能 + 2 个共享库**。

**技能名策略**：保留原名称——`expert-*` 之间有大量交叉引用，改名会断链；仅清洗 openclaw 痕迹（见 §5.2）。

## 4. 分批计划（按依赖顺序）

| 批次 | 内容 | 验收 | 状态 |
|------|------|------|------|
| 0·地基 | `_shared`、`platform-runtime`、`published-track`、`smart-search` + 薄适配层（§5） | `published-track init-db` 成功；smart-search 真实搜索一次，验证 camoufox 链路与 cookie 复用 | 已完成（2026-10-26，smart-search 真搜延后至用户会话） |
| 1·纯方法论 | `council`、`viral-chaser`、`expert-design`、`pitch-deck`、`talking-head-cut`、`video-edit`、`content-calibrator` | agent 各调用一次完成真实小任务（如出一版 deck） | 已完成（2026-10-26，交互实测延后至用户会话） |
| 2·平台运营 | 7 个 `expert-*` + 7 个 `*-hunter` + `weibo/zhihu-publish` + `expert-video` + `wxwork-moments` | 每技能先跑只读命令（采集一条/读 DNA 模板），选 1–2 个做真实发布冒烟 | 已完成（2026-10-26，实落 22 技能含 video-review/bgm-library/awk-img-gen/aigc-video-gen 四助手；零成本只读冒烟已做，真实发布冒烟延后至用户会话） |
| 3·商业闭环 | `expert-bd`、`expert-osbi`、`expert-ir`、`sales-cs` 五件套 + 每日复盘定时任务 | 客服链路 dry-run；复盘任务按期触发一次 |
| ~~4·it-engineer~~ | ~~`icp-filing`、`icp-exemption`、`seo`、`tccli`、`alicloud-find-skills`、`camoufox-guard`~~ | **已取消（2026-10-27，需求方裁定暂不需要）**——映射表 #16（网站设计与制作、ICP 备案材料）随之取消；`camoufox-guard` 巡检能力一并取消，进程巡检改由人工/按需处理 |

### 4.1 批次 0+1 实测记录（2026-10-26）

- 验收：网关 `GET /api/skills` 7/7 技能名命中（council/viral-chaser/pitch-deck/talking-head-cut/video-edit/expert-design/content-calibrator）；`DECLARED_SKILLS` 残留 ALL-CLEAN；各 SKILL.md 无 openclaw metadata 残留。
- 延后项（需用户 EvoFlow 会话交互实测）：council 辩论、video-edit 抽段、pitch-deck 出稿、smart-search 真搜、content-calibrator 真数据评估。
- 环境发现：本地 sqlite3 3.54.1 落 `.tools/`（已 gitignore）；published_track DB 全新建 17 表；网关启动需 `UV_NO_SYNC=1` + `EVOFLOW_SKIP_CONFIG_UPGRADE=1` 规避。
- 补充：viral-chaser 转写依赖的 ASR 三件库补拷入顶层 `_shared`（15c5d0ac）。
- 残留修正：platform-runtime SKILL.md 残留的 `metadata.openclaw` frontmatter 块已在验收时移除（ed373663）。
- 终审修复：EVOFLOW_MEDIA_WS 未设时改 fail-fast（原 3 级回落在 EvoFlow 布局指向 skills/ 源码树，有污染风险）。
- 决策记录：platform-runtime/_shared 中 ~/.openclaw 登录态默认值本阶段保留——本机与 xiaobei 共享平台登录态是「零迁移复用」意图；产品化阶段统一 re-home 到 ~/.evoflow。

### 4.2 批次 2 实测记录（2026-10-26）

- 验收：网关 `GET /api/skills` 22/22 技能名命中（video-review/bgm-library/awk-img-gen/aigc-video-gen/tiktok-hunter/kuaishou-hunter/x-hunter/weibo-hunter/weibo-publish/douyin-hunter/xhs-hunter/wx-mp-hunter/zhihu-publish/wxwork-moments/expert-kuaishou/expert-tiktok/expert-twitter/expert-douyin/expert-wx-channel/expert-wx-mp/expert-xhs/expert-video）；`DECLARED_SKILLS` 残留 ALL-CLEAN；22 个 SKILL.md 无 openclaw metadata 残留。
- 只读冒烟范围：按裁定仅零成本命令（--help/--check/live `--access read`），未做真实发布/生成/登录；真实采集/发布冒烟延后至用户会话（与批次 0/1 同口径）。
- 受限能力清单（`.env.xiaobei-keys` 现仅 `AWK_API_KEY` 一项存量；以下缺配解锁后即自动可用）：
  - `OFB_KEY` 缺失 → expert-wx-mp 发布（relay）、wxwork-moments、expert-xhs 发布签名、expert-douyin fetch-retro-data 受限；采集层 douyin-hunter（login 及依赖会话子命令）、xhs-hunter（全部平台请求类子命令，签名走 relay）同受波及。
  - `WX_BIZ_*` 缺失 → wx-mp-hunter 不可用。
  - `WXWORK_CORP_ID`/`WXWORK_SECRET` 缺失 → wxwork-moments 双密钥缺口（叠加 OFB_KEY）。
  - ASR/生图现状：`AWK_API_KEY` 已桥接可用（awk-img-gen plan 模式、aigc-video-gen 百炼 agent plan 兜底，Task 2 验证）；`DASHSCOPE_API_KEY`（业务空间模式）、`MINIMAX_API_KEY`（bgm-library 定制音乐/aigc-video-gen music 与 minimax 视频路线）、`VOLC_SEEDANCE_API_KEY`（火山路线）缺失，相关子能力受限属预期非移植缺陷。
- 计划外编辑汇总：fcntl shim 扩展（Task 8 expert-douyin ×2、Task 11 expert-xhs ×3）；`_shared/bailian_media.py` 补拷（Task 12，批次 0 漏项）；batch-i2v 解析本地路径优先（Task 12）；各 wrapper/SKILL.md 注释清洗超纲项。
- 验收门发现并修复：`.env.xiaobei-keys` 与 `start-dev.bat` 原为 LF-only 行尾——cmd `for /f "usebackq ..."` 实测从 LF-only 文件读 0 行（CRLF 对照组正常读 1 行），真实重启时密钥桥会静默失效；且 `start-dev.bat` 含 `goto wait_vite` 标签循环，LF-only bat 有解析风险。两文件已转 CRLF 并隔离 cmd 复测 for /f 注入 `AWK_API_KEY` 成功。两文件均不入库（bat 未跟踪、keys 已 gitignore），无提交内容变化。
- 重启验证按裁定保留运行中栈：网关 19:53 启动早于 bat 最后编辑（21:29），未杀进程；真实重启验证由用户下次 `start-dev.bat` 启动自然覆盖（CRLF 修复后注入链路已隔离验证）。
- 未移植项：`native-ui-card` 不在规格映射内，未移植——是否补移待用户决策。

## 5. 薄适配层

### 5.1 环境变量（有默认回落，不硬编码）

| 变量 | 作用 | 初版默认值 |
|------|------|-----------|
| `CAMOUFOX_CLI` | 浏览器层入口；`_shared/browser_publish_text.py` 已用 `os.environ.get('CAMOUFOX_CLI', 'camoufox-cli')` | PATH 中的 `camoufox-cli`（本机已有 wrapper：`~/.openclaw/bin/`） |
| `EVOFLOW_MEDIA_WS` | 平台数据根：`db/published_track.db`、cookie 库等相对路径的基准目录 | `E:/xiaobei-data/workspace-main`（直接复用现有登录态与指标库，零迁移） |
| `PYTHONUTF8` | Windows 中文脚本防坑 | `1` |

产品化阶段：`EVOFLOW_MEDIA_WS` 默认值改为 `~/.evoflow/media-data` 并在安装包初始化，技能本体零改动。

### 5.2 SKILL.md 清洗规则（每批次执行）

- 删除 `metadata.openclaw` frontmatter、DECLARED_SKILLS / crew 声明段落；
- 「crew / main agent / openclaw」措辞 → 「EvoFlow agent」；
- 保留全部技能名与交叉引用；
- 每个 SKILL.md 头部加「环境前置」段：camoufox-cli、ffmpeg、Python 依赖的检查命令。

### 5.3 每日定时复盘

`published-track`（指标回填）+ `content-calibrator`（DNA 评估）入位后，用 EvoFlow 网关定时任务（automation_runner）每日触发复盘 prompt → 调用 content-calibrator。技能本体不感知定时机制。

### 5.4 落地位置

`E:/EvoFlow/skills/public/`（自用阶段直接生效；产品化时随 EvoFlow skill pack 打包）。

## 6. 非目标（本期不做）

- camoufox → agent-browser 的脚本重写；
- 安装包 / 跨平台（非 Windows）适配；
- awada 建站能力引入（待需求方确认）；
- platform 登录态迁移到 `~/.evoflow`。

## 7. 风险

| 风险 | 缓解 |
|------|------|
| 平台风控对 camoufox 会话异常 | 沿用 xiaobei 既有 cookie 库与指纹模板，不新建会话 |
| `_shared` Python 依赖版本漂移 | xiaobei `requirements.txt` 随批次 0 一起记录并核对 |
| openclaw 概念残留误导 agent | 批次清洗规则 + 验收时抽查 SKILL.md |
| EvoFlow 与 openclaw 同时跑 camoufox 进程冲突 | `camoufox-guard`（批次 4）可提前移植到批次 0 作为巡检工具 |
