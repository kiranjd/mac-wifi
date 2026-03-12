import CheckoutButton from '../components/CheckoutButton'
import { PRICE } from '../config/commerce'
import { lead, pageTitle, primaryButton, section, shell } from '../lib/ui'
import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const pricingMeta = makeMeta({
  title: 'Pricing | One Time.',
  description: 'One purchase. Lifetime access.',
  canonicalPath: '/pricing/',
})

export default function PricingPage() {
  return (
    <>
      <SeoHead meta={pricingMeta} />

      <main className="min-h-screen bg-black text-white">
        <section className={section}>
          <div className={shell}>
            <h1 className={pageTitle}>ONE <br /> PURCHASE.</h1>
            <div className="mt-24 grid gap-24 lg:grid-cols-[1.1fr_0.9fr] lg:items-start">
              <div>
                <p className={lead}>
                  No monthly fee. No data collection. No forced upsell. Buy MacWiFi once and keep
                  the full network diagnostic tool on your Mac.
                </p>
                <div className="mt-16 space-y-6">
                  {[
                    'Native Swift binary',
                    'Apple Silicon and Intel support',
                    'Zero cloud dependency',
                    'Secure LemonSqueezy checkout',
                  ].map((spec) => (
                    <div
                      key={spec}
                      className="flex items-center gap-5 font-display text-sm font-black uppercase tracking-[0.28em] text-white/42"
                    >
                      <div className="h-px w-12 bg-accent/65" />
                      {spec}
                    </div>
                  ))}
                </div>
              </div>
              <div className="border border-white/10 bg-white/[0.04] p-12 text-center lg:p-24">
                <span className="mb-12 block text-[8rem] font-black leading-none tracking-tighter text-white lg:text-[10rem]">
                  {PRICE}
                </span>
                <CheckoutButton className={`${primaryButton} w-full justify-center py-10 text-3xl`}>
                  Get lifetime access
                </CheckoutButton>
                <p className="mt-8 font-display text-[11px] font-black uppercase tracking-[0.28em] text-white/38">
                  Secure checkout via LemonSqueezy
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>
    </>
  )
}
