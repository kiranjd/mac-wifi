# Architecture

## Overview

`MacWiFi` is a menu bar utility built with SwiftUI + AppKit interop.

- `App.swift`
  - App lifecycle, status item, popover management, and launch behavior.
- `WiFiManager.swift`
  - Wi-Fi scanning, network listing, connection/disconnection orchestration.
- `NetworkQualityMonitor.swift`
  - Active network quality checks and reliability metrics collection.
- `ConnectionDiagnosis.swift`
  - Plain-English diagnosis layer over raw metrics.
- `Views/MenuContent.swift`
  - Primary popover UI and user-facing diagnostics presentation.

## Runtime Flow

1. App launches and creates status item + popover.
2. On popover open, app scans networks and starts/continues quality checks when connected.
3. Monitor streams live measurements to UI.
4. Diagnosis layer maps measurements to friendly status and actionable guidance.

## Release Artifacts

- Local release script builds a signed app bundle and DMG in `dist/`.
- CI release workflow signs/notarizes when required secrets are present.

