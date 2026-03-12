import { House, LifeBuoy, Mail, Tag, Heart } from 'lucide-react'
import { Link } from 'react-router-dom'
import { eyebrow, shell } from '../lib/ui'

export default function SiteFooter() {
  return (
    <footer className="bg-white border-t border-slate-100 py-24">
      <div className={shell}>
        <div className="grid gap-16 lg:grid-cols-[1fr_auto] items-start">
          <div className="max-w-xl">
            <Link to="/" className="inline-flex items-center gap-3 mb-8">
              <img
                className="h-10 w-10 rounded-[14px]"
                src="/assets/icon.png"
                alt="MacWiFi"
              />
              <span className="text-2xl font-extrabold tracking-tight text-slate-900 font-['Plus_Jakarta_Sans']">MacWiFi</span>
            </Link>
            <p className="text-xl text-slate-500 leading-relaxed font-['DM_Sans'] mb-8">
              The native macOS tool for remote professionals who need reliable internet for every call.
            </p>
            <div className="flex items-center gap-2 text-slate-400 font-medium font-['DM_Sans']">
              <span>Made with</span>
              <Heart className="h-4 w-4 text-rose-400 fill-rose-400" />
              <span>for the remote community.</span>
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-12 lg:gap-24">
            <div>
              <p className={`${eyebrow} !mb-6 text-slate-900`}>Product</p>
              <nav className="flex flex-col gap-4">
                <Link className="text-slate-500 hover:text-indigo-600 font-bold transition font-['Plus_Jakarta_Sans'] flex items-center gap-2" to="/">
                  <House className="h-4 w-4" /> Home
                </Link>
                <Link className="text-slate-500 hover:text-indigo-600 font-bold transition font-['Plus_Jakarta_Sans'] flex items-center gap-2" to="/pricing/">
                  <Tag className="h-4 w-4" /> Pricing
                </Link>
                <Link className="text-slate-500 hover:text-indigo-600 font-bold transition font-['Plus_Jakarta_Sans'] flex items-center gap-2" to="/download/">
                  Download
                </Link>
              </nav>
            </div>
            <div>
              <p className={`${eyebrow} !mb-6 text-slate-900`}>Support</p>
              <nav className="flex flex-col gap-4">
                <Link className="text-slate-500 hover:text-indigo-600 font-bold transition font-['Plus_Jakarta_Sans'] flex items-center gap-2" to="/help/activate-license/">
                  <LifeBuoy className="h-4 w-4" /> Help Center
                </Link>
                <a className="text-slate-500 hover:text-indigo-600 font-bold transition font-['Plus_Jakarta_Sans'] flex items-center gap-2" href="mailto:support@macwifi.live">
                  <Mail className="h-4 w-4" /> Contact
                </a>
              </nav>
            </div>
          </div>
        </div>
        
        <div className="mt-24 pt-12 border-t border-slate-50 flex flex-col sm:flex-row justify-between items-center gap-6 text-slate-400 text-sm font-medium font-['DM_Sans']">
          <p>© {new Date().getFullYear()} MacWiFi. All rights reserved.</p>
          <a href="mailto:support@macwifi.live" className="hover:text-slate-600 transition">
            support@macwifi.live
          </a>
        </div>
      </div>
    </footer>
  )
}
