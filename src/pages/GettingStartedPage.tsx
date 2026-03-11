import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'

const pageMeta = makeMeta({
  title: 'MacWiFi Getting Started',
  description: 'How to install MacWiFi and get your first read on the current connection.',
  canonicalPath: '/help/getting-started',
})

export default function GettingStartedPage() {
  return (
    <>
      <SeoHead meta={pageMeta} />
      <main className="section-pad help-page">
        <div className="shell help-layout">
          <div className="intro-block">
            <p className="section-label">Getting started</p>
            <h1>Install it. Open it. Read the connection.</h1>
            <p>
              MacWiFi is meant to be quick: install from the download in your purchase email, open
              it from the menu bar, and use the readiness view as your first answer.
            </p>
          </div>

          <div className="help-card">
            <ol>
              <li>Download the app from your purchase email.</li>
              <li>Move it to Applications and launch it.</li>
              <li>Grant the macOS permission needed for Wi-Fi details if prompted.</li>
              <li>Open the menu bar panel and check the current readiness state.</li>
            </ol>
          </div>
        </div>
      </main>
    </>
  )
}
