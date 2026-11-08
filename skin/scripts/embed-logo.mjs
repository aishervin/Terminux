#!/usr/bin/env bun
/**
 * assets/ را می‌خواند و src/logo.ts را می‌سازد.
 * استفاده:  bun run logo
 */
import { readFileSync, writeFileSync } from "node:fs"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const root = dirname(dirname(fileURLToPath(import.meta.url)))
const src = join(root, "assets", "shen_logo.png")
const out = join(root, "src", "logo.ts")

const b64 = readFileSync(src).toString("base64")
const file = `// این فایل خودکار ساخته می‌شود — دستی ویرایش نکن.
// برای عوض کردن لوگو: فایل assets/shen_logo.png را جای‌گذاری کن و \`bun run logo\` بزن.
export const LOGO_PNG = "data:image/png;base64,${b64}"
`
writeFileSync(out, file)
console.log(`✓ ${out} (${(file.length / 1024).toFixed(1)} KB)`)
