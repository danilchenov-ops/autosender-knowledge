# Интеграции и доступы

Токенов и паролей здесь нет — только где что лежит.

## Яндекс Директ

- Рекламный аккаунт: **synergosmoto**, боевой, общий счёт
- Доступ у Claude: MCP `yandex_direct` (`direct_campaigns`, `direct_report`, `direct_api`)
- Запись включается на маке Тимофея:
  `sed -i '' 's/^YANDEX_DIRECT_ALLOW_WRITE=no/YANDEX_DIRECT_ALLOW_WRITE=yes/' ~/.config/yandex-mcp/.env`
  Сервер читает `.env` на лету, перезапуск не нужен.
- Расход в Директе **с НДС 22 %**, в Метрике — **без НДС**. Всегда указывать базис.

## Яндекс Метрика

- Счётчик **56331115** «Autosender.ru», владелец `synergosmoto`, TZ Asia/Vladivostok
- Доступ у Claude: MCP `yandex_metrika` (чтение).
- Токен с правом записи (scopes `metrika:read`, `metrika:write`, `metrika:offline_data`,
  OAuth-приложение под `synergosmoto`, ClientID `4755aa74…`) — в `/opt/ropbot/.env` →
  `YANDEX_METRIKA_TOKEN`. С 07.09.2026 включён расширенный период офлайн-конверсий
  (`offline_conversions/extended_threshold`). Правило по-прежнему: цели/настройки счётчика
  без «да» Тимофея не менять.
- ~105 городских зеркал вида `<город>.autosender.ru`.
  **`mes.autosender.ru` в списке зеркал НЕ значится** — на сбор данных не влияет.

### Ключевые цели

| Цель | Id | Что |
|---|---|---|
| `sub` | 598775226 | подписка (MAX или Telegram), прокладка |
| `sub_max` / `sub_tg` | см. `metrika_goals` | по каналам |
| Подобрать автомобиль+ | 63078325 | заявка |
| CRM: Заказ создан+ | 255698793 | |
| CRM: Заказ оплачен+ | 255698794 | ценность в Метрике 40 000 ₽, фактическая — 100 000 ₽ |
| **Подписка ТГ** | **609783020** | идентификатор `tg_subscribed`; факт вступления в канал от бота, грузится офлайн-конверсией (`tg_offline.py`). **На эту цель учить подписные кампании.** |
| Unique target call / Unique call | 602708319 / 602708320 | коллтрекинг, появились к 07.09.2026 |

### Сегменты для ретаргетинга

| Сегмент | Id | Размер, 90 дн. |
|---|---|---|
| Калькулятор или избранное без заказа | 1008072855 | 6 621 чел. (не-десктоп 4 529) |
| Вовлечённые без заказа | 1008072850 | 135 099 чел. (не-десктоп 89 625) |

## Яндекс Вебмастер

- Доступ есть с 08.09.2026. OAuth-приложение «Вебмастер» под `synergosmoto`,
  ClientID `eeddb2a7…`, права `webmaster:hostinfo`, `webmaster:verify`.
- Токен — в `/opt/ropbot/.env` → `YANDEX_WEBMASTER_TOKEN`. Отдельного MCP нет:
  ходим в `https://api.webmaster.yandex.net/v4` через curl с сервера ropbot.
- Токен светился в чате при выпуске — **перевыпустить** при случае.
- Зачем: история показов/кликов/позиций по запросам, индексирование, диагностика —
  разбор «тряски» сайта в поиске.

## Google Search Console

- Доступ с 14.09.2026. Ресурс **доменный**: `sc-domain:autosender.ru`, уровень `siteFullUser`.
- Сервисный аккаунт `gsc-reader@autosender-1713165947569.iam.gserviceaccount.com`
  в проекте Google Cloud «Autosender» (`autosender-1713165947569`), там же включён
  Google Search Console API. Права выданы в самом Search Console («Пользователи и
  разрешения»), ролей Google Cloud у аккаунта нет.
