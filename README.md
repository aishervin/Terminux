# TΞRMINUX™

<p align="center"><b>ایجنت کدنویسی OpenCode روی اندروید، با نصب خودکار محیط Linux در Termux</b></p>

<p align="center">
  <a href="https://github.com/aishervin/Terminux"><img alt="GitHub" src="https://img.shields.io/badge/GitHub-aishervin%2FTerminux-ff7a00?style=flat-square"></a>
  <img alt="Runtime" src="https://img.shields.io/badge/runtime-Debian%20%2B%20proot-orange?style=flat-square">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-3ddc84?style=flat-square">
</p>

Terminux اجرای OpenCode را در یک محیط کامل Debian داخل Termux مدیریت می‌کند. این روش از اجرای مستقیم باینری Linux روی Android جلوگیری می‌کند و وابستگی‌های موردنیاز را خودش نصب می‌کند.

## نصب یک‌خطی

داخل Termux اجرا کن:

```bash
curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash
```

نصب‌کننده معماری را بررسی می‌کند، ابزارهای لازم Termux را نصب می‌کند، Debian را با proot-distro آماده می‌کند، وابستگی‌های Linux را نصب می‌کند، OpenCode را در همان محیط نصب و اجراپذیری آن را بررسی می‌کند و در پایان لانچر Terminux را نصب می‌کند. اجرای دوبارهٔ نصب‌کننده برای ترمیم یا به‌روزرسانی امن طراحی شده است؛ داده‌ها و سشن‌های OpenCode حذف نمی‌شوند.

سپس فقط بنویس:

```bash
Terminux
```

لانچر سرویس را روی `127.0.0.1:4096` بالا می‌آورد، سلامت آن را بررسی می‌کند، لینک Pairing می‌سازد و مرورگر را باز می‌کند.

## دستورها

| دستور | عملکرد |
|---|---|
| `Terminux` | شروع سرویس و باز کردن مرورگر |
| `Terminux status` | بررسی سلامت سرویس |
| `Terminux restart` | راه‌اندازی مجدد |
| `Terminux stop` | توقف سرویس |
| `Terminux logs` | نمایش گزارش آخرین اجرا |
| `Terminux update` | دریافت نسخهٔ جدید نصب‌کننده |
| `Terminux uninstall` | حذف لانچر و پوستهٔ Terminux، بدون حذف Debian یا سشن‌ها |

گزارش‌ها در `~/.termunix/` ذخیره می‌شوند:
- `install.log` گزارش نصب
- `opencode.log` گزارش سرویس

## رابط و برند

نام، لوگو، پالت مشکی/ذغالی و نارنجی، فونت فارسی و CSS پوسته در `skin/src/brand.ts` و فایل‌های مرتبط نگهداری می‌شوند.

**محدودیت مهم و شفاف:** پلاگین فعلی `@opencode/plugin/gui` فقط در OpenCode Desktop بارگذاری می‌شود. رابطی که با Pairing در مرورگر باز می‌شود، فعلاً رابط استاندارد وب OpenCode است و از این پلاگین رنگ و لوگو نمی‌گیرد. این مخزن نباید این دو را به‌عنوان یک قابلیت انجام‌شده معرفی کند. شخصی‌سازی واقعی وب نیازمند پچ و ساخت فرانت‌اند وب OpenCode است.

## امنیت و پایداری

- سرویس به‌صورت پیش‌فرض فقط روی `127.0.0.1` گوش می‌دهد.
- هیچ پورت عمومی یا دسترسی شبکه‌ای بیرونی باز نمی‌شود.
- حذف Terminux داده‌ها و سشن‌های OpenCode را پاک نمی‌کند.
- محدودیت‌های مدیریت باتری اندروید ممکن است پردازش پس‌زمینه را متوقف کند؛ برای اجرای پایدارتر، محدودیت باتری Termux را در تنظیمات Android غیرفعال کن.

## توسعه

ساخت پلاگین GUI دسکتاپ:

```bash
cd skin
bun install
bun run brand
```

امضای توسعه‌دهنده: [aishervin](https://github.com/aishervin) · [Telegram](https://t.me/shervini) · [X](https://x.com/shervinonx)

MIT License.
