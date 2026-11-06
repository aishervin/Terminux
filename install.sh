#!/data/data/com.termux/files/usr/bin/bash
# Terminux installer - Professional Termux Setup
# Usage: curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash

set -uo pipefail

# Configuration
REPO_URL="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"
INSTALL_DIR="${TERMINUX_DIR:-$HOME/Terminux}"
WORKSPACE_DIR="${TERMINUX_WORKSPACE:-$HOME/Terminux-workspace}"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
TERMUX_BASH="${PREFIX:-/data/data/com.termux/files/usr}/bin/bash"

# Colors
if [[ -t 1 ]]; then
  O=$'\033[38;5;208m'; W=$'\033[97m'; D=$'\033[90m'
  OK=$'\033[38;5;114m'; E=$'\033[38;5;203m'; C=$'\033[36m'
  B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
  P=$'\033[38;5;196m'; Y=$'\033[38;5;226m'
else
  O= W= D= OK= E= C= B= R= DIM= P= Y=
fi

# Global variables
SPIN_PID=""
PROGRESS=0
TOTAL_STEPS=5

# Cleanup function
cleanup() {
  stop_spinner
  tput cnorm 2>/dev/null || true
}

trap cleanup EXIT

# Fail function
fail() {
  stop_spinner
  printf "\n\n  ${E}${B}✗ Installation Failed${R}\n  ${E}%s${R}\n\n" "$*" >&2
  exit 1
}

