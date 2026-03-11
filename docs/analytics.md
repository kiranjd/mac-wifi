# MacWiFi Analytics

This is the event contract for the public website and the macOS app.

## Website

| Event | Trigger | Parameters |
| --- | --- | --- |
| `page_view` | Every page load after GA4 is ready | `page_title`, `page_location`, `page_path` |
| `checkout_click` | Any Lemon Squeezy checkout CTA | `location`, `path` |
| `blog_index_view` | `/blog` page load | `page_path` |
| `blog_post_view` | Any `/blog/{slug}` article load | `article_slug`, `page_path` |
| `blog_link_click` | Click from any page to a blog article | `article_slug`, `location` |

Checkout links also forward attribution context into Lemon custom fields:

- `utm_source`
- `utm_medium`
- `utm_campaign`
- `utm_term`
- `utm_content`
- `gclid`
- `fbclid`
- `msclkid`
- `ttclid`
- `landing_path`
- `referrer_host`
- `ga_client_id`

## App

| Event | Trigger | Parameters |
| --- | --- | --- |
| `app_install_anonymous` | First successful anonymous install ping | Base app parameters |
| `checkout_initiated` | In-app buy CTA | `surface` |

Base app parameters:

- `platform`
- `engagement_time_msec`
- `site_domain`
- `app_version`
- `build_number`
- `os_version`

User property:

- `install_id`

## Notes

- Website GA4 uses the `kiranjd8@gmail.com` MacWiFi property once the production measurement ID is set in `website/main.js`.
- App GA4 Measurement Protocol uses the production measurement ID and API secret in [AnalyticsConfiguration.swift](/Users/jd/things/mac-wifi/Sources/MacWiFi/Config/AnalyticsConfiguration.swift).
- Lemon Squeezy checkout carries attribution from both the site and app through `checkout[custom][...]`.
