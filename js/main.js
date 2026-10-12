"use strict";

// Native <details> navigation and all links remain usable without JavaScript.
const mobileMenu = document.querySelector(".mobile-menu");

if (mobileMenu) {
  mobileMenu.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => { mobileMenu.open = false; });
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && mobileMenu.open) {
      mobileMenu.open = false;
      mobileMenu.querySelector("summary").focus();
    }
  });

  document.addEventListener("click", (event) => {
    if (!mobileMenu.contains(event.target)) mobileMenu.open = false;
  });

  window.matchMedia("(min-width: 851px)").addEventListener("change", (event) => {
    if (event.matches) mobileMenu.open = false;
  });
}

// Keep an honest text fallback if the approved product asset cannot load.
document.querySelectorAll("[data-product-image]").forEach((image) => {
  const showFallback = () => {
    const stage = image.closest("[data-product-stage]");
    image.hidden = true;
    stage.querySelectorAll(".scene-smoke").forEach((layer) => { layer.hidden = true; });
    stage.querySelector(".image-fallback").hidden = false;
  };
  image.addEventListener("error", showFallback, { once: true });
  if (image.complete && image.naturalWidth === 0) showFallback();
});

// One restrained arrival of the editorial scene; the default state stays visible.
const impactScene = document.querySelector(".scene-impact");
const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");

if (impactScene && "IntersectionObserver" in window) {
  let impactAnimation;
  const observer = new IntersectionObserver((entries) => {
    if (!entries.some((entry) => entry.isIntersecting)) return;
    observer.disconnect();
    const image = impactScene.querySelector(".impact-image");
    const animationTarget = impactScene.querySelector(".impact-layer-group") || image;
    if (motionPreference.matches || image.hidden || !image.animate) return;
    impactAnimation = animationTarget.animate([
      { transform: "scale(1.025)", opacity: .78 },
      { transform: "scale(1)", opacity: 1 }
    ], { duration: 1100, easing: "cubic-bezier(.2,.65,.3,1)" });
  }, { threshold: .25 });
  observer.observe(impactScene);
  motionPreference.addEventListener("change", (event) => {
    if (event.matches) impactAnimation?.cancel();
  });
}
