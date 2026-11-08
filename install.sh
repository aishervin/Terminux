#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ — Zero-to-Hero installer for Termux
# Installs Ubuntu (proot-distro) + OpenCode, then links this GitHub repo
# so every skill/plugin added to the repo reaches every user.
set -uo pipefail

REPO="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; RD=$'\033[38;5;203m'
D=$'\033[90m'; B=$'\033[1m'; R=$'\033[0m'

step() { printf "\n%s%s==> %s%s\n" "$O" "$B" "$*" "$R"; }
ok()   { printf "  %sOK%s %s\n" "$G" "$R" "$*"; }
warn() { printf "  %s!%s %s\n" "$O" "$R" "$*"; }
die()  { printf "\n  %sFAIL:%s %s\n\n" "$RD$B" "$R" "$*" >&2; exit 1; }

clear
cat <<'BANNER'
  ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██╗   ██╗██╗  ██╗
  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██║   ██║╚██╗██╔╝
     ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║   ██║ ╚███╔╝
     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║   ██║ ██╔██╗
     ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝██╔╝ ██╗
     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝

     TΞRMINUX™ — FULL TUNED OPENCODE FOR ANDROID BY : SHΞN™
BANNER

# ── 1. Termux base ──────────────────────────────────────────
step "1/5 Preparing Termux"
command -v pkg >/dev/null 2>&1 || die "pkg not found - is this Termux?"
pkg update -y >/dev/null 2>&1 || warn "pkg update failed, continuing"
pkg install -y proot-distro curl git termux-tools >/dev/null 2>&1 \
  || pkg install -y proot-distro curl git >/dev/null 2>&1 \
  || die "could not install proot-distro / curl / git"
command -v proot-distro >/dev/null 2>&1 || die "proot-distro is not available"
ok "Termux packages ready."

# ── 2. Ubuntu container ────────────────────────────────────
step "2/5 Ubuntu container"
if proot-distro login ubuntu -- true >/dev/null 2>&1; then
  ok "Ubuntu container already installed."
else
  printf "  %s-> downloading Ubuntu (one time, ~120 MB)...%s\n" "$D" "$R"
  proot-distro install ubuntu || die "Ubuntu installation failed"
  proot-distro login ubuntu -- true >/dev/null 2>&1 || die "Ubuntu container is not usable"
  ok "Ubuntu installed."
fi

# ── 3. Repo + OpenCode inside Ubuntu ──────────────────────
step "3/5 OpenCode + repository (inside Ubuntu)"
proot-distro login ubuntu -- env TERMINUX_REPO="$REPO" TERMINUX_BRANCH="$BRANCH" \
  bash <<'INSIDE'
set -u
LOG=/tmp/terminux-install.log
: > "$LOG"
export DEBIAN_FRONTEND=noninteractive
export PATH="$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Save repo settings so "Terminux update" uses the same source.
printf 'REPO=%s\nBRANCH=%s\n' "$TERMINUX_REPO" "$TERMINUX_BRANCH" > "$HOME/.terminux.conf"

# Helper: sync repo + apply plugin/theme/skills config.
# Used by the installer AND by "Terminux update" (single source of truth).
cat > "$HOME/.terminux-apply.sh" <<'APPLY'
#!/bin/bash
set -u
REPO="https://github.com/aishervin/Terminux.git"
BRANCH="main"
[ -f "$HOME/.terminux.conf" ] && . "$HOME/.terminux.conf"
DIR="$HOME/Terminux"
CFGDIR="$HOME/.config/opencode"
LOG=/tmp/terminux-install.log

# --- sync repo (discard local edits, always match remote) ---
if [ -d "$DIR/.git" ]; then
  if git -C "$DIR" fetch --depth 1 origin "$BRANCH" >>"$LOG" 2>&1; then
    git -C "$DIR" reset --hard FETCH_HEAD >>"$LOG" 2>&1 \
      || { echo "ERR: git reset failed"; exit 1; }
  else
    echo "WARN: could not fetch updates, using the existing copy"
  fi
else
  rm -rf "$DIR"
  git clone --depth 1 --branch "$BRANCH" "$REPO" "$DIR" >>"$LOG" 2>&1 \
    || { echo "ERR: git clone failed"; exit 1; }
fi

# --- branded skin plugin ---
if [ -f "$DIR/skin/dist/gui-experimental.cjs" ]; then
  mkdir -p "$CFGDIR/plugins/termunix"
  cp "$DIR/skin/dist/gui-experimental.cjs" "$CFGDIR/plugins/termunix/"
  printf '%s\n' '{"name":"opencode-termunix-skin","version":"0.2.0","type":"module","exports":{"./gui-experimental":"./gui-experimental.cjs"}}' \
    > "$CFGDIR/plugins/termunix/package.json"
fi

# --- branded colour theme ---
if [ -f "$DIR/skin/themes/terminux-charcoal.json" ]; then
  mkdir -p "$CFGDIR/themes"
  cp "$DIR/skin/themes/terminux-charcoal.json" "$CFGDIR/themes/"
fi

# --- cli.json (theme) + opencode.json (skills) ---
if command -v node >/dev/null 2>&1; then
  node - "$CFGDIR" "$DIR" <<'JS' || echo "WARN: config update failed"
const fs = require("fs");
const path = require("path");
const [cfgDir, repoDir] = process.argv.slice(2);
const load = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch (e) { return {}; } };
const save = (p, j) => fs.writeFileSync(p, JSON.stringify(j, null, 2) + "\n");
fs.mkdirSync(cfgDir, { recursive: true });

const cliPath = path.join(cfgDir, "cli.json");
const cli = load(cliPath);
cli.theme = Object.assign({}, cli.theme, { name: "terminux-charcoal" });
save(cliPath, cli);

