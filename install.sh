#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPOSITORY="aishervin/Terminux"
BRANCH="main"
APP_DIR="$HOME/.local/share/terminux"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

if ! command -v pkg >/dev/null 2>&1; then
  printf '%s\n' "این نصب‌گر باید داخل Termux اجرا شود." >&2
  printf '%s\n' "نسخهٔ Termux را از F-Droid یا GitHub نصب کن، نه Google Play." >&2
  exit 1
fi

printf '%s\n' "۱/۳ نصب Python و ابزارهای لازم..."
pkg install -y python curl tar termux-tools

printf '%s\n' "۲/۳ دریافت Termux Shell Agent از GitHub..."
ARCHIVE_URL="https://codeload.github.com/${REPOSITORY}/tar.gz/refs/heads/${BRANCH}"
curl -fsSL "$ARCHIVE_URL" -o "$TEMP_DIR/source.tar.gz"
tar -xzf "$TEMP_DIR/source.tar.gz" -C "$TEMP_DIR"
mkdir -p "$APP_DIR"
cp -R "$TEMP_DIR/Terminux-${BRANCH}/." "$APP_DIR/"

printf '%s\n' "۳/۳ راه‌اندازی ایجنت محلی..."
printf '%s\n' "صفحهٔ چت در مرورگر باز می‌شود. برای توقف، در Termux کلید Ctrl+C را بزن."
exec python "$APP_DIR/app.py" --open-browser
