#!/bin/bash
# Сторож инфраструктуры Autosender. Только чтение + алерты в Telegram.
# Молчит, пока всё в порядке. Пишет один раз при поломке и один раз при выздоровлении.
# Крон: */30 * * * * /opt/knowledge/watch.sh
#
# Реестр НЕ трогает. Он только сигналит — решение и запись всегда за человеком.

set -o pipefail
STATE_DIR=/var/lib/kbwatch
STATE="$STATE_DIR/state"
PREV="$STATE_DIR/prev"
COUNT="$STATE_DIR/count"
mkdir -p "$STATE_DIR"
: > "$STATE"

BOSS_CHAT=460128042                      # Тимофей, @Tim_danilchen
PROXY="socks5h://127.0.0.1:1080"
TOKEN=$(grep -E '^TG_BOT_TOKEN=' /opt/ropbot/.env | cut -d= -f2- | tr -d '"'"'"' \r')
REMOTE="root@195.2.74.207"
SSH="ssh -i /root/.ssh/relay -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes"

ok()  { echo "$1|OK|$2"   >> "$STATE"; }
bad() { echo "$1|BAD|$2"  >> "$STATE"; }

# ── 1. Контейнеры ────────────────────────────────────────────────────────────
EXPECTED="ropbot-postgres-1 ropbot-collector-1 ropbot-asr-1 ropbot-asr-2 ropbot-llm-1 ropbot-tgbot-1"
RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null)
DOWN=""
for c in $EXPECTED; do
  echo "$RUNNING" | grep -qx "$c" || DOWN="$DOWN $c"
done
if [ -n "$DOWN" ]; then bad containers "контейнеры лежат:$DOWN"; else ok containers ""; fi

HEALTH=$(docker inspect ropbot-postgres-1 --format '{{.State.Health.Status}}' 2>/dev/null)
if [ "$HEALTH" = "healthy" ]; then ok pg_health ""; else bad pg_health "postgres не healthy: ${HEALTH:-нет ответа}"; fi

# ── 2. Диск ──────────────────────────────────────────────────────────────────
USE=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if [ "${USE:-0}" -ge 85 ]; then bad disk "диск занят ${USE}%"; else ok disk ""; fi

# ── 3. Свежесть кронов по логам ──────────────────────────────────────────────
fresh() { # файл, минут, имя
  local f=$1 lim=$2 name=$3
  if [ ! -f "$f" ]; then bad "$name" "нет лога $f"; return; fi
  local age=$(( ( $(date +%s) - $(stat -c %Y "$f") ) / 60 ))
  if [ "$age" -gt "$lim" ]; then bad "$name" "$name молчит $age мин (норма до $lim)"; else ok "$name" ""; fi
}
fresh /var/log/ropbot/pipeline.log 25 pipeline
fresh /var/log/ropbot/marker.log   40 marker

# ── 4. Скоринг реально идёт ──────────────────────────────────────────────────
SCORED=$(docker exec ropbot-postgres-1 psql -U rop -d rop -tAc \
  "select count(*) from lead_scores where scored_at > now() - interval '6 hours'" 2>/dev/null | tr -dc '0-9')
if [ -z "$SCORED" ]; then bad scoring "не смог опросить базу по скорингу"
elif [ "$SCORED" -eq 0 ]; then bad scoring "скоринг встал: 0 оценок за 6 часов"
else ok scoring ""; fi

# ── 5. Очередь расшифровки движется ──────────────────────────────────────────
ASR=$(docker exec ropbot-postgres-1 psql -U rop -d rop -tAc \
  "select count(*) filter (where status='pending'), count(*) filter (where status='done' and updated_at > now() - interval '6 hours') from asr_queue" 2>/dev/null)
PEND=$(echo "$ASR" | cut -d'|' -f1 | tr -dc '0-9')
DONE6=$(echo "$ASR" | cut -d'|' -f2 | tr -dc '0-9')
if [ -n "$PEND" ] && [ "$PEND" -gt 0 ] && [ "${DONE6:-0}" -eq 0 ]; then
  bad asr "расшифровка стоит: в очереди $PEND, за 6 часов ноль готовых"
else ok asr ""; fi

