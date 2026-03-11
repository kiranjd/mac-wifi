import siteMetaConfig from '../seo/siteMeta.config.json'

export const SITE_BASE_URL = siteMetaConfig.siteBaseUrl as string

export const buildCanonicalUrl = (pathname: string) => {
  const normalized = pathname && pathname !== '/' ? (pathname.startsWith('/') ? pathname : `/${pathname}`) : '/'
  return `${SITE_BASE_URL}${normalized}`
}
