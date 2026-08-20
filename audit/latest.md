# Снимок состояния — 2026-08-20 07:29 MSK

## Диск
/dev/vda3        79G   11G   64G  15% /

## Docker
| ropbot-collector-1 | Up 13 hours | ropbot-collector |
| ropbot-asr-1 | Up 13 hours | ropbot-asr |
| ropbot-asr-2 | Up 13 hours | ropbot-asr |
| ropbot-tgbot-1 | Up 13 hours | ropbot-tgbot |
| ropbot-llm-1 | Up 13 hours | ropbot-llm |
| ropbot-postgres-1 | Up 44 hours (healthy) | postgres:16-alpine |

## Крон root
*/5 * * * * docker exec ropbot-collector-1 sh -c 'python metrika.py enrich --days 2 --limit 100 && python scorer.py score' >> /var/log/ropbot/pipeline.log 2>&1
0 22 * * * docker exec ropbot-collector-1 python metrika.py enrich --days 440 --skip 45 --limit 3500 >> /var/log/ropbot/metrika.log 2>&1
10 1 * * * docker exec ropbot-collector-1 python scorer.py train --model all >> /var/log/ropbot/scorer.log 2>&1
30 1 * * * docker exec ropbot-collector-1 python digest.py >> /var/log/ropbot/digest.log 2>&1

## Слушающие порты
0.0.0.0:1080
0.0.0.0:22
127.0.0.1:5432
127.0.0.53%lo:53
127.0.0.54:53
[::]:22

## Логи ropbot — последняя строка каждого
- digest.log: 2026-08-19 22:30:01,917 INFO [rop] дайджест отправлен: 3 чатов
- metrika.log: 2026-08-19 19:05:44,186 ERROR [rop] Метрика: 5 ошибок подряд, стоп
- pipeline.log: 2026-08-20 04:25:02,196 INFO [rop] Миграция применена: 011_scoring.sql
- scorer.log: 2026-08-19 22:10:07,638 INFO [rop] v1: сохранено 48 весов

## Оценено лидов за 24 часа
3195
