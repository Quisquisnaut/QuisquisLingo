QuisquisLingo - Udhëzues për Windows
===================================

QuisquisLingo është një aplikacion për mësimin e gjuhëve, i krijuar për nxënësit
dhe krijuesit e kurseve. Ai ndërthur mësime të strukturuara, ushtrime ndërvepruese,
veprimtari me audio dhe mjete përsëritjeje, si dhe ofron mjete për krijimin dhe
redaktimin e kurseve të gjuhëve.

Është krijuar si për njerëzit që duan të mësojnë një gjuhë, ashtu edhe për
autorët, mësuesit ose përdoruesit e tjerë që duan të ndërtojnë kurset e tyre.

Për një përmbledhje të shpejtë pamore të mënyrës se si funksionon QuisquisLingo,
shihni QQL infographic.png, të përfshirë në paketën e aplikacionit.

Për të nisur QuisquisLingo, ekzekutoni QuisquisLingo.exe.

PËRDORIMI I PAKETËS
-------------------

Kjo paketë përmban aplikacionin QQL. Shpaketoni të gjithë arkivin ZIP para nisjes
dhe mbajini së bashku të gjithë skedarët e dhënë dhe dosjen data. Mos shpërndani,
zhvendosni, fshini ose riemërtoni veçmas skedarë EXE ose DLL.

KONTROLLET GJATË NISJES
-----------------------

Para nisjes, QuisquisLingo kontrollon skedarët e nevojshëm të paketës,
përputhshmërinë me Windows dhe Media Foundation. Këto kontrolle nuk shkarkojnë
ose instalojnë kurrë programe, nuk kërkojnë të drejta administratori, nuk
ndryshojnë registry dhe nuk modifikojnë Windows.

Nëse një problem lejon vazhdimin, shfaqet një mesazh i vetëm me Continue anyway
dhe Cancel. Continue anyway përpiqet të nisë QQL; Cancel e mbyll. Nëse mungon një
skedar thelbësor i programit, mesazhi ofron Close, sepse paketa duhet shkarkuar
dhe shpaketuar përsëri plotësisht.

Mbështetja për Wine është Experimental. Mungesa e Media Foundation në Wine mund
të pengojë nisjen ose funksionimin e veçorive audio dhe mediatike.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Paketa e plotë përfshin këta skedarë runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Nëse mungon ndonjëri, shkarkoni përsëri paketën e plotë QuisquisLingo për Windows
dhe shpaketojeni të gjithën. Për runtime installer përdorni vetëm burime zyrtare
të Microsoft dhe mos shkarkoni kurrë skedarë të veçantë DLL nga faqe të palëve
të treta.

Informacion zyrtar nga Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Edicionet Windows N mund të kërkojnë Microsoft Media Feature Pack për funksionet
audio dhe mediatike. Media Feature Pack zakonisht gjendet te Windows Optional
Features. Në disa versione të Windows N, Media Feature Pack mund të mos gjendet
te Optional Features. Në këtë rast, shkarkoni nga faqja e Microsoft Media Feature
Pack të përshtatshëm për versionin tuaj të Windows.

Rinisni Windows pasi të instaloni Media Feature Pack. QuisquisLingo nuk e
shkarkon ose instalon automatikisht dhe nuk ndryshon cilësimet e sistemit.

KTHIMI I TEKSTIT NË TË FOLUR
----------------------------

QuisquisLingo përdor zërat e të folurit të instaluar në Windows. Gjuhët dhe
zërat e disponueshëm varen nga përbërësit e gjuhës dhe zërit të Windows të
instaluar në kompjuter. Nëse nuk ka një zë të përputhshëm, instaloni përbërësin
e duhur përmes cilësimeve të Windows.

Audio Settings > Test Voice shqipton vetëm tekstin që futni dhe përdor gjuhën e
zërit të caktuar nga kursi i zgjedhur.

REGJISTRAT DHE DIAGNOSTIKIMI
---------------------------

Crash log kryesor ruhet këtu:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log i kontrollit gjatë nisjes ruhet këtu:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug shfaq mundësitë diagnostikuese. Logët mbeten në kompjuterin
lokal dhe nuk ngarkohen automatikisht.

ZGJIDHJA E PROBLEMEVE
---------------------

1. Shpaketoni plotësisht të gjithë arkivin ZIP.
2. Ekzekutoni QuisquisLingo.exe nga paketa e shpaketuar.
3. Nëse raportohet se mungon një runtime DLL, shkarkoni dhe shpaketoni përsëri
   paketën e plotë para se të merrni parasysh një Microsoft runtime installer
   zyrtar.
4. Nëse kërkohet Media Feature Pack, ndiqni udhëzimet e mësipërme dhe rinisni
   Windows pas instalimit.
5. Nëse QQL ende nuk niset, ruani mesazhin e plotë të gabimit dhe skedarët log
   të disponueshëm për mbështetje.
