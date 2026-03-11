import siteMetaConfig from './siteMeta.config.json'

export type SeoMeta = {
  title: string
  description?: string
  canonicalPath: string
  socialImage?: string
  socialAlt?: string
  siteName?: string
  twitterCard?: string
  openGraphType?: 'website' | 'article' | (string & {})
  noIndex?: boolean
}

const normalizeMeta = (meta: Partial<SeoMeta>): SeoMeta => ({
  title: meta.title ?? siteMetaConfig.title,
  description: meta.description ?? siteMetaConfig.description,
  canonicalPath: meta.canonicalPath ?? siteMetaConfig.canonicalPath,
  socialImage: meta.socialImage ?? siteMetaConfig.socialImage,
  socialAlt: meta.socialAlt ?? siteMetaConfig.socialAlt,
  siteName: meta.siteName ?? 'MacWiFi',
  twitterCard: meta.twitterCard ?? siteMetaConfig.twitterCard,
  openGraphType: meta.openGraphType ?? 'website',
  noIndex: meta.noIndex ?? false,
})

export const baseMeta = normalizeMeta({})

export const makeMeta = (overrides: Partial<SeoMeta> = {}) => normalizeMeta(overrides)
