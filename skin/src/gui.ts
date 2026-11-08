import { Plugin, Style, Theme } from "@opencode/plugin/gui"
import { brand } from "./brand"
import { buildCss } from "./styles"
import { buildTheme } from "./theme"

const THEME_KEY = "opencode-theme-id"
const INIT_FLAG = "termunix.theme.initialized"

/**
 * تم برند را یک‌بار به‌صورت پیش‌فرض انتخاب می‌کند.
 * پرچمِ INIT_FLAG تضمین می‌کند فقط یک‌بار اجرا شود، پس اگر کاربر
 * بعداً تم را عوض کند، ما دوباره رویش نمی‌پریم.
 */
function applyDefaultTheme(pluginId: string) {
  try {
    if (!brand.applyByDefault) return
    if (localStorage.getItem(INIT_FLAG)) return
    localStorage.setItem(INIT_FLAG, "1")

    const want = `${pluginId}:${brand.themeId}`
    if (localStorage.getItem(THEME_KEY) === want) return

    localStorage.setItem(THEME_KEY, want)
    // یک‌بار رفرش تا اسکریپت preload تم را از اول بخواند
    setTimeout(() => {
      try {
        location.reload()
      } catch {
        /* noop */
      }
    }, 600)
  } catch {
    /* localStorage ممکن است در دسترس نباشد */
  }
}

/**
 * ورودی پلاگین GUI.
 * عمداً کوچک نگه داشته شده: فقط تم + CSS + ترجمه + برندینگ.
 * چیزی از رفتار یا چیدمان OpenCode عوض نمی‌شود.
 */
export default Plugin.define({
  i18n: {
    en: {
      "termunix.name": brand.name,
      "termunix.tagline": brand.tagline,
      "termunix.about": `${brand.name} ${brand.version}`,
    },
    fa: {
      "termunix.name": brand.name,
      "termunix.tagline": brand.tagline,
      "termunix.about": `${brand.name} ${brand.version}`,
    },
  },

  setup(ctx) {
    ctx.add(Theme, buildTheme())
    ctx.add(Style, buildCss())

    applyDefaultTheme(ctx.id)

    try {
      document.title = `${brand.name} — OpenCode`
    } catch {
      /* noop */
    }
  },
})
