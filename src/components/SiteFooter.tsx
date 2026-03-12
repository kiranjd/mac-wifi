import { Link } from 'react-router-dom'
import { shell } from '../lib/ui'

export default function SiteFooter() {
  const year = new Date().getFullYear()

  return (
    <footer className="bg-white border-t border-black py-32">
      <div className={shell}>
        <div className="grid gap-24 lg:grid-cols-2 items-start">
          <div>
            <h2 className="text-6xl font-black uppercase tracking-tighter mb-12">MACWIFI.</h2>
            <p className="text-xl font-medium tracking-tight text-black/40 uppercase">
              The only tool you need for network truth. <br />
              Made for remote professionals.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-12 uppercase font-black tracking-tighter">
            <nav className="flex flex-col gap-4">
              <Link className="hover:line-through" to="/">Home</Link>
              <Link className="hover:line-through" to="/pricing/">Pricing</Link>
              <Link className="hover:line-through" to="/download/">Download</Link>
            </nav>
            <nav className="flex flex-col gap-4">
              <Link className="hover:line-through" to="/help/activate-license/">Help</Link>
              <a className="hover:line-through" href="mailto:support@macwifi.live">Support</a>
            </nav>
          </div>
        </div>
        <div className="mt-32 pt-12 border-t border-black font-black uppercase tracking-tighter text-black/20 text-xs">
          <p>© {year} MACWIFI. ALL RIGHTS RESERVED.</p>
        </div>
      </div>
    </footer>
  )
}