- Ключ — `/opt/ropbot/gsc-sa.json` (600, в `.gitignore`). Ключ проходил через чат
  при заведении — **перевыпустить** при случае.
- Инструмент: `/opt/ropbot/tools/gsc.py` (свой venv `/opt/ropbot/venv-gsc`).
  `gsc.py sites` — ресурсы; `gsc.py query --dim query,page --days 28 --limit 200`.
  Разрезы: query, page, country, device, date, searchAppearance. Потолок 25 000 строк.
- **Истории нет:** данные копятся с 11.09.2026, задним числом Google их не отдаёт.
  Ретроспектива до этой даты невозможна — сравнения только вперёд.
- Лаг данных 2-3 дня, поэтому период по умолчанию в скрипте сдвинут на 3 дня назад.

## Битрикс24

- Вебхук в `/opt/ropbot/.env`, переменная `B24_WEBHOOK`
- Используется коллектором Виртуального РОПа для истории звонков

## Telegram

- Канал «Автосендер. Автомобили из Японии, Кореи и Китая», chat_id **-1001774094574**;
  чат обсуждений -2071774094574 (бот там есть, ничего не делает).
- Бот Виртуального РОПа `@ironbossAS_bot` — **администратор канала** с правом
  «пригласительные ссылки». Контейнер `ropbot-tgbot-1`, Bot API через SOCKS-туннель
  `tg-tunnel.service` (127.0.0.1:1080; слушает 0.0.0.0 — проверить файрвол).

### Точный учёт подписок Telegram (с 07.09.2026)

**Цели Метрики `sub` / `sub_tg` / `sub_max` срабатывают на `onclick` кнопки — это
клики, не подписки** (подтверждено кодом прокладки 07.09). Источник правды по
подписчикам — база `rop`, контрольная сумма — `getChatMemberCount` (сошлась с ручным
замером: 6 808 = 6 808).

Как устроено (клик → подписка → Метрика → CRM):

1. Объявления подписных кампаний 713638280 «Горячие» / 713639252 «Вовлечённые» ведут на
   `mes.autosender.ru/?utm_source=direct&utm_medium=cpc&utm_campaign={campaign_id}&utm_content={ad_id}`.
2. Прокладка (v2, сервер 195.2.74.207, `/var/www/mes.autosender.ru/index.html`, бэкап
   `index.html.bak-before-tglinks`): кнопка TG → `ym getClientID` (таймаут 900 мс) →
   `GET /tg/go?c=<кампания>&yclid=&cid=<ClientID>`. Без JS — именованная ссылка кампании.
3. Сервис пула `/opt/tglinks/app.py` на том же сервере (127.0.0.1:8082, sqlite
   `/opt/tglinks/tglinks.db`, юнит `tglinks.service`, nginx `location /tg/`, бэкап конфига
   `/opt/tglinks/nginx.conf.bak-before-tg`) выдаёт **одноразовую персональную ссылку**
   (`member_limit=1`, имя `p<N>`) и запоминает ClientID/yclid/кампанию. Пул пуст → ссылка
   кампании. Состояние: `https://mes.autosender.ru/tg/health`.
4. Ропбот `bin/tg_pool.sh` (cron `*/5`, flock, лог `/var/log/ropbot/tg_pool.log`):
   забирает выданные ссылки с прокладки, доливает пул до 100 (≤40 за прогон, ≈6 с/ссылка),
   пишет `getChatMemberCount` в `tg_channel_counts`. Команды: `app/tg_pool.py import|make N|count|status`.
5. Вступление/выход приходит боту апдейтом `chat_member` (`app/tg_register.py`) →
   `tg_channel_members` с ссылкой, по ней — `client_id`, `yclid`, `campaign`.
6. `app/tg_offline.py` (cron `*/10`, лог `/var/log/ropbot/tg_offline.log`) грузит
   вступления в цель **609783020 «Подписка ТГ»** (`tg_subscribed`) офлайн-конверсией:
   по ClientID, без него — по yclid; ставит `metrika_sent_at`.
