import fs from 'node:fs'
import path from 'node:path'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

const staticBlogPlugin = () => {
  const rootDir = process.cwd()
  const websiteDir = path.join(rootDir, 'website')
  const contentTypes: Record<string, string> = {
    '.css': 'text/css; charset=utf-8',
    '.html': 'text/html; charset=utf-8',
    '.ico': 'image/x-icon',
    '.jpg': 'image/jpeg',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.txt': 'text/plain; charset=utf-8',
    '.webp': 'image/webp',
  }

  const sendFile = (
    filePath: string,
    res: { setHeader: (name: string, value: string) => void; end: (body: Buffer | string) => void },
  ) => {
    const ext = path.extname(filePath)
    res.setHeader('Content-Type', contentTypes[ext] || 'application/octet-stream')
    res.end(fs.readFileSync(filePath))
  }

  return {
    name: 'static-blog-dev-routes',
    configureServer(server: { middlewares: { use: (handler: (req: { url?: string }, res: { setHeader: (name: string, value: string) => void; end: (body: string) => void }, next: () => void) => void) => void } }) {
      server.middlewares.use((req, res, next) => {
        const rawUrl = req.url
        if (!rawUrl) {
          next()
          return
        }

        const pathname = rawUrl.split('?')[0]
        const directStaticPaths = new Map<string, string>([
          ['/styles.css', path.join(websiteDir, 'styles.css')],
          ['/content.css', path.join(websiteDir, 'content.css')],
          ['/blog.css', path.join(websiteDir, 'blog.css')],
          ['/main.js', path.join(websiteDir, 'main.js')],
          ['/robots.txt', path.join(websiteDir, 'robots.txt')],
        ])

        const directStaticMatch = directStaticPaths.get(pathname)
        if (directStaticMatch && fs.existsSync(directStaticMatch)) {
          sendFile(directStaticMatch, res)
          return
        }

        if (pathname.startsWith('/assets/')) {
          const assetPath = path.join(websiteDir, pathname.replace(/^\/+/, ''))
          if (fs.existsSync(assetPath) && fs.statSync(assetPath).isFile()) {
            sendFile(assetPath, res)
            return
          }
        }

        if (pathname === '/blog' || pathname === '/blog/') {
          const blogIndexPath = path.join(websiteDir, 'blog', 'index.html')
          if (fs.existsSync(blogIndexPath)) {
            sendFile(blogIndexPath, res)
            return
          }
        }

        if (!pathname.startsWith('/blog/')) {
          next()
          return
        }

        const normalized = pathname.endsWith('/') ? pathname.slice(0, -1) : pathname
        const relativePath = normalized.replace(/^\/+/, '')
        const exactFilePath = path.join(websiteDir, `${relativePath}.html`)
        const nestedIndexPath = path.join(websiteDir, relativePath, 'index.html')
        const matchedFilePath = fs.existsSync(nestedIndexPath)
          ? nestedIndexPath
          : fs.existsSync(exactFilePath)
            ? exactFilePath
            : null

        if (!matchedFilePath) {
          next()
          return
        }

        sendFile(matchedFilePath, res)
      })
    },
  }
}

export default defineConfig({
  plugins: [react(), tailwindcss(), staticBlogPlugin()],
})
