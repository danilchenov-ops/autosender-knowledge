# Что изменилось на серверах — 2026-08-29

было: размер базы: 773MB
стало: размер базы: 782MB
было: последний бэкап: /opt/ropbot/backups/full/rop-2026-08-28.sql.gz (28.08 03:01)
стало: последний бэкап: /opt/ropbot/backups/full/rop-2026-08-29.sql.gz (29.08 03:01)
было: - `balance_watch.log` (28.08 06:00):   warnings.warn(
стало: - `balance_watch.log` (29.08 05:45): 2026-08-29 02:45:03,892 INFO [rop] Баланс ProxyAPI: пробный запрос 200, всё в порядке
было: - `control.log` (28.08 05:45): 2026-08-28 02:45:03,224 INFO [rop] Контроль: открыто {'closed_alive': 72, 'going_cold': 15}
было: - `dash.log` (25.08 14:25): Error response from daemon: container 4a59bc3a591ed2e19f7b1d03842033cbc3c255db8c834cea535c65324d6406e0 is not running
стало: - `control.log` (29.08 03:45): 2026-08-29 00:45:03,402 INFO [rop] Контроль: открыто {'going_cold': 17, 'closed_alive': 81}
стало: - `dash.log` (28.08 09:38): SyntaxError: '(' was never closed
было: - `marker.log` (28.08 05:50): 2026-08-28 02:50:18,477 INFO [rop] маркировка: обновлено 0 лидов (ошибок 5)
было: - `metrika.log` (28.08 05:30): 2026-08-28 02:30:05,134 INFO [rop] матчинг по времени: сопоставлено 0, без матча 3
было: - `pipeline.log` (28.08 05:55): 2026-08-28 02:55:04,101 INFO [rop] Миграция применена: 021_qa_a4.sql
было: - `presence.log` (28.08 05:55): 2026-08-28 02:55:09,679 INFO [rop] Присутствие: онлайн 5, отметок в табеле сегодня 0
стало: - `marker.log` (29.08 05:50): 2026-08-29 02:50:17,646 INFO [rop] маркировка: обновлено 1 лидов (ошибок 5)
стало: - `metrika.log` (29.08 05:30):   warnings.warn(
стало: - `pipeline.log` (29.08 06:00):   warnings.warn(
стало: - `presence.log` (29.08 05:55): 2026-08-29 02:55:09,895 INFO [rop] Присутствие: онлайн 3, отметок в табеле сегодня 0
было: - `scorer.log` (28.08 01:10): 2026-08-27 22:10:12,972 INFO [rop] v1: сохранено 48 весов
было: - `smsd.log` (28.08 05:59): 2026-08-28 02:59:01,887 WARNING [rop] статус zUs42_Z46TAPg2K5yfzvf: 404 Client Error: Not Found for url: https://api.sms-gate.app/3rdp
было: - `snapshot.log` (27.08 23:15): 2026-08-27 20:15:20,930 INFO [rop] Слепок 2026-08-28: записано 1275 значений
стало: - `scorer.log` (29.08 01:10): 2026-08-28 22:10:12,738 INFO [rop] v1: сохранено 48 весов
стало: - `smsd.log` (29.08 05:59): 2026-08-29 02:59:01,749 WARNING [rop] статус zUs42_Z46TAPg2K5yfzvf: 404 Client Error: Not Found for url: https://api.sms-gate.app/3rdp
стало: - `snapshot.log` (28.08 23:15): 2026-08-28 20:15:24,336 INFO [rop] Слепок 2026-08-29: записано 1275 значений
было: - `stagehist_fix.log` (28.08 05:43): 2026-08-28 02:43 stagehist_fix: просмотрено 1266, дозаполнено 0
стало: - `stagehist_fix.log` (29.08 05:43): 2026-08-29 02:43 stagehist_fix: просмотрено 1278, дозаполнено 0
стало: - `visual.log` (28.08 16:55): 2026-08-28: 15077=66.6, 11807=91.0, 11357=67.8, 8829=44.8, 8831=120.8
было: done: 5346
было: pending: 4767
было: processing: 3
было: skipped: 105
стало: done: 5837
стало: pending: 4398
стало: processing: 2
стало: skipped: 134
было: v1 A: 361
было: v1 B: 780
было: v1 C: 950
было: v1 D: 1275
было: v2b A: 316
было: v2b B: 584
было: v2b C: 874
было: v2b D: 506
стало: v1 A: 370
стало: v1 B: 815
стало: v1 C: 1010
стало: v1 D: 1311
стало: v2b A: 322
стало: v2b B: 603
стало: v2b C: 905
стало: v2b D: 531
было: /dev/vda1        50G  8.1G   39G  18% /
было:   за неделю manager7@autosender.ru — 247
было:   за неделю manager6@autosender.ru — 160
было:   за неделю manager2@autosender.ru — 156
было:   за неделю manager5@autosender.ru — 147
было:   за неделю manager1@autosender.ru — 136
стало: /dev/vda1        50G  8.2G   39G  18% /
стало:   за неделю manager7@autosender.ru — 241
стало:   за неделю manager6@autosender.ru — 158

_Пусто — значит структурных изменений нет, менялись только числа._
