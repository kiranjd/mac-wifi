# MacWiFi Product Feature Inventory

This inventory reflects the current product and messaging implemented in the repo as of March 11, 2026.

## 1. Product snapshot

- Product: `MacWiFi`
- Platform: native `macOS` menu bar app
- Distribution shape: direct purchase and download
- Current public price in repo copy: `$9.99 one-time`
- Commercial posture: no account, local utility, in-app license activation
- Core claim repeated across app/docs/site:
  - tell people whether the connection is usable right now
  - translate network health into plain language
  - help answer whether the issue is local Wi-Fi or farther upstream

## 2. Core value themes already present

### A. Outcome-first connection verdicts

The app is designed to answer practical questions instead of only showing raw network stats.

- "Calls" readiness
- "Streaming" readiness
- "Browsing" readiness
- Summary states such as:
  - internet looks stable right now
  - usable, but not consistent
  - unstable right now
- Activity-specific impact language:
  - may freeze / robotic audio
  - may buffer under load
  - pages may load slowly

What this means commercially:
- The product is already closer to "connection confidence" than "Wi-Fi scanner."
- This is a stronger wedge for remote workers and everyday Mac users than generic speed-test positioning.

## 3. Feature groups

### Group 1: Menu bar utility and quick-access workflow

- Runs as a menu bar app rather than a dock-first app.
- Menu bar icon reflects connection state:
  - Wi-Fi off
  - Wi-Fi on but not connected
  - connected
  - connected and testing
  - connected with warning / poor quality
- Popover opens directly from the status item.
- Right click or control click opens utility actions:
  - License and Settings
  - Quit

User value:
- Low friction, check-in-and-close utility.
- Good fit for "I need an answer now" behavior rather than long diagnostic sessions.

### Group 2: Wi-Fi state management and network control

- Detects whether Wi-Fi power is on or off.
- Allows Wi-Fi power toggle from the app.
- Shows current connected network.
- Shows connected network band and security type.
- Supports disconnect from current network.
- Scans nearby networks.
- Sorts scanned networks by strongest signal.
- Separates known networks from others.
- Deduplicates SSIDs by strongest signal.
- Filters hidden SSIDs from the main UI.
- Detects likely personal hotspot SSIDs and surfaces them separately.
- Supports connect flow for open and password-protected networks.
- Includes password prompt for protected networks.
- Shows connect state progression:
  - finding network
  - connecting
  - authenticating
  - getting IP
  - connected
  - failed with reason

User value:
- Replaces part of the built-in macOS Wi-Fi menu workflow.
- Adds clearer state and stronger network visibility than the default menu.

### Group 3: Active connection testing and live feedback

- Manual "Test Connection" action when no fresh result exists.
- Auto-starts testing after relevant connection changes or stale results.
- Uses Apple's `networkQuality` CLI for throughput and responsiveness testing.
- Runs ping diagnostics in parallel with throughput testing.
- Measures:
  - download throughput
  - upload throughput
  - responsiveness / RPM
  - base RTT
  - loaded latency P50 and P95
  - loaded jitter
  - latency inflation
- Shows live graph during testing.
- Shows live download and upload values during the run.
- Displays phase-aware testing status while running.
- Supports refresh / re-test behavior after results exist.

User value:
- Faster perceived usefulness than a dead static dashboard.
- Turns the app into a lightweight diagnostic session instead of a passive network list.

### Group 4: Reliability scoring and stability analysis

- Reliability score is composite, not speed-only.
- Factors include:
  - responsiveness
  - loaded latency
  - latency inflation
  - packet loss
  - run-to-run consistency
- Converts reliability into human-friendly labels:
  - Reliable
  - Okay
  - Unstable
- Produces confidence labels:
  - High
  - Medium
  - Low
- Tracks reliability trend over recent samples:
  - improving
  - worsening
  - stable
- Keeps short histories for:
  - jitter
  - packet loss
  - reliability

User value:
- Better than speed-test theater.
- Gives a path to product differentiation around trust and repeat usage.

### Group 5: Wi-Fi-vs-ISP issue attribution

- Runs gateway ping diagnostics for local path quality.
- Runs public internet ping diagnostics for upstream path quality.
- Measures DNS lookup timing.
- Calculates likely issue source:
  - none
  - Wi-Fi problem
  - ISP problem
  - both problems
- Uses attribution inside the diagnosis layer and advanced info.

User value:
- This is one of the strongest differentiators in the repo.
- It maps directly to a real user question:
  - "Do I move closer to the router?"
  - "Do I switch networks?"
  - "Do I blame my ISP?"

