QuisquisLingo - Průvodce pro Windows
===================================

QuisquisLingo je aplikace pro výuku jazyků určená studentům a tvůrcům kurzů.
Spojuje strukturované lekce, interaktivní cvičení, zvukové aktivity a nástroje
pro opakování a zároveň poskytuje nástroje pro vytváření a úpravu jazykových
kurzů.

Je určena jak lidem, kteří se chtějí učit jazyk, tak autorům, učitelům a dalším
uživatelům, kteří si chtějí vytvořit vlastní kurzy.

Rychlý obrazový přehled fungování QuisquisLingo najdete v souboru
QQL infographic.png, který je součástí balíčku aplikace.

QuisquisLingo spustíte souborem QuisquisLingo.exe.

POUŽÍVÁNÍ BALÍČKU
-----------------

Tento balíček obsahuje aplikaci QQL. Před spuštěním rozbalte celý archiv ZIP a
ponechte všechny dodané soubory i složku data pohromadě. Jednotlivé soubory EXE
nebo DLL nedistribuujte, nepřesouvejte, nemažte ani nepřejmenovávejte.

KONTROLY PŘI SPUŠTĚNÍ
---------------------

Před spuštěním QuisquisLingo zkontroluje požadované soubory balíčku,
kompatibilitu s Windows a Media Foundation. Tyto kontroly nikdy nestahují ani
neinstalují software, nevyžadují oprávnění správce, nemění registry ani Windows.

Při problému, po kterém lze pokračovat, se zobrazí jedna zpráva s možnostmi
Continue anyway a Cancel. Continue anyway se pokusí spustit QQL; Cancel program
zavře. Pokud chybí nezbytný soubor programu, zpráva nabídne Close, protože je
třeba balíček znovu stáhnout a celý rozbalit.

Podpora Wine je Experimental. Chybějící Media Foundation ve Wine může zabránit
spuštění nebo fungování zvukových a multimediálních funkcí.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Úplný balíček obsahuje tyto soubory runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Pokud některý chybí, stáhněte znovu celý balíček QuisquisLingo pro Windows a
úplně jej rozbalte. Pro runtime installer používejte pouze oficiální zdroje
Microsoft a jednotlivé soubory DLL nikdy nestahujte z webů třetích stran.

Oficiální informace Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Edice Windows N mohou pro zvukové a multimediální funkce vyžadovat Microsoft
Media Feature Pack. Media Feature Pack je obvykle k dispozici v nabídce Windows
Optional Features. V některých verzích Windows N nemusí být Media Feature Pack
v Optional Features dostupný. V takovém případě stáhněte z webu Microsoft Media
Feature Pack odpovídající vaší verzi Windows.

Po instalaci Media Feature Pack restartujte Windows. QuisquisLingo jej
automaticky nestahuje ani neinstaluje a nemění nastavení systému.

PŘEVOD TEXTU NA ŘEČ
-------------------

QuisquisLingo používá hlasy nainstalované ve Windows. Dostupné jazyky a hlasy
závisí na jazykových a hlasových součástech Windows nainstalovaných v počítači.
Pokud není k dispozici kompatibilní hlas, nainstalujte příslušnou součást v
nastavení Windows.

Audio Settings > Test Voice přečte pouze text, který zadáte, a použije jazyk
hlasu nastavený ve vybraném kurzu.

PROTOKOLY A DIAGNOSTIKA
-----------------------

Hlavní crash log je uložen zde:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log kontroly při spuštění je uložen zde:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug zobrazuje diagnostické možnosti. Logy zůstávají v místním
počítači a automaticky se neodesílají.

ŘEŠENÍ POTÍŽÍ
-------------

1. Úplně rozbalte celý archiv ZIP.
2. Z rozbaleného balíčku spusťte QuisquisLingo.exe.
3. Pokud je ohlášena chybějící runtime DLL, znovu stáhněte a rozbalte celý
   balíček, než zvážíte oficiální runtime installer Microsoft.
4. Pokud je potřeba Media Feature Pack, postupujte podle pokynů výše a po
   instalaci restartujte Windows.
5. Pokud se QQL stále nespustí, uschovejte úplnou chybovou zprávu a dostupné
   soubory log pro účely podpory.
