# MacWiFi (macOS)

`MacWiFi` is a native macOS menu bar app that diagnoses Wi-Fi and internet stability in plain English while running lightweight live checks.

Download the latest app: [GitHub Releases](https://github.com/kiranjd/mac-wifi/releases/latest)

https://github.com/user-attachments/assets/7b97475f-a63f-44f0-ba97-9844473b3c7d

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
- `PREFERRED_DMG_SIGN_IDENTITY` (default matches `APP_SIGN_IDENTITY`)
- `NOTARIZE=1`
- `NOTARYTOOL_PROFILE` (default: `textify-notary`)
- `SKIP_KEYCHAIN_IDENTITY_DISCOVERY=1` (default; avoids extra `security find-identity` probing)

By default, it uses fixed identities and skips keychain identity discovery to reduce security prompts. Set `SKIP_KEYCHAIN_IDENTITY_DISCOVERY=0` if you want automatic identity discovery from keychain.

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
