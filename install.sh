#!/usr/bin/env bash
# Terminux — reliable Termux installer
set -Eeuo pipefail
REPO_URL="https://github.com/aishervin/Terminux.git"
INSTALL_DIR="$HOME/Terminux"
WORKSPACE_DIR="${TERMINUX_WORKSPACE:-$HOME/Terminux-workspace}"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
O='\033[38;5;208m' W='\033[97m' G='\033[90m' OK='\033[38;5;114m' E='\033[38;5;203m' R='\033[0m' B='\033[1m'
[[ -t 1 ]] || O='' W='' G='' OK='' E='' R='' B=''
clear 2>/dev/null || true
printf "\n${O}${B}  TERMINUX${R}  ${G}· local AI agent for Termux${R}\n  ${G}────────────────────────────────────────${R}\n\n"
fail(){ printf "\n  ${E}✕ نصب متوقف شد: %s${R}\n" "$*" >&2; exit 1; }
trap 'fail "خطا در خط $LINENO؛ خروجی بالا را بررسی کن."' ERR
step(){ printf "  ${O}━━━━━━━━━━━━━━━━━━━━━━━━${R}  ${W}%s${R}\n" "$1"; }
command -v pkg >/dev/null 2>&1 || fail "این نصب‌کننده مخصوص Termux است."
step "۱/۵ · به‌روزرسانی محیط"
pkg update -y
pkg install -y nodejs-lts git termux-api
step "۲/۵ · دریافت سورس"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" fetch --depth=1 origin main
  git -C "$INSTALL_DIR" reset --hard origin/main
else
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 --branch main "$REPO_URL" "$INSTALL_DIR"
fi
step "۳/۵ · نصب وابستگی‌ها"
[[ -f "$INSTALL_DIR/package.json" ]] || fail "package.json پیدا نشد."
npm install --prefix "$INSTALL_DIR" --omit=dev --no-audit --no-fund
[[ -x "$INSTALL_DIR/node_modules/.bin/tsx" ]] || fail "نصب وابستگی‌ها کامل نشد."
step "۴/۵ · ساخت میانبر"
mkdir -p "$PREFIX_BIN" "$WORKSPACE_DIR"
cat > "$PREFIX_BIN/terminux" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
export TERMINUX_WORKSPACE="$WORKSPACE_DIR"
cd "$INSTALL_DIR"
exec npm start
EOF
chmod 700 "$PREFIX_BIN/terminux"
step "۵/۵ · آماده‌سازی فضای کاری"
printf "\n  ${OK}${B}✓ نصب با موفقیت تمام شد${R}\n"
printf "  ${G}پوشه برنامه: ${R}%s\n  ${G}فضای کاری:  ${R}%s\n  ${G}اجرا:        ${O}terminux${R}\n  ${G}نشانی:      ${W}http://127.0.0.1:3000${R}\n\n" "$INSTALL_DIR" "$WORKSPACE_DIR"
cd "$INSTALL_DIR"
export TERMINUX_WORKSPACE="$WORKSPACE_DIR"
printf "  ${O}در حال راه‌اندازی Terminux…${R}\n"
exec npm start
