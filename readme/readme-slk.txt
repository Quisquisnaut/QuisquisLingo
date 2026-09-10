QuisquisLingo - Sprievodca pre Windows
=====================================

QuisquisLingo je aplikácia na učenie jazykov pre študentov a tvorcov kurzov.
Spája štruktúrované lekcie, interaktívne cvičenia, zvukové aktivity a nástroje
na opakovanie a zároveň poskytuje nástroje na vytváranie a úpravu jazykových
kurzov.

Je určená ľuďom, ktorí sa chcú učiť jazyk, aj autorom, učiteľom a ďalším
používateľom, ktorí si chcú vytvárať vlastné kurzy.

Rýchly obrazový prehľad fungovania QuisquisLingo nájdete v súbore
QQL infographic.png, ktorý je súčasťou balíka aplikácie.

QuisquisLingo spustíte súborom QuisquisLingo.exe.

POUŽÍVANIE BALÍKA
-----------------

Tento balík obsahuje aplikáciu QQL. Pred spustením rozbaľte celý archív ZIP a
ponechajte všetky dodané súbory aj priečinok data spolu. Jednotlivé súbory EXE
alebo DLL nedistribuujte, nepresúvajte, neodstraňujte ani nepremenúvajte.

KONTROLY PRI SPUSTENÍ
---------------------

Pred spustením QuisquisLingo skontroluje požadované súbory balíka, kompatibilitu
s Windows a Media Foundation. Tieto kontroly nikdy nesťahujú ani neinštalujú
softvér, nežiadajú oprávnenia správcu, nemenia registry ani Windows.

Pri probléme, po ktorom možno pokračovať, sa zobrazí jedna správa s možnosťami
Continue anyway a Cancel. Continue anyway sa pokúsi spustiť QQL; Cancel program
zatvorí. Ak chýba nevyhnutný súbor programu, správa ponúkne Close, pretože balík
treba znova stiahnuť a celý rozbaliť.

Podpora Wine je Experimental. Chýbajúci Media Foundation vo Wine môže zabrániť
spusteniu alebo fungovaniu zvukových a multimediálnych funkcií.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Úplný balík obsahuje tieto súbory runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Ak niektorý chýba, znova stiahnite úplný balík QuisquisLingo pre Windows a celý
ho rozbaľte. Pre runtime installer používajte iba oficiálne zdroje Microsoft a
jednotlivé súbory DLL nikdy nesťahujte z webov tretích strán.

Oficiálne informácie Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Edície Windows N môžu na zvukové a multimediálne funkcie vyžadovať Microsoft
Media Feature Pack. Media Feature Pack je zvyčajne dostupný v ponuke Windows
Optional Features. V niektorých verziách Windows N nemusí byť Media Feature Pack
v Optional Features dostupný. V takom prípade stiahnite z webu Microsoft Media
Feature Pack vhodný pre vašu verziu Windows.

Po inštalácii Media Feature Pack reštartujte Windows. QuisquisLingo ho
automaticky nesťahuje ani neinštaluje a nemení nastavenia systému.

PREVOD TEXTU NA REČ
-------------------

QuisquisLingo používa hlasy nainštalované vo Windows. Dostupné jazyky a hlasy
závisia od jazykových a hlasových súčastí Windows nainštalovaných v počítači.
Ak nie je dostupný kompatibilný hlas, nainštalujte príslušnú súčasť cez
nastavenia Windows.

Audio Settings > Test Voice prečíta iba text, ktorý zadáte, a použije jazyk
hlasu nastavený vo vybranom kurze.

PROTOKOLY A DIAGNOSTIKA
-----------------------

Hlavný crash log je uložený tu:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log kontroly pri spustení je uložený tu:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug zobrazuje diagnostické možnosti. Logy zostávajú v miestnom
počítači a automaticky sa neodosielajú.

RIEŠENIE PROBLÉMOV
------------------

1. Úplne rozbaľte celý archív ZIP.
2. Z rozbaleného balíka spustite QuisquisLingo.exe.
3. Ak sa ohlási chýbajúca runtime DLL, znova stiahnite a rozbaľte celý balík,
   než zvážite oficiálny runtime installer Microsoft.
4. Ak je potrebný Media Feature Pack, postupujte podľa pokynov vyššie a po
   inštalácii reštartujte Windows.
5. Ak sa QQL stále nespustí, uschovajte úplnú chybovú správu a dostupné súbory
   log pre podporu.
