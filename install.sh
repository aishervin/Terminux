#!/usr/bin/env bash
# =========================================================
#  Terminux — one-line installer for Termux
#  bash <(curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh)
# =========================================================
set -e

REPO_URL="https://github.com/aishervin/Terminux.git"
INSTALL_DIR="$HOME/Terminux"
WORKSPACE_DIR="${TERMINUX_WORKSPACE:-$HOME/Terminux-workspace}"
TOTAL=5

if [ -t 1 ]; then
  C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[1m'; D='\033[2m'; R='\033[0m'
else
  C=''; G=''; Y=''; B=''; D=''; R=''
fi

printf "${C}${B}"
cat << 'LOGO'
   _____ _____ ____  __  __ ___ _   _ _   ___  __
  |_   _| ____|  _ \|  \/  |_ _| \ | | | | \ \/ /
    | | |  _| | |_) | |\/| || ||  \| | | | |\  /
    | | | |___|  _ <| |  | || || |\  | |_| |/  \
    |_| |_____|_| \_\_|  |_|___|_| \_|____//_/_\_/
LOGO
printf "${R}"
printf "  ${B}Terminux${R} ${D}· local AI agent for Termux${R}\n"
printf "  ${D}github.com/aishervin/Terminux${R}\n\n"

STEP=0
status() {
  STEP=$((STEP+1))
  local msg="$1"
  local pct=$((STEP*100/TOTAL))
  local width=22
  local filled=$((STEP*width/TOTAL))
  local bar=""
  local i
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=filled; i<width; i++)); do bar+="·"; done
  printf "\r\033[K  ${Y}%s${R} ${B}%s${R} ${D}%3d%%${R}" "$bar" "$msg" "$pct"
}

# 1/5 — environment
status "updating environment"
if command -v pkg >/dev/null 2>&1; then
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y nodejs-lts git termux-api xdg-utils >/dev/null 2>&1 || true
fi

# 2/5 — source code
status "syncing source code"
if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only >/dev/null 2>&1 || true
else
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1
fi

# 3/5 — dependencies
status "installing dependencies"
if ! command -v npm >/dev/null 2>&1; then
  echo ""
  echo "  npm not found — install Node.js first:  pkg install nodejs-lts"
  exit 1
fi
npm install --omit=dev --no-audit --no-fund >/dev/null 2>&1

# 4/5 — launcher shortcut
status "creating launcher"
PREFIX_BIN="/data/data/com.termux/files/usr/bin"
[ -d "$PREFIX_BIN" ] || PREFIX_BIN="/usr/local/bin"
LAUNCHER_CMD="npm start"
if mkdir -p "$PREFIX_BIN" 2>/dev/null && [ -w "$PREFIX_BIN" ]; then
  cat << EOF > "$PREFIX_BIN/terminux"
#!/usr/bin/env bash
export TERMINUX_WORKSPACE="$WORKSPACE_DIR"
mkdir -p "\$TERMINUX_WORKSPACE"
cd "$INSTALL_DIR"
exec npm start
EOF
  chmod +x "$PREFIX_BIN/terminux"
  LAUNCHER_CMD="terminux"
fi

# 5/5 — workspace
status "preparing workspace"
mkdir -p "$WORKSPACE_DIR"

BAR=""
for ((i=0; i<22; i++)); do BAR+="█"; done
printf "\r\033[K  ${Y}%s${R} ${G}${B}ready${R} ${D}100%%${R}\n" "$BAR"
echo ""
printf "  ${G}✔${R} app        ${D}%s${R}\n" "$INSTALL_DIR"
printf "  ${G}✔${R} workspace  ${D}%s${R}\n" "$WORKSPACE_DIR"
printf "  ${G}✔${R} launcher   ${D}%s${R}\n" "$LAUNCHER_CMD"
printf "  ${G}✔${R} interface  ${D}http://localhost:3000${R}\n"
echo ""

# big countdown before first launch
printf "\033[s"
for i in 5 4 3 2 1; do
  printf "\033[u${C}"
  case $i in
    1) printf "     ██ \n     ██ \n     ██ \n     ██ \n     ██ \n";;
    2) printf " █████ \n     ██\n █████ \n ██    \n ██████\n";;
    3) printf " █████ \n     ██\n █████ \n     ██\n █████ \n";;
    4) printf " ██  ██\n ██  ██\n █████ \n     ██\n     ██\n";;
    5) printf " █████ \n ██    \n █████ \n     ██\n █████ \n";;
  esac
  printf "${R}  ${D}opening browser in${R} ${B}${Y}%d${R} ${D}sec …${R}\n" "$i"
  sleep 1
done
printf "\033[u\033[J"
printf "  ${G}${B}starting Terminux …${R}\n\n"

# launch
cd "$INSTALL_DIR"
export TERMINUX_WORKSPACE="$WORKSPACE_DIR"
if command -v termux-open-url >/dev/null 2>&1; then
  ( sleep 3 && termux-open-url http://localhost:3000 >/dev/null 2>&1 ) &
fi
exec npm start