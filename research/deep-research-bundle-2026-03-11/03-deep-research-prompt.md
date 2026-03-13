# Deep Research Prompt: MacWiFi

You are conducting deep product, market, and positioning research for a paid `macOS` utility called `MacWiFi`.

Use the attached context files and media assets as the ground truth for what the product currently is. Do not rely on generic assumptions about Wi-Fi apps. Read the feature inventory, inspect the screenshots and demo video, and then research the external market using current public sources available at the time you run this analysis.

## Mission

Figure out how to shape `MacWiFi` into something useful that people will genuinely pay for.

The founder's current starting point is broad:

- they originally wanted a better version of the built-in Mac Wi-Fi menu
- they care about fixing the weaknesses of the default macOS Wi-Fi menu
- they have been posting and talking about the app from a developer/product-builder perspective
- the app already includes more than menu replacement: it also diagnoses connection quality, shows activity readiness, and tries to separate Wi-Fi-side issues from ISP-side issues

Your job is to determine:

- who the best target audience really is
- what job the product should own first
- what competitive position is most defensible
- what current features are valuable
- what gaps block willingness to pay
- how the product should be packaged and messaged so it feels worth paying for

## Commercial success criteria

Do not answer this as an abstract branding exercise. Anchor your judgment to measurable commercial outcomes.

Define what "people will genuinely pay for this" should mean for a product like this, such as:

- plausible visit-to-buy conversion target
- plausible trial-to-paid target if you recommend a trial
- likely willingness-to-pay ceiling for the initial wedge
- rough CAC tolerance for likely acquisition channels
- what evidence would prove the wedge is working

## Inputs you should use

You have access to:

- a feature inventory file describing current shipped capabilities
- a grouped media inventory
- screenshots of the app
- demo videos
- website and marketing mockups

Treat those materials as evidence.

## Product context to anchor on

Current truth from the repo:

- Product name: `MacWiFi`
- Platform: `macOS`
- Format: menu bar app
- Current public price in repo copy: `$9.99 one-time`
- Current commercial framing:
  - no account
  - direct purchase and download
  - in-app license activation
- Repeated product claims:
  - know what your internet can actually do right now
  - find out if it's your Wi-Fi or your ISP
  - calls / streaming / browsing readiness
  - native macOS diagnostics for normal people

Current shipped capability clusters:

- menu bar Wi-Fi utility behavior
- network scanning and connect / disconnect controls
- active speed and responsiveness testing
- plain-English reliability diagnosis
- activity readiness for calls, streaming, and browsing
- Wi-Fi-vs-ISP issue attribution
- advanced diagnostics such as packet loss, jitter, latency, DNS timing, and radio details
- clipboard export of diagnostics

Current product tension:

- one possible wedge is "better built-in Mac Wi-Fi menu"
- another possible wedge is "connection confidence and blame diagnosis"
- another possible wedge is "lightweight home or travel troubleshooting"

Research should resolve that tension instead of glossing over it.

## Research questions to answer

### 1. Target audience and ICP

Identify and rank the most promising audiences for this product.

For each audience, evaluate:

- pain intensity
- frequency of pain
- existing substitute behavior
- willingness to pay
- urgency
- message clarity
- fit with current shipped features
- likely acquisition channels

Potential audiences to test include, but do not limit yourself to:

- remote workers on video calls
- freelancers / consultants / recruiters / support people
- digital nomads and frequent travelers
- non-technical home users
- the "household IT person"
- tech-savvy prosumers
- gamers / streamers
- indie developers
- support agents or customer-facing workers

Do not just say "broad audience." Force prioritization.

For the top two audiences, also write the full JTBD timeline:

- trigger
- struggle moment
- current workaround
- desired outcome
- switching trigger
- hesitation or fear before paying

### 2. Competitor and substitute landscape

Research direct and indirect competitors on macOS, especially tools that overlap with one or more of these jobs:

- better Wi-Fi menu / network picker
- network quality or internet health diagnosis
- menu bar connectivity visibility
- call-readiness or troubleshooting
- ongoing network monitoring

At minimum, examine whether these are relevant and how they compare:

- WhyFi
- PeakHour
- iStat Menus
- PingPlotter
- Ookla Speedtest for Mac
- WiFi Explorer / WiFi Explorer Pro
- NetSpot
- AirRadar
- WiFi Signal
- Signal Peek
- TripMode
- Little Snitch
- built-in macOS Wireless Diagnostics

For each serious competitor or substitute, capture:

