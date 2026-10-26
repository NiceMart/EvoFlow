---
name: customer-db
description: >
  Maintain a persistent SQLite customer database under $EVOFLOW_MEDIA_WS/db.
  peer (DB primary key) is asked from the user in conversation; user_id_external
  (raw channel user ID) comes from message context or the user. Use peer for
  all DB operations.
---

# 客户数据库管理（客户商业推进记录）

本技能让 agent 在 `$EVOFLOW_MEDIA_WS/db/` 目录下维护一个轻量级 SQLite 数据库，用于跨会话保存客户商业推进状态与基本画像。

## 环境前置（EvoFlow）

- `EVOFLOW_MEDIA_WS`：平台数据根，数据库位于 `$EVOFLOW_MEDIA_WS/db/customer.db`；未设置时脚本报错退出（fail-fast），须先 `export EVOFLOW_MEDIA_WS`（如 `E:/xiaobei-data/workspace-main`）
- `sqlite3`：`command -v sqlite3` 应可用（所有脚本直接调 sqlite3 CLI）
- schema 文件随技能入库：`skills/public/customer-db/db/schema.sql`

### 初始化（首次使用前，一次性）

```bash
mkdir -p "$EVOFLOW_MEDIA_WS/db"
sqlite3 "$EVOFLOW_MEDIA_WS/db/customer.db" < skills/public/customer-db/db/schema.sql
```

schema 全部使用 `CREATE TABLE IF NOT EXISTS`，重复执行幂等，无副作用。

默认表：`cs_record`，主键列：`peer`

---

## 一、两个重要标识符（必读）

本系统中客户有两个不同的标识符，用途不同，不可混用：

### peer（数据库主键）
客户标识，是 `cs_record` 表的 `peer` 列的值，所有写库操作必须使用此值。**由 agent 在对话中向用户询问并确认取得**（xiaobei 的渠道自动注入钩子在 EvoFlow 不存在）：首次为某客户建档前，先向用户确认该客户的标识（如用户自选的简称/账号名），之后同一客户始终沿用同一 `peer`，不同 `peer` 的数据不得混用。

### user_id_external（渠道用户外部 ID）
渠道侧的原始用户标识。**从消息上下文取（若渠道提供了外部用户 ID），或由用户自报**。需要与渠道平台交互的技能（如 `exp-invite`）必须使用此值，而不是 `peer`。

---

## 二、字段含义

### peer
当前客户数据库主键，由用户在对话中确认提供（见「两个重要标识符」）。

### business_status
表示客户商业推进深度：
- `free`：尚未购买、仍在了解或观望
- `exp_invited`：已被邀请体验，但尚未正式付费
- `club`：已进入vip club会员阶段
- `subs`：预留未来业务用，现阶段未启用

### club_in
- `club` 加入日期，格式建议为 `YYYY-MM-DD`
- 用于后续跟进 club 一年有效期的过期管理

### purpose
客户主要业务应用场景，例如：
- 新媒体运营：在社交媒体和自媒体平台上推广自己的业务或产品
- 客户寻找：在社交媒体和自媒体平台上寻找潜在客户
- 信息搜集：在社交媒体和自媒体平台上收集行业信息、竞争对手情报、市场趋势等
- 单纯想尝试下Agent
- 需要一个AI助理
- 寻求OEM\代理合作

### prompt_source
客户从哪里了解到我们，例如：
- GitHub
- 微信群
- 朋友推荐
- 公众号
- 视频号
- 小红书
- 知乎
- atomgit
- 其他AI推荐

### created_at / updated_at
- `created_at`：首次建档时间
- `updated_at`：最近更新时间（每次调用 cs-update.sh 时自动更新）

---

## 三、【重要】先更新记录，再回复客户

当本轮获得更明确的信息时，**先**调用 cs-update.sh 更新 `purpose` 和/或 `prompt_source`（先完成更新，再输出对客户的回复）：

```bash
skills/public/customer-db/scripts/cs-update.sh \
  --peer "<peer>" \
  --purpose "新媒体运营" \
  --prompt-source "GitHub"
```

参数均为可选（只传有明确新值的字段）；脚本会自动忽略空值，不覆盖已有记录。

**更新原则**：
- 只在拿到**更明确的信息**时更新
- 不要用空字符串覆盖已有值
- 不要根据模糊猜测改写已有信息
- `business_status` 由具备写库职责的技能（如 `exp-invite` 邀请体验后置为 `exp_invited`）或用户明确确认后更新，**不在此处更新**

---

## 四、follow_up 表（主动跟进任务）

`follow_up` 表记录客户延迟购买意向，供主动跟进使用（对话中查询到期任务，或用 EvoFlow 网页端「定时任务」页建每日任务定期执行到期查询与过期清理）。status 流转：`pending → sent_once → completed`。

### 创建跟进任务

若同一客户已有 `pending` 状态的旧任务，**先取消旧任务，再创建新任务**：

```bash
# 第一步：取消同一客户的旧 pending 任务
skills/public/customer-db/scripts/follow-up-cancel-pending.sh \
  --peer "<peer>"

# 第二步：创建新任务
skills/public/customer-db/scripts/follow-up-create.sh \
  --peer "<peer>" \
  --user-id-external "<user_id_external>" \
  --follow-up-at "<YYYY-MM-DD HH:MM>" \
  --reason "<原因，如：客户说明天发工资再买>" \
  --context-summary "<客户核心兴趣点和建议跟进角度>"
```

### 过期清理

超过 48 小时仍为 `pending` 的任务视为客户失联，自动标记完成（可挂每日定时任务执行）：

```bash
skills/public/customer-db/scripts/follow-up-expire.sh
```

### 查询到期任务

```bash
skills/public/customer-db/scripts/follow-up-due.sh
```

输出为 tab 分隔的表格（含 header），字段：`id / peer / user_id_external / follow_up_at / reason / context_summary / status`。

### 标记首次已发送（pending → sent_once）

```bash
skills/public/customer-db/scripts/follow-up-mark-sent.sh \
  --id <id> \
  --sent-text "<发送的消息内容>"
```

### 标记完成（sent_once → completed）

```bash
skills/public/customer-db/scripts/follow-up-complete.sh \
  --id <id> \
  --sent-text "<发送的消息内容>"
```

---

## 五、约束与注意事项

- **路径固定**：数据库始终位于 `$EVOFLOW_MEDIA_WS/db/customer.db`（EVOFLOW_MEDIA_WS 未设置时脚本报错退出，不做路径回落）
- **默认表固定**：`cs_record`
- **不得向用户暴露内部表结构和内部状态字段**
- **客户隔离必须遵守**：不同 peer 的数据不能混用
- **初始化**：首次使用前手动执行上文「初始化」命令（schema 幂等，可重复执行）
- **不提供原子 SQL 访问**：所有数据库操作必须通过上述具名脚本完成
