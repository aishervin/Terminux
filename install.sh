#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ — resilient Termux installer (OpenCode runs inside Debian/glibc)
set -Eeuo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
BIN_DIR="$PREFIX/bin"
DISTRO="debian"
REPO_URL="https://github.com/aishervin/Terminux.git"
CONFIG_DIR="$HOME/.config/opencode"
PLUGIN_DIR="$CONFIG_DIR/plugins/termunix"
THEME_DIR="$CONFIG_DIR/themes"
LOG_DIR="$HOME/.termunix"
LOG_FILE="$LOG_DIR/install.log"
LOCK_DIR="$LOG_DIR/install.lock"
TMP_DIR=""

ORANGE=$'\033[38;5;208m'; GREEN=$'\033[38;5;114m'; RED=$'\033[38;5;203m'; RESET=$'\033[0m'
log(){ printf "%b[Terminux]%b %s\n" "$ORANGE" "$RESET" "$*" | tee -a "$LOG_FILE"; }
ok(){ printf "%b[✓]%b %s\n" "$GREEN" "$RESET" "$*" | tee -a "$LOG_FILE"; }
die(){ printf "%b[Terminux ERROR]%b %s\n" "$RED" "$RESET" "$*" | tee -a "$LOG_FILE" >&2; exit 1; }
cleanup(){ [ -z "$TMP_DIR" ] || rm -rf "$TMP_DIR"; rmdir "$LOCK_DIR" 2>/dev/null || true; }
trap cleanup EXIT
fail(){ local code=$?; printf '\n[Terminux] Installation stopped (exit %s). Log: %s\n' "$code" "$LOG_FILE" >&2; exit "$code"; }
trap fail ERR

[ -n "${HOME:-}" ] || die "HOME is not set."
if [ -z "${TERMUX_VERSION:-}" ] && [ ! -d /data/data/com.termux/files/usr ]; then
  die "این نصب‌کننده باید داخل برنامه Termux اجرا شود."
fi
case "$(uname -m)" in aarch64|arm64|x86_64|amd64) ;; *) die "معماری پشتیبانی‌نشده: $(uname -m)" ;; esac
mkdir -p "$LOG_DIR"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then die "نصب دیگری در حال اجراست؛ چند لحظه صبر کن."; fi
: > "$LOG_FILE"

command -v pkg >/dev/null 2>&1 || die "مدیر بسته Termux (pkg) پیدا نشد."
command -v proot-distro >/dev/null 2>&1 || {
  log "Installing proot-distro..."
  pkg update -y >>"$LOG_FILE" 2>&1
  pkg install -y proot-distro >>"$LOG_FILE" 2>&1
}
for cmd in curl git; do
  command -v "$cmd" >/dev/null 2>&1 || {
    log "Installing $cmd..."
    pkg install -y "$cmd" >>"$LOG_FILE" 2>&1
  }
done
command -v proot-distro >/dev/null 2>&1 || die "proot-distro نصب نشد."

if ! proot-distro list 2>/dev/null | grep -Eq '(^|[[:space:]])debian([[:space:]]|$)'; then
  log "Installing Debian Linux environment (first run may take a while)..."
  proot-distro install "$DISTRO" >>"$LOG_FILE" 2>&1 || die "نصب Debian ناموفق بود. گزارش: $LOG_FILE"
else
  log "Debian environment already exists."
fi

linux(){
  proot-distro login "$DISTRO" --shared-tmp -- "$@"
}

log "Preparing Debian and required runtime packages..."
linux apt-get update >>"$LOG_FILE" 2>&1
linux env DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git bash procps coreutils grep sed gawk >>"$LOG_FILE" 2>&1

if ! linux sh -lc 'command -v opencode >/dev/null 2>&1 && opencode --version >/dev/null 2>&1'; then
  log "Installing the Linux-compatible OpenCode runtime..."
  linux bash -lc 'curl -fsSL https://opencode.ai/v2/install | bash' >>"$LOG_FILE" 2>&1 || die "OpenCode install failed. See $LOG_FILE"
fi
linux bash -lc 'command -v opencode >/dev/null && opencode --version' >>"$LOG_FILE" 2>&1 || die "OpenCode does not run in Debian. See $LOG_FILE"

log "Downloading Terminux files..."
TMP_DIR="$(mktemp -d)"
git clone --depth 1 --branch main "$REPO_URL" "$TMP_DIR/repo" >>"$LOG_FILE" 2>&1 || die "GitHub download failed."
SRC="$TMP_DIR/repo"
[ -s "$SRC/bin/termunix" ] || die "Launcher file is missing."
[ -s "$SRC/skin/dist/gui-experimental.cjs" ] || die "Desktop GUI plugin bundle is missing."
[ -s "$SRC/skin/themes/terminux-charcoal.json" ] || die "Theme file is missing."

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$PLUGIN_DIR" "$THEME_DIR"
install -m 0755 "$SRC/bin/termunix" "$BIN_DIR/termunix"
ln -sf "$BIN_DIR/termunix" "$BIN_DIR/Terminux"
install -m 0644 "$SRC/skin/dist/gui-experimental.cjs" "$PLUGIN_DIR/gui-experimental.cjs"
install -m 0644 "$SRC/skin/themes/terminux-charcoal.json" "$THEME_DIR/terminux-charcoal.json"

[ -x "$BIN_DIR/termunix" ] || die "Launcher verification failed."
linux bash -lc 'opencode --version' >/dev/null 2>&1 || die "Final OpenCode verification failed."
ok "Terminux نصب شد؛ OpenCode در Debian اجرا می‌شود تا خطای باینری اندروید/Termux رخ ندهد."
printf '\nبرای باز کردن رابط: %bTerminux%b\n' "$ORANGE" "$RESET"
printf 'وضعیت: Terminux status | گزارش: %s\n' "$LOG_FILE"
printf '\nنکته: پوستهٔ GUI فعلی فقط روی OpenCode Desktop اعمال می‌شود؛ مرورگر فعلاً رابط استاندارد OpenCode را نشان می‌دهد.\n'
