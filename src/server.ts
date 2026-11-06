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
  B=$'\033[1m'; R=$'\033[0m'
else
  O= W= D= OK= E= C= B= R=
fi

trap 'fail "Installation aborted by signal."' INT TERM

fail() {
  printf "\n\n  ${E}${B}[X] Installation failed${R}\n  ${E}%s${R}\n\n" "$*" >&2
  exit 1
}

# ── Sequential ASCII Loading ──
print_loading() {
  clear 2>/dev/null || true
  printf "\n  ${O}${B}TERMINUX by  ☬ SHΞЯVIN™${R}\n\n"
  
  local ascii_lines=(
    "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠉⠉⠉⠉⠉⠉⠉⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⣿⡿⠟⠋⢀⣤⣾⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠉⠀⠀⠚⠛⠛⠛⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⣶⣶⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⣀⣀⣀⣀⣀⣀⣀⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠀⠉⠛⠿⠿⣿⣿⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⣿⣷⣶⣤⠤⠀⠉⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠉⠉⢀⣀⣤⣶⣾⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠒⠛⠛⠛⠛⠛⠛⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠀⣶⣶⠀⢰⣶⣶⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⡀⠙⠋⢀⡀⠈⠛⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠿⣶⡶⠿⣿⣿⠶⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠀⣿⡇⠀⣿⣿⠀⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠀⣿⣇⣀⣿⣿⠀⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠛⠛⠛⠛⠛⠛⠛⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⣶⣶⣶⠀⣶⣶⣶⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠿⠿⠿⠀⠿⠿⠿⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⣤⣤⣤⣤⣤⣤⣤⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⠋⢀⣿⠋⢀⡀⠙⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣇⠀⢿⡏⢀⣾⡿⠀⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⣤⣀⣀⣼⣇⣀⣰⣿⣿⣿⣿⣿"
    "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
  )

  for line in "${ascii_lines[@]}"; do
    printf "  ${O}%s${R}\n" "$line"
    sleep 0.02
  done

  printf "\n  ${D}☬  Exclusive  SHΞN™   made${R}\n"
  printf "  ${D}────────────────────────────────────────────────────${R}\n"
  printf "  ${W}${B}local AI coding agent${R}  ${D}·${R}  ${O}SHΞN™${R}  ${D}·${R}  ${C}Termux${R}\n"
  printf "  ${D}────────────────────────────────────────────────────${R}\n\n"
  sleep 0.3
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

# ── Start ──
print_loading
command -v pkg >/dev/null 2>&1 || fail "This installer only runs on Termux (pkg command not found)."

printf "  ${D}Install dir:${R}  ${W}%s${R}\n" "$INSTALL_DIR"
printf "  ${D}Workspace:${R}    ${W}%s${R}\n\n" "$WORKSPACE_DIR"

# ── 1/5 packages ──
printf "  ${O}[1/5]${R} Updating packages (nodejs, git)...\n"
if ! run_quiet pkg update -y; then true; fi
if ! run_quiet pkg install -y nodejs-lts git; then
  run_quiet pkg install -y nodejs git || fail "Failed to install nodejs/git. Check output above."
fi
command -v node >/dev/null 2>&1 || fail "node not found after install."
command -v npm  >/dev/null 2>&1 || fail "npm not found after install."
command -v git  >/dev/null 2>&1 || fail "git not found after install."
printf "  ${OK}✓${R} Termux environment ready (node $(node -v 2>/dev/null | tr -d '\n'))\n\n"

# ── 2/5 source ──
printf "  ${O}[2/5]${R} Fetching source from GitHub...\n"
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

# بررسی مسیر صحیح فایل سرور (داخل پوشه src)
if [[ ! -f "$INSTALL_DIR/src/server.ts" ]]; then
  printf "\n  ${E}[X] Error: 'src/server.ts' not found in the repository!${R}\n"
  printf "  ${D}The clone was successful, but the file does not exist at the expected path.${R}\n"
  printf "  ${D}Check your repository at: %s${R}\n\n" "$REPO_URL"
  exit 1
fi
printf "  ${OK}✓${R} Source downloaded\n\n"

# ── 3/5 npm ──
printf "  ${O}[3/5]${R} Installing npm dependencies (may take a few minutes)...\n"
if ! run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund; then
  rm -rf "$INSTALL_DIR/node_modules" "$INSTALL_DIR/package-lock.json"
  run_quiet npm install --prefix "$INSTALL_DIR" --no-audit --no-fund \
    || fail "npm install failed."
fi
if [[ ! -x "$INSTALL_DIR/node_modules/.bin/tsx" ]] && [[ ! -f "$INSTALL_DIR/node_modules/tsx/dist/cli.mjs" ]]; then
  fail "tsx was not installed. Check npm install manually in $INSTALL_DIR."
fi
printf "  ${OK}✓${R} Dependencies installed\n\n"

# ── 4/5 launcher ──
printf "  ${O}[4/5]${R} Creating 'terminux' launcher...\n"
mkdir -p "$PREFIX_BIN" "$WORKSPACE_DIR" || fail "Failed to create bin/workspace directories."
cat > "$PREFIX_BIN/terminux" <<EOF
#!${TERMUX_BASH}
# Terminux launcher
export TERMINUX_WORKSPACE="${WORKSPACE_DIR}"
cd "${INSTALL_DIR}" || exit 1
if [[ -x ./node_modules/.bin/tsx ]]; then
  exec ./node_modules/.bin/tsx src/server.ts
fi
exec npm start
EOF
chmod 700 "$PREFIX_BIN/terminux" || fail "chmod on launcher failed."
command -v terminux >/dev/null 2>&1 || export PATH="$PREFIX_BIN:$PATH"
printf "  ${OK}✓${R} Launcher 'terminux' ready\n\n"

# ── 5/5 workspace ──
printf "  ${O}[5/5]${R} Preparing workspace...\n"
mkdir -p "$WORKSPACE_DIR" \
  "$HOME/.config/terminux" \
  "$INSTALL_DIR/workspace" 2>/dev/null || true
: >> "$WORKSPACE_DIR/.terminux_ready" 2>/dev/null || true
printf "  ${OK}✓${R} Workspace ready\n\n"

# ── done ──
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

# اجرای نهایی با مسیر صحیح
if [[ -x ./node_modules/.bin/tsx ]]; then
  exec ./node_modules/.bin/tsx src/server.ts
fi
exec npm start
