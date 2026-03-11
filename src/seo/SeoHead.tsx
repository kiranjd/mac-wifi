import type { ReactNode } from 'react'
import { Helmet } from 'react-helmet-async'
import { buildCanonicalUrl } from '../config/site'
import type { SeoMeta } from './siteMeta'

type SeoHeadProps = {
  meta: SeoMeta
  children?: ReactNode
}

export function SeoHead({ meta, children }: SeoHeadProps) {
  const canonicalUrl = buildCanonicalUrl(meta.canonicalPath)

  return (
    <Helmet>
      <title>{meta.title}</title>
      {meta.description ? <meta name="description" content={meta.description} /> : null}
      <link rel="canonical" href={canonicalUrl} />
      <meta property="og:title" content={meta.title} />
      {meta.siteName ? <meta property="og:site_name" content={meta.siteName} /> : null}
      {meta.description ? <meta property="og:description" content={meta.description} /> : null}
      <meta property="og:type" content={meta.openGraphType ?? 'website'} />
      <meta property="og:url" content={canonicalUrl} />
      {meta.socialImage ? <meta property="og:image" content={meta.socialImage} /> : null}
      {meta.socialAlt ? <meta property="og:image:alt" content={meta.socialAlt} /> : null}
      <meta name="twitter:card" content={meta.twitterCard ?? 'summary_large_image'} />
      <meta name="twitter:title" content={meta.title} />
      {meta.description ? <meta name="twitter:description" content={meta.description} /> : null}
      {meta.socialImage ? <meta name="twitter:image" content={meta.socialImage} /> : null}
      {meta.socialAlt ? <meta name="twitter:image:alt" content={meta.socialAlt} /> : null}
      <meta name="robots" content={meta.noIndex ? 'noindex, nofollow' : 'index, follow'} />
      {children}
    </Helmet>
  )
}
