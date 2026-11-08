import type { Theme } from "@opencode/plugin/gui"
import { brand, type Brand } from "./brand"

/**
 * تم را از پالتِ brand می‌سازد.
 * اگر خواستی تک‌تک توکن‌ها را دستی بگذاری، از overrides استفاده کن.
 */
export function buildTheme(b: Brand = brand): Theme {
  const d = b.colors.dark
  const l = b.colors.light

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
        diffDelete: d.diffDelete,
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
        "markdown-code-block": d.ink,
      },
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
        diffDelete: l.diffDelete,
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
        "markdown-code-block": l.ink,
      },
    },
  }
}
