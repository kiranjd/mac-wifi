import { ShoppingCart } from 'lucide-react'
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
    <header className="sticky top-0 z-50 border-b border-slate-200/60 bg-white/80 backdrop-blur-2xl">
      <div className={`${shell} flex h-20 items-center gap-6`}>
        <Link
          className="inline-flex items-center gap-3 text-[1.25rem] font-extrabold tracking-tight text-slate-900 font-['Plus_Jakarta_Sans'] transition-opacity hover:opacity-80"
          to="/"
          aria-label="MacWiFi home"
        >
          <img
            className="h-10 w-10 rounded-[14px] shadow-sm"
            src="/assets/icon.png"
            alt=""
          />
          <span className="hidden sm:inline">MacWiFi</span>
        </Link>

        <nav
          className="ml-auto hidden flex-wrap items-center justify-end gap-10 md:flex"
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

        <div className="ml-auto md:ml-4">
          <CheckoutButton className={`${primaryButton} h-[44px] gap-2 px-5 py-0 text-sm`}>
            <ShoppingCart className="h-[18px] w-[18px]" strokeWidth={2.5} />
            <span className="hidden xs:inline">Buy Now</span>
            <span className="xs:hidden">Buy</span>
          </CheckoutButton>
        </div>
      </div>
    </header>
  )
}
