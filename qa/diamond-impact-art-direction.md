# DIAMOND — Когда аргумент очевиден

Единая editorial-сцена: бриллиантовая бита встречается с античным мрамором. Трещины и зависшие осколки фиксируют момент действия, спокойное лицо статуи сохраняет музейный характер сцены.

Главный визуал: `../assets/diamond-impact.jpg` (1536 × 1024, JPEG для страницы).
Исходник генерации: `../assets/diamond-impact.png` (1536 × 1024).
Инструмент: встроенный `image_gen`, с утверждённой `diamond-bat.png` как референсом формы и материалов.

На desktop текст встроен в тёмное поле изображения; на tablet/mobile текст расположен над полной сценой, бита и точка контакта остаются в кадре. Единственное появление изображения длится 1,1 секунды; при reduced motion анимация отключена. Без JavaScript контент виден.

Перестроение композиции: ≤1100 px. На статическом desktop-превью скорректировано положение текста, чтобы рукоять не пересекала подзаголовок. Превью: `../previews/04-impact-desktop.png`, `../previews/04-impact-mobile.png`; источник композиции в SVG и скрипт `render-impact-preview.swift` сохранены рядом с результатами.

Статические проверки пройдены: вложенность HTML, уникальные ID, цели якорей и ARIA, локальные пути, точные тексты брифа, отсутствие CTA в новой секции, порядок «текст → изображение» в DOM, удаление старой сцены из рабочего HTML/CSS, синхронизация страницы просмотра, синтаксис JavaScript. Ничего не деплоилось.

Просмотр: `light-shadow-review.html` — изолированная секция с размерами 1920, 1440, 768, 390 и 375 px. Якорь лендинга `#light-shadow` сохранён.

Браузерная проверка в среде агента недоступна: Chrome-коннектор возвращает ошибку JSON, IAB отсутствует, запуск локального сервера запрещён sandbox. Статические PNG-превью демонстрируют композицию; они не являются браузерными скриншотами.

## Промпт генерации

Use case: ads-marketing.
Asset type: single seamless cinematic editorial image for DIAMOND luxury landing-page narrative climax.
Input image 1: strict product identity reference, the approved DIAMOND bat. Preserve its exact recognizable silhouette and proportions, white wrapped grip with jeweled end cap, polished sculptural platinum/chrome taper with integrated little metallic skull and flowing metal ribs, densely diamond-encrusted cylindrical barrel. Do not substitute a generic bat. Reorient this same product faithfully into this scene.

Create a premium dark museum art photograph, wide landscape 3:2 composition, very high detail. On the right two thirds of the image a monumental antique white Carrara marble classical male bust, recognizable as an inanimate carved museum sculpture, three-quarter face facing left, head near upper right, cropped chest at bottom. A complete DIAMOND bat thrusts diagonally from lower middle-left toward the statue's left temple, white handle at lower left, diamond barrel at upper right touching the temple. The product reads distinctly in front of the dark ground and retains its full length. Capture the precise instant of first impact: fine branching cracks in the marble temple, a small elegant fracture/chip at contact, a restrained fan of tiny marble chips and fine powder propelled to upper right, a few suspended angular fragments. The sculpture's face remains beautiful, calm, intact and clearly stone. Tension and impulse, action frozen by high-speed studio photography. Composition should have strong diagonal momentum and plausible local contact, not disconnected objects placed nearby. Bat and statue belong to ONE coherent photographic scene with physically matched lighting and depth. Bat diamond barrel clearly visible and bright, white grip clearly visible, sculpture sharp and detailed. No hand or person holding the bat.

Lighting: cold silver grazing museum light from above-left, deep velvety graphite shadows, black satin backdrop near #0b0b0e, subtly brighter grey behind bust only. Use restrained low-key tonal contrast, realistic Carrara grain, exquisite diamond facets, clean polished platinum reflections. Quiet costly fashion editorial and museum vandal energy. No pedestal necessary.
Framing: leftmost 35 percent is uninterrupted near-black negative space for HTML heading (do not render any text); objects mainly in right 65 percent. Bust and entire bat must stay inside frame with some breathing room. Key contact point around x=72%, y=36%, bat grip around x=38%, y=82%. Image edges fade naturally into extremely dark black graphite backdrop so it integrates seamlessly into a dark site. No rectangular frame.
Avoid: blood, flesh, injuries, realistic violence against people, horror, gore, cartoon, meme, flames, explosion effects, neon, colored glow, excessive debris, smoke clouds, chaotic motion blur, gold metal, extra props, labels, typography, logos, watermark. This is a surreal museum sculpture and jewelry-object art metaphor, not human violence.
