import { LEMON_SCRIPT_URL } from '../config/commerce'

declare global {
  interface Window {
    LemonSqueezy?: {
      Refresh?: () => void
      Setup?: (config: { eventHandler: (event: { event: string }) => void }) => void
      Url?: {
        Open?: (url: string) => void
        Close?: () => void
      }
    }
    createLemonSqueezy?: () => void
  }
}

const loadLemonOverlay = (successPath = '/download') => {
  if (typeof window === 'undefined') return Promise.resolve(() => {})

  const markReady = () => {
    window.createLemonSqueezy?.()
    window.LemonSqueezy?.Refresh?.()

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
    return Promise.resolve(() => {})
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
      return Promise.resolve(() => {})
    }

    return new Promise<() => void>((resolve) => {
      const onLoad = (event?: Event) => {
        handleLoad(event)
        resolve(() => existingScript.removeEventListener('load', onLoad))
      }

      existingScript.addEventListener('load', onLoad)
    })
  }

  const script = document.createElement('script')
  return new Promise<() => void>((resolve) => {
    const onLoad = (event?: Event) => {
      handleLoad(event)
      resolve(() => script.removeEventListener('load', onLoad))
    }

    script.src = LEMON_SCRIPT_URL
    script.defer = true
    script.addEventListener('load', onLoad)
    document.body.appendChild(script)
  })
}

export const initLemonOverlay = (successPath = '/download') => {
  if (typeof window === 'undefined') return () => {}
  let cleanup: (() => void) | undefined
  void loadLemonOverlay(successPath).then((dispose) => {
    cleanup = dispose
  })
  return () => cleanup?.()
}

export const openLemonCheckout = async (href: string, successPath = '/download') => {
  if (typeof window === 'undefined') return false

  await loadLemonOverlay(successPath)
  const open = window.LemonSqueezy?.Url?.Open

  if (typeof open === 'function') {
    open(href)
    return true
  }

  return false
}
