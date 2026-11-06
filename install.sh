#!/data/data/com.termux/files/usr/bin/bash
# Terminux installer — graphical Termux setup
# Usage: curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash

set -uo pipefail

REPO_URL="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"
INSTALL_DIR="${TERMINUX_DIR:-$HOME/Terminux}"
WORKSPACE_DIR="${TERMINUX_WORKSPACE:-$HOME/Terminux-workspace}"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
TERMUX_BASH="${PREFIX:-/data/data/com.termux/files/usr}/bin/bash"

# ── colors ──
if [[ -t 1 ]]; then
  O=$'\033[38;5;208m'; W=$'\033[97m'; D=$'\033[90m'
  OK=$'\033[38;5;114m'; E=$'\033[38;5;203m'; C=$'\033[36m'
  B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
else
  O= W= D= OK= E= C= B= R= DIM=
fi

PROGRESS=0
TOTAL_STEPS=5

cleanup() { tput cnorm 2>/dev/null || true; }
trap cleanup EXIT
trap 'fail "Installation aborted by signal."' INT TERM

fail() {
  printf "\n\n  ${E}${B}[X] Installation failed${R}\n  ${E}%s${R}\n\n" "$*" >&2
  exit 1
}

# ── logo / loading splash (block-art structure) ──
print_logo() {
  printf "\n%s\n\n" "${O}${B} TERMINUX by ☬ SHΞЯVIN™"
  cat << 'LOGO'
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠉⠉⠉⠉⠉⠉⠉⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⡿⠟⠋⢀⣤⣾⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠉⠀⠀⠚⠛⠛⠛⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣶⣶⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣀⣀⣀⣀⣀⣀⣀⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠀⠉⠛⠿⠿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣷⣶⣤⠤⠀⠉⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠉⠉⢀⣀⣤⣶⣾⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠒⠛⠛⠛⠛⠛⠛⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠀⣶⣶⠀⢰⣶⣶⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⡀⠙⠋⢀⡀⠈⠛⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠿⣶⡶⠿⣿⣿⠶⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠀⣿⡇⠀⣿⣿⠀⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠀⣿⣇⣀⣿⣿⠀⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠛⠛⠛⠛⠛⠛⠛⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣶⣶⣶⠀⣶⣶⣶⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠿⠿⠿⠀⠿⠿⠿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣤⣤⣤⣤⣤⣤⣤⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠋⢀⣿⠋⢀⡀⠙⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣇⠀⢿⡏⢀⣾⡿⠀⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣤⣀⣀⣼⣇⣀⣰⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
LOGO
  printf "\n  ${D}☬  Exclusive  SHΞN™   made${R}\n"
  printf "  ${D}────────────────────────────────────────────────────${R}\n"
  printf "  ${W}${B}local AI coding agent${R}  ${D}·${R}  ${O}SHΞN™${R}  ${D}·${R}  ${C}Termux${R}\n"
  printf "  ${D}────────────────────────────────────────────────────${R}\n\n"
}

# ── thick linear progress bar (double-width blocks) ──
draw_bar() {
  local pct="$1" label="${2:-}"
  local width=25
  local filled=$(( pct * width / 100 ))
  (( filled > width )) && filled=$width
  local empty=$(( width - filled ))
  local bar="" i
  for (( i=0; i<filled; i++ )); do bar+="██"; done
  for (( i=0; i<empty; i++ )); do bar+="░░"; done
  if [[ -t 1 ]]; then
    printf "\r  ${D}[${O}%s${D}]${R} ${W}%3d%%${R}  ${DIM}%s${R}\033[K" "$bar" "$pct" "$label"
  else
    printf "  [%s] %3d%%  %s\n" "$bar" "$pct" "$label"
  fi
}

step_done() {
  local n="$1" title="$2"
  PROGRESS=$(( n * 100 / TOTAL_STEPS ))
  draw_bar "$PROGRESS" ""
  printf "\n  ${OK}✓${R}  ${W}%s${R}\n" "$title"
}

run_quiet() {
  local log
  log="$(mktemp 2>/dev/null || echo /tmp/terminux-install.log)"
  if "$@" >"$log" 2>&1; then
    rm -f "$log" 2>/dev/null || true
    return 0
  fi
  local code=$?
  printf "\n  ${E}Error output:${R}\n"
  tail -n 25 "$log" 2>/dev/null | sed 's/^/    /' >&2 || true
  rm -f "$log" 2>/dev/null || true
  return "$code"
}

# ── preflight ──
clear 2>/dev/null || true
print_logo
command -v pkg >/dev/null 2>&1 || fail "This installer only runs on Termux (pkg command not found)."

