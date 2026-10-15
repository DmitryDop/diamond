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

// V2 tuning: cursor x/y are FULL edge-to-edge travel in CSS pixels.
// Camera x/y are end-of-scroll offsets; scale is the final uniform scale.
const HERO_MOTION = {
  cursor: { inertiaSeconds: .8, referenceWidth: 1440, minViewportFactor: .85 },
  camera: {
    inertiaSeconds: .2,
    pinViewport: .9,
    desktopMinWidth: 1101,
    pinMinHeight: 812,
    mobileStrength: .4,
    mobileEntryViewport: .7,
    mobileTravelViewport: .5
  },
  appearance: { durationMs: 1600, startOpacity: .35 },
  layers: {
    backgroundSmoke: { cursor: { x: 20, y: 16 }, camera: { x: 6, y: -6, scale: 1.025 }, origin: [.65, .6], air: { period: 27.3, x: 4, y: 2, phase: 0, opacity: .985 } },
    centralRock: { cursor: { x: 45, y: 36 }, camera: { x: -14, y: -26, scale: 1.1 }, origin: [.58, .62] },
    foregroundSmoke: { cursor: { x: 65, y: 52 }, camera: { x: -28, y: -48, scale: 1.13 }, origin: [.35, .42], air: { period: 19.7, x: 7, y: 3.5, phase: 1.4, opacity: .97 } },
    foregroundRock: { cursor: { x: 120, y: 100 }, camera: { x: -64, y: -100, scale: 1.22 }, origin: [.25, .35] }
  }
};

