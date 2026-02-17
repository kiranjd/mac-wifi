# MacWiFi (macOS)

`MacWiFi` is a native macOS menu bar app that diagnoses Wi-Fi and internet stability in plain English while running lightweight live checks.

Latest installable release: [GitHub Releases](https://github.com/kiranjd/mac-wifi/releases/latest)

Demo issue (with video): https://github.com/kiranjd/mac-wifi/issues/1

https://raw.githubusercontent.com/kiranjd/mac-wifi/main/docs/mac-wifi-demo.mp4

## Features

- Live download/upload graph in the menu bar popover
- Friendly diagnosis cards (Wi-Fi vs ISP path clarity)
- Task-focused guidance (calls, streaming, transfers)
- Advanced diagnostics for latency, jitter, packet loss, and link details

## Requirements

- macOS 14+
- Xcode 16+ (for local development)

## Build and Run (Local)

```bash
./scripts/build_local.sh
./scripts/build-and-run.sh
```

## Tests

```bash
if [ -d Tests ]; then swift test; else echo "No Tests target yet"; fi
```

## Release Signing (Optional)

The release script is environment-driven and does not store secrets in-repo.

```bash
./scripts/release_sign.sh
```

Useful variables:

- `DEVELOPER_TEAM_ID`
- `APP_SIGN_IDENTITY`
- `DMG_SIGN_IDENTITY`
- `PREFERRED_DMG_SIGN_IDENTITY` (used only when `DMG_SIGN_IDENTITY` is unset)
- `NOTARIZE=1`
- `NOTARYTOOL_PROFILE`

By default, it uses `DMG_SIGN_IDENTITY` when set, otherwise falls back to `APP_SIGN_IDENTITY`, then the first available `Developer ID Application` identity in keychain.

## Troubleshooting

- App not visible:
  - `MacWiFi` is a menu bar app; check the menu bar icon.
- Permission issues:
  - Ensure app has required network access and is not blocked by local security tooling.
- No useful results:
  - Re-run the test after pausing heavy background transfers.

## Contributing

- Contribution guide: `CONTRIBUTING.md`
- Code of conduct: `CODE_OF_CONDUCT.md`
