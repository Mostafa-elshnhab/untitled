# نظام الميزان المتعدد المنصات (Multi-Platform Scale System)

تطبيق Flutter مصمم لقراءة البيانات من الموازين الإلكترونية (Scales) عبر منافذ السيريال (RS232/COM) ويدعم العمل على المتصفح (Web) وسطح المكتب (Windows).

## المميزات
- **دعم الويب**: يستخدم `Web Serial API` لقراءة البيانات مباشرة من المتصفح (Chrome/Edge).
- **دعم سطح المكتب**: يستخدم مكتبة `flutter_libserialport` للتعامل مع منافذ COM في بيئة ويندوز.
- **واجهة مستخدم بسيطة**: تعرض الوزن الحالي وحالة الاتصال بشكل واضح.

## المتطلبات (Requirements)

### للتشغيل على الويب (Web)
- متصفح يدعم **Web Serial API** (مثل Google Chrome أو Microsoft Edge).
- يجب تشغيل التطبيق عبر **HTTPS** أو **localhost** للسماح بالوصول للأجهزة.

### للتشغيل/البناء لسطح المكتب (Windows)
لبناء نسخة ويندوز، يجب تثبيت **Visual Studio 2022** مع اختيار عبء العمل (Workload):
- **Desktop development with C++**
- تأكد من تضمين "MSVC v143" و "Windows 10/11 SDK".

## بدء التشغيل

1. قم بتثبيت الاعتمادات:
   ```bash
   flutter pub get
   ```

2. للتشغيل على الويب:
   ```bash
   flutter run -d chrome
   ```

3. لبناء نسخة ويندوز:
   استخدم ملف `build_windows.bat` أو قم بتشغيل:
   ```bash
   flutter build windows
   ```

## ملاحظات تقنية
- يتم استخدام `js_stub.dart` كبديل للمكتبات الخاصة بالويب عند التشغيل على سطح المكتب لتجنب أخطاء التصريف (Compilation errors).
- إعدادات السيريال الافتراضية: `BaudRate: 9600`, `DataBits: 8`, `StopBits: 1`.