# Spinner frames
spin_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# Start spinner
start_spinner() {
  local msg="${1:-Processing...}"
  stop_spinner
  [[ -t 1 ]] || { printf "  %s\n" "$msg"; return; }
  tput civis 2>/dev/null || true
  (
    i=0
    while true; do
      printf "\r  ${O}${spin_frames[i]}${R}  ${W}%s${R}  " "$msg"
      i=$(( (i + 1) % ${#spin_frames[@]} ))
      sleep 0.08
    done
  ) &
  SPIN_PID=$!
}

# Stop spinner
stop_spinner() {
  if [[ -n "${SPIN_PID:-}" ]] && kill -0 "$SPIN_PID" 2>/dev/null; then
    kill "$SPIN_PID" 2>/dev/null || true
    wait "$SPIN_PID" 2>/dev/null || true
  fi
  SPIN_PID=""
  [[ -t 1 ]] && printf "\r\033[K" || true
}

# Progress bar
draw_bar() {
  local pct="$1" label="${2:-}"
  local width=28
  local filled=$(( pct * width / 100 ))
  (( filled > width )) && filled=$width
  local empty=$(( width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty; i++ )); do bar+="░"; done
  if [[ -t 1 ]]; then
    printf "\r  ${D}[${O}%s${D}]${R} ${W}%3d%%${R}  ${DIM}%s${R}\033[K" "$bar" "$pct" "$label"
  else
    printf "  [%s] %3d%%  %s\n" "$bar" "$pct" "$label"
  fi
}

# Step completion
step_done() {
  local n="$1" title="$2"
  PROGRESS=$(( n * 100 / TOTAL_STEPS ))
  stop_spinner
  draw_bar "$PROGRESS" ""
  printf "\n  ${OK}✓${R}  ${W}%s${R}\n" "$title"
}

# Pixel Art Banner
show_banner() {
  clear 2>/dev/null || true
  
  # ASCII Art for Terminux
  printf "${P}${B}"
  cat << 'ASCII'
     █████████████████████████████████████████████
    ██████████████████████████████████████████
   ██████████████████████████████████████████
  ███████████████████████████████████████████
 █████████████████████████████████████████████
███████████████████████████████████████████████
 █████████████████████████████████████████████
  █████████████████████████████████████████
   ███████████████████████████████████████
    ████████████████████████████████████
     ██████████████████████████████████
ASCII
  printf "${R}"
  
  # Header
  printf "  ${D}════════════════════════════════════════════════════════════${R}\n"
  printf "  ${W}${B}         TERMINUX - Local AI Coding Agent${R}\n"
  printf "  ${D}════════════════════════════════════════════════════════════${R}\n\n"
  
  # Info
  printf "  ${W}Install Dir:${R}   ${C}%s${R}\n" "$INSTALL_DIR"
  printf "  ${W}Workspace:${R}   ${C}%s${R}\n\n" "$WORKSPACE_DIR"
}

# Run command quietly
run_quiet() {
  local log
  log="$(mktemp 2>/dev/null || echo /tmp/terminux-install.log)"
  local code=0
  "$@" >"$log" 2>&1 || code=$?
  if [[ "$code" -eq 0 ]]; then
    rm -f "$log" 2>/dev/null || true
    return 0
  fi
  stop_spinner
  printf "\n  ${E}Error occurred:${R}\n"
  tail -n 25 "$log" 2>/dev/null | sed 's/^/    /' >&2 || true
  rm -f "$log" 2>/dev/null || true
  return "$code"
}

# Main installation
show_banner

# Check for pkg
command -v pkg >/dev/null 2>&1 || fail "pkg not found. Please install Termux first."

printf "  ${D}Starting installation...${R}\n\n"
draw_bar 0 "Initializing..."
printf "\n"

# Step 1: Update and install packages
start_spinner "Step 1/5  Updating packages and installing dependencies (nodejs, git)..."
if ! run_quiet pkg update -y; then
  true
fi
if ! run_quiet pkg install -y nodejs-lts git; then
  run_quiet pkg install -y nodejs git || fail "Failed to install nodejs/git. Please check your Termux setup."
fi
command -v node >/dev/null 2>&1 || fail "node not found after installation."
command -v npm  >/dev/null 2>&1 || fail "npm not found after installation."
command -v git  >/dev/null 2>&1 || fail "git not found after installation."
step_done 1 "Termux environment ready (node $(node -v 2>/dev/null | tr -d '\n'))"

# Step 2: Clone repository
start_spinner "Step 2/5  Cloning Terminux from GitHub..."
mkdir -p "$(dirname "$INSTALL_DIR")"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  if ! run_quiet git -C "$INSTALL_DIR" fetch --depth 1 origin "$BRANCH"; then
    fail "git fetch failed. Please check your internet connection."
  fi
  run_quiet git -C "$INSTALL_DIR" checkout -f -B "$BRANCH" "origin/$BRANCH" \
    || run_quiet git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" \
    || fail "Failed to update existing repository."
else
  rm -rf "$INSTALL_DIR"
  run_quiet git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR" \
    || fail "Failed to clone repository: $REPO_URL"
fi
[[ -f "$INSTALL_DIR/package.json" ]] || fail "package.json not found in $INSTALL_DIR"
[[ -f "$INSTALL_DIR/src/server.ts" ]] || fail "src/server.ts not found - clone may have failed."
step_done 2 "Source code downloaded successfully"

# Step 3: Install npm dependencies
start_spinner "Step 3/5  Installing npm dependencies (this may take a while)..."
if ! run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund; then
  rm -rf "$INSTALL_DIR/node_modules"
  run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund \
    || fail "npm install failed."
fi
if [[ ! -x "$INSTALL_DIR/node_modules/.bin/tsx" ]] && [[ ! -f "$INSTALL_DIR/node_modules/tsx/dist/cli.mjs" ]]; then
  fail "tsx not found. npm install may have failed in $INSTALL_DIR"
fi
step_done 3 "Dependencies installed successfully"

# Step 4: Create launcher script
start_spinner "Step 4/5  Creating terminux launcher..."
mkdir -p "$PREFIX_BIN" "$WORKSPACE_DIR" || fail "Failed to create bin/workspace directories."
cat > "$PREFIX_BIN/terminux" <<EOF
#!${TERMUX_BASH}
# Terminux launcher
export TERMINUX_WORKSPACE="${WORKSPACE_DIR}"
cd "${INSTALL_DIR}" || exit 1
while true; do
  if [[ -x ./node_modules/.bin/tsx ]]; then ./node_modules/.bin/tsx src/server.ts; else npm start; fi
  code=\$?
  [[ \$code -eq 75 ]] || exit \$code
  echo "→ Restarting Terminux..."
  sleep 1
done
EOF
chmod 700 "$PREFIX_BIN/terminux" || fail "Failed to set permissions for terminux launcher."
command -v terminux >/dev/null 2>&1 || export PATH="$PREFIX_BIN:$PATH"
step_done 4 "terminux launcher created"

# Step 5: Setup workspace
start_spinner "Step 5/5  Setting up workspace..."
mkdir -p "$WORKSPACE_DIR" \
  "$HOME/.config/terminux" \
  "$INSTALL_DIR/workspace" 2>/dev/null || true
: >> "$WORKSPACE_DIR/.terminux_ready" 2>/dev/null || true
step_done 5 "Workspace ready"

# Completion
stop_spinner
draw_bar 100 "Complete"
printf "\n\n"
printf "  ${OK}${B}✓ Terminux installed successfully!${R}\n\n"
printf "  ${D}Install Dir:${R}   ${W}%s${R}\n" "$INSTALL_DIR"
printf "  ${D}Workspace:${R}   ${W}%s${R}\n" "$WORKSPACE_DIR"
printf "  ${D}Command:${R}     ${C}terminux${R}\n"
printf "  ${D}Web UI:${R}      ${C}http://127.0.0.1:3000${R}\n\n"
printf "  ${D}════════════════════════════════════════════════════════════${R}\n"
printf "  ${O}→ Run ${B}terminux${R}${O} to start the AI agent!${R}\n"
printf "  ${D}════════════════════════════════════════════════════════════${R}\n\n"

export PATH="$PREFIX_BIN:$PATH"
exec "$PREFIX_BIN/terminux"
