#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: deploy-single-ec2-service.sh <service-name> <repo-dir> [up|down|restart|logs|ps|pull]" >&2
  exit 1
}

SERVICE_NAME="${1:-}"
REPO_DIR="${2:-}"
ACTION="${3:-up}"

[[ -n "$SERVICE_NAME" && -n "$REPO_DIR" ]] || usage
[[ -d "$REPO_DIR" ]] || { echo "Repo dir not found: $REPO_DIR" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OVERRIDE_DIR="$TEMPLATE_ROOT/overrides"
NETWORK_NAME="${SERVICE_SHARED_NETWORK:-service-backbone-shared}"

ensure_network() {
  if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "Creating external docker network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME" >/dev/null
  fi
}

compose_up() {
  local env_file="$1"
  shift
  SERVICE_SHARED_NETWORK="$NETWORK_NAME" BACKEND_SHARED_NETWORK="$NETWORK_NAME" MSA_SHARED_NETWORK="$NETWORK_NAME" SHARED_SERVICE_NETWORK="$NETWORK_NAME" \
    docker compose --env-file "$env_file" "$@"
}

run_compose() {
  local env_file="$1"
  local project_name="$2"
  shift 2
  case "$ACTION" in
    up) compose_up "$env_file" -p "$project_name" "$@" pull && compose_up "$env_file" -p "$project_name" "$@" up -d ;;
    down) compose_up "$env_file" -p "$project_name" "$@" down --remove-orphans ;;
    restart) compose_up "$env_file" -p "$project_name" "$@" pull && compose_up "$env_file" -p "$project_name" "$@" up -d ;;
    logs) compose_up "$env_file" -p "$project_name" "$@" logs -f ;;
    ps) compose_up "$env_file" -p "$project_name" "$@" ps ;;
    pull) compose_up "$env_file" -p "$project_name" "$@" pull ;;
    *) usage ;;
  esac
}

ensure_network

case "$SERVICE_NAME" in
  gateway-service)
    ENV_FILE="$REPO_DIR/.env.prod"
    [[ -f "$ENV_FILE" ]] || { echo "Env file not found: $ENV_FILE" >&2; exit 1; }
    run_compose "$ENV_FILE" "gateway-service" \
      -f "$REPO_DIR/docker/compose.yml" \
      -f "$REPO_DIR/docker/prod/compose.yml" \
      -f "$OVERRIDE_DIR/gateway-service.single-ec2.override.yml"
    ;;
  auth-service)
    ENV_FILE="$REPO_DIR/.env.prod"
    [[ -f "$ENV_FILE" ]] || { echo "Env file not found: $ENV_FILE" >&2; exit 1; }
    run_compose "$ENV_FILE" "auth-service" \
      -f "$REPO_DIR/docker/compose.yml" \
      -f "$REPO_DIR/docker/prod/compose.yml" \
      -f "$OVERRIDE_DIR/auth-service.single-ec2.override.yml"
    ;;
  user-service)
    ENV_FILE="$REPO_DIR/.env.prod"
    [[ -f "$ENV_FILE" ]] || { echo "Env file not found: $ENV_FILE" >&2; exit 1; }
    run_compose "$ENV_FILE" "user-service-prod" \
      -f "$REPO_DIR/docker/compose.yml" \
      -f "$REPO_DIR/docker/prod/compose.yml" \
      -f "$OVERRIDE_DIR/user-service.single-ec2.override.yml"
    ;;
  authz-service)
    ENV_FILE="$REPO_DIR/.env.prod"
    [[ -f "$ENV_FILE" ]] || { echo "Env file not found: $ENV_FILE" >&2; exit 1; }
    run_compose "$ENV_FILE" "authz-service" \
      -f "$REPO_DIR/docker/compose.yml" \
      -f "$REPO_DIR/docker/prod/compose.yml" \
      -f "$OVERRIDE_DIR/authz-service.single-ec2.override.yml"
    ;;
  editor-service)
    ENV_FILE="$REPO_DIR/.env.prod"
    [[ -f "$ENV_FILE" ]] || { echo "Env file not found: $ENV_FILE" >&2; exit 1; }
    run_compose "$ENV_FILE" "editor-service-prod" \
      -f "$REPO_DIR/docker/prod/compose.yml" \
      -f "$OVERRIDE_DIR/editor-service.single-ec2.override.yml"
    ;;
  redis-service)
    ENV_FILE="${ENV_FILE:-$REPO_DIR/env.docker.prod}"
    [[ -f "$ENV_FILE" ]] || { echo "Env file not found: $ENV_FILE" >&2; exit 1; }
    run_compose "$ENV_FILE" "redis-server" \
      -f "$REPO_DIR/docker/prod/compose.yml" \
      -f "$OVERRIDE_DIR/redis-service.single-ec2.override.yml"
    ;;
  monitoring-service)
    ENV_FILE="${ENV_FILE:-$REPO_DIR/.env.prod}"
    if [[ ! -f "$ENV_FILE" ]]; then
      ENV_FILE="/tmp/monitoring-service-empty.env"
      : > "$ENV_FILE"
    fi
    run_compose "$ENV_FILE" "monitoring-server" \
      -f "$REPO_DIR/docker/prod/compose.yml" \
      -f "$OVERRIDE_DIR/monitoring-service.single-ec2.override.yml"
    ;;
  *)
    echo "Unsupported service: $SERVICE_NAME" >&2
    exit 1
    ;;
esac
