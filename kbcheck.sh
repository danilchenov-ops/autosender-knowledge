#!/usr/bin/env bash
# Еженедельный контроль дрейфа реестра /opt/knowledge. Только чтение + отчёт в Telegram.
# Cron: 0 9 * * 1 /opt/knowledge/kbcheck.sh >> /var/log/kbcheck.log 2>&1
# 1-го числа дополнительно архивирует прошлый месяц changelog.md.
set -uo pipefail
cd /opt/knowledge
BOSS_CHAT=460128042
PROXY="socks5h://127.0.0.1:1080"
TOKEN=$(grep -E '^TG_BOT_TOKEN=' /opt/ropbot/.env | cut -d= -f2- | tr -d '"'"'"' \r')
NOW=$(date +%s); TODAY=$(date +%F)
R=""   # отчёт
n() { R="${R}$1
"; }

# 1. Свежесть блока «СОСТОЯНИЕ НА» в project-файлах
n "<b>Состояние проектов</b>"
for f in projects/*.md; do
  [ "$f" = projects/README.md ] && continue
  d=$(grep -m1 -oE '^## СОСТОЯНИЕ НА [0-9]{2}\.[0-9]{2}\.[0-9]{4}' "$f" | grep -oE '[0-9]{2}\.[0-9]{2}\.[0-9]{4}')
  last=$(git log -1 --format=%ad --date=short -- "$f")
  if [ -z "$d" ]; then n "⚪ $(basename $f): нет блока «Состояние» (посл. правка $last)"
  else
    age=$(( (NOW - $(date -d "$(echo $d | awk -F. '{print $3"-"$2"-"$1}')" +%s)) / 86400 ))
    if [ "$age" -gt 14 ]; then n "🔴 $(basename $f): состояние от $d ($age дн), правки до $last"
    elif [ "$age" -gt 7 ]; then n "🟡 $(basename $f): состояние от $d ($age дн)"
    fi
  fi
done

# 2. services.md против фактического крона
n ""; n "<b>services.md ↔ крон</b>"
FACT=$(grep -oE '[a-z_]+\.(py|sh|sql)' audit/latest.md | sort -u)
MISS=""
for j in $FACT; do grep -q "$j" services.md || MISS="$MISS $j"; done
[ -n "$MISS" ] && n "🟡 в кроне есть, в services.md нет:$MISS" || n "🟢 совпадает"

# 3. Открытые вопросы
OPEN=$(grep -cE '^[0-9]+\. ' open-questions.md); CLOSED=$(grep -c 'ЗАКРЫТО' open-questions.md)
OQAGE=$(( (NOW - $(git log -1 --format=%at -- open-questions.md)) / 86400 ))
n ""; n "<b>Открытые вопросы:</b> $((OPEN-CLOSED)) открыто, $CLOSED закрыто, файл правился $OQAGE дн назад"

# 4. Inbox
INB=$(ls inbox | grep -v README | wc -l)
[ "$INB" -gt 0 ] && n "🟡 inbox: $INB неразобранных файлов: $(ls inbox | grep -v README | tr '\n' ' ')"

# 5. Размеры
CL=$(wc -l < changelog.md); RK=$(wc -l < projects/reklama.md)
n ""; n "<b>Размеры:</b> changelog $CL строк$( [ $CL -gt 1500 ] && echo ' 🔴 (>1500 — пора архивировать)'), reklama.md $RK строк$( [ $RK -gt 1500 ] && echo ' 🔴')"

# 6. Незакоммиченное
DIRTY=$(git status --porcelain | wc -l)
[ "$DIRTY" -gt 0 ] && n "🔴 незакоммиченных изменений: $DIRTY" || n "🟢 git чистый"

# 7. Архив changelog 1-го числа
if [ "$(date +%d)" = "01" ]; then
  PM=$(date -d "$TODAY -1 day" +%Y-%m)
  if [ ! -f "changelog-$PM.md" ]; then
    { echo "# Журнал изменений — $PM (архив)"; echo; echo "_Текущий журнал — \`changelog.md\`._"; echo; sed -n '/^## /,$p' changelog.md; } > "changelog-$PM.md"
    { sed -n '1,/^## /p' changelog.md | sed '$d'; echo; } > changelog.tmp && mv changelog.tmp changelog.md
    sed -i "s|^Архивы: |Архивы: \`changelog-$PM.md\`, |" changelog.md
    n "📦 changelog за $PM перенесён в changelog-$PM.md"
  fi
fi

# 8. Пишем и шлём
mkdir -p audit; printf '%s' "$R" | sed 's/<[^>]*>//g' > audit/kbcheck-latest.md
git add -A >/dev/null 2>&1; git commit -qm "kbcheck $TODAY" >/dev/null 2>&1 || true
echo "$(date '+%F %T') kbcheck"; printf '%s' "$R" | sed 's/<[^>]*>//g'
[ -n "$TOKEN" ] && curl -s --max-time 25 --proxy "$PROXY" "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -d chat_id="$BOSS_CHAT" -d parse_mode=HTML --data-urlencode "text=<b>Реестр · еженедельная сверка</b> $(date '+%d.%m')
$R
Что делать: открыть чат «Яндекс Метрика+Директ» и сказать «сверь реестр» — Claude закроет пункты." >/dev/null
