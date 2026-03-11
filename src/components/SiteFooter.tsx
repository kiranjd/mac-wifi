import { Link } from 'react-router-dom'

export default function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="shell footer-grid">
        <div className="footer-copy">
          <p className="section-label">MacWiFi</p>
          <h2>The diagnostic tool macOS should have had.</h2>
          <p>
            A small menu bar app that turns connection data into plain answers about whether your
            current internet is usable and where the problem likely lives.
          </p>
        </div>

        <div className="footer-links">
          <Link to="/">Home</Link>
          <Link to="/pricing">Pricing</Link>
          <Link to="/blog">Blog</Link>
          <Link to="/help/activate-license">Activate license</Link>
          <a href="mailto:support@macwifi.live">Support</a>
        </div>
      </div>
    </footer>
  )
}
