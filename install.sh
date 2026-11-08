#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ — Professional One-Line Installer (JSON Theme Edition)
set -uo pipefail

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; W=$'\033[37m'; R=$'\033[0m'; D=$'\033[90m'
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

progress() {
  local p=$1; local label=$2; local w=30
  local n=$((p*w/100))
  printf "\r%s[%-*.*s] %3d%% %s%s%s" "$O" "$w" "$n" "##############################" "$p" "$D" "$label" "$R"
}

clear
cat << 'BANNER'
  ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██╗   ██╗██╗  ██╗
  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██║   ██║╚██╗██╔╝
     ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║   ██║ ╚███╔╝ 
     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║   ██║ ██╔██╗ 
     ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝██╔╝ ██╗
     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
     
     TΞRMINUX™ — Official JSON Theme Edition
BANNER

printf "\n\n"
progress 0 "Checking environment..."
mkdir -p "$PREFIX/bin" 2>/dev/null || PREFIX="$HOME/.local"
mkdir -p "$PREFIX/bin"

progress 20 "Installing system dependencies..."
pkg update -y >/dev/null 2>&1 || apt-get update -y >/dev/null 2>&1 || true
pkg install -y curl git nodejs-lts termux-tools dpkg >/dev/null 2>&1 || apt-get install -y curl git nodejs termux-tools dpkg >/dev/null 2>&1 || true

progress 40 "Verifying OpenCode runtime..."
if ! command -v opencode >/dev/null 2>&1; then
  curl -fsSL https://opencode.ai/v2/install | bash >/dev/null 2>&1 || true
fi

progress 60 "Fetching TΞRMINUX themes & launcher..."
TMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/aishervin/Terminux.git "$TMP_DIR/src" >/dev/null 2>&1

progress 80 "Applying JSON theme and configuration..."
THEME_DIR="$HOME/.config/opencode/themes"
mkdir -p "$THEME_DIR"
cp "$TMP_DIR/src/skin/themes/terminux-charcoal.json" "$THEMED_DIR" 2>/dev/null || cp "$TMP_DIR/src/skin/themes/terminux-charcoal.json" "$THEME_DIR/"

# Set default theme in tui.json / cli.json per official docs
CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/tui.json" <<'JSON'
{
  "$schema": "https://opencode.ai/tui.json",
  "theme": "Terminux Charcoal"
}
JSON

cp "$TMP_DIR/src/bin/termunix" "$PREFIX/bin/termunix" 2>/dev/null || cp "$TMP_DIR/src/bin/termunix" "$HOME/.local/bin/termunix"
chmod +x "$PREFIX/bin/termunix" 2>/dev/null || chmod +x "$HOME/.local/bin/termunix"
ln -sf "$PREFIX/bin/termunix" "$PREFIX/bin/Terminux" 2>/dev/null || ln -sf "$HOME/.local/bin/termunix" "$HOME/.local/bin/Terminux"

rm -rf "$TMP_DIR"
progress 100 "Installation complete!"

echo -e "\n\n${G}✔ TΞRMINUX JSON Theme is ready!${R}"
echo -e "${W}Type ${O}Terminux${W} to launch your coding agent.\n"
EOF
