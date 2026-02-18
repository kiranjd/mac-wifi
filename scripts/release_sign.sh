#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SCRIPT_NAME="$(basename -- "$0")"
PRODUCT_NAME="${PRODUCT_NAME:-MacWiFi}"
DEFAULT_SIGN_IDENTITY="Developer ID Application: Kiran Murthy Jd (MN4M99XHF7)"
BUILD_PATH="${BUILD_PATH:-${REPO_ROOT}/.build-release}"
DIST_ROOT="${DIST_ROOT:-${REPO_ROOT}/dist}"
EXPORT_PATH="${EXPORT_PATH:-${DIST_ROOT}/export}"
APP_BUNDLE_PATH="${APP_BUNDLE_PATH:-${EXPORT_PATH}/${PRODUCT_NAME}.app}"
APP_BINARY_PATH="${APP_BINARY_PATH:-${BUILD_PATH}/release/${PRODUCT_NAME}}"
INFO_PLIST_PATH="${INFO_PLIST_PATH:-${REPO_ROOT}/Sources/${PRODUCT_NAME}/Info.plist}"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-${REPO_ROOT}/MacWiFi.entitlements}"
DMG_PATH="${DMG_PATH:-${DIST_ROOT}/${PRODUCT_NAME}.dmg}"
DEVELOPER_TEAM_ID="${DEVELOPER_TEAM_ID:-MN4M99XHF7}"
APP_SIGN_IDENTITY="${APP_SIGN_IDENTITY:-${DEFAULT_SIGN_IDENTITY}}"
DMG_SIGN_IDENTITY="${DMG_SIGN_IDENTITY:-}"
PREFERRED_DMG_SIGN_IDENTITY="${PREFERRED_DMG_SIGN_IDENTITY:-${DEFAULT_SIGN_IDENTITY}}"
NOTARIZE="${NOTARIZE:-0}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-textify-notary}"
SKIP_KEYCHAIN_IDENTITY_DISCOVERY="${SKIP_KEYCHAIN_IDENTITY_DISCOVERY:-1}"

