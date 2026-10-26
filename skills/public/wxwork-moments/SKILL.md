---
name: wxwork-moments
description: Publish content (text + images/video/link) to WeChat Work (企业微信) customer
  moments via relay. Credentials (corp_id + corp_secret) read from the environment
  and passed per-request; relay is stateless.
---

# WeChat Work Moments Publisher（企业微信朋友圈发布）

经 relay 透传凭据发布企业微信客户朋友圈。

## 环境前置（EvoFlow）

- `python3` 可用（wrapper `wxwork-moments.sh` → `scripts/post_moments.py`，纯标准库；图片自动规范化用到 PIL 时可选）
- 需 `RELAY_BASE_URL`（默认 relay.openclaw-for-business.com）+ `OFB_KEY` + `WXWORK_CORP_ID` + `WXWORK_CORP_SECRET`（凭据由 relay 服务端校验与剥离）；`OFB_KEY` 未配置时本技能不可用——写入 `.env.xiaobei-keys` 后自动解锁

---

## 凭据与存储位置

- **企业微信凭据** `WXWORK_CORP_ID` + `WXWORK_CORP_SECRET` 由环境变量注入（EvoFlow 下写入 `.env.xiaobei-keys`，重启 start-dev 后生效；朋友圈 + 微盘共用）。
- **relay 身份** `OFB_KEY` + `RELAY_BASE_URL` 同样来自环境变量注入。

### 凭据缺失时 Agent 行为

1. 若 `WXWORK_CORP_ID` / `WXWORK_CORP_SECRET` 未配置：**先读同目录 `REFERENCE.md`**，按其中的步骤指导用户获取企业 ID + 应用 Secret（含 relay 可信 IP `123.60.18.144` 的配置、微盘 / 客户联系权限开通）。
2. 收到值后，由**用户**写入 `.env.xiaobei-keys`（EvoFlow 密钥桥，git-ignored），重启 start-dev 后生效。
3. 若 `OFB_KEY` 未配置：同样由用户写入 `.env.xiaobei-keys`（`OFB_KEY` 是 relay 服务方签发的会员凭证，需向服务方索取）。

---

## 发布命令

通过 PATH 调用 wrapper：`wxwork-moments "<正文>" [附件...]`，无需拼接脚本路径。

### 纯文字

```bash
wxwork-moments "正文内容"
```

### 图文（最多 9 张图）

```bash
wxwork-moments "正文内容" /path/to/img1.jpg /path/to/img2.png
```

### 视频（1 个，≤ 30 秒，≤ 10MB）

```bash
wxwork-moments "正文内容" /path/to/video.mp4
```

### 图文链接（必须传封面图）

> ⚠️ 链接模式**必须**附封面图，否则发布失败。

```bash
wxwork-moments "推荐阅读" --link https://example.com/article "文章标题" /path/to/cover.jpg
```

---

## Agent 行为约束

> 以下规则**严格执行**，不得跳过。

1. **等待脚本完整返回后**再进行下一步，脚本包含上传和发布两个网络请求，耗时可能超过 10 秒，期间告知用户"正在上传素材 / 正在发布……"，**禁止**在脚本结束前自行拼接其他 curl 命令。
2. 脚本已处理凭据读取、素材上传、发布等全部步骤，**无需**手动执行任何中间步骤。
3. 脚本输出最后一行若以 `✓` 开头表示成功；以 `✗` 开头表示失败，需将错误信息完整告知用户。
4. 正文中不要包含换行 "\n"，wxwork api 不能解析 "\n"。

---

## 附件限制速查

| 附件类型 | 限制 |
|---------|------|
| 图片（jpg/png/gif） | 最多 9 个 |
| 视频（mp4/mov）     | 最多 1 个，时长 ≤ 30 秒，大小 ≤ 10MB |
| 图文链接            | 最多 1 个，可附 1 张封面图 |
| 图片与视频/链接      | 不可同时存在 |

---

## Error Handling

| 错误信息 | 原因 | 处理 |
|---------|------|------|
| `WXWORK_CORP_ID / WXWORK_CORP_SECRET 未配置` | 密钥源缺凭据 | 按 `REFERENCE.md` 引导用户获取，写入 `.env.xiaobei-keys` + 重启 |
| `OFB_KEY 未配置` | 密钥源缺 OFB_KEY | 向 relay 服务方索取后写入 `.env.xiaobei-keys` 重启 |
| `MISSING_CORP_CREDENTIALS`（relay 400） | 请求体缺 corp_id/corp_secret | 检查 `.env.xiaobei-keys` 是否生效（需重启 start-dev） |
| `GETTOKEN_FAILED`（relay 502） | corp_secret 错或 corp_id 不存在 | 核对凭据；按 `REFERENCE.md` 重新获取 |
| `no privilege` | 应用未开通客户联系权限 | 按 `REFERENCE.md` 第 3 步开通 |
| `41081 media's resolution invalid` | 图片分辨率不合规（非 RGB / 过小 / 过大） | 脚本已自动规范化（RGB 转换 + 分辨率调整），若仍失败检查图片是否损坏 |
| `图片最多 9 张` | 超出数量限制 | 减少传入文件数量 |

---

## Notes

- 朋友圈任务创建成功后，指定员工会在企业微信中收到一键发布提醒
- `moment_id` 可用于后续在企业微信管理后台（客户联系 → 客户朋友圈）查询发布状态
- 临时素材（media_id）有效期 **3 天**，脚本每次发布时重新上传，无需手动管理
- relay 在转发给企业微信前会剥离 `corp_id` / `corp_secret`，不下发

---

企业微信朋友圈分发无需执行 `published-track` 相关操作。
