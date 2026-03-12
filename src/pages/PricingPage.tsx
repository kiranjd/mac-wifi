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
import { eyebrow, lead, section, sectionTitle, shell } from '../lib/ui'
import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const pricingMeta = makeMeta({
  title: 'MacWiFi Pricing | One-time purchase',
  description:
    'MacWiFi is a $9.99 one-time macOS menu bar app that tells you how usable your current internet actually is and whether the problem looks local or upstream.',
  canonicalPath: '/pricing',
})

const pricingSchema = {
  '@context': 'https://schema.org',
  '@type': 'Offer',
  name: 'MacWiFi',
  price: '9.99',
  priceCurrency: 'USD',
  availability: 'https://schema.org/InStock',
  url: 'https://macwifi.live/pricing',
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
      className={`inline-flex h-11 w-11 items-center justify-center rounded-[12px] border border-slate-900/8 ${tintClass}`}
    >
      {children}
    </span>
  )
}

export default function PricingPage() {
  const featureItems = [
    {
      title: 'Current usability',
      copy: 'Calls, streaming, browsing',
      icon: <Activity className="h-5 w-5 text-slate-900" strokeWidth={1.9} />,
      tintClass: 'bg-[#eef6f5]',
    },
    {
      title: 'Problem split',
      copy: 'Wi-Fi side or internet side',
      icon: <ArrowLeftRight className="h-5 w-5 text-slate-900" strokeWidth={1.9} />,
      tintClass: 'bg-[#f5f0e8]',
    },
    {
      title: 'Deeper detail',
      copy: 'Signal, radio, DNS, live graph',
      icon: <ChartNoAxesCombined className="h-5 w-5 text-slate-900" strokeWidth={1.9} />,
      tintClass: 'bg-[#f4f1f8]',
    },
  ]

  const pricingItems = [
    { label: 'One-time purchase', icon: <CircleDollarSign className="h-[18px] w-[18px] text-[#2d6f68]" strokeWidth={1.9} /> },
    { label: 'Native macOS menu bar app', icon: <Monitor className="h-[18px] w-[18px] text-[#2d6f68]" strokeWidth={1.9} /> },
    { label: 'Fast call-readiness answer', icon: <Zap className="h-[18px] w-[18px] text-[#2d6f68]" strokeWidth={1.9} /> },
    { label: 'No account required', icon: <ShieldCheck className="h-[18px] w-[18px] text-[#2d6f68]" strokeWidth={1.9} /> },
  ]

  return (
    <>
      <SeoHead meta={pricingMeta}>
        <script type="application/ld+json">{JSON.stringify(pricingSchema)}</script>
      </SeoHead>

      <main className={section}>
        <div className={`${shell} grid items-start gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(420px,560px)] lg:gap-12`}>
          <div className="max-w-2xl lg:pt-4">
            <p className={eyebrow}>Pricing</p>
            <h1 className={sectionTitle}>MacWiFi is {PRICE} once.</h1>
            <p className={`${lead} mt-5 max-w-xl`}>
              MacWiFi costs {PRICE} once. It lives in the menu bar and translates connection health
              into plain answers about calls, streaming, browsing, and whether the problem looks
              close to you or farther upstream.
            </p>

            <div className="mt-8 grid gap-3 sm:grid-cols-3">
              {featureItems.map(({ title, copy, icon, tintClass }) => (
                <div
                  key={title}
                  className="rounded-[14px] border border-slate-900/8 bg-white px-4 py-4 shadow-[0_10px_26px_-20px_rgba(15,23,42,0.18)]"
                >
                  <FeatureIcon tintClass={tintClass}>{icon}</FeatureIcon>
                  <strong className="mt-4 block text-[0.98rem] font-semibold tracking-[-0.03em] text-slate-950">
                    {title}
                  </strong>
                  <span className="mt-1.5 block text-sm leading-6 text-slate-600">{copy}</span>
                </div>
              ))}
            </div>
          </div>

          <aside className="grid gap-4 lg:sticky lg:top-28 lg:grid-cols-[minmax(240px,280px)_minmax(180px,1fr)]">
            <div className="rounded-[14px] border border-slate-900/8 bg-white p-6 shadow-[0_14px_30px_-24px_rgba(15,23,42,0.22)]">
              <div className="inline-flex rounded-[10px] border border-[#2f7f76]/14 bg-[#eef6f5] px-3 py-1 text-sm font-semibold text-[#2d6f68]">
                MacWiFi
              </div>
              <div className="mt-5">
                <strong className="block text-[3.45rem] font-semibold leading-none tracking-[-0.08em] text-slate-950">
                  {PRICE}
                </strong>
                <span className="mt-2 block text-[0.98rem] text-slate-600">One-time purchase</span>
              </div>

              <ul className="mt-6 space-y-3">
                {pricingItems.map((item) => (
                  <li key={item.label} className="flex items-center gap-3 text-[0.96rem] leading-6 text-slate-700">
                    <span className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-[10px] bg-[#eef6f5]">
                      {item.icon}
                    </span>
                    <span>{item.label}</span>
                  </li>
                ))}
              </ul>

              <CheckoutButton className="mt-8 inline-flex w-full items-center justify-center gap-2 rounded-[10px] bg-[#2f7f76] px-5 py-3 text-[0.96rem] font-semibold text-white transition hover:bg-[#276861]">
                <ShoppingCart className="h-[18px] w-[18px]" strokeWidth={2} />
                <span>Buy MacWiFi</span>
              </CheckoutButton>
              <Link
                className="mt-3 inline-flex w-full items-center justify-center gap-2 rounded-[10px] border border-slate-900/10 bg-[#fbfaf8] px-5 py-3 text-[0.96rem] font-semibold text-slate-900 transition hover:bg-white"
                to="/help/activate-license"
              >
                <LifeBuoy className="h-[18px] w-[18px]" strokeWidth={1.9} />
                <span>Activation help</span>
              </Link>
            </div>

            <figure className="overflow-hidden rounded-[14px] border border-slate-900/8 bg-white p-3 shadow-[0_14px_30px_-24px_rgba(15,23,42,0.18)]">
              <div className="mb-3 flex flex-wrap gap-2">
                <span className="inline-flex items-center gap-1.5 rounded-[10px] bg-[#eef6f5] px-2.5 py-1 text-[0.76rem] font-medium text-[#2d6f68]">
                  <Wifi className="h-[16px] w-[16px]" strokeWidth={2} />
                  Menu bar
                </span>
                <span className="inline-flex items-center gap-1.5 rounded-[10px] bg-[#f5f0e8] px-2.5 py-1 text-[0.76rem] font-medium text-[#7b5a2f]">
                  <Activity className="h-[16px] w-[16px]" strokeWidth={2} />
                  Live answer
                </span>
              </div>
              <img
                className="block w-full rounded-[10px]"
                src="/assets/wi-fi.png"
                alt="MacWiFi screenshot."
              />
            </figure>
          </aside>
        </div>
      </main>
    </>
  )
}