7. Путь клиента: вью `v_tg_subscriber_journey` = подписчик → лид (`ym_client_id`) →
   сделка → оплата. Смотреть с октября (лаг 30–90 дней).

Справочник ссылок (`tg_invite_links`): `ads_hot` → Горячие, `ads_involved` → Вовлечённые,
`ads_other` → прокладка без utm, `seed_groups` → посевы вручную, `p<N>` — персональные.
Старая `+WZfPxLy5sD1lZmMy` жива: вступившие по ней = органика/старые размещения
(строка «без ссылки»).

Миграции: `024_tg_channel.sql`, `025_tg_pool.sql`. Бэкапы кода: `tg.py.bak-channel`,
`tg_register.py.bak-channel`, прокладка v1 `/opt/ropbot/tmp/prokladka_index.v1.html`.

```sql
-- подписки по дням и источникам
SELECT day_msk, invite_name, joins, leaves, net FROM v_tg_subs_daily
WHERE day_msk >= current_date - 7 ORDER BY 1,2;
-- сколько вступлений уже привязано к Метрике
SELECT count(*) FILTER (WHERE action='join') joins,
       count(*) FILTER (WHERE action='join' AND client_id IS NOT NULL) with_cid,
       count(*) FILTER (WHERE metrika_sent_at IS NOT NULL) sent
FROM tg_channel_members;
```

**Что дальше:** когда в цели 609783020 будет ≥10–15 конверсий в неделю — переводить
подписные кампании на «Максимум конверсий» по этой цели (сейчас учатся на `sub` = клики).
Еженедельная сверка: `v_tg_subs_daily` против ручного замера канала.

### Замеры подписчиков Telegram

| Дата (MSK) | Подписчиков | Прирост | Метрика `sub_tg` | Сходимость |
|---|---:|---:|---:|---:|
| 18.08.2026 | 6 762 | — | — | — |
| 31.08.2026 | 6 795 | +33 | 47 | 70 % |
| 07.09.2026 | 6 808 | **+13** | 32 | **41 %** |

Сходимость падает (70 % → 41 %), потому что `sub_tg` считает клики: часть кликов до
подписки не доходит. С 07.09 ручной замер нужен только как контроль бота.

## MAX

### Точный учёт подписок MAX (с 07.09.2026)

Бот **BOtmetr** `@id253001266870_bot` (токен `/opt/ropbot/.env` → `MAX_BOT_TOKEN`, канал
`MAX_CHAT_ID=-70996748460165` «Автосендер Автомобили из Японии Китая и Кореи», публичный,
`https://max.ru/channel_autosender`). Добавлен в канал 07.09 подписчиком (не админом).
API: `platform-api2.max.ru`, сертификат Минцифры — Russian Trusted Root CA поставлен на хост ропбота
(`/usr/local/share/ca-certificates/russian_trusted_root_ca.crt`).

**Отличие от TG:** в MAX у канала одна ссылка, персональных нет. Вступление привязывается к клику
на прокладке **по окну времени** (клик за ≤15 мин до вступления, ≤1 мин после). Качество привязки
`match_quality`: `exact` — один клик в окне (ClientID → Метрика); `campaign` — несколько кликов,
все из одной кампании (кампания известна, в Метрику не грузим); `ambiguous` — несколько из разных;
`organic` — кликов не было.

Цепочка:
1. Кнопка MAX на прокладке (`a[data-maxlink]`) → `GET /max/go?c=&yclid=&cid=<ClientID>` → пишет
   клик в sqlite `max_clicks` → 302 на канал. Без JS — прямой href канала.
2. Вебхук Bot API MAX → `POST https://mes.autosender.ru/max/hook` (секрет `/opt/tglinks/max_secret`,
   заголовок `X-Max-Bot-Api-Secret`; в ропботе `MAX_HOOK_SECRET`) → sqlite `max_events`. Подписка
   на `user_added, user_removed, bot_added, bot_removed, bot_started, chat_title_changed`.
   Состояние: `https://mes.autosender.ru/max/health`.
