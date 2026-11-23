# noop 镜像仓库

本仓库**不存储上游代码**，只存放自动镜像构建的 Dockerfile 与工作流。上游代码来自 [huacnlee/noop](https://github.com/huacnlee/noop)，每次构建按上游 main 分支的锁定 commit 拉取源码。

## 工作流

- `.github/workflows/image.yml` 每 6 小时比对上游 `main` 的最新 commit sha 与 `upstream.json` 记录的上次构建值。
- 有变化时：锁定该 sha 拉取源码 → `bun install --frozen-lockfile && bunx tsc --noEmit` → 构建 `linux/amd64` 镜像 → 推送 `ghcr.io/dockers-x/noop:<版本>` 与 `:latest` → 把 sha 和版本写回 `upstream.json`。
- 版本号跟随上游 `app/nsh.json` 的 `version`；上游代码变动但版本号未变时用 `<版本>-<日期>` 兜底，避免 tag 冲突。
- 无变化时跳过构建；也可用 `workflow_dispatch` 的 `force` 输入强制构建。
- 镜像内容是 noop 服务端（bun daemon）：任务编排、agent 调度、本地聊天 API + Web 聊天页（8787 端口）。真正的 AI agent 运行时（claude/codex CLI）由用户在容器内登录配置。
