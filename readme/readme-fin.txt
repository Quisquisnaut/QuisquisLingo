QuisquisLingo - Windows-opas
===========================

QuisquisLingo on kieltenopiskelusovellus oppijoille ja kurssien tekijöille. Se
yhdistää jäsennellyt oppitunnit, vuorovaikutteiset harjoitukset, äänitoiminnot
ja kertaustyökalut sekä tarjoaa työkaluja kielikurssien luomiseen ja
muokkaamiseen.

Se on suunniteltu sekä kieltä opiskelemaan haluaville että omia kurssejaan
rakentaville kirjoittajille, opettajille ja muille käyttäjille.

QuisquisLingon toiminnasta saa nopean kuvallisen yleiskuvan sovelluspakettiin
sisältyvästä tiedostosta QQL infographic.png.

Käynnistä QuisquisLingo suorittamalla QuisquisLingo.exe.

PAKETIN KÄYTTÄMINEN
-------------------

Tämä paketti sisältää QQL-sovelluksen. Pura koko ZIP-arkisto ennen käynnistämistä
ja pidä kaikki toimitetut tiedostot sekä data-kansio yhdessä. Älä jaa, siirrä,
poista tai nimeä uudelleen yksittäisiä EXE- tai DLL-tiedostoja.

KÄYNNISTYSTARKISTUKSET
---------------------

Ennen käynnistämistä QuisquisLingo tarkistaa paketin vaaditut tiedostot,
Windows-yhteensopivuuden ja Media Foundationin. Tarkistukset eivät koskaan lataa
tai asenna ohjelmistoja, pyydä järjestelmänvalvojan oikeuksia, muuta registryä
eivätkä Windowsia.

Ongelma, jonka jälkeen voidaan jatkaa, tuottaa yhden viestin, jossa ovat Continue
anyway ja Cancel. Continue anyway yrittää käynnistää QQL:n, ja Cancel sulkee sen.
Jos olennainen ohjelmatiedosto puuttuu, viestissä on Close, koska paketti täytyy
ladata uudelleen ja purkaa kokonaan.

Wine-tuki on Experimental. Media Foundationin puuttuminen Winestä voi estää
käynnistymisen tai ääni- ja mediatoimintojen toiminnan.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Täydellinen paketti sisältää seuraavat Microsoft Visual C++ x64 runtime -tiedostot:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Jos jokin puuttuu, lataa täydellinen QuisquisLingo Windows -paketti uudelleen ja
pura se kokonaan. Käytä runtime installer -ohjelmiin vain Microsoftin virallisia
lähteitä äläkä koskaan lataa yksittäisiä DLL-tiedostoja kolmansien osapuolten
sivustoilta.

Microsoftin viralliset tiedot:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N -versiot saattavat edellyttää Microsoft Media Feature Packia ääni- ja
mediatoimintoihin. Media Feature Pack on tavallisesti saatavilla Windows Optional
Features -kohdassa. Joissakin Windows N -versioissa Media Feature Pack ei ehkä
ole saatavilla Optional Features -kohdassa. Lataa siinä tapauksessa Windows-
versiollesi sopiva Media Feature Pack Microsoftin verkkosivustolta.

Käynnistä Windows uudelleen Media Feature Packin asentamisen jälkeen.
QuisquisLingo ei lataa tai asenna sitä automaattisesti eikä muuta järjestelmän
asetuksia.

TEKSTISTÄ PUHEEKSI
------------------

QuisquisLingo käyttää Windowsiin asennettuja puheääniä. Saatavilla olevat kielet
ja äänet riippuvat tietokoneeseen asennetuista Windowsin kieli- ja
äänikomponenteista. Jos yhteensopivaa ääntä ei ole, asenna sopiva komponentti
Windowsin asetuksista.

Audio Settings > Test Voice puhuu vain syöttämäsi tekstin ja käyttää valitulle
kurssille määritettyä puhekieltä.

LOKIT JA DIAGNOSTIIKKA
----------------------

Pääasiallinen crash log tallennetaan tänne:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Käynnistystarkistuksen log tallennetaan tänne:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug näyttää diagnostiikkavaihtoehdot. Lokit pysyvät paikallisessa
tietokoneessa, eikä niitä lähetetä automaattisesti.

VIANMÄÄRITYS
------------

1. Pura koko ZIP-arkisto kokonaan.
2. Suorita QuisquisLingo.exe puretusta paketista.
3. Jos runtime DLL ilmoitetaan puuttuvaksi, lataa ja pura koko paketti uudelleen
   ennen virallisen Microsoft runtime installer -ohjelman harkitsemista.
4. Jos Media Feature Pack tarvitaan, noudata yllä olevia ohjeita ja käynnistä
   Windows uudelleen asennuksen jälkeen.
5. Jos QQL ei vieläkään käynnisty, säilytä koko virheilmoitus ja käytettävissä
   olevat lokitiedostot tukea varten.
