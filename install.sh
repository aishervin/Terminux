#!/data/data/com.termux/files/usr/bin/bash
# Terminux Installer - Ultra Professional Edition
# Usage: curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash

set -uo pipefail

# === CONFIGURATION ===
REPO_URL="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"
INSTALL_DIR="${TERMINUX_DIR:-$HOME/Terminux}"
WORKSPACE_DIR="${TERMINUX_WORKSPACE:-$HOME/Terminux-workspace}"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
TERMUX_BASH="${PREFIX:-/data/data/com.termux/files/usr}/bin/bash"

# === COLORS ===
if [[ -t 1 ]]; then
  declare -A colors=(
    [reset]="\033[0m"
    [bold]="\033[1m"
    [dim]="\033[2m"
    [red]="\033[38;5;196m"
    [green]="\033[38;5;114m"
    [yellow]="\033[38;5;226m"
    [blue]="\033[38;5;33m"
    [purple]="\033[38;5;201m"
    [cyan]="\033[38;5;51m"
    [white]="\033[97m"
    [gray]="\033[90m"
    [orange]="\033[38;5;208m"
  )
else
  for color in reset bold dim red green yellow blue purple cyan white gray orange; do
    colors[$color]=""
  done
fi

# === GLOBALS ===
SPIN_PID=""
TOTAL_STEPS=5
CURRENT_STEP=0

# === CLEANUP ===
cleanup() {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null
  tput cnorm 2>/dev/null
}
trap cleanup EXIT

# === FAIL ===
fail() {
  cleanup
  printf "\n\n  ${colors[red]}${colors[bold]}✗ INSTALLATION FAILED${colors[reset]}\n"
  printf "  ${colors[red]}%s${colors[reset]}\n\n" "$*" >&2
  exit 1
}

