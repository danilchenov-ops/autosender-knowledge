# Снимок состояния — 2026-08-22 06:00 MSK

## Диск
/dev/vda3        79G   12G   64G  16% /

## Docker
| ropbot-collector-1 | Up 15 hours | ropbot-collector |
| ropbot-llm-1 | Up 15 hours | ropbot-llm |
| ropbot-asr-2 | Up 37 hours | ropbot-asr |
| ropbot-asr-1 | Up 37 hours | ropbot-asr |
| ropbot-tgbot-1 | Up 37 hours | ropbot-tgbot |
| ropbot-postgres-1 | Up 3 days (healthy) | postgres:16-alpine |

## Крон root
*/5 * * * * docker exec ropbot-collector-1 sh -c 'python metrika.py enrich --days 2 --limit 100 && python scorer.py score' >> /var/log/ropbot/pipeline.log 2>&1
0 22 * * * docker exec ropbot-collector-1 python metrika.py enrich --days 440 --skip 45 --limit 3500 >> /var/log/ropbot/metrika.log 2>&1
10 1 * * * docker exec ropbot-collector-1 python scorer.py train --model all >> /var/log/ropbot/scorer.log 2>&1
0 6 * * * /opt/knowledge/audit.sh >/dev/null 2>&1
*/30 * * * * docker exec ropbot-collector-1 python metrika.py match --limit 400 >> /var/log/ropbot/metrika.log 2>&1
0 3 * * * /opt/ropbot/db/backup.sh >> /var/log/ropbot-backup.log 2>&1
*/5 * * * * docker exec ropbot-collector-1 python presence.py >> /var/log/ropbot/presence.log 2>&1
30 23 * * 0 docker exec ropbot-collector-1 python profile.py >> /var/log/ropbot/profile.log 2>&1
7 * * * * cat /opt/ropbot/db/asr_priority.sql | docker exec -i ropbot-postgres-1 psql -U rop -d rop -q >> /var/log/ropbot/asr_priority.log 2>&1
*/10 * * * * docker exec ropbot-collector-1 sh -c "python composite.py --days 90 --limit 300 && python marker.py --limit 300" >> /var/log/ropbot/marker.log 2>&1

## Слушающие порты
0.0.0.0:1080
0.0.0.0:22
127.0.0.1:5432
127.0.0.53%lo:53
127.0.0.54:53
[::]:22

## Логи ropbot — последняя строка каждого
- asr_priority.log: 
- composite_backfill.log: готово Fri Aug 21 03:31:17 PM MSK 2026
- digest.log: 2026-08-19 22:30:01,917 INFO [rop] дайджест отправлен: 3 чатов
- marker.log: 2026-08-22 02:50:14,244 INFO [rop] Миграция применена: 015_ideal.sql
- metrika.log:   warnings.warn(
- pipeline.log: 2026-08-22 02:55:17,388 INFO [rop] Миграция применена: 015_ideal.sql
- presence.log: 2026-08-22 02:55:23,832 INFO [rop] Присутствие: онлайн 3, отметок в табеле сегодня 0
- scorer.log: 2026-08-21 22:10:35,454 INFO [rop] v1: сохранено 48 весов

## Оценено лидов за 24 часа
1999
