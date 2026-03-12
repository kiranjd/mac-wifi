import { Link, useLocation } from 'react-router-dom'
import { navLink, shell } from '../lib/ui'

const navItems = [
  { href: '/#answers', label: 'Truth' },
  { href: '/#walkthrough', label: 'How' },
  { href: '/pricing/', label: 'Buy' },
  { href: '/#faq', label: '?' },
]

export default function SiteHeader() {
  const location = useLocation()
  const isHome = location.pathname === '/'

  return (
    <header className="sticky top-0 z-50 border-b border-white/8 bg-black/88 backdrop-blur-xl">
      <div className={`${shell} flex h-32 items-center justify-between`}>
        <Link
          className="flex items-center gap-6"
          to="/"
          aria-label="MacWiFi home"
        >
          <div className="h-16 w-16 overflow-hidden border border-white/15 bg-white/6 p-1">
            <img
              className="h-full w-full object-contain grayscale"
              src="/assets/icon.png"
              alt="MacWiFi"
            />
          </div>
          <span className="text-4xl font-black uppercase tracking-tighter text-white">
            MacWiFi.
          </span>
        </Link>

        <nav
          className="hidden items-center gap-20 md:flex"
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

        <div className="flex items-center">
          <Link
            to="/pricing/"
            className="border border-white/12 bg-white px-12 py-4 font-display font-black uppercase tracking-tighter text-black transition-colors hover:bg-accent"
          >
            Get License
          </Link>
        </div>
      </div>
    </header>
  )
}
