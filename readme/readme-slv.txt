QuisquisLingo - Vodnik za Windows
================================

QuisquisLingo je aplikacija za učenje jezikov, namenjena učencem in ustvarjalcem
tečajev. Združuje strukturirane lekcije, interaktivne vaje, zvočne dejavnosti in
orodja za ponavljanje, obenem pa ponuja orodja za ustvarjanje in urejanje
jezikovnih tečajev.

Namenjena je tako ljudem, ki se želijo naučiti jezika, kot tudi avtorjem,
učiteljem in drugim uporabnikom, ki želijo oblikovati lastne tečaje.

Za hiter slikovni pregled delovanja aplikacije QuisquisLingo si oglejte
QQL infographic.png, ki je priložena paketu aplikacije.

Za zagon aplikacije QuisquisLingo zaženite QuisquisLingo.exe.

UPORABA PAKETA
--------------

Ta paket vsebuje aplikacijo QQL. Pred zagonom v celoti razširite arhiv ZIP ter
ohranite vse priložene datoteke in mapo data skupaj. Posameznih datotek EXE ali
DLL ne razširjajte, premikajte, brišite ali preimenujte.

PREVERJANJE OB ZAGONU
---------------------

Pred zagonom QuisquisLingo preveri zahtevane datoteke paketa, združljivost s
sistemom Windows in Media Foundation. Ti pregledi nikoli ne prenesejo ali
namestijo programske opreme, ne zahtevajo skrbniških pravic, ne spreminjajo
registry niti sistema Windows.

Če je po težavi mogoče nadaljevati, se prikaže eno sporočilo z možnostma
Continue anyway in Cancel. Continue anyway poskusi zagnati QQL; Cancel ga zapre.
Če manjka nujna programska datoteka, sporočilo ponudi Close, saj je treba paket
znova prenesti in ga v celoti razširiti.

Podpora za Wine je Experimental. Če Media Foundation v okolju Wine manjka, se
program morda ne bo zagnal ali pa zvočne in predstavnostne funkcije ne bodo
delovale.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Celoten paket vsebuje naslednje datoteke runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Če katera manjka, znova prenesite celoten paket QuisquisLingo za Windows in ga
popolnoma razširite. Za runtime installer uporabljajte samo uradne Microsoftove
vire in nikoli ne prenašajte posameznih datotek DLL s spletnih mest tretjih oseb.

Uradne informacije podjetja Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Izdaje Windows N lahko za zvočne in predstavnostne funkcije zahtevajo Microsoft
Media Feature Pack. Media Feature Pack je običajno na voljo v Windows Optional
Features. V nekaterih različicah sistema Windows N Media Feature Pack morda ni
na voljo v Optional Features. V tem primeru z Microsoftovega spletnega mesta
prenesite Media Feature Pack, ki ustreza vaši različici sistema Windows.

Po namestitvi paketa Media Feature Pack znova zaženite Windows. QuisquisLingo ga
ne prenese ali namesti samodejno in ne spreminja sistemskih nastavitev.

PRETVORBA BESEDILA V GOVOR
--------------------------

QuisquisLingo uporablja govorne glasove, nameščene v sistemu Windows. Razpoložljivi
jeziki in glasovi so odvisni od jezikovnih in glasovnih komponent sistema Windows,
nameščenih v računalniku. Če združljiv glas ni na voljo, namestite ustrezno
komponento prek nastavitev sistema Windows.

Audio Settings > Test Voice izgovori samo besedilo, ki ga vnesete, in uporabi
jezik glasu, nastavljen za izbrani tečaj.

DNEVNIKI IN DIAGNOSTIKA
-----------------------

Glavni crash log je shranjen tukaj:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log preverjanja ob zagonu je shranjen tukaj:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug prikaže diagnostične možnosti. Logi ostanejo v lokalnem
računalniku in se ne naložijo samodejno.

ODPRAVLJANJE TEŽAV
------------------

1. V celoti razširite celoten arhiv ZIP.
2. Zaženite QuisquisLingo.exe iz razširjenega paketa.
3. Če je sporočeno, da manjka runtime DLL, znova prenesite in razširite celoten
   paket, preden razmislite o uradnem Microsoftovem runtime installer.
4. Če potrebujete Media Feature Pack, sledite zgornjim navodilom in po namestitvi
   znova zaženite Windows.
5. Če se QQL še vedno ne zažene, shranite celotno sporočilo o napaki in
   razpoložljive datoteke log za podporo.
