import { useEffect, useRef, useState } from 'react'
import CheckoutButton from '../components/CheckoutButton'
import { PRICE } from '../config/commerce'
import {
  card,
  eyebrow,
  lead,
  pageTitle,
  primaryButton,
  section,
  sectionTitle,
  shell,
  subtleCard,
} from '../lib/ui'
import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const homeMeta = makeMeta({
  title: 'MacWiFi | Diagnose unstable internet on Mac before the next call',
  description:
    'MacWiFi is a native macOS menu bar app for unstable internet on Mac. Check call readiness, separate Wi-Fi-side trouble from ISP-side trouble, and see why a connection feels bad.',
  canonicalPath: '/',
})

const softwareSchema = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'MacWiFi',
  operatingSystem: 'macOS',
  applicationCategory: 'UtilitiesApplication',
  description:
    'MacWiFi translates unstable internet on Mac into plain answers about call readiness, usable connection quality, and whether the problem is on your Wi-Fi side or farther upstream.',
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
      name: 'Can it help when my Mac says connected to Wi-Fi but the internet still feels broken?',
      acceptedAnswer: {
        '@type': 'Answer',
        text: 'Yes. One of the main jobs is separating local Wi-Fi trouble from DNS trouble and upstream internet trouble when the Wi-Fi icon still looks normal.',
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
    eyebrow: 'Before a call that matters',
    title: 'Check whether this connection is safe for Zoom, Meet, or Teams before you join.',
    copy: 'MacWiFi turns the current connection into a plain readiness read so you can decide before the call starts going sideways.',
  },
  {
    eyebrow: 'When the icon says connected but work still hangs',
    title: 'Separate shaky Wi-Fi from DNS trouble and upstream outages.',
    copy: 'It helps you stop treating every failure like vague Wi-Fi drama when the real weak spot is sometimes past your router.',
  },
  {
    eyebrow: 'When home internet becomes everybody’s problem',
    title: 'See whether the issue is inside your home network or farther upstream.',
    copy: 'Use it to decide whether to move, switch, restart the router, or stop blaming the router and call the ISP.',
  },
]

const builtInPainPoints = [
  {
    title: 'Connected is not the same as usable',
    copy: 'The menu bar can say you are online while calls still break up and pages still hang.',
  },
  {
    title: 'Call-quality problems stay hidden',
    copy: 'The default read does not tell you enough about stability, dropouts, or whether video will hold up.',
  },
  {
    title: 'The icon cannot tell you where the path breaks',
    copy: 'macOS still leaves you guessing whether the weak spot is local Wi-Fi, DNS, or the internet path after your router.',
  },
]

const productSections = [
  {
    title: 'See whether the current internet is actually usable.',
    copy: 'Instead of leaving you with signal bars and vague instincts, MacWiFi shows whether the connection is stable enough for calls, streaming, and normal browsing right now.',
    image: '/assets/wi-fi.png',
    alt: 'MacWiFi main status screenshot showing connection readiness.',
  },
  {
    title: 'Get the details when you actually need them.',
    copy: 'If something feels wrong, you can open the deeper diagnostics and see the connection path, local network details, and the kind of instability that is causing the problem.',
    image: '/assets/advanced-info.png',
    alt: 'MacWiFi advanced information screenshot with deeper diagnostics.',
  },
  {
    title: 'Catch the cases where Wi-Fi looks fine but the internet is not.',
    copy: 'DNS timing, packet loss, and path checks make the annoying “connected but useless” state much easier to understand in normal English.',
    image: '/assets/dns-response.png',
    alt: 'MacWiFi screenshot showing DNS response and connection path diagnostics.',
  },
]

