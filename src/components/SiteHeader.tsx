import { Link, useLocation } from 'react-router-dom'
import CheckoutButton from './CheckoutButton'
import { navLink, primaryButton, shell } from '../lib/ui'

const navItems = [
  { href: '/#answers', label: 'Features' },
  { href: '/#walkthrough', label: 'How it works' },
  { href: '/pricing', label: 'Pricing' },
  { href: '/#faq', label: 'FAQ' },
]

export default function SiteHeader() {
  const location = useLocation()
  const isHome = location.pathname === '/'

  return (
    <header className="sticky top-0 z-40 border-b border-slate-900/8 bg-[#ece8de]/88 backdrop-blur-xl">
      <div className={`${shell} flex items-center gap-5 py-4`}>
        <Link
          className="inline-flex items-center gap-2.5 text-base font-semibold tracking-[-0.04em] text-slate-950 sm:gap-3 sm:text-lg"
          to="/"
          aria-label="MacWiFi home"
        >
          <img
            className="h-9 w-9 rounded-xl border border-slate-900/8 shadow-[0_18px_28px_-20px_rgba(15,23,42,0.45)] sm:h-11 sm:w-11"
            src="/assets/icon.png"
            alt=""
          />
          <span>MacWiFi</span>
        </Link>

        <nav
          className="ml-auto hidden flex-wrap items-center justify-end gap-6 text-right md:flex"
          aria-label="Primary"
        >
          {navItems.map((item) =>
            item.href.startsWith('/#') && !isHome ? (
              <a key={item.href} className={navLink} href={item.href}>
                {item.label}
              </a>
            ) : item.href.startsWith('/#') ? (
              <a key={item.href} className={navLink} href={item.href.slice(1)}>
                {item.label}
              </a>
            ) : (
              <Link key={item.href} className={navLink} to={item.href}>
                {item.label}
              </Link>
            ),
          )}
        </nav>

        <div className="ml-auto md:ml-6">
          <CheckoutButton className={`${primaryButton} px-3.5 py-2 text-xs sm:px-4 sm:py-2.5 sm:text-sm`}>
            Buy for $9.99
          </CheckoutButton>
        </div>
      </div>
    </header>
  )
}
