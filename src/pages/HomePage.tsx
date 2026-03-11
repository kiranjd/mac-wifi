import { Link } from 'react-router-dom'
import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const homeMeta = makeMeta({
  title: 'MacWiFi | The Wi-Fi monitor macOS should have had',
  description:
    'MacWiFi is a native macOS Wi-Fi monitor that translates connection health into plain answers about what your current internet can actually handle and where the trouble probably is.',
  canonicalPath: '/',
})

const softwareSchema = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'MacWiFi',
  operatingSystem: 'macOS',
  applicationCategory: 'UtilitiesApplication',
  description:
    'MacWiFi translates connection health into plain answers about what your current internet can actually handle and whether the problem is on your Wi-Fi side or farther upstream.',
  offers: {
    '@type': 'Offer',
    price: '9.99',
    priceCurrency: 'USD',
    url: 'https://macwifi.live/pricing',
  },
}

const faqSchema = {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: [
    {
      '@type': 'Question',
      name: 'What does MacWiFi actually tell me?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'It translates network health into plain answers about whether your current connection is usable for calls, streaming, browsing, and whether the problem looks local or upstream.',
      },
    },
    {
      '@type': 'Question',
      name: 'Is this just another speed test app?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'No. It uses network measurements, but the point is to tell you what the connection feels capable of right now, not to show off one download number.',
      },
    },
    {
      '@type': 'Question',
      name: 'What is wrong with the built-in Mac Wi-Fi indicator?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'The built-in menu mostly shows signal strength. That does not tell you whether a call will freeze, whether the issue is packet loss, or whether the trouble is on your Wi-Fi or your ISP path.',
      },
    },
    {
      '@type': 'Question',
      name: 'Can it help me choose between nearby Wi-Fi networks?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'Yes. One common use is comparing nearby networks so you can avoid guessing based on bars alone or picking the first SSID in the list.',
      },
    },
    {
      '@type': 'Question',
      name: 'Does MacWiFi sort networks by signal strength?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'That is one of the practical improvements we are building toward, because the default macOS Wi-Fi menu often makes nearby networks harder to scan than they should be.',
      },
    },
    {
      '@type': 'Question',
      name: 'Do I need an account?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'No. It is a one-time purchase and works as a native menu bar app.',
      },
    },
  ],
}

const practicalUses = [
  {
    eyebrow: 'Remote calls',
    title: 'Before a client call or interview',
    copy: 'Open MacWiFi and get a plain read on whether this connection is ready for Zoom, Meet, or Teams before you join and hope for the best.',
    href: '/blog/how-to-check-if-your-internet-is-good-enough-for-a-video-call-on-mac',
    linkLabel: 'Read the call-readiness guide',
  },
  {
    eyebrow: 'Travel / coworking',
    title: 'When there are five SSIDs and no obvious good one',
    copy: 'Use it to decide which network is actually worth trying when hotel, Airbnb, or coworking Wi-Fi all look equally suspicious.',
    href: '/blog/how-to-pick-the-best-wifi-network-on-mac',
    linkLabel: 'Read the network-picking guide',
  },
  {
    eyebrow: 'House IT',
    title: 'When everyone says “the Wi-Fi is broken”',
    copy: 'It helps you figure out whether to move closer, switch bands, restart the router, or stop blaming the router and call the ISP.',
    href: '/blog/should-you-restart-your-router-or-call-your-isp-on-mac',
    linkLabel: 'Read the troubleshooting guide',
  },
]

const builtInPainPoints = [
  {
    title: 'Bars do not tell you if a call will survive',
    copy: 'macOS shows signal bars. That is not the same as call quality, jitter, packet loss, or whether pages will hang.',
  },
  {
    title: 'The useful diagnostics are buried',
    copy: 'The built-in tools are hidden behind option-clicks and Wireless Diagnostics, which is more than most people want for a quick answer.',
  },
  {
    title: 'Choosing a network is still awkward',
    copy: 'The default Wi-Fi menu does not really help you pick the best nearby network for what you are about to do.',
  },
]

