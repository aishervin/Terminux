#!/data/data/com.termux/files/usr/bin/bash
# TERMINUX doctor: finds why the UI does not load. Read-only; stops anything it starts.
OUT="$HOME/terminux-report.txt"
H() { printf '\n\033[1;38;5;208m== %s ==\033[0m\n' "$*"; }

main() {
  H "Termux"
  echo "arch: $(uname -m)  android: $(getprop ro.build.version.release 2>/dev/null)  sdk: $(getprop ro.build.version.sdk 2>/dev/null)"
  echo "termux source: ${TERMUX_APK_RELEASE:-unknown}  version: ${TERMUX_VERSION:-unknown}"
  echo "free disk: $(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $4}')"
  for c in proot-distro termux-open-url termux-wake-lock curl; do
    if command -v "$c" >/dev/null 2>&1; then echo "ok      $c"; else echo "MISSING $c"; fi
  done
  L="$(command -v termunix || command -v Terminux)"
  if [ -n "$L" ]; then
    if bash -n "$L" 2>/dev/null; then echo "ok      launcher syntax"; else echo "BAD     launcher syntax -> re-run the installer"; fi
    if grep -q TERMINUX_READY "$L"; then echo "ok      launcher is the new (foreground) version"; else echo "OLD     launcher -> re-run the installer"; fi
  else
    echo "MISSING launcher (Terminux / termunix)"
  fi

  H "Ubuntu login"
  if ! proot-distro login ubuntu -- true </dev/null >/dev/null 2>&1; then
    echo "FAIL    cannot enter Ubuntu -> re-run the installer"
    echo "VERDICT: Ubuntu container is broken."
    return
  fi
  echo "ok      Ubuntu login works"

  H "Inside Ubuntu"
  proot-distro login ubuntu -- bash -s <<'EOS'
export PATH="$HOME/.opencode/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
MASK() { sed -E 's#(/auth/connect/)[A-Za-z0-9_-]+#\1***#g'; }

echo "opencode: $(command -v opencode || echo MISSING)  $(opencode --version </dev/null 2>&1 | head -1)"
echo "node: $(node -v </dev/null 2>&1 | head -1)   git: $(git --version </dev/null 2>&1 | head -1)"
if [ -d "$HOME/Terminux/.git" ]; then
  echo "repo: $(git -C "$HOME/Terminux" log -1 --format='%h %s' </dev/null 2>&1)"
else
  echo "repo: MISSING (~/Terminux)"
fi
for f in .config/opencode/opencode.json .config/opencode/cli.json \
         .config/opencode/themes/terminux-charcoal.json \
         .config/opencode/plugins/termunix/gui-experimental.cjs; do
  if [ -f "$HOME/$f" ]; then echo "ok      $f"; else echo "MISSING $f"; fi
done
echo "--- install log (last 6 lines)"
tail -n 6 /tmp/terminux-install.log 2>/dev/null || echo "(no install log)"

up() {
  st="$(opencode service status </dev/null 2>&1)"; rc=$?
  [ "$rc" -eq 0 ] && ! printf '%s' "$st" | grep -qiE 'stopped|not running|inactive|dead'
}

started=0
if up; then
  echo "service: already running"
else
  echo "service: not running -> starting it for the test"
  opencode service start </dev/null 2>&1 | head -5
  started=1
  for i in $(seq 1 20); do up && break; sleep 1; done
  sleep 2
fi

echo "--- service status"
opencode service status </dev/null 2>&1 | MASK | head -10

echo "--- pair link"
pair_out="$(timeout 20 opencode pair </dev/null 2>&1)"
printf '%s\n' "$pair_out" | MASK | head -6
if printf '%s' "$pair_out" | grep -qE 'https?://[^ ]+/auth/connect/[A-Za-z0-9_-]+'; then
  pair_ok=yes
else
  pair_ok=no
fi
echo "launcher can read the pair link: $pair_ok"

echo "--- probing local ports"
ports=""
for f in /proc/net/tcp /proc/net/tcp6; do
  [ -r "$f" ] || continue
  while read -r _ addr _ state _; do
    [ "$state" = "0A" ] && ports="$ports $((16#${addr##*:}))"
  done < <(tail -n +2 "$f")
done
ports="$ports $(printf '%s' "$st" | grep -oE '[0-9]{4,5}' | tr '\n' ' ') 49374 4096"
found=""
for p in $(printf '%s\n' $ports | sort -un); do
  [ "$p" -ge 1024 ] 2>/dev/null || continue
  code="$(curl -s -o /dev/null -m 3 -w '%{http_code}' "http://127.0.0.1:$p/" </dev/null 2>/dev/null)"
  if [ -n "$code" ] && [ "$code" != "000" ]; then
    echo "port $p answers HTTP $code"
    found="$found $p"
  fi
done
[ -z "$found" ] && echo "no local port answers HTTP"

lg="$(ls -t "$HOME"/.local/share/opencode/log/*.log 2>/dev/null | head -1)"
if [ -n "$lg" ]; then
  echo "--- last log ($lg)"
  tail -n 12 "$lg" | MASK
fi

echo
echo "================ VERDICT ================"
if [ -z "$found" ]; then
  echo "The service is NOT serving HTTP. The browser page is empty because nothing is listening."
  echo "Look at 'service status' and the log above. Send me this report."
else
  # Prefer a port named in the service status; then the default; else any answering port.
  first=""
  for p in $(printf '%s' "$st" | grep -oE '[0-9]{4,5}'); do
    case " $found " in *" $p "*) first="$p"; break ;; esac
  done
  if [ -z "$first" ]; then
    case " $found " in *" 49374 "*) first=49374 ;; esac
  fi
  [ -z "$first" ] && first="$(printf '%s\n' $found | head -1)"
  if [ "$first" = "49374" ]; then
    echo "Service answers on 49374 (the launcher default)."
  else
    echo "Service most likely answers on port $first, NOT 49374."
    echo "Fix now:  TERMINUX_PORT=$first Terminux"
    echo "(ports that answered: $found - some may belong to other apps)"
  fi
  if [ "$pair_ok" = "no" ]; then
    echo "The launcher cannot read the pair link, so it falls back to a guessed port. Send me this report."
  else
    echo "Pair link is readable. If the browser still shows nothing: paste http://127.0.0.1:$first into Chrome by hand,"
    echo "and turn off any VPN / proxy / data-saver for the test."
  fi
fi
if [ "$started" = "1" ]; then
  opencode service stop </dev/null >/dev/null 2>&1
  echo "(test service stopped again)"
fi
EOS
}

main 2>&1 | tee "$OUT"
echo
echo "Report saved to: $OUT  (pair tokens are hidden). Send its text to the developer."
