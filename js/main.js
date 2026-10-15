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

// Editorial impact scene and shared motion preference.
const impactScene = document.querySelector(".scene-impact");
const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");

// V3 tuning: cursor x/y are FULL edge-to-edge travel in CSS pixels.
// Camera x/y are end-of-scroll offsets; scale is the final uniform scale.
const HERO_MOTION = {
  cursor: { inertiaSeconds: .8, referenceWidth: 1440, minViewportFactor: .85 },
  camera: {
    scrollViewport: .55,
    progressPower: 2, // Ease-out: most of the push-in happens in the first 30–40vh.
    desktopMinWidth: 1101,
    mobileStrength: .4
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
  const stage = heroScene.closest(".hero-art");
  const layers = [...heroScene.querySelectorAll("[data-hero-layer]")].map((node) => {
    const config = HERO_MOTION.layers[node.dataset.heroLayer];
    node.style.transformOrigin = `${config.origin[0] * 100}% ${config.origin[1] * 100}%`;
    return { node, config, smoke: node.querySelector(".hero-smoke"), width: 1, height: 1, rightReserve: 0, bottomReserve: 0, airX: 0, airY: 0 };
  });
  const finePointer = window.matchMedia("(hover: hover) and (pointer: fine) and (min-width: 851px)");
  const desktop = window.matchMedia(`(min-width: ${HERO_MOTION.camera.desktopMinWidth}px)`);
  let frame = 0, lastTime = 0, airTime = 0, arrival;
  let ready = false, visible = true, appeared = false;
  let geometryDirty = true, boundsDirty = true;
  let bounds = hero.getBoundingClientRect();
  let cameraDistance = 1, cameraProgress = 0;
  let targetX = 0, targetY = 0, x = 0, y = 0;
  let cursorFactor = 1, cameraFactor = 1, mobile = false;
  const resetPointer = () => { targetX = targetY = 0; };
  const clamp = (value, low = 0, high = 1) => Math.max(low, Math.min(high, value));
  // Absolute page scroll starts at zero: the first pixel moves both page and camera.
  const targetCamera = () => 1 - Math.pow(1 - clamp(window.scrollY / cameraDistance), HERO_MOTION.camera.progressPower);

  const measure = () => {
    mobile = !desktop.matches;
    bounds = hero.getBoundingClientRect();
    const stageBox = stage.getBoundingClientRect();
    const sceneBox = heroScene.getBoundingClientRect();
    const viewportFactor = Math.min(1, stageBox.width / HERO_MOTION.cursor.referenceWidth);
    cursorFactor = Math.max(HERO_MOTION.cursor.minViewportFactor, viewportFactor);
    cameraFactor = viewportFactor * (mobile ? HERO_MOTION.camera.mobileStrength : 1);
    cameraDistance = Math.max(1, window.innerHeight * HERO_MOTION.camera.scrollViewport);
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
    // Direct scrub; inertia belongs only to the independent cursor movement.
    cameraProgress = targetCamera();
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
    .catch(() => { /* Keep the static composition or existing image fallback. */ });
}

// Character: native scroll scrub, matching the existing requestAnimationFrame stack.
// Layout and the bat's resting angle live in CSS; only wrappers move here.
const characterSection = document.querySelector(".final-section");
if (characterSection) {
  const stage = characterSection.querySelector(".character-stage");
  const trajectories = {
    bottle: { x: 190, y: -150, angle: 23, start: 0, end: .76 },
    glass: { x: -150, y: 180, angle: -18, start: .12, end: .9 },
    bat: { x: -240, y: -120, angle: -25, start: .24, end: 1 }
  };
  const objects = [...stage.querySelectorAll("[data-character-object]")];
  const scrubSeconds = 1.2;
  let frame = 0, lastTime = null, progress = null;
  const clamp = value => Math.max(0, Math.min(1, value));
  const paint = (time = performance.now()) => {
    frame = 0;
    const target = clamp((innerHeight * .95 - characterSection.getBoundingClientRect().top) / (innerHeight * .9));
    const reduced = motionPreference.matches;
    const dt = lastTime === null ? 1 / 60 : Math.min((time - lastTime) / 1000, .064);
    // Frame-rate-independent damping: cover 99% of the gap in ~1.2 seconds.
    // Retarget continuously so reversing scroll never queues another animation.
    if (progress === null || reduced) progress = target;
    else progress += (target - progress) * (1 - Math.exp(-dt * 4.605 / scrubSeconds));
    const settling = !reduced && Math.abs(target - progress) > .00001;
    if (!settling) progress = target;
    lastTime = settling ? time : null;
    const distance = Math.min(1, Math.max(.35, innerWidth / 1100));
    stage.toggleAttribute("data-character-moving", !reduced && progress > 0 && progress < 1);
    objects.forEach(node => {
      if (reduced || progress >= 1) {
        node.style.transform = "";
        node.style.opacity = "";
        return;
      }
      const path = trajectories[node.dataset.characterObject];
      const local = clamp((progress - path.start) / (path.end - path.start));
      // Cubic deceleration reaches zero velocity at rest, with no overshoot.
      const remaining = Math.pow(1 - local, 3);
      node.style.transform = `translate3d(${path.x * distance * remaining}px,${path.y * distance * remaining}px,0) rotate(${path.angle * remaining}deg)`;
      node.style.opacity = String(1 - Math.pow(1 - clamp(local / .45), 2));
    });
    if (settling) frame = requestAnimationFrame(paint);
  };
  const schedule = () => { if (!frame) frame = requestAnimationFrame(paint); };
  window.addEventListener("scroll", schedule, { passive: true });
  window.addEventListener("resize", schedule, { passive: true });
  window.addEventListener("pageshow", schedule);
  motionPreference.addEventListener("change", schedule);
  if ("ResizeObserver" in window) new ResizeObserver(schedule).observe(document.body);
  stage.querySelectorAll(".character-object img").forEach(image => {
    const fallback = () => {
      image.hidden = true;
      stage.querySelector(".image-fallback").hidden = false;
    };
    image.addEventListener("error", fallback, { once: true });
    if (image.complete && !image.naturalWidth) fallback();
  });
  paint();
}

// Reversible impact, driven directly by the section's scroll distance.
if (impactScene) {
  const art = impactScene.querySelector(".impact-art");
  const group = art.querySelector(".impact-layer-group");
  const intact = group.querySelector(".impact-head-intact");
  const broken = group.querySelector(".impact-head-broken");
  const bat = group.querySelector(".impact-bat");
  const flash = group.querySelector(".impact-flash");
  const register = () => {
    const width = art.clientWidth;
    const height = art.clientHeight;
    const fit = window.innerWidth <= 850 ? Math.min : Math.max;
    const scale = fit(width / 1536, height / 1024);
    group.style.setProperty("--impact-width", `${1536 * scale}px`);
    group.style.setProperty("--impact-height", `${1024 * scale}px`);
    group.style.setProperty("--impact-left", `${(width - 1536 * scale) / 2}px`);
    group.style.setProperty("--impact-top", `${(height - 1024 * scale) * .48}px`);
    group.setAttribute("data-registered", "");
  };
  register();
  if ("ResizeObserver" in window) new ResizeObserver(register).observe(art);
  else window.addEventListener("resize", register, { passive: true });

  if (window.gsap && window.ScrollTrigger) {
    const gsap = window.gsap;
    const ScrollTrigger = window.ScrollTrigger;
    gsap.registerPlugin(ScrollTrigger);
    // Arm only when both head states and the bat are decoded. Smoke is untouched.
    Promise.all([intact, broken, bat].map(image => {
      image.loading = "eager";
      return image.decode();
    })).then(() => {
      const media = gsap.matchMedia();
      media.add({
        motion: "(prefers-reduced-motion: no-preference)",
        mobile: "(max-width: 850px)"
      }, context => {
        if (!context.conditions.motion) return;
        const strength = context.conditions.mobile ? .55 : 1;
        const visibleStart = () => {
          register();
          const section = impactScene.getBoundingClientRect();
          const head = intact.getBoundingClientRect();
          const frame = group.getBoundingClientRect();
          const viewport = window.innerHeight;
          // Start at top 25%, or later if 70% of the actual head is not yet visible.
          return Math.max(
            window.scrollY + section.top - viewport * .25,
            window.scrollY + head.top + head.height * .7 - viewport,
            window.scrollY + frame.top + frame.height * .24 - viewport * .72
          );
        };
        gsap.set(bat, { transformOrigin: "70% 24%" });
        const timeline = gsap.timeline({
          id: "argument-strike",
          defaults: { ease: "none" },
          scrollTrigger: {
            id: "argument-visibility",
            trigger: impactScene,
            start: visibleStart,
            end: () => `+=${window.innerHeight * .9}`,
            pin: impactScene,
            scrub: true,
            invalidateOnRefresh: true
          }
        });
        timeline
          // 0–75%: a long, linear diagonal approach. No clock-driven motion.
          .fromTo(bat,
            { xPercent: -5, yPercent: 4, rotation: -1 },
            { xPercent: 0, yPercent: 0, rotation: 0, duration: .75 }, 0)
          // 75–80%: discrete head swap, local flash and a restrained impulse.
          .set(intact, { visibility: "hidden" }, .75)
          .set(broken, { visibility: "visible" }, .75)
          .set(flash, { opacity: .65 * strength }, .75)
          .to(flash, { opacity: 0, duration: .05 }, .75)
          .fromTo(group, { x: 0, y: 0 }, { x: -3 * strength, y: 1.5 * strength, duration: .01 }, .75)
          .to(group, { x: 2 * strength, y: -strength, duration: .015 }, .76)
          .to(group, { x: 0, y: 0, duration: .025 }, .775)
          .to(bat, { xPercent: .4, yPercent: -.3, duration: .05 }, .75)
          // 80–100%: settle precisely into the approved registered composition.
          .to(bat, { xPercent: 0, yPercent: 0, duration: .2 }, .8);
      });
      ScrollTrigger.refresh();
    }).catch(() => { /* The static artwork and its existing image fallback remain usable. */ });
  }
}

// Anatomy: source-registered layers, reversible scroll and a readable static fallback.
const anatomyScene = document.querySelector(".scene-silhouette");
if (anatomyScene) {
  // Measure a stable flow wrapper even while the article is fixed by ScrollTrigger.
  const flow = anatomyScene.closest(".anatomy-scroll");
  const art = anatomyScene.querySelector(".silhouette-art");
  const canvas = art.querySelector(".anatomy-canvas");
  const bat = canvas.querySelector(".anatomy-bat");
  const parts = canvas.querySelector(".anatomy-parts");
  const pieces = [...parts.querySelectorAll("img")];
  const legend = canvas.querySelector(".anatomy-legend");
  const zoom = anatomyScene.querySelector(".anatomy-zoom");
  const dialog = anatomyScene.querySelector(".anatomy-dialog");
  // Source pixels: axial contraction only; the plank additionally nests into the body.
  // Every final offset is zero, so the legend remains registered to the supplied PNGs.
  const compact = [[160,-68],[110,-47],[58,-25],[20,-8],[-90,38],[-140,59],[-253,107],[-245,104],[-316,134],[-320,136],[-100,115]];

  Promise.all([...canvas.querySelectorAll("img")].map(image => {
    image.loading = "eager";
    return image.decode();
  })).then(() => {
    canvas.hidden = false;
    art.querySelector(".silhouette-image").hidden = true;
    art.querySelector(".image-fallback").hidden = true;
    anatomyScene.setAttribute("data-anatomy-ready", "");

    const enlarged = canvas.cloneNode(true);
    enlarged.querySelector(".anatomy-bat").remove();
    dialog.querySelector(".anatomy-zoom-scroll").append(enlarged);
    zoom.hidden = false;
    zoom.addEventListener("click", () => {
      dialog.showModal();
      // Start at the handle/body callouts rather than the PNG's transparent left margin.
      dialog.querySelector(".anatomy-zoom-scroll").scrollLeft = Math.max(0, enlarged.clientWidth * .24 - 16);
    });
    dialog.querySelector("[data-anatomy-close]").addEventListener("click", () => dialog.close());
    dialog.addEventListener("click", event => { if (event.target === dialog) dialog.close(); });

    if (!window.gsap || !window.ScrollTrigger) return;
    const { gsap, ScrollTrigger } = window;
    gsap.registerPlugin(ScrollTrigger);
    const media = gsap.matchMedia();
    media.add({
      motion: "(prefers-reduced-motion: no-preference)",
      stacked: "(max-width: 1100px)",
      phone: "(max-width: 520px)",
      short: "(max-height: 720px)"
    }, context => {
      if (!context.conditions.motion) return;
      const { stacked, phone, short } = context.conditions;
      const header = () => document.querySelector(".site-header").offsetHeight;
      const flowTop = () => flow.getBoundingClientRect().top + window.scrollY;
      // A short viewport uses natural page travel so neither copy nor diagram is trapped.
      const pinned = !short && (!stacked || phone);
      gsap.set(bat, { autoAlpha: 1 });
      gsap.set([parts, legend], { autoAlpha: 0 });
      pieces.forEach((piece, index) => gsap.set(piece, {
        xPercent: compact[index][0] / 2000 * 100,
        yPercent: compact[index][1] / 887 * 100
      }));
      const timeline = gsap.timeline({
        id: "anatomy-disassembly",
        defaults: { ease: "none" },
        scrollTrigger: {
          id: "anatomy-scroll",
          trigger: flow,
          // Read the current document position after responsive scroll anchoring.
          start: () => flowTop() - (pinned ? header() : window.innerHeight * .75),
          end: pinned ? () => `+=${window.innerHeight * (stacked ? 1.15 : 1.8)}` : () => flowTop() + flow.offsetHeight - window.innerHeight * .45,
          pin: pinned ? anatomyScene : false,
          scrub: true,
          anticipatePin: 1,
          refreshPriority: 1,
          invalidateOnRefresh: true
        }
      });
      timeline
        // 0–12% hold, 12–32% overlapping handover, 25–76% measured axial release.
        .to(bat, { autoAlpha: 0, duration: .2 }, .12)
        .to(parts, { autoAlpha: 1, duration: .18 }, .12)
        .to(pieces, { xPercent: 0, yPercent: 0, duration: .51, ease: "power1.inOut" }, .25)
        .to(legend, { autoAlpha: 1, duration: .12 }, .71)
        // A final 17% of the scroll is reserved for reading the construction.
        .to({}, { duration: .17 }, .83);
    });
    document.fonts.ready.then(() => ScrollTrigger.refresh());
  }).catch(() => { /* Keep the existing complete diagram if a supplied layer cannot decode. */ });
}

// Texture: subtle reversible motion of existing objects; atmosphere stays static.
const textureScene = document.querySelector(".scene-texture");
if (textureScene && window.gsap && window.ScrollTrigger) {
  const art = textureScene.querySelector(".texture-art");
  const layers = art.querySelector(".texture-layers");
  const bat = layers.querySelector(".texture-bat");
  const diamonds = [...layers.querySelectorAll(".texture-diamond")];
  const gsap = window.gsap;
  const ScrollTrigger = window.ScrollTrigger;
  gsap.registerPlugin(ScrollTrigger);
  const assemble = () => {
    Promise.all([...layers.querySelectorAll("img")].map(image => {
      image.loading = "eager";
      return image.decode();
    })).then(() => {
      layers.hidden = false;
      art.setAttribute("data-texture-ready", "");
      const media = gsap.matchMedia();
      media.add({ motion: "(prefers-reduced-motion: no-preference)", mobile: "(max-width: 850px)" }, context => {
        if (!context.conditions.motion) return;
        const strength = context.conditions.mobile ? .5 : 1;
        const timeline = gsap.timeline({
          id: "texture-parallax",
          defaults: { duration: 1, ease: "none" },
          scrollTrigger: {
            id: "texture-scroll",
            trigger: art,
            start: "top 85%",
            end: "top -25%",
            scrub: true,
            invalidateOnRefresh: true
          }
        });
        timeline.fromTo(bat, { rotation: -15 }, { rotation: -15 + 8 * strength }, 0);
        const travel = [[-44,-46],[46,-42],[44,48],[-30,-24],[32,-24],[-48,42],[-26,32],[46,44],[-34,28],[38,30]];
        diamonds.forEach((diamond, index) => {
          const [x, y] = travel[index];
          timeline.fromTo(diamond, { x: 0, y: 0 }, { x: x * strength, y: y * strength }, 0);
        });
      });
      ScrollTrigger.refresh();
    }).catch(() => { /* Keep the approved whole-scene placeholder if any layer fails. */ });
  };
  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(entries => {
      if (!entries.some(entry => entry.isIntersecting)) return;
      observer.disconnect();
      assemble();
    }, { rootMargin: "100% 0px" });
    observer.observe(art);
  } else assemble();
}