usage() {
  cat <<USAGE
Usage: ${SCRIPT_NAME}

Environment:
  DEVELOPER_TEAM_ID            Team used for notarization/export context (default: ${DEVELOPER_TEAM_ID})
  APP_SIGN_IDENTITY            Developer ID identity for app signing (default: ${APP_SIGN_IDENTITY})
  DMG_SIGN_IDENTITY            Optional exact Developer ID identity for DMG signing
  PREFERRED_DMG_SIGN_IDENTITY  Fallback identity if DMG_SIGN_IDENTITY is unset (default: ${PREFERRED_DMG_SIGN_IDENTITY})
  NOTARIZE                     1 to notarize DMG, 0 to skip (default: ${NOTARIZE})
  NOTARYTOOL_PROFILE           Notarytool keychain profile (default: ${NOTARYTOOL_PROFILE})
  SKIP_KEYCHAIN_IDENTITY_DISCOVERY  1 to skip security keychain identity probing (default: ${SKIP_KEYCHAIN_IDENTITY_DISCOVERY})
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

available_developer_ids() {
  security find-identity -v -p codesigning | awk -F\" '/Developer ID Application/ {print $2}'
}

is_identity_available() {
  local identity="$1"
  local identities="$2"
  [[ -n "${identity}" ]] || return 1
  echo "${identities}" | grep -Fxq "${identity}"
}

if [[ "${SKIP_KEYCHAIN_IDENTITY_DISCOVERY}" == "1" ]]; then
  DEVELOPER_IDS=""
else
  DEVELOPER_IDS="$(available_developer_ids || true)"
fi

if [[ -z "${APP_SIGN_IDENTITY}" && -n "${DEVELOPER_IDS}" ]]; then
  APP_SIGN_IDENTITY="$(echo "${DEVELOPER_IDS}" | head -n 1)"
fi

if [[ -z "${DMG_SIGN_IDENTITY}" && -n "${PREFERRED_DMG_SIGN_IDENTITY}" ]]; then
  if [[ -z "${DEVELOPER_IDS}" ]] || is_identity_available "${PREFERRED_DMG_SIGN_IDENTITY}" "${DEVELOPER_IDS}"; then
    DMG_SIGN_IDENTITY="${PREFERRED_DMG_SIGN_IDENTITY}"
  else
    echo "Preferred DMG identity is not available in keychain: ${PREFERRED_DMG_SIGN_IDENTITY}" >&2
  fi
fi

if [[ -z "${DMG_SIGN_IDENTITY}" ]]; then
  DMG_SIGN_IDENTITY="${APP_SIGN_IDENTITY}"
fi

if [[ -n "${DEVELOPER_IDS}" && -n "${APP_SIGN_IDENTITY}" ]]; then
  if ! is_identity_available "${APP_SIGN_IDENTITY}" "${DEVELOPER_IDS}"; then
    echo "APP_SIGN_IDENTITY is not available in keychain: ${APP_SIGN_IDENTITY}" >&2
    exit 1
  fi
fi

if [[ -n "${DEVELOPER_IDS}" && -n "${DMG_SIGN_IDENTITY}" ]]; then
  if ! is_identity_available "${DMG_SIGN_IDENTITY}" "${DEVELOPER_IDS}"; then
    echo "DMG_SIGN_IDENTITY is not available in keychain: ${DMG_SIGN_IDENTITY}" >&2
    exit 1
  fi
fi

if [[ -z "${DEVELOPER_TEAM_ID}" && -n "${APP_SIGN_IDENTITY}" ]]; then
  DEVELOPER_TEAM_ID=$(echo "${APP_SIGN_IDENTITY}" | sed -nE 's/.*\(([A-Z0-9]{10})\)$/\1/p')
fi

if [[ -z "${DEVELOPER_TEAM_ID}" ]]; then
  echo "Could not determine DEVELOPER_TEAM_ID. Set DEVELOPER_TEAM_ID explicitly." >&2
  exit 1
fi

echo "Using DEVELOPER_TEAM_ID=${DEVELOPER_TEAM_ID}"
if [[ -n "${APP_SIGN_IDENTITY}" ]]; then
  echo "Using APP_SIGN_IDENTITY=${APP_SIGN_IDENTITY}"
fi
if [[ -n "${DMG_SIGN_IDENTITY}" ]]; then
  echo "Using DMG_SIGN_IDENTITY=${DMG_SIGN_IDENTITY}"
fi

mkdir -p "${DIST_ROOT}" "${EXPORT_PATH}"
rm -rf "${BUILD_PATH}" "${APP_BUNDLE_PATH}"

if [[ -x "${SCRIPT_DIR}/generate_app_icon.sh" ]]; then
  "${SCRIPT_DIR}/generate_app_icon.sh"
fi

swift build \
  -c release \
  --product "${PRODUCT_NAME}" \
  --build-path "${BUILD_PATH}"

if [[ ! -f "${APP_BINARY_PATH}" ]]; then
  echo "Built binary not found at ${APP_BINARY_PATH}" >&2
  exit 1
fi

if [[ ! -f "${INFO_PLIST_PATH}" ]]; then
  echo "Info.plist not found at ${INFO_PLIST_PATH}" >&2
  exit 1
fi

mkdir -p "${APP_BUNDLE_PATH}/Contents/MacOS"
mkdir -p "${APP_BUNDLE_PATH}/Contents/Resources"
cp "${APP_BINARY_PATH}" "${APP_BUNDLE_PATH}/Contents/MacOS/${PRODUCT_NAME}"
cp "${INFO_PLIST_PATH}" "${APP_BUNDLE_PATH}/Contents/Info.plist"
if [[ -f "${REPO_ROOT}/Resources/AppIcon.icns" ]]; then
  cp "${REPO_ROOT}/Resources/AppIcon.icns" "${APP_BUNDLE_PATH}/Contents/Resources/AppIcon.icns"
fi

if [[ -n "${APP_SIGN_IDENTITY}" ]]; then
  echo "Signing app bundle with ${APP_SIGN_IDENTITY}"
  CODESIGN_ARGS=(
    --force
    --timestamp
    --options runtime
    --sign "${APP_SIGN_IDENTITY}"
  )
  if [[ -f "${ENTITLEMENTS_PATH}" ]]; then
    CODESIGN_ARGS+=(--entitlements "${ENTITLEMENTS_PATH}")
  fi

  codesign "${CODESIGN_ARGS[@]}" "${APP_BUNDLE_PATH}"
  codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE_PATH}"
else
  echo "No Developer ID identity found; skipping app signing."
fi

TMP_DMG_DIR="${DIST_ROOT}/dmg-root"
rm -rf "${TMP_DMG_DIR}"
mkdir -p "${TMP_DMG_DIR}"
cp -R "${APP_BUNDLE_PATH}" "${TMP_DMG_DIR}/"
ln -s /Applications "${TMP_DMG_DIR}/Applications"

rm -f "${DMG_PATH}"
hdiutil create -volname "${PRODUCT_NAME}" -srcfolder "${TMP_DMG_DIR}" -ov -format UDZO "${DMG_PATH}"

if [[ -n "${DMG_SIGN_IDENTITY}" ]]; then
  echo "Signing DMG with ${DMG_SIGN_IDENTITY}"
  codesign --force --timestamp --sign "${DMG_SIGN_IDENTITY}" "${DMG_PATH}"
  codesign --verify --verbose=2 "${DMG_PATH}"
else
  echo "No Developer ID identity found; skipping DMG signing."
fi

if [[ "${NOTARIZE}" == "1" ]]; then
  xcrun notarytool submit "${DMG_PATH}" --wait --keychain-profile "${NOTARYTOOL_PROFILE}"
  xcrun stapler staple "${DMG_PATH}"
  xcrun stapler validate "${DMG_PATH}"
fi

spctl --assess --type open --context context:primary-signature --verbose "${DMG_PATH}" || true

echo "Release artifact: ${DMG_PATH}"
