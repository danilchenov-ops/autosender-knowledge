# Снимок состояния — 2026-08-21 06:00 MSK

## Диск
/dev/vda3        79G   12G   64G  15% /

## Docker
| ropbot-collector-1 | Up 12 hours | ropbot-collector |
| ropbot-llm-1 | Up 12 hours | ropbot-llm |
| ropbot-asr-2 | Up 13 hours | ropbot-asr |
| ropbot-asr-1 | Up 13 hours | ropbot-asr |
| ropbot-tgbot-1 | Up 13 hours | ropbot-tgbot |
| ropbot-postgres-1 | Up 2 days (healthy) | postgres:16-alpine |

## Крон root
*/5 * * * * docker exec ropbot-collector-1 sh -c 'python metrika.py enrich --days 2 --limit 100 && python scorer.py score' >> /var/log/ropbot/pipeline.log 2>&1
0 22 * * * docker exec ropbot-collector-1 python metrika.py enrich --days 440 --skip 45 --limit 3500 >> /var/log/ropbot/metrika.log 2>&1
10 1 * * * docker exec ropbot-collector-1 python scorer.py train --model all >> /var/log/ropbot/scorer.log 2>&1
0 6 * * * /opt/knowledge/audit.sh >/dev/null 2>&1
*/10 * * * * docker exec ropbot-collector-1 python marker.py --limit 300 >> /var/log/ropbot/marker.log 2>&1
*/30 * * * * docker exec ropbot-collector-1 python metrika.py match --limit 400 >> /var/log/ropbot/metrika.log 2>&1
0 3 * * * /opt/ropbot/db/backup.sh >> /var/log/ropbot-backup.log 2>&1
*/5 * * * * docker exec ropbot-collector-1 python presence.py >> /var/log/ropbot/presence.log 2>&1
30 23 * * 0 docker exec ropbot-collector-1 python profile.py >> /var/log/ropbot/profile.log 2>&1
7 * * * * cat /opt/ropbot/db/asr_priority.sql | docker exec -i ropbot-postgres-1 psql -U rop -d rop -q >> /var/log/ropbot/asr_priority.log 2>&1

## Слушающие порты
0.0.0.0:1080
0.0.0.0:22
127.0.0.1:5432
127.0.0.53%lo:53
127.0.0.54:53
[::]:22

## Логи ropbot — последняя строка каждого
- asr_priority.log: 
- digest.log: 2026-08-19 22:30:01,917 INFO [rop] дайджест отправлен: 3 чатов
- marker.log: 2026-08-21 02:50:28,608 INFO [rop] маркировка: обновлено 1 лидов (ошибок 0)
- metrika.log: 2026-08-21 02:30:33,406 INFO [rop] матчинг по времени: сопоставлено 1, без матча 0
- pipeline.log: 2026-08-21 02:55:27,690 INFO [rop] v1: оценено лидов 1
- presence.log: 2026-08-21 02:55:33,995 INFO [rop] Присутствие: онлайн 6, отметок в табеле сегодня 0
- scorer.log: 2026-08-20 22:10:13,719 INFO [rop] v1: сохранено 48 весов

## Оценено лидов за 24 часа
452