const hero = document.querySelector(".hero");
const heroScene = hero?.querySelector("[data-hero-scene]");
if (heroScene) {
  const track = hero.closest("[data-hero-track]");
  const stage = heroScene.closest(".hero-art");
  const layers = [...heroScene.querySelectorAll("[data-hero-layer]")].map((node) => {
    const config = HERO_MOTION.layers[node.dataset.heroLayer];
    node.style.transformOrigin = `${config.origin[0] * 100}% ${config.origin[1] * 100}%`;
    return { node, config, smoke: node.querySelector(".hero-smoke"), width: 1, height: 1, rightReserve: 0, bottomReserve: 0, airX: 0, airY: 0 };
  });
  const finePointer = window.matchMedia("(hover: hover) and (pointer: fine) and (min-width: 851px)");
  const desktop = window.matchMedia(`(min-width: ${HERO_MOTION.camera.desktopMinWidth}px)`);
  const pinViewport = window.matchMedia(`(min-width: ${HERO_MOTION.camera.desktopMinWidth}px) and (min-height: ${HERO_MOTION.camera.pinMinHeight}px)`);
  let frame = 0, lastTime = 0, airTime = 0, arrival;
  let ready = false, visible = true, appeared = false, pinned = false;
  let geometryDirty = true, boundsDirty = true;
  let bounds = hero.getBoundingClientRect();
  let cameraStart = 0, cameraDistance = 1, cameraProgress = 0;
  let targetX = 0, targetY = 0, x = 0, y = 0;
  let cursorFactor = 1, cameraFactor = 1, mobile = false;
  const resetPointer = () => { targetX = targetY = 0; };
  const clamp = (value, low = 0, high = 1) => Math.max(low, Math.min(high, value));
  const targetCamera = () => clamp((window.scrollY - cameraStart) / cameraDistance);

  const measure = () => {
    mobile = !desktop.matches;
    pinned = pinViewport.matches && !motionPreference.matches && !heroScene.hidden && HERO_MOTION.camera.pinViewport > 0;
    const pinDistance = window.innerHeight * HERO_MOTION.camera.pinViewport;
    track.style.setProperty("--hero-rest-height", `${hero.offsetHeight}px`);
    track.style.setProperty("--hero-pin-distance", `${pinDistance}px`);
    track.toggleAttribute("data-hero-pin", pinned);
    bounds = hero.getBoundingClientRect();
    const stageBox = stage.getBoundingClientRect();
    const sceneBox = heroScene.getBoundingClientRect();
    const headerHeight = document.querySelector(".site-header")?.offsetHeight || 0;
    const viewportFactor = Math.min(1, stageBox.width / HERO_MOTION.cursor.referenceWidth);
    cursorFactor = Math.max(HERO_MOTION.cursor.minViewportFactor, viewportFactor);
    cameraFactor = viewportFactor * (mobile ? HERO_MOTION.camera.mobileStrength : 1);
    cameraStart = pinned ? track.getBoundingClientRect().top + window.scrollY - headerHeight
      : Math.max(0, stageBox.top + window.scrollY - (mobile ? window.innerHeight * HERO_MOTION.camera.mobileEntryViewport : headerHeight));
    cameraDistance = pinned ? pinDistance : mobile ? stageBox.height + window.innerHeight * HERO_MOTION.camera.mobileTravelViewport : pinDistance;
    cameraDistance = Math.max(1, cameraDistance);
    layers.forEach((layer) => {
      // Layout offsets ignore the currently animated layer transform.
      const layout = getComputedStyle(layer.node);
      layer.width = parseFloat(layout.width);
      layer.height = parseFloat(layout.height);
      layer.rightReserve = sceneBox.left + parseFloat(layout.left) + layer.width - stageBox.right;
      layer.bottomReserve = sceneBox.top + parseFloat(layout.top) + layer.height - stageBox.bottom;
    });
    geometryDirty = boundsDirty = false;
  };

  const paint = () => {
    const calm = finePointer.matches ? 1 : .4;
    const airFactor = Math.min(1, stage.clientWidth / 1440) * calm;
    layers.forEach((layer) => {
      const { config, node, smoke } = layer;
      if (smoke) {
        const { air } = config;
        const angle = airTime * 2 * Math.PI / air.period + air.phase;
        layer.airX = (Math.sin(angle) - Math.sin(air.phase)) * air.x * airFactor;
        layer.airY = (Math.cos(angle) - Math.cos(air.phase)) * air.y * airFactor;
        smoke.style.transform = `translate3d(${layer.airX.toFixed(3)}px,${layer.airY.toFixed(3)}px,0)`;
        smoke.style.opacity = String(air.opacity + (1 - air.opacity) * Math.cos(angle * .73));
      }
      const tx = x * config.cursor.x * cursorFactor / 2 + config.camera.x * cameraProgress * cameraFactor;
      const ty = y * config.cursor.y * cursorFactor / 2 + config.camera.y * cameraProgress * cameraFactor;
      const cameraScale = 1 + (config.camera.scale - 1) * cameraProgress * (mobile ? HERO_MOTION.camera.mobileStrength : 1);
      // Create crop reserve by uniform scaling, rather than weakening movement.
      // At rest this is exactly 1. Only the PNG's cut right/bottom edges need
      // protection: top/left contours are transparent (smoke already feathered).
      // Smoke's original feathered mask handles its independent air drift.
      const coverX = 1 + Math.max(0, -layer.rightReserve - tx - .1) / Math.max(1, layer.width * (1 - config.origin[0]));
      const coverY = 1 + Math.max(0, -layer.bottomReserve - ty - .1) / Math.max(1, layer.height * (1 - config.origin[1]));
      const scale = Math.max(cameraScale, coverX, coverY);
      node.style.transform = `translate3d(${tx.toFixed(3)}px,${ty.toFixed(3)}px,0) scale(${scale.toFixed(6)})`;
    });
  };

  const draw = (time) => {
    const dt = lastTime ? Math.min((time - lastTime) / 1000, .05) : 0;
    lastTime = time;
    if (geometryDirty) measure();
    else if (boundsDirty) { bounds = hero.getBoundingClientRect(); boundsDirty = false; }
    airTime += dt;
    const pointerEase = 1 - Math.exp(-dt / HERO_MOTION.cursor.inertiaSeconds);
    x += (targetX - x) * pointerEase;
    y += (targetY - y) * pointerEase;
    if (Math.abs(targetX - x) < .00001) x = targetX;
    if (Math.abs(targetY - y) < .00001) y = targetY;
    cameraProgress += (targetCamera() - cameraProgress) * (1 - Math.exp(-dt / HERO_MOTION.camera.inertiaSeconds));
    if (Math.abs(targetCamera() - cameraProgress) < .00001) cameraProgress = targetCamera();
    paint();
    frame = requestAnimationFrame(draw);
  };

  const sync = () => {
    if (geometryDirty) measure();
    const active = ready && visible && !document.hidden && !motionPreference.matches && !heroScene.hidden;
    stage.toggleAttribute("data-motion-active", active);
    if (!active) {
      cancelAnimationFrame(frame); frame = 0; lastTime = 0;
      resetPointer(); x = y = 0;
      arrival?.cancel();
      if (motionPreference.matches || !ready || heroScene.hidden) {
        cameraProgress = 0;
        layers.forEach(({ node, smoke }) => {
          node.style.transform = "";
          if (smoke) { smoke.style.transform = ""; smoke.style.opacity = ""; }
        });
      } else { cameraProgress = targetCamera(); paint(); }
      return;
    }
    if (!appeared) {
      appeared = true;
      if (heroScene.animate) arrival = heroScene.animate([
        { opacity: HERO_MOTION.appearance.startOpacity }, { opacity: 1 }
      ], { duration: HERO_MOTION.appearance.durationMs, easing: "cubic-bezier(.2,.65,.3,1)" });
    }
    if (!frame) { cameraProgress = targetCamera(); frame = requestAnimationFrame(draw); }
  };
  const refresh = () => { geometryDirty = true; resetPointer(); sync(); };

  hero.addEventListener("pointermove", (event) => {
    if (!finePointer.matches || event.pointerType !== "mouse" || motionPreference.matches) return;
    targetX = clamp((event.clientX - bounds.left) / bounds.width * 2 - 1, -1, 1);
    targetY = clamp((event.clientY - bounds.top) / bounds.height * 2 - 1, -1, 1);
  }, { passive: true });
  hero.addEventListener("pointerleave", resetPointer);
  window.addEventListener("blur", resetPointer);
  window.addEventListener("resize", refresh, { passive: true });
  window.addEventListener("scroll", () => { boundsDirty = true; }, { passive: true });
  document.addEventListener("visibilitychange", sync);
  motionPreference.addEventListener("change", refresh);
  desktop.addEventListener("change", refresh);
  pinViewport.addEventListener("change", refresh);
  finePointer.addEventListener("change", refresh);
  if ("ResizeObserver" in window) {
    const observer = new ResizeObserver(() => { geometryDirty = true; });
    observer.observe(hero); observer.observe(stage);
  }
  if ("IntersectionObserver" in window) {
    new IntersectionObserver((entries) => { visible = entries[0].isIntersecting; sync(); }).observe(stage);
  }
  Promise.all([...heroScene.querySelectorAll("img")].map((image) => image.decode()))
    .then(() => { ready = true; geometryDirty = true; sync(); })
    .catch(() => { track.removeAttribute("data-hero-pin"); });
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
