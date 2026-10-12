# diamond-impact — отдельные слои

Файлы для анимации: `assets/diamond-impact-bat.png` и `assets/diamond-impact-sculpture.png`. Оба — RGBA PNG, 1536 × 1024. Одинаковый холст сохраняет исходные координаты: бита располагается поверх скульптуры без дополнительного сдвига.

Бита вырезана из `assets/diamond-impact.png`: RGB сохранён для всех её непрозрачных и полупрозрачных пикселей. Видимые области скульптуры взяты из исходника; фон заменён alpha-маской. Осколки и пыль входят в слой скульптуры. Скрытый битой участок восстановлен по согласованию с Дмитрием; у его края согласована исходная тень. Для устранения остатков биты маска восстановления расширена на 7 px вокруг контура. Детали, которых нет в исходнике из-за перекрытия, являются реконструкцией.

Восстановление и исходная маска скульптуры: встроенный `image_gen`. Финальное выделение, сохранение RGB исходника и регистрация слоёв: локальный Swift/AppKit. Генеративная вырезка биты не использована: она изменила масштаб объекта.

Проверка: размер, наличие полностью прозрачных и непрозрачных пикселей, полупрозрачные края, точное совпадение RGB биты с исходником; визуальный просмотр отдельных объектов на тёмном и светлом фоне. Результаты: `diamond-impact-layers-validation.json`, превью: `diamond-impact-layers-preview.png`.

## Созданные файлы

- `assets/diamond-impact-bat.png`
- `assets/diamond-impact-sculpture.png`
- `qa/extract-impact-layers.swift` — воспроизводимая сборка.
- `qa/diamond-impact-sculpture-restoration.png` — исходное восстановление и alpha-маска.
- `qa/diamond-impact-layers-preview.png` — визуальная проверка двух слоёв.
- `qa/diamond-impact-layers-validation.json` — проверка экспортов.
- `qa/diamond-impact-contour-crop.png`, `qa/diamond-impact-contour-grid.png` — материалы проверки контура.
- `qa/diamond-impact-layers.md` — эта запись.

## Промпт восстановления

Use case: background-extraction. Edit target: attached diamond-impact.png, 1536x1024. Extract ONLY the existing marble sculpture and its existing suspended marble chips and fine dust as a transparent RGBA PNG at exact original scale, original pixel positions, original lighting on same 1536x1024 canvas. Remove the bat completely and remove black studio backdrop. Preserve all visible existing sculpture details without change, original face, eye, nose, mouth, jaw, hair, grain, cracks, break at temple and neckline, shoulders, all debris and dust in their original coordinates. Only reconstruct the small previously occluded sculpture/hair region under the removed bat, continuing existing dark shaded carved hair and cracked marble seamlessly; do not repair cracks or impact damage. Preserve original crop at right and bottom. Absolutely do not move, recenter, rotate, zoom, restyle or beautify sculpture. True transparent background, no black backdrop, no bat, no shadow behind silhouette. Exact original 1536x1024 registration needed for animation layers.

## Промпт неиспользованной генеративной вырезки биты

Use case: background-extraction. Edit target: attached diamond-impact.png, 1536x1024. Extract ONLY the complete DIAMOND bat as a transparent RGBA PNG on exactly the same 1536x1024 canvas, at EXACT same original pixel coordinates, size and diagonal angle. Remove the entire sculpture, marble shards, dust and black backdrop. This is precise extraction, NEVER redesign or rerender the bat. Preserve every original visible bat pixel/detail, all diamond stones and facets, chrome black and white reflections, skull, ribs, white wrapped grip, jeweled pommel. Full bat from x57 y835 to x1185 y175 remains unchanged and uncropped. Retain thin crisp antialiased original silhouette without halos. No drop shadow or background. Output genuine transparency. Do not recenter, resize, rotate or crop.
