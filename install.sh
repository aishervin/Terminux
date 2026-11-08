#!/data/data/com.termux/files/usr/bin/bash
# TΞRMINUX™ — Zero-to-Hero installer for Termux
# Installs Ubuntu (proot-distro) + OpenCode, then links this GitHub repo
# so every skill/plugin added to the repo reaches every user.
set -uo pipefail

REPO="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; W=$'\033[37m'; RD=$'\033[38;5;203m'
D=$'\033[90m'; B=$'\033[1m'; R=$'\033[0m'

step() { printf "\n%s%s==> %s%s\n" "$O" "$B" "$*" "$R"; }
ok()   { printf "  %sOK%s %s\n" "$G" "$R" "$*"; }
warn() { printf "  %s!%s %s\n" "$O" "$R" "$*"; }
die()  { printf "\n  %sFAIL:%s %s\n\n" "$RD$B" "$*" "$R" >&2; exit 1; }

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
  bash <<'INSIDE' || die "setup inside Ubuntu failed"
set -u
REPO="$TERMINUX_REPO"
BRANCH="$TERMINUX_BRANCH"
export DEBIAN_FRONTEND=noninteractive
export PATH="$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

apt-get update -y >/dev/null 2>&1 || true
apt-get install -y curl git ca-certificates nodejs npm >/dev/null 2>&1 || true

if [ ! -d "$HOME/Terminux/.git" ]; then
  git clone --depth 1 --branch "$BRANCH" "$REPO" "$HOME/Terminux" >/dev/null 2>&1 || exit 1
else
  git -C "$HOME/Terminux" fetch --depth 1 origin "$BRANCH" >/dev/null 2>&1 \
    && git -C "$HOME/Terminux" checkout -q FETCH_HEAD || true
fi
echo "REPO_OK"

if ! command -v opencode >/dev/null 2>&1; then
  curl -fsSL https://opencode.ai/v2/install | bash >/dev/null 2>&1 || exit 3
fi
export PATH="$HOME/.opencode/bin:$PATH"
command -v opencode >/dev/null 2>&1 || exit 3

# branded skin plugin from this repo
if [ -f "$HOME/Terminux/skin/dist/gui-experimental.cjs" ]; then
  mkdir -p "$HOME/.config/opencode/plugins/termunix"
  cp "$HOME/Terminux/skin/dist/gui-experimental.cjs" "$HOME/.config/opencode/plugins/termunix/"
  printf '%s\n' '{"name":"opencode-termunix-skin","version":"0.2.0","type":"module","exports":{"./gui-experimental":"./gui-experimental.cjs"}}' \
    > "$HOME/.config/opencode/plugins/termunix/package.json"
fi

# branded colour theme (file-based theme: the id is the file name)
if [ -f "$HOME/Terminux/skin/themes/terminux-charcoal.json" ]; then
  mkdir -p "$HOME/.config/opencode/themes"
  cp "$HOME/Terminux/skin/themes/terminux-charcoal.json" "$HOME/.config/opencode/themes/"
fi
CLI_CFG="$HOME/.config/opencode/cli.json"
node -e '
const fs=require("fs");
const p=process.argv[1];
let j={};
try { j=JSON.parse(fs.readFileSync(p,"utf8")) } catch(e) { j={} }
j.theme = Object.assign({}, j.theme, { name: "terminux-charcoal" });
fs.writeFileSync(p, JSON.stringify(j,null,2)+"\n");
' "$CLI_CFG" || true

# skills from this repo, via the official skills config
mkdir -p "$HOME/.config/opencode"
CFG="$HOME/.config/opencode/opencode.json"
if [ ! -f "$CFG" ]; then
  printf '%s\n' '{"$schema":"https://opencode.ai/config.json","skills":[]}' > "$CFG"
fi
node -e '
const fs=require("fs");
const p=process.argv[1];
let j={};
try { j=JSON.parse(fs.readFileSync(p,"utf8")) } catch(e) { j={} }
if(!Array.isArray(j.skills)) j.skills=[];
for (const s of ["~/Terminux/skills"]) if(!j.skills.includes(s)) j.skills.push(s);
fs.writeFileSync(p, JSON.stringify(j,null,2)+"\n");
' "$CFG" || true

opencode --version >/dev/null 2>&1 || exit 3
echo "OPENCODE_OK"
INSIDE

ok "OpenCode and repository are ready inside Ubuntu."

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
    proot-distro login "$distro" -- bash -c '
      export PATH="$HOME/.opencode/bin:$PATH"
      if [ -d "$HOME/Terminux/.git" ]; then
        git -C "$HOME/Terminux" fetch --depth 1 origin main && git -C "$HOME/Terminux" checkout -q FETCH_HEAD
      fi
      if [ -f "$HOME/Terminux/skin/dist/gui-experimental.cjs" ]; then
        mkdir -p "$HOME/.config/opencode/plugins/termunix"
        cp "$HOME/Terminux/skin/dist/gui-experimental.cjs" "$HOME/.config/opencode/plugins/termunix/"
      fi
      if [ -f "$HOME/Terminux/skin/themes/terminux-charcoal.json" ]; then
        mkdir -p "$HOME/.config/opencode/themes"
        cp "$HOME/Terminux/skin/themes/terminux-charcoal.json" "$HOME/.config/opencode/themes/"
      fi
      node -e '
      const fs=require("fs");
      const p=process.env.HOME+"/.config/opencode/cli.json";
      let j={};
      try { j=JSON.parse(fs.readFileSync(p,"utf8")) } catch(e) { j={} }
      j.theme = Object.assign({}, j.theme, { name: "terminux-charcoal" });
      fs.writeFileSync(p, JSON.stringify(j,null,2)+"\n");
      ' || true
      opencode service restart >/dev/null 2>&1 || true
    '
    echo "Done. Refresh the browser tab."
    exit 0
    ;;
  stop)
    proot-distro login "$distro" -- bash -c 'export PATH="$HOME/.opencode/bin:$PATH"; opencode service stop' || true
    echo "Stopped."
    exit 0
    ;;
  status)
    proot-distro login "$distro" -- bash -c 'export PATH="$HOME/.opencode/bin:$PATH"; opencode --version; opencode service status' || true
    exit 0
    ;;
  uninstall)
    echo "Removing TΞRMINUX (sessions and OpenCode data are kept)..."
    proot-distro login "$distro" -- bash -c '
      export PATH="$HOME/.opencode/bin:$PATH"
      opencode service stop >/dev/null 2>&1 || true
      rm -rf "$HOME/Terminux" "$HOME/.config/opencode/plugins/termunix"
    ' || true
    BIN_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")"
    rm -f "$BIN_DIR/termunix" "$BIN_DIR/Terminux"
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
ok "Commands installed: Terminux / termunix"

# ── 5. Done ────────────────────────────────────────────────
step "5/5 Done"
printf "\n  %s%sTΞRMINUX™ is ready.%s\n" "$G" "$B" "$R"
printf "  Open the UI:      %sTerminux%s\n" "$B" "$R"
printf "  Pull updates:     %sTerminux update%s\n" "$B" "$R"
printf "  Server status:    %sTerminux status%s\n\n" "$B" "$R"
