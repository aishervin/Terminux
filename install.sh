#!/data/data/com.termux/files/usr/bin/bash
# ─────────────────────────────────────────────────────────────
#  Terminux — نصب‌کنندهٔ خودکار برای Termux
#  استفاده:  curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash
# ─────────────────────────────────────────────────────────────
set -uo pipefail

REPO="${TERMINUX_REPO:-https://github.com/aishervin/Terminux.git}"
BRANCH="${TERMINUX_BRANCH:-main}"
SRC_DIR="${TERMINUX_SRC:-$HOME/.termunix/src}"
PLUGIN_DIR="${TERMINUX_PLUGIN:-$HOME/.config/opencode/plugins/termunix}"
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
NO_OPEN="${TERMINUX_NO_OPEN:-0}"

O=$'\033[38;5;208m'; W=$'\033[97m'; D=$'\033[90m'; OK=$'\033[38;5;114m'
E=$'\033[38;5;203m'; B=$'\033[1m'; R=$'\033[0m'

say()  { printf "%s▸%s %s\n" "$O" "$R" "$*"; }
ok()   { printf "%s✓%s %s\n" "$OK" "$R" "$*"; }
warn() { printf "%s!%s %s\n" "$O" "$R" "$*"; }
die()  { printf "\n%s✕ %s%s\n\n" "$E$B" "$*" "$R" >&2; exit 1; }

banner() {
  printf "\n%s%s" "$O" "$B"
  cat <<'ART'
   ┌─────────────────────────────────────┐
   │   T E R M I N U X                   │
   │   local coding agent · termux       │
   └─────────────────────────────────────┘
ART
  printf "%s\n" "$R"
}

# 0. محیط
case "${PREFIX:-}" in
  *com.termux*) : ;;
  *) die "این نصب‌کننده مخصوص Termux است (PREFIX پیدا نشد)." ;;
esac
[ -x "$BIN_DIR/bash" ] || die "bash در Termux پیدا نشد."

banner

# 1. بسته‌های پایه
say "۱/۵ بررسی پیش‌نیازها…"
command -v pkg >/dev/null 2>&1 || die "pkg پیدا نشد؛ Termux سالم نیست."
pkg install -y curl git nodejs-lts >/dev/null 2>&1 || warn "نصب برخی بسته‌ها هشدار داد (احتمالاً از قبل نصب بودند)."
ok "curl / git / node آماده‌اند."

# 2. OpenCode
say "۲/۵ نصب OpenCode…"
export PATH="$HOME/.opencode/bin:$BIN_DIR:$PATH"
if command -v opencode >/dev/null 2>&1; then
  ok "OpenCode از قبل نصب است: $(opencode --version 2>/dev/null | head -1)"
else
  curl -fsSL https://opencode.ai/v2/install | bash || die "نصب OpenCode ناموفق بود."
  export PATH="$HOME/.opencode/bin:$BIN_DIR:$PATH"
  command -v opencode >/dev/null 2>&1 || die "opencode پس از نصب پیدا نشد."
  ok "OpenCode نصب شد: $(opencode --version 2>/dev/null | head -1)"
fi

# 3. دریافت پوست Terminux
say "۳/۵ دریافت پوست Terminux…"
if [ -d "$SRC_DIR/.git" ]; then
  git -C "$SRC_DIR" fetch --depth 1 origin "$BRANCH" >/dev/null 2>&1 \
    && git -C "$SRC_DIR" reset --hard "origin/$BRANCH" >/dev/null 2>&1 \
    || warn "به‌روزرسانی پوست ناموفق بود؛ از نسخهٔ موجود استفاده می‌شود."
else
  rm -rf "$SRC_DIR"
  git clone --depth 1 --branch "$BRANCH" "$REPO" "$SRC_DIR" >/dev/null 2>&1 \
    || die "دریافت مخزن ناموفق بود."
fi
[ -f "$SRC_DIR/skin/dist/gui-experimental.cjs" ] || die "فایل پوست در مخزن پیدا نشد."
ok "پوست دریافت شد."

# 4. نصب پوست در OpenCode
say "۴/۵ فعال‌سازی پوست…"
mkdir -p "$PLUGIN_DIR"
cp "$SRC_DIR/skin/dist/gui-experimental.cjs" "$PLUGIN_DIR/"
cp "$SRC_DIR/skin/package.json" "$PLUGIN_DIR/" 2>/dev/null || true
# package.json مخصوص پلاگین (نه پکیج build)
cat > "$PLUGIN_DIR/package.json" <<'EOF'
{
  "name": "opencode-termunix-skin",
  "version": "0.1.0",
  "type": "module",
  "exports": { "./gui-experimental": "./gui-experimental.cjs" }
}
EOF
ok "پلاگین در $PLUGIN_DIR نصب شد."

# 5. اجرا
say "۵/۵ راه‌اندازی سرور و اتصال…"
opencode service start >/dev/null 2>&1 || true
sleep 2

# دستور کوتاه
cat > "$BIN_DIR/termunix" <<'WRAP'
#!/data/data/com.termux/files/usr/bin/bash
export PATH="$HOME/.opencode/bin:/data/data/com.termux/files/usr/bin:$PATH"
opencode service start >/dev/null 2>&1 || true
LINK=$(opencode pair 2>/dev/null | grep -oE 'https?://[^ ]+/auth/connect/[A-Za-z0-9_-]+' | head -1)
if [ -n "$LINK" ]; then
  termux-open-url "$LINK" >/dev/null 2>&1 || echo "$LINK"
else
  echo "لینک ساخته نشد. دستی بزن: opencode pair"
fi
WRAP
chmod +x "$BIN_DIR/termunix"

if [ "$NO_OPEN" = "1" ]; then
  ok "نصب کامل شد. برای شروع: termunix"
else
  LINK=$(opencode pair 2>/dev/null | grep -oE 'https?://[^ ]+/auth/connect/[A-Za-z0-9_-]+' | head -1)
  if [ -n "$LINK" ]; then
    termux-open-url "$LINK" >/dev/null 2>&1 || printf "\n%s\n\n" "$LINK"
    ok "رابط کاربری در مرورگر باز شد."
  else
    warn "لینک خودکار ساخته نشد. بعداً بزن: termunix"
  fi
fi

printf "\n%s%s نصب کامل شد!%s\n" "$OK" "$B" "$R"
printf "  %s▸%s دفعهٔ بعد فقط بزن:  %stermunix%s\n" "$O" "$R" "$B" "$R"
printf "  %s▸%s تم: Settings › Appearance › Theme › %sTerminux Neon%s\n" "$O" "$R" "$B" "$R"
printf "  %s▸%s شخصی‌سازی: %s%s/skin/src/brand.ts%s\n\n" "$O" "$R" "$D" "$SRC_DIR" "$R"
