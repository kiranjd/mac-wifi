#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PRODUCT_NAME="${PRODUCT_NAME:-MacWiFi}"
BUILD_PATH="${BUILD_PATH:-${REPO_ROOT}/.build-local}"
CONFIGURATION="${CONFIGURATION:-debug}"

cd "${REPO_ROOT}"

swift build \
  -c "${CONFIGURATION}" \
  --product "${PRODUCT_NAME}" \
  --build-path "${BUILD_PATH}"

