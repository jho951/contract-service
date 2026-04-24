#!/usr/bin/env bash
set -euo pipefail

DEPLOY_ROOT="${1:-/opt/deploy}"
CONTRACT_REPO_URL="${CONTRACT_REPO_URL:-https://github.com/jho951/contract-service.git}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

sudo mkdir -p "$DEPLOY_ROOT"
sudo chown -R "$(id -un)":"$(id -gn)" "$DEPLOY_ROOT"

git clone "$CONTRACT_REPO_URL" "$TMP_DIR/contract-service"

cp -R "$TMP_DIR/contract-service/templates/single-ec2/deploy-bundle/." "$DEPLOY_ROOT/"
cp "$TMP_DIR/contract-service/templates/single-ec2/nginx.single-ec2.conf.example" "$DEPLOY_ROOT/nginx.single-ec2.conf.example"

chmod +x \
  "$DEPLOY_ROOT/scripts/bootstrap-ec2.sh" \
  "$DEPLOY_ROOT/scripts/cleanup-old-clones.sh" \
  "$DEPLOY_ROOT/scripts/deploy-stack.sh"

echo "Deploy bundle installed to $DEPLOY_ROOT"
echo "Next:"
echo "  cd $DEPLOY_ROOT"
echo "  cp .env.backend.example .env.backend"
echo "  cp .env.frontend.example .env.frontend"
echo "  vi .env.backend"
echo "  vi .env.frontend"
