import { Link } from 'react-router-dom'
import { shell } from '../lib/ui'

export default function SiteFooter() {
  return (
    <footer className="border-t border-white/10 bg-black py-40 text-white">
      <div className={shell}>
        <div className="grid items-start gap-24 lg:grid-cols-2">
          <div>
            <div className="mb-10 flex items-center gap-6">
              <div className="h-20 w-20 border border-white/12 bg-white p-1">
                <img
                  className="h-full w-full object-contain grayscale"
                  src="/assets/icon.png"
                  alt="MacWiFi"
                />
              </div>
              <h2 className="text-7xl font-black uppercase tracking-tighter">MACWIFI.</h2>
            </div>
            <p className="max-w-xl text-xl font-medium uppercase leading-tight tracking-tight text-white/60">
              The only tool you need for network truth. <br />
              Built for remote work that cannot break.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-18 text-xl font-black uppercase tracking-tighter">
            <nav className="flex flex-col gap-6">
              <Link className="strikethrough-hover w-fit" to="/">Home</Link>
              <Link className="strikethrough-hover w-fit" to="/pricing/">Pricing</Link>
              <Link className="strikethrough-hover w-fit" to="/download/">Download</Link>
            </nav>
            <nav className="flex flex-col gap-6">
              <Link className="strikethrough-hover w-fit" to="/help/activate-license/">Help</Link>
              <a className="strikethrough-hover w-fit" href="mailto:support@macwifi.live">Support</a>
            </nav>
          </div>
        </div>

        <div className="mt-32 flex flex-col items-center justify-between gap-8 border-t border-white/10 pt-10 text-xs font-black uppercase tracking-tighter text-white/30 sm:flex-row">
          <p>© {new Date().getFullYear()} MACWIFI. ALL RIGHTS RESERVED.</p>
          <p>support@macwifi.live</p>
        </div>
      </div>
    </footer>
  )
}
