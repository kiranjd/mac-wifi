# MacWiFi Progressive Disclosure UI Plan

## Design Philosophy

**Core Principle**: Lead with practical value, reveal complexity on demand.

The common user doesn't care about RPM, jitter, or bufferbloat. They care about:
- "Will my Zoom call work?"
- "Why is my game laggy?"
- "Is my WiFi the problem or the internet?"

Technical metrics are the *proof* behind the answer, not the answer itself.

---

## Information Architecture

### Level 0: Menu Bar Icon (Always Visible)
**Goal**: At-a-glance health without opening the app

```
Options:
A) Standard WiFi icon with color dot overlay
   - 🟢 Green dot = Excellent
   - 🟡 Yellow dot = Issues detected
   - 🔴 Red dot = Poor connection

B) Dynamic icon showing signal + health
   - Full bars + no dot = Great
   - Partial bars + yellow = Degraded
```

**Decision**: Option A - less visual noise, clear semantic meaning

---

### Level 1: Collapsed Card (First Thing User Sees)
**Goal**: Answer "Is my connection good?" in 2 seconds

```
┌────────────────────────────────────────────┐
│ 📶 dude what                    Disconnect │
│    5 GHz                                   │
├────────────────────────────────────────────┤
│                                            │
│  ● Great for everything            ↻  ○    │
│                                            │
│  ✓✓✓✓✓✓  All activities supported          │
│                                            │
└────────────────────────────────────────────┘
```

Or with issues:

```
┌────────────────────────────────────────────┐
│ 📶 dude what                    Disconnect │
│    5 GHz                                   │
├────────────────────────────────────────────┤
│                                            │
│  ● Video calls may stutter         ↻  ○    │
│                                            │
│  ✗✗ ✓✓✓✓  2 activities limited             │
│                                            │
└────────────────────────────────────────────┘
```

**Elements**:
1. **Health dot**: 🟢🟡🔴 - Instant emotional read
2. **Plain English summary**: One sentence, no jargon
3. **Capability summary**: Dense icon row (✓/✗)
4. **Recency ring**: Visual freshness indicator around refresh button

**Interaction**: Tap anywhere on the quality section to expand

---

### Level 2: Expanded Card (Tap to Reveal)
**Goal**: Explain what works/doesn't and why, still in human terms

```
┌────────────────────────────────────────────┐
│ 📶 dude what                    Disconnect │
│    5 GHz                                   │
├────────────────────────────────────────────┤
│                                            │
│  ● Video calls may stutter         ↻  ○    │
│                                            │
│  Your connection gets sluggish when        │
│  multiple devices are active.              │
│                                            │
│  ─────────────────────────────────────     │
│                                            │
│  Limited:                                  │
│   🎮 Gaming        → too much delay        │
│   📹 Video calls   → may freeze/stutter    │
│                                            │
│  Works well:                               │
│   📺 4K streaming  ✓                       │
│   🎬 HD streaming  ✓                       │
│   🌐 Browsing      ✓                       │
│   ⬇️ Downloads     ✓                       │
│                                            │
│  ─────────────────────────────────────     │
│                                            │
│  [Technical details]                    ▼  │
│                                            │
└────────────────────────────────────────────┘
```

**Elements**:
1. **Explanation sentence**: Why this is happening (bufferbloat, slow speed, etc.)
2. **Limited activities**: With human-readable reason
3. **Working activities**: Simple checkmarks
4. **Technical details toggle**: Collapsed by default

**Reasons mapping** (internal → display):
- `latency` → "too much delay" / "may freeze/stutter"
- `speed` → "too slow" / "not enough bandwidth"
- `both` → "connection too weak"

---

### Level 3: Technical Details (Opt-in)
**Goal**: Give power users the numbers they want

```
┌────────────────────────────────────────────┐
│  Technical Details                      ▲  │
│  ─────────────────────────────────────     │
│                                            │
│  Speed                                     │
│   ↓ 45.2 Mbps download                     │
│   ↑ 12.1 Mbps upload                       │
│                                            │
│  Responsiveness                            │
│   320 RPM (Fair)                           │
│   ⓘ How well your connection handles       │
│      multiple activities at once           │
│                                            │
│  Signal Quality                            │
│   -58 dBm signal, -90 dBm noise            │
│   32 dB SNR (Good)                         │
│                                            │
│  Last tested: 2 min ago                    │
│                                            │
└────────────────────────────────────────────┘
```

**Elements**:
1. **Speed**: Raw Mbps with labels
2. **Responsiveness**: RPM with grade + one-line explanation
3. **Signal**: RSSI, noise, SNR from CoreWLAN
4. **Timestamp**: When test was run

**Inline explanations** (ⓘ icon expands):
- RPM: "How well your connection handles multiple activities at once"
- SNR: "Higher is better - measures signal clarity vs interference"

---

## Health Status Logic

### Computing the Health Grade

