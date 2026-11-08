# Terminux

<p align="center">
  <b>ایجنت کدنویسی محلی روی Termux — با رابط وب فارسی و تم اختصاصی</b>
</p>

<p align="center">
  <a href="https://github.com/aishervin/Terminux"><img alt="repo" src="https://img.shields.io/badge/github-aishervin%2FTerminux-ff7a00?style=flat-square"></a>
  <img alt="opencode" src="https://img.shields.io/badge/opencode-2.2.6-111?style=flat-square">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-3ddc84?style=flat-square">
</p>

Terminux یک **پوست (skin)** برای رابط وب/دسکتاپ [OpenCode](https://opencode.ai) است:
تم رنگی، فونت فارسی، و ریزه‌کاری‌های ظاهری — بدون فورک کردن هسته.

مزیت این روش:

- ✅ **همهٔ قابلیت‌های OpenCode** سر جایشان هستند (سشن، ابزارها، دیف، ترمینال، MCP، …)
- ✅ با آپدیت‌های OpenCode نمی‌شکند
- ✅ همهٔ برند در **یک فایل** است: [`skin/src/brand.ts`](skin/src/brand.ts)
- ✅ نصب با یک دستور

---

## نصب

```bash
curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash
```

نصب‌کننده این کارها را انجام می‌دهد:

1. نصب `curl` / `git` / `nodejs-lts` در Termux
2. نصب OpenCode (اگر نصب نباشد)
3. دریافت پوست و کپی آن در `~/.config/opencode/plugins/termunix`
4. ساخت دستور `termunix`
5. راه‌اندازی سرور و باز کردن رابط در مرورگر

بعد از نصب، هر بار فقط:

```bash
termunix
```

> اولین بار در مرورگر: **Settings › Appearance › Theme › Terminux Neon**

## ساختار

```
Terminux/
├─ install.sh              نصب‌کنندهٔ یک‌خطی
├─ skin/
│  ├─ src/
│  │  ├─ brand.ts          ← همهٔ برند اینجاست (نام، رنگ، لوگو، فونت، لینک)
│  │  ├─ theme.ts          ساخت تم از پالت brand
│  │  ├─ styles.ts         تزریق CSS (فونت، RTL، اسکرول‌بار، خط نئون)
│  │  └─ gui.ts            ورودی پلاگین GUI
│  ├─ dist/                باندل آماده (کامیت می‌شود تا نصب سریع باشد)
│  └─ vite.config.ts
└─ docs/
   └─ customize.md         راهنمای شخصی‌سازی
```

## شخصی‌سازی

فایل `skin/src/brand.ts` را عوض کن، بعد:

```bash
cd skin
bun run build:termux      # روی Termux (بدون نیاز به rollup)
# یا
bun run build             # روی لینوکس/CI
```

سپس فایل `skin/dist/gui-experimental.cjs` را در
`~/.config/opencode/plugins/termunix/` جای‌گذاری کن و صفحه را رفرش کن.

جزئیات: [docs/customize.md](docs/customize.md)

## حذف

```bash
rm -rf ~/.config/opencode/plugins/termunix ~/.termunix
rm -f "$PREFIX/bin/termunix"
```

## مجوز

MIT © aishervin