printf "  ${D}Install dir:${R}  ${W}%s${R}\n" "$INSTALL_DIR"
printf "  ${D}Workspace:${R}    ${W}%s${R}\n\n" "$WORKSPACE_DIR"
draw_bar 0 "starting..."
printf "\n"

# ── 1/5 packages ──
draw_bar 3 "updating packages (nodejs, git)..."
if ! run_quiet pkg update -y; then
  true   # soft-fail update, still try install
fi
if ! run_quiet pkg install -y nodejs-lts git; then
  run_quiet pkg install -y nodejs git || fail "Failed to install nodejs/git. Check output above."
fi
command -v node >/dev/null 2>&1 || fail "node not found after install."
command -v npm  >/dev/null 2>&1 || fail "npm not found after install."
command -v git  >/dev/null 2>&1 || fail "git not found after install."
step_done 1 "Termux environment ready  (node $(node -v 2>/dev/null | tr -d '\n'))"

# ── 2/5 source ──
draw_bar 25 "fetching source from GitHub..."
mkdir -p "$(dirname "$INSTALL_DIR")"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  run_quiet git -C "$INSTALL_DIR" fetch --depth 1 origin "$BRANCH" \
    || fail "git fetch failed. Check internet or GitHub access."
  run_quiet git -C "$INSTALL_DIR" checkout -f -B "$BRANCH" "origin/$BRANCH" \
    || run_quiet git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" \
    || fail "Failed to update local repository."
else
  rm -rf "$INSTALL_DIR"
  run_quiet git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR" \
    || fail "Failed to clone repository: $REPO_URL"
fi
[[ -f "$INSTALL_DIR/package.json" ]] || fail "package.json not found in $INSTALL_DIR."
[[ -f "$INSTALL_DIR/server.ts" ]]    || fail "server.ts not found — clone is incomplete."
step_done 2 "Source downloaded"

# ── 3/5 npm ──
draw_bar 45 "installing npm dependencies (may take a few minutes)..."
if ! run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund; then
  rm -rf "$INSTALL_DIR/node_modules" "$INSTALL_DIR/package-lock.json"
  run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund \
    || fail "npm install failed."
fi
if [[ ! -x "$INSTALL_DIR/node_modules/.bin/tsx" ]] && [[ ! -f "$INSTALL_DIR/node_modules/tsx/dist/cli.mjs" ]]; then
  fail "tsx was not installed. Check npm install manually in $INSTALL_DIR."
fi
step_done 3 "Dependencies installed"

# ── 4/5 launcher ──
draw_bar 65 "creating 'terminux' launcher..."
mkdir -p "$PREFIX_BIN" "$WORKSPACE_DIR" || fail "Failed to create bin/workspace directories."
cat > "$PREFIX_BIN/terminux" <<EOF
#!${TERMUX_BASH}
# Terminux launcher
export TERMINUX_WORKSPACE="${WORKSPACE_DIR}"
cd "${INSTALL_DIR}" || exit 1
if [[ -x ./node_modules/.bin/tsx ]]; then
  exec ./node_modules/.bin/tsx server.ts
fi
exec npm start
EOF
chmod 700 "$PREFIX_BIN/terminux" || fail "chmod on launcher failed."
command -v terminux >/dev/null 2>&1 || export PATH="$PREFIX_BIN:$PATH"
step_done 4 "Launcher 'terminux' ready"

# ── 5/5 workspace ──
draw_bar 85 "preparing workspace..."
mkdir -p "$WORKSPACE_DIR" \
  "$HOME/.config/terminux" \
  "$INSTALL_DIR/workspace" 2>/dev/null || true
: >> "$WORKSPACE_DIR/.terminux_ready" 2>/dev/null || true
step_done 5 "Workspace ready"

# ── done ──
draw_bar 100 "complete"
printf "\n\n"
printf "  ${OK}${B}✓ Terminux installation completed successfully${R}\n\n"
printf "  ${D}Install dir:${R}   ${W}%s${R}\n" "$INSTALL_DIR"
printf "  ${D}Workspace:${R}     ${W}%s${R}\n" "$WORKSPACE_DIR"
printf "  ${D}Run:${R}           ${O}${B}terminux${R}\n"
printf "  ${D}Web URL:${R}       ${C}http://127.0.0.1:3000${R}\n\n"
printf "  ${D}────────────────────────────────────────────────────${R}\n"
printf "  ${O}▶${R}  Starting server...\n\n"

cd "$INSTALL_DIR" || fail "Failed to enter $INSTALL_DIR."
export TERMINUX_WORKSPACE="$WORKSPACE_DIR"
export PATH="$PREFIX_BIN:$PATH"

if [[ -x ./node_modules/.bin/tsx ]]; then
  exec ./node_modules/.bin/tsx server.ts
fi
exec npm start
