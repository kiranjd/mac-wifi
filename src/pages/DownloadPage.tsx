import { CreditCard, Download, Mail } from 'lucide-react'
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
            <div className="mb-5 grid gap-3 sm:grid-cols-2">
              <div className="rounded-[12px] border border-slate-900/8 bg-white/70 p-4">
                <Download className="h-[18px] w-[18px] text-[#0f766e]" strokeWidth={2} />
                <strong className="mt-3 block text-sm font-semibold tracking-[-0.03em] text-slate-950">
                  Already bought it?
                </strong>
                <p className="mt-1.5 text-sm leading-6 text-slate-600">
                  Open the purchase email and use the download link there.
                </p>
              </div>
              <div className="rounded-[12px] border border-slate-900/8 bg-white/70 p-4">
                <CreditCard className="h-[18px] w-[18px] text-[#0f766e]" strokeWidth={2} />
                <strong className="mt-3 block text-sm font-semibold tracking-[-0.03em] text-slate-950">
                  Need to buy first?
                </strong>
                <p className="mt-1.5 text-sm leading-6 text-slate-600">
                  Start on the MacWiFi page and finish checkout there.
                </p>
              </div>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link className={`${primaryButton} gap-2`} to="/pricing">
                <CreditCard className="h-[18px] w-[18px]" strokeWidth={2} />
                <span>See MacWiFi</span>
              </Link>
              <a className={`${secondaryButton} gap-2`} href="mailto:support@macwifi.live">
                <Mail className="h-[18px] w-[18px]" strokeWidth={1.9} />
                <span>Contact support</span>
              </a>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}
