const SITE_CONFIG = {
  gaMeasurementId: "G-0DWSJTXQ65",
  checkoutHost: "kiranjd8.lemonsqueezy.com",
};

const observer = new IntersectionObserver(
  (entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      }
    }
  },
  {
    threshold: 0.16,
    rootMargin: "0px 0px -32px 0px",
  },
);

document.querySelectorAll(".reveal").forEach((node) => observer.observe(node));

const header = document.querySelector("[data-header]");

const updateHeaderState = () => {
  if (!header) return;
  header.classList.toggle("is-scrolled", window.scrollY > 10);
};

const trackEvent = (name, params = {}) => {
  if (typeof window.gtag !== "function") return;
  window.gtag("event", name, params);
};

const getPageContext = () => {
  const path = window.location.pathname.replace(/\/+$/, "") || "/";
  const isBlogIndex = path === "/blog";
  const isBlogPost = path.startsWith("/blog/") && path !== "/blog";
  const pageType = isBlogIndex ? "blog_index" : isBlogPost ? "blog_post" : "site";
  const slug = isBlogPost ? path.slice("/blog/".length) : "";

  return {
    path,
    pageType,
    pageSlug: slug,
  };
};

const getAttributionParams = () => {
  const search = new URLSearchParams(window.location.search);
  const params = {
    utm_source: search.get("utm_source"),
    utm_medium: search.get("utm_medium"),
    utm_campaign: search.get("utm_campaign"),
    utm_term: search.get("utm_term"),
    utm_content: search.get("utm_content"),
    gclid: search.get("gclid"),
    fbclid: search.get("fbclid"),
    msclkid: search.get("msclkid"),
    ttclid: search.get("ttclid"),
    landing_path: window.location.pathname,
    referrer_host: "",
  };

  if (document.referrer) {
    try {
      params.referrer_host = new URL(document.referrer).host;
    } catch {
      params.referrer_host = "";
    }
  }

  return params;
};

const decorateCheckoutLinks = (gaClientId = "") => {
  const attribution = getAttributionParams();
  const links = document.querySelectorAll('a[href*="lemonsqueezy.com/checkout/buy/"]');

  for (const link of links) {
    let url;
    try {
      url = new URL(link.href);
    } catch {
      continue;
    }

    if (url.host !== SITE_CONFIG.checkoutHost) continue;

    for (const [key, value] of Object.entries(attribution)) {
      if (!value) continue;
      url.searchParams.set(key, value);
      url.searchParams.set(`checkout[custom][${key}]`, value);
    }

    if (gaClientId) {
      url.searchParams.set("checkout[custom][ga_client_id]", gaClientId);
    }

    link.href = url.toString();
  }
};

const ensureGA4Bootstrap = async () => {
  if (!SITE_CONFIG.gaMeasurementId) return false;

  window.dataLayer = window.dataLayer || [];
  window.gtag =
    window.gtag ||
    function gtag() {
      window.dataLayer.push(arguments);
    };

  if (!window.__macwifiGAConfigured) {
    const hasScript = document.querySelector(
      `script[src="https://www.googletagmanager.com/gtag/js?id=${SITE_CONFIG.gaMeasurementId}"]`,
    );

    if (!hasScript) {
      await new Promise((resolve, reject) => {
        const script = document.createElement("script");
        script.async = true;
        script.src = `https://www.googletagmanager.com/gtag/js?id=${SITE_CONFIG.gaMeasurementId}`;
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
      }).catch(() => undefined);
    }

    window.gtag("js", new Date());
    window.gtag("config", SITE_CONFIG.gaMeasurementId, {
      anonymize_ip: true,
      send_page_view: false,
    });
    window.__macwifiGAConfigured = true;
  }

  return typeof window.gtag === "function";
};

const loadGA4 = async () => {
  const ready = await ensureGA4Bootstrap();
  if (!ready) return;

  trackEvent("page_view", {
    page_title: document.title,
    page_location: window.location.href,
    page_path: window.location.pathname,
  });

  const pageContext = getPageContext();
  if (pageContext.pageType === "blog_index") {
    trackEvent("blog_index_view", {
      page_path: pageContext.path,
    });
  }

  if (pageContext.pageType === "blog_post") {
    trackEvent("blog_post_view", {
      article_slug: pageContext.pageSlug,
      page_path: pageContext.path,
    });
  }

  window.gtag("get", SITE_CONFIG.gaMeasurementId, "client_id", (clientId) => {
    decorateCheckoutLinks(clientId);
  });
};

