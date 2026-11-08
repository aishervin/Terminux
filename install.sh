#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────
#  TΞRMINUX™ — نصب‌کنندهٔ کامل و خودکار برای Termux
#
#  نصب:   curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash
#  اجرا:  Terminux
#
#  گزینه‌ها (متغیر محیطی):
#    TERMINUX_NO_OPEN=1      در پایان مرورگر باز نشود
#    TERMINUX_BRANCH=main    شاخهٔ مخزن
#    TERMINUX_SRC=...        محل سورس
#    OPENCODE_VERSION=...    نسخهٔ مشخص OpenCode
# ─────────────────────────────────────────────────────────────
set -uo pipefail

REPO="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"
SRC_DIR="${TERMINUX_SRC:-$HOME/.termunix/src}"
PLUGIN_DIR="${TERMINUX_PLUGIN:-$HOME/.config/opencode/plugins/termunix}"
NO_OPEN="${TERMINUX_NO_OPEN:-0}"
PIN="${OPENCODE_VERSION:-}"

PREFIX="${PREFIX:-}"
BIN_DIR="$PREFIX/bin"
OC_BIN="$HOME/.opencode/bin"

O=$'\033[38;5;208m'; G=$'\033[38;5;114m'; RD=$'\033[38;5;203m'
D=$'\033[90m'; B=$'\033[1m'; R=$'\033[0m'

step() { printf "\n%s%s▸ %s%s\n" "$O" "$B" "$*" "$R"; }
ok()   { printf "  %s✓%s %s\n" "$G" "$R" "$*"; }
warn() { printf "  %s!%s %s\n" "$O" "$R" "$*"; }
die()  { printf "\n  %s✕ %s%s\n\n" "$RD$B" "$*" "$R" >&2; exit 1; }

banner() {
  printf "\n%s%s" "$O" "$B"
  cat <<'ART'
  ┌──────────────────────────────────────────┐
  │   T Ξ R M I N U X ™                      │
  │   local coding agent · termux            │
  └──────────────────────────────────────────┘
ART
  printf "%s\n" "$R"
}

# ── ۰. محیط ────────────────────────────────────────────────
banner
step "۰/۶ بررسی محیط"

case "$PREFIX" in
  *com.termux*) ok "Termux شناسایی شد ($PREFIX)" ;;
  *) die "این نصب‌کننده مخصوص Termux است. PREFIX=$PREFIX" ;;
esac
[ -x "$BIN_DIR/bash" ] || die "bash در Termux پیدا نشد."
command -v pkg >/dev/null 2>&1 || die "دستور pkg موجود نیست؛ Termux سالم نیست."

export PATH="$OC_BIN:$BIN_DIR:$PATH"

# ── ۱. پیش‌نیازها ──────────────────────────────────────────
step "۱/۶ پیش‌نیازها"
missing=()
command -v curl >/dev/null 2>&1 || missing+=(curl)
command -v git  >/dev/null 2>&1 || missing+=(git)
command -v node >/dev/null 2>&1 || missing+=(nodejs-lts)
command -v termux-open-url >/dev/null 2>&1 || missing+=(termux-tools)