- product category
- target user
- core job-to-be-done
- pricing
- product strengths
- product weaknesses
- where MacWiFi is stronger
- where MacWiFi is weaker
- how easy or hard it would be to differentiate

Where available, also capture:

- current price
- review count
- average rating
- last update date
- free trial shape
- refund policy
- paywall or pricing-page framing

Also identify which competitors are:

- the closest direct threat
- the strongest substitute
- the easiest to beat with positioning
- the hardest to beat without product expansion

### 3. Positioning strategy

Determine the best positioning options for MacWiFi given the current product.

Compare and rank possible positions such as:

- better built-in Mac Wi-Fi menu
- know if your next call will hold up
- find out if it's your Wi-Fi or your ISP
- internet reliability for normal Mac users
- menu bar troubleshooting utility
- lightweight home / travel network evaluator

For each positioning option, assess:

- clarity
- distinctiveness
- emotional resonance
- ability to command payment
- fit with current screenshots and UI
- credibility based on shipped features
- room for future expansion

Then recommend one primary position and one backup position.

### 4. Value for money and monetization

Assess whether the current product, as implemented, feels worth `$9.99 one-time`.

Then answer:

- what makes it feel worth paying for today
- what makes it feel too thin today
- which current features drive perceived value
- which features are necessary but not monetizable
- which future additions would materially increase willingness to pay

Recommend a packaging model:

- one-time paid only
- free plus paid unlock
- free trial plus paid unlock
- one-time purchase with optional pro tier
- subscription only if genuinely justified

If you recommend paid boundaries, specify exactly what should be:

- free
- paid
- premium or pro later

Do not default to subscription unless the product genuinely supports ongoing high-value behavior.

Also model simple monetization scenarios:

- price points: `$4.99`, `$9.99`, `$19.99`
- pricing shapes: one-time vs yearly
- rough revenue implications at `1k`, `5k`, and `10k` paid users
- what conversion assumptions would need to be true for each scenario to make sense

### 5. Product direction and roadmap leverage

Based on the current product and market, identify the best next-step features that would strengthen:

- retention
- differentiation
- willingness to pay
- word-of-mouth
- credibility

Prioritize features that fit the product's current DNA, for example:

- pre-call or pre-meeting checks
- per-network history or memory
- stronger action recommendations
- exportable "proof" for ISP disputes
- smart network sorting by likely quality
- traveler / hotspot workflows
- household troubleshooting workflows

Also call out feature ideas that sound nice but are actually a distraction.

### 6. Messaging and sellability

Based on the current app and market research, produce:

- homepage headline and subheadline options
- App Store-style one-liners
- Product Hunt-style positioning
- ad or social hooks
- comparison-page angles
- credibility proof points
- language to avoid

Evaluate whether the current messaging leans too technical, too broad, or too founder-centric.

Also list the top five purchase objections specific to this product and the best copy, proof, or product move to reduce each objection.

### 7. Visual and screenshot interpretation

Inspect the attached screenshots and videos.

Tell me:

- what user you think the visuals are currently speaking to
- what they imply the product is
- what they fail to communicate
- whether the visuals support a paid utility purchase
- what screenshot order and emphasis would best support conversion

## Output format

Return the analysis in this exact structure:

1. Executive conclusion
2. Best primary target audience
3. Secondary target audience
4. Competitor matrix
5. Best positioning statement
6. Top 3 reasons someone would pay today
7. Top 3 reasons someone would hesitate to pay today
8. Recommended pricing and packaging
9. Recommended wedge feature set to emphasize now
10. Recommended next features to build
11. Messaging recommendations
12. Screenshot and asset recommendations
13. 30-day validation plan
14. 90-day product direction

## Output quality bar

I do not want generic SaaS advice.

I want concrete, product-specific judgment based on:

- the current product truth
- current competitors
- evidence from the assets
- real willingness-to-pay logic

If you recommend a segment or positioning, explain why it is better than the obvious alternatives.

If you recommend product changes, tie each change to:

- a target user
- a buying reason
- a competitive advantage
- a likely commercial outcome

## Research standards

- Use current public sources, not stale summaries.
- Verify current pricing and product status where possible.
- Prefer official product pages, App Store pages, product reviews, user discussions, and launch materials.
- Distinguish direct competitors from substitutes.
- Be explicit when you are inferring from the available evidence.
- Cite sources or link them when possible.

## Final decision question

At the end, answer this directly:

If you had to make `MacWiFi` a genuinely compelling paid Mac utility in the next 90 days, what exact audience would you pick, what exact promise would you lead with, and which exact features would you emphasize or add first to make the app feel obviously worth paying for?
