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

updateHeaderState();
window.addEventListener("scroll", updateHeaderState, { passive: true });
