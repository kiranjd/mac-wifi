import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'
import { card, eyebrow, lead, section, sectionTitle, shell } from '../lib/ui'

const pageMeta = makeMeta({
  title: 'MacWiFi Getting Started',
  description: 'How to install MacWiFi and get your first read on the current connection.',
  canonicalPath: '/help/getting-started/',
})

export default function GettingStartedPage() {
  return (
    <>
      <SeoHead meta={pageMeta} />
      <main className={section}>
        <div className={`${shell} grid gap-8 lg:max-w-5xl lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1fr)]`}>
          <div className="max-w-2xl">
            <p className={eyebrow}>Getting started</p>
            <h1 className={sectionTitle}>Install it. Open it. Read the connection.</h1>
            <p className={`${lead} mt-5`}>
              MacWiFi is meant to be quick: install from the download in your purchase email, open
              it from the menu bar, and use the readiness view as your first answer.
            </p>
          </div>

          <div className={`${card} p-7`}>
            <ol className="list-decimal space-y-3 pl-5 text-base leading-7 text-slate-700">
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
