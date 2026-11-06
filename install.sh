#!/data/data/com.termux/files/usr/bin/bash
# Terminux installer — graphical Termux setup
# Usage: curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash

set -uo pipefail

REPO_URL="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"
INSTALL_DIR="${TERMINUX_DIR:-$HOME/Terminux}"
WORKSPACE_DIR="${TERMINUX_WORKSPACE:-$HOME/Terminux-workspace}"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
TERMUX_BASH="${PREFIX:-/data/data/com.termux/files/usr}/bin/bash"

# ── colors (disable if not a TTY) ──────────────────────────────────
if [[ -t 1 ]]; then
  O=$'\033[38;5;208m'; W=$'\033[97m'; D=$'\033[90m'
  OK=$'\033[38;5;114m'; E=$'\033[38;5;203m'; C=$'\033[36m'
  B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
else
  O= W= D= OK= E= C= B= R= DIM=
fi

SPIN_PID=""
PROGRESS=0
TOTAL_STEPS=5

cleanup() {
  stop_spinner
  tput cnorm 2>/dev/null || true
}
trap cleanup EXIT
trap 'fail "نصب با سیگنال قطع شد."' INT TERM

fail() {
  stop_spinner
  printf "\n\n  ${E}${B}✕ نصب متوقف شد${R}\n  ${E}%s${R}\n\n" "$*" >&2
  exit 1
}

