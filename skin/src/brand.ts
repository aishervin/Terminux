/**
 * ─────────────────────────────────────────────────────────────
 *  TΞRMINUX™ — BRAND FILE
 *  همه‌چیزِ ظاهری از همین فایل خوانده می‌شود.
 *  برای شخصی‌سازی، فقط همین فایل را عوض کن، بعد: bun run brand
 * ─────────────────────────────────────────────────────────────
 */

import { LOGO_PNG } from "./logo"

export const brand = {
  /** نام نمایشی محصول */
  name: "TΞRMINUX™",
  /** نام کوتاه/لاتین برای تم */
  themeName: "Terminux Charcoal",
  /** شناسهٔ تم — فقط حروف کوچک، عدد و خط تیره */
  themeId: "terminux-charcoal",
  tagline: "local coding agent · termux",
  version: "0.2.0",

  /** لوگو (PNG به‌صورت data URI). برای عوض کردن: assets/shen_logo.png را جای‌گذاری کن. */
  logo: LOGO_PNG,

  /** لینک‌ها */
  links: {
    github: "https://github.com/aishervin/Terminux",
    telegram: "https://t.me/shervini",
    x: "https://x.com/shervinonx",
  },

  /** فونت رابط کاربری */
  font: {
    family: "Vazirmatn",
    stylesheet:
      "https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300..900&family=JetBrains+Mono:wght@400;600&display=swap",
    mono: "JetBrains Mono",
  },

  /**
   * پالت: مشکی ذغالی + طوسی + نارنجی
   * تم از همین‌ها ساخته می‌شود.
   */
  colors: {
    dark: {
      neutral: "#0d0d0f",
      ink: "#ececed",
      primary: "#ff7a00",
      accent: "#ffa64d",
      success: "#3ddc84",
      warning: "#ffb020",
      error: "#ff4d6d",
      info: "#8b8b95",
      diffAdd: "#2ea043",
      diffDelete: "#f85149",
    },
    light: {
      neutral: "#f4f4f5",
      ink: "#17171a",
      primary: "#e86a00",
      accent: "#8a4a10",
      success: "#127a3c",
      warning: "#9a6200",
      error: "#c4213f",
      info: "#5a5a63",
      diffAdd: "#1a7f37",
      diffDelete: "#cf222e",
    },
  },

  /** تمِ برند به‌صورت پیش‌فرض انتخاب شود (یک‌بار رفرش خودکار) */
  applyByDefault: true,

  /** رفتار ورودی */
  behavior: {
    /**
     * false = Enter خط جدید می‌زند، ارسال با Ctrl/Cmd+Enter یا دکمهٔ ارسال.
     * true  = Enter ارسال می‌کند (رفتار دسکتاپ OpenCode).
     */
    enterToSend: false,
  },

  /** ریزه‌کاری‌های ظاهری */
  style: {
    /** خط نئون بالای صفحه */
    topLine: true,
    /** پس‌زمینهٔ گرادیانی ملایم */
    gradientBackground: true,
    /** انحنای گوشه‌ها (px) */
    radius: 12,
    /** رنگ انتخاب متن */
    selection: "#ff7a00",
    /** اندازهٔ نشان گوشه (px) */
    badgeSize: 30,
    /** نشان گوشه در موبایل نمایش داده شود؟ */
    badgeOnMobile: true,
  },
} as const

export type Brand = typeof brand
