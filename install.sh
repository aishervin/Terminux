#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ — Bulletproof Zero-to-Hero Installer for Termux
set -uo pipefail

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; W=$'\033[37m'; R=$'\033[0m'; D=$'\033[90m'

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
     
     TΞRMINUX™ — Zero-to-Hero Ubuntu Engine for Termux
BANNER

print_step "1/5: Checking Termux base packages..."
pkg update -y >/dev/null 2>&1 || true
pkg install -y proot-distro curl git termux-tools >/dev/null 2>&1

print_step "2/5: Setting up Ubuntu Linux container (Proot)..."
if ! proot-distro list | grep -q "ubuntu.*installed"; then
  echo "Installing Ubuntu container (this may take a minute)..."
  proot-distro install ubuntu
else
  echo "Ubuntu container already installed."
fi

print_step "3/5: Installing OpenCode and dependencies inside Ubuntu..."
# We use a heredoc to run multiple commands inside the container
proot-distro login ubuntu -- bash << 'INSIDE'
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y >/dev/null 2>&1
  apt-get install -y curl git nodejs npm build-essential >/dev/null 2>&1
  
  if ! command -v opencode >/dev/null 2>&1; then
    curl -fsSL https://opencode.ai/v2/install | bash
  fi
INSIDE

print_step "4/5: Installing TΞRMINUX launcher into Termux..."
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/termunix" << 'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

# Run everything inside Ubuntu container securely
proot-distro login ubuntu -- bash << 'INNER'
  export PATH="$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
  
  # Ensure OpenCode server is running
  if ! opencode service status >/dev/null 2>&1; then
    echo "Starting OpenCode service..."
    opencode service start >/dev/null 2>&1
    sleep 3
  fi
  
  # Generate pair link
  LINK=$(opencode pair 2>/dev/null | grep -oE "https?://[^ ]+/auth/connect/[A-Za-z0-9_-]+" | head -1)
  if [ -n "$LINK" ]; then
    echo "CONNECTION_URL=$LINK" > /tmp/terminux_url.env
  else
    echo "CONNECTION_URL=http://127.0.0.1:49374" > /tmp/terminux_url.env
  fi
INNER

# Copy the env file out of the container or read it via cat
CONNECTION_URL=$(proot-distro login ubuntu -- cat /tmp/terminux_url.env | cut -d= -f2)

echo -e "\033[38;5;114m✔ OpenCode is up!\033[0m"
echo -e "Opening browser..."
if [ -n "${CONNECTION_URL:-}" ]; then
  termux-open-url "$CONNECTION_URL" || echo "Open this link: $CONNECTION_URL"
fi
LAUNCHER

chmod +x "$BIN_DIR/termunix"
ln -sf "$BIN_DIR/termunix" "$BIN_DIR/Terminux"

print_step "5/5: Finalizing setup..."
echo -e "\n${G}✔ Installation completed successfully!${R}"
echo -e "${W}Type ${O}Terminux${W} anytime to launch your coding agent.\n"
