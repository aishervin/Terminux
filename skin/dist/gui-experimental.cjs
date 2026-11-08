var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __hasOwnProp = Object.prototype.hasOwnProperty;
function __accessProp(key) {
  return this[key];
}
var __toCommonJS = (from) => {
  var entry = (__moduleCache ??= new WeakMap).get(from), desc;
  if (entry)
    return entry;
  entry = __defProp({}, "__esModule", { value: true });
  if (from && typeof from === "object" || typeof from === "function") {
    for (var key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(entry, key))
        __defProp(entry, key, {
          get: __accessProp.bind(from, key),
          enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable
        });
  }
  __moduleCache.set(from, entry);
  return entry;
};
var __moduleCache;
var __returnValue = (v) => v;
function __exportSetter(name, newValue) {
  this[name] = __returnValue.bind(null, newValue);
}
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, {
      get: all[name],
      enumerable: true,
      configurable: true,
      set: __exportSetter.bind(all, name)
    });
};

// src/gui.ts
var exports_gui = {};
__export(exports_gui, {
  default: () => gui_default
});
module.exports = __toCommonJS(exports_gui);
var import_gui = require("@opencode/plugin/gui");

// src/brand.ts
var brand = {
  name: "Terminux",
  themeName: "Terminux Neon",
  themeId: "termunix-neon",
  tagline: "ایجنت کدنویسی محلی روی Termux",
  version: "0.1.0",
  logo: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" role="img" aria-label="Terminux">
  <defs>
    <linearGradient id="tg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FF9A3C"/>
      <stop offset="1" stop-color="#FF5E00"/>
    </linearGradient>
  </defs>
  <rect x="2" y="2" width="60" height="60" rx="16" fill="url(#tg)"/>
  <path d="M18 21l12 11-12 11" fill="none" stroke="#0b0b0d" stroke-width="5"
        stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="34" y="39" width="14" height="5" rx="2.5" fill="#0b0b0d"/>
</svg>`,
  links: {
    github: "https://github.com/aishervin/Terminux",
    telegram: "https://t.me/shervini",
    x: "https://x.com/shervinonx"
  },
  font: {
    family: "Vazirmatn",
    stylesheet: "https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300..900&family=JetBrains+Mono:wght@400;600&display=swap",
    mono: "JetBrains Mono"
  },
  colors: {
    dark: {
      neutral: "#0b0b0d",
      ink: "#f4f4f5",
      primary: "#ff7a00",
      accent: "#ffb066",
      success: "#3ddc84",
      warning: "#ffb020",
      error: "#ff4d6d",
      info: "#26a5e4",
      diffAdd: "#2ea043",
      diffDelete: "#f85149"
    },
    light: {
      neutral: "#fbfaf8",
      ink: "#16161a",
      primary: "#e86a00",
      accent: "#8a4a10",
      success: "#127a3c",
      warning: "#9a6200",
      error: "#c4213f",
      info: "#0b6fa4",
      diffAdd: "#1a7f37",
      diffDelete: "#cf222e"
    }
  },
  applyByDefault: true,
  style: {
    topLine: true,
    glow: true,
    radius: 12,
    gradientBackground: true,
    selection: "#ff7a00"
  }
};

// src/styles.ts
function buildCss(b = brand) {
  const dark = b.colors.dark;
  const p = dark.primary;
  const parts = [];
  if (b.font.stylesheet)
    parts.push(`@import url("${b.font.stylesheet}");`);
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
`);
  if (b.style.gradientBackground) {
    parts.push(`
body {
  background-image:
    radial-gradient(1100px 520px at 100% -10%, color-mix(in oklab, ${p} 10%, transparent), transparent 62%),
    radial-gradient(900px 480px at -10% 110%, color-mix(in oklab, ${dark.info} 7%, transparent), transparent 60%);
  background-attachment: fixed;
}
`);
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
`);
  }
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
`);
  parts.push(`
button, input, textarea, select, [role="button"] {
  border-radius: var(--termunix-radius);
}
`);
  const logo = `data:image/svg+xml,${encodeURIComponent(b.logo)}`;
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
`);
  parts.push(`
.termunix-brand {
  display: inline-flex;
  align-items: center;
  gap: .5rem;
  font-weight: 700;
  letter-spacing: .01em;
}
.termunix-brand__mark { width: 1.15em; height: 1.15em; display: block; }
`);
  return parts.join(`
