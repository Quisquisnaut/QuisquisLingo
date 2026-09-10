QuisquisLingo - Vodič za Windows
================================

QuisquisLingo je aplikacija za učenje jezika namijenjena učenicima i autorima
tečajeva. Objedinjuje strukturirane lekcije, interaktivne vježbe, zvučne
aktivnosti i alate za ponavljanje, a pruža i alate za izradu i uređivanje
jezičnih tečajeva.

Namijenjena je i ljudima koji žele učiti jezik i autorima, nastavnicima te
drugim korisnicima koji žele izraditi vlastite tečajeve.

Za brz vizualni pregled načina rada aplikacije QuisquisLingo pogledajte
QQL infographic.png, uključenu u paket aplikacije.

Za pokretanje aplikacije QuisquisLingo izvršite QuisquisLingo.exe.

UPOTREBA PAKETA
---------------

Ovaj paket sadrži aplikaciju QQL. Prije pokretanja potpuno raspakirajte ZIP
arhivu i držite sve isporučene datoteke i mapu data zajedno. Nemojte zasebno
distribuirati, premještati, brisati ili preimenovati EXE ili DLL datoteke.

PROVJERE PRI POKRETANJU
-----------------------

Prije pokretanja QuisquisLingo provjerava potrebne datoteke paketa,
kompatibilnost sa sustavom Windows i Media Foundation. Te provjere nikada ne
preuzimaju niti instaliraju softver, ne traže administratorske ovlasti, ne
mijenjaju registry ni Windows.

Ako je unatoč problemu moguće nastaviti, prikazuje se jedna poruka s gumbima
Continue anyway i Cancel. Continue anyway pokušava pokrenuti QQL; Cancel ga
zatvara. Ako nedostaje nužna programska datoteka, poruka nudi Close jer paket
treba ponovno preuzeti i potpuno raspakirati.

Podrška za Wine je Experimental. Ako Media Foundation nedostaje u okruženju
Wine, pokretanje može biti onemogućeno ili zvučne i medijske značajke možda neće
raditi.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Potpuni paket sadrži sljedeće runtime datoteke Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Ako neka nedostaje, ponovno preuzmite potpuni paket QuisquisLingo za Windows i
raspakirajte ga u cijelosti. Za runtime installer koristite samo službene izvore
tvrtke Microsoft i nikada ne preuzimajte pojedinačne DLL datoteke s web-mjesta
trećih strana.

Službene informacije tvrtke Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Izdanja Windows N mogu zahtijevati Microsoft Media Feature Pack za zvučne i
medijske funkcije. Media Feature Pack obično je dostupan u izborniku Windows
Optional Features. U nekim verzijama sustava Windows N Media Feature Pack možda
neće biti dostupan u Optional Features. U tom slučaju s web-mjesta tvrtke
Microsoft preuzmite Media Feature Pack prikladan za svoju verziju sustava
Windows.

Nakon instalacije paketa Media Feature Pack ponovno pokrenite Windows.
QuisquisLingo ga ne preuzima niti instalira automatski i ne mijenja postavke
sustava.

PRETVARANJE TEKSTA U GOVOR
--------------------------

QuisquisLingo koristi govorne glasove instalirane u sustavu Windows. Dostupni
jezici i glasovi ovise o jezičnim i glasovnim komponentama sustava Windows
instaliranima na računalu. Ako nema kompatibilnog glasa, instalirajte
odgovarajuću komponentu putem postavki sustava Windows.

Audio Settings > Test Voice izgovara samo tekst koji unesete i koristi jezik
glasa postavljen za odabrani tečaj.

ZAPISNICI I DIJAGNOSTIKA
------------------------

Glavni crash log sprema se ovdje:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log provjera pri pokretanju sprema se ovdje:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug prikazuje dijagnostičke mogućnosti. Logovi ostaju na lokalnom
računalu i ne šalju se automatski.

RJEŠAVANJE PROBLEMA
-------------------

1. Potpuno raspakirajte cijelu ZIP arhivu.
2. Pokrenite QuisquisLingo.exe iz raspakiranog paketa.
3. Ako se prijavi da nedostaje runtime DLL, ponovno preuzmite i raspakirajte
   cijeli paket prije nego što razmotrite službeni Microsoft runtime installer.
4. Ako je potreban Media Feature Pack, slijedite prethodne upute i nakon
   instalacije ponovno pokrenite Windows.
5. Ako se QQL i dalje ne pokreće, sačuvajte cijelu poruku o pogrešci i dostupne
   log datoteke za podršku.