3. `bin/tg_pool.sh` (cron `*/5`, шаг 4): `pooltool.py maxexport` → `app/max_pool.py import`
   (таблицы `max_clicks`, `max_channel_members`, привязка) + `participants_count` →
   `max_channel_counts` (контрольная сумма, как `getChatMemberCount`).
4. `app/tg_offline.py` грузит `exact`-вступления в цель **609807401 «Подписка MAX»**
   (`max_subscribed`, создана через API 07.09) офлайн-конверсией по ClientID / yclid.
5. Вью: `v_max_subs_daily`, `v_max_subscriber_journey`, общая `v_subs_daily` (tg + max).

Миграция `026_max_channel.sql`. Бэкапы: `app.py.bak-before-max`, `pooltool.py.bak-before-max`,
`index.html.bak-before-maxgo`, `nginx.conf.bak-before-max`, `tg_offline.py.bak-before-max`,
`tg_pool.sh.bak-before-max`.

```sql
SELECT day_msk, source, joins, leaves, net FROM v_max_subs_daily WHERE day_msk >= current_date-7 ORDER BY 1,2;
SELECT match_quality, count(*), round(avg(match_delay_s)) avg_delay_s FROM max_channel_members WHERE action='join' GROUP BY 1;
```

**Открыто:** приходит ли `user_added` без прав администратора у бота — проверить по первому
органическому вступлению (≈20/сут). Если за 2 часа событий нет — назначить бота админом.
Окно 15 мин — гипотеза; подобрать по распределению `match_delay_s` через неделю.


- Канал `https://max.ru/channel_autosender`
- ~~Аналитики по ссылкам нет, Bot API не проверен~~ — с 07.09 учёт ведёт бот BOtmetr (см. выше); `sub_max` = клики.
- **Посевы в группах идут постоянно (Тимофей, 31.08.2026)** — прирост канала MAX
  с рекламой сверить нельзя без цифры прироста от посева за тот же период.
  Формула: `подписки с рекламы ≈ прирост канала − прирост от посева + отписки`.
- Замеры по MSK, счётчик живёт по Asia/Vladivostok (+7 ч) — границы периодов не
  совпадают, сутки нерепрезентативны; сверять на интервале от недели.

### Замеры подписчиков MAX

| Дата (MSK) | Подписчиков | Прирост | Метрика `sub_max` | Сходимость | Примечание |
|---|---:|---:|---:|---:|---|
| 31.08.2026 ~08:36 | **2 113** | — | — | — | первая точка (18.08 не зафиксирована) |
| 01.09.2026 ~08:49 | **2 170** | +57 | ≈28 | 2:1 | сутки, нерепрезентативно |
| 03.09.2026 ~06:30 | **2 188** | +18 | ≈72 за 31.08→03.09 (+75) | ~1:1 | клики и посев гасят друг друга |
| 07.09.2026 | **2 208** | **+38** | 177 за 01.09→07.09 | **21 %** | посев работает в плюс — рекламных ещё меньше |

Вывод на 07.09: цена подписчика по факту прироста ≈370 ₽ против 111–146 ₽ по целям;
масштабирование подписных кампаний отозвано (`decisions.md`).

## GitHub (с 13.09.2026)

- Аккаунт: `danilchenov-ops`. Репозитории приватные, ветка `main`.
  - `autosender-knowledge` ← `/opt/knowledge` (реестр)
  - `autosender-ropbot` ← `/opt/ropbot` (код Виртуального РОПа)
- Ключи доступа с ропбот-сервера. **Один ключ на репозиторий** — GitHub не даёт
  использовать один deploy key дважды:
  - `~/.ssh/github` → knowledge, обычный хост `github.com`
  - `~/.ssh/github-ropbot` → ropbot, алиас `github-ropbot` в `~/.ssh/config`
  Оба добавлены как deploy key с правом записи.
- Отзыв доступа: удалить соответствующий ключ в Settings → Deploy keys нужного репозитория.
- Сайт autosender.ru в этот контур НЕ входит: GitLab `Sisyphus-forever/autosender-2025`,
  своя база знаний `/opt/claude-kb` на 83.136.235.210.
