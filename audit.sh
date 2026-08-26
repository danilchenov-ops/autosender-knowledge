#!/bin/bash
# Снимок фактического состояния инфраструктуры Autosender. Только чтение.
# Крон: 0 6 * * * /opt/knowledge/audit.sh
#
# Пишет audit/YYYY-MM-DD.md (история) и audit/latest.md (последний).
# Реестр НЕ правит: расхождение снимка с реестром — сигнал для человека,
# а не повод молча подогнать реестр под факт.

cd /opt/knowledge || exit 1
DAY=$(date '+%Y-%m-%d')
OUT="audit/$DAY.md"
REMOTE="root@195.2.74.207"
SSH="ssh -i /root/.ssh/relay -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes"
PSQL="docker exec ropbot-postgres-1 psql -U rop -d rop -tAc"

q() { $PSQL "$1" 2>/dev/null | tr -d ' '; }

{
  echo "# Снимок состояния — $(date '+%Y-%m-%d %H:%M %Z')"
  echo
  echo "## Сервер 5.35.99.93 — обработка"
  echo
  echo "### Диск и база"
  echo '```'
  df -h / | tail -1
  echo "размер базы: $(q "select pg_size_pretty(pg_database_size('rop'))")"
  echo "таблиц в базе: $(q "select count(*) from information_schema.tables where table_schema='public'")"
  LASTBK=$(find /opt/ropbot/backups -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1)
  echo "последний бэкап: $(echo "$LASTBK" | cut -d' ' -f2-) ($(date -d @$(echo "$LASTBK" | cut -d' ' -f1 | cut -d. -f1) '+%d.%m %H:%M' 2>/dev/null))"
  echo '```'
  echo
  echo "### Контейнеры"
  docker ps --format '| {{.Names}} | {{.Status}} | {{.Image}} |' 2>/dev/null
  echo
  echo "### Крон root"
  echo '```'
  crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$'
  echo '```'
  echo
  echo "### Слушающие порты"
  echo '```'
  ss -tlnp 2>/dev/null | awk 'NR>1{print $4}' | sort -u
  echo '```'
  echo
  echo "### Службы"
  for s in tg-tunnel.service docker.service; do
    echo "- $s: $(systemctl is-active $s 2>/dev/null)"
  done
  echo
  echo "### Логи — последняя строка каждого"
  for f in /var/log/ropbot/*.log; do
    [ -f "$f" ] && echo "- \`$(basename "$f")\` ($(date -d @$(stat -c %Y "$f") '+%d.%m %H:%M')): $(tail -1 "$f" | cut -c1-140)"
  done
  echo
  echo "## Рабочие числа за сутки"
  echo
  echo "| Показатель | Значение |"
  echo "|---|---:|"
  echo "| Новых лидов | $(q "select count(*) from leads where date_create > now() - interval '24 hours'") |"
  echo "| Оценено скорингом | $(q "select count(*) from lead_scores where scored_at > now() - interval '24 hours'") |"
  echo "| Собрано звонков | $(q "select count(*) from calls where call_start > now() - interval '24 hours'") |"
  echo "| Расшифровано | $(q "select count(*) from asr_queue where status='done' and updated_at > now() - interval '24 hours'") |"
  echo "| Разобрано моделью | $(q "select count(*) from call_extractions where created_at > now() - interval '24 hours'") |"
  echo
  echo "### Очередь расшифровки"
  echo '```'
  $PSQL "select status||': '||count(*) from asr_queue group by status order by 1" 2>/dev/null
  echo '```'
  echo
  echo "### Скоринг — распределение классов, накоплено всего"
  echo '```'
  $PSQL "select model_version||' '||coalesce(grade,'?')||': '||count(*) from lead_scores group by model_version, grade order by 1" 2>/dev/null | head -12
  echo '```'
  echo
  echo "## Сервер 195.2.74.207 — то, что смотрит наружу"
  echo
  echo '```'
  $SSH "$REMOTE" '
    echo "lead-router: $(systemctl is-active lead-router)"
    echo "nginx: $(systemctl is-active nginx)"
    df -h / | tail -1
    python3 -c "
import sqlite3
c=sqlite3.connect(\"/opt/lead-router/state.db\")
print(\"назначений за сутки:\", c.execute(\"select count(*) from assignments where created_at > datetime(\x27now\x27,\x27-1 day\x27)\").fetchone()[0])
print(\"назначений всего:\", c.execute(\"select count(*) from assignments\").fetchone()[0])
for r in c.execute(\"select email, count(*) from assignments where created_at > datetime(\x27now\x27,\x27-7 day\x27) group by 1 order by 2 desc\"):
    print(\"  за неделю\", r[0], \"—\", r[1])
" 2>/dev/null
    echo "--- сертификаты ---"
    for d in /etc/letsencrypt/live/*/; do
      n=$(basename $d)
      e=$(openssl x509 -enddate -noout -in $d/cert.pem 2>/dev/null | cut -d= -f2)
      [ -n "$e" ] && echo "$n: до $(date -d "$e" "+%d.%m.%Y") ($(( ( $(date -d "$e" +%s) - $(date +%s) ) / 86400 )) дн)"
    done
  ' 2>&1
  echo '```'
  echo
  echo "---"
  echo
  echo "_Снято автоматически. Расхождения с реестром разбирает человек:_"
  echo "_реестр — что задумано, снимок — что есть на самом деле._"
} > "$OUT"

cp "$OUT" audit/latest.md

# Что изменилось со вчера — коротким списком, чтобы не читать снимок целиком
YEST="audit/$(date -d yesterday '+%Y-%m-%d').md"
if [ -f "$YEST" ]; then
  {
    echo "# Что изменилось на серверах — $DAY"
    echo
    diff <(grep -vE '^# Снимок|^- \`|^\| Показатель|Up |назначений|^\|.*\| *[0-9]+ \|' "$YEST") \
         <(grep -vE '^# Снимок|^- \`|^\| Показатель|Up |назначений|^\|.*\| *[0-9]+ \|' "$OUT") \
      | grep -E '^[<>]' | sed 's/^</было:/;s/^>/стало:/' | head -60
    echo
    echo "_Пусто — значит структурных изменений нет, менялись только числа._"
  } > audit/diff-latest.md
fi

# Оставляем 60 снимков, старые чистим
ls -1 audit/[0-9]*.md 2>/dev/null | sort | head -n -60 | xargs -r rm -f

git add -A
git commit -qm "audit $DAY" 2>/dev/null
exit 0
