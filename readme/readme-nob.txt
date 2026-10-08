QuisquisLingo - Veiledning for Windows
=====================================

QuisquisLingo er et program for språklæring, beregnet på elever og kursskapere.
Det kombinerer strukturerte leksjoner, interaktive øvelser, lydaktiviteter og
verktøy for repetisjon, samtidig som det tilbyr verktøy for å lage og redigere
språkkurs.

Det er utformet både for personer som vil lære et språk, og for forfattere,
lærere eller andre brukere som vil bygge sine egne kurs.

Du finner en rask visuell oversikt over hvordan QuisquisLingo fungerer, i
QQL infographic.png, som følger med programpakken.

Start QuisquisLingo ved å kjøre QuisquisLingo.exe.

BRUKE PAKKEN
------------

Denne pakken inneholder QQL-programmet. Pakk ut hele ZIP-arkivet før du starter
det, og behold alle medfølgende filer og mappen data samlet. Ikke distribuer,
flytt, slett eller gi nytt navn til enkelte EXE- eller DLL-filer.

KONTROLLER VED OPPSTART
----------------------

Før oppstart kontrollerer QuisquisLingo de nødvendige pakkefilene,
Windows-kompatibilitet og Media Foundation. Kontrollene laster aldri ned eller
installerer programvare, ber ikke om administratorrettigheter, endrer ikke
registry eller Windows.

Et problem som det går an å fortsette etter, gir én melding med Continue anyway
og Cancel. Continue anyway forsøker å starte QQL; Cancel lukker det. Hvis en
nødvendig programfil mangler, viser meldingen Close fordi pakken må lastes ned
og pakkes helt ut på nytt.

Støtte for Wine er Experimental. Hvis Media Foundation mangler under Wine, kan
det hindre oppstart eller gjøre at lyd- og mediefunksjoner ikke virker.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Den komplette pakken inneholder følgende Microsoft Visual C++ x64 runtime-filer:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Hvis en av dem mangler, laster du ned den komplette QuisquisLingo-pakken for
Windows på nytt og pakker ut alt. Bruk bare offisielle Microsoft-kilder for
runtime installer, og last aldri ned enkelte DLL-filer fra tredjepartsnettsteder.

Offisiell informasjon fra Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N-utgaver kan kreve Microsoft Media Feature Pack for lyd- og
mediefunksjoner. Media Feature Pack er vanligvis tilgjengelig under Windows
Optional Features. I enkelte versjoner av Windows N er Media Feature Pack kanskje
ikke tilgjengelig under Optional Features. I så fall laster du ned den Media
Feature Pack som passer til din versjon av Windows, fra Microsofts nettsted.

Start Windows på nytt etter at Media Feature Pack er installert. QuisquisLingo
laster den ikke ned eller installerer den automatisk og endrer ikke
systeminnstillingene.

TEKST TIL TALE
--------------

QuisquisLingo bruker talestemmene som er installert i Windows. Tilgjengelige
språk og stemmer avhenger av språk- og stemmekomponentene for Windows som er
installert på datamaskinen. Hvis ingen kompatibel stemme er tilgjengelig,
installerer du riktig komponent gjennom innstillingene i Windows.

Audio Settings > Test Voice leser bare opp teksten du skriver inn, og bruker
stemmespråket som er konfigurert for det valgte kurset.

LOGGER OG DIAGNOSTIKK
---------------------

Den primære crash log lagres her:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Loggen for oppstartskontrollen lagres her:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug viser diagnostiske alternativer. Loggene blir værende på den
lokale datamaskinen og lastes ikke opp automatisk.

FEILSØKING
----------

1. Pakk ut hele ZIP-arkivet fullstendig.
2. Kjør QuisquisLingo.exe fra den utpakkede pakken.
3. Hvis det meldes om en manglende runtime DLL, laster du ned og pakker ut hele
   pakken på nytt før du vurderer en offisiell Microsoft runtime installer.
4. Hvis Media Feature Pack er nødvendig, følger du veiledningen ovenfor og
   starter Windows på nytt etter installasjonen.
5. Hvis QQL fortsatt ikke starter, beholder du hele feilmeldingen og de
   tilgjengelige loggfilene for brukerstøtte.
