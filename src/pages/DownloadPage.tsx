import { Link } from 'react-router-dom'
import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'
import { card, eyebrow, lead, primaryButton, secondaryButton, section, sectionTitle, shell } from '../lib/ui'

const pageMeta = makeMeta({
  title: 'Download MacWiFi',
  description: 'Download instructions for MacWiFi buyers.',
  canonicalPath: '/download',
})

export default function DownloadPage() {
  return (
    <>
      <SeoHead meta={pageMeta} />
      <main className={section}>
        <div className={`${shell} grid gap-8 lg:max-w-5xl lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1fr)]`}>
          <div className="max-w-2xl">
            <p className={eyebrow}>Download</p>
            <h1 className={sectionTitle}>Use the download in your purchase email.</h1>
            <p className={`${lead} mt-5`}>
              If you already bought MacWiFi, the purchase email includes the download path and
              license details. If you have not bought it yet, start on the pricing page.
            </p>
          </div>

          <div className={`${card} p-7`}>
            <div className="flex flex-wrap gap-3">
              <Link className={primaryButton} to="/pricing">
                See pricing
              </Link>
              <a className={secondaryButton} href="mailto:support@macwifi.live">
                Contact support
              </a>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}
