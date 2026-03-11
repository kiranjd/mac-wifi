import { Link } from 'react-router-dom'
import CheckoutButton from './CheckoutButton'
import { eyebrow, primaryButton, secondaryButton, shell } from '../lib/ui'

export default function SiteFooter() {
  return (
    <footer className="overflow-hidden border-t border-slate-900/8 bg-[radial-gradient(circle_at_top_left,rgba(20,184,166,0.28),transparent_28%),radial-gradient(circle_at_bottom_right,rgba(251,191,36,0.18),transparent_30%),linear-gradient(180deg,#07131b,#0b1a22)] py-20 text-slate-100">
      <div className={`${shell} grid gap-12 lg:grid-cols-[minmax(0,1.1fr)_auto] lg:items-start`}>
        <div className="max-w-2xl">
          <p className={`${eyebrow} text-emerald-300`}>MacWiFi</p>
          <h2 className="text-[2.8rem] leading-[0.92] tracking-[-0.07em] sm:text-5xl">
            Stop guessing before important calls.
          </h2>
          <p className="mt-5 max-w-xl text-lg leading-8 text-slate-300">
            MacWiFi tells you whether the connection can hold up, what it can handle, and where
            the problem likely is.
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
            <CheckoutButton className={primaryButton}>Buy for $9.99</CheckoutButton>
            <Link className={secondaryButton} to="/help/activate-license">
              FAQ / help
            </Link>
          </div>
        </div>

        <nav className="flex flex-wrap gap-3 lg:max-w-sm lg:justify-end" aria-label="Footer">
          <Link
            className="rounded-full border border-white/12 bg-white/8 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-white/14"
            to="/"
          >
            Home
          </Link>
          <Link
            className="rounded-full border border-white/12 bg-white/8 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-white/14"
            to="/pricing"
          >
            Pricing
          </Link>
          <Link
            className="rounded-full border border-white/12 bg-white/8 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-white/14"
            to="/help/activate-license"
          >
            Help
          </Link>
          <a
            className="rounded-full border border-white/12 bg-white/8 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-white/14"
            href="mailto:support@macwifi.live"
          >
            Support
          </a>
        </nav>
      </div>
    </footer>
  )
}