# ── 6. Туннель до Telegram ───────────────────────────────────────────────────
if systemctl is-active --quiet tg-tunnel.service; then ok tunnel ""; else bad tunnel "tg-tunnel.service не работает — бот и алерты немы"; fi

# ── 7. Бэкап базы свежий ─────────────────────────────────────────────────────
LASTBK=$(find /opt/ropbot/backups -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
if [ -z "$LASTBK" ]; then bad backup "бэкапов базы нет вообще"
else
  BKAGE=$(( ( $(date +%s) - $(stat -c %Y "$LASTBK") ) / 3600 ))
  if [ "$BKAGE" -gt 30 ]; then bad backup "последний бэкап базы $BKAGE часов назад"; else ok backup ""; fi
fi

# ── 8. Второй сервер: lead-router ────────────────────────────────────────────
RSTAT=$($SSH "$REMOTE" 'systemctl is-active lead-router' 2>/dev/null)
if [ "$RSTAT" = "active" ]; then ok router ""
elif [ -z "$RSTAT" ]; then bad router "195.2.74.207 не отвечает по ssh"
else bad router "lead-router не работает: $RSTAT — лиды не раздаются"; fi

DOW=$(date +%u)
if [ "$DOW" -le 5 ] && [ "$RSTAT" = "active" ]; then
  ASG=$($SSH "$REMOTE" "python3 -c \"import sqlite3; print(sqlite3.connect('/opt/lead-router/state.db').execute(\\\"select count(*) from assignments where created_at > datetime('now','-1 day')\\\").fetchone()[0])\"" 2>/dev/null | tr -dc '0-9')
  if [ -n "$ASG" ] && [ "$ASG" -eq 0 ]; then bad assignments "будни, а lead-router за сутки не назначил ни одного лида"; else ok assignments ""; fi
else ok assignments ""; fi

# ── 9. Сертификаты ───────────────────────────────────────────────────────────
CERTS=$($SSH "$REMOTE" 'for d in /etc/letsencrypt/live/*/; do n=$(basename $d); e=$(openssl x509 -enddate -noout -in $d/cert.pem 2>/dev/null | cut -d= -f2); [ -n "$e" ] && echo "$n $(( ( $(date -d "$e" +%s) - $(date +%s) ) / 86400 ))"; done' 2>/dev/null)
EXPIRING=$(echo "$CERTS" | awk '$2 < 14 && $2 != "" {printf "%s (%s дн) ", $1, $2}')
if [ -n "$EXPIRING" ]; then bad certs "сертификаты истекают: $EXPIRING"; else ok certs ""; fi

# ── Сравнение с прошлым прогоном и отправка ──────────────────────────────────
send() {
  [ -z "$TOKEN" ] && return
  curl -s --max-time 25 --proxy "$PROXY" \
    "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="$BOSS_CHAT" -d parse_mode=HTML --data-urlencode "text=$1" >/dev/null
}

MSG=""
while IFS='|' read -r key st txt; do
  [ -z "$key" ] && continue
  was=$(grep "^$key|" "$PREV" 2>/dev/null | cut -d'|' -f2)
  if [ "$st" = "BAD" ] && [ "$was" != "BAD" ]; then
    MSG="${MSG}🔴 ${txt}
"
    echo "$(date '+%F %T') BAD $key: $txt" >> "$COUNT"
  elif [ "$st" = "OK" ] && [ "$was" = "BAD" ]; then
    MSG="${MSG}🟢 восстановилось: ${key}
"
  fi
done < "$STATE"

if [ -n "$MSG" ]; then
  send "<b>Autosender · сторож</b>
$(date '+%d.%m %H:%M')

${MSG}
Реестр не изменён — сверь и запиши руками, если это новая норма."
fi

# ── Понедельник 09:00: подтверждение, что сторож жив ─────────────────────────
if [ "$(date +%u)" = "1" ] && [ "$(date +%H)" = "09" ] && [ "$(date +%M)" -lt 30 ]; then
  WEEK=$(awk -v d="$(date -d '7 days ago' '+%Y-%m-%d')" '$1 >= d' "$COUNT" 2>/dev/null | wc -l)
  send "<b>Autosender · сторож жив</b>
Проверок в обороте: $(wc -l < "$STATE"). Срабатываний за неделю: ${WEEK}."
fi

cp "$STATE" "$PREV"
exit 0
