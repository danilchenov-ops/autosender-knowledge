# Сервисы

## Виртуальный РОП — /opt/ropbot (сервер 5.35.99.93)

Сбор звонков из Битрикс24, локальная расшифровка на faster-whisper, метрики
качества разговоров, скоринг и приоритизация заявок. Аудио не хранится, только текст.

### Контейнеры (docker compose)

| Контейнер | Назначение |
|---|---|
| `ropbot-postgres-1` | база: звонки, расшифровки, метрики, скоры. Слушает только 127.0.0.1 |
| `ropbot-collector-1` | опрос Битрикса каждые 5 минут + бэкфилл истории |
| `ropbot-asr-1`, `ropbot-asr-2` | очередь расшифровки, faster-whisper |
| `ropbot-llm-1` | LLM-обработка |
| `ropbot-tgbot-1` | Telegram-бот |

### Крон (root, сервер 5.35.99.93)

_Актуальный список берётся из `audit/latest.md` (снимается в 06:00). Ниже — тот же
список с пояснениями; при расхождении верить аудиту, реестр — поправить._

| Расписание | Задание | Зачем |
|---|---|---|
| `*/5` | metrika.py enrich --days 45 && scorer.py score | обогащение свежих лидов из Метрики + скоринг |
| `0 22` | metrika.py enrich --days 440 --skip 45 --limit 3500 | ночной backfill старых лидов |
| `*/30` | metrika.py match --limit 400 | матчинг лид↔визит по времени (без ClientID) |
| `10 1` | scorer.py train --model all | переобучение v1/v2b |
| `*/10` | composite.py && marker.py | составная оценка + маркировка в CRM |
| `*/5` | presence.py | кто из менеджеров онлайн |
| `13,43` | stagehist_fix.py --days 3 | дозаполнение истории стадий |
| `15 23` | snapshot.py | ежедневный слепок менеджеров (`manager_snapshot`) |
| `30 23 вс` | profile.py | недельный портрет менеджера |
| `0 3 пн–пт` | bestworst.py | лучший/худший разговор → Светлане |
| `10 2 пн` | qa_advice.py | QA-план на неделю |
| `55 13` | web/visual_daily.py | точки для панелей |
| `* * ` / `*/15` | web/build_now.sh / build.sh (flock) | пересборка панелей менеджеров |
| `*/15` | balance_watch.py | баланс ProxyAPI |
| `*` / `*/15` | smsd.py / sms_watch.py (если есть `/opt/ropbot/sms_on`) | рассылка СМС и сторож телефонов |
| `*/10` | sale_watch.py (в tgbot) | сторож продаж/уведомления |
| `*/5` | bin/tg_pool.sh | пул персональных ссылок TG, импорт MAX, счётчики каналов |
| `*/10` | tg_offline.py (в tgbot) | офлайн-конверсии подписок в Метрику |
| `7 *` | db/asr_priority.sql | приоритет очереди расшифровки |
| `0 3` | db/backup.sh | дамп базы, 7 копий + копия на 195.2.74.207 |
| `40 3 1-го` | lab/prices_models.py | актуальные цены и модели |
| `0 6` | /opt/knowledge/audit.sh | снимок состояния серверов |
| `*/30` | /opt/knowledge/watch.sh | сторож инфраструктуры |
| `0 9 пн` | /opt/knowledge/kbcheck.sh | еженедельный дрейф реестра → бот |

Точные строки крона:

```
*/5 * * * * docker exec ropbot-collector-1 sh -c 'python metrika.py enrich --days 45 --limit 100 && python scorer.py score' >> /var/log/ropbot/pipeline.log 2>&1
0 22 * * * docker exec ropbot-collector-1 python metrika.py enrich --days 440 --skip 45 --limit 3500 >> /var/log/ropbot/metrika.log 2>&1
10 1 * * * docker exec ropbot-collector-1 python scorer.py train --model all >> /var/log/ropbot/scorer.log 2>&1
0 6 * * * /opt/knowledge/audit.sh >/dev/null 2>&1
*/30 * * * * docker exec ropbot-collector-1 python metrika.py match --limit 400 >> /var/log/ropbot/metrika.log 2>&1
0 3 * * * /opt/ropbot/db/backup.sh >> /var/log/ropbot-backup.log 2>&1
*/5 * * * * docker exec ropbot-collector-1 python presence.py >> /var/log/ropbot/presence.log 2>&1
30 23 * * 0 docker exec ropbot-collector-1 python profile.py >> /var/log/ropbot/profile.log 2>&1
7 * * * * cat /opt/ropbot/db/asr_priority.sql | docker exec -i ropbot-postgres-1 psql -U rop -d rop -q >> /var/log/ropbot/asr_priority.log 2>&1
*/10 * * * * docker exec ropbot-collector-1 sh -c "python composite.py --days 90 --limit 300 && python marker.py --limit 300" >> /var/log/ropbot/marker.log 2>&1
40 3 1 * * cd /opt/ropbot && cat lab/prices_models.py | docker exec -i ropbot-collector-1 python - --json > /root/out/actual_prices_models.json 2>>/var/log/ropbot/prices_models.log && cat lab/prices_models.py | docker exec -i ropbot-collector-1 python - --md > /root/out/actual_prices_models.md 2>>/var/log/ropbot/prices_models.log
0 3 * * 1-5 docker exec -i ropbot-collector-1 python - < /opt/ropbot/app/bestworst.py >> /var/log/ropbot/bestworst.log 2>&1
* * * * * flock -n /tmp/dash.lock /opt/ropbot/web/build_now.sh >> /var/log/ropbot/dash.log 2>&1
*/15 * * * * flock -w 55 /tmp/dash.lock /opt/ropbot/web/build.sh >> /var/log/ropbot/dash.log 2>&1
13,43 * * * * docker exec -i ropbot-collector-1 python - --days 3 < /opt/ropbot/app/stagehist_fix.py >> /var/log/ropbot/stagehist_fix.log 2>&1
15 23 * * * docker exec -i ropbot-collector-1 python - < /opt/ropbot/app/snapshot.py >> /var/log/ropbot/snapshot.log 2>&1
10 2 * * 1 docker exec -i ropbot-collector-1 python - < /opt/ropbot/app/qa_advice.py >> /var/log/ropbot/qa_advice.log 2>&1
*/15 * * * * docker exec -i ropbot-collector-1 python - < /opt/ropbot/app/balance_watch.py >> /var/log/ropbot/balance_watch.log 2>&1
*/30 * * * * /opt/knowledge/watch.sh >> /var/log/kbwatch.log 2>&1
* * * * * [ -f /opt/ropbot/sms_on ] && flock -n /tmp/smsd.lock docker exec -i ropbot-collector-1 python - < /opt/ropbot/app/smsd.py >> /var/log/ropbot/smsd.log 2>&1
55 13 * * * docker exec -i ropbot-collector-1 python - < /opt/ropbot/web/visual_daily.py >> /var/log/ropbot/visual.log 2>&1
*/15 * * * * [ -f /opt/ropbot/sms_on ] && flock -n /tmp/sms_watch.lock docker exec -i ropbot-collector-1 python - < /opt/ropbot/app/sms_watch.py >> /var/log/ropbot/sms_watch.log 2>&1
*/10 * * * * docker exec -i ropbot-tgbot-1 python - < /opt/ropbot/app/sale_watch.py >> /var/log/ropbot/sale_watch.log 2>&1
*/5 * * * * flock -n /run/lock/tg_pool.lock /opt/ropbot/bin/tg_pool.sh >> /var/log/ropbot/tg_pool.log 2>&1
*/10 * * * * docker exec -i ropbot-tgbot-1 python - < /opt/ropbot/app/tg_offline.py >> /var/log/ropbot/tg_offline.log 2>&1
```

