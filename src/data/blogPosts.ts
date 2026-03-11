export type BlogPost = {
  slug: string
  title: string
  description: string
}

export const blogPosts: BlogPost[] = [
  {
    slug: 'connected-to-wifi-but-no-internet-on-mac',
    title: 'Connected to Wi-Fi but No Internet on Mac',
    description: 'Why the Wi-Fi icon can still look fine while the connection is effectively unusable.',
  },
  {
    slug: 'wi-fi-keeps-disconnecting-on-mac-what-to-check-first',
    title: 'Wi-Fi Keeps Disconnecting on Mac: What to Check First',
    description: 'A practical first-pass checklist for when the connection drops, returns, and wastes half the morning.',
  },
  {
    slug: 'how-to-check-if-your-internet-is-good-enough-for-a-video-call-on-mac',
    title: 'How to Check if Your Internet Is Good Enough for a Video Call on Mac',
    description: 'A practical guide for remote workers who want to know if a connection is actually ready for Zoom, Meet, or Teams.',
  },
  {
    slug: 'zoom-says-your-internet-is-unstable-on-mac',
    title: 'Zoom Says Your Internet Is Unstable on Mac',
    description: 'What that warning usually means and how to separate Wi-Fi trouble from upstream trouble before the call gets worse.',
  },
  {
    slug: 'how-to-pick-the-best-wifi-network-on-mac',
    title: 'How to Pick the Best Wi-Fi Network on Mac',
    description: 'What to do when there are multiple nearby networks and the built-in menu does not help you choose well.',
  },
  {
    slug: 'should-you-restart-your-router-or-call-your-isp-on-mac',
    title: 'Should You Restart Your Router or Call Your ISP on Mac?',
    description: 'A plain troubleshooting path for the person everybody asks when the home internet starts acting up.',
  },
  {
    slug: 'best-wifi-analyzer-for-mac',
    title: 'Best Wi-Fi Analyzer for Mac',
    description: 'What to look for when you want more than raw speed and need a better read on real connection quality.',
  },
  {
    slug: 'how-to-tell-if-wifi-or-isp-is-the-problem',
    title: 'How to Tell if Wi-Fi or Your ISP Is the Problem',
    description: 'A practical way to separate local Wi-Fi issues from upstream internet problems.',
  },
  {
    slug: 'how-to-check-packet-loss-on-mac',
    title: 'How to Check Packet Loss on Mac',
    description: 'Packet loss matters more than most speed tests admit. Here is how to check it and what it means.',
  },
  {
    slug: 'how-to-use-networkquality-on-mac',
    title: 'How to Use networkQuality on Mac',
    description: 'What Apple’s built-in networkQuality test tells you, what it misses, and how to read it without pretending one number explains everything.',
  },
  {
    slug: 'how-to-use-wireless-diagnostics-on-mac',
    title: 'How to Use Wireless Diagnostics on Mac',
    description: 'A plain-English guide to Apple’s hidden Wi-Fi troubleshooting tool and when it helps.',
  },
  {
    slug: 'how-to-improve-zoom-call-quality-on-mac',
    title: 'How to Improve Zoom Call Quality on Mac',
    description: 'The checks that actually matter when calls get unstable or start breaking up.',
  },
  {
    slug: 'whyfi-alternative-for-mac',
    title: 'WhyFi Alternative for Mac',
    description: 'A plain comparison for people who want a lighter menu bar tool focused on current usability.',
  },
  {
    slug: 'how-to-check-jitter-on-mac',
    title: 'How to Check Jitter on Mac',
    description: 'Jitter is one of the fastest ways to ruin a call. Here is how to think about it on macOS.',
  },
  {
    slug: 'best-internet-monitor-for-mac-menu-bar',
    title: 'Best Internet Monitor for Mac Menu Bar',
    description: 'A look at menu bar monitors that focus on actual connection reliability instead of dashboards full of noise.',
  },
]
