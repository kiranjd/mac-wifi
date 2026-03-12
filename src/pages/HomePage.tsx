import { useEffect, useRef } from 'react'
import CheckoutButton from '../components/CheckoutButton'
import { PRICE } from '../config/commerce'
import {
  lead,
  pageTitle,
  primaryButton,
  section,
  shell,
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

      <main className="bg-black text-white">
        <section className="border-b border-white/10 py-28 sm:py-40 lg:min-h-[calc(100vh-8rem)] lg:py-0">
          <div className={`${shell} grid gap-24 lg:min-h-[calc(100vh-8rem)] lg:grid-cols-[minmax(0,1.1fr)_minmax(420px,0.9fr)] lg:items-center`}>
            <div>
              <h1 className={`${pageTitle} mb-12`}>
                NEVER FAIL <br />
                A CALL.
              </h1>
              <p className={lead}>
                Most internet problems are not about speed. They are about stability. MacWiFi
                tells you whether your connection is ready before you hit Join.
              </p>
              <div className="mt-14 flex flex-col gap-6 sm:max-w-xl">
                <CheckoutButton className={`${primaryButton} w-full justify-center text-3xl sm:text-4xl`}>
                  Get License
                </CheckoutButton>
                <p className="font-display text-xs font-black uppercase tracking-[0.28em] text-white/42">
                  One purchase. Lifetime access. No cloud dependency.
                </p>
              </div>
            </div>

            <div className="border border-white/10 bg-white/[0.03] p-8 sm:p-10">
              <div className="grid gap-10 sm:grid-cols-2">
                <div>
                  <p className="font-display text-xs font-black uppercase tracking-[0.28em] text-accent">
                    Packet loss
                  </p>
                  <p className="mt-3 text-5xl font-black tracking-tighter">0.00%</p>
                </div>
                <div>
                  <p className="font-display text-xs font-black uppercase tracking-[0.28em] text-accent">
                    Readiness
                  </p>
                  <p className="mt-3 text-5xl font-black tracking-tighter">Ready</p>
                </div>
                <div>
                  <p className="font-display text-xs font-black uppercase tracking-[0.28em] text-accent">
                    DNS
                  </p>
                  <p className="mt-3 text-3xl font-black tracking-tighter">Verified</p>
                </div>
                <div>
                  <p className="font-display text-xs font-black uppercase tracking-[0.28em] text-accent">
                    Price
                  </p>
                  <p className="mt-3 text-3xl font-black tracking-tighter">{PRICE} once</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="walkthrough" className="bg-white py-32 text-black lg:py-56">
          <div className={shell}>
            <div className="flex flex-col gap-24 lg:flex-row lg:items-center">
              <div className="flex-1">
                <video
                  ref={videoRef}
                  className="w-full border-2 border-black bg-zinc-100 grayscale"
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
              <div className="flex-1 flex flex-col gap-24">
                <div>
                  <p className="mb-6 font-display text-sm font-black uppercase tracking-[0.28em] text-black/35">
                    Telemetry
                  </p>
                  <h2 className="mb-10 text-7xl font-black uppercase tracking-tighter leading-none lg:text-9xl">
                    Truth.
                  </h2>
                  <p className="max-w-xl text-2xl font-medium leading-tight tracking-tight text-black/62 lg:text-3xl">
                    Real-time monitoring of jitter, packet loss, and DNS health. Technical detail,
                    reduced to a fast answer.
                  </p>
                </div>
                <div>
                  <p className="mb-6 font-display text-sm font-black uppercase tracking-[0.28em] text-black/35">
                    Isolation
                  </p>
                  <h2 className="mb-10 text-7xl font-black uppercase tracking-tighter leading-none lg:text-9xl">
                    Isolation.
                  </h2>
                  <p className="max-w-xl text-2xl font-medium leading-tight tracking-tight text-black/62 lg:text-3xl">
                    Separate local Wi-Fi trouble from upstream ISP trouble in seconds, before the
                    next call falls apart.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="answers" className={`${section} bg-black`}>
          <div className={shell}>
            <div className="mb-24 border-b border-white/10 pb-12">
              <h2 className="text-7xl font-black uppercase tracking-tighter leading-[0.82] text-white lg:text-9xl">
                The <br /> outcome.
              </h2>
            </div>
            <div className="grid gap-1">
              {[
                { t: 'Call readiness', c: 'Know if the connection is stable enough for live video before the meeting starts.' },
                { t: 'Fault detection', c: 'See whether the problem is local interference, the router, DNS, or the ISP path.' },
                { t: 'Zero cloud', c: 'All diagnostics stay on your Mac. No remote telemetry is required to use the product.' },
                { t: 'Native performance', c: 'Built in Swift for low overhead and fast reads from the menu bar.' },
              ].map((item) => (
                <div key={item.t} className={`${subtleCard} border-white/5 transition-colors hover:bg-white/[0.02]`}>
                  <h3 className="text-5xl font-black uppercase tracking-tighter text-white lg:text-7xl">
                    {item.t}
                  </h3>
                  <p className="max-w-3xl text-2xl font-medium leading-tight text-white/58 lg:text-3xl">
                    {item.c}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section id="faq" className={`${section} bg-white text-black`}>
          <div className={shell}>
            <h2 className="massive-type mb-32 font-black uppercase tracking-tighter text-black">
              FAQ.
            </h2>
            <div className="grid gap-24 lg:grid-cols-2">
              {[
                {
                  q: 'Why not Speedtest?',
                  a: 'Speed tests measure capacity. MacWiFi measures quality. You can have fast internet and still have a bad call if the connection is unstable.',
                },
                {
                  q: 'Is it a subscription?',
                  a: 'No. Buy it once and keep it. The product is licensed as a one-time purchase.',
                },
                {
                  q: 'Does it support Apple Silicon?',
                  a: 'Yes. MacWiFi supports Apple Silicon and Intel Macs with a native macOS build.',
                },
              ].map((faq) => (
                <div key={faq.q} className="border-l-2 border-black/10 pl-12">
                  <h4 className="mb-8 text-3xl font-black uppercase tracking-tighter text-black/35">
                    {faq.q}
                  </h4>
                  <p className="text-2xl font-medium leading-snug tracking-tight lg:text-3xl">
                    {faq.a}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="border-t border-white/10 bg-black py-48 text-center">
          <div className={shell}>
            <h2 className="massive-type mb-20 font-black uppercase tracking-tighter leading-none text-white">
              Own the <br /> truth.
            </h2>
            <CheckoutButton className={`${primaryButton} px-24 py-12 text-4xl sm:text-5xl`}>
              Get MacWiFi
            </CheckoutButton>
          </div>
        </section>
      </main>
    </>
  )
}
