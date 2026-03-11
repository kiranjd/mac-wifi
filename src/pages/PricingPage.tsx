import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { CHECKOUT_URL, PRICE } from '../config/commerce'
import { decorateCheckoutHref } from '../lib/checkout'
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
  url: CHECKOUT_URL,
}

export default function PricingPage() {
  const [checkoutHref, setCheckoutHref] = useState(CHECKOUT_URL)

  useEffect(() => {
    let cancelled = false
    decorateCheckoutHref(CHECKOUT_URL).then((href) => {
      if (!cancelled) {
        setCheckoutHref(href)
      }
    })
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <>
      <SeoHead meta={pricingMeta}>
        <script type="application/ld+json">{JSON.stringify(pricingSchema)}</script>
      </SeoHead>

      <main className="section-pad pricing-page">
        <div className="shell pricing-layout">
          <div className="pricing-copy">
            <p className="section-label">Pricing</p>
            <h1>MacWiFi is $9.99 once.</h1>
            <p className="pricing-lead">
              MacWiFi costs {PRICE} once. It lives in the menu bar and translates connection health
              into plain answers about calls, streaming, browsing, and whether the problem looks
              close to you or farther upstream.
            </p>

            <div className="pricing-includes">
              <div>
                <strong>Current usability</strong>
                <span>Calls, streaming, browsing</span>
              </div>
              <div>
                <strong>Problem split</strong>
                <span>Wi-Fi side or internet side</span>
              </div>
              <div>
                <strong>Deeper detail</strong>
                <span>Signal, radio, DNS, live graph</span>
              </div>
            </div>

            <div className="pricing-note-block">
              <p>Purchase email includes the download details and license key.</p>
            </div>
          </div>

          <aside className="pricing-card">
            <div className="price-pill">MacWiFi</div>
            <div className="price-block">
              <strong>{PRICE}</strong>
              <span>One-time purchase</span>
            </div>

            <ul>
              <li>Native macOS menu bar app</li>
              <li>No account</li>
              <li>License activation inside the app</li>
              <li>Download delivered by email after checkout</li>
            </ul>

            <a className="button button-wide lemonsqueezy-button" href={checkoutHref}>
              Buy MacWiFi
            </a>
            <Link className="button button-secondary button-wide" to="/help/activate-license">
              Activation help
            </Link>

            <figure className="pricing-shot">
              <img src="/assets/wi-fi.png" alt="MacWiFi screenshot." />
            </figure>
          </aside>
        </div>
      </main>
    </>
  )
}