export default function HomePage() {
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const [heroMuted, setHeroMuted] = useState(true)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return
    video.muted = heroMuted
    void video.play().catch(() => {})
  }, [heroMuted])

  const toggleHeroMuted = () => {
    const nextMuted = !heroMuted
    setHeroMuted(nextMuted)
    const video = videoRef.current
    if (!video) return
    video.muted = nextMuted
    void video.play().catch(() => {})
  }

  return (
    <>
      <SeoHead meta={homeMeta}>
        <script type="application/ld+json">{JSON.stringify(softwareSchema)}</script>
        <script type="application/ld+json">{JSON.stringify(faqSchema)}</script>
      </SeoHead>

      <main>
        <section className={section}>
          <div className={`${shell} grid items-center gap-8 sm:gap-12 lg:grid-cols-[minmax(0,1fr)_minmax(380px,520px)] lg:gap-16`}>
            <div className="max-w-2xl">
              <h1 className={pageTitle}>Know whether your Mac internet can handle the next call.</h1>
              <p className={`${lead} mt-6 max-w-xl`}>
                MacWiFi checks unstable internet on Mac in plain English. It tells you whether the
                current connection is good enough for calls and normal work, and whether the
                problem is likely your Wi-Fi or something upstream.
              </p>
              <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
                <CheckoutButton className={`${primaryButton} w-full sm:w-auto`}>Buy for {PRICE}</CheckoutButton>
                <a
                  className="inline-flex w-full items-center justify-center rounded-full border border-slate-900/10 bg-white/70 px-5 py-3 text-[0.9rem] font-semibold text-slate-900 transition hover:bg-white sm:w-auto sm:text-[0.96rem]"
                  href="#walkthrough"
                >
                  Watch 30-second demo
                </a>
              </div>

              <div className="mt-8 grid grid-cols-2 gap-3 sm:mt-9 sm:grid-cols-4">
                {[
                  ['One-time purchase', `${PRICE} once`],
                  ['Native app', 'Menu bar, not a dashboard'],
                  ['No account', 'Install it and use it'],
                  ['Diagnosis', 'Wi-Fi side or ISP side'],
                ].map(([label, value]) => (
                  <div
                    key={label}
                    className={`${card} min-h-0 p-4 sm:p-5`}
                  >
                    <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-500 sm:text-sm sm:tracking-[0.2em]">
                      {label}
                    </p>
                    <p className="mt-2 text-[0.98rem] font-semibold leading-5 tracking-[-0.04em] text-slate-950 sm:text-lg">
                      {value}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            <div className="relative">
              <div className="absolute inset-x-10 top-6 h-20 rounded-full bg-emerald-300/20 blur-3xl sm:inset-x-12 sm:top-8 sm:h-24" />
              <div className="relative mx-auto w-full max-w-[420px] rounded-[26px] border border-slate-900/8 bg-[#0b1118] p-3 shadow-[0_44px_110px_-48px_rgba(15,23,42,0.72)] sm:max-w-[560px] sm:rounded-[36px] sm:p-4">
                <video
                  ref={videoRef}
                  className="block w-full rounded-[18px] object-contain sm:rounded-[26px]"
                  autoPlay
                  loop
                  muted={heroMuted}
                  playsInline
                  preload="auto"
                  poster="/assets/wi-fi.png"
                  aria-label="MacWiFi app demo video"
                >
                  <source src="/assets/macwifi-hero.mp4" type="video/mp4" />
                </video>
                <div className="pointer-events-none absolute inset-x-5 bottom-4 flex items-end justify-end sm:inset-x-7 sm:bottom-6">
                  <button
                    className="pointer-events-auto rounded-full bg-slate-950/88 px-3 py-1.5 text-xs font-semibold text-white shadow-[0_20px_40px_-18px_rgba(15,23,42,0.82)] transition hover:bg-slate-950 sm:px-4 sm:py-2 sm:text-sm"
                    type="button"
                    onClick={toggleHeroMuted}
                  >
                    {heroMuted ? 'Unmute' : 'Mute'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="answers" className={section}>
          <div className={shell}>
            <div className="max-w-3xl">
              <p className={eyebrow}>Three answers in one glance</p>
              <h2 className={sectionTitle}>The part that matters most.</h2>
            </div>

            <div className="mt-8 grid gap-4 lg:mt-10 lg:grid-cols-3">
              <article className={`${card} p-5 sm:p-7`}>
                <p className="text-sm font-semibold uppercase tracking-[0.2em] text-[#0f766e]">Calls</p>
                <h3 className="mt-4 text-[1.5rem] font-semibold leading-[1.04] tracking-[-0.05em] text-slate-950">
                  Can I trust this for a meeting?
                </h3>
                <p className="mt-4 text-base leading-7 text-slate-700">
                  MacWiFi turns latency, jitter, and loss into a simple read on call readiness.
                </p>
              </article>

              <article className={`${card} p-5 sm:p-7`}>
                <p className="text-sm font-semibold uppercase tracking-[0.2em] text-[#0f766e]">Streaming</p>
                <h3 className="mt-4 text-[1.5rem] font-semibold leading-[1.04] tracking-[-0.05em] text-slate-950">
                  Is this internet just slow, or actually unstable?
                </h3>
                <p className="mt-4 text-base leading-7 text-slate-700">
                  It focuses on whether the connection feels usable, not just whether one test
                  spiked high.
                </p>
              </article>

              <article className={`${card} p-5 sm:p-7`}>
                <p className="text-sm font-semibold uppercase tracking-[0.2em] text-[#0f766e]">Diagnosis</p>
                <h3 className="mt-4 text-[1.5rem] font-semibold leading-[1.04] tracking-[-0.05em] text-slate-950">
                  Is the mess inside my home network or past it?
                </h3>
                <p className="mt-4 text-base leading-7 text-slate-700">
                  It helps split local Wi-Fi trouble from upstream internet trouble so you know
                  where to look.
                </p>
              </article>
            </div>
          </div>
        </section>

        <section className={section}>
          <div className={shell}>
            <div className="max-w-3xl">
              <p className={eyebrow}>Where people use this</p>
              <h2 className={sectionTitle}>Stressful moments, clearer answers.</h2>
            </div>

            <div className="mt-8 grid gap-4 lg:mt-10 lg:grid-cols-3">
              {practicalUses.map((use) => (
                <article key={use.title} className={`${card} p-5 sm:p-7`}>
                  <p className="text-sm font-semibold uppercase tracking-[0.2em] text-[#0f766e]">
                    {use.eyebrow}
                  </p>
                  <h3 className="mt-4 text-[1.55rem] font-semibold leading-[1.04] tracking-[-0.05em] text-slate-950">
                    {use.title}
                  </h3>
                  <p className="mt-4 text-base leading-7 text-slate-700">{use.copy}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className={`${section} bg-[#e6e0d3]/64`}>
          <div className={shell}>
            <div className="max-w-3xl">
              <p className={eyebrow}>Why macOS isn’t enough</p>
              <h2 className={sectionTitle}>Signal bars don’t tell you enough.</h2>
            </div>

            <div className="mt-8 grid gap-4 lg:mt-10 lg:grid-cols-3">
              {builtInPainPoints.map((pain) => (
                <article key={pain.title} className={`${subtleCard} p-5 sm:p-7`}>
                  <h3 className="text-[1.45rem] font-semibold leading-[1.04] tracking-[-0.05em] text-slate-950">
                    {pain.title}
                  </h3>
                  <p className="mt-4 text-base leading-7 text-slate-700">{pain.copy}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section id="walkthrough" className={`${section} bg-[#07131b] text-white`}>
          <div className={shell}>
            <div className="max-w-3xl">
              <p className="mb-4 text-[11px] font-semibold uppercase tracking-[0.24em] text-emerald-300 sm:text-xs">
                Product walkthrough
              </p>
              <h2 className="text-[2.15rem] leading-[0.94] tracking-[-0.06em] text-white sm:text-5xl lg:text-[4rem]">
                See whether the current internet is actually usable.
              </h2>
              <p className="mt-5 max-w-2xl text-lg leading-8 text-slate-300 sm:text-xl">
                These are the product states that matter: call readiness, deeper issue source, and
                the reasons a connection can still feel broken even when Wi-Fi says connected.
              </p>
            </div>

            <div className="mt-10 space-y-12 sm:mt-12 sm:space-y-14">
              {productSections.map((section, index) => (
                <article
                  key={section.title}
                  className={`grid items-center gap-5 sm:gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(320px,420px)] lg:gap-16 ${
                    index % 2 === 1 ? 'lg:grid-cols-[minmax(320px,420px)_minmax(0,1fr)]' : ''
                  }`}
                >
                  <div className={`${index % 2 === 1 ? 'lg:order-2 lg:justify-self-end' : ''} max-w-xl`}>
                    <h3 className="text-[2rem] font-semibold leading-[0.98] tracking-[-0.06em] text-white sm:text-[3rem]">
                      {section.title}
                    </h3>
                    <p className="mt-4 text-[1rem] leading-7 text-slate-300 sm:mt-5 sm:text-lg sm:leading-8">{section.copy}</p>
                  </div>

                  <figure
                    className={`${
                      index % 2 === 1 ? 'lg:order-1 lg:justify-self-start' : 'lg:justify-self-end'
                    }`}
                  >
                    <div className="rounded-[24px] border border-white/10 bg-white/5 p-3 shadow-[0_34px_90px_-50px_rgba(0,0,0,0.8)] backdrop-blur sm:rounded-[32px] sm:p-4">
                      <img
                        className="mx-auto block w-full max-w-[320px] rounded-[18px] sm:max-w-[380px] sm:rounded-[24px]"
                        src={section.image}
                        alt={section.alt}
                      />
                    </div>
                  </figure>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section id="faq" className={`${section} scroll-mt-28`}>
          <div className={`${shell} grid gap-4 lg:grid-cols-3`}>
            <div className="max-w-lg lg:pr-6">
              <p className={eyebrow}>FAQ</p>
              <h2 className={sectionTitle}>Common questions.</h2>
            </div>

            <article className={`${card} p-5 sm:p-7`}>
              <h3 className="text-[1.45rem] font-semibold leading-[1.05] tracking-[-0.04em] text-slate-950">
                What does it actually test?
              </h3>
              <p className="mt-4 text-base leading-7 text-slate-700">
                It looks at local Wi-Fi health and the wider internet path, then summarizes what
                the connection feels capable of right now.
              </p>
            </article>

            <article className={`${card} p-5 sm:p-7`}>
              <h3 className="text-[1.45rem] font-semibold leading-[1.05] tracking-[-0.04em] text-slate-950">
                Is this a speed test?
              </h3>
              <p className="mt-4 text-base leading-7 text-slate-700">
                Not really. The point is not to chase one big number. It is to tell you whether
                the connection is likely to behave well for the thing you are about to do.
              </p>
            </article>

            <article className={`${card} p-5 sm:p-7`}>
              <h3 className="text-[1.45rem] font-semibold leading-[1.05] tracking-[-0.04em] text-slate-950">
                Why is the built-in Mac Wi-Fi meter not enough?
              </h3>
              <p className="mt-4 text-base leading-7 text-slate-700">
                Signal bars tell you only part of the story. They do not tell you much about
                jitter, packet loss, flaky DNS, or whether the connection will hold up during a
                call.
              </p>
            </article>

            <article className={`${card} p-5 sm:p-7`}>
              <h3 className="text-[1.45rem] font-semibold leading-[1.05] tracking-[-0.04em] text-slate-950">
                Can it help when my Mac says connected to Wi-Fi but pages still do not load?
              </h3>
              <p className="mt-4 text-base leading-7 text-slate-700">
                Yes. It helps separate local Wi-Fi trouble from DNS trouble and broader
                internet-path trouble, which is usually the real question in that moment.
              </p>
            </article>

            <article className={`${card} p-5 sm:p-7`}>
              <h3 className="text-[1.45rem] font-semibold leading-[1.05] tracking-[-0.04em] text-slate-950">
                Will it help me figure out whether to blame Wi-Fi or my ISP?
              </h3>
              <p className="mt-4 text-base leading-7 text-slate-700">
                That is one of the main reasons it exists. It helps separate local Wi-Fi trouble
                from broader internet trouble so you know what to change first.
              </p>
            </article>

          </div>
        </section>
      </main>
    </>
  )
}
