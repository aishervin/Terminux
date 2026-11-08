#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ — Professional One-Line Installer
set -uo pipefail

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; W=$'\033[37m'; R=$'\033[0m'; D=$'\033[90m'

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
     
     TΞRMINUX™ — Professional Edition for Termux
BANNER

printf "\n\n"
progress 0 "Checking environment..."
case "$PREFIX" in
  *com.termux*) ;;
  *) echo -e "\n\033[31mError: This installer is designed for Termux only.\033[0m"; exit 1 ;;
esac

progress 20 "Installing system dependencies..."
pkg update -y >/dev/null 2>&1 || true
pkg install -y curl git nodejs-lts termux-tools dpkg >/dev/null 2>&1

progress 40 "Verifying OpenCode runtime..."
if ! command -v opencode >/dev/null 2>&1; then
  curl -fsSL https://opencode.ai/v2/install | bash >/dev/null 2>&1 || true
fi

progress 60 "Fetching TΞRMINUX package..."
TMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/aishervin/Terminux.git "$TMP_DIR/src" >/dev/null 2>&1

progress 80 "Applying skin and commands..."
PLUGIN_DIR="$HOME/.config/opencode/plugins/termunix"
mkdir -p "$PLUGIN_DIR"
cp "$TMP_DIR/src/skin/dist/gui-experimental.cjs" "$PLUGIN_DIR/"
cat > "$PLUGIN_DIR/package.json" <<'JSON'
{"name":"opencode-termunix-skin","version":"0.2.0","type":"module","exports":{"./gui-experimental":"./gui-experimental.cjs"}}
JSON

cp "$TMP_DIR/src/bin/termunix" "$PREFIX/bin/termunix"
chmod +x "$PREFIX/bin/termunix"
ln -sf "$PREFIX/bin/termunix" "$PREFIX/bin/Terminux"

rm -rf "$TMP_DIR"
progress 100 "Installation complete!"

echo -e "\n\n${G}✔ TΞRMINUX is ready to use!${R}"
echo -e "${W}Type ${O}Terminux${W} to launch your coding agent.\n"
