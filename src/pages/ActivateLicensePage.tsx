import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const pageMeta = makeMeta({
  title: 'Activate MacWiFi License',
  description: 'How to activate your MacWiFi license after purchase.',
  canonicalPath: '/help/activate-license',
})

export default function ActivateLicensePage() {
  return (
    <>
      <SeoHead meta={pageMeta} />
      <main className="section-pad help-page">
        <div className="shell help-layout">
          <div className="intro-block">
            <p className="section-label">Activation</p>
            <h1>Activate your MacWiFi license.</h1>
            <p>
              Open MacWiFi and the app will show the license screen immediately until this Mac is
              activated. Paste the key from your purchase email there.
            </p>
          </div>

          <div className="help-card">
            <ol>
              <li>Buy MacWiFi and open the purchase email.</li>
              <li>Open the app. If it is not activated yet, MacWiFi opens straight into the license screen.</li>
              <li>Paste the key into the activation field, or use the one-click activation link from the email.</li>
            </ol>
            <p>
              If anything looks wrong, email <a href="mailto:support@macwifi.live">support@macwifi.live</a>.
            </p>
          </div>
        </div>
      </main>
    </>
  )
}
