#!/usr/bin/env bash
# =========================================================
# Terminux — Ultra-Stable Graphical Installation for Termux
# =========================================================

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 
BOLD='\033[1m'

INSTALL_DIR="$HOME/Terminux"
REPO_URL="https://github.com/aishervin/Terminux.git"

show_header() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "  _____ _____ ____  __  __ ___ _   _ _   ___  __"
  echo " |_   _| ____|  _ \|  \/  |_ _| \ | | | | \ \/ /"
  echo "   | | |  _| | |_) | |\/| || ||  \| | | | |\  / "
  echo "   | | | |___|  _ <| |  | || || |\  | |_| |/  \ "
  echo "   |_| |_____|_| \_\_|  |_|___|_| \_|\___//_/\_\\"
  echo -e "${NC}"
}

show_status() {
  local step_num=$1
  local msg=$2
  local total_steps=5
  local percentage=$((step_num * 100 / total_steps))
  local width=25
  local completed=$((step_num * width / total_steps))
  local remaining=$((width - completed))
  
  # Use \r and no newline to keep it on one line. Clear line first.
  printf "\r\033[K${BOLD}${CYAN}📦 Step $step_num/$total_steps:${NC} $msg [${YELLOW}"
  for ((i=0; i<completed; i++)); do printf "█"; done
  for ((i=0; i<remaining; i++)); do printf " "; done
  printf "${NC}] %d%%" "$percentage"
}

# 1. Update Packages
show_header
show_status 1 "Updating environment..."
if command -v pkg >/dev/null 2>&1; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y nodejs-lts git python termux-api xdg-utils >/dev/null 2>&1 || true
else
  echo -e "\n${RED}⚠️ Not a Termux environment. Manual install required.${NC}"
fi

# 2. Clone/Update Repo
show_status 2 "Syncing Terminux Source Code..."
if [ -d "$INSTALL_DIR" ]; then
  cd "$INSTALL_DIR"
  git pull origin main || true
else
  git clone "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# 3. NPM Install
show_status 3 "Installing dependencies..."
npm install --production=false >/dev/null 2>&1

# 4. Global Launcher
show_status 4 "Creating Shortcut Launcher..."
PREFIX_BIN="/data/data/com.termux/files/usr/bin"
[ ! -d "$PREFIX_BIN" ] && PREFIX_BIN="/usr/local/bin"

if [ -w "$PREFIX_BIN" ] || [ "$EUID" -eq 0 ]; then
  LAUNCHER="$PREFIX_BIN/terminux"
  cat << EOF > "$LAUNCHER"
#!/usr/bin/env bash
export TERMINUX_WORKSPACE="\$HOME/Terminux-workspace"
mkdir -p "\$TERMINUX_WORKSPACE"
cd "$INSTALL_DIR"
npm start
EOF
  chmod +x "$LAUNCHER"
  LAUNCHER_CMD="terminux"
else
  LAUNCHER_CMD="npm start"
fi

# 5. Verify Workspace
show_status 5 "Configuring Workspace..."
mkdir -p "$HOME/Terminux-workspace"

# AUTO-LAUNCH
echo -e "\n"
if [ "$LAUNCHER_CMD" = "terminux" ]; then
  # Use am start for Termux to ensure browser opens if possible
  if command -v termux-open-url >/dev/null 2>&1; then
    (sleep 3 && termux-open-url http://localhost:3000) &
  fi
  terminux
else
  npm start
fi
