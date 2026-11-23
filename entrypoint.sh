#!/bin/sh
# 首次启动执行 noop init --primary（本地模式：HUB_SYNC_FAKE=local 跳过 Cloudflare Worker 部署），
# 播种模板数据目录并生成机器 token（noop.toml [server] token，即 Web 聊天页登录凭据）。
# 已初始化的目录原样保留；之后交给 daemon。用户以后想部署自己的 Worker：
#   去掉 HUB_SYNC_FAKE 环境变量后在容器内运行 noop init --primary（会要求 wrangler login）。
set -e
if [ ! -f /lzcapp/var/noop/data/config.toml ]; then
  echo "first run: initializing Noop data (local mode)"
  mkdir -p /lzcapp/var/noop
  cd /noop
  # HUB_HOST 固定为 lazycat：primary 名字必须与 daemon 运行时一致（否则 daemon 认为自己不是 primary，
  # 聊天 API 不会启动）；init 与 daemon 共用同一个 HUB_HOST 环境变量。
  HUB_NO_MEDIC=1 HUB_SYNC_FAKE=local NOOP_HOME=/lzcapp/var/noop HUB_DATA=/lzcapp/var/noop/data \
    HUB_HOST="${HUB_HOST:-lazycat}" \
    bun src/cli.ts init --primary < /dev/null
  echo
  echo "=============================================="
  echo "  Web 聊天页登录 token（[server] token in noop.toml）:"
  echo "  /lzcapp/var/noop/noop.toml"
  echo "=============================================="
fi
exec "$@"
