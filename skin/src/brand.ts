/**
 * ─────────────────────────────────────────────────────────────
 *  Terminux — BRAND FILE
 *  همه‌چیزِ ظاهری از همین فایل خوانده می‌شود.
 *  برای شخصی‌سازی، فقط همین فایل را عوض کن، بعد: bun run build
 * ─────────────────────────────────────────────────────────────
 */

export const brand = {
  /** نام نمایشی محصول (در تم و صفحهٔ درباره) */
  name: "Terminux",
  /** نام کوتاه/لاتین برای تم */
  themeName: "Terminux Neon",
  /** شناسهٔ تم — فقط حروف کوچک، عدد و خط تیره */
  themeId: "termunix-neon",
  tagline: "ایجنت کدنویسی محلی روی Termux",
  version: "0.1.0",

  /** لوگو به صورت SVG inline. هر SVG دیگری بگذاری، همان استفاده می‌شود. */
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

  /** لینک‌ها */
  links: {
    github: "https://github.com/aishervin/Terminux",
    telegram: "https://t.me/shervini",
    x: "https://x.com/shervinonx",
  },

  /** فونت رابط کاربری */
  font: {
    /** نام خانوادهٔ فونت */
    family: "Vazirmatn",
    /** آدرس CSS فونت (می‌توانی خالی بگذاری تا از فونت سیستم استفاده شود) */
    stylesheet:
      "https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300..900&family=JetBrains+Mono:wght@400;600&display=swap",
    /** فونت کد */
    mono: "JetBrains Mono",
  },

  /** پالت رنگ: منبع تولید کل تم */
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
      diffDelete: "#f85149",
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
      diffDelete: "#cf222e",
    },
  },

  /** تمِ برند به‌صورت پیش‌فرض انتخاب شود (یک‌بار رفرش خودکار) */
  applyByDefault: true,

  /** ریزه‌کاری‌های ظاهری */
  style: {
    /** خط نئون بالای صفحه */
    topLine: true,
    /** درخشش دکمهٔ اصلی */
    glow: true,
    /** انحنای گوشه‌ها (px) */
    radius: 12,
    /** پس‌زمینهٔ گرادیانی ملایم */
    gradientBackground: true,
    /** انتخاب متن */
    selection: "#ff7a00",
  },
} as const

export type Brand = typeof brand
