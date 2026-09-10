QuisquisLingo - Windows رہنما
============================

QuisquisLingo زبان سیکھنے والوں اور کورس بنانے والوں کے لیے زبان سیکھنے کی ایک
ایپلی کیشن ہے۔ اس میں منظم اسباق، انٹرایکٹو مشقیں، آڈیو سرگرمیاں اور دہرائی کے
وسائل شامل ہیں، اور زبان کے کورس بنانے اور ان میں ترمیم کرنے کے وسائل بھی موجود
ہیں۔

یہ ان لوگوں کے لیے تیار کی گئی ہے جو کوئی زبان سیکھنا چاہتے ہیں، اور ان مصنفین،
اساتذہ یا دوسرے صارفین کے لیے بھی جو اپنے کورس بنانا چاہتے ہیں۔

QuisquisLingo کے کام کرنے کے طریقے کا مختصر بصری تعارف دیکھنے کے لیے ایپلی کیشن
پیکیج میں شامل QQL infographic.png دیکھیں۔

QuisquisLingo شروع کرنے کے لیے QuisquisLingo.exe چلائیں۔

پیکیج کا استعمال
----------------

اس پیکیج میں QQL ایپلی کیشن شامل ہے۔ اسے شروع کرنے سے پہلے مکمل ZIP archive
نکالیں اور فراہم کردہ تمام فائلوں اور data فولڈر کو ایک ساتھ رکھیں۔ الگ الگ EXE
یا DLL فائلیں تقسیم، منتقل، حذف یا rename نہ کریں۔

ابتدائی جانچ
------------

شروع ہونے سے پہلے QuisquisLingo مطلوبہ پیکیج فائلوں، Windows کی مطابقت اور
Media Foundation کو جانچتا ہے۔ یہ جانچ کبھی software download یا install نہیں
کرتی، administrator کی اجازت نہیں مانگتی، registry نہیں بدلتی اور Windows میں
کوئی تبدیلی نہیں کرتی۔

جس مسئلے کے باوجود آگے بڑھا جا سکتا ہو، اس کے لیے Continue anyway اور Cancel
والا ایک پیغام دکھایا جاتا ہے۔ Continue anyway، QQL شروع کرنے کی کوشش کرتا ہے؛
Cancel اسے بند کر دیتا ہے۔ اگر پروگرام کی کوئی لازمی فائل موجود نہ ہو تو پیغام
میں Close آتا ہے، کیونکہ پیکیج کو دوبارہ download کر کے مکمل طور پر نکالنا ضروری
ہے۔

Wine کی معاونت Experimental ہے۔ Wine میں Media Foundation نہ ہونے سے پروگرام
شروع نہیں ہو سکتا یا audio اور media کی سہولتیں کام نہیں کر سکتیں۔

MICROSOFT VISUAL C++ RUNTIME
----------------------------

مکمل پیکیج میں Microsoft Visual C++ x64 کی یہ runtime فائلیں شامل ہیں:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

اگر ان میں سے کوئی فائل موجود نہ ہو تو مکمل QuisquisLingo Windows پیکیج دوبارہ
download کریں اور پورا نکالیں۔ Runtime installer صرف Microsoft کے سرکاری ذرائع
سے حاصل کریں اور انفرادی DLL فائل کبھی تیسرے فریق کی website سے download نہ کریں۔

Microsoft کی سرکاری معلومات:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N editions میں audio اور media کی سہولتوں کے لیے Microsoft Media Feature
Pack درکار ہو سکتا ہے۔ Media Feature Pack عموماً Windows Optional Features میں
دستیاب ہوتا ہے۔ Windows N کے کچھ versions میں Media Feature Pack، Optional
Features میں دستیاب نہیں بھی ہو سکتا۔ ایسی صورت میں اپنی Windows version کے لیے
موزوں Media Feature Pack، Microsoft کی website سے download کریں۔

Media Feature Pack install کرنے کے بعد Windows کو restart کریں۔ QuisquisLingo
اسے خودکار طور پر download یا install نہیں کرتا اور system settings نہیں بدلتا۔

TEXT-TO-SPEECH
--------------

QuisquisLingo، Windows میں install آوازیں استعمال کرتا ہے۔ دستیاب زبانیں اور
آوازیں computer پر install کیے گئے Windows language اور voice components پر
منحصر ہیں۔ اگر کوئی موزوں آواز دستیاب نہ ہو تو Windows settings سے مناسب component
install کریں۔

Audio Settings > Test Voice صرف آپ کا درج کردہ متن بولتا ہے اور منتخب course
میں مقرر کردہ voice language استعمال کرتا ہے۔

LOGS اور تشخیص
--------------

بنیادی crash log یہاں محفوظ ہوتا ہے:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

ابتدائی جانچ کا log یہاں محفوظ ہوتا ہے:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug میں تشخیصی options موجود ہیں۔ Logs مقامی computer پر رہتے ہیں
اور خودکار طور پر upload نہیں ہوتے۔

مسئلہ حل کرنا
-------------

1. مکمل ZIP archive پوری طرح نکالیں۔
2. نکالے گئے پیکیج سے QuisquisLingo.exe چلائیں۔
3. اگر runtime DLL غائب ہونے کی اطلاع ملے تو Microsoft کے سرکاری runtime
   installer پر غور کرنے سے پہلے مکمل پیکیج دوبارہ download کر کے نکالیں۔
4. اگر Media Feature Pack درکار ہو تو اوپر دی گئی رہنمائی پر عمل کریں اور install
   کرنے کے بعد Windows کو restart کریں۔
5. اگر QQL پھر بھی شروع نہ ہو تو معاونت کے لیے مکمل error message اور دستیاب log
   فائلیں محفوظ رکھیں۔
