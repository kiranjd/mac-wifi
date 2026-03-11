import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const rootDir = path.resolve(__dirname, '..')
const websiteDir = path.join(rootDir, 'website')
const publicDir = path.join(rootDir, 'public')

async function copyIfExists(source, destination) {
  await fs.rm(destination, { recursive: true, force: true })
  await fs.mkdir(path.dirname(destination), { recursive: true })
  await fs.cp(source, destination, { recursive: true })
}

async function syncBlogFolders() {
  const sourceBlogDir = path.join(websiteDir, 'blog')
  const destinationBlogDir = path.join(publicDir, 'blog')

  await fs.rm(destinationBlogDir, { recursive: true, force: true })
  await fs.mkdir(destinationBlogDir, { recursive: true })

  const entries = await fs.readdir(sourceBlogDir, { withFileTypes: true })
  for (const entry of entries) {
    if (!entry.isDirectory()) continue

    const sourceDir = path.join(sourceBlogDir, entry.name)
    const indexPath = path.join(sourceDir, 'index.html')
    try {
      await fs.access(indexPath)
    } catch {
      continue
    }

    await copyIfExists(sourceDir, path.join(destinationBlogDir, entry.name))
  }
}

async function main() {
  await fs.mkdir(publicDir, { recursive: true })
  await copyIfExists(path.join(websiteDir, 'assets'), path.join(publicDir, 'assets'))
  await copyIfExists(path.join(websiteDir, 'blog.css'), path.join(publicDir, 'blog.css'))
  await copyIfExists(path.join(websiteDir, 'content.css'), path.join(publicDir, 'content.css'))
  await copyIfExists(path.join(websiteDir, 'styles.css'), path.join(publicDir, 'styles.css'))
  await copyIfExists(path.join(websiteDir, 'main.js'), path.join(publicDir, 'main.js'))
  await syncBlogFolders()
}

main().catch((error) => {
  console.error('Failed to sync static files:', error)
  process.exitCode = 1
})
