# syntax=docker/dockerfile:1
# Noop 服务端镜像：上游无官方 Docker 发布，直接从源码构建。
# 运行时 = bun daemon（src/cli.ts daemon）：任务编排、agent 调度、本地聊天 API + Web 聊天页（8787）。
# 构建上下文根目录需包含 checkout 出来的上游源码（upstream/）。
FROM oven/bun:1.4-debian AS build

WORKDIR /noop
COPY upstream/ ./

# 生产依赖极少（仅 devDependencies），--frozen-lockfile 保证与 bun.lock 一致
RUN bun install --frozen-lockfile \
    && bunx tsc --noEmit

FROM debian:12-slim

# daemon 及其 agent 的运行时依赖：git（self-update / 数据仓库 / gh 操作）、gh（GitHub 集成，可选但常用）、
# ca-certificates + curl（web 客户端下载与网络）、tini（信号转发：daemon 优雅排水退出）
RUN apt-get update \
    && apt-get install -y --no-install-recommends git gh ca-certificates curl tini \
    && rm -rf /var/lib/apt/lists/*

# bun 运行时从构建阶段拷贝（oven/bun 是完整 Debian，静态二进制在 /usr/local/bin/bun）
COPY --from=build /usr/local/bin/bun /usr/local/bin/bun

WORKDIR /noop
COPY --from=build /noop /noop
ENV PATH="/noop/bin:${PATH}" \
    NOOP_HOME=/lzcapp/var/noop \
    HUB_DATA=/lzcapp/var/noop/data \
    NOOP_CLIENT_BASE_URL=https://github.com/huacnlee/noop/releases/latest/download

EXPOSE 8787
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bun", "/noop/src/cli.ts", "daemon"]
