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

```
*/5 * * * *  metrika.py enrich --days 2 --limit 100 && scorer.py score
0 22 * * *   metrika.py enrich --days 440 --skip 45 --limit 3500
10 1 * * *   scorer.py train --model all
30 1 * * *   digest.py
```

Логи: `/var/log/ropbot/{pipeline,metrika,scorer,digest}.log`

### Схема БД

Миграции применяются автоматически при запуске. На 20.08.2026 накачено 11:
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