`);
}

// src/theme.ts
function buildTheme(b = brand) {
  const d = b.colors.dark;
  const l = b.colors.light;
  return {
    $schema: "https://opencode.ai/desktop-theme.json",
    name: b.themeName,
    id: b.themeId,
    dark: {
      palette: {
        neutral: d.neutral,
        ink: d.ink,
        primary: d.primary,
        accent: d.accent,
        success: d.success,
        warning: d.warning,
        error: d.error,
        info: d.info,
        interactive: d.primary,
        diffAdd: d.diffAdd,
        diffDelete: d.diffDelete
      },
      overrides: {
        "text-weak": "#8b8b93",
        "syntax-comment": "#6f6f78",
        "syntax-keyword": d.primary,
        "syntax-string": d.success,
        "syntax-primitive": d.accent,
        "syntax-variable": "#ff8fa3",
        "syntax-property": d.info,
        "syntax-type": "#e5c07b",
        "syntax-constant": d.accent,
        "syntax-operator": d.info,
        "syntax-punctuation": "#a1a1aa",
        "syntax-object": "#ff8fa3",
        "markdown-heading": d.primary,
        "markdown-text": d.ink,
        "markdown-link": d.primary,
        "markdown-link-text": d.info,
        "markdown-code": d.success,
        "markdown-block-quote": "#e5c07b",
        "markdown-emph": "#e5c07b",
        "markdown-strong": d.primary,
        "markdown-horizontal-rule": "#52525b",
        "markdown-list-item": d.primary,
        "markdown-list-enumeration": d.info,
        "markdown-image": d.primary,
        "markdown-image-text": d.info,
        "markdown-code-block": d.ink
      }
    },
    light: {
      palette: {
        neutral: l.neutral,
        ink: l.ink,
        primary: l.primary,
        accent: l.accent,
        success: l.success,
        warning: l.warning,
        error: l.error,
        info: l.info,
        interactive: l.primary,
        diffAdd: l.diffAdd,
        diffDelete: l.diffDelete
      },
      overrides: {
        "text-weak": "#6b6b73",
        "syntax-comment": "#8a8a90",
        "syntax-keyword": l.primary,
        "syntax-string": l.success,
        "syntax-primitive": l.accent,
        "syntax-variable": l.error,
        "syntax-property": l.info,
        "syntax-type": "#8a5a00",
        "syntax-constant": l.accent,
        "syntax-operator": l.info,
        "syntax-punctuation": l.ink,
        "syntax-object": l.error,
        "markdown-heading": l.primary,
        "markdown-text": l.ink,
        "markdown-link": l.primary,
        "markdown-link-text": l.info,
        "markdown-code": l.success,
        "markdown-block-quote": "#8a5a00",
        "markdown-emph": "#8a5a00",
        "markdown-strong": l.primary,
        "markdown-horizontal-rule": "#b8b8bf",
        "markdown-list-item": l.primary,
        "markdown-list-enumeration": l.info,
        "markdown-image": l.primary,
        "markdown-image-text": l.info,
        "markdown-code-block": l.ink
      }
    }
  };
}

// src/gui.ts
var THEME_KEY = "opencode-theme-id";
var INIT_FLAG = "termunix.theme.initialized";
function applyDefaultTheme(pluginId) {
  try {
    if (!brand.applyByDefault)
      return;
    if (localStorage.getItem(INIT_FLAG))
      return;
    localStorage.setItem(INIT_FLAG, "1");
    const want = `${pluginId}:${brand.themeId}`;
    if (localStorage.getItem(THEME_KEY) === want)
      return;
    localStorage.setItem(THEME_KEY, want);
    setTimeout(() => {
      try {
        location.reload();
      } catch {}
    }, 600);
  } catch {}
}
var gui_default = import_gui.Plugin.define({
  i18n: {
    en: {
      "termunix.name": brand.name,
      "termunix.tagline": brand.tagline,
      "termunix.about": `${brand.name} ${brand.version}`
    },
    fa: {
      "termunix.name": brand.name,
      "termunix.tagline": brand.tagline,
      "termunix.about": `${brand.name} ${brand.version}`
    }
  },
  setup(ctx) {
    ctx.add(import_gui.Theme, buildTheme());
    ctx.add(import_gui.Style, buildCss());
    applyDefaultTheme(ctx.id);
    try {
      document.title = `${brand.name} — OpenCode`;
    } catch {}
  }
});
