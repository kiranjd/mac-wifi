import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const rootDir = path.resolve(__dirname, '..')
const websiteBlogDir = path.join(rootDir, 'website', 'blog')
const publicDir = path.join(rootDir, 'public')
const sitemapPath = path.join(publicDir, 'sitemap.xml')

const BASE_URL = 'https://macwifi.live'
const TODAY = new Date().toISOString().slice(0, 10)

const STATIC_ROUTES = [
  '/',
  '/pricing',
  '/blog',
  '/download',
  '/help/getting-started',
  '/help/activate-license',
]

async function loadBlogRoutes() {
  const entries = await fs.readdir(websiteBlogDir, { withFileTypes: true })
  return entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => `/blog/${entry.name}`)
    .sort()
}

async function main() {
  const blogRoutes = await loadBlogRoutes()
  const routes = [...STATIC_ROUTES, ...blogRoutes]
  const body = routes
    .map((route) => `  <url>\n    <loc>${BASE_URL}${route}</loc>\n    <lastmod>${TODAY}</lastmod>\n  </url>`)
    .join('\n')

  await fs.mkdir(publicDir, { recursive: true })
  await fs.writeFile(
    sitemapPath,
    `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${body}\n</urlset>\n`,
    'utf8',
  )
}

main().catch((error) => {
  console.error('Failed to generate sitemap:', error)
  process.exitCode = 1
})
