#!/usr/bin/env bash
set -euo pipefail

SERVICES_ROOT="${SERVICES_ROOT:-/opt/services}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SERVICE_SCRIPT="$SCRIPT_DIR/deploy-single-ec2-service.sh"
ACTION="${1:-up}"

declare -a DEPLOY_ORDER=(
  "redis-service"
  "auth-service"
  "user-service"
  "authz-service"
  "editor-service"
  "gateway-service"
)

if [[ "${INCLUDE_MONITORING:-false}" == "true" ]]; then
  DEPLOY_ORDER+=("monitoring-service")
fi

if [[ "$ACTION" == "down" ]]; then
  declare -a REVERSED_ORDER=()
  for (( idx=${#DEPLOY_ORDER[@]}-1 ; idx>=0 ; idx-- )); do
    REVERSED_ORDER+=("${DEPLOY_ORDER[idx]}")
  done
  DEPLOY_ORDER=("${REVERSED_ORDER[@]}")
fi

for service in "${DEPLOY_ORDER[@]}"; do
  repo_dir="$SERVICES_ROOT/$service"
  echo ""
  echo "==> ${ACTION} ${service} (${repo_dir})"
  "$DEPLOY_SERVICE_SCRIPT" "$service" "$repo_dir" "$ACTION"
done
