---
name: rollback
description: Безопасный откат production-версии DIAMOND.PALKAHELP.RU на предыдущую рабочую версию. 
Используй этот skill при запросах на rollback, откат, возврат предыдущей версии или 
восстановление production после неудачного деплоя.
---

# DIAMOND.PALKAHELP.RU Rollback

## Purpose

Безопасно вернуть production PALKAHELP к предыдущей известной рабочей версии.

Пользователь всегда принимает финальное решение.

---

## Environment

Project:

`DIAMOND.PALKAHELP.RU`

Server (SSH alias):

`palkahelp`

Remote path:

`/home/p/palkahelru/diamond_palkahelp_ru/public_html`

Production URL:

`https://diamond.palkahelp.ru/`

Работай только из корневой папки проекта.

---

# Rollback source

По умолчанию источником rollback является Git.

Перед откатом определи:

- текущий production commit, если он известен;
- текущий локальный commit;
- предыдущий стабильный commit;
- какие файлы отличаются между текущей и предыдущей версиями.

Никогда не выбирай commit для rollback наугад.

Если невозможно надёжно определить предыдущую рабочую версию — остановись и спроси 
пользователя.

---

## Production version metadata

Перед анализом Git history сначала проверь:

`.deploy/production-current`

и

`.deploy/production-previous`

Используй их как основной источник информации о production-версиях.

Правила:

1. Если `.deploy/production-current` содержит commit:
   - считай его текущей известной production-версией.
2. Если `.deploy/production-previous` содержит commit:
   - считай его основным кандидатом для rollback.
3. Проверь, что оба commit существуют в Git.
4. Покажи:
   - current production commit;
   - previous production commit;
   - commit messages;
   - различия между ними.
5. Не доверяй metadata вслепую:
   - если commit отсутствует в Git;
   - если файл повреждён;
   - если значения некорректны;
   - если metadata противоречит текущему состоянию,
   остановись и сообщи пользователю.

Если `.deploy/production-current` или `.deploy/production-previous` пусты, отсутствуют или не позволяют надёжно определить rollback target — используй Git history как fallback и спроси пользователя при неоднозначности.

Не изменяй `.deploy/production-current` и `.deploy/production-previous` до успешного завершения rollback.

---

# SAFE ROLLBACK — режим по умолчанию

Если пользователь пишет:

- `rollback`
- `откати`
- `верни прошлую версию`
- `откати прод`
- `верни предыдущий деплой`

выполняй SAFE ROLLBACK.

## Before rollback

1. Проверь `git status`.
2. Покажи:
   - текущую ветку;
   - текущий commit;
   - uncommitted changes;
   - untracked files.
3. Определи commit, на который предлагается rollback.
4. Покажи:
   - текущий commit;
   - rollback target commit;
   - commit message;
   - список файлов, которые изменятся.
5. Не изменяй рабочую ветку пользователя без необходимости.
6. Не выполняй `git reset --hard` автоматически.
7. Не переписывай историю Git.
8. Подготовь rollback-версию отдельно от текущей рабочей копии, если это возможно.
9. Выполни dry-run будущей загрузки на production.
10. Не выполняй реальный rollback на этом этапе.

После подготовки покажи краткий отчёт:

- current commit;
- rollback target;
- changed files;
- dry-run result;
- deployment target;
- найденные риски.

После этого спроси:

`Продолжить rollback?`

До явного подтверждения production не изменять.

---

# BOSS OVERRIDE

Пользователь может явно приказать немедленный rollback.

Примеры:

- `откатывай сразу`
- `верни прошлую версию немедленно`
- `rollback now`
- `катись назад без проверок`

В этом режиме:

1. Не спорь с пользователем.
2. Пропусти обычные quality checks, если пользователь явно этого требует.
3. Не требуй дополнительного подтверждения.
4. Всё равно определи конкретный rollback target.
5. Никогда не выбирай commit наугад.
6. Не удаляй secrets, runtime data или серверные данные.
7. Не используй destructive Git commands без необходимости.
8. Не используй `--delete`, если пользователь явно не разрешил удаление.

Если rollback target нельзя определить однозначно — остановись и спроси пользователя даже 
при Boss override.

---

# Critical safety rules

Никогда автоматически:

- не выполняй `git reset --hard`;
- не выполняй `git clean -fd`;
- не переписывай историю;
- не удаляй production-файлы без необходимости;
- не удаляй runtime data;
- не удаляй заказы, CSV, пользовательские данные и серверные данные;
- не загружай `.env`;
- не загружай SSH keys;
- не загружай secrets;
- не загружай `.git/`;
- не загружай `.agents/`;
- не загружай `.claude/`.

Rollback должен затрагивать только production-код и production-assets, необходимые для 
возврата версии.

---

# Rollback procedure

Предпочтительный способ:

1. Определи rollback target commit.
2. Подготовь содержимое этого commit отдельно.
3. Не переключай текущую рабочую ветку пользователя, если можно этого избежать.
4. Выполни `rsync` dry-run.
5. Покажи изменения.
6. После подтверждения выполни реальный `rsync`.
7. Не используй `--delete` без явного разрешения.

Если для корректного rollback требуется удаление файлов, появившихся только в новой 
версии:

1. покажи точный список таких файлов;
2. объясни, почему без удаления rollback будет неполным;
3. запроси отдельное подтверждение на удаление.

---

# Runtime data protection

Особое правило для PALKAHELP:

Rollback кода не должен откатывать или удалять runtime-данные production.

Сохраняй серверные данные, которые создаются после деплоя, включая:

- заказы;
- CSV;
- пользовательские данные;
- runtime-файлы;
- приватные серверные файлы.

Если не уверен, является ли файл runtime-данными — не трогай его автоматически.

---

# Post-rollback verification

После rollback обязательно проверь:

1. HTTP status `https://diamond.palkahelp.ru/`;
2. что главная страница отдаётся;
3. что `index.html` соответствует rollback-версии;
4. основные затронутые endpoints;
5. что runtime-данные не были потеряны;
6. что production не содержит файлов, случайно загруженных из локальной служебной среды.

---

# Production metadata after successful rollback

После успешного rollback и успешного smoke-check:

1. Запиши rollback target commit в:
   `.deploy/production-current`

2. Предыдущий production commit до rollback запиши в:
   `.deploy/production-previous`

3. Создай отдельный commit:

`Record production rollback <short-commit>`

4. Выполни `git push`.

Не включай в этот commit посторонние изменения.

Если Git sync metadata завершился ошибкой:
- rollback всё равно считается выполненным;
- сообщи об ошибке синхронизации;
- не запускай rollback повторно.

---

# Rollback report

После завершения сообщи:

- rollback target commit;
- какие файлы были восстановлены;
- какие файлы не трогались;
- были ли удаления;
- smoke-check result;
- HTTP status;
- warnings.

Если rollback прошёл успешно, явно сообщи:

`ROLLBACK: SUCCESS`

Если verification не пройдена, не сообщай об успешном rollback.

---

# Failure handling

Если любой этап завершается ошибкой:

1. останови дальнейшие действия;
2. сообщи точный этап;
3. покажи ошибку;
4. не продолжай destructive actions;
5. не скрывай проблему;
6. не пытайся молча чинить production.

Если rollback сам создаёт новую проблему — остановись и сообщи пользователю текущее 
состояние production.
