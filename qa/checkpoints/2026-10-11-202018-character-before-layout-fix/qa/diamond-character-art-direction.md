# DIAMOND — Характер

Невесомая рекламная сцена: белая рукоять и платина задают длинную нисходящую диагональ, крупная прозрачная Absolut удерживает верх композиции, стакан и дуга жидкости создают встречное движение. Лёд и капли фиксируют один frozen moment. Поверхности, опоры и столкновения отсутствуют.

Главный visual — единая фотографическая сцена. Она занимает всю ширину секции, без финального слогана. Прежние заголовок, описание и CTA восстановлены в отдельном скрытом контейнере `#character-copy-draft`; в текущий визуал они не внедрены. Для телефона подготовлена отдельная вертикальная композиция через `<picture>`.

## Файлы

- `../assets/diamond-character-campaign.png` — исходник desktop-сцены.
- `../assets/diamond-character-campaign.jpg` — оптимизированный desktop-визуал лендинга.
- `../assets/diamond-character-campaign-mobile.png` — исходник вертикальной композиции.
- `../assets/diamond-character-campaign-mobile.jpg` — мобильный visual.
- `../assets/diamond-character-bat.png` — утверждённая бита из вложения Дмитрия, скопирована без изменений, прозрачный PNG.
- `../assets/diamond-character-bottle.png` — бутылка отдельно, прозрачный PNG.
- `../assets/diamond-character-glass-splash.png` — стакан с жидкостью, льдом и брызгами, прозрачный PNG. Splash сохранён вместе со стаканом, чтобы не разрывать течение жидкости.
- `../assets/absolut-bottle-reference.png`, `../assets/ice-glass-reference.png` — исходные референсы из вложений.
- `diamond-character-review.html` — просмотр секции и галерея отдельных объектов.

Основная сцена и отдельные glass-ассеты созданы встроенным `image_gen`. В главном визуале бутылка дополнительно доработана: убрано белёсое заполнение корпуса, восстановлена целая крышка и добавлен отступ до края. Отдельные объекты — изображения для дальнейшей сборки; основной key visual остаётся цельным изображением, поэтому разделённые PNG не заявляются как идентичные слои исходной сцены.

## Завершение технической интеграции

После утверждения изображений новых генераций не было. Desktop/mobile-композиции и PNG отдельных объектов сохранены побайтно без изменений; SHA-256, размеры и расчёт геометрии находятся в `diamond-character-validation.json`.

Desktop: 1519 × 1035 px, mobile: 1122 × 1402 px. На ширинах 1920 / 1440 / 768 применяется desktop-ассет, на 390 / 375 — уже подготовленный и утверждённый portrait-ассет. CSS использует точные пропорции исходников и `object-fit: contain`, кадрирования нет. Затемнение для стыка ограничено пустыми краями (верхние 3% и нижний 1%); декоративный разделитель перед сценой снят. Расположение и свет объектов не менялись.

Проверены статические превью всех пяти размеров: `../previews/03-character-{1920,1440,768,390,375}.png`. Это иллюстрации CSS-компоновки, не браузерные скриншоты. Бита, крышка/основание бутылки, стакан и основная дуга splash целиком в кадре; случайной обрезки важных частей нет. Отдельные объекты просмотрены на графите в `../previews/03-character-objects.png`; настоящие прозрачные и полупрозрачные пиксели PNG подтверждены.

Ограничения проверки: Chrome-коннектор возвращает ошибку JSON; IAB недоступен, локальный сервер заблокирован sandbox. Поэтому живые browser overflow/console/scroll checks не подтверждены. Ширина новой секции и всех её слоёв равна 100% родителя, трансформаций или выходящих за контейнер слоёв нет. Это статическая проверка геометрии, не измерение `scrollWidth` всей страницы.

