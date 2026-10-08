QuisquisLingo - Windows útmutató
===============================

A QuisquisLingo nyelvtanulóknak és kurzuskészítőknek szánt nyelvtanulási
alkalmazás. Strukturált leckéket, interaktív gyakorlatokat, hangos feladatokat
és ismétlőeszközöket egyesít, emellett nyelvi kurzusok létrehozására és
szerkesztésére szolgáló eszközöket is biztosít.

Azoknak készült, akik nyelvet szeretnének tanulni, valamint azoknak a
szerzőknek, tanároknak és más felhasználóknak, akik saját kurzusokat szeretnének
készíteni.

A QuisquisLingo működésének gyors képi áttekintéséhez tekintse meg az
alkalmazáscsomagban található QQL infographic.png fájlt.

A QuisquisLingo indításához futtassa a QuisquisLingo.exe fájlt.

A CSOMAG HASZNÁLATA
-------------------

Ez a csomag a QQL alkalmazást tartalmazza. Indítás előtt bontsa ki a teljes ZIP
archívumot, és tartsa együtt az összes mellékelt fájlt és a data mappát. Az
egyes EXE- vagy DLL-fájlokat ne terjessze, helyezze át, törölje vagy nevezze át.

INDÍTÁSI ELLENŐRZÉSEK
---------------------

Indítás előtt a QuisquisLingo ellenőrzi a szükséges csomagfájlokat, a Windows
kompatibilitását és a Media Foundation meglétét. Ezek az ellenőrzések soha nem
töltenek le vagy telepítenek szoftvert, nem kérnek rendszergazdai jogosultságot,
nem módosítják a registry tartalmát vagy a Windows rendszert.

Ha egy probléma mellett tovább lehet lépni, egyetlen üzenet jelenik meg Continue
anyway és Cancel lehetőséggel. A Continue anyway megpróbálja elindítani a QQL-t;
a Cancel bezárja. Ha egy nélkülözhetetlen programfájl hiányzik, az üzenet a Close
lehetőséget kínálja, mert a csomagot újra le kell tölteni és teljesen ki kell
bontani.

A Wine támogatása Experimental. Ha a Media Foundation hiányzik a Wine alól,
az alkalmazás esetleg nem indul el, illetve a hang- és médiafunkciók nem működnek.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

A teljes csomag a következő Microsoft Visual C++ x64 runtime fájlokat tartalmazza:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Ha valamelyik hiányzik, töltse le újra a teljes QuisquisLingo Windows-csomagot,
és bontsa ki teljesen. Runtime installer beszerzéséhez kizárólag hivatalos
Microsoft-forrást használjon, és soha ne töltsön le külön DLL-fájlokat harmadik
fél webhelyéről.

Hivatalos Microsoft-információ:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

A Windows N kiadásoknak szükségük lehet a Microsoft Media Feature Pack csomagra
a hang- és médiafunkciókhoz. A Media Feature Pack általában a Windows Optional
Features alatt érhető el. A Windows N egyes verzióiban előfordulhat, hogy a Media
Feature Pack nem található az Optional Features között. Ebben az esetben töltse
le a Windows verziójához megfelelő Media Feature Pack csomagot a Microsoft
webhelyéről.

A Media Feature Pack telepítése után indítsa újra a Windows rendszert. A
QuisquisLingo nem tölti le és nem telepíti automatikusan, valamint nem módosítja
a rendszerbeállításokat.

SZÖVEGFELOLVASÁS
----------------

A QuisquisLingo a Windows rendszerben telepített beszédhangokat használja. Az
elérhető nyelvek és hangok a számítógépre telepített Windows nyelvi és
hangösszetevőitől függenek. Ha nincs kompatibilis hang, telepítse a megfelelő
összetevőt a Windows beállításaiban.

Az Audio Settings > Test Voice csak a beírt szöveget mondja ki, és a kiválasztott
kurzusban beállított hangnyelvet használja.

NAPLÓK ÉS DIAGNOSZTIKA
----------------------

A fő crash log helye:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Az indítási ellenőrzés log helye:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

A Settings > Debug diagnosztikai lehetőségeket jelenít meg. A logok a helyi
számítógépen maradnak, és feltöltésük nem történik meg automatikusan.

HIBAELHÁRÍTÁS
-------------

1. Bontsa ki teljesen a teljes ZIP archívumot.
2. Futtassa a QuisquisLingo.exe fájlt a kibontott csomagból.
3. Ha hiányzó runtime DLL-ről kap értesítést, töltsön le és bontson ki újra egy
   teljes csomagot, mielőtt hivatalos Microsoft runtime installer használatát
   fontolóra venné.
4. Ha Media Feature Pack szükséges, kövesse a fenti útmutatást, és a telepítés
   után indítsa újra a Windows rendszert.
5. Ha a QQL továbbra sem indul el, őrizze meg a teljes hibaüzenetet és az
   elérhető log fájlokat a támogatáshoz.
