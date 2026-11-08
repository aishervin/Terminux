#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ — Professional Installer
set -uo pipefail

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; W=$'\033[37m'; R=$'\033[0m'; D=$'\033[90m'

# Progress bar function
progress() {
  local p=$1; local label=$2; local w=30
  local n=$((p*w/100))
  printf "\r%s[%-*.*s] %3d%% %s%s%s" "$O" "$w" "$n" "##############################" "$p" "$D" "$label" "$R"
}

clear
cat assets/banner.txt

printf "\n\n"
progress 0 "Initializing..."
pkg update -y >/dev/null 2>&1
progress 20 "Installing deps..."
pkg install -y curl git nodejs-lts termux-tools >/dev/null 2>&1
progress 40 "Configuring OpenCode..."
if ! command -v opencode >/dev/null 2>&1; then
  curl -fsSL https://opencode.ai/v2/install | bash >/dev/null 2>&1
fi
progress 60 "Setting up TΞRMINUX..."
REPO="https://github.com/aishervin/Terminux.git"
SRC_DIR="$HOME/.termunix/src"
mkdir -p "$SRC_DIR"
git clone --depth 1 "$REPO" "$SRC_DIR" >/dev/null 2>&1 || git -C "$SRC_DIR" pull >/dev/null 2>&1
PLUGIN_DIR="$HOME/.config/opencode/plugins/termunix"
mkdir -p "$PLUGIN_DIR"
cp "$SRC_DIR/skin/dist/gui-experimental.cjs" "$PLUGIN_DIR/"
progress 80 "Finalizing commands..."
cp "$SRC_DIR/bin/termunix" "$PREFIX/bin/termunix"
chmod +x "$PREFIX/bin/termunix"
ln -sf "$PREFIX/bin/termunix" "$PREFIX/bin/Terminux"
progress 100 "Done!"

echo -e "\n\n${G}✔ TΞRMINUX installed successfully!${R}"
echo -e "${W}Start by typing: ${O}Terminux${R}\n"