На экране шириной 1920 px desktop-исходник масштабируется в 1,264 раза; настоящего 4K/Retina desktop-исходника нет. Изображения не апскейлились. Мелкая печать на этикетках сгенерирована и не предназначена для проверки побуквенной точности. Финальные сцены не ретушировались после утверждения.

Статические проверки HTML/JS пройдены: вложенность, уникальные ID, цели якорей/ARIA, локальные пути, фактические размеры ассетов, скрытый текстовый блок, синхронизация страницы просмотра. На статических превью целых сцен явных рамок, случайных обрезок или коллажных стыков не обнаружено. Утверждённая бита совпадает с исходным вложением побайтно.

### Восстановленный текст

Источник — предыдущий `index.html`, прочитанный в этом сеансе до пересборки. В `qa/background-review.html` есть более ранний снимок со старой редакцией «Характер в деталях»; вместо него сохранена последняя редакция из рабочего HTML:

- Заголовок: «Холодный. Крепкий.»
- Описание: «Платина, бриллианты и лёд. Характер DIAMOND не требует объяснений.»
- CTA: «Перейти в PALKAHELP», прежний URL `https://palkahelp.ru`.

Восстановлены `container → final-copy → label / h2 / p / a`; контейнер имеет `hidden`. Скрытый технический заголовок секции «Характер» остаётся её доступным названием. Копирайт не переписан.

Для этапа типографики остаются расположение отдельного текстового блока относительно сцены, окончательные заголовок/описание, размер и переносы, роль и положение CTA, их компоновка на телефоне. Ничего не деплоилось.

## Промпты

### Главная сцена

Use case: ads-marketing.
Asset type: seamless large campaign key visual for the DIAMOND landing page "Character" section.
Input image 1 = strict DIAMOND bat identity reference. Image 2 = strict Absolut bottle identity/label reference. Image 3 = glass silhouette and thick glass base reference. These are references, NOT flat PNGs to paste. Re-photograph the same products together in one physically coherent luxury scene.

Create a striking high-end advertising still photograph, landscape 3:2, lavish sharp material detail, optical realism. Three objects levitate in a black graphite void. No table, floor, pedestal, shelf, people, hands, or support.
The dominant DIAMOND bat spans almost the full frame on a strong descending diagonal: white wrapped handle near x=12%,y=20%, long polished platinum taper across center, huge diamond-encrusted barrel near x=86%,y=74%. Keep full bat and exact proportions inside the frame with breathing room. Retain precise white grip, jeweled end cap and collar, chrome taper with flowing elongated metal ribs, dense ordered diamonds on cylindrical barrel, rounded platinum barrel cap. Use THIS approved bat, no deformation, no generic sports bat, no wood, no gold, do not add skulls absent from this supplied reference.
A LARGE full Absolut bottle levitates in the upper center/right, approximately x=66%,y=35%, occupying about 60 percent of frame height, tilted 12 degrees clockwise, complete cap and base visible. Its label faces camera and is unmistakably readable "ABSOLUT VODKA" in original blue, preserve original silver cap and distinctive squat-shouldered glass silhouette and original label design. Clear colorless vodka, truly TRANSPARENT glass with deep graphite seen THROUGH the bottle body, crisp cold rim highlights and realistic optical refraction, thick transparent base. NO solid white inner body, no opaque white paper panel behind all lettering, no frosted glass. The supplied cutout has white studio reflections: replace those with physically coherent dark-set glass reflections.
A big beautiful thick-base transparent rocks tumbler levitates at x=33%,y=72%, tilted 22 degrees counterclockwise. Glass about 30 percent of frame height; full glass visible, not touching the bat or bottle. Half-filled with clear colorless vodka, a few large crystal-clear ice cubes. An elegant translucent sheet of vodka flows up and OUT of its rim in a controlled sculptural ribbon, curving toward the center upper-left around the bat without contact. Two ice cubes and a few perfectly frozen droplets float in that arc above the glass. Ice shows transparent cores, tiny frosty internal fractures, crisp edges. Splash MUST clearly originate at glass rim. This is poised zero-gravity fluid motion, NOT a collision, shattering, accident or pouring bottle. No debris or shattered glass. Preserve uncluttered space between objects so each remains legible.

