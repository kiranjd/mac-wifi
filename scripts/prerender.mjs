import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { build as esbuildBuild } from 'esbuild'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const rootDir = path.resolve(__dirname, '..')
const distDir = path.join(rootDir, 'dist')
const templatePath = path.join(distDir, 'index.html')

const ROUTES = ['/', '/pricing/', '/blog/', '/help/activate-license/', '/help/getting-started/', '/download/']

function resolveOutputPath(pathname) {
  if (pathname === '/') {
    return path.join(distDir, 'index.html')
  }

  return path.join(distDir, ...pathname.split('/').filter(Boolean), 'index.html')
}

function stripSeoTags(html) {
  return html
    .replace(/<title>[\s\S]*?<\/title>/i, '')
    .replace(/<meta[^>]+name="description"[^>]*>\s*/gi, '')
    .replace(/<meta[^>]+property="og:[^"]*"[^>]*>\s*/gi, '')
    .replace(/<meta[^>]+name="twitter:[^"]*"[^>]*>\s*/gi, '')
    .replace(/<link[^>]+rel="canonical"[^>]*>\s*/gi, '')
}

function injectHelmet(template, helmet) {
  const inserts = ['title', 'meta', 'link', 'script', 'noscript', 'style']
    .map((key) => helmet?.[key]?.toString?.())
    .filter(Boolean)

  return inserts.length === 0 ? template : template.replace('</head>', `${inserts.join('\n')}\n</head>`)
}

function injectAppHtml(template, appHtml) {
  return template.replace('<div id="root"></div>', `<div id="root">${appHtml}</div>`)
}

async function createRenderer() {
  const ssrDir = path.join(rootDir, '.prerender-ssr')
  const outfile = path.join(ssrDir, 'entry-prerender.cjs')

  await fs.rm(ssrDir, { recursive: true, force: true })

  await esbuildBuild({
    entryPoints: [path.join(rootDir, 'src', 'entry-prerender.tsx')],
    outfile,
    bundle: true,
    format: 'cjs',
    platform: 'node',
    target: ['node20'],
    logLevel: 'silent',
    absWorkingDir: rootDir,
    tsconfig: path.join(rootDir, 'tsconfig.json'),
    define: {
      'process.env.NODE_ENV': '"production"',
      'import.meta.env.DEV': 'false',
      'import.meta.env.PROD': 'true',
      'import.meta.env.SSR': 'true',
      'import.meta.env.VITE_PUBLIC_GA4_ID': JSON.stringify(process.env.VITE_PUBLIC_GA4_ID ?? ''),
    },
  })

  const mod = await import(pathToFileURL(outfile).href)
  return {
    render: mod.render,
    close: () => fs.rm(ssrDir, { recursive: true, force: true }),
  }
}

async function main() {
  const template = await fs.readFile(templatePath, 'utf8')
  const baseTemplate = stripSeoTags(template)
  const renderer = await createRenderer()

  try {
    for (const route of ROUTES) {
      const outputPath = resolveOutputPath(route)
      const { html, helmet } = await renderer.render(route)
      const withApp = injectAppHtml(baseTemplate, html)
      const finalHtml = injectHelmet(withApp, helmet)
      await fs.mkdir(path.dirname(outputPath), { recursive: true })
      await fs.writeFile(outputPath, finalHtml, 'utf8')
    }
  } finally {
    await renderer.close()
  }
}

main().catch((error) => {
  console.error('Prerender failed:', error)
  process.exitCode = 1
})