# ── spinner ────────────────────────────────────────────────────────
spin_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
start_spinner() {
  local msg="${1:-در حال کار…}"
  stop_spinner
  [[ -t 1 ]] || { printf "  %s\n" "$msg"; return; }
  tput civis 2>/dev/null || true
  (
    i=0
    while true; do
      printf "\r  ${O}${spin_frames[i]}${R}  ${W}%s${R}  " "$msg"
      i=$(( (i + 1) % ${#spin_frames[@]} ))
      sleep 0.08
    done
  ) &
  SPIN_PID=$!
}

stop_spinner() {
  if [[ -n "${SPIN_PID:-}" ]] && kill -0 "$SPIN_PID" 2>/dev/null; then
    kill "$SPIN_PID" 2>/dev/null || true
    wait "$SPIN_PID" 2>/dev/null || true
  fi
  SPIN_PID=""
  [[ -t 1 ]] && printf "\r\033[K" || true
}

# ── progress bar ───────────────────────────────────────────────────
draw_bar() {
  local pct="$1" label="${2:-}"
  local width=28
  local filled=$(( pct * width / 100 ))
  (( filled > width )) && filled=$width
  local empty=$(( width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty; i++ )); do bar+="░"; done
  if [[ -t 1 ]]; then
    printf "\r  ${D}[${O}%s${D}]${R} ${W}%3d%%${R}  ${DIM}%s${R}\033[K" "$bar" "$pct" "$label"
  else
    printf "  [%s] %3d%%  %s\n" "$bar" "$pct" "$label"
  fi
}

step_done() {
  local n="$1" title="$2"
  PROGRESS=$(( n * 100 / TOTAL_STEPS ))
  stop_spinner
  draw_bar "$PROGRESS" ""
  printf "\n  ${OK}✓${R}  ${W}%s${R}\n" "$title"
}

# ── banner ─────────────────────────────────────────────────────────
banner() {
  clear 2>/dev/null || true
  printf "%s\n" "${O}${B}"
  cat << 'ASCII'
      ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██╗   ██╗██╗  ██╗
      ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██║   ██║╚██╗██╔╝
         ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║   ██║ ╚███╔╝
         ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║   ██║ ██╔██╗
         ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝██╔╝ ██╗
         ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
ASCII
  printf "%s" "${R}"
  printf "  ${D}────────────────────────────────────────────────────────${R}\n"
  printf "  ${W}${B}local AI coding agent${R}  ${D}·${R}  ${O}SHΞN™${R}  ${D}·${R}  ${C}Termux${R}\n"
  printf "  ${D}────────────────────────────────────────────────────────${R}\n\n"
}

run_quiet() {
  # run command, capture output; on failure show last lines
  local log
  log="$(mktemp 2>/dev/null || echo /tmp/terminux-install.log)"
  if "$@" >"$log" 2>&1; then
    rm -f "$log" 2>/dev/null || true
    return 0
  fi
  local code=$?
  stop_spinner
  printf "\n  ${E}خروجی خطا:${R}\n"
  tail -n 25 "$log" 2>/dev/null | sed 's/^/    /' >&2 || true
  rm -f "$log" 2>/dev/null || true
  return "$code"
}

# ── preflight ──────────────────────────────────────────────────────
banner
command -v pkg >/dev/null 2>&1 || fail "این نصب‌کننده فقط روی Termux کار می‌کند (دستور pkg پیدا نشد)."

printf "  ${D}مسیر نصب:${R}  ${W}%s${R}\n" "$INSTALL_DIR"
printf "  ${D}فضای کاری:${R} ${W}%s${R}\n\n" "$WORKSPACE_DIR"
draw_bar 0 "شروع…"
printf "\n"

# ── 1/5 packages ───────────────────────────────────────────────────
start_spinner "۱/۵  به‌روزرسانی و نصب بسته‌ها (nodejs git)…"
if ! run_quiet pkg update -y; then
  # soft-fail update; still try install
  true
fi
if ! run_quiet pkg install -y nodejs-lts git; then
  # fallback package names used on some Termux mirrors
  run_quiet pkg install -y nodejs git || fail "نصب nodejs/git ناموفق بود. خروجی بالا را بررسی کن."
fi
command -v node >/dev/null 2>&1 || fail "node بعد از نصب پیدا نشد."
command -v npm  >/dev/null 2>&1 || fail "npm بعد از نصب پیدا نشد."
command -v git  >/dev/null 2>&1 || fail "git بعد از نصب پیدا نشد."
step_done 1 "محیط Termux آماده شد  (node $(node -v 2>/dev/null | tr -d '\n'))"

# ── 2/5 source ─────────────────────────────────────────────────────
start_spinner "۲/۵  دریافت سورس از GitHub…"
mkdir -p "$(dirname "$INSTALL_DIR")"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  if ! run_quiet git -C "$INSTALL_DIR" fetch --depth 1 origin "$BRANCH"; then
    fail "git fetch ناموفق بود. اتصال اینترنت یا دسترسی به GitHub را چک کن."
  fi
  # reset to remote main to avoid ff-only failures on dirty trees
  run_quiet git -C "$INSTALL_DIR" checkout -f -B "$BRANCH" "origin/$BRANCH" \
    || run_quiet git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" \
    || fail "به‌روزرسانی مخزن محلی ناموفق بود."
else
  rm -rf "$INSTALL_DIR"
  run_quiet git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR" \
    || fail "کلون مخزن ناموفق بود: $REPO_URL"
fi
[[ -f "$INSTALL_DIR/package.json" ]] || fail "package.json در $INSTALL_DIR پیدا نشد."
[[ -f "$INSTALL_DIR/src/server.ts" ]] || fail "src/server.ts پیدا نشد — کلون ناقص است."
step_done 2 "سورس دریافت شد"

# ── 3/5 npm ────────────────────────────────────────────────────────
start_spinner "۳/۵  نصب وابستگی‌های npm (ممکن است چند دقیقه طول بکشد)…"
# prefer full install so tsx stays available; omit optional noise
if ! run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund; then
  # retry once clean
  rm -rf "$INSTALL_DIR/node_modules" "$INSTALL_DIR/package-lock.json"
  run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund \
    || fail "npm install ناموفق بود."
fi
if [[ ! -x "$INSTALL_DIR/node_modules/.bin/tsx" ]] && [[ ! -f "$INSTALL_DIR/node_modules/tsx/dist/cli.mjs" ]]; then
  fail "tsx نصب نشد. npm install را دستی در $INSTALL_DIR بررسی کن."
fi
step_done 3 "وابستگی‌ها نصب شدند"

# ── 4/5 launcher ───────────────────────────────────────────────────
start_spinner "۴/۵  ساخت میانبر terminux…"
mkdir -p "$PREFIX_BIN" "$WORKSPACE_DIR" || fail "ساخت پوشه bin/workspace ناموفق بود."
cat > "$PREFIX_BIN/terminux" <<EOF
#!${TERMUX_BASH}
# Terminux launcher
export TERMINUX_WORKSPACE="${WORKSPACE_DIR}"
cd "${INSTALL_DIR}" || exit 1
if [[ -x ./node_modules/.bin/tsx ]]; then
  exec ./node_modules/.bin/tsx src/server.ts
fi
exec npm start
EOF
chmod 700 "$PREFIX_BIN/terminux" || fail "chmod میانبر ناموفق بود."
command -v terminux >/dev/null 2>&1 || export PATH="$PREFIX_BIN:$PATH"
step_done 4 "میانبر «terminux» آماده شد"

# ── 5/5 workspace ──────────────────────────────────────────────────
start_spinner "۵/۵  آماده‌سازی فضای کاری…"
mkdir -p "$WORKSPACE_DIR" \
  "$HOME/.config/terminux" \
  "$INSTALL_DIR/workspace" 2>/dev/null || true
# light touch so first boot is clean
: >> "$WORKSPACE_DIR/.terminux_ready" 2>/dev/null || true
step_done 5 "فضای کاری آماده شد"

# ── done ───────────────────────────────────────────────────────────
stop_spinner
draw_bar 100 "تمام"
printf "\n\n"
printf "  ${OK}${B}✓ نصب Terminux با موفقیت تمام شد${R}\n\n"
printf "  ${D}پوشه برنامه${R}   ${W}%s${R}\n" "$INSTALL_DIR"
printf "  ${D}فضای کاری${R}    ${W}%s${R}\n" "$WORKSPACE_DIR"
printf "  ${D}اجرا${R}          ${O}${B}terminux${R}\n"
printf "  ${D}نشانی وب${R}     ${C}http://127.0.0.1:3000${R}\n\n"
printf "  ${D}────────────────────────────────────────────────────────${R}\n"
printf "  ${O}▶${R}  در حال راه‌اندازی سرور…\n\n"

cd "$INSTALL_DIR" || fail "ورود به $INSTALL_DIR ممکن نشد."
export TERMINUX_WORKSPACE="$WORKSPACE_DIR"
export PATH="$PREFIX_BIN:$PATH"

if [[ -x ./node_modules/.bin/tsx ]]; then
  exec ./node_modules/.bin/tsx src/server.ts
fi
exec npm start
