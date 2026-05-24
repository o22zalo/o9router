#!/bin/sh
set -e

prefixed_env() {
  printenv "$1" 2>/dev/null || true
}

map_prefixed_env() {
  target="$1"
  source="$2"
  value="$(prefixed_env "$source")"
  current="$(printenv "$target" 2>/dev/null || true)"
  if [ -n "$value" ] && [ -z "$current" ]; then
    export "$target=$value"
  fi
}

map_prefixed_env JWT_SECRET 9ROUTER_JWT_SECRET
map_prefixed_env INITIAL_PASSWORD 9ROUTER_INITIAL_PASSWORD
map_prefixed_env DATA_DIR 9ROUTER_DATA_DIR
map_prefixed_env PORT 9ROUTER_PORT
map_prefixed_env HOSTNAME 9ROUTER_HOSTNAME
map_prefixed_env NODE_ENV 9ROUTER_NODE_ENV
map_prefixed_env API_KEY_SECRET 9ROUTER_API_KEY_SECRET
map_prefixed_env MACHINE_ID_SALT 9ROUTER_MACHINE_ID_SALT
map_prefixed_env ENABLE_REQUEST_LOGS 9ROUTER_ENABLE_REQUEST_LOGS
map_prefixed_env OBSERVABILITY_ENABLED 9ROUTER_OBSERVABILITY_ENABLED
map_prefixed_env AUTH_COOKIE_SECURE 9ROUTER_AUTH_COOKIE_SECURE
map_prefixed_env REQUIRE_API_KEY 9ROUTER_REQUIRE_API_KEY
map_prefixed_env BASE_URL 9ROUTER_BASE_URL
map_prefixed_env CLOUD_URL 9ROUTER_CLOUD_URL
map_prefixed_env NEXT_PUBLIC_BASE_URL 9ROUTER_NEXT_PUBLIC_BASE_URL
map_prefixed_env NEXT_PUBLIC_CLOUD_URL 9ROUTER_NEXT_PUBLIC_CLOUD_URL
map_prefixed_env HTTP_PROXY 9ROUTER_HTTP_PROXY
map_prefixed_env HTTPS_PROXY 9ROUTER_HTTPS_PROXY
map_prefixed_env ALL_PROXY 9ROUTER_ALL_PROXY
map_prefixed_env NO_PROXY 9ROUTER_NO_PROXY

chown -R node:node /app/data /app/data-home 2>/dev/null || true
exec su-exec node "$@"
