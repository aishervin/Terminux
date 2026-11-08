import { brand, type Brand } from "./brand"

/** CSS پوست را از مقادیر brand می‌سازد */
export function buildCss(b: Brand = brand): string {
  const dark = b.colors.dark
  const p = dark.primary

  const parts: string[] = []

  if (b.font.stylesheet) parts.push(`@import url("${b.font.stylesheet}");`)

  parts.push(`
:root {
  --font-family-sans: "${b.font.family}", "Inter", ui-sans-serif, system-ui, -apple-system, sans-serif;
  --font-family-mono: "${b.font.mono}", "IBM Plex Mono", ui-monospace, SFMono-Regular, monospace;
  --termunix-radius: ${b.style.radius}px;
  --termunix-accent: ${p};
}

::selection { background: ${b.style.selection}; color: #0b0b0d; }

/* حلقهٔ فوکوس هم‌رنگ برند */
:focus-visible { outline-color: ${p}; }

/* اسکرول‌بار */
* { scrollbar-color: color-mix(in oklab, ${p} 45%, transparent) transparent; }
::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-thumb {
  background: color-mix(in oklab, ${p} 35%, transparent);
  border-radius: 999px;
  border: 2px solid transparent;
  background-clip: content-box;
}
::-webkit-scrollbar-thumb:hover { background: color-mix(in oklab, ${p} 60%, transparent); background-clip: content-box; }
`)

  if (b.style.gradientBackground) {
    parts.push(`
body {
  background-image:
    radial-gradient(1100px 520px at 100% -10%, color-mix(in oklab, ${p} 10%, transparent), transparent 62%),
    radial-gradient(900px 480px at -10% 110%, color-mix(in oklab, ${dark.info} 7%, transparent), transparent 60%);
  background-attachment: fixed;
}
`)
  }

  if (b.style.topLine) {
    parts.push(`
body::before {
  content: "";
  position: fixed;
  inset: 0 0 auto 0;
  height: 2px;
  z-index: 2147483000;
  pointer-events: none;
  background: linear-gradient(90deg,
    transparent 0%,
    color-mix(in oklab, ${p} 85%, transparent) 35%,
    ${p} 50%,
    color-mix(in oklab, ${p} 85%, transparent) 65%,
    transparent 100%);
  opacity: .9;
}
`)
  }

  /* در حالت راست‌به‌چپ: کد همیشه چپ‌به‌راست بماند */
  parts.push(`
html[dir="rtl"] pre,
html[dir="rtl"] code,
html[dir="rtl"] kbd,
html[dir="rtl"] .font-mono {
  direction: ltr;
  text-align: left;
  unicode-bidi: plaintext;
}

html[dir="rtl"] { --termunix-rtl: 1; }
`)

  /* گوشه‌های نرم‌تر برای کنترل‌ها */
  parts.push(`
button, input, textarea, select, [role="button"] {
  border-radius: var(--termunix-radius);
}
`)

  /* نشان برندِ شناور (فعلاً بدون نیاز به کامپوننت) */
  const logo = `data:image/svg+xml,${encodeURIComponent(b.logo)}`
  parts.push(`
body::after {
  content: "";
  position: fixed;
  inset-inline-end: 12px;
  bottom: 12px;
  width: 26px;
  height: 26px;
  background: url("${logo}") center / contain no-repeat;
  opacity: .35;
  pointer-events: none;
  z-index: 2147483000;
  filter: drop-shadow(0 0 6px color-mix(in oklab, ${p} 45%, transparent));
}
`)

  /* نشان برند — برای استفاده در کامپوننت‌های بعدی */
  parts.push(`
.termunix-brand {
  display: inline-flex;
  align-items: center;
  gap: .5rem;
  font-weight: 700;
  letter-spacing: .01em;
}
.termunix-brand__mark { width: 1.15em; height: 1.15em; display: block; }
`)

  return parts.join("\n")
}
