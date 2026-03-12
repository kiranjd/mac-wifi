import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'
import { card, eyebrow, lead, section, sectionTitle, shell } from '../lib/ui'

const pageMeta = makeMeta({
  title: 'Activate MacWiFi License',
  description: 'How to activate your MacWiFi license after purchase.',
  canonicalPath: '/help/activate-license/',
})

export default function ActivateLicensePage() {
  return (
    <>
      <SeoHead meta={pageMeta} />
      <main className={section}>
        <div className={`${shell} grid gap-8 lg:max-w-5xl lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1fr)]`}>
          <div className="max-w-2xl">
            <p className={eyebrow}>Activation</p>
            <h1 className={sectionTitle}>Activate your MacWiFi license.</h1>
            <p className={`${lead} mt-5`}>
              Open MacWiFi and the app will show the license screen immediately until this Mac is
              activated. Paste the key from your purchase email there.
            </p>
          </div>

          <div className={`${card} p-7`}>
            <ol className="list-decimal space-y-3 pl-5 text-base leading-7 text-slate-700">
              <li>Buy MacWiFi and open the purchase email.</li>
              <li>
                Open the app. If it is not activated yet, MacWiFi opens straight into the license
                screen.
              </li>
              <li>
                Paste the key into the activation field, or use the one-click activation link from
                the email.
              </li>
            </ol>
            <p className="mt-6 text-base leading-7 text-slate-700">
              If anything looks wrong, email <a href="mailto:support@macwifi.live">support@macwifi.live</a>.
            </p>
          </div>
        </div>
      </main>
    </>
  )
}
