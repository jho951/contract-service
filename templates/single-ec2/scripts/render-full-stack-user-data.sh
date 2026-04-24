#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: render-full-stack-user-data.sh <vars-file> [output-file]" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${TEMPLATE_DIR}/../.." && pwd)"
USER_DATA_TEMPLATE="${TEMPLATE_DIR}/user_data.full-stack.sh.tftpl"

VARS_FILE="${1:-}"
OUTPUT_FILE="${2:-}"

[[ -n "${VARS_FILE}" ]] || usage
[[ -f "${VARS_FILE}" ]] || { echo "Vars file not found: ${VARS_FILE}" >&2; exit 1; }
[[ -f "${USER_DATA_TEMPLATE}" ]] || { echo "Template not found: ${USER_DATA_TEMPLATE}" >&2; exit 1; }

set -a
# shellcheck disable=SC1090
source "${VARS_FILE}"
set +a

required_vars=(
  deploy_user
  base_dir
  network_name
  contract_repo_url
  contract_repo_ref
  include_monitoring
  gateway_repo_url
  gateway_repo_ref
  auth_repo_url
  auth_repo_ref
  user_repo_url
  user_repo_ref
  authz_repo_url
  authz_repo_ref
  editor_repo_url
  editor_repo_ref
  redis_repo_url
  redis_repo_ref
  monitoring_repo_url
  monitoring_repo_ref
  gateway_env_file
  auth_env_file
  user_env_file
  authz_env_file
  editor_env_file
  redis_env_file
  monitoring_env_file
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Required variable is missing: ${var_name}" >&2
    exit 1
  fi
done

resolve_path() {
  local path="$1"
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
    return
  fi
  if [[ -f "$path" ]]; then
    printf '%s\n' "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    return
  fi
  if [[ -f "${REPO_ROOT}/${path}" ]]; then
    printf '%s\n' "${REPO_ROOT}/${path}"
    return
  fi
  echo "Referenced file not found: ${path}" >&2
  exit 1
}

base64_no_wrap() {
  local file_path="$1"
  if base64 --help >/dev/null 2>&1; then
    base64 < "$file_path" | tr -d '\n'
  else
    openssl base64 -A -in "$file_path"
  fi
}

gateway_env_prod_b64="$(base64_no_wrap "$(resolve_path "$gateway_env_file")")"
auth_env_prod_b64="$(base64_no_wrap "$(resolve_path "$auth_env_file")")"
user_env_prod_b64="$(base64_no_wrap "$(resolve_path "$user_env_file")")"
authz_env_prod_b64="$(base64_no_wrap "$(resolve_path "$authz_env_file")")"
editor_env_prod_b64="$(base64_no_wrap "$(resolve_path "$editor_env_file")")"
redis_env_prod_b64="$(base64_no_wrap "$(resolve_path "$redis_env_file")")"
monitoring_env_prod_b64="$(base64_no_wrap "$(resolve_path "$monitoring_env_file")")"

rendered="$(cat "${USER_DATA_TEMPLATE}")"

replace_var() {
  local key="$1"
  local value="$2"
  rendered="${rendered//\$\{$key\}/$value}"
}

replace_var "deploy_user" "${deploy_user}"
replace_var "base_dir" "${base_dir}"
replace_var "network_name" "${network_name}"
replace_var "contract_repo_url" "${contract_repo_url}"
replace_var "contract_repo_ref" "${contract_repo_ref}"
replace_var "include_monitoring" "${include_monitoring}"

replace_var "gateway_repo_url" "${gateway_repo_url}"
replace_var "gateway_repo_ref" "${gateway_repo_ref}"
replace_var "auth_repo_url" "${auth_repo_url}"
replace_var "auth_repo_ref" "${auth_repo_ref}"
replace_var "user_repo_url" "${user_repo_url}"
replace_var "user_repo_ref" "${user_repo_ref}"
replace_var "authz_repo_url" "${authz_repo_url}"
replace_var "authz_repo_ref" "${authz_repo_ref}"
replace_var "editor_repo_url" "${editor_repo_url}"
replace_var "editor_repo_ref" "${editor_repo_ref}"
replace_var "redis_repo_url" "${redis_repo_url}"
replace_var "redis_repo_ref" "${redis_repo_ref}"
replace_var "monitoring_repo_url" "${monitoring_repo_url}"
replace_var "monitoring_repo_ref" "${monitoring_repo_ref}"

replace_var "gateway_env_prod_b64" "${gateway_env_prod_b64}"
replace_var "auth_env_prod_b64" "${auth_env_prod_b64}"
replace_var "user_env_prod_b64" "${user_env_prod_b64}"
replace_var "authz_env_prod_b64" "${authz_env_prod_b64}"
replace_var "editor_env_prod_b64" "${editor_env_prod_b64}"
replace_var "redis_env_prod_b64" "${redis_env_prod_b64}"
replace_var "monitoring_env_prod_b64" "${monitoring_env_prod_b64}"

if [[ -n "${OUTPUT_FILE}" ]]; then
  printf '%s\n' "${rendered}" > "${OUTPUT_FILE}"
  chmod 600 "${OUTPUT_FILE}" || true
  echo "Rendered user data written to ${OUTPUT_FILE}"
else
  printf '%s\n' "${rendered}"
fi
