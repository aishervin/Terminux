#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ — Connected Edition (Live Link to GitHub Repo)
set -uo pipefail

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; W=$'\033[37m'; R=$'\033[0m'; D=$'\033[90m'
REPO="https://github.com/aishervin/Terminux.git"

print_step() {
  echo -e "\n${O}==> $1${R}"
}

clear
cat << 'BANNER'
  ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██╗   ██╗██╗  ██╗
  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██║   ██║╚██╗██╔╝
     ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║   ██║ ╚███╔╝ 
     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║   ██║ ██╔██╗ 
     ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝██╔╝ ██╗
     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
     
     TΞRMINUX™ — GitHub Connected Edition
BANNER

print_step "1/5: Preparing Termux environment..."
pkg update -y >/dev/null 2>&1 || true
pkg install -y proot-distro curl git termux-tools >/dev/null 2>&1

print_step "2/5: Synchronizing Ubuntu Container..."
if ! proot-distro list | grep -q "ubuntu.*installed"; then
  proot-distro install ubuntu
fi

print_step "3/5: Connecting to aishervin/Terminux repository..."
proot-distro login ubuntu -- bash << INSIDE
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y >/dev/null 2>&1
  apt-get install -y curl git nodejs npm >/dev/null 2>&1
  
  # Clone or Update the repo inside Ubuntu
  if [ ! -d "~/Terminux" ]; then
    git clone $REPO ~/Terminux
  else
    cd ~/Terminux && git pull origin main
  fi

  # Install OpenCode if missing
  if ! command -v opencode >/dev/null 2>&1; then
    curl -fsSL https://opencode.ai/v2/install | bash
  fi

  # LINK YOUR REPO CONTENT TO OPENCODE
  mkdir -p ~/.config/opencode/skills
  mkdir -p ~/.config/opencode/plugins
  
  # Link skills from your repo to OpenCode skills folder
  if [ -d "~/Terminux/skills" ]; then
    ln -sf ~/Terminux/skills/* ~/.config/opencode/skills/
  fi
INSIDE

print_step "4/5: Installing Smart Launcher..."
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
cat > "$BIN_DIR/termunix" << 'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

if [ "${1:-}" == "update" ]; then
  echo "Updating TΞRMINUX from GitHub..."
  proot-distro login ubuntu -- bash -c "cd ~/Terminux && git pull origin main"
  echo "Update complete."
  exit 0
fi

proot-distro login ubuntu -- bash << 'INNER'
  export PATH="$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
  if ! opencode service status >/dev/null 2>&1; then
    opencode service start >/dev/null 2>&1
    sleep 3
  fi
  LINK=$(opencode pair 2>/dev/null | grep -oE "https?://[^ ]+/auth/connect/[A-Za-z0-9_-]+" | head -1)
  echo "CONNECTION_URL=${LINK:-http://127.0.0.1:49374}" > /tmp/terminux_url.env
INNER

CONNECTION_URL=$(proot-distro login ubuntu -- cat /tmp/terminux_url.env | cut -d= -f2)
termux-open-url "$CONNECTION_URL" || echo "Link: $CONNECTION_URL"
LAUNCHER

chmod +x "$BIN_DIR/termunix"
ln -sf "$BIN_DIR/termunix" "$BIN_DIR/Terminux"

print_step "5/5: Ready!"
echo -e "\n${G}✔ Now connected to GitHub: aishervin/Terminux${R}"
echo -e "To update skills later, just type: ${O}Terminux update${R}\n"
