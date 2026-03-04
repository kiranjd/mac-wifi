#!/bin/zsh

if [ -z "${ZSH_VERSION:-}" ]; then
  if command -v zsh >/dev/null 2>&1; then
    exec zsh "$0" "$@"
  else
    echo "This script requires zsh. Run: zsh $0 <debug|release>" >&2
    exit 1
  fi
fi

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SCRIPT_BASENAME="$(basename "$0")"

PRODUCT="${PRODUCT:-MacWiFi}"
APP_NAME="${APP_NAME:-${PRODUCT}.app}"
APP_BUNDLE_PATH="${APP_BUNDLE_PATH:-${REPO_ROOT}/${APP_NAME}}"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-${REPO_ROOT}/MacWiFi.entitlements}"
INFO_PLIST_PATH="${INFO_PLIST_PATH:-${REPO_ROOT}/Sources/${PRODUCT}/Info.plist}"
ICON_SCRIPT_PATH="${ICON_SCRIPT_PATH:-${SCRIPT_DIR}/generate_app_icon.sh}"
ICON_PATH="${ICON_PATH:-${REPO_ROOT}/Resources/AppIcon.icns}"

DEBUG_BUILD_PATH="${DEBUG_BUILD_PATH:-${REPO_ROOT}/.build-local}"
RELEASE_BUILD_PATH="${RELEASE_BUILD_PATH:-${REPO_ROOT}/.build-release}"
INSTALL_ROOT="${INSTALL_ROOT:-/Applications}"

AUTO_SIGN_DEBUG="${AUTO_SIGN_DEBUG:-1}"
AUTO_SIGN_RELEASE="${AUTO_SIGN_RELEASE:-1}"

# Backward-compatible env names from prior scripts.
DEBUG_SIGN_IDENTITY="${DEBUG_SIGN_IDENTITY:-${LOCAL_SIGN_IDENTITY:-}}"
RELEASE_SIGN_IDENTITY="${RELEASE_SIGN_IDENTITY:-}"

usage() {
  cat <<__USAGE__
Usage: ${SCRIPT_BASENAME} <debug|release> [--local] [--no-install]

  debug    Kill existing app, build Debug, refresh bundle, sign (optional), launch local app.
  release  Kill existing app, build Release, refresh bundle, sign (optional), install to Applications, launch.

Options:
  --local               Release only: skip signing (local testing).
  --no-install          Release only: do not copy to ${INSTALL_ROOT}; launch local app bundle.

Environment overrides:
  PRODUCT               Default: ${PRODUCT}
  APP_NAME              Default: ${APP_NAME}
  APP_BUNDLE_PATH       Default: ${APP_BUNDLE_PATH}
  DEBUG_BUILD_PATH      Default: ${DEBUG_BUILD_PATH}
  RELEASE_BUILD_PATH    Default: ${RELEASE_BUILD_PATH}
  ENTITLEMENTS_PATH     Default: ${ENTITLEMENTS_PATH}
  INFO_PLIST_PATH       Default: ${INFO_PLIST_PATH}
  ICON_SCRIPT_PATH      Default: ${ICON_SCRIPT_PATH}
  ICON_PATH             Default: ${ICON_PATH}
  INSTALL_ROOT          Default: ${INSTALL_ROOT}
  AUTO_SIGN_DEBUG       Default: ${AUTO_SIGN_DEBUG}
  AUTO_SIGN_RELEASE     Default: ${AUTO_SIGN_RELEASE}
  DEBUG_SIGN_IDENTITY   Default: (auto-detect, prefers Apple Development)
  RELEASE_SIGN_IDENTITY Default: (auto-detect, prefers Developer ID Application)
__USAGE__
}

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Required command not found: ${cmd}" >&2
    exit 1
  fi
}

ensure_prereqs() {
  require_cmd swift
  require_cmd open
  require_cmd ditto

  if [[ ! -x "${ICON_SCRIPT_PATH}" ]]; then
    echo "Icon generator script missing or not executable: ${ICON_SCRIPT_PATH}" >&2
    exit 1
  fi

  if [[ ! -f "${INFO_PLIST_PATH}" ]]; then
    echo "Info.plist not found: ${INFO_PLIST_PATH}" >&2
    exit 1
  fi
}

kill_running_app() {
  echo "Stopping existing ${PRODUCT}..."
  killall -q "${PRODUCT}" 2>/dev/null || true
  sleep 0.4
}

build_debug() {
  echo "Building Debug configuration for ${PRODUCT}..."
  swift build -c debug --product "${PRODUCT}" --build-path "${DEBUG_BUILD_PATH}"
}

build_release() {
  echo "Building Release configuration for ${PRODUCT}..."
  swift build -c release --product "${PRODUCT}" --build-path "${RELEASE_BUILD_PATH}"
}

refresh_app_bundle() {
  local binary_path="$1"

  if [[ ! -f "${binary_path}" ]]; then
    echo "Built binary not found: ${binary_path}" >&2
    exit 1
  fi

  echo "Refreshing app bundle at ${APP_BUNDLE_PATH}..."
  "${ICON_SCRIPT_PATH}"

  mkdir -p "${APP_BUNDLE_PATH}/Contents/MacOS"
  mkdir -p "${APP_BUNDLE_PATH}/Contents/Resources"

  cp "${binary_path}" "${APP_BUNDLE_PATH}/Contents/MacOS/${PRODUCT}"
  cp "${INFO_PLIST_PATH}" "${APP_BUNDLE_PATH}/Contents/Info.plist"

  if [[ -f "${ICON_PATH}" ]]; then
    cp "${ICON_PATH}" "${APP_BUNDLE_PATH}/Contents/Resources/AppIcon.icns"
  fi
}

