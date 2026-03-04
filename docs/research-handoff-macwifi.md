# MacWiFi Research Handoff (Current Product State)

Use this as source context for competitor/positioning/viability research.
Assume this reflects the product **as currently implemented** in repo.

## 1) Product Snapshot

- Product name: **MacWiFi**
- Platform: **macOS menu bar app** (agent app, no dock presence)
- Category: **Consumer/prosumer network quality diagnostics**
- Core promise: **Explain internet quality in plain language, not raw stats**
- Current version in app bundle metadata: **1.2.0**
- Bundle ID: `com.kiranjd.macwifi`

## 2) What The App Does Today

### Primary user flow

1. User clicks menu bar icon.
2. App shows current Wi-Fi connection + live network quality area.
3. App runs/uses active network tests and computes reliability.
4. App presents:
   - overall internet state summary
   - practical outcomes (Calls / Streaming / Browsing)
   - expandable “why” reasons
   - advanced “Wi-Fi side vs Internet side” diagnostics

### Main user-visible features

- Live download/upload graph in popover during tests.
- Plain-language diagnosis (stable / mixed / unstable).
- Outcome rows for:
  - Calls
  - Streaming
  - Browsing
- Each outcome row has:
  - severity chip (`Low risk`, `Medium risk`, `High risk`)
  - short impact statement
  - expandable “Why” explanation
- Advanced diagnostics split by fault domain:
  - **Likely issue source**
  - **Wi-Fi side**
  - **Internet side**
- Scan/connect/disconnect Wi-Fi networks from app.
- Password prompt for secured networks.
- Copy diagnostics to clipboard.
- Open macOS Wi-Fi Settings.

## 3) Diagnostic Model (Current Logic)

### Measurement inputs

- Throughput + responsiveness from Apple `networkQuality` CLI.
- Ping diagnostics:
  - router (gateway) ping
  - public internet ping (`1.1.1.1`)
- DNS lookup timing (`one.one.one.one`).
- Packet loss (router path + internet path).
- Loaded latency and latency inflation.
- Jitter metrics and short history.
- Ambient traffic monitoring to infer sustained usage conditions.

### Reliability scoring

Reliability score is composite and weighted, not speed-only:
- responsiveness (RPM)
- loaded latency
- latency inflation
- packet loss
- run consistency

### Path split logic

App computes `ConnectionIssue` categories:
- `wifiProblem`
- `ispProblem`
- `bothProblems`
- `none`

This is used to support trust-building statements like:
- “Wi-Fi weak signal / local interference”
- “ISP/public internet path unstable”
- “Both Wi-Fi and ISP path have issues”

### Real-world activity readiness

Per-activity checks use combinations of:
- download Mbps
- upload Mbps
- RPM
- packet loss tolerance
- loaded latency limits
- latency inflation limits

Activities modeled:
- Gaming
- Video calls
- 4K streaming
- HD streaming
- Browsing
- File downloads

## 4) Current UX Positioning Inside Product

The current product direction emphasizes:
- **Outcome-first** language (“Will my call work?”) over raw telemetry.
- Progressive disclosure:
  - quick answer first
  - deeper diagnostics when needed
- “Where is the problem?” confidence layer (Wi-Fi vs ISP path)

## 5) Advanced Info (As Implemented Now)

Advanced info is intentionally scoped to answer: **“Is it Wi-Fi or ISP?”**

### Likely issue source
- One-line path verdict.

### Wi-Fi side
- RSSI / noise
- Band
- Channel width (+ channel)
- PHY rate
- Router ping (LAN)

### Internet side
- DNS response
- ISP/public ping
- Packet loss to router
- Packet loss to internet

## 6) Technical Architecture

- Swift Package executable app, macOS 14+.
- SwiftUI + AppKit popover/status item integration.
- CoreWLAN for Wi-Fi scan/state/connect flows.
- CoreLocation permission needed for SSID visibility on macOS.
- Runtime modules:
  - `App.swift` (status item/popover lifecycle)
  - `WiFiManager.swift` (Wi-Fi state/scan/connect)
  - `NetworkQualityMonitor.swift` (active tests + metrics)
  - `ConnectionDiagnosis.swift` (plain-English logic)
  - `Views/MenuContent.swift` (popover UI)

## 7) What It Is Not (Current Boundaries)

- Not a router management app.
- Not a packet-capture/deep network forensics tool.
- Not enterprise fleet monitoring.
- No cloud dashboard or team features currently.
- No explicit in-repo analytics backend.

## 8) Known Constraints / Risk Factors

- macOS only.
- Depends on location permission for SSID names.
- Quality estimates are point-in-time and environment-sensitive.
- No formal test suite target currently present in repo.

## 9) Candidate USP Signals To Validate (Research Hypotheses)

Use these as hypotheses to test against market/competitors:

1. **“Practical answer, not speed test theater.”**
2. **“Trust layer: tells users if issue is likely Wi‑Fi-side or ISP-side.”**
3. **“Outcome framing (Calls/Streaming/Browsing) beats raw metrics for everyday users.”**
4. **“Menu bar frictionless utility vs heavyweight diagnostic apps.”**
5. **“Local-first feel with immediate diagnostics and no account setup.”**

## 10) Target Customer Hypotheses To Validate

1. Remote workers with frequent call-quality complaints.
2. Non-technical home users who only care if internet “will work now.”
3. Tech-support-heavy households where blame between ISP/router/device is unclear.
4. Prosumers who want just enough diagnostics without enterprise complexity.

## 11) Research Tasks For External Model

Please research and return:

1. **Competitor landscape**
   - Direct competitors (macOS consumer diagnostics apps)
   - Indirect substitutes (speed tests, router apps, ISP tools)
   - For each: positioning, pricing, core UX, strengths/weaknesses.

2. **Positioning opportunities**
   - Best positioning angles for MacWiFi based on current capabilities.
   - Which angle is most defensible vs incumbents.

3. **USP recommendations**
   - Top 3 USPs that are both true now and commercially meaningful.
   - What evidence/messages to use to make each credible.

4. **ICP prioritization**
   - Rank customer segments by willingness to pay + urgency.
   - Recommend initial wedge segment.

5. **Pricing and packaging hypotheses**
   - Free vs paid boundaries.
   - Candidate paywalls based on current feature set.

6. **Go-to-market messaging**
   - Homepage headline/subheadline options.
   - App Store style pitch options.
   - Problem-aware ad/message hooks.

7. **Gaps to close for stronger moat**
   - What product gaps block defensibility today.
   - Which additions would materially improve differentiation.

## 12) Preferred Output Format

Please output:

1. Competitor matrix (table).
2. Recommended positioning statement.
3. Top 3 USP stack (with proof points).
4. Primary ICP and secondary ICP.
5. Pricing/packaging recommendation.
6. 30-day product + messaging validation plan.
