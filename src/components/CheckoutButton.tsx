import type { ReactNode } from 'react'
import { useEffect, useState } from 'react'
import { CHECKOUT_URL } from '../config/commerce'
import { decorateCheckoutHref } from '../lib/checkout'
import { openLemonCheckout } from '../lib/lemon'

type CheckoutButtonProps = {
  children: ReactNode
  className: string
  successPath?: string
}

export default function CheckoutButton({
  children,
  className,
  successPath = '/download',
}: CheckoutButtonProps) {
  const [checkoutHref, setCheckoutHref] = useState(CHECKOUT_URL)

  useEffect(() => {
    let cancelled = false

    decorateCheckoutHref(CHECKOUT_URL).then((href) => {
      if (!cancelled) {
        setCheckoutHref(href)
      }
    })

    return () => {
      cancelled = true
    }
  }, [])

  return (
    <a
      className={className}
      href={checkoutHref}
      onClick={async (event) => {
        event.preventDefault()
        const opened = await openLemonCheckout(checkoutHref, successPath)
        if (!opened) {
          window.location.href = checkoutHref
        }
      }}
    >
      {children}
    </a>
  )
}