```swift
enum ConnectionHealth {
    case excellent  // 🟢 "Great for everything"
    case good       // 🟢 "Good for most activities"
    case fair       // 🟡 "Some activities may be limited"
    case poor       // 🟡 "Several activities won't work well"
    case bad        // 🔴 "Connection is struggling"
}

func computeHealth(mbps: Double, rpm: Int) -> ConnectionHealth {
    // RPM thresholds (bufferbloat indicator)
    let rpmExcellent = rpm >= 1000
    let rpmGood = rpm >= 500
    let rpmFair = rpm >= 200

    // Speed thresholds
    let speedExcellent = mbps >= 100
    let speedGood = mbps >= 25
    let speedFair = mbps >= 10

    // Matrix logic - RPM weighted more heavily
    if rpmExcellent && speedGood { return .excellent }
    if rpmGood && speedGood { return .good }
    if rpmGood && speedFair { return .good }
    if rpmFair && speedGood { return .fair }  // Fast but laggy
    if rpmFair && speedFair { return .fair }
    if rpmFair || speedFair { return .poor }
    return .bad
}
```

### Plain English Status Messages

```swift
func statusMessage(health: ConnectionHealth, issues: [Capability]) -> String {
    switch health {
    case .excellent:
        return "Great for everything"
    case .good:
        return "Good for most activities"
    case .fair:
        if issues.contains(.videoCalls) || issues.contains(.gaming) {
            return "Video calls may stutter"
        }
        return "Some activities may be limited"
    case .poor:
        let issueNames = issues.prefix(2).map { $0.shortName }
        return "\(issueNames.joined(separator: " and ")) won't work well"
    case .bad:
        return "Connection is struggling"
    }
}
```

### Explanation Sentences

```swift
func explanationSentence(rpm: Int, mbps: Double) -> String? {
    let hasBufferbloat = rpm < 500 && mbps > 25
    let isSlow = mbps < 10
    let isUnstable = rpm < 200

    if hasBufferbloat {
        return "Your connection gets sluggish when multiple devices are active."
    } else if isSlow && isUnstable {
        return "Your connection is both slow and unstable."
    } else if isSlow {
        return "Your connection speed is limited."
    } else if isUnstable {
        return "Your connection has high latency, causing delays."
    }
    return nil  // No explanation needed for good connections
}
```

---

## Visual Design Specifications

### Color Palette (macOS Native)

```swift
// Health indicators - subtle, not alarming
let excellentColor = Color(nsColor: .systemGreen).opacity(0.7)
let goodColor = Color(nsColor: .systemGreen).opacity(0.6)
let fairColor = Color(nsColor: .systemYellow).opacity(0.6)
let poorColor = Color(nsColor: .systemOrange).opacity(0.6)
let badColor = Color(nsColor: .systemRed).opacity(0.5)

// Text hierarchy
let primaryText = Color.primary
let secondaryText = Color.secondary
let tertiaryText = Color(nsColor: .tertiaryLabelColor)
let disabledText = Color.primary.opacity(0.35)
```

### Capability Icons

```swift
let capabilityIcons: [Capability: String] = [
    .gaming: "gamecontroller.fill",
    .videoCalls: "video.fill",
    .fourKStreaming: "tv.fill",
    .hdStreaming: "play.rectangle.fill",
    .browsing: "globe",
    .downloads: "arrow.down.circle.fill"
]
```

### Typography

```swift
// Level 1 (Glance)
let healthStatus = Font.system(size: 12, weight: .medium)
let capabilitySummary = Font.system(size: 10)

// Level 2 (Expanded)
let explanationText = Font.system(size: 11)
let activityLabel = Font.system(size: 11)
let activityReason = Font.system(size: 10, weight: .regular)

// Level 3 (Technical)
let metricValue = Font.system(size: 11, weight: .medium, design: .monospaced)
let metricLabel = Font.system(size: 10)
let metricExplanation = Font.system(size: 9)
```

---

## Interaction Design

### Gestures & Transitions

1. **Tap quality section** → Expand/collapse Level 2
   - Animation: 0.2s ease-in-out
   - Chevron rotates to indicate state

2. **Tap "Technical details"** → Expand/collapse Level 3
   - Animation: 0.15s ease-in-out
   - Stays expanded until manually collapsed

3. **Tap refresh button** → Run speed test
   - Recency ring animates to full
   - Live speed graph appears during test

### State Persistence

```swift
@AppStorage("showTechnicalDetails") var showTechnicalDetails = false
@AppStorage("qualityExpanded") var qualityExpanded = false
```

User's expansion preferences persist across sessions.

---

## Implementation Phases

### Phase 1: Restructure Current UI
- Replace capability pills with icon row
- Add plain English status message
- Implement health grade computation
- Add expansion toggle for quality section

### Phase 2: Enhanced Explanations
- Add explanation sentences
- Show "Limited" vs "Works well" sections
- Add human-readable reasons

### Phase 3: Technical Details Panel
- Collapsible technical section
- Add inline explanations (ⓘ)
- Add signal quality from CoreWLAN

### Phase 4: Menu Bar Enhancement
- Add health dot to menu bar icon
- Consider mini tooltip on hover

---

## Success Metrics

1. **Glance comprehension**: User understands health in < 2 seconds
2. **No jargon at L1/L2**: Zero technical terms visible by default
3. **Actionable insights**: User knows if their activity will work
4. **Power user satisfaction**: Technical details available on demand

---

## Open Questions for Review

1. Should the capability icons be labeled at Level 1, or purely visual?
2. Is a letter grade (A/B/C/D/F) more intuitive than colored dots?
3. Should we show "why" explanations proactively, or only when there are issues?
4. How do we handle the "testing in progress" state at each level?
5. Should technical details be in a popover or inline expansion?
