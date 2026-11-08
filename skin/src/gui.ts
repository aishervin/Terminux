import { Plugin, Style, Theme } from "@opencode/plugin/gui"
import { brand } from "./brand"
import { buildCss } from "./styles"
import { buildTheme } from "./theme"

/**
 * ورودی پلاگین GUI.
 * عمداً کوچک نگه داشته شده: فقط تم + CSS + ترجمه.
 * بقیهٔ رفتارها (پنل‌ها، دستورها، صفحهٔ تنظیمات) بعداً به همین setup اضافه می‌شود.
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
  },
})
