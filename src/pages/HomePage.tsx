import { useEffect, useRef } from 'react'
import CheckoutButton from '../components/CheckoutButton'
import { PRICE } from '../config/commerce'
import {
  pageTitle,
  primaryButton,
  section,
  shell,
  lead,
  subtleCard,
} from '../lib/ui'
import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const homeMeta = makeMeta({
  title: 'MacWiFi | Never fail a call.',
  description: 'The singular tool for Mac internet stability.',
  canonicalPath: '/',
})

export default function HomePage() {
  const videoRef = useRef<HTMLVideoElement | null>(null)

  useEffect(() => {
    const video = videoRef.current
    if (!video) return
    void video.play().catch(() => {})
  }, [])

  return (
    <>
      <SeoHead meta={homeMeta} />

      <main>
        {/* HERO */}
        <section className={`${section} border-b border-black`}>
          <div className={shell}>
            <h1 className={pageTitle}>
              NEVER FAIL <br />
              A CALL.
            </h1>
            <div className="mt-24 grid gap-24 lg:grid-cols-2 lg:items-end">
              <p className={lead}>
                Most internet problems aren't about speed. They're about stability. MacWiFi is the only tool that tells you the truth before you hit Join.
              </p>
              <div className="flex flex-col gap-8">
                <CheckoutButton className={primaryButton}>
                  BUY NOW — {PRICE}
                </CheckoutButton>
                <p className="font-display font-black uppercase tracking-tighter text-black/40">
                  ONE PURCHASE. FOREVER.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* THE PRODUCT */}
        <section className="border-b border-black">
          <div className="flex flex-col lg:flex-row">
            <div className="flex-1 border-b border-black lg:border-b-0 lg:border-r border-black p-12 lg:p-24">
              <video
                ref={videoRef}
                className="w-full grayscale border border-black shadow-[20px_20px_0_0_#000]"
                autoPlay
                loop
                muted
                playsInline
                preload="auto"
                poster="/assets/wi-fi.png"
              >
                <source src="/assets/macwifi-hero.mp4" type="video/mp4" />
              </video>
            </div>
            <div className="flex-1 flex flex-col">
              <div className="p-12 lg:p-24 border-b border-black flex-1">
                <h2 className="text-6xl font-black uppercase tracking-tighter mb-8">TELEMETRY.</h2>
                <p className="text-xl font-medium tracking-tight text-black/60">
                  Real-time monitoring of jitter, packet loss, and DNS health. Technical precision, simplified for the modern pro.
                </p>
              </div>
              <div className="p-12 lg:p-24 flex-1">
                <h2 className="text-6xl font-black uppercase tracking-tighter mb-8">ISOLATION.</h2>
                <p className="text-xl font-medium tracking-tight text-black/60">
                  Instantly know if the problem is your Wi-Fi, your ISP, or your DNS. Stop guessing. Start fixing.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* TRUTH */}
        <section id="answers" className={section}>
          <div className={shell}>
            <div className="grid gap-1 border-t border-black">
              {[
                { t: "CALL READINESS", c: "A simple green light means your connection is ready for video." },
                { t: "FAULT DETECTION", c: "Identify local interference vs. upstream outages in seconds." },
                { t: "ZERO CLOUD", c: "Your data never leaves your Mac. Privacy is built in by design." },
                { t: "NATIVE PERFORMANCE", c: "Built in Swift for near-zero CPU and memory overhead." }
              ].map((item) => (
                <div key={item.t} className={subtleCard}>
                  <h3 className="text-4xl font-black uppercase tracking-tighter">{item.t}</h3>
                  <p className="text-xl font-medium text-black/60">{item.c}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* FAQ */}
        <section id="faq" className={`${section} bg-black text-white`}>
          <div className={shell}>
            <h2 className="massive-type font-black tracking-tighter uppercase mb-24">FAQ.</h2>
            <div className="grid gap-12 lg:grid-cols-2">
              {[
                { q: "WHY NOT SPEEDTEST?", a: "Speed is capacity. Stability is quality. You can have 1Gbps and still freeze on Zoom. We measure the quality." },
                { q: "IS IT A SUBSCRIPTION?", a: "No. Buy it once. Own it forever. We hate subscriptions as much as you do." },
                { q: "DOES IT WORK ON M1/M2/M3?", a: "Yes. Native support for all Apple Silicon and Intel Macs." }
              ].map((faq) => (
                <div key={faq.q}>
                  <h4 className="text-2xl font-black uppercase tracking-tighter mb-4 text-white/40">{faq.q}</h4>
                  <p className="text-xl font-medium tracking-tight">{faq.a}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="py-48 text-center border-t border-black">
          <div className={shell}>
            <h2 className="massive-type font-black tracking-tighter uppercase mb-12">DON'T GUESS.</h2>
            <CheckoutButton className="inline-flex items-center justify-center bg-black text-white text-4xl font-black uppercase tracking-tighter px-24 py-12 hover:line-through">
              GET MACWIFI
            </CheckoutButton>
          </div>
        </section>
      </main>
    </>
  )
}
