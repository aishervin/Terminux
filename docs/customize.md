# شخصی‌سازی Terminux

همهٔ چیزهایی که ظاهر را می‌سازند در `skin/src/` هستند.

## ۱. برند: `brand.ts`

| فیلد | کاربرد |
|---|---|
| `name` / `tagline` / `version` | نام و شعار نمایشی |
| `themeName` / `themeId` | نام تم در لیست تم‌ها و شناسهٔ یکتا |
| `logo` | دادهٔ base64 لوگو — از `assets/shen_logo.png` ساخته می‌شود (دستی ویرایش نکن) |
| `links` | گیت‌هاب / تلگرام / X |
| `font.family` | خانوادهٔ فونت رابط |
| `font.stylesheet` | آدرس CSS فونت (خالی = فونت سیستم) |
| `font.mono` | فونت کد |
| `colors.dark` / `colors.light` | پالت؛ تم از همین‌ها ساخته می‌شود |
| `applyByDefault` | تم برند خودکار انتخاب شود (پیش‌فرض: `true`) |
| `behavior.enterToSend` | `false` = Enter خط جدید (پیش‌فرض)، ارسال با Ctrl/Cmd+Enter |
| `style.*` | خط نئون، گرادیان، انحنا، رنگ انتخاب متن، نشان گوشه |

برای عوض کردن لوگو، `assets/shen_logo.png` را جای‌گذاری کن و `bun run logo` بزن.

## ۲. تم: `theme.ts`

تم از `palette` ساخته می‌شود. اگر خواستی توکن خاصی را دستی بگذاری،
از `overrides` استفاده کن (مثل نمونه‌های `syntax-*` و `markdown-*`).

فرمت کامل: `https://opencode.ai/desktop-theme.json`

## ۳. استایل: `styles.ts`

CSS به‌صورت رشته ساخته و تزریق می‌شود. چیزهایی که الان دارد:

- `@import` فونت
- متغیرهای `--font-family-sans` / `--font-family-mono`
- خط نئون بالای صفحه (`body::before`)
- گرادیان ملایم پس‌زمینه
- اسکرول‌بار و رنگ انتخاب متن
- در حالت RTL، کدها چپ‌به‌راست می‌مانند

برای اضافه کردن استایل جدید، یک رشته به آرایهٔ `parts` اضافه کن.

## ۴. ساخت

```bash
cd skin
bun install
bun run brand             # logo + build:termux
```

خروجی: `skin/dist/gui-experimental.cjs`

> چرا `build:termux`؟ چون در proot ترمکس، ماژول نیتیو rollup
> قابل `dlopen` نیست؛ `bun build` از این مشکل ندارد.

## ۵. اعمال

```bash
cp skin/dist/gui-experimental.cjs ~/.config/opencode/plugins/termunix/
# یا اگر از گیت‌هاب نصب کرده‌ای:
Terminux update
```

بعد صفحهٔ وب را رفرش کن (Ctrl+Shift+R).

## ۶. اضافه کردن قابلیت به پلاگین

در `gui.ts` می‌توانی از رجیستری‌های SDK استفاده کنی:

| رجیستری | کاربرد |
|---|---|
| `Style` | تزریق CSS |
| `Theme` | افزودن تم |
| `Command` | فرمان در پالت فرمان‌ها |
| `SettingsPage` | صفحهٔ تنظیمات اختصاصی |
| `Panel` | پنل کنار صفحه |
| `Slot` | جای‌گذاری کامپوننت (مثلاً `window.bottom`) |
| `TitlebarItem` / `ComposerPill` | آیتم در نوار عنوان / کنار ورودی چت |

مستندات: <https://opencode.ai/docs/build/plugins/gui>

> ⚠️ API پلاگین GUI هنوز experimental است؛ نسخهٔ OpenCode را در
> `install.sh` و `package.json` پین نگه دار.