All three objects form one monumental triangular campaign composition filling the frame, not small objects in a corner. Bat in front, glass lower left/middle, bottle behind and higher right. Product overlaps may be subtle but do not obscure bottle label or bat grip and barrel. Every object FLOATS at a distinct suspended angle, none is standing on anything. White grip contrasts black, transparent glass contrasts black via precise rim lights; light actually travels through liquid and glass.
Lighting: premium cold silver large softbox edge lighting from above left and behind right, narrow clean black reflections in chrome, crisp diamond facets without cheap starbursts; physically coherent light shared by all objects. Near-black graphite/satin background #0b0b0e, very subtle broad charcoal light behind bottle and glass, edges fade naturally near-black. Realistic beautiful glass caustics inside objects, no floating artificial spotlight glow.
Mood: frozen moment, cold, strength, platinum, luxury fashion/product editorial. Extremely polished high-speed studio campaign photograph. Restrained sculptural fluid motion, expensive precise arrangement, tangible material depth. No typography on background, no headline, no decorative symbols, no watermark.
Avoid: violence, impact, destruction, smashed glass, smoke, explosions, chaotic splatter everywhere, neon, acid colors, opaque milky glass, white plastic bottle, cheap collage, extraneous props, extra bottles or bats, hands, duplicate glasses, warm lighting, surface reflections suggesting a floor.

### Доработка бутылки

Use case: precise-object-edit.
Edit THIS campaign image, with one targeted correction: replace only the Absolut bottle rendering while preserving the whole excellent composition, DIAMOND bat, glass, liquid splash, droplets, ice cubes, lighting style, background, and their exact geometry. Landscape 3:2.
The current bottle has an opaque white body and the cap is cropped. Correct BOTH:
1. The bottle must be FULLY inside the frame. Make bottle about 12% smaller and shift it down so its entire silver cap has at least 5% frame-height breathing room above it. Keep its original tilt, upper-right placement, squat-shouldered Absolut shape and prominent scale, behind the bat. No contact or support.
2. ABSOLUT bottle is clear transparent glass filled with clear transparent colorless liquid. REMOVE the solid white/milky interior and white rectangular printed background. Through the bottle body one must visibly see the SAME charcoal-black background as outside the bottle, refracted and distorted by glass thickness. Only blue printed "ABSOLUT VODKA" letters, black cursive "Country of Sweden", original portrait medallion and tiny printed details are on the transparent glass. A tiny frosted lower import band is acceptable but main body MUST be DARK-TRANSPARENT rather than white. Strong cold silver rim highlights outline glass edges, localized slim grey reflections, clear thick base with refraction. Premium clear spirit-bottle photography on a DARK set, NOT a white studio shot.
Preserve blue ABSOLUT VODKA lettering exactly and make it legible via local silver reflection behind just the letters. Do not make the whole bottle pale. Preserve the current high-end visual, all bat diamonds, white grip, and beautiful transparent glass splash. No other changes, no new objects, no captions or text outside the original bottle printing.

### Стакан и splash

Use case: background-extraction.
Asset type: isolated transparent-background glass, splash and ice production asset for the DIAMOND campaign.
Extract ONLY the exact lower-left tilted rocks tumbler WITH its originating sculptural vodka splash, droplets and two flying ice cubes from this supplied campaign image. Remove the DIAMOND bat, the Absolut bottle and all black backdrop entirely. Reconstruct only the small bits of fluid hidden behind the bat so the whole ribbon is a clean continuous curve starting at the rim. Keep the exact tumbler silhouette, angle, thick clear base, clear vodka and internal ice cubes, and elegant flying splash curl matching the campaign. One rocks glass only, NOT a bottle.
Keep photoreal transparent GLASS and colorless LIQUID: crisp cold rim highlights and realistic refraction, tiny clear droplets, the object must read correctly on a dark graphite backdrop. Transparent areas of the glass and space around the splash should transmit the destination background. Genuine alpha background, no white fill, no dark rectangle, no checkerboard baked into pixels, no drop shadow, no floor or support, no added props. Portrait 3:4 canvas, the complete glass AND entire splash AND both flying ice cubes inside frame with a generous safe margin. Render as beautifully sharp luxury studio object, not an opaque plastic white glass. Preserve the campaign lighting style. No text or watermark.