const productSections = [
  {
    eyebrow: 'Main read',
    title: 'See whether the current internet is actually usable.',
    copy: 'Instead of leaving you with signal bars and vague instincts, MacWiFi shows whether the connection is stable enough for calls, streaming, and normal browsing right now.',
    image: '/assets/wi-fi.png',
    alt: 'MacWiFi main status screenshot showing connection readiness.',
  },
  {
    eyebrow: 'Advanced info',
    title: 'Get the details when you actually need them.',
    copy: 'If something feels wrong, you can open the deeper diagnostics and see the connection path, local network details, and the kind of instability that is causing the problem.',
    image: '/assets/advanced-info.png',
    alt: 'MacWiFi advanced information screenshot with deeper diagnostics.',
  },
  {
    eyebrow: 'DNS and response',
    title: 'Spot the kind of lag that makes a connection feel bad.',
    copy: 'It helps surface slow DNS or unstable response timing, which is often the reason internet feels unreliable even when the usual Wi-Fi icon looks fine.',
    image: '/assets/dns-response.png',
    alt: 'MacWiFi DNS response screenshot.',
  },
]

export default function HomePage() {
  return (
    <>
      <SeoHead meta={homeMeta}>
        <script type="application/ld+json">{JSON.stringify(softwareSchema)}</script>
        <script type="application/ld+json">{JSON.stringify(faqSchema)}</script>
      </SeoHead>

      <main>
        <section className="hero-section section-pad">
          <div className="shell hero-grid">
            <div className="hero-copy">
              <h1>The Wi-Fi monitor macOS should have had.</h1>
              <p className="hero-lead">
                MacWiFi tells you whether the current connection is actually usable, what it can
                handle, and where the problem probably is.
              </p>

              <div className="hero-facts">
                <div>
                  <strong>$9.99 once</strong>
                  <span>No subscription</span>
                </div>
                <div>
                  <strong>Native menu bar app</strong>
                  <span>Open, check, move on</span>
                </div>
                <div>
                  <strong>No account</strong>
                  <span>Install it and use it</span>
                </div>
              </div>
            </div>

            <div className="hero-visual">
              <div className="hero-card hero-card-top">
                <span>Ready for</span>
                <strong>Calls, streaming, browsing</strong>
              </div>
              <video
                className="hero-video"
                autoPlay
                loop
                muted
                playsInline
                preload="auto"
                poster="/assets/wi-fi.png"
                aria-label="MacWiFi app demo video"
              >
                <source src="/assets/macwifi-hero.mp4" type="video/mp4" />
              </video>
              <div className="hero-card hero-card-bottom">
                <span>Likely issue</span>
                <strong>Wi-Fi side or internet side</strong>
              </div>
            </div>
          </div>
        </section>

        <section className="section-pad">
          <div className="shell">
            <div className="intro-block">
              <p className="section-label">Practical uses</p>
              <h2>Where people actually use this.</h2>
              <p>
                The app makes the most sense in moments where the built-in Wi-Fi meter stops being
                useful and you need a decision instead of another vague signal icon.
              </p>
            </div>

            <div className="persona-grid">
              {practicalUses.map((use) => (
                <article key={use.title} className="persona-card">
                  <p className="question-kicker">{use.eyebrow}</p>
                  <h3>{use.title}</h3>
                  <p>{use.copy}</p>
                  <Link className="use-case-link" to={use.href}>
                    {use.linkLabel}
                  </Link>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="section-pad section-pad-tight">
          <div className="shell">
            <div className="intro-block">
              <p className="section-label">Why people outgrow the built-in Wi-Fi view</p>
              <h2>The default macOS menu still leaves a few important gaps.</h2>
              <p>
                That gap is the reason MacWiFi exists. The built-in menu shows whether you are
                connected. It does not do a great job of telling you whether the connection is
                actually usable.
              </p>
            </div>

            <div className="pain-grid">
              {builtInPainPoints.map((pain) => (
                <article key={pain.title} className="pain-card">
                  <h3>{pain.title}</h3>
                  <p>{pain.copy}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="section-pad">
          <div className="shell">
            <div className="intro-block">
              <p className="section-label">What it translates</p>
              <h2>Three things you usually want to know.</h2>
              <p>
                You open it when the connection feels off and you want to know whether you can trust
                it, what it can handle, and where the trouble probably is.
              </p>
            </div>

            <div className="question-grid">
              <article className="question-card">
                <p className="question-kicker">Calls</p>
                <h3>Can I trust this for a meeting?</h3>
                <p>MacWiFi turns latency, jitter, and loss into a simple read on call readiness.</p>
              </article>

              <article className="question-card">
                <p className="question-kicker">Streaming</p>
                <h3>Is this internet just slow, or actually unstable?</h3>
                <p>It focuses on whether the connection feels usable, not just whether one test spiked high.</p>
              </article>

              <article className="question-card">
                <p className="question-kicker">Diagnosis</p>
                <h3>Is the mess inside my home network or past it?</h3>
                <p>It helps split local Wi-Fi trouble from upstream internet trouble so you know where to look.</p>
              </article>
            </div>
          </div>
        </section>

        <section className="section-pad product-gallery-section">
          <div className="shell">
            <div className="intro-block intro-block-tight">
              <p className="section-label">Inside the app</p>
              <h2>What the app shows, without much ceremony.</h2>
            </div>

            <div className="zigzag-list">
              {productSections.map((section, index) => (
                <article
                  key={section.title}
                  className={`zigzag-row ${index % 2 === 1 ? 'zigzag-row-reverse' : ''}`}
                >
                  <div className="zigzag-copy">
                    <p className="question-kicker">{section.eyebrow}</p>
                    <h3>{section.title}</h3>
                    <p>{section.copy}</p>
                  </div>

                  <figure className="gallery-card zigzag-media">
                    <figcaption>{section.eyebrow}</figcaption>
                    <img src={section.image} alt={section.alt} />
                  </figure>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section id="faq" className="section-pad">
          <div className="shell faq-grid">
            <div className="intro-block intro-block-tight">
              <p className="section-label">FAQ</p>
              <h2>Common questions.</h2>
            </div>

            <article className="faq-card">
              <h3>What does it actually test?</h3>
              <p>
                It looks at local Wi-Fi health and the wider internet path, then summarizes what
                the connection feels capable of right now.
              </p>
            </article>

            <article className="faq-card">
              <h3>Is this a speed test?</h3>
              <p>
                Not really. The point is not to chase one big number. It is to tell you whether
                the connection is likely to behave well for the thing you are about to do.
              </p>
            </article>

            <article className="faq-card">
              <h3>Why is the built-in Mac Wi-Fi meter not enough?</h3>
              <p>
                Signal bars tell you only part of the story. They do not tell you much about
                jitter, packet loss, flaky DNS, or whether the connection will hold up during a
                call.
              </p>
            </article>

            <article className="faq-card">
              <h3>Can it help me pick between nearby networks?</h3>
              <p>
                Yes. One practical use is comparing nearby Wi-Fi options instead of guessing from
                a crowded list and hoping the top one is the best one.
              </p>
            </article>

            <article className="faq-card">
              <h3>Will it help me figure out whether to blame Wi-Fi or my ISP?</h3>
              <p>
                That is one of the main reasons it exists. It helps separate local Wi-Fi trouble
                from broader internet trouble so you know what to change first.
              </p>
            </article>

            <article className="faq-card">
              <h3>Why does macOS ask for location permission?</h3>
              <p>
                That is how macOS exposes Wi-Fi details to apps. MacWiFi uses it for local radio
                and network information.
              </p>
            </article>

            <article className="faq-card">
              <h3>How do I buy it?</h3>
              <p>
                It is a one-time purchase. The checkout email includes the download path, and
                licensing will stay simple.
              </p>
            </article>
          </div>
        </section>
      </main>
    </>
  )
}
