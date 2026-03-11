import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'
import { blogPosts } from '../data/blogPosts'

const blogMeta = makeMeta({
  title: 'MacWiFi Blog | Connection quality on macOS',
  description:
    'Guides about Wi-Fi stability, packet loss, jitter, macOS troubleshooting, and how to tell whether the problem is your network or your ISP.',
  canonicalPath: '/blog',
})

export default function BlogIndexPage() {
  return (
    <>
      <SeoHead meta={blogMeta} />

      <main className="section-pad">
        <div className="shell blog-index">
          <div className="intro-block">
            <p className="section-label">Blog</p>
            <h1>Connection quality, explained plainly.</h1>
            <p>
              These are practical guides about unstable internet on macOS, what different signals
              mean, and how to decide whether the problem is local Wi-Fi or something beyond it.
            </p>
          </div>

          <div className="blog-list">
            {blogPosts.map((post) => (
              <article key={post.slug} className="blog-card">
                <h2>
                  <a href={`/blog/${post.slug}`}>{post.title}</a>
                </h2>
                <p>{post.description}</p>
                <a className="blog-link" href={`/blog/${post.slug}`}>
                  Read article
                </a>
              </article>
            ))}
          </div>
        </div>
      </main>
    </>
  )
}
