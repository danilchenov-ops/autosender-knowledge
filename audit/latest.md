# Снимок состояния — 2026-08-24 06:00 MSK

## Диск
/dev/vda3        79G   14G   62G  19% /

## Docker
| ropbot-llm-1 | Up 12 hours | ropbot-llm |
| ropbot-collector-1 | Up 24 hours | ropbot-collector |
| ropbot-asr-2 | Up 10 hours | ropbot-asr |
| ropbot-asr-1 | Up 11 hours | ropbot-asr |
| ropbot-tgbot-1 | Up 3 days | ropbot-tgbot |
| ropbot-postgres-1 | Up 5 days (healthy) | postgres:16-alpine |

## Крон root
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
*/15 * * * * flock -n /tmp/dash.lock /opt/ropbot/web/build.sh >> /var/log/ropbot/dash.log 2>&1

## Слушающие порты
0.0.0.0:1080
0.0.0.0:22
0.0.0.0:443
0.0.0.0:80
127.0.0.1:5432
127.0.0.1:8077
127.0.0.53%lo:53
127.0.0.54:53
[::]:22
[::]:443
[::]:80

## Логи ropbot — последняя строка каждого
- asr_priority.log: 
- bestworst.log: 2026-08-24 00:00:45,084 INFO [rop] лучший/худший → 7487296664: 30892 / 25017, ok=True
- certbot_retry.log: Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for mo
- cert_hunt.log: nginx: configuration file /etc/nginx/nginx.conf test is successful
- composite_backfill.log: готово Sat Aug 22 05:03:16 PM MSK 2026
- control.log: 2026-08-24 02:15:07,247 INFO [rop] Контроль: открыто {'going_cold': 39, 'closed_alive': 56}
- dash.log: UnboundLocalError: cannot access local variable 'nav_block' where it is not associated with a value
- digest.log: 2026-08-19 22:30:01,917 INFO [rop] дайджест отправлен: 3 чатов
- marker.log: 2026-08-24 02:50:13,010 INFO [rop] маркировка: обновлено 0 лидов (ошибок 1)
- metrika.log: 2026-08-24 02:30:20,280 INFO [rop] матчинг по времени: сопоставлено 0, без матча 1
- pipeline.log: 2026-08-24 02:55:05,360 INFO [rop] Миграция применена: 017_traits.sql
- presence.log: 2026-08-24 02:55:11,079 INFO [rop] Присутствие: онлайн 7, отметок в табеле сегодня 0
- profile.log: 2026-08-23 20:30:41,439 ERROR [rop] Отправка в 460128042: sendMessage: Bad Request: message is too long
- rebuild_once.log: 
- scorer.log: 2026-08-23 22:11:06,226 INFO [rop] v1: сохранено 47 весов

## Оценено лидов за 24 часа
186
