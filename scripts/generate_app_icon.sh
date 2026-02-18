#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

SOURCE_ICON="${1:-${REPO_ROOT}/icon.png}"
ICONSET_DIR="${ICONSET_DIR:-${REPO_ROOT}/Resources/AppIcon.iconset}"
ICNS_OUTPUT="${ICNS_OUTPUT:-${REPO_ROOT}/Resources/AppIcon.icns}"

if [[ ! -f "${SOURCE_ICON}" ]]; then
  echo "Source icon not found: ${SOURCE_ICON}" >&2
  exit 1
fi

mkdir -p "${ICONSET_DIR}"

render() {
  local size="$1"
  local name="$2"
  sips -z "${size}" "${size}" "${SOURCE_ICON}" --out "${ICONSET_DIR}/${name}" >/dev/null
}

render 16 icon_16x16.png
render 32 icon_16x16@2x.png
render 32 icon_32x32.png
render 64 icon_32x32@2x.png
render 128 icon_128x128.png
render 256 icon_128x128@2x.png
render 256 icon_256x256.png
render 512 icon_256x256@2x.png
render 512 icon_512x512.png
render 1024 icon_512x512@2x.png

iconutil -c icns "${ICONSET_DIR}" -o "${ICNS_OUTPUT}"

echo "Generated ${ICNS_OUTPUT}"
