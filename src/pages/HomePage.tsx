import { ShoppingCart, CheckCircle2, Wifi, Zap, Layout } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import CheckoutButton from '../components/CheckoutButton'
import { PRICE } from '../config/commerce'
import {
  card,
  eyebrow,
  lead,
  pageTitle,
  primaryButton,
  secondaryButton,
  section,
  sectionTitle,
  shell,
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
    icon: <Zap className="h-6 w-6 text-indigo-500" />,
    eyebrow: 'Confidence',
    title: 'Ready for that big meeting?',
    copy: 'Stop guessing if your video will freeze. MacWiFi gives you a "green light" before you hit Join.',
  },
  {
    icon: <Wifi className="h-6 w-6 text-emerald-500" />,
    eyebrow: 'Clarity',
    title: 'Wi-Fi or ISP problem?',
    copy: 'Separate shaky local Wi-Fi from upstream outages. Know exactly who to blame (and what to fix).',
  },
  {
    icon: <Layout className="h-6 w-6 text-amber-500" />,
    eyebrow: 'Simplicity',
    title: 'Answers, not numbers.',
    copy: 'No more deciphering dBm or latency spikes. Just clear, plain-English advice on your connection.',
  },
]

const productSections = [
  {
    title: 'Is it actually usable?',
    copy: 'Instead of signal bars, see if your connection is stable enough for Zoom, Netflix, or just getting work done.',
    image: '/assets/wi-fi.png',
    alt: 'MacWiFi main status screenshot showing connection readiness.',
    accent: 'bg-emerald-50',
  },
  {
    title: 'Deep dive when needed.',
    copy: 'Get the technical details on connection path, local network health, and exactly why things are feeling slow.',
    image: '/assets/advanced-info.png',
    alt: 'MacWiFi advanced information screenshot with deeper diagnostics.',
    accent: 'bg-indigo-50',
  },
  {
    title: 'The "Invisible" issues.',
    copy: 'DNS timing and packet loss are often the real culprits. MacWiFi catches them even when your Wi-Fi icon says "Full Bars".',
    image: '/assets/dns-response.png',
    alt: 'MacWiFi screenshot showing DNS response and connection path diagnostics.',
    accent: 'bg-amber-50',
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

      <main className="overflow-hidden">
        {/* Hero Section */}
        <section className={`${section} relative`}>
          {/* Background Decorations */}
          <div className="absolute top-[-10%] right-[-5%] w-[40%] h-[40%] bg-indigo-200/30 rounded-full blur-[120px] pointer-events-none" />
          <div className="absolute bottom-[5%] left-[-10%] w-[35%] h-[35%] bg-emerald-200/20 rounded-full blur-[100px] pointer-events-none" />
          
          <div className={`${shell} relative grid items-center gap-12 lg:grid-cols-[1.1fr_0.9fr] lg:gap-20`}>
            <div className="max-w-3xl">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-50 text-indigo-700 text-xs font-bold uppercase tracking-wider mb-6 border border-indigo-100">
                <CheckCircle2 className="h-3.5 w-3.5" />
                <span>Trusted by 5,000+ Remote Workers</span>
              </div>
              <h1 className={pageTitle}>Internet peace of mind, right in your menu bar.</h1>
              <p className={`${lead} mt-8 max-w-2xl`}>
                Stop guessing if your Mac connection is ready for the next meeting. MacWiFi translates technical network health into plain-English answers about call readiness and stability.
              </p>
              <div className="mt-10 flex flex-col gap-4 sm:flex-row sm:items-center">
                <CheckoutButton className={`${primaryButton} w-full sm:w-auto px-8 py-5 shadow-xl shadow-indigo-200/50`}>
                  <ShoppingCart className="mr-2.5 h-5 w-5" strokeWidth={2.5} />
                  <span>Get MacWiFi for {PRICE}</span>
                </CheckoutButton>
                <a href="#walkthrough" className="inline-flex items-center justify-center font-bold text-slate-600 hover:text-indigo-600 px-6 py-4 transition">
                  See how it works →
                </a>
              </div>
            </div>

            <div className="relative group">
              <div className="absolute -inset-4 bg-gradient-to-tr from-indigo-100 to-emerald-100 rounded-[44px] opacity-40 blur-2xl group-hover:opacity-60 transition duration-1000" />
              <div className="relative rounded-[36px] bg-white p-2.5 shadow-2xl shadow-slate-200 border border-slate-100 overflow-hidden">
                <div className="absolute top-0 inset-x-0 h-8 bg-slate-50/80 border-b border-slate-100 flex items-center px-4 gap-1.5 z-10">
                  <div className="w-2.5 h-2.5 rounded-full bg-slate-200" />
                  <div className="w-2.5 h-2.5 rounded-full bg-slate-200" />
                  <div className="w-2.5 h-2.5 rounded-full bg-slate-200" />
                </div>
                <div className="pt-8">
                  <video
                    ref={videoRef}
                    className="block w-full rounded-b-[24px] shadow-sm"
                    autoPlay
                    loop
                    muted={heroMuted}
                    playsInline
                    preload="auto"
                    poster="/assets/wi-fi.png"
                  >
                    <source src="/assets/macwifi-hero.mp4" type="video/mp4" />
                  </video>
                </div>
                <button
                  className="absolute bottom-6 right-6 rounded-full bg-slate-900/90 hover:bg-slate-900 text-white p-2.5 shadow-lg backdrop-blur-md transition z-20"
                  type="button"
                  onClick={toggleHeroMuted}
                >
                  {heroMuted ? (
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2" /></svg>
                  ) : (
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" /></svg>
                  )}
                </button>
              </div>
            </div>
          </div>
        </section>

        {/* Feature Highlights */}
        <section id="answers" className={`${section} bg-slate-50`}>
          <div className={shell}>
            <div className="text-center max-w-3xl mx-auto mb-16 lg:mb-24">
              <p className={eyebrow}>Everything you need</p>
              <h2 className={sectionTitle}>Clarity in a click.</h2>
              <p className={`${lead} mt-6`}>We take the guesswork out of network troubleshooting, focusing on the stuff that actually affects your work day.</p>
            </div>

            <div className="grid gap-8 md:grid-cols-3">
              {practicalUses.map((use) => (
                <div key={use.title} className={`${card} p-8 lg:p-10 flex flex-col items-center text-center`}>
                  <div className="w-16 h-16 rounded-[22px] bg-slate-50 border border-slate-100 flex items-center justify-center mb-8 shadow-inner">
                    {use.icon}
                  </div>
                  <h3 className="text-2xl font-extrabold tracking-tight text-slate-900 mb-4">{use.title}</h3>
                  <p className="text-slate-600 leading-relaxed">{use.copy}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Walkthrough Sections */}
        <section id="walkthrough" className={section}>
          <div className={shell}>
            <div className="space-y-24 lg:space-y-40">
              {productSections.map((item, index) => (
                <div
                  key={item.title}
                  className={`grid items-center gap-12 lg:grid-cols-2 lg:gap-24 ${
                    index % 2 === 1 ? 'lg:direction-rtl' : ''
                  }`}
                >
                  <div className={index % 2 === 1 ? 'lg:order-2' : ''}>
                    <div className={`inline-block px-4 py-1 rounded-full ${item.accent} text-indigo-700 font-bold text-sm mb-6`}>
                      Step {index + 1}
                    </div>
                    <h2 className="text-4xl lg:text-6xl font-extrabold tracking-tight text-slate-900 mb-8">
                      {item.title}
                    </h2>
                    <p className={`${lead} text-xl`}>
                      {item.copy}
                    </p>
                    <div className="mt-10 space-y-4">
                      <div className="flex items-start gap-3">
                        <div className="mt-1 rounded-full bg-emerald-100 p-1">
                          <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                        </div>
                        <p className="font-medium text-slate-700">Instant visual feedback</p>
                      </div>
                      <div className="flex items-start gap-3">
                        <div className="mt-1 rounded-full bg-emerald-100 p-1">
                          <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                        </div>
                        <p className="font-medium text-slate-700">Native macOS performance</p>
                      </div>
                    </div>
                  </div>

                  <div className={`${index % 2 === 1 ? 'lg:order-1' : ''} relative`}>
                    <div className={`absolute inset-0 ${item.accent} rounded-[48px] rotate-2 transform-gpu -z-10`} />
                    <div className="bg-white rounded-[40px] p-4 shadow-2xl border border-slate-100 overflow-hidden">
                      <img
                        className="w-full rounded-[28px]"
                        src={item.image}
                        alt={item.alt}
                      />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* FAQ Section */}
        <section id="faq" className={`${section} bg-slate-50`}>
          <div className={`${shell} max-w-4xl`}>
            <div className="text-center mb-16">
              <p className={eyebrow}>FAQ</p>
              <h2 className={sectionTitle}>Common questions.</h2>
            </div>

            <div className="grid gap-6">
              {[
                {
                  q: "What does it actually test?",
                  a: "It continuously monitors local Wi-Fi health (signal, noise, MCS) and the wider internet path (DNS, packet loss, jitter) to build a complete picture of your connection quality."
                },
                {
                  q: "Is this a speed test?",
                  a: "Not in the traditional sense. Speed tests tell you how fast you *could* download a big file. MacWiFi tells you how stable your connection *is* for real-time apps like Zoom or Meet."
                },
                {
                  q: "Why isn't the built-in Wi-Fi meter enough?",
                  a: "Signal bars only show strength, not quality. You can have full bars but 10% packet loss, making video calls impossible. MacWiFi shows you that missing quality metric."
                },
                {
                  q: "Will it slow down my Mac?",
                  a: "No. It's a highly optimized, native Swift app that uses negligible CPU and memory. It's designed to live in your menu bar 24/7 without you noticing."
                }
              ].map((faq, i) => (
                <div key={i} className="bg-white rounded-[32px] p-8 border border-slate-100 shadow-sm">
                  <h3 className="text-xl font-bold text-slate-900 mb-4">{faq.q}</h3>
                  <p className="text-slate-600 leading-relaxed">{faq.a}</p>
                </div>
              ))}
            </div>
            
            <div className="mt-16 text-center">
              <p className="text-slate-500 mb-8">Still have questions?</p>
              <a href="mailto:support@macwifi.live" className={`${secondaryButton}`}>
                Contact Support
              </a>
            </div>
          </div>
        </section>

        {/* Final CTA */}
        <section className={`${section} mb-12 sm:mb-20`}>
          <div className={shell}>
            <div className="relative rounded-[48px] bg-indigo-600 p-12 lg:p-24 overflow-hidden text-center text-white">
              <div className="absolute top-0 right-0 w-[50%] h-[100%] bg-indigo-500 rounded-full blur-[120px] translate-x-1/2 -translate-y-1/2" />
              <div className="absolute bottom-0 left-0 w-[40%] h-[80%] bg-emerald-400 rounded-full blur-[100px] -translate-x-1/2 translate-y-1/2 opacity-30" />
              
              <div className="relative z-10 max-w-3xl mx-auto">
                <h2 className="text-4xl lg:text-7xl font-extrabold tracking-tight mb-8">
                  Fix your internet anxiety today.
                </h2>
                <p className="text-xl lg:text-2xl text-indigo-100 mb-12">
                  Join 5,000+ remote professionals who trust MacWiFi to keep them connected and confident.
                </p>
                <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
                  <CheckoutButton className="inline-flex items-center justify-center rounded-[22px] bg-white px-10 py-6 text-xl font-bold text-indigo-600 shadow-xl shadow-indigo-950/20 transition hover:scale-105 active:scale-95">
                    Get MacWiFi for {PRICE}
                  </CheckoutButton>
                  <p className="text-indigo-200 text-sm font-medium">One-time purchase • Native macOS app</p>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>
    </>
  )
}
