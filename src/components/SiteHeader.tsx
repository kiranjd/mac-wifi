import { Link, useLocation } from 'react-router-dom'

type SiteHeaderProps = {
  ctaLabel?: string
  ctaHref?: string
}

const navItems = [
  { href: '/pricing', label: 'Pricing' },
  { href: '/blog', label: 'Blog' },
  { href: '/#faq', label: 'FAQ' },
]

export default function SiteHeader({ ctaLabel = 'Pricing', ctaHref = '/pricing' }: SiteHeaderProps) {
  const location = useLocation()
  const isHome = location.pathname === '/'

  return (
    <header className="site-header">
      <div className="shell header-row">
        <Link className="brand-link" to="/" aria-label="MacWiFi home">
          <img src="/assets/icon.png" alt="" />
          <span>MacWiFi</span>
        </Link>

        <nav className="header-nav" aria-label="Primary">
          {navItems.map((item) =>
            item.href.startsWith('/#') && !isHome ? (
              <a key={item.href} href={item.href}>
                {item.label}
              </a>
            ) : item.href.startsWith('/#') ? (
              <a key={item.href} href={item.href.slice(1)}>
                {item.label}
              </a>
            ) : (
              <Link key={item.href} to={item.href}>
                {item.label}
              </Link>
            ),
          )}
        </nav>

        <Link className="button button-small" to={ctaHref}>
          {ctaLabel}
        </Link>
      </div>
    </header>
  )
}
