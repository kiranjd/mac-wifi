import type { ReactNode } from 'react'
import {
  Activity,
  ArrowLeftRight,
  ChartNoAxesCombined,
  CircleDollarSign,
  LifeBuoy,
  Monitor,
  ShoppingCart,
  ShieldCheck,
  Wifi,
  Zap,
} from 'lucide-react'
import { Link } from 'react-router-dom'
import CheckoutButton from '../components/CheckoutButton'
import { PRICE } from '../config/commerce'
import { eyebrow, lead, section, sectionTitle, shell, card, primaryButton, secondaryButton } from '../lib/ui'
import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const pricingMeta = makeMeta({
  title: 'MacWiFi Pricing | One-time purchase',
  description:
    'MacWiFi is a $9.99 one-time macOS menu bar app that tells you how usable your current internet actually is and whether the problem looks local or upstream.',
  canonicalPath: '/pricing/',
})

const pricingSchema = {
  '@context': 'https://schema.org',
  '@type': 'Offer',
  name: 'MacWiFi',
  price: '9.99',
  priceCurrency: 'USD',
  availability: 'https://schema.org/InStock',
  url: 'https://macwifi.live/pricing/',
}

function FeatureIcon({
  children,
  tintClass,
}: {
  children: ReactNode
  tintClass: string
}) {
  return (
    <span
      className={`inline-flex h-12 w-12 items-center justify-center rounded-[14px] shadow-sm ${tintClass}`}
    >
      {children}
    </span>
  )
}

export default function PricingPage() {
  return (
    <>
      <SeoHead meta={pricingMeta}>
        <script type="application/ld+json">{JSON.stringify(pricingSchema)}</script>
      </SeoHead>

      <main className="min-h-[calc(100vh-80px)]">
        <section className={section}>
          <div className={`${shell} grid gap-16 lg:grid-cols-[1fr_minmax(0,420px)] lg:items-start`}>
            <div>
              <p className={eyebrow}>Pricing</p>
              <h1 className={sectionTitle}>One-time payment.</h1>
              <p className={`${lead} mt-6`}>
                Stop guessing if your internet is actually ready for the next call. Get MacWiFi
                and know for sure in one click.
              </p>

              <div className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
                <div className="flex flex-col items-start gap-4">
                  <FeatureIcon tintClass="bg-emerald-100 text-emerald-700">
                    <Activity className="h-6 w-6" strokeWidth={2.5} />
                  </FeatureIcon>
                  <div>
                    <strong className="block text-lg font-bold text-slate-900">
                      Current usability
                    </strong>
                    <span className="mt-1 block text-sm leading-6 text-slate-600">
                      Instant green light for Zoom, Meet, and Slack calls.
                    </span>
                  </div>
                </div>
                <div className="flex flex-col items-start gap-4">
                  <FeatureIcon tintClass="bg-indigo-100 text-indigo-700">
                    <ArrowLeftRight className="h-6 w-6" strokeWidth={2.5} />
                  </FeatureIcon>
                  <div>
                    <strong className="block text-lg font-bold text-slate-900">
                      Problem split
                    </strong>
                    <span className="mt-1 block text-sm leading-6 text-slate-600">
                      Know if the trouble is on your Wi-Fi or your ISP side.
                    </span>
                  </div>
                </div>
                <div className="flex flex-col items-start gap-4">
                  <FeatureIcon tintClass="bg-amber-100 text-amber-700">
                    <ChartNoAxesCombined className="h-6 w-6" strokeWidth={2.5} />
                  </FeatureIcon>
                  <div>
                    <strong className="block text-lg font-bold text-slate-900">
                      Deeper detail
                    </strong>
                    <span className="mt-1 block text-sm leading-6 text-slate-600">
                      Technical graphs for jitter, packet loss, and DNS timing.
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <aside className="sticky top-32">
              <div className={card}>
                <div className="p-8">
                  <h2 className="text-xl font-bold text-slate-900">MacWiFi Lifetime</h2>
                  <div className="mt-4 flex items-baseline gap-2">
                    <span className="text-5xl font-extrabold tracking-tight text-slate-950">
                      {PRICE}
                    </span>
                    <span className="text-sm font-bold text-slate-500 uppercase tracking-wider">
                      One-time
                    </span>
                  </div>

                  <ul className="mt-8 space-y-4">
                    {[
                      'Native macOS menu bar app',
                      'Intel & Apple Silicon native',
                      'No monthly subscriptions',
                      'No account or login required',
                      'Fast, plain-English answers',
                      'Privacy-first: no data collection',
                    ].map((feature) => (
                      <li key={feature} className="flex items-start gap-3 text-sm text-slate-600">
                        <ShieldCheck className="h-5 w-5 shrink-0 text-emerald-600" />
                        <span>{feature}</span>
                      </li>
                    ))}
                  </ul>

                  <div className="mt-10 flex flex-col gap-4">
                    <CheckoutButton className={`${primaryButton} w-full gap-2`}>
                      <ShoppingCart className="h-5 w-5" strokeWidth={2.5} />
                      <span>Buy MacWiFi</span>
                    </CheckoutButton>
                    <p className="text-center text-xs font-bold uppercase tracking-widest text-slate-400">
                      Secure checkout via LemonSqueezy
                    </p>
                  </div>
                </div>
              </div>

              <figure className="mt-8 overflow-hidden rounded-2xl border border-slate-900/5 bg-slate-100 shadow-inner">
                <img
                  className="block w-full"
                  src="/assets/wi-fi.png"
                  alt="MacWiFi screenshot."
                />
              </figure>
            </aside>
          </div>
        </section>
      </main>
    </>
  )
}
