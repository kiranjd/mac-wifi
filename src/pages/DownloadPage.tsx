import { Link } from 'react-router-dom'
import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const pageMeta = makeMeta({
  title: 'Download MacWiFi',
  description: 'Download instructions for MacWiFi buyers.',
  canonicalPath: '/download',
})

export default function DownloadPage() {
  return (
    <>
      <SeoHead meta={pageMeta} />
      <main className="section-pad help-page">
        <div className="shell help-layout">
          <div className="intro-block">
            <p className="section-label">Download</p>
            <h1>Use the download in your purchase email.</h1>
            <p>
              If you already bought MacWiFi, the purchase email includes the download path and
              license details. If you have not bought it yet, start on the pricing page.
            </p>
          </div>

          <div className="help-card">
            <div className="button-row">
              <Link className="button" to="/pricing">
                See pricing
              </Link>
              <a className="button button-secondary" href="mailto:support@macwifi.live">
                Contact support
              </a>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}
