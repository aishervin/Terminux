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

نصب‌کننده کاملاً خودکار و تکرارپذیر است — فقط چیزهایی را نصب می‌کند که نیست:

1. بررسی محیط Termux
2. نصب فقط پیش‌نیازهای غایب: `curl` / `git` / `nodejs-lts` / `termux-tools`
3. نصب OpenCode (اگر نباشد) + تنظیم دائمی `PATH`
4. دریافت پوست و کپی باندل در `~/.config/opencode/plugins/termunix`
5. ساخت دستور `Terminux`
6. wake-lock، هوک `Termux:Boot`، راه‌اندازی سرور و باز کردن UI در مرورگر

بعد از نصب، هر بار فقط:

```bash
Terminux
```

> تم برند (`Terminux Charcoal`) **خودکار** اعمال می‌شود؛ نیازی به انتخاب دستی نیست.

### دستورها

| دستور | کار |
|---|---|
| `Terminux` | سرور را بالا می‌آورد و UI را باز می‌کند |
| `Terminux link` | فقط لینک اتصال را چاپ می‌کند |
| `Terminux status` | وضعیت سرور و پوست |
| `Terminux update` | به‌روزرسانی پوست از گیت‌هاب |
| `Terminux stop` / `restart` | توقف / راه‌اندازی مجدد سرور |
| `Terminux uninstall` | حذف پوست و دستورها (سشن‌ها می‌مانند) |

## ساختار

```
Terminux/
├─ install.sh              نصب‌کنندهٔ یک‌خطی و idempotent
├─ bin/termunix            لانچر (Terminux هم به همین اشاره می‌کند)
├─ skin/
│  ├─ assets/shen_logo.png لوگوی خام
│  ├─ scripts/embed-logo.mjs
│  ├─ src/
│  │  ├─ brand.ts          ← همهٔ برند اینجاست (نام، رنگ، لوگو، فونت، رفتار)
│  │  ├─ theme.ts          ساخت تم از پالت brand
│  │  ├─ styles.ts         تزریق CSS (فونت، RTL، اسکرول‌بار، نشان گوشه)
│  │  ├─ logo.ts           لوگو به‌صورت base64 (خودکار ساخته می‌شود)
│  │  └─ gui.ts            ورودی پلاگین GUI
│  └─ dist/                باندل آماده (کامیت می‌شود تا نصب سریع باشد)
└─ docs/
   └─ customize.md         راهنمای شخصی‌سازی
```

## شخصی‌سازی

**لوگو:** `skin/assets/shen_logo.png` را جای‌گذاری کن.

**رنگ/نام/رفتار:** `skin/src/brand.ts` را عوض کن.

بعد فقط:

```bash
cd skin
bun run brand             # لوگو + باندل را از نو می‌سازد
```

سپس `skin/dist/gui-experimental.cjs` را در
`~/.config/opencode/plugins/termunix/` بگذار (یا `Terminux update` بزن).

جزئیات: [docs/customize.md](docs/customize.md)

## حذف

```bash
Terminux uninstall
```

## مجوز

MIT © aishervin
