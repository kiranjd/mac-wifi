# Architecture

## Overview

`MacWiFi` is a menu bar utility built with SwiftUI + AppKit interop.

- `App.swift`
  - App lifecycle, status item, popover management, launch behavior, and gated result-driven auto-open logic.
- `WiFiManager.swift`
  - Wi-Fi scanning, network listing, connection/disconnection orchestration.
- `NetworkQualityMonitor.swift`
  - Active network quality checks and reliability metrics collection.
- `ConnectionDiagnosis.swift`
  - Plain-English diagnosis layer over raw metrics.
- `Views/MenuContent.swift`
  - Primary popover UI and user-facing diagnostics presentation.
- `Services/AppDiagnostics.swift`
  - Developer-machine detection via `dev.txt` markers plus log file path resolution.
- `Services/AppLogger.swift`
  - Unified logging facade with optional file sinks for developer machines.

## Runtime Flow

1. App launches and creates the status item + popover shell.
2. The app validates stored license state and auto-presents the license gate until activation succeeds.
3. Only licensed sessions open the diagnostics UI, scan networks, and start or continue quality checks.
4. Monitor streams live measurements to UI.
5. Completed results may reopen the popover only if the user previously opened it and it later collapsed.
6. Diagnosis layer maps measurements to friendly status and actionable guidance.

## Release Artifacts

- Local release script builds a signed app bundle and DMG in `dist/`.
- CI release workflow signs/notarizes when required secrets are present.
