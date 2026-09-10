QuisquisLingo - Vodič za Windows
================================

QuisquisLingo je aplikacija za učenje jezika namijenjena učenicima i kreatorima
kurseva. Objedinjuje strukturirane lekcije, interaktivne vježbe, zvučne
aktivnosti i alate za ponavljanje, a pruža i alate za pravljenje i uređivanje
jezičkih kurseva.

Namijenjena je ljudima koji žele učiti jezik, kao i autorima, nastavnicima i
drugim korisnicima koji žele napraviti vlastite kurseve.

Za brz vizuelni pregled načina rada aplikacije QuisquisLingo pogledajte
QQL infographic.png, koja je uključena u paket aplikacije.

Za pokretanje aplikacije QuisquisLingo pokrenite QuisquisLingo.exe.

KORIŠTENJE PAKETA
-----------------

Ovaj paket sadrži aplikaciju QQL. Prije pokretanja potpuno raspakujte ZIP arhivu
i držite sve isporučene datoteke i fasciklu data zajedno. Nemojte zasebno
distribuirati, premještati, brisati ili preimenovati EXE ili DLL datoteke.

PROVJERE PRI POKRETANJU
-----------------------

Prije pokretanja QuisquisLingo provjerava potrebne datoteke paketa,
kompatibilnost sa sistemom Windows i Media Foundation. Ove provjere nikada ne
preuzimaju niti instaliraju softver, ne traže administratorska prava, ne
mijenjaju registry ni Windows.

Ako je uprkos problemu moguće nastaviti, prikazuje se jedna poruka sa Continue
anyway i Cancel. Continue anyway pokušava pokrenuti QQL; Cancel ga zatvara. Ako
nedostaje neophodna programska datoteka, poruka nudi Close jer paket treba ponovo
preuzeti i potpuno raspakovati.

Podrška za Wine je Experimental. Ako Media Foundation nedostaje u okruženju
Wine, pokretanje može biti onemogućeno ili zvučne i medijske funkcije možda neće
raditi.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Potpuni paket sadrži sljedeće runtime datoteke Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Ako neka nedostaje, ponovo preuzmite potpuni paket QuisquisLingo za Windows i
raspakujte ga u cijelosti. Za runtime installer koristite samo zvanične Microsoft
izvore i nikada ne preuzimajte pojedinačne DLL datoteke sa web-stranica trećih
lica.

Zvanične informacije kompanije Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Izdanjima Windows N može biti potreban Microsoft Media Feature Pack za zvučne i
medijske funkcije. Media Feature Pack je obično dostupan u odjeljku Windows
Optional Features. U nekim verzijama sistema Windows N Media Feature Pack možda
nije dostupan u Optional Features. U tom slučaju sa web-stranice kompanije
Microsoft preuzmite Media Feature Pack koji odgovara vašoj verziji sistema
Windows.

Nakon instalacije paketa Media Feature Pack ponovo pokrenite Windows.
QuisquisLingo ga ne preuzima niti instalira automatski i ne mijenja sistemske
postavke.

PRETVARANJE TEKSTA U GOVOR
--------------------------

QuisquisLingo koristi govorne glasove instalirane u sistemu Windows. Dostupni
jezici i glasovi zavise od jezičkih i glasovnih komponenti sistema Windows
instaliranih na računaru. Ako nema kompatibilnog glasa, instalirajte odgovarajuću
komponentu putem postavki sistema Windows.

Audio Settings > Test Voice izgovara samo tekst koji unesete i koristi jezik
glasa podešen za odabrani kurs.

ZAPISNICI I DIJAGNOSTIKA
------------------------

Glavni crash log čuva se ovdje:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log provjere pri pokretanju čuva se ovdje:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug prikazuje dijagnostičke opcije. Logovi ostaju na lokalnom
računaru i ne šalju se automatski.

RJEŠAVANJE PROBLEMA
-------------------

1. Potpuno raspakujte cijelu ZIP arhivu.
2. Pokrenite QuisquisLingo.exe iz raspakovanog paketa.
3. Ako se prijavi da nedostaje runtime DLL, ponovo preuzmite i raspakujte cijeli
   paket prije nego što razmotrite zvanični Microsoft runtime installer.
4. Ako je potreban Media Feature Pack, pratite prethodne upute i nakon instalacije
   ponovo pokrenite Windows.
5. Ako se QQL i dalje ne pokreće, sačuvajte cijelu poruku o grešci i dostupne
   log datoteke za podršku.
