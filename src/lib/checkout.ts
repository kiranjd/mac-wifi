const CHECKOUT_HOST = 'kiranjd8.lemonsqueezy.com'

declare global {
  interface Window {
    gtag?: (...args: unknown[]) => void
  }
}

const getAttributionParams = () => {
  if (typeof window === 'undefined') return {}

  const search = new URLSearchParams(window.location.search)
  const params: Record<string, string> = {}

  for (const key of ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content', 'gclid', 'fbclid', 'msclkid', 'ttclid']) {
    const value = search.get(key)
    if (value) {
      params[key] = value
    }
  }

  params.landing_path = window.location.pathname

  if (document.referrer) {
    try {
      params.referrer_host = new URL(document.referrer).host
    } catch {
      // Ignore malformed referrers.
    }
  }

  return params
}

const applyTrackingParams = (href: string, gaClientId = '') => {
  let url: URL
  try {
    url = new URL(href)
  } catch {
    return href
  }

  if (url.host !== CHECKOUT_HOST) return href

  const params = getAttributionParams()
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value)
    url.searchParams.set(`checkout[custom][${key}]`, value)
  }

  if (gaClientId) {
    url.searchParams.set('checkout[custom][ga_client_id]', gaClientId)
  }

  return url.toString()
}

export const decorateCheckoutHref = async (href: string) => {
  if (typeof window === 'undefined' || typeof window.gtag !== 'function') {
    return applyTrackingParams(href)
  }

  return new Promise<string>((resolve) => {
    window.gtag?.('get', import.meta.env.VITE_PUBLIC_GA4_ID || 'G-0DWSJTXQ65', 'client_id', (clientId: string) => {
      resolve(applyTrackingParams(href, clientId))
    })
  })
}
