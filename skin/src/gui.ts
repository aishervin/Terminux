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

/** Enter را به «خط جدید» تبدیل می‌کند؛ ارسال با Ctrl/Cmd+Enter یا دکمهٔ ارسال */
function applyEnterBehavior() {
  if (brand.behavior.enterToSend) return
  try {
    document.addEventListener(
      "keydown",
      (event: KeyboardEvent) => {
        if (event.key !== "Enter") return
        if (event.shiftKey || event.ctrlKey || event.metaKey || event.altKey) return
        if (event.isComposing || event.keyCode === 229) return

        const el = event.target as HTMLElement | null
        if (!el) return
        if (!el.isContentEditable && el.tagName !== "TEXTAREA") return

        event.preventDefault()
        event.stopImmediatePropagation()
        try {
          document.execCommand("insertLineBreak")
        } catch {
          /* noop */
        }
      },
      true,
    )
  } catch {
    /* noop */
  }
}

/** عنوان تب، فاوآیکون، آیکون PWA و theme-color را با برند هم‌سان می‌کند */
function applyBrandChrome() {
  try {
    document.title = brand.name

    const isPng = brand.logo.startsWith("data:image/png")
    const setLink = (rel: string, href: string, extra: Record<string, string> = {}) => {
      let el = document.head.querySelector<HTMLLinkElement>(`link[rel="${rel}"][data-termunix]`)
      if (!el) {
        el = document.createElement("link")
        el.rel = rel
        el.dataset.termunix = "1"
        document.head.appendChild(el)
      }
      el.href = href
      for (const [k, v] of Object.entries(extra)) el.setAttribute(k, v)
    }

    const type = isPng ? { type: "image/png" } : { type: "image/svg+xml" }
    setLink("icon", brand.logo, type)
    setLink("apple-touch-icon", brand.logo)
    setLink("mask-icon", brand.logo)

    const meta = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]')
    if (meta) meta.setAttribute("content", brand.colors.dark.neutral)

    const ensureMeta = (name: string, content: string) => {
      let el = document.head.querySelector<HTMLMetaElement>(`meta[name="${name}"]`)
      if (!el) {
        el = document.createElement("meta")
        el.name = name
        document.head.appendChild(el)
      }
      el.content = content
    }
    ensureMeta("apple-mobile-web-app-title", brand.name)
    ensureMeta("application-name", brand.name)
    ensureMeta("mobile-web-app-capable", "yes")

    document.documentElement.style.setProperty("--termunix-accent", brand.colors.dark.primary)
  } catch {
    /* noop */
  }
}

/**
 * ورودی پلاگین GUI.
 * عمداً کوچک نگه داشته شده: فقط تم + CSS + برندینگ.
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
    applyBrandChrome()
    applyEnterBehavior()
    applyDefaultTheme(ctx.id)
  },
})