Крон на хосте идёт по **MSK**; 03:00 MSK = 10:00 Владивосток.
`digest.py` из крона снят 20.08 — вывод скоринга ушёл в CRM, не в телеграм.

Логи: `/var/log/ropbot/{pipeline,metrika,scorer,marker,presence,dash,control,profile,bestworst}.log`

### Схема БД

Миграции применяются автоматически при запуске. На 08.09.2026 — 27 (последняя `027_telega.sql`); на 20.08 было 11:
`001_core`, `002_crm`, `003_views`, `004_metrics`, `005_phone`, `006_llm`,
`007_telegram`, `008_clean`, `009_clients`, `010_call_phone`, `011_scoring`.

### Скоринг заявок

Две модели работают параллельно: **v1** и **v2b**. Таблица `lead_scores`.
За сутки 19–20.08.2026 оценено **3 195 лидов**.

**Замысел, отличия v1/v2b, критерии готовности — не описаны.
Заполнить из чата, где это делалось.**

### Полезные команды

```bash
docker ps
docker compose -f /opt/ropbot/docker-compose.yml logs -f collector
docker exec -it ropbot-postgres-1 psql -U rop -d rop
tail -50 /var/log/ropbot/pipeline.log
```

### Настройки

`/opt/ropbot/.env` — там же `B24_WEBHOOK`, параметры whisper
(`WHISPER_MODEL`, `WHISPER_COMPUTE`, `MIN_CALL_SEC`, `ASR_CPU_LIMIT`).

---

## Страница-прокладка mes.autosender.ru (сервер 195.2.74.207)

Статическая страница подписки на каналы MAX и Telegram. Форм нет.

- Файл: `/var/www/mes.autosender.ru/index.html`
- Счётчик Метрики: **56331115** (общий с основным сайтом)
- Кнопки шлют цели `sub_max` / `sub_tg` и общую `sub`,
  переход в мессенджер через `setTimeout 400 мс` (иначе на мобильных событие теряется)
- Ссылка MAX: `https://max.ru/channel_autosender`
- Ссылка Telegram: `https://t.me/+WZfPxLy5sD1lZmMy` (заменена 20.08.2026)
- `meta robots: noindex, nofollow`

---

## Сторож инфраструктуры — `/opt/knowledge/watch.sh` (сервер 5.35.99.93)

Крон `*/30 * * * *`, лог `/var/log/kbwatch.log`, состояние `/var/lib/kbwatch/`.
Только чтение. **Реестр не правит и править не должен.**

Молчит, пока всё в порядке. Шлёт в `@ironbossAS_bot` Тимофею (chat 460128042)
один раз при поломке и один раз при восстановлении. По понедельникам в 09:00 —
подтверждение, что сторож сам жив.

12 проверок: контейнеры, healthcheck postgres, диск ≥85%, свежесть `pipeline.log`
и `marker.log`, скоринг за 6 часов, движение очереди ASR, `tg-tunnel.service`,
свежесть бэкапа базы, `lead-router` на 195.2.74.207, назначения лидов в будни,
сроки сертификатов.

## Аудит — `/opt/knowledge/audit.sh`

Крон `0 6 * * *`. Пишет `audit/ГГГГ-ММ-ДД.md` (история 60 дней), копию в
`audit/latest.md` и `audit/diff-latest.md` — что структурно изменилось со вчера.
Охватывает оба сервера, включает рабочие числа за сутки, очередь расшифровки,
распределение классов скоринга, назначения lead-router и сроки сертификатов.
Коммитит сам.
