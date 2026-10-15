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
    stage.querySelector("[data-hero-scene]")?.setAttribute("hidden", "");
    stage.querySelectorAll(".scene-smoke").forEach((layer) => { layer.hidden = true; });
    stage.querySelector(".image-fallback").hidden = false;
  };
  image.addEventListener("error", showFallback, { once: true });
  if (image.complete && image.naturalWidth === 0) showFallback();
});

// One restrained arrival of the editorial scene; the default state stays visible.
const impactScene = document.querySelector(".scene-impact");
const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");

// Pointer and scroll offsets compose on each layer; air has its own nested transform.
const hero = document.querySelector(".hero");
const heroScene = hero?.querySelector("[data-hero-scene]");
if (heroScene) {
  const stage = heroScene.closest(".hero-art");
  const layers = [...heroScene.querySelectorAll("[data-hero-depth]")];
  const finePointer = window.matchMedia("(hover: hover) and (pointer: fine) and (min-width: 851px)");
  const animations = [];
  let frame = 0, lastTime = 0, airTime = 0, pointerTime = -Infinity;
  let visible = true, ready = false, appeared = false;
  let targetX = 0, targetY = 0, x = 0, y = 0;
  let bounds = hero.getBoundingClientRect();
  let geometryDirty = true, boundsDirty = true;
  let scrollStart = 0, scrollDistance = 1, scrollProgress = 0;
  let scrollDepths = [0, 0, 0, 0];
  const measureScroll = () => {
    bounds = hero.getBoundingClientRect();
    const stageBounds = stage.getBoundingClientRect();
    const sceneBounds = heroScene.getBoundingClientRect();
    scrollStart = bounds.top + window.scrollY;
    scrollDistance = Math.max(1, bounds.height);
    const scale = Math.min(1, stageBounds.width / 1440);
    const strength = scale * (finePointer.matches ? 1 : .35);
    // Use the existing crop reserve and only the very end of its existing fade.
    // Leave room for pointer and air motion; never reveal a hard PNG bottom edge.
    const reserve = Math.max(0, sceneBounds.bottom - stageBounds.bottom + stageBounds.height * .025
      - (finePointer.matches ? 18 : 7) * scale);
    const fit = strength ? Math.min(1, reserve / (110 * strength)) : 0;
    scrollDepths = [32, 52, 74, 110].map((depth) => depth * strength * fit);
    geometryDirty = boundsDirty = false;
  };
  const targetScroll = () => Math.max(0, Math.min(1, (window.scrollY - scrollStart) / scrollDistance));
  const resetPointer = () => { targetX = targetY = 0; pointerTime = -Infinity; };
  const draw = (time) => {
    const dt = lastTime ? Math.min((time - lastTime) / 1000, .05) : 0;
    lastTime = time;
    airTime += dt;
    if (geometryDirty) measureScroll();
    else if (boundsDirty) { bounds = hero.getBoundingClientRect(); boundsDirty = false; }
    scrollProgress += (targetScroll() - scrollProgress) * (1 - Math.exp(-dt / .18));
    if (Math.abs(targetScroll() - scrollProgress) < .00001) scrollProgress = targetScroll();
    if (time - pointerTime > 160) targetX = targetY = 0;
    const ease = 1 - Math.exp(-dt / .65);
    x += (targetX - x) * ease;
    y += (targetY - y) * ease;
    const calm = finePointer.matches ? 1 : .4;
    const scale = Math.min(1, stage.clientWidth / 1440);
    layers.forEach((layer, index) => {
      const depth = Number(layer.dataset.heroDepth) * scale;
      layer.style.transform = `translate3d(${(x * depth).toFixed(3)}px,${(y * depth * .6 - scrollProgress * scrollDepths[index]).toFixed(3)}px,0)`;
    });
    // Elliptical paths have continuous velocity; differing periods and phases
    // prevent the two air planes from turning together or repeating as a pair.
    [ [".hero-layer-back-smoke", 27.3, 4, 2, 0, .985],
      [".hero-layer-front-smoke", 19.7, 7, 3.5, 1.4, .97] ].forEach(([selector, period, ax, ay, phase, opacity]) => {
      const smoke = heroScene.querySelector(`${selector} img`);
      const angle = airTime * 2 * Math.PI / period + phase;
      const driftX = (Math.sin(angle) - Math.sin(phase)) * ax * calm * scale;
      const driftY = (Math.cos(angle) - Math.cos(phase)) * ay * calm * scale;
      smoke.style.transform = `translate3d(${driftX.toFixed(3)}px,${driftY.toFixed(3)}px,0)`;
      smoke.style.opacity = String(opacity + (1 - opacity) * Math.cos(angle * .73));
    });
    frame = requestAnimationFrame(draw);
  };
  const sync = () => {
    const active = ready && visible && !document.hidden && !motionPreference.matches && !heroScene.hidden;
    stage.toggleAttribute("data-motion-active", active);
    if (!active) {
      cancelAnimationFrame(frame); frame = 0; lastTime = 0;
      animations.forEach((animation) => animation.cancel());
      resetPointer(); x = y = 0;
      if (geometryDirty) measureScroll();
      scrollProgress = motionPreference.matches ? 0 : targetScroll();
      layers.forEach((layer, index) => {
        layer.style.transform = motionPreference.matches ? "" : `translate3d(0,${(-scrollProgress * scrollDepths[index]).toFixed(3)}px,0)`;
      });
      heroScene.querySelectorAll(".hero-smoke").forEach((smoke) => { smoke.style.transform = ""; smoke.style.opacity = ""; });
      return;
    }
    if (!appeared) {
      appeared = true;
      if (heroScene.animate) animations.push(heroScene.animate([
        { opacity: .35 }, { opacity: 1 }
      ], { duration: 1600, easing: "cubic-bezier(.2,.65,.3,1)" }));
    }
    if (!frame) {
      if (geometryDirty) measureScroll();
      scrollProgress = targetScroll();
      frame = requestAnimationFrame(draw);
    }
  };
  hero.addEventListener("pointermove", (event) => {
    if (!finePointer.matches || event.pointerType !== "mouse" || motionPreference.matches) return;
    targetX = Math.max(-1, Math.min(1, (event.clientX - bounds.left) / bounds.width * 2 - 1));
    targetY = Math.max(-1, Math.min(1, (event.clientY - bounds.top) / bounds.height * 2 - 1));
    pointerTime = performance.now();
  }, { passive: true });
  hero.addEventListener("pointerleave", resetPointer);
  window.addEventListener("blur", resetPointer);
  window.addEventListener("resize", () => { geometryDirty = true; resetPointer(); }, { passive: true });
  window.addEventListener("scroll", () => { boundsDirty = true; }, { passive: true });
  document.addEventListener("visibilitychange", sync);
  motionPreference.addEventListener("change", sync);
  finePointer.addEventListener("change", () => { geometryDirty = true; resetPointer(); });
  if ("ResizeObserver" in window) {
    const geometryObserver = new ResizeObserver(() => { geometryDirty = true; });
    geometryObserver.observe(hero);
    geometryObserver.observe(stage);
  }
  if ("IntersectionObserver" in window) {
    new IntersectionObserver((entries) => { visible = entries[0].isIntersecting; sync(); }).observe(stage);
  }
  Promise.all([...heroScene.querySelectorAll("img")].map((image) => image.decode()))
    .then(() => { ready = true; bounds = hero.getBoundingClientRect(); sync(); })
    .catch(() => { /* Keep the static layers or the existing product fallback. */ });
}

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
