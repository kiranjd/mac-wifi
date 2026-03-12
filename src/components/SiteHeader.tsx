import { Link, useLocation } from 'react-router-dom'
import { navLink, shell } from '../lib/ui'

const navItems = [
  { href: '/#answers', label: 'Truth' },
  { href: '/#walkthrough', label: 'How' },
  { href: '/pricing', label: 'Buy' },
  { href: '/#faq', label: '?' },
]

export default function SiteHeader() {
  const location = useLocation()
  const isHome = location.pathname === '/'

  return (
    <header className="sticky top-0 z-50 border-b-2 border-black bg-white/90 backdrop-blur-md">
      <div className={`${shell} flex h-32 items-center justify-between`}>
        <Link
          className="text-4xl font-black uppercase tracking-tighter text-black transition-transform hover:scale-105 active:scale-95"
          to="/"
          aria-label="MacWiFi home"
        >
          MacWiFi.
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
          <Link to="/pricing" className="bg-black px-12 py-4 font-display font-black uppercase tracking-tighter text-white transition-all hover:invert">
            Get License
          </Link>
        </div>
      </div>
    </header>
  )
}
