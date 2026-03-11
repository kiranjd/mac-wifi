import { LEMON_SCRIPT_URL } from '../config/commerce'

declare global {
  interface Window {
    LemonSqueezy?: {
      Refresh?: () => void
      Setup?: (config: { eventHandler: (event: { event: string }) => void }) => void
      Url?: {
        Close?: () => void
      }
    }
    createLemonSqueezy?: () => void
  }
}

export const initLemonOverlay = (successPath = '/download') => {
  if (typeof window === 'undefined') return () => {}

  const markReady = () => {
    window.createLemonSqueezy?.()

    window.LemonSqueezy?.Setup?.({
      eventHandler: (event) => {
        if (event.event !== 'Checkout.Success' && event.event !== 'Payment.Success') {
          return
        }

        window.LemonSqueezy?.Url?.Close?.()
        window.location.href = successPath + window.location.search
      },
    })
  }

  if (window.LemonSqueezy) {
    markReady()
    return () => {}
  }

  const handleLoad = (event?: Event) => {
    const target = event?.currentTarget as HTMLScriptElement | null
    if (target) {
      target.dataset.codexLemonLoaded = 'true'
    }
    markReady()
  }

  const existingScript = document.querySelector<HTMLScriptElement>(`script[src="${LEMON_SCRIPT_URL}"]`)

  if (existingScript) {
    if (window.LemonSqueezy || existingScript.dataset.codexLemonLoaded === 'true') {
      markReady()
      return () => {}
    }

    existingScript.addEventListener('load', handleLoad)
    return () => existingScript.removeEventListener('load', handleLoad)
  }

  const script = document.createElement('script')
  script.src = LEMON_SCRIPT_URL
  script.defer = true
  script.addEventListener('load', handleLoad)
  document.body.appendChild(script)

  return () => {
    script.removeEventListener('load', handleLoad)
  }
}
