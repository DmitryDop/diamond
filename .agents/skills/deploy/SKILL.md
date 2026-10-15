---
name: deploy
description: Безопасный production-деплой DIAMOND.PALKAHELP.RU на SpaceWeb через rsync. Используй этот skill при запросах на деплой, публикацию, выкладку или обновление production-версии сайта.
---

# DIAMOND.PALKAHELP.RU Deploy

## Purpose

Деплой текущей production-версии DIAMOND.PALKAHELP.RU на SpaceWeb.

Пользователь всегда является финальным лицом, принимающим решение о деплое.

---

## Environment

Server (SSH alias):

`palkahelp`

Remote path:

`/home/p/palkahelru/diamond_palkahelp_ru/public_html`

Production URL:

`https://diamond.palkahelp.ru/`

Deployment tool:

`rsync`

Работай только из корневой папки проекта.

---

# Deployment modes

## 1. SAFE DEPLOY — режим по умолчанию

Если пользователь просто просит:

- `деплой`
- `задеплой`
- `выложи`
- `обнови прод`
- `deploy`

используй SAFE DEPLOY.

### Before deployment

1. Убедись, что находишься в корне проекта.
2. Выполни `git status`.
3. Покажи:
   - текущую ветку;
   - текущий commit;
   - изменённые файлы;
   - untracked-файлы.
4. Определи production-файлы проекта.
5. Убедись, что запрещённые файлы не попадут на сервер.
6. Запусти доступные для проекта тесты и lint-проверки.
7. Выполни `rsync` только в режиме dry-run (`-n`).
8. Не выполняй настоящий deploy на этом этапе.

### rsync

Для DIAMOND.PALKAHELP.RU используй совместимые с macOS параметры:

`-rvz`

Для dry-run добавляй:

`-n`

Не используй без отдельной необходимости:

`-a`

`--delete`

`--delete-excluded`

### Deployment preview

После проверок и dry-run покажи короткий итог:

- branch;
- commit;
- какие файлы будут загружены;
- какие файлы исключены;
- результаты тестов;
- результат dry-run;
- deployment target;
- будут ли удаляться файлы;
- найденные риски.

После этого остановись и спроси:

`Продолжить деплой?`

До явного подтверждения пользователя production не изменять.

---

## 2. BOSS OVERRIDE

Пользователь является владельцем процесса и может явно приказать выполнить немедленный deploy.

Примеры:

- `лей сразу`
- `лей быстрее всё`
- `деплой без проверок`
- `пропусти проверки`
- `deploy now`
- `skip checks and deploy`

При явном Boss override:

1. Не спорь с пользователем.
2. Не выполняй обычные quality checks, которые пользователь приказал пропустить.
3. Не требуй SAFE DEPLOY.
4. Кратко сообщи, какие проверки будут пропущены.
5. Выполни deploy без дополнительного вопроса `Продолжить?`.

### Critical safety checks

Boss override НЕ отключает базовую защиту production.

Даже при немедленном deploy никогда:

- не загружай `.env` и `.env.*`;
- не загружай SSH-ключи;
- не загружай пароли, API keys и другие secrets;
- не загружай `.git/`;
- не загружай `.agents/`;
- не загружай `.claude/`;
- не публикуй приватные серверные файлы;
- не используй `--delete`, если пользователь явно не разрешил удаление;
- не удаляй файлы на production без явного разрешения пользователя.

Если обнаружена непосредственная угроза публикации секрета или ключа — остановись и сообщи пользователю.

---

# Files excluded from deployment

Всегда исключай как минимум:

- `.git/`
- `.gitignore`
- `.agents/`
- `.claude/`
- `.env`
- `.env.*`
- `.DS_Store`
- `CLAUDE.md`
- `AGENTS.md`
- `docs/`
- `tmp/`
- `PLAN.md`
- `.deploy/`

Также исключай:

- SSH private keys;
- credentials;
- API keys;
- локальные конфигурационные файлы с секретами;
- любые файлы, явно не предназначенные для production.

Не исключай рабочие production-данные или runtime-файлы только по предположению.
Если назначение файла неясно — сначала проверь его роль.

---

# Production deletion rules

По умолчанию deploy не должен удалять файлы на сервере.

Не используй:

`--delete`

или другие destructive rsync-options без явного разрешения пользователя.

Если удаление действительно необходимо:

1. покажи, что будет удалено;
2. объясни причину;
3. запроси отдельное подтверждение.

Boss override не считается автоматическим разрешением на удаление файлов, если пользователь прямо этого не сказал.

---

# Deployment

После подтверждения в SAFE DEPLOY или сразу при Boss override:

1. выполни реальный `rsync`;
2. загружай только production-файлы;
3. не изменяй файлы вне configured remote path;
4. не выполняй дополнительные destructive actions автоматически.

---

# Post-deployment verification

После каждого реального deploy обязательно выполни smoke-check.

Проверь:

1. наличие `index.html` на сервере;
2. что `index.html` корректно загружен;
3. HTTP status Production URL;
4. что `https://diamond.palkahelp.ru/` действительно отдаёт страницу;
5. при необходимости — основные затронутые deploy-изменением endpoints.

Проверяй только configured Production URL.

Не угадывай другие домены.
Не ищи альтернативные адреса проекта.

---

# Deployment report

После завершения сообщи:

- результат deploy;
- какие файлы были отправлены;
- результат smoke-check;
- HTTP status;
- предупреждения;
- пропущенные проверки, если использовался Boss override.

Если всё прошло успешно, явно сообщи:

`DEPLOY: SUCCESS`

Если проверка не пройдена, не сообщай об успешном deploy.

---
# Production version tracking

После успешного production deploy и успешного smoke-check обнови локальную историю production-версий.

Используй:

`.deploy/production-current`

и

`.deploy/production-previous`

Правила:

1. Выполни `git rev-parse HEAD` и получи commit, который был задеплоен.
2. Прочитай `.deploy/production-current`.
3. Если в нём уже есть commit:
   - запиши его в `.deploy/production-previous`.
4. Запиши текущий deployed commit в `.deploy/production-current`.
5. Не обновляй эти файлы, если deploy или smoke-check завершились ошибкой.
6. Никогда не отправляй `.deploy/` на production через rsync.
7. После обновления файлов покажи:
   - предыдущий production commit;
   - текущий production commit.

Если содержимое `.deploy/production-current` уже совпадает с текущим deployed commit, не меняй историю повторно.

## Git sync for production version

После успешного обновления `.deploy/production-current` и `.deploy/production-previous`:

1. Выполни `git status`.
2. Добавь только файлы:
   - `.deploy/production-current`
   - `.deploy/production-previous`
3. Создай отдельный commit:

`Record production deploy <short-commit>`

4. Выполни `git push`.

Не включай в этот служебный commit посторонние изменения.

Если `git push` завершился ошибкой:
- production deploy всё равно считается выполненным;
- сообщи, что production-version metadata не синхронизирована;
- не скрывай ошибку;
- не повторяй deploy из-за ошибки Git sync.
---

# Failure handling

Если любой этап завершается ошибкой:

1. останови дальнейшие действия;
2. сообщи, на каком этапе произошла ошибка;
3. покажи текст ошибки;
4. не скрывай проблему;
5. не выполняй следующие destructive actions автоматически;
6. не пытайся молча чинить production.

Не заявляй об успешном deploy, если post-deployment verification не пройдена.

Если исправление production требует изменения кода или конфигурации — сначала сообщи проблему пользователю и дождись решения.