### Бутылка отдельно

Use case: background-extraction.
Asset type: separate Absolut bottle production cutout matching DIAMOND luxury campaign.
Extract ONLY the complete tilted Absolut bottle from supplied campaign image. Remove the bat, glass, splash, flying ice and black background. Reconstruct the clear lower bottle body/base where obscured by the bat, faithfully continuing the existing bottle shape. Retain the exact cap, 12-degree clockwise tilt, original Absolut silhouette, printed blue "ABSOLUT VODKA", cursive "Country of Sweden", portrait medallion and silver import band. Match this scene's cold silver edge lighting and polished optical quality. Full bottle within a portrait 3:4 canvas with safe margin on all sides.
IMPORTANT: the bottle is transparent colorless glass and vodka, not opaque white plastic. Genuine alpha background including transmission through clear parts of bottle. Preserve realistic glass thickness, refraction, narrow highlights and navy-blue lettering; no big opaque white fill behind lettering, no solid dark rectangle behind/inside bottle. On a dark graphite background the body must read as genuinely clear glass via rim lights and local reflections. Do not whiten the body. No floor, shadow, other objects, additional logos or captions. Preserve premium realistic material depth. Deliver transparent PNG, no checkerboard pattern baked in.

### Вертикальная адаптация

Use case: precise-object-edit.
Asset type: mobile portrait adaptation of this approved DIAMOND campaign scene.
Recompose this EXACT approved scene as a VERTICAL 4:5 campaign photograph. Preserve every product's design, cold silver lighting, near-black graphite atmosphere, crystalline material quality, color and identity. This is the same frozen zero-gravity moment, only its composition adapts to a portrait phone frame.
Keep ALL THREE objects large, complete and fully inside the frame with safe margins. No cropped ends.
DIAMOND bat is the dominant long object across portrait on a steeper descending diagonal, white grip near upper-left x=18%,y=12%, huge diamond barrel toward lower-right x=82%,y=84%. Preserve exact full bat length and proportions, white wrapped grip, jewel end cap, flowing platinum taper and diamond rows. NO skull, NO deformation.
The same clear transparent ABSOLUT VODKA bottle levitates behind the bat in upper-right x=68%,y=30%, complete cap and base visible. Label faces camera, original blue printed lettering and portrait preserved. Body remains DARK-CLEAR transparent with graphite transmitting through, silver edge reflections, not an opaque white fill.
The exact transparent rocks glass is lower-left x=30%,y=69%, tilted, with clear vodka and ice. Its frozen liquid ribbon rises from rim toward upper-center left in a graceful curve, two flying ice cubes and sparse clear droplets complete the diagonal rhythm.
Nothing touches a surface, no bat collision, no shattering, no floor, supports, human, hands or extra objects. The scene fills portrait generously, each object stays distinct, bottle text and glass not obscured by bat. All material detail remains photoreal and expensive. Graphite edges blend seamlessly into #0b0b0e. No background copy, slogan or watermark.

## Возврат видимого текста по просьбе Дмитрия

Заголовок «Холодный. Крепкий.», прежнее описание и CTA теперь отображаются в отдельном контейнере над сценой. Атрибут `hidden` снят, заголовок снова имеет `id="final-title"`. Изображения и размеры visual не менялись; увеличилась общая высота секции за счёт текстового блока. Страница просмотра синхронизирована. Это заменяет прежнее решение о скрытом контейнере.