### Group 6: Plain-English diagnosis engine

- Converts signal quality into:
  - Strong
  - Good
  - Okay
  - Very Weak
  - Barely Connected
- Converts internet quality into:
  - Fast
  - Good
  - Slow
  - Very Slow
  - Barely Working
- Produces status messages such as:
  - Great for everything
  - Good for most activities
  - Video calls may stutter
  - Connection is struggling
- Produces explanation copy such as:
  - Wi-Fi signal or interference is causing drops
  - slowdown is likely on your provider or upstream route
  - some data is being dropped
  - the connection slows down when the network is busy

User value:
- Makes the app legible to non-network specialists.
- Supports "normal people" positioning already used on the site.

### Group 7: Activity readiness model

The diagnosis model includes task-level requirements and impact analysis for:

- video calls
- gaming
- 4K streaming
- HD streaming
- browsing
- file transfers

The current UI surfaces three simplified user-facing buckets:

- Calls
- Streaming
- Browsing

Each row includes:

- risk level:
  - Good
  - Fair
  - Poor
- short verdict text
- short "why" logic based on the underlying metrics

User value:
- Strong bridge between technical data and human willingness to pay.
- Particularly useful for remote work and household troubleshooting.

### Group 8: Advanced diagnostics and progressive disclosure

- "Advanced info" disclosure group keeps the first view simple.
- Advanced details include:
  - likely issue source
  - Wi-Fi side
  - Internet side
  - signal and radio info
  - DNS timing
  - packet loss
  - latency-related metrics
- App explains terms such as:
  - latency
  - jitter
  - packet loss
  - download and upload
- Copy diagnostics to clipboard.

User value:
- Gives credibility without forcing all users into a technical interface.
- Supports both everyday users and more technical prosumers.

### Group 9: Permissions, guidance, and recovery UX

- Handles location permission state explicitly.
- Explains why location access is needed.
- Offers direct jump to Privacy and Security settings.
- Handles Wi-Fi off state and not-connected state clearly.
- Clears stale results when disconnected or Wi-Fi power changes.

User value:
- Reduces confusion around a common macOS Wi-Fi permission hurdle.
- Helps make the app feel trustworthy rather than broken.

### Group 10: Commercial and support features already present

- Lemon Squeezy license activation inside the app.
- Validate license now.
- Deactivate this Mac.
- Direct buy CTA from settings.
- `macwifi://activate?key=...` deep-link activation support.
- Support links and activation guide links.

User value:
- Indicates the product is already being shaped as a paid utility, not just a side project.

## 4. Current external messaging and market posture

The repo's website and docs currently push these ideas repeatedly:

- `Know what your internet can actually do right now`
- `Find out if it's your Wi-Fi or your ISP`
- `Calls, streaming, browsing`
- `No account`
- `One-time purchase`
- `Native macOS diagnostics for normal people`

This matters because research should evaluate not only feature-market fit, but whether this messaging is the right wedge.

## 5. What the product is not yet

- Not a router admin app.
- Not an enterprise fleet monitor.
- Not a deep packet inspection or route tracing tool.
- Not a team dashboard.
- Not a cross-platform product.
- Not a long-history / reporting-heavy monitoring suite yet.
- Not positioned around VPN, privacy, or firewall control.

## 6. Constraints and risks the research should factor in

- `macOS` only.
- Location permission is required for full Wi-Fi discovery details.
- Some value depends on one-point-in-time testing.
- No formal automated test suite target is visible yet.
- The product currently mixes two jobs:
  - better Wi-Fi menu / network control
  - internet reliability diagnosis

This overlap is important. Research should determine which job is the better paid wedge and whether the other job is a useful differentiator or a distraction.

## 7. Current audience clues already present in the repo

The repo suggests these possible audiences, even if they are not yet crisply prioritized:

- remote workers who need call confidence
- people troubleshooting "is it my Wi-Fi or my ISP?"
- everyday Mac users who want clearer answers than macOS gives
- prosumers who want enough detail without a heavyweight network tool
- people comparing MacWiFi against WhyFi, PeakHour, iStat Menus, or other menu bar utilities

## 8. Strategic question the research should answer

What is the strongest commercially viable wedge for MacWiFi:

- better built-in Wi-Fi menu replacement
- call-readiness and internet confidence tool
- lightweight home troubleshooting utility
- traveler / hotel / coworking network evaluator
- prosumer connection-quality utility

The answer should be based on:

- willingness to pay
- urgency of pain
- clarity of messaging
- fit with current product truth
- defensibility against competitors
