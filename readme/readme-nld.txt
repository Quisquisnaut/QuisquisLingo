QuisquisLingo - Windows-handleiding
==================================

QuisquisLingo is een toepassing voor het leren van talen, bedoeld voor cursisten
en cursusmakers. De toepassing combineert gestructureerde lessen, interactieve
oefeningen, audioactiviteiten en hulpmiddelen voor herhaling, en biedt daarnaast
hulpmiddelen om taalcursussen te maken en te bewerken.

QuisquisLingo is ontworpen voor mensen die een taal willen leren én voor auteurs,
docenten en andere gebruikers die hun eigen cursussen willen samenstellen.

Bekijk QQL infographic.png, meegeleverd in het toepassingspakket, voor een snel
visueel overzicht van de werking van QuisquisLingo.

Start QuisquisLingo door QuisquisLingo.exe uit te voeren.

HET PAKKET GEBRUIKEN
--------------------

Dit pakket bevat de QQL-toepassing. Pak het volledige ZIP-archief uit voordat u
de toepassing start en houd alle meegeleverde bestanden en de map data bij
elkaar. Verspreid, verplaats, verwijder of hernoem geen afzonderlijke EXE- of
DLL-bestanden.

CONTROLES BIJ HET STARTEN
-------------------------

Vóór het starten controleert QuisquisLingo de vereiste pakketbestanden,
compatibiliteit met Windows en Media Foundation. Deze controles downloaden of
installeren nooit software, vragen niet om beheerdersrechten, wijzigen het
registry niet en brengen geen veranderingen aan Windows aan.

Bij een probleem waarbij doorgaan mogelijk is, verschijnt één melding met
Continue anyway en Cancel. Continue anyway probeert QQL te starten; Cancel sluit
het af. Als een essentieel programmabestand ontbreekt, biedt de melding Close,
omdat het pakket opnieuw moet worden gedownload en volledig uitgepakt.

Ondersteuning voor Wine is Experimental. Als Media Foundation onder Wine
ontbreekt, kan de toepassing mogelijk niet starten of werken audio- en
mediafuncties mogelijk niet.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Het volledige pakket bevat de volgende Microsoft Visual C++ x64-runtimebestanden:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Als een bestand ontbreekt, download dan het volledige QuisquisLingo Windows-pakket
opnieuw en pak het helemaal uit. Gebruik voor een runtime installer uitsluitend
officiële Microsoft-bronnen en download nooit afzonderlijke DLL-bestanden van
websites van derden.

Officiële informatie van Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Voor Windows N-edities kan Microsoft Media Feature Pack nodig zijn voor audio-
en mediafuncties. Media Feature Pack is normaal beschikbaar via Windows Optional
Features. In sommige versies van Windows N is Media Feature Pack mogelijk niet
beschikbaar via Optional Features. Download in dat geval het Media Feature Pack
dat geschikt is voor uw Windows-versie van de Microsoft-website.

Start Windows opnieuw op nadat Media Feature Pack is geïnstalleerd.
QuisquisLingo downloadt of installeert het niet automatisch en wijzigt geen
systeeminstellingen.

TEXT-TO-SPEECH
--------------

QuisquisLingo gebruikt de spraakstemmen die in Windows zijn geïnstalleerd. De
beschikbare talen en stemmen zijn afhankelijk van de taal- en spraakonderdelen
van Windows die op de computer zijn geïnstalleerd. Installeer het juiste onderdeel
via de Windows-instellingen als er geen compatibele stem beschikbaar is.

Audio Settings > Test Voice spreekt uitsluitend de tekst uit die u invoert en
gebruikt de stemtaal die voor de geselecteerde cursus is ingesteld.

LOGBOEKEN EN DIAGNOSTIEK
------------------------

Het belangrijkste crash log wordt hier opgeslagen:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Het logboek van de startcontrole wordt hier opgeslagen:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug toont diagnostische opties. Logboeken blijven op de lokale
computer en worden niet automatisch geüpload.

PROBLEMEN OPLOSSEN
------------------

1. Pak het volledige ZIP-archief helemaal uit.
2. Voer QuisquisLingo.exe uit vanuit het uitgepakte pakket.
3. Als een ontbrekende runtime DLL wordt gemeld, download en pak dan eerst het
   volledige pakket opnieuw uit voordat u een officiële runtime installer van
   Microsoft overweegt.
4. Als Media Feature Pack nodig is, volg dan de bovenstaande aanwijzingen en
   start Windows na de installatie opnieuw op.
5. Als QQL nog steeds niet start, bewaar dan de volledige foutmelding en de
   beschikbare logbestanden voor ondersteuning.