detect_sign_identity() {
  local mode="$1"
  local identities

  identities="$(security find-identity -v -p codesigning 2>/dev/null | awk -F\" '{print $2}' || true)"
  if [[ -z "${identities}" ]]; then
    return 0
  fi

  if [[ "${mode}" == "debug" ]]; then
    local debug_identity
    debug_identity="$(printf '%s\n' "${identities}" | awk '/^Apple Development: / { print; exit }')"
    if [[ -n "${debug_identity}" ]]; then
      echo "${debug_identity}"
      return 0
    fi
    printf '%s\n' "${identities}" | awk '/^Developer ID Application: / { print; exit }'
    return 0
  fi

  local release_identity
  release_identity="$(printf '%s\n' "${identities}" | awk '/^Developer ID Application: / { print; exit }')"
  if [[ -n "${release_identity}" ]]; then
    echo "${release_identity}"
    return 0
  fi
  printf '%s\n' "${identities}" | awk '/^Apple Development: / { print; exit }'
  return 0
}

sign_app_bundle() {
  local identity="$1"

  require_cmd codesign

  echo "Signing ${APP_BUNDLE_PATH} with identity: ${identity}"
  codesign --force --sign "${identity}" "${APP_BUNDLE_PATH}/Contents/MacOS/${PRODUCT}"

  if [[ -f "${ENTITLEMENTS_PATH}" ]]; then
    codesign --force --sign "${identity}" --entitlements "${ENTITLEMENTS_PATH}" "${APP_BUNDLE_PATH}"
  else
    codesign --force --sign "${identity}" "${APP_BUNDLE_PATH}"
  fi

  codesign --verify --deep --strict --verbose=1 "${APP_BUNDLE_PATH}"
}

maybe_sign() {
  local mode="$1"
  local auto_sign=0
  local identity=""

  case "${mode}" in
    debug)
      auto_sign="${AUTO_SIGN_DEBUG}"
      identity="${DEBUG_SIGN_IDENTITY}"
      ;;
    release)
      auto_sign="${AUTO_SIGN_RELEASE}"
      identity="${RELEASE_SIGN_IDENTITY}"
      ;;
    *)
      echo "Unknown signing mode: ${mode}" >&2
      exit 1
      ;;
  esac

  if [[ "${auto_sign}" != "1" ]]; then
    local mode_upper="${mode:u}"
    echo "Skipping signing for ${mode} build (AUTO_SIGN_${mode_upper}=${auto_sign})."
    return
  fi

  if [[ -z "${identity}" ]]; then
    identity="$(detect_sign_identity "${mode}")"
  fi

  if [[ -n "${identity}" ]]; then
    sign_app_bundle "${identity}"
  else
    echo "No signing identity found. Continuing unsigned."
  fi
}

install_app() {
  local source_app="$1"
  local install_path="${INSTALL_ROOT%/}/${APP_NAME}"

  echo "Replacing ${install_path}..."

  if [[ -d "${install_path}" ]]; then
    if command -v trash >/dev/null 2>&1; then
      trash "${install_path}"
    else
      mv "${install_path}" "${install_path}.bak.$(date +%s)"
    fi
  fi

  ditto "${source_app}" "${install_path}"
  echo "Installed at ${install_path}"
}

launch_app() {
  local app_path="$1"
  echo "Launching ${app_path}..."
  open "${app_path}"
}

run_debug() {
  kill_running_app
  build_debug
  refresh_app_bundle "${DEBUG_BUILD_PATH}/debug/${PRODUCT}"
  maybe_sign debug
  launch_app "${APP_BUNDLE_PATH}"
}

run_release() {
  local install_requested="$1"
  local local_build="$2"

  kill_running_app
  build_release
  refresh_app_bundle "${RELEASE_BUILD_PATH}/release/${PRODUCT}"

  if [[ "${local_build}" == "1" ]]; then
    echo "--local specified, skipping release signing."
  else
    maybe_sign release
  fi

  if [[ "${install_requested}" == "1" ]]; then
    install_app "${APP_BUNDLE_PATH}"
    launch_app "${INSTALL_ROOT%/}/${APP_NAME}"
  else
    launch_app "${APP_BUNDLE_PATH}"
  fi
}

main() {
  local command=""
  local install_requested=1
  local local_build=0

  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      debug|release|-h|--help|help)
        if [[ -n "${command}" ]]; then
          echo "Command already specified: ${command}" >&2
          usage
          exit 1
        fi
        command="$1"
        shift
        ;;
      --local)
        local_build=1
        shift
        ;;
      --no-install)
        install_requested=0
        shift
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "${command}" ]]; then
    usage
    exit 1
  fi

  if [[ "${command}" == "-h" || "${command}" == "--help" || "${command}" == "help" ]]; then
    usage
    exit 0
  fi

  ensure_prereqs

  case "${command}" in
    debug)
      if [[ "${local_build}" == "1" ]]; then
        echo "--local is only available for release builds." >&2
        exit 1
      fi
      run_debug
      ;;
    release)
      run_release "${install_requested}" "${local_build}"
      ;;
  esac
}

main "$@"
