import CheckoutButton from '../components/CheckoutButton'
import { PRICE } from '../config/commerce'
import { pageTitle, section, shell, lead } from '../lib/ui'
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

      <main className="min-h-screen">
        <section className={section}>
          <div className={shell}>
            <h1 className={pageTitle}>ONE <br /> PURCHASE.</h1>
            <div className="mt-24 grid gap-24 lg:grid-cols-2">
              <div>
                <p className={lead}>
                  No monthly fees. No data tracking. No bullshit. Just the best network tool for macOS, yours forever.
                </p>
                <div className="mt-12 space-y-4 font-display font-black uppercase tracking-widest text-black/40">
                  <p>→ Native Swift Binary</p>
                  <p>→ Apple Silicon Native</p>
                  <p>→ Zero Cloud Dependency</p>
                </div>
              </div>
              <div className="bg-black p-12 lg:p-24 flex flex-col items-center justify-center text-center">
                <span className="text-white text-9xl font-black tracking-tighter mb-12">{PRICE}</span>
                <CheckoutButton className="w-full bg-white text-black py-8 text-2xl font-black uppercase tracking-tighter hover:line-through transition-all">
                  GET LIFETIME ACCESS
                </CheckoutButton>
                <p className="mt-8 text-white/40 font-mono text-xs uppercase tracking-widest">
                  Secure via LemonSqueezy
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>
    </>
  )
}