const ocPath = path.join(cfgDir, "opencode.json");
const oc = load(ocPath);
if (!oc.$schema) oc.$schema = "https://opencode.ai/config.json";
if (!Array.isArray(oc.skills)) oc.skills = [];
const skillsDir = path.join(repoDir, "skills");
oc.skills = oc.skills.filter((s) => s !== "~/Terminux/skills");
if (!oc.skills.includes(skillsDir)) oc.skills.push(skillsDir);
save(ocPath, oc);
JS
else
  echo "WARN: node not found, theme/skills config skipped"
fi
exit 0
APPLY
chmod +x "$HOME/.terminux-apply.sh"

# --- base packages ---
apt-get update -y >>"$LOG" 2>&1 || true
apt-get install -y curl git ca-certificates nodejs npm >>"$LOG" 2>&1 || true
command -v git >/dev/null 2>&1 || { echo "ERR: git is not installed in Ubuntu"; exit 2; }

# --- repo + config ---
bash "$HOME/.terminux-apply.sh" || exit 1
echo "REPO_OK"

# --- OpenCode ---
if ! command -v opencode >/dev/null 2>&1; then
  curl -fsSL https://opencode.ai/v2/install 2>>"$LOG" | bash >>"$LOG" 2>&1 || true
fi
export PATH="$HOME/.opencode/bin:$PATH"
if ! command -v opencode >/dev/null 2>&1; then
  npm install -g opencode-ai >>"$LOG" 2>&1 || true
fi
command -v opencode >/dev/null 2>&1 || exit 3
opencode --version >/dev/null 2>&1 || exit 3
echo "OPENCODE_OK"
INSIDE
rc=$?

case "$rc" in
  0) ok "OpenCode and repository are ready inside Ubuntu." ;;
  1) die "could not download the repo ($REPO). Check your internet and run again." ;;
  2) die "git could not be installed inside Ubuntu." ;;
  3) die "OpenCode installation failed. See log: proot-distro login ubuntu -- cat /tmp/terminux-install.log" ;;
  *) die "setup inside Ubuntu failed (code $rc)." ;;
esac

# ── 4. Launcher ────────────────────────────────────────────
step "4/5 Launcher"
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
[ -d "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/termunix" <<'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

distro="${TERMINUX_DISTRO:-ubuntu}"
port="${TERMINUX_PORT:-49374}"

inner() {
  proot-distro login "$distro" -- bash <<'INNER'
export PATH="$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
if ! opencode service status >/dev/null 2>&1; then
  opencode service start >/dev/null 2>&1
  sleep 3
fi
for i in $(seq 1 20); do
  opencode service status >/dev/null 2>&1 && break
  sleep 0.5
done
opencode pair 2>/dev/null
INNER
}

case "${1:-open}" in
  update)
    echo "Updating TΞRMINUX from GitHub..."
    proot-distro login "$distro" -- bash <<'UPD'
export PATH="$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
if [ -x "$HOME/.terminux-apply.sh" ]; then
  bash "$HOME/.terminux-apply.sh" || echo "Update finished with errors."
else
  echo "Updater not found. Re-run the installer."
fi
opencode service restart >/dev/null 2>&1 || true
UPD
    echo "Done. Refresh the browser tab."
    exit 0
    ;;
  stop)
    proot-distro login "$distro" -- bash <<'STP' || true
export PATH="$HOME/.opencode/bin:$PATH"
opencode service stop
STP
    echo "Stopped."
    exit 0
    ;;
  status)
    proot-distro login "$distro" -- bash <<'STS' || true
export PATH="$HOME/.opencode/bin:$PATH"
opencode --version
opencode service status
STS
    exit 0
    ;;
  uninstall)
    echo "Removing TΞRMINUX (sessions and OpenCode data are kept)..."
    proot-distro login "$distro" -- bash <<'UNI' || true
export PATH="$HOME/.opencode/bin:$PATH"
opencode service stop >/dev/null 2>&1 || true
rm -rf "$HOME/Terminux" "$HOME/.config/opencode/plugins/termunix" \
       "$HOME/.terminux-apply.sh" "$HOME/.terminux.conf"
UNI
    self_dir="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")"
    rm -f "$self_dir/termunix" "$self_dir/Terminux"
    echo "Removed. The Ubuntu container is kept; remove it with: proot-distro remove ubuntu"
    exit 0
    ;;
esac

out="$(inner)"
link="$(printf '%s\n' "$out" | grep -oE 'https?://[^ ]+/auth/connect/[A-Za-z0-9_-]+' | tail -1)"

if [ -z "$link" ]; then
  link="http://127.0.0.1:${port}"
  echo "Could not create a pair link; trying $link"
fi

if command -v termux-open-url >/dev/null 2>&1; then
  termux-open-url "$link" && echo "Opened in browser."
else
  echo "Open this link: $link"
fi
LAUNCHER

chmod +x "$BIN_DIR/termunix"
ln -sf "$BIN_DIR/termunix" "$BIN_DIR/Terminux"
bash -n "$BIN_DIR/termunix" || die "launcher has a syntax error"
ok "Commands installed: Terminux / termunix"

# ── 5. Done ────────────────────────────────────────────────
step "5/5 Done"
printf "\n  %s%sTΞRMINUX™ is ready.%s\n" "$G" "$B" "$R"
printf "  Open the UI:      %sTerminux%s\n" "$B" "$R"
printf "  Pull updates:     %sTerminux update%s\n" "$B" "$R"
printf "  Server status:    %sTerminux status%s\n" "$B" "$R"
printf "  Stop server:      %sTerminux stop%s\n\n" "$B" "$R"