if [ ${#missing[@]} -gt 0 ]; then
  printf "  %s→ نصب: %s%s\n" "$D" "${missing[*]}" "$R"
  pkg update -y >/dev/null 2>&1 || warn "pkg update هشدار داد (ادامه می‌دهیم)"
  if ! pkg install -y "${missing[@]}" >/tmp/termunix-pkg.log 2>&1; then
    # nodejs-lts روی برخی مخازن نیست
    if printf '%s' "${missing[*]}" | grep -q nodejs-lts; then
      pkg install -y nodejs >/tmp/termunix-pkg2.log 2>&1 || true
    fi
  fi
fi

for c in curl git node; do
  command -v "$c" >/dev/null 2>&1 || die "$c نصب نشد. لاگ: /tmp/termunix-pkg.log"
done
ok "curl / git / node $(node -v 2>/dev/null) آماده‌اند."

# ── ۲. OpenCode ────────────────────────────────────────────
step "۲/۶ OpenCode"

install_opencode() {
  printf "  %s→ دریافت نصب‌کنندهٔ رسمی OpenCode…%s\n" "$D" "$R"
  curl -fsSL https://opencode.ai/v2/install | bash || die "نصب OpenCode ناموفق بود."
}
oc_version() { opencode --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1; }

if ! command -v opencode >/dev/null 2>&1; then
  install_opencode
  export PATH="$OC_BIN:$BIN_DIR:$PATH"
  command -v opencode >/dev/null 2>&1 || die "opencode پس از نصب پیدا نشد."
  ok "OpenCode نصب شد: $(oc_version)"
else
  ok "OpenCode موجود است: $(oc_version)"
fi

if [ -n "$PIN" ] && [ "$(oc_version)" != "$PIN" ]; then
  printf "  %s→ پین به نسخهٔ %s…%s\n" "$D" "$PIN" "$R"
  opencode upgrade "$PIN" >/dev/null 2>&1 || warn "پین نسخه ناموفق بود؛ نسخهٔ فعلی می‌ماند."
  ok "نسخه: $(oc_version)"
fi

# PATH دائمی برای شل‌های بعدی
RC="$HOME/.bashrc"
if [ -f "$RC" ] && ! grep -q 'opencode/bin' "$RC" 2>/dev/null; then
  printf '\n# Terminux\nexport PATH="$HOME/.opencode/bin:$PATH"\n' >> "$RC"
fi
ok "PATH دائمی تنظیم شد."

# ── ۳. سورس و پوست ────────────────────────────────────────
step "۳/۶ دریافت پوست TΞRMINUX"
if [ -d "$SRC_DIR/.git" ]; then
  if git -C "$SRC_DIR" fetch --depth 1 origin "$BRANCH" >/dev/null 2>&1; then
    git -C "$SRC_DIR" reset --hard "origin/$BRANCH" >/dev/null 2>&1 || warn "reset ناموفق"
    ok "به‌روزرسانی شد."
  else
    warn "به‌روزرسانی ناموفق (آفلاین؟) — نسخهٔ موجود استفاده می‌شود."
  fi
else
  mkdir -p "$(dirname "$SRC_DIR")"
  rm -rf "$SRC_DIR"
  git clone --depth 1 --branch "$BRANCH" "$REPO" "$SRC_DIR" >/dev/null 2>&1 \
    || die "دریافت مخزن ناموفق بود."
  ok "مخزن دریافت شد."
fi

DIST="$SRC_DIR/skin/dist/gui-experimental.cjs"
[ -f "$DIST" ] || die "باندل پوست در مخزن نیست: $DIST"

# ── ۴. نصب پوست ───────────────────────────────────────────
step "۴/۶ فعال‌سازی پوست"
mkdir -p "$PLUGIN_DIR"
if [ -f "$PLUGIN_DIR/gui-experimental.cjs" ] && cmp -s "$DIST" "$PLUGIN_DIR/gui-experimental.cjs"; then
  ok "پوست از قبل به‌روز است."
else
  cp "$DIST" "$PLUGIN_DIR/gui-experimental.cjs"
  ok "پوست نصب/به‌روز شد."
fi
cat > "$PLUGIN_DIR/package.json" <<'EOF'
{
  "name": "opencode-termunix-skin",
  "version": "0.2.0",
  "type": "module",
  "exports": { "./gui-experimental": "./gui-experimental.cjs" }
}
EOF

# ── ۵. دستور Terminux ─────────────────────────────────────
step "۵/۶ نصب دستور اجرا"
if [ -f "$SRC_DIR/bin/termunix" ]; then
  cp "$SRC_DIR/bin/termunix" "$BIN_DIR/termunix"
else
  die "bin/termunix در مخزن پیدا نشد."
fi
chmod +x "$BIN_DIR/termunix"
ln -sf "$BIN_DIR/termunix" "$BIN_DIR/Terminux"
ok "دستورهای «terminux» و «Terminux» نصب شدند."

# ── ۶. راه‌اندازی و اتصال ─────────────────────────────────
step "۶/۶ راه‌اندازی"
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock >/dev/null 2>&1 || true

# استارت خودکار با بوت (اگر Termux:Boot نصب باشد)
BOOT_DIR="$HOME/.termux/boot"
mkdir -p "$BOOT_DIR" 2>/dev/null || true
cat > "$BOOT_DIR/termunix" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
export PATH="$HOME/.opencode/bin:$PATH"
opencode service start >/dev/null 2>&1
EOF
chmod +x "$BOOT_DIR/termunix" 2>/dev/null || true

if [ "$NO_OPEN" = "1" ]; then
  printf "\n%s%s نصب کامل شد.%s\n" "$G" "$B" "$R"
  printf "  شروع: %sTerminux%s\n\n" "$B" "$R"
  exit 0
fi

exec "$BIN_DIR/termunix"
