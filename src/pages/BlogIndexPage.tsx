import { SeoHead } from '../seo/SeoHead'
import { makeMeta } from '../seo/siteMeta'
import { blogPosts } from '../data/blogPosts'
import { card, eyebrow, lead, section, sectionTitle, shell } from '../lib/ui'

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

      <main className={section}>
        <div className={shell}>
          <div className="max-w-3xl">
            <p className={eyebrow}>Blog</p>
            <h1 className={sectionTitle}>Connection quality, explained plainly.</h1>
            <p className={`${lead} mt-5 max-w-2xl`}>
              These are practical guides about unstable internet on macOS, what different signals
              mean, and how to decide whether the problem is local Wi-Fi or something beyond it.
            </p>
          </div>

          <div className="mt-10 grid gap-4 lg:grid-cols-2">
            {blogPosts.map((post) => (
              <article key={post.slug} className={`${card} p-7`}>
                <h2 className="text-[1.7rem] font-semibold leading-[1.02] tracking-[-0.05em] text-slate-950">
                  <a href={`/blog/${post.slug}`}>{post.title}</a>
                </h2>
                <p className="mt-4 text-base leading-7 text-slate-700">{post.description}</p>
                <a
                  className="mt-6 inline-flex text-sm font-semibold text-[#0f766e] transition hover:text-[#0b5f59]"
                  href={`/blog/${post.slug}`}
                >
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
