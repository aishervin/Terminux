#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ reliable Termux installer
set -Eeuo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
BIN_DIR="$PREFIX/bin"
CONFIG_DIR="$HOME/.config/opencode"
PLUGIN_DIR="$CONFIG_DIR/plugins/termunix"
THEME_DIR="$CONFIG_DIR/themes"
REPO="https://github.com/aishervin/Terminux.git"
TMP_DIR=""

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; R=$'\033[0m'
log() { printf "%b[Terminux]%b %s\n" "$O" "$R" "$*"; }
die() { printf "%b[Terminux] ERROR:%b %s\n" "$O" "$R" "$*" >&2; exit 1; }
cleanup() { [ -z "$TMP_DIR" ] || rm -rf "$TMP_DIR"; }
trap cleanup EXIT

[ -n "${HOME:-}" ] || die "HOME is not set."
[ -d /data/data/com.termux/files/usr ] || [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ] || die "Run this installer inside Termux."
mkdir -p "$BIN_DIR" "$CONFIG_DIR"

log "Checking dependencies..."
if command -v pkg >/dev/null 2>&1; then
  missing=()
  for cmd in curl git; do command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd"); done
  [ "${#missing[@]}" -eq 0 ] || pkg install -y "${missing[@]}" || die "Could not install required packages."
  command -v node >/dev/null 2>&1 || pkg install -y nodejs-lts || die "Node.js installation failed."
else
  command -v curl >/dev/null 2>&1 || die "curl is required."
  command -v git >/dev/null 2>&1 || die "git is required."
fi

export PATH="$HOME/.opencode/bin:$BIN_DIR:$HOME/.local/bin:$PATH"
if ! command -v opencode >/dev/null 2>&1; then
  log "Installing OpenCode v2..."
  curl -fsSL https://opencode.ai/v2/install | bash || die "OpenCode installation failed."
  export PATH="$HOME/.opencode/bin:$BIN_DIR:$HOME/.local/bin:$PATH"
fi
command -v opencode >/dev/null 2>&1 || die "OpenCode binary not found after installation."
opencode --version >/dev/null 2>&1 || die "OpenCode is installed but cannot execute on this device."

log "Downloading Terminux..."
TMP_DIR="$(mktemp -d)"
git clone --depth 1 --branch main "$REPO" "$TMP_DIR/repo" >/dev/null 2>&1 || die "GitHub download failed."
SRC="$TMP_DIR/repo"
[ -s "$SRC/bin/termunix" ] || die "Launcher file is missing."
[ -s "$SRC/skin/dist/gui-experimental.cjs" ] || die "Built GUI plugin is missing; installation aborted."
[ -s "$SRC/skin/themes/terminux-charcoal.json" ] || die "Theme file is missing."

log "Installing GUI plugin, theme and launcher..."
mkdir -p "$PLUGIN_DIR" "$THEME_DIR"
install -m 0644 "$SRC/skin/dist/gui-experimental.cjs" "$PLUGIN_DIR/gui-experimental.cjs"
install -m 0644 "$SRC/skin/themes/terminux-charcoal.json" "$THEME_DIR/terminux-charcoal.json"
install -m 0755 "$SRC/bin/termunix" "$BIN_DIR/termunix"
ln -sf "$BIN_DIR/termunix" "$BIN_DIR/Terminux"

[ -s "$PLUGIN_DIR/gui-experimental.cjs" ] || die "Plugin installation verification failed."
[ -x "$BIN_DIR/termunix" ] || die "Launcher installation verification failed."

printf "\n%b✓ Terminux installed successfully.%b\n" "$G" "$R"
printf "Run: Terminux\n"
printf "Commands: link | status | restart | stop | update | uninstall\n"