const bindEvents = () => {
  const checkoutLinks = document.querySelectorAll('a[href*="lemonsqueezy.com/checkout/buy/"]');
  for (const link of checkoutLinks) {
    link.addEventListener("click", () => {
      trackEvent("checkout_click", {
        location: link.dataset.ctaLocation || "site",
        path: window.location.pathname,
      });
    });
  }

  const trackedLinks = document.querySelectorAll("[data-track-event]");
  for (const node of trackedLinks) {
    node.addEventListener("click", () => {
      trackEvent(node.dataset.trackEvent, {
        location: node.dataset.trackLocation || window.location.pathname,
      });
    });
  }

  const blogLinks = document.querySelectorAll('a[href^="/blog/"]:not([href="/blog/"])');
  for (const link of blogLinks) {
    link.addEventListener("click", () => {
      const slug = (link.getAttribute("href") || "").replace(/^\/blog\//, "").replace(/\/$/, "");
      trackEvent("blog_link_click", {
        article_slug: slug,
        location: link.dataset.trackLocation || window.location.pathname,
      });
    });
  }
};

const BLOG_REFERENCES = {
  zoomBandwidth: {
    label: "Zoom bandwidth requirements",
    href: "https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0060748",
    note: "Official Zoom guidance for HD meetings and connection quality.",
  },
  meetRequirements: {
    label: "Google Meet system requirements",
    href: "https://support.google.com/a/answer/1279090",
    note: "Official Meet bandwidth guidance and setup details.",
  },
  teamsNetwork: {
    label: "Microsoft Teams network planning",
    href: "https://learn.microsoft.com/en-us/microsoftteams/prepare-network",
    note: "Official Teams guidance around network quality and planning.",
  },
  teamsAssessment: {
    label: "Teams Network Assessment Tool",
    href: "https://learn.microsoft.com/en-us/microsoftteams/use-network-testing-companion",
    note: "Microsoft's tool for testing the live-call path and quality metrics.",
  },
  appleWifiIssues: {
    label: "Apple: Resolve Wi-Fi issues on Mac",
    href: "https://support.apple.com/en-in/guide/mac-help/mchl8490d51e/mac",
    note: "Apple's built-in troubleshooting path for Mac Wi-Fi problems.",
  },
  appleWirelessDiagnostics: {
    label: "Apple: Use Wireless Diagnostics on Mac",
    href: "https://support.apple.com/en-us/guide/mac-help/mchlf4de377f/mac",
    note: "Apple's documentation for the hidden Wireless Diagnostics utility.",
  },
  whyfiSite: {
    label: "WhyFi",
    href: "https://whyfi.network/",
    note: "Official product site and feature overview.",
  },
  peakHourSite: {
    label: "PeakHour",
    href: "https://peakhourapp.com/",
    note: "Official site for monitoring and historical traffic tracking.",
  },
  iStatMenusSite: {
    label: "iStat Menus",
    href: "https://bjango.com/mac/istatmenus/",
    note: "Official site for the broader system monitor.",
  },
  netspotSite: {
    label: "NetSpot",
    href: "https://www.netspotapp.com/",
    note: "Official RF scanning and site-survey tooling.",
  },
  wifiExplorerSite: {
    label: "WiFi Explorer",
    href: "https://www.intuitibits.com/products/wifi-explorer/",
    note: "Official Wi-Fi analysis and channel-inspection tooling.",
  },
};

const CALL_SERVICE_TILES = [
  {
    className: "service-tile--zoom",
    label: "Zoom",
    detail: "Use published meeting requirements as a sanity check, not as the whole diagnosis.",
    src: "/assets/blog/zoom-favicon.ico",
    alt: "Zoom icon",
  },
  {
    label: "Google Meet",
    detail: "Meet publishes bandwidth guidance too, which keeps the call-readiness conversation concrete.",
    src: "/assets/blog/google-meet.svg",
    alt: "Google Meet icon",
  },
  {
    className: "service-tile--teams",
    label: "Teams",
    detail: "Teams quality is mostly a consistency conversation: latency, jitter, and packet loss.",
  },
];

const BLOG_ENHANCEMENTS = {
  "how-to-check-if-your-internet-is-good-enough-for-a-video-call-on-mac": {
    kicker: "Call readiness map",
    title: "What matters before you join",
    summary:
      "The useful pre-call split is simple: do the call apps publish enough stable headroom for this scenario, and if the connection still feels risky, is the weak spot local or upstream?",
    badges: ["Call readiness first", "Use official app guidance", "Split Wi-Fi vs upstream"],
    mediaImage: "/assets/wi-fi.png",
    mediaAlt: "MacWiFi screenshot showing call readiness.",
    mediaCaption:
      "A pre-call guide is only helpful if it helps you decide whether to stay, switch SSIDs, or switch networks entirely.",
    tiles: CALL_SERVICE_TILES,
    cards: [
      {
        eyebrow: "Zoom",
        title: "720p is a stability test too",
        body: "Zoom publishes bandwidth guidance for HD calls, but the bigger takeaway is that live upload has to stay stable under pressure.",
      },
      {
        eyebrow: "Google Meet",
        title: "Meet rewards consistency",
        body: "Meet's published guidance is another reminder that a lucky speed test does not guarantee a clean call.",
      },
      {
        eyebrow: "Best next move",
        title: "Switch when the path says switch",
        body: "If the local Wi-Fi side looks clean but the public path does not, stop rearranging the room and change networks.",
      },
    ],
    sources: [BLOG_REFERENCES.zoomBandwidth, BLOG_REFERENCES.meetRequirements, BLOG_REFERENCES.teamsAssessment],
  },
  "how-to-improve-zoom-call-quality-on-mac": {
    kicker: "Zoom triage",
    title: "Fix the part that actually ruins the meeting",
    summary:
      "Most Zoom fixes come from isolating packet loss, loaded latency, and weak local Wi-Fi instead of rerunning another generic speed test.",
    badges: ["Audio first", "Upload matters", "Look for loaded latency"],
    mediaImage: "/assets/advanced-info.png",
    mediaAlt: "MacWiFi advanced diagnostics screenshot.",
    mediaCaption:
      "The useful Zoom question is rarely just 'How fast is it?' It is usually 'What falls apart once the meeting becomes interactive?'",
    tiles: CALL_SERVICE_TILES,
    cards: [
      {
        eyebrow: "Most common",
        title: "Background uploads quietly ruin calls",
        body: "The connection can look fine at idle and then collapse once photos sync, backups start, or another app begins uploading.",
      },
      {
        eyebrow: "Best test",
        title: "Try one alternate network once",
        body: "A hotspot is the fastest way to prove whether the current path is the problem instead of your mic or Zoom settings.",
      },
      {
        eyebrow: "Keep proof",
        title: "Save the diagnosis when upstream is bad",
        body: "If the local Wi-Fi looks fine but the public side does not, save the evidence instead of repeating the same room-level fixes.",
      },
    ],
    sources: [BLOG_REFERENCES.zoomBandwidth, BLOG_REFERENCES.teamsAssessment],
  },
  "zoom-says-your-internet-is-unstable-on-mac": {
    kicker: "Warning translator",
    title: "What Zoom usually means by unstable",
    summary:
      "Zoom's warning is usually about inconsistency, not just low headline speed. The real job is to work out whether that inconsistency starts on your Wi-Fi hop, under load, or farther upstream.",
    badges: ["Warning ≠ just slow", "Look for loss + jitter", "Try one backup network"],
    mediaImage: "/assets/dns-response.png",
    mediaAlt: "MacWiFi DNS and path diagnostics screenshot.",
    mediaCaption:
      "Warnings like this are most useful when they push you toward the next decision, not toward another random speed test.",
    tiles: CALL_SERVICE_TILES,
    cards: [
      {
        eyebrow: "Usually means",
        title: "The path is inconsistent",
        body: "Short bursts of loss, jitter, or loaded latency can trigger the warning even when the Wi-Fi icon still looks normal.",
      },
      {
        eyebrow: "Fastest check",
        title: "Pause heavy uploads",
        body: "If the warning disappears after cloud sync or uploads stop, the issue is loaded behavior, not idle capacity.",
      },
      {
        eyebrow: "Most useful split",
        title: "Local hop or after-router path",
        body: "That tells you whether to move closer, change SSIDs, or keep proof for the ISP instead.",
      },
    ],
    sources: [BLOG_REFERENCES.zoomBandwidth, BLOG_REFERENCES.teamsAssessment],
  },
  "connected-to-wifi-but-no-internet-on-mac": {
    kicker: "Symptom map",
    title: "Why this failure wastes so much time",
    summary:
      "The local Wi-Fi link can still be alive while DNS, the router, or the public path after the router is the part that actually failed. That is why this symptom feels so misleading.",
    badges: ["Router reachable", "DNS can still fail", "Public path can still fail"],
    mediaImage: "/assets/dns-response.png",
    mediaAlt: "MacWiFi screenshot showing DNS response diagnostics.",
    mediaCaption:
      "This is the kind of split that matters when the icon still says connected but the internet is effectively gone.",
    cards: [
      {
        eyebrow: "Usually means",
        title: "Your Mac still sees the router",
        body: "Connected Wi-Fi only proves the local hop is up. It does not prove usable internet beyond it.",
      },
      {
        eyebrow: "Best next check",
        title: "Compare local and public path health",
        body: "If the router side is clean but the public side is failing, stop blaming the Wi-Fi bars.",
      },
      {
        eyebrow: "Often missed",
        title: "DNS can feel like a full outage",
        body: "When names stop resolving, normal browsing can look dead even though the underlying link is still alive.",
      },
    ],
    sources: [BLOG_REFERENCES.appleWifiIssues, BLOG_REFERENCES.appleWirelessDiagnostics],
  },
  "how-to-tell-if-wifi-or-isp-is-the-problem": {
    kicker: "Blame split",
    title: "The cleanest diagnosis loop on Mac",
    summary:
      "This guide is most helpful when it stops random restarts and vague blame. The key split is local Wi-Fi behavior versus the public path after the router.",
    badges: ["Local first", "Then public path", "Change one thing at a time"],
    mediaImage: "/assets/advanced-info.png",
    mediaAlt: "MacWiFi advanced information screenshot.",
    mediaCaption:
      "If the local side and the public side do not agree, you already have a better next move than most default troubleshooting gives you.",
    cards: [
      {
        eyebrow: "Wi-Fi side clue",
        title: "Weakness changes with your position",
        body: "If the issue improves dramatically when you move or switch bands, the local wireless hop is telling on itself.",
      },
      {
        eyebrow: "ISP-side clue",
        title: "Router looks fine but the internet does not",
        body: "That is the classic signal that the weak spot is farther upstream than your room or access point.",
      },
      {
        eyebrow: "Best move",
        title: "Run one alternate-network sanity check",
        body: "A hotspot or different SSID can save an hour of speculation if it fixes the problem immediately.",
      },
    ],
    sources: [BLOG_REFERENCES.appleWifiIssues, BLOG_REFERENCES.teamsAssessment],
  },
  "should-you-restart-your-router-or-call-your-isp-on-mac": {
    kicker: "Action filter",
    title: "Choose the next move that is least stupid",
    summary:
      "This problem is mostly about avoiding busywork. If the local hop looks weak, router-level fixes make sense. If the public side looks bad while the local side looks clean, that is a different conversation.",
    badges: ["Restart less randomly", "Call with evidence", "Use the path split"],
    mediaImage: "/assets/dns-response.png",
    mediaAlt: "MacWiFi diagnostics screenshot separating local and public checks.",
    mediaCaption:
      "The point is not to avoid ever restarting the router. It is to restart it for the right reason instead of by reflex.",
    cards: [
      {
        eyebrow: "Restart first when",
        title: "The local side looks flaky",
        body: "Intermittent local reachability, poor SSID behavior, or router-side weirdness are the cleanest restart cases.",
      },
      {
        eyebrow: "Call first when",
        title: "The local side is fine but the path is not",
        body: "At that point the reset button is often just a way to postpone the real call you need to make.",
      },
      {
        eyebrow: "Best outcome",
        title: "Change one variable and recheck",
        body: "That keeps you from turning a simple diagnosis into a pile of unrelated fixes.",
      },
    ],
    sources: [BLOG_REFERENCES.appleWifiIssues, BLOG_REFERENCES.teamsAssessment],
  },
  "wi-fi-keeps-disconnecting-on-mac-what-to-check-first": {
    kicker: "Disconnect map",
    title: "Not every dropout is the same failure",
    summary:
      "The first question is whether the Mac is losing the wireless association entirely, staying connected while internet access dies, or bouncing between bad network choices under pressure.",
    badges: ["Association drops", "Path drops", "Roaming mistakes"],
    mediaImage: "/assets/wi-fi.png",
    mediaAlt: "MacWiFi main status screenshot.",
    mediaCaption:
      "Repeated disconnects are easier to fix once you stop treating the local radio, DNS trouble, and upstream reliability as the same thing.",
    cards: [
      {
        eyebrow: "Best clue",
        title: "Notice what actually disappears",
        body: "The Wi-Fi icon dropping is a different problem from websites hanging while Wi-Fi still looks connected.",
      },
      {
        eyebrow: "Fastest test",
        title: "Check one other device",
        body: "If everything on the same network is unhappy, the Mac is less likely to be the only culprit.",
      },
      {
        eyebrow: "Good fallback",
        title: "Try one alternate network once",
        body: "The backup network tells you quickly whether you are fighting the current path or the machine itself.",
      },
    ],
    sources: [BLOG_REFERENCES.appleWifiIssues, BLOG_REFERENCES.appleWirelessDiagnostics],
  },
  "how-to-pick-the-best-wifi-network-on-mac": {
    kicker: "Network choice",
    title: "Choose the network that survives real work",
    summary:
      "Picking the best network is not just picking the strongest bars. The right network is the one whose local hop and upstream path stay calm enough for the task you care about next.",
    badges: ["Bars are not enough", "Stability beats optimism", "Call first, not after"],
    mediaImage: "/assets/wi-fi.png",
    mediaAlt: "MacWiFi screenshot showing main Wi-Fi details.",
    mediaCaption:
      "The best network is the one that stays usable under the task you are actually about to do, not the one that merely looks strongest for a second.",
    cards: [
      {
        eyebrow: "Hotel / coworking",
        title: "Prefer the calmer path",
        body: "Public Wi-Fi is often less about raw speed and more about whether the path becomes ugly once the room gets busy.",
      },
      {
        eyebrow: "Best quick check",
        title: "Compare two options back to back",
        body: "You learn more from a short A/B check than from trusting whichever SSID happens to look familiar.",
      },
      {
        eyebrow: "If both look bad",
        title: "Use the hotspot sooner",
        body: "Sometimes the best network choice is leaving the network category entirely for the call that matters.",
      },
    ],
    sources: [BLOG_REFERENCES.zoomBandwidth, BLOG_REFERENCES.meetRequirements],
  },
  "how-to-check-packet-loss-on-mac": {
    kicker: "Packet loss map",
    title: "Why packet loss feels worse than a mediocre speed test",
    summary:
      "Packet loss is one of the quickest ways to make live audio sound broken while the connection still looks vaguely online. This guide is about seeing that difference earlier.",
    badges: ["Live traffic hates loss", "Compare local vs public", "Loss can hide in bursts"],
    mediaImage: "/assets/advanced-info.png",
    mediaAlt: "MacWiFi advanced info screenshot showing diagnostics.",
    mediaCaption:
      "Loss matters most when it stacks with interaction, which is why calls expose it faster than passive browsing does.",
    cards: [
      {
        eyebrow: "What you notice first",
        title: "Choppy audio and robotic voices",
        body: "Calls usually reveal packet loss before speed tests do because missed packets are immediately obvious in live media.",
      },
      {
        eyebrow: "Best comparison",
        title: "Router path versus public path",
        body: "That split helps you decide whether the loss starts inside your network or after it.",
      },
      {
        eyebrow: "Easy mistake",
        title: "Trusting one clean idle test",
        body: "Loss often shows up under load or in short ugly bursts, which is why one quick result can miss it.",
      },
    ],
    sources: [BLOG_REFERENCES.teamsAssessment, BLOG_REFERENCES.appleWirelessDiagnostics],
  },
  "how-to-check-jitter-on-mac": {
    kicker: "Jitter map",
    title: "Why averages can lie during a call",
    summary:
      "Jitter is not just latency. It is unstable latency, which is why an average number can look acceptable while the conversation still feels ragged and out of rhythm.",
    badges: ["Latency swings", "Calls expose it fast", "Loaded paths get ugly"],
    mediaImage: "/assets/advanced-info.png",
    mediaAlt: "MacWiFi advanced information screenshot.",
    mediaCaption:
      "Jitter matters because the problem is not the average trip time. It is the lack of consistency from moment to moment.",
    cards: [
      {
        eyebrow: "What it feels like",
        title: "Voices step on each other",
        body: "Jitter shows up as uneven timing, gaps, and the strange half-second rhythm that makes meetings exhausting.",
      },
      {
        eyebrow: "Best next check",
        title: "See what happens under load",
        body: "A path that is calm at idle can get much worse when uploads or backups start.",
      },
      {
        eyebrow: "Useful split",
        title: "Local instability or public instability",
        body: "That tells you whether to move, change networks, or keep evidence for the provider instead.",
      },
    ],
    sources: [BLOG_REFERENCES.teamsAssessment, BLOG_REFERENCES.zoomBandwidth],
  },
  "how-to-use-networkquality-on-mac": {
    kicker: "Apple tool translator",
    title: "Where Apple's built-in test helps and where it stops",
    summary:
      "networkQuality is useful as a clue. It becomes genuinely helpful when you combine it with the task in front of you and with a cleaner split between local Wi-Fi trouble and upstream trouble.",
    badges: ["Quick clue", "Not the whole diagnosis", "Compare networks, not just numbers"],
    mediaImage: "/assets/advanced-info.png",
    mediaAlt: "MacWiFi advanced diagnostics screenshot used alongside Apple's networkQuality test.",
    mediaCaption:
      "The most useful role for networkQuality is a quick built-in comparison, not a final verdict on whether every call will be fine.",
    tiles: [
      {
        label: "networkQuality",
        detail: "A quick built-in check for throughput and responsiveness on macOS.",
        src: "/assets/blog/apple-network-tool.png",
        alt: "Apple network tool icon",
      },
      {
        label: "MacWiFi",
        detail: "Better when you need the result translated into a practical next move.",
        src: "/assets/icon.png",
        alt: "MacWiFi icon",
      },
    ],
    cards: [
      {
        eyebrow: "Good for",
        title: "A quick before-and-after check",
        body: "It is handy when you want to compare one SSID against another or see whether a restart changed anything.",
      },
      {
        eyebrow: "Not enough for",
        title: "Explaining every bad call",
        body: "One score cannot tell you whether the pain is DNS, packet loss, jitter, or something only visible under real load.",
      },
      {
        eyebrow: "Best follow-up",
        title: "Add a local-vs-upstream split",
        body: "That turns a generic score into a diagnosis you can actually act on.",
      },
    ],
    sources: [BLOG_REFERENCES.appleWifiIssues, BLOG_REFERENCES.appleWirelessDiagnostics],
  },
  "how-to-use-wireless-diagnostics-on-mac": {
    kicker: "Apple tool translator",
    title: "Use the utility for the part it is actually good at",
    summary:
      "Wireless Diagnostics is strongest when you already suspect the local Wi-Fi side. It is less useful when the pain lives in DNS, the router's upstream path, or the wider internet.",
    badges: ["Good for local Wi-Fi", "Not for every outage", "Translate into next steps"],
    mediaImage: "/assets/blog/whyfi-main-panel.png",
    mediaAlt: "A network diagnostics panel used as a visual comparison for richer Wi-Fi tooling.",
    mediaCaption:
      "The point of a diagnostic utility is not just more fields. It is whether those fields help you decide what to change next.",
    tiles: [
      {
        label: "Wireless Diagnostics",
        detail: "Apple's deeper Wi-Fi-side utility when the local hop looks suspicious.",
        src: "/assets/blog/apple-wireless-diagnostics.png",
        alt: "Apple Wireless Diagnostics icon",
      },
      {
        label: "MacWiFi",
        detail: "Stronger when the question is 'What should I do next?' rather than 'What fields can I open?'",
        src: "/assets/icon.png",
        alt: "MacWiFi icon",
      },
    ],
    cards: [
      {
        eyebrow: "Good for",
        title: "Local wireless suspicion",
        body: "If the signal, band, or access-point side feels wrong, this is the right Apple tool to reach for.",
      },
      {
        eyebrow: "Not enough for",
        title: "Call-readiness and upstream blame",
        body: "It is not the cleanest way to answer whether the problem is DNS, your ISP path, or the wider internet.",
      },
      {
        eyebrow: "Best follow-up",
        title: "Translate the clue into an action",
        body: "Once you think the local hop is fine, widen the diagnosis instead of staying inside the same Apple utility forever.",
      },
    ],
    sources: [BLOG_REFERENCES.appleWirelessDiagnostics, BLOG_REFERENCES.appleWifiIssues],
  },
  "best-wifi-analyzer-for-mac": {
    kicker: "Decision frame",
    title: "Choose the category before the app",
    summary:
      "This comparison gets better once you stop asking for one magic winner. The real question is whether you need RF detail, historical monitoring, or plain-language diagnosis for work that has to survive now.",
    badges: ["Pick the job first", "RF tools are different", "Monitors are different"],
    mediaImage: "/assets/blog/whyfi-main-panel.png",
    mediaAlt: "WhyFi panel screenshot used in the comparison cluster.",
    mediaCaption:
      "Comparison pages are most useful when they help people choose the category that matches the job, not just the app with the biggest feature list.",
    comparisons: [
      {
        title: "MacWiFi",
        note: "Best when you want call readiness and a clean Wi-Fi-vs-upstream diagnosis.",
        emphasis: "Normal people, urgent decisions",
      },
      {
        title: "WhyFi / PeakHour",
        note: "Better if you want always-on monitoring behavior or a dedicated network utility feel.",
        emphasis: "Lighter monitor category",
      },
      {
        title: "NetSpot / WiFi Explorer",
        note: "Best for RF scanning, channels, interference, and survey-style work.",
        emphasis: "RF and site work",
      },
    ],
    cards: [
      {
        eyebrow: "Mistake to avoid",
        title: "Treating RF tools like readiness tools",
        body: "A brilliant channel analyzer is still not the same thing as a plain answer about whether the next Zoom call is risky.",
      },
      {
        eyebrow: "Best buyer fit",
        title: "Choose by consequence",
        body: "If the job is high-consequence calls from sketchy networks, the best tool is not necessarily the one with the deepest survey view.",
      },
      {
        eyebrow: "Good comparison habit",
        title: "Open the official product pages",
        body: "The official product pages usually tell you quickly which job the tool is built to do.",
      },
    ],
    sources: [
      BLOG_REFERENCES.whyfiSite,
      BLOG_REFERENCES.peakHourSite,
      BLOG_REFERENCES.netspotSite,
      BLOG_REFERENCES.wifiExplorerSite,
    ],
  },
  "best-internet-monitor-for-mac-menu-bar": {
    kicker: "Menu bar tradeoffs",
    title: "Pick the tool that answers the right question first",
    summary:
      "Menu bar network tools feel similar until you ask what answer you actually want. Some are built to monitor everything. Some are built to help you make one decision fast.",
    badges: ["Dashboard vs diagnosis", "History vs quick answers", "Menu bar fit"],
    mediaImage: "/assets/wi-fi.png",
    mediaAlt: "MacWiFi main menu bar screenshot.",
    mediaCaption:
      "A menu bar tool earns its place when it shortens decisions, not when it simply adds another panel to watch.",
    comparisons: [
      {
        title: "MacWiFi",
        note: "Best when you want to know if the connection is usable right now and what to blame first.",
        emphasis: "Quick diagnosis",
      },
      {
        title: "PeakHour",
        note: "Stronger if you want bandwidth history, trend monitoring, and a heavier monitoring posture.",
        emphasis: "Longer-running monitor",
      },
      {
        title: "iStat Menus",
        note: "Better when the job is broad system monitoring rather than network-specific diagnosis.",
        emphasis: "System dashboard",
      },
    ],
    cards: [
      {
        eyebrow: "Start here",
        title: "What answer do you want first?",
        body: "If the first answer you want is network-specific blame, broad dashboard tools can feel busier than they are helpful.",
      },
      {
        eyebrow: "Keep it running if",
        title: "The app earns its menu bar seat",
        body: "Always-on utilities need a clear reason to stay there. Fast diagnosis and pre-call confidence are stronger reasons than generic traffic graphs alone.",
      },
      {
        eyebrow: "Useful split",
        title: "History versus urgency",
        body: "Pick historical monitors for trend work. Pick diagnosis tools for stressful moments.",
      },
    ],
    sources: [BLOG_REFERENCES.peakHourSite, BLOG_REFERENCES.iStatMenusSite, BLOG_REFERENCES.whyfiSite],
  },
  "whyfi-alternative-for-mac": {
    kicker: "WhyFi vs MacWiFi",
    title: "Where each app feels different in daily use",
    summary:
      "WhyFi and MacWiFi overlap, but the difference becomes clearer once you ask whether you want a lighter Wi-Fi health readout or a stronger call-readiness and Wi-Fi-vs-upstream diagnosis view.",
    badges: ["Call readiness", "Wi-Fi health", "Menu bar workflow"],
    mediaImage: "/assets/blog/whyfi-main-panel.png",
    mediaAlt: "WhyFi dashboard screenshot from the official product site.",
    mediaCaption:
      "WhyFi's dashboard is useful context for how it presents ongoing Wi-Fi condition and network health.",
    comparisons: [
      {
        title: "Choose MacWiFi if",
        note: "You want plainer answers about whether the connection can handle the next call and whether the problem is local or upstream.",
        emphasis: "Outcome-first diagnosis",
      },
      {
        title: "Choose WhyFi if",
        note: "You prefer a lighter Wi-Fi health readout and like its presentation of ongoing condition checks.",
        emphasis: "Lighter health view",
      },
      {
        title: "Choose heavier tools if",
        note: "You really need longer-running history, remote access, or heavier proof-building instead of a quick menu bar decision helper.",
        emphasis: "Monitoring / evidence",
      },
    ],
    cards: [
      {
        eyebrow: "Start here",
        title: "How quickly can you act from the answer?",
        body: "The better tool for you is the one that makes the next move obvious under pressure.",
      },
      {
        eyebrow: "Where MacWiFi is stronger",
        title: "Call-risk and path-splitting language",
        body: "That is especially helpful for people joining important meetings from home, hotel, or coworking networks.",
      },
      {
        eyebrow: "Where WhyFi is useful",
        title: "Always-on Wi-Fi condition checking",
        body: "If that simpler readout fits the way you check network problems, the overlap is still real and worth comparing honestly.",
      },
    ],
    sources: [BLOG_REFERENCES.whyfiSite, BLOG_REFERENCES.peakHourSite],
  },
};

const slugifyHeading = (text) =>
  text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

const renderTopicPills = (badges = []) =>
  badges.map((badge) => `<span class="topic-pill">${badge}</span>`).join("");

const renderServiceTiles = (tiles = []) => {
  if (!tiles.length) return "";

  return `
    <div class="service-rail">
      ${tiles
        .map(
          (tile) => `
            <div class="service-tile ${tile.className || ""}">
              ${tile.src ? `<img src="${tile.src}" alt="${tile.alt || tile.label}" loading="lazy" />` : ""}
              <strong>${tile.label}</strong>
              <span>${tile.detail}</span>
            </div>
          `,
        )
        .join("")}
    </div>
  `;
};

const renderComparisonCards = (comparisons = []) => {
  if (!comparisons.length) return "";

  return `
    <div class="comparison-mini-grid">
      ${comparisons
        .map(
          (item) => `
            <div class="comparison-mini-card">
              <strong>${item.title}</strong>
              <span>${item.note}</span>
              <em>${item.emphasis}</em>
            </div>
          `,
        )
        .join("")}
    </div>
  `;
};

const renderInsightCards = (cards = []) => {
  if (!cards.length) return "";

  return `
    <div class="insight-cards">
      ${cards
        .map(
          (card) => `
            <div class="insight-card">
              <span class="insight-card-eyebrow">${card.eyebrow}</span>
              <strong>${card.title}</strong>
              <p>${card.body}</p>
            </div>
          `,
        )
        .join("")}
    </div>
  `;
};

const renderInsightModule = (config) => `
  <section class="article-insight">
    <div class="article-insight-copy">
      <p class="insight-kicker">${config.kicker}</p>
      <h2>${config.title}</h2>
      <p class="insight-summary">${config.summary}</p>
      ${config.badges?.length ? `<div class="insight-badges">${renderTopicPills(config.badges)}</div>` : ""}
    </div>
    ${config.mediaImage || config.tiles?.length || config.comparisons?.length
      ? `
        <div class="article-insight-media">
          ${
            config.mediaImage
              ? `
                <figure class="insight-figure">
                  <img src="${config.mediaImage}" alt="${config.mediaAlt || ""}" loading="lazy" />
                  ${config.mediaCaption ? `<figcaption>${config.mediaCaption}</figcaption>` : ""}
                </figure>
              `
              : ""
          }
          ${renderServiceTiles(config.tiles)}
          ${renderComparisonCards(config.comparisons)}
        </div>
      `
      : ""}
  </section>
  ${renderInsightCards(config.cards)}
`;

const renderAsideCard = (title, innerHtml) => `
  <div class="aside-card">
    <h3>${title}</h3>
    ${innerHtml}
  </div>
`;

const buildReadingPill = (articleBody) => {
  const words = (articleBody.textContent || "").trim().split(/\s+/).filter(Boolean).length;
  const minutes = Math.max(2, Math.round(words / 220));
  return `<span class="reading-pill">${minutes} min read</span>`;
};

const buildTocCard = (articleBody) => {
  const headings = [...articleBody.querySelectorAll("h2")];
  if (headings.length < 2) return "";

  const links = headings
    .map((heading) => {
      if (!heading.id) {
        heading.id = slugifyHeading(heading.textContent || "");
      }

      return `
        <a href="#${heading.id}">
          <strong>${heading.textContent || ""}</strong>
          <span>Jump to section</span>
        </a>
      `;
    })
    .join("");

  return renderAsideCard("In This Guide", `<div class="toc-list">${links}</div>`);
};

const buildSourcesCard = (sources = []) => {
  if (!sources.length) return "";

  const links = sources
    .map(
      (source) => `
        <a class="source-link" href="${source.href}" target="_blank" rel="noreferrer">
          <strong>${source.label}</strong>
          <span>${source.note}</span>
        </a>
      `,
    )
    .join("");

  return renderAsideCard("Useful References", `<div class="source-list">${links}</div>`);
};

const renderInlinePricingBlock = (variant = "intro") => {
  if (variant === "closing") {
    return `
      <section class="inline-pricing-block inline-pricing-block--closing" aria-label="MacWiFi pricing">
        <p>
          If you would rather skip the manual checks next time,
          <a href="/pricing">see the MacWiFi page</a>
          and use the menu bar app that turns this into a quick local-versus-upstream read.
        </p>
        <span class="inline-pricing-block-label">See MacWiFi</span>
      </section>
    `;
  }

  return `
    <section class="inline-pricing-block inline-pricing-block--intro" aria-label="MacWiFi pricing">
      <p>
        Want the short version?
        <a href="/pricing">See the MacWiFi page</a>
        if you want these checks condensed into one quick menu bar answer before the next call.
      </p>
      <span class="inline-pricing-block-label">MacWiFi</span>
    </section>
  `;
};

const addInlinePricingBlocks = (articleBody) => {
  if (!articleBody || articleBody.dataset.pricingBlocksAdded) return;
  articleBody.dataset.pricingBlocksAdded = "true";

  const paragraphs = [...articleBody.querySelectorAll(":scope > p")];
  const firstSubstantiveParagraph =
    paragraphs.find((paragraph) => (paragraph.textContent || "").trim().length >= 120) || paragraphs[0];

  if (firstSubstantiveParagraph) {
    firstSubstantiveParagraph.insertAdjacentHTML("afterend", renderInlinePricingBlock("intro"));
  }

  const trailingTarget = [...articleBody.children]
    .reverse()
    .find(
      (element) =>
        !element.classList?.contains("inline-pricing-block") &&
        !/^H2$/i.test(element.tagName),
    );

  if (trailingTarget) {
    trailingTarget.insertAdjacentHTML("afterend", renderInlinePricingBlock("closing"));
  } else {
    articleBody.insertAdjacentHTML("beforeend", renderInlinePricingBlock("closing"));
  }
};

const enhanceBlogPost = () => {
  const { pageType, pageSlug } = getPageContext();
  if (pageType !== "blog_post") return;

  const config = BLOG_ENHANCEMENTS[pageSlug];
  const articleShell = document.querySelector(".article-shell");
  const articleLead = articleShell?.querySelector(".article-lead");
  const articleBody = articleShell?.querySelector(".article-body");
  const articleMeta = articleShell?.querySelector(".article-meta");
  const articleAside = document.querySelector(".article-aside");

  if (!articleShell || !articleLead || !articleBody || articleShell.dataset.richEnhanced) return;
  articleShell.dataset.richEnhanced = "true";

  if (config) {
    articleLead.insertAdjacentHTML("afterend", renderInsightModule(config));
  }

  addInlinePricingBlocks(articleBody);

  if (articleMeta && !articleMeta.querySelector(".reading-pill")) {
    articleMeta.insertAdjacentHTML("beforeend", buildReadingPill(articleBody));
  }

  if (articleAside) {
    const tocCard = buildTocCard(articleBody);
    const sourcesCard = buildSourcesCard(config?.sources || []);
    articleAside.insertAdjacentHTML("afterbegin", `${sourcesCard}${tocCard}`);
  }
};

updateHeaderState();
window.addEventListener("scroll", updateHeaderState, { passive: true });
decorateCheckoutLinks();
bindEvents();
enhanceBlogPost();
loadGA4();
