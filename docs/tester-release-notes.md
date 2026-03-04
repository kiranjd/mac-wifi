# MacWiFi v1.2.0 – Tester Notes

- Updated the diagnostics UI to a more native macOS palette and simplified visual hierarchy.
- Reworked diagnosis copy to be more user-friendly and outcome-focused.
- Replaced expandable impact cards with compact outcome rows and callout chips (`Good` / `Fair` / `Poor`).
- Added clearer advanced diagnostics split to help identify Wi-Fi-side vs internet-side issues.
- Improved menu bar popover behavior and state handling across open/close, Wi-Fi off, disconnect, and reconnect transitions.
- Consolidated local build/release workflow into one script: `./scripts/build_macwifi.sh`.

## Regression checks

- Launch app with Wi-Fi on/off and verify menu icon + popover state parity.
- While connected, run test and verify diagnosis + impact rows update without layout clipping.
- Toggle Wi-Fi power during/after tests and verify stale states are cleared.
- Confirm app requests location permission once and reuses granted access on relaunch.
