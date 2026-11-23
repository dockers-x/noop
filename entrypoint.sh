#!/bin/sh
# 首次启动执行 noop init --primary（本地模式：HUB_SYNC_FAKE=local 跳过 Cloudflare Worker 部署），
# 播种模板数据目录并生成机器 token（noop.toml [server] token，即 Web 聊天页登录凭据）。
# 已初始化的目录原样保留；之后交给 daemon。用户以后想部署自己的 Worker：
#   先 bunx wrangler login，再进容器去掉本地模式运行 noop init --primary。
set -e
HOST="${HUB_HOST:-lazycat}"
if [ ! -f /lzcapp/var/noop/data/config.toml ]; then
  echo "first run: initializing Noop data (local mode)"
  mkdir -p /lzcapp/var/noop
  cd /noop
  HUB_NO_MEDIC=1 HUB_SYNC_FAKE=local NOOP_HOME=/lzcapp/var/noop HUB_DATA=/lzcapp/var/noop/data \
    HUB_HOST="$HOST" \
    bun src/cli.ts init --primary < /dev/null
  # init 把 primary 写成容器 hostname（hostname()），但 daemon 以 HUB_HOST 运行；
  # isPrimary() 不匹配 → 聊天 API 不启动。统一改成 HUB_HOST 名。
  sed -i "s/^primary = \"[^\"]*\"/primary = \"$HOST\"/" /lzcapp/var/noop/data/config.toml
  echo
  echo "=============================================="
  echo "  Web 聊天页登录 token（[server] token in noop.toml）:"
  echo "  /lzcapp/var/noop/noop.toml"
  echo "=============================================="
fi
exec "$@"
