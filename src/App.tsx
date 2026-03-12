import { useEffect } from 'react'
import { Route, Routes, useLocation } from 'react-router-dom'
import SiteHeader from './components/SiteHeader'
import SiteFooter from './components/SiteFooter'
import HomePage from './pages/HomePage'
import PricingPage from './pages/PricingPage'
import BlogIndexPage from './pages/BlogIndexPage'
import ActivateLicensePage from './pages/ActivateLicensePage'
import GettingStartedPage from './pages/GettingStartedPage'
import DownloadPage from './pages/DownloadPage'
import { trackGAEvent, trackPageView } from './lib/ga4'
import { initLemonOverlay } from './lib/lemon'

function RouteEffects() {
  const location = useLocation()

  useEffect(() => {
    if (typeof window !== 'undefined') {
      window.scrollTo({ top: 0, behavior: 'auto' })
    }
  }, [location.pathname])

  useEffect(() => {
    trackPageView()
    trackGAEvent('event', 'route_view', {
      page_path: location.pathname,
    })
  }, [location.pathname, location.search])

  return null
}

export default function App() {
  useEffect(() => initLemonOverlay('/download/'), [])

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-['DM_Sans'] selection:bg-indigo-100 selection:text-indigo-900">
      <RouteEffects />
      <SiteHeader />
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/pricing" element={<PricingPage />} />
        <Route path="/pricing/" element={<PricingPage />} />
        <Route path="/blog" element={<BlogIndexPage />} />
        <Route path="/blog/" element={<BlogIndexPage />} />
        <Route path="/help/activate-license" element={<ActivateLicensePage />} />
        <Route path="/help/activate-license/" element={<ActivateLicensePage />} />
        <Route path="/help/getting-started" element={<GettingStartedPage />} />
        <Route path="/help/getting-started/" element={<GettingStartedPage />} />
        <Route path="/download" element={<DownloadPage />} />
        <Route path="/download/" element={<DownloadPage />} />
        <Route path="*" element={<HomePage />} />
      </Routes>
      <SiteFooter />
    </div>
  )
}
