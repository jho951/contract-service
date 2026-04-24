#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-/opt/services}"

declare -a TARGETS=(
  "contract-service"
  "gateway-service"
  "auth-service"
  "user-service"
  "authz-service"
  "editor-service"
  "redis-service"
  "monitoring-service"
  "editor-page"
  "explain-page"
  "contract-oss"
)

if [[ "${FORCE:-false}" != "true" ]]; then
  echo "Set FORCE=true to delete old cloned repositories under ${ROOT_DIR}." >&2
  exit 1
fi

for target in "${TARGETS[@]}"; do
  path="${ROOT_DIR}/${target}"
  if [[ -e "$path" ]]; then
    echo "Removing ${path}"
    rm -rf "$path"
  fi
done