# === SPINNER ===
spin_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
start_spinner() {
  local msg="${1:-Processing...}"
  cleanup
  [[ -t 1 ]] || { printf "  %s\n" "$msg"; return; }
  tput civis 2>/dev/null
  ( i=0
    while true; do
      printf "\r  ${colors[orange]}${spin_frames[i]}${colors[reset]}  ${colors[white]}%s${colors[reset]}  " "$msg"
      i=$(( (i+1) % ${#spin_frames[@]} ))
      sleep 0.08
    done ) &
  SPIN_PID=$!
}

# === PROGRESS BAR ===
draw_progress() {
  local pct=$1
  local label="${2:-}"
  local width=30
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))

  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  printf "\r  ${colors[gray]}[${colors[green]}%s${colors[gray]}]${colors[reset]} ${colors[white]}%3d%%${colors[reset]} ${colors[dim]}%s${colors[reset]}\033[K\n" "$bar" "$pct" "$label"
}

# === STEP COMPLETE ===
step_done() {
  local title="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local pct=$(( CURRENT_STEP * 100 / TOTAL_STEPS ))
  cleanup
  draw_progress "$pct" "$title"
  printf "  ${colors[green]}${colors[bold]}✓${colors[reset]} ${colors[white]}%s${colors[reset]}\n" "$title"
}

# === PIXEL ART BANNER ===
show_banner() {
  clear 2>/dev/null

  printf "${colors[purple]}${colors[bold]}\n"
  cat << 'EOF'
   ████████████████████████████████████████
  ████████████████████████████████████████
 ███████████████████████████████████████████
██████      TERMINUX      ████████████████
██████   AI Coding Agent   ██████████████
█████████████████████████████████████
 █████████████████████████████████████
  ██████████████████████████████████
   ███████████████████████████████
EOF
  printf "${colors[reset]}\n"

  printf "  ${colors[gray]}════════════════════════════════════════════════════════${colors[reset]}\n"
  printf "  ${colors[white]}${colors[bold]}       TERMINUX - Local AI Coding Agent${colors[reset]}\n"
  printf "  ${colors[gray]}════════════════════════════════════════════════════════${colors[reset]}\n\n"
  printf "  ${colors[white]}Install Dir:${colors[reset]}   ${colors[cyan]}%s${colors[reset]}\n" "$INSTALL_DIR"
  printf "  ${colors[white]}Workspace:${colors[reset]}   ${colors[cyan]}%s${colors[reset]}\n\n" "$WORKSPACE_DIR"
}

# === RUN QUIETLY ===
run_quiet() {
  local log
  log="$(mktemp 2>/dev/null || echo /tmp/terminux-install.log)"
  local code=0
  "$@" >"$log" 2>&1 || code=$?
  if [[ "$code" -eq 0 ]]; then
    rm -f "$log" 2>/dev/null
    return 0
  fi
  cleanup
  printf "\n  ${colors[yellow]}Error:${colors[reset]}\n"
  tail -n 25 "$log" 2>/dev/null | sed 's/^/    /' >&2 || true
  rm -f "$log" 2>/dev/null
  return "$code"
}

# === MAIN INSTALLATION ===
show_banner

# Check pkg
command -v pkg >/dev/null 2>&1 || fail "pkg not found. Install Termux first."

printf "  ${colors[dim]}Initializing installation...${colors[reset]}\n\n"
draw_progress 0 "Starting..."
printf "\n"

# Step 1: Update & Install Dependencies
start_spinner "Step 1/5  Updating packages..."
if ! run_quiet pkg update -y; then true; fi
if ! run_quiet pkg install -y nodejs-lts git; then
  run_quiet pkg install -y nodejs git || fail "Failed to install dependencies"
fi
command -v node >/dev/null 2>&1 || fail "node not found"
command -v npm >/dev/null 2>&1 || fail "npm not found"
command -v git >/dev/null 2>&1 || fail "git not found"
step_done "Environment ready (node $(node -v 2>/dev/null | tr -d '\n'))"

# Step 2: Clone Repository
start_spinner "Step 2/5  Cloning repository..."
mkdir -p "$(dirname "$INSTALL_DIR")"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  if ! run_quiet git -C "$INSTALL_DIR" fetch --depth 1 origin "$BRANCH"; then
    fail "git fetch failed"
  fi
  run_quiet git -C "$INSTALL_DIR" checkout -f -B "$BRANCH" "origin/$BRANCH" \
    || run_quiet git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" \
    || fail "Failed to update repository"
else
  rm -rf "$INSTALL_DIR"
  run_quiet git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR" \
    || fail "Failed to clone: $REPO_URL"
fi
[[ -f "$INSTALL_DIR/package.json" ]] || fail "package.json not found"
[[ -f "$INSTALL_DIR/src/server.ts" ]] || fail "src/server.ts not found"
step_done "Repository cloned"

# Step 3: Install NPM Dependencies
start_spinner "Step 3/5  Installing dependencies..."
if ! run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund; then
  rm -rf "$INSTALL_DIR/node_modules"
  run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund \
    || fail "npm install failed"
fi
[[ -x "$INSTALL_DIR/node_modules/.bin/tsx" ]] || [[ -f "$INSTALL_DIR/node_modules/tsx/dist/cli.mjs" ]] \
  || fail "tsx not found"
step_done "Dependencies installed"

# Step 4: Create Launcher
start_spinner "Step 4/5  Creating launcher..."
mkdir -p "$PREFIX_BIN" "$WORKSPACE_DIR" || fail "Failed to create directories"
cat > "$PREFIX_BIN/terminux" <<EOF
#!${TERMUX_BASH}
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
chmod 700 "$PREFIX_BIN/terminux" || fail "Failed to set permissions"
command -v terminux >/dev/null 2>&1 || export PATH="$PREFIX_BIN:$PATH"
step_done "Launcher created"

# Step 5: Setup Workspace
start_spinner "Step 5/5  Setting up workspace..."
mkdir -p "$WORKSPACE_DIR" "$HOME/.config/terminux" "$INSTALL_DIR/workspace" 2>/dev/null || true
: >> "$WORKSPACE_DIR/.terminux_ready" 2>/dev/null || true
step_done "Workspace ready"

# === COMPLETION ===
cleanup
draw_progress 100 "Complete"
printf "\n\n"
printf "  ${colors[green]}${colors[bold]}✓ TERMINUX INSTALLED SUCCESSFULLY!${colors[reset]}\n\n"
printf "  ${colors[gray]}Install Dir:${colors[reset]}   ${colors[white]}%s${colors[reset]}\n" "$INSTALL_DIR"
printf "  ${colors[gray]}Workspace:${colors[reset]}   ${colors[white]}%s${colors[reset]}\n" "$WORKSPACE_DIR"
printf "  ${colors[gray]}Command:${colors[reset]}     ${colors[cyan]}terminux${colors[reset]}\n"
printf "  ${colors[gray]}Web UI:${colors[reset]}      ${colors[cyan]}http://127.0.0.1:3000${colors[reset]}\n\n"
printf "  ${colors[gray]}════════════════════════════════════════════════════════${colors[reset]}\n"
printf "  ${colors[orange]}→ Run ${colors[bold]}terminux${colors[reset]}${colors[orange]} to start!${colors[reset]}\n"
printf "  ${colors[gray]}════════════════════════════════════════════════════════${colors[reset]}\n\n"

export PATH="$PREFIX_BIN:$PATH"
exec "$PREFIX_BIN/terminux"
