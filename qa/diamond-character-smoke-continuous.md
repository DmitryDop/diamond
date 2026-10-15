# Дымка «Холодный. Крепкий.»

Встроенный imagegen. Финальный слой: `assets/diamond-character/character-smoke-continuous.png`.

Одна непрерывная дымка с альфа-каналом. Предметов и вырезов по их контурам нет. Исходные объекты не изменены. Отдельный PNG подключён под существующей сценой как статический слой. Исходный JPEG, содержащий прежнюю атмосферу, сохранён. Параллакс не включён; предметы и анимации не заменены.

Промпт первого прохода:

Use case: lighting-weather / background-extraction.
Asset type: one independent seamless smoke-and-haze atmosphere PNG plate for a website parallax layer.
Input image: the approved DIAMOND campaign photo, used ONLY as a reference for the very subtle existing cool charcoal-blue haze, its distribution and softness. The bat, bottle, glass, water ribbon, ice and droplets are NOT the subjects of the output.
Primary request: output ONLY a continuous atmospheric field of the same restrained graphite-blue smoky haze, on a genuinely transparent alpha background. It must be continuous THROUGH ALL positions formerly occupied by objects. Fill those areas with natural coherent haze; do NOT trace objects, do NOT cut object-shaped holes, and do NOT include masks following their outlines.
Landscape canvas around 3:2 matching the reference field of view. Preserve a broad subtle cloud around the upper middle/right, a soft dim haze crossing the center, and a sparse barely visible lower haze. There must be no recognizable bat, bottle, glass, splash, ice, droplets, object edges, typography, logos, reflections or solid backdrop in the output.
The atmospheric texture should be soft low-contrast cool graphite and desaturated slate blue, photoreal fine gaseous wisps without thick white plumes. A continuous veil with organic variations in density, gently diffuse and spread across the scene. It must fade into actual fully transparent alpha at all outer canvas edges with at least 8% completely clear border and a generous smooth falloff. Not a rectangle with a dark fill. Genuine partial alpha throughout the haze, not opaque gray paint or a checkerboard baked into pixels.
This is a background atmosphere plate independent of product geometry, with haze underneath where the objects would be, suitable for moving horizontally or vertically by 5% without showing silhouettes or holes. Keep the amount and cold dark tone of atmosphere close to the input, restrained, premium, quiet. NO OBJECTS OF ANY KIND; ONLY HAZE WITH TRANSPARENCY. Do not return the product scene or modify any source object assets.

Промпт коррекции прозрачности:

Edit the supplied haze-only image. Change ONLY the alpha / background separation and haze density. Preserve the organic wisps and broad spatial flow.
The current image has a DARK RECTANGULAR BACKGROUND and is too opaque. REMOVE THAT DARK BACKGROUND COMPLETELY. Replace ALL black/dark filler between the smoky wisps with actual fully transparent alpha (alpha 0). Keep ONLY a delicate continuous field of translucent cool graphite-blue atmospheric wisps on genuine transparent PNG.
Think of an isolated translucent smoke VFX element, not a background texture. Wisps should have pale desaturated silver/slate-blue RGB with LOW opacity: mostly alpha 0.05 to 0.25 and only a few denser areas up to about 0.45. Empty spaces must be entirely clear. No opaque black pixels. It should visibly transmit whatever is behind it.
Use a landscape 3:2 canvas. Increase the clear padding: at least 10% of the canvas on every side must be completely empty transparent pixels, then soft long gradual wisps into the middle. No straight rectangular edges in the smoke, no dark mat, no vignette painted as dark filler.
The cloud field must be continuous and physically plausible wherever any object might later be placed, with NO object outlines, NO cut-out silhouettes, NO product-shaped gaps. No bat, bottle, glass, splash, ice, drops, symbols or text.
This is one independent parallax fog layer. Return ONLY the genuinely translucent low-density smoke wisps and genuine transparency. Keep the atmospheric style restrained and close to the original haze, not bright dense white smoke.
