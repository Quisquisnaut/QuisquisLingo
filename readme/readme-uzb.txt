QuisquisLingo - Windows qo‘llanmasi
==================================

QuisquisLingo til o‘rganuvchilar va kurs yaratuvchilar uchun til o‘rganish
ilovasidir. U tartibli darslar, interaktiv mashqlar, audio mashg‘ulotlar va
takrorlash vositalarini birlashtiradi, shuningdek til kurslarini yaratish va
tahrirlash vositalarini taqdim etadi.

U til o‘rganishni istaganlar uchun ham, o‘z kurslarini yaratmoqchi bo‘lgan
mualliflar, o‘qituvchilar va boshqa foydalanuvchilar uchun ham mo‘ljallangan.

QuisquisLingo qanday ishlashini qisqa va ko‘rgazmali tarzda bilish uchun ilova
paketiga kiritilgan QQL infographic.png faylini ko‘ring.

QuisquisLingo-ni boshlash uchun QuisquisLingo.exe faylini ishga tushiring.

PAKETDAN FOYDALANISH
--------------------

Bu paket QQL ilovasini o‘z ichiga oladi. Boshlashdan oldin ZIP arxivini to‘liq
oching va taqdim etilgan barcha fayllar bilan data jildini birga saqlang. Alohida
EXE yoki DLL fayllarini tarqatmang, ko‘chirmang, o‘chirmang yoki qayta nomlamang.

ISHGA TUSHIRISHDAGI TEKSHIRUVLAR
-------------------------------

Ishga tushirishdan oldin QuisquisLingo kerakli paket fayllari, Windows bilan
moslik va Media Foundation mavjudligini tekshiradi. Bu tekshiruvlar hech qachon
dasturiy ta’minotni yuklab olmaydi yoki o‘rnatmaydi, administrator huquqlarini
so‘ramaydi, registry yoki Windows tizimini o‘zgartirmaydi.

Muammoga qaramay davom etish mumkin bo‘lsa, Continue anyway va Cancel tugmalari
bo‘lgan bitta xabar ko‘rsatiladi. Continue anyway QQL-ni ishga tushirishga urinadi;
Cancel uni yopadi. Muhim dastur fayli yo‘q bo‘lsa, xabar Close-ni taklif qiladi,
chunki paketni qayta yuklab olib, to‘liq ochish kerak.

Wine qo‘llovi Experimental holatida. Wine muhitida Media Foundation bo‘lmasa,
dastur ishga tushmasligi yoki audio va media imkoniyatlari ishlamasligi mumkin.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

To‘liq paket quyidagi Microsoft Visual C++ x64 runtime fayllarini o‘z ichiga oladi:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Ulardan biri yo‘q bo‘lsa, to‘liq QuisquisLingo Windows paketini yana yuklab olib,
butunlay oching. Runtime installer uchun faqat Microsoft-ning rasmiy manbalaridan
foydalaning va alohida DLL fayllarini hech qachon uchinchi tomon saytlaridan
yuklab olmang.

Microsoft-ning rasmiy ma’lumoti:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N nashrlarida audio va media funksiyalari uchun Microsoft Media Feature
Pack kerak bo‘lishi mumkin. Media Feature Pack odatda Windows Optional Features
bo‘limida mavjud. Windows N-ning ayrim versiyalarida Media Feature Pack Optional
Features bo‘limida bo‘lmasligi mumkin. Bunday holatda Windows versiyangizga mos
Media Feature Pack-ni Microsoft veb-saytidan yuklab oling.

Media Feature Pack-ni o‘rnatgandan so‘ng Windows-ni qayta ishga tushiring.
QuisquisLingo uni avtomatik yuklab olmaydi yoki o‘rnatmaydi va tizim sozlamalarini
o‘zgartirmaydi.

MATNNI NUTQQA AYLANTIRISH
-------------------------

QuisquisLingo Windows-da o‘rnatilgan nutq ovozlaridan foydalanadi. Mavjud tillar
va ovozlar kompyuterda o‘rnatilgan Windows til va ovoz komponentlariga bog‘liq.
Mos ovoz bo‘lmasa, Windows sozlamalari orqali tegishli komponentni o‘rnating.

Audio Settings > Test Voice faqat siz kiritgan matnni o‘qiydi va tanlangan
kursda sozlangan ovoz tilidan foydalanadi.

JURNALLAR VA DIAGNOSTIKA
------------------------

Asosiy crash log shu yerda saqlanadi:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Ishga tushirish tekshiruvining log fayli shu yerda saqlanadi:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug diagnostika imkoniyatlarini ko‘rsatadi. Log fayllari mahalliy
kompyuterda qoladi va avtomatik yuklanmaydi.

MUAMMOLARNI HAL QILISH
----------------------

1. Butun ZIP arxivini to‘liq oching.
2. Ochilgan paketdan QuisquisLingo.exe faylini ishga tushiring.
3. Runtime DLL yo‘qligi xabar qilinsa, rasmiy Microsoft runtime installer-dan
   foydalanishni ko‘rib chiqishdan oldin to‘liq paketni qayta yuklab olib oching.
4. Media Feature Pack kerak bo‘lsa, yuqoridagi ko‘rsatmalarga amal qiling va
   o‘rnatgandan so‘ng Windows-ni qayta ishga tushiring.
5. QQL hali ham ishga tushmasa, yordam olish uchun to‘liq xato xabari va mavjud
   log fayllarini saqlang.
