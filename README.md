# Terminux

ایجنت هوش مصنوعی محلی برای کدنویسی و ترمینال، با رابط وب فارسی — ساخته‌شده برای Termux.

## نصب (Termux)

```bash
curl -fsSL https://raw.githubusercontent.com/aishervin/Terminux/main/install.sh | bash
terminux            
```

## اجرای دستی

```bash
npm install
export GEMINI_API_KEY=...   # اختیاری؛ نمونهٔ متغیرها: .env.example
npm start
```

نیازمند Node.js 20 یا بالاتر. کلیدها از بخش «تنظیمات» رابط وب ذخیره می‌شوند (`~/.config/terminux/config.json`).

## ساختار مخزن

```
Terminux/
├─ src/server.ts        بک‌اند Express: API، حلقهٔ ایجنت، ابزارها، ارائه‌دهنده‌های مدل
├─ web/index.html       رابط کاربری تک‌فایلی (فارسی، RTL)
├─ install.sh           نصب‌کنندهٔ Termux (curl | bash)
├─ docs/                مستندات
├─ .github/workflows/   CI (typecheck + بررسی install.sh)
├─ .env.example         نمونهٔ متغیرهای محیطی
├─ package.json · tsconfig.json · LICENSE
```

## امنیت

سرور فقط روی `127.0.0.1` گوش می‌دهد و Hostهای غیرمحلی را رد می‌کند. اجرای فرمان‌های shell به‌صورت پیش‌فرض نیاز به تأیید دستی دارد.

☬ Exclusive SHΞN™ made
