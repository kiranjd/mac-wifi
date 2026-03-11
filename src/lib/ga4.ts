const GA_MEASUREMENT_ID = import.meta.env.VITE_PUBLIC_GA4_ID || 'G-0DWSJTXQ65'

type GtagArgs = [string, ...unknown[]]

declare global {
  interface Window {
    gtag?: (...args: GtagArgs) => void
  }
}

export const trackGAEvent = (...args: GtagArgs) => {
  if (import.meta.env.DEV) return
  if (typeof window === 'undefined' || typeof window.gtag !== 'function') return
  window.gtag(...args)
}

export const trackPageView = () => {
  if (import.meta.env.DEV) return
  if (typeof window === 'undefined' || typeof window.gtag !== 'function') return
  window.gtag('event', 'page_view', {
    send_to: GA_MEASUREMENT_ID,
    page_title: document.title,
    page_location: window.location.href,
    page_path: window.location.pathname,
  })
}

export {}
