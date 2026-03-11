const SITE_CONFIG = {
  gaMeasurementId: "G-0DWSJTXQ65",
  checkoutHost: "kiranjd8.lemonsqueezy.com",
};

const observer = new IntersectionObserver(
  (entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      }
    }
  },
  {
    threshold: 0.16,
    rootMargin: "0px 0px -32px 0px",
  },
);

document.querySelectorAll(".reveal").forEach((node) => observer.observe(node));

const header = document.querySelector("[data-header]");

const updateHeaderState = () => {
  if (!header) return;
  header.classList.toggle("is-scrolled", window.scrollY > 10);
};

const trackEvent = (name, params = {}) => {
  if (typeof window.gtag !== "function") return;
  window.gtag("event", name, params);
};

const getPageContext = () => {
  const path = window.location.pathname.replace(/\/+$/, "") || "/";
  const isBlogIndex = path === "/blog";
  const isBlogPost = path.startsWith("/blog/") && path !== "/blog";
  const pageType = isBlogIndex ? "blog_index" : isBlogPost ? "blog_post" : "site";
  const slug = isBlogPost ? path.slice("/blog/".length) : "";

  return {
    path,
    pageType,
    pageSlug: slug,
  };
};

const getAttributionParams = () => {
  const search = new URLSearchParams(window.location.search);
  const params = {
    utm_source: search.get("utm_source"),
    utm_medium: search.get("utm_medium"),
    utm_campaign: search.get("utm_campaign"),
    utm_term: search.get("utm_term"),
    utm_content: search.get("utm_content"),
    gclid: search.get("gclid"),
    fbclid: search.get("fbclid"),
    msclkid: search.get("msclkid"),
    ttclid: search.get("ttclid"),
    landing_path: window.location.pathname,
    referrer_host: "",
  };

  if (document.referrer) {
    try {
      params.referrer_host = new URL(document.referrer).host;
    } catch {
      params.referrer_host = "";
    }
  }

  return params;
};

const decorateCheckoutLinks = (gaClientId = "") => {
  const attribution = getAttributionParams();
  const links = document.querySelectorAll('a[href*="lemonsqueezy.com/checkout/buy/"]');

  for (const link of links) {
    let url;
    try {
      url = new URL(link.href);
    } catch {
      continue;
    }

    if (url.host !== SITE_CONFIG.checkoutHost) continue;

    for (const [key, value] of Object.entries(attribution)) {
      if (!value) continue;
      url.searchParams.set(key, value);
      url.searchParams.set(`checkout[custom][${key}]`, value);
    }

    if (gaClientId) {
      url.searchParams.set("checkout[custom][ga_client_id]", gaClientId);
    }

    link.href = url.toString();
  }
};

const ensureGA4Bootstrap = async () => {
  if (!SITE_CONFIG.gaMeasurementId) return false;

  window.dataLayer = window.dataLayer || [];
  window.gtag =
    window.gtag ||
    function gtag() {
      window.dataLayer.push(arguments);
    };

  if (!window.__macwifiGAConfigured) {
    const hasScript = document.querySelector(
      `script[src="https://www.googletagmanager.com/gtag/js?id=${SITE_CONFIG.gaMeasurementId}"]`,
    );

    if (!hasScript) {
      await new Promise((resolve, reject) => {
        const script = document.createElement("script");
        script.async = true;
        script.src = `https://www.googletagmanager.com/gtag/js?id=${SITE_CONFIG.gaMeasurementId}`;
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
      }).catch(() => undefined);
    }

    window.gtag("js", new Date());
    window.gtag("config", SITE_CONFIG.gaMeasurementId, {
      anonymize_ip: true,
      send_page_view: false,
    });
    window.__macwifiGAConfigured = true;
  }

  return typeof window.gtag === "function";
};

const loadGA4 = async () => {
  const ready = await ensureGA4Bootstrap();
  if (!ready) return;

  trackEvent("page_view", {
    page_title: document.title,
    page_location: window.location.href,
    page_path: window.location.pathname,
  });

  const pageContext = getPageContext();
  if (pageContext.pageType === "blog_index") {
    trackEvent("blog_index_view", {
      page_path: pageContext.path,
    });
  }

  if (pageContext.pageType === "blog_post") {
    trackEvent("blog_post_view", {
      article_slug: pageContext.pageSlug,
      page_path: pageContext.path,
    });
  }

  window.gtag("get", SITE_CONFIG.gaMeasurementId, "client_id", (clientId) => {
    decorateCheckoutLinks(clientId);
  });
};

const bindEvents = () => {
  const checkoutLinks = document.querySelectorAll('a[href*="lemonsqueezy.com/checkout/buy/"]');
  for (const link of checkoutLinks) {
    link.addEventListener("click", () => {
      trackEvent("checkout_click", {
        location: link.dataset.ctaLocation || "site",
        path: window.location.pathname,
      });
    });
  }

  const trackedLinks = document.querySelectorAll("[data-track-event]");
  for (const node of trackedLinks) {
    node.addEventListener("click", () => {
      trackEvent(node.dataset.trackEvent, {
        location: node.dataset.trackLocation || window.location.pathname,
      });
    });
  }

  const blogLinks = document.querySelectorAll('a[href^="/blog/"]:not([href="/blog/"])');
  for (const link of blogLinks) {
    link.addEventListener("click", () => {
      const slug = (link.getAttribute("href") || "").replace(/^\/blog\//, "").replace(/\/$/, "");
      trackEvent("blog_link_click", {
        article_slug: slug,
        location: link.dataset.trackLocation || window.location.pathname,
      });
    });
  }
};

updateHeaderState();
window.addEventListener("scroll", updateHeaderState, { passive: true });
decorateCheckoutLinks();
bindEvents();
loadGA4();
