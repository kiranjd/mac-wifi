import { Link } from 'react-router-dom'
import CheckoutButton from '../components/CheckoutButton'
import { PRICE } from '../config/commerce'
import { card, eyebrow, lead, primaryButton, section, sectionTitle, secondaryButton, shell } from '../lib/ui'
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

export default function PricingPage() {
  return (
    <>
      <SeoHead meta={pricingMeta}>
        <script type="application/ld+json">{JSON.stringify(pricingSchema)}</script>
      </SeoHead>

      <main className={section}>
        <div className={`${shell} grid items-start gap-8 lg:grid-cols-[minmax(0,1fr)_380px] lg:gap-12`}>
          <div className="max-w-2xl">
            <p className={eyebrow}>Pricing</p>
            <h1 className={sectionTitle}>MacWiFi is {PRICE} once.</h1>
            <p className={`${lead} mt-5 max-w-xl`}>
              MacWiFi costs {PRICE} once. It lives in the menu bar and translates connection health
              into plain answers about calls, streaming, browsing, and whether the problem looks
              close to you or farther upstream.
            </p>

            <div className="mt-8 grid gap-3 sm:grid-cols-3">
              {[
                ['Current usability', 'Calls, streaming, browsing'],
                ['Problem split', 'Wi-Fi side or internet side'],
                ['Deeper detail', 'Signal, radio, DNS, live graph'],
              ].map(([title, copy]) => (
                <div key={title} className={`${card} p-5`}>
                  <strong className="block text-base font-semibold tracking-[-0.03em] text-slate-950">
                    {title}
                  </strong>
                  <span className="mt-2 block text-sm leading-6 text-slate-600">{copy}</span>
                </div>
              ))}
            </div>

            <div className={`${card} mt-8 max-w-xl p-6`}>
              <p className="text-base leading-7 text-slate-700">
                Purchase email includes the download details and license key.
              </p>
            </div>
          </div>

          <aside className={`${card} sticky top-28 p-7`}>
            <div className="inline-flex rounded-full border border-emerald-700/18 bg-emerald-500/10 px-3 py-1 text-sm font-semibold text-emerald-800">
              MacWiFi
            </div>
            <div className="mt-5">
              <strong className="block text-[3.6rem] font-semibold leading-none tracking-[-0.08em] text-slate-950">
                {PRICE}
              </strong>
              <span className="mt-2 block text-base text-slate-600">One-time purchase</span>
            </div>

            <ul className="mt-6 space-y-3 text-[0.98rem] leading-7 text-slate-700">
              <li>Native macOS menu bar app</li>
              <li>No account</li>
              <li>License activation inside the app</li>
              <li>Download delivered by email after checkout</li>
            </ul>

            <CheckoutButton className={`${primaryButton} mt-8 w-full justify-center`}>
              Buy MacWiFi
            </CheckoutButton>
            <Link className={`${secondaryButton} mt-3 w-full justify-center`} to="/help/activate-license">
              Activation help
            </Link>

            <figure className="mt-8">
              <img
                className="block w-full rounded-[24px] shadow-[0_34px_90px_-52px_rgba(15,23,42,0.52)]"
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
