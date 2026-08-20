#!/bin/bash
# Снимок фактического состояния сервера. Только чтение.
cd /opt/knowledge || exit 1
OUT=audit/latest.md
{
  echo "# Снимок состояния — $(date '+%Y-%m-%d %H:%M %Z')"
  echo
  echo "## Диск"
  df -h / | tail -1
  echo
  echo "## Docker"
  docker ps --format '| {{.Names}} | {{.Status}} | {{.Image}} |' 2>/dev/null
  echo
  echo "## Крон root"
  crontab -l 2>/dev/null | grep -v '^#'
  echo
  echo "## Слушающие порты"
  ss -tlnp 2>/dev/null | awk 'NR>1{print $4}' | sort -u
  echo
  echo "## Логи ropbot — последняя строка каждого"
  for f in /var/log/ropbot/*.log; do
    [ -f "$f" ] && echo "- $(basename "$f"): $(tail -1 "$f" | cut -c1-160)"
  done
  echo
  echo "## Оценено лидов за 24 часа"
  docker exec ropbot-postgres-1 psql -U rop -d rop -tAc \
    "select count(*) from lead_scores where scored_at > now() - interval '24 hours'" 2>/dev/null
} > "$OUT"
git add -A
git commit -qm "audit $(date '+%Y-%m-%d %H:%M')" 2>/dev/null
exit 0
