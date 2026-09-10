QuisquisLingo - Ghid pentru Windows
==================================

QuisquisLingo este o aplicație pentru învățarea limbilor, destinată cursanților
și creatorilor de cursuri. Aceasta combină lecții structurate, exerciții
interactive, activități audio și instrumente de recapitulare, oferind totodată
instrumente pentru crearea și editarea cursurilor de limbi străine.

Este concepută atât pentru persoanele care doresc să învețe o limbă, cât și
pentru autori, profesori sau alți utilizatori care doresc să-și creeze propriile
cursuri.

Pentru o prezentare vizuală rapidă a modului în care funcționează QuisquisLingo,
consultați QQL infographic.png, inclusă în pachetul aplicației.

Pentru a porni QuisquisLingo, rulați QuisquisLingo.exe.

UTILIZAREA PACHETULUI
--------------------

Acest pachet conține aplicația QQL. Extrageți întreaga arhivă ZIP înainte de
pornire și păstrați împreună toate fișierele furnizate și folderul data. Nu
distribuiți, mutați, ștergeți sau redenumiți separat fișiere EXE ori DLL.

VERIFICĂRI LA PORNIRE
--------------------

Înainte de pornire, QuisquisLingo verifică fișierele necesare ale pachetului,
compatibilitatea cu Windows și Media Foundation. Aceste verificări nu descarcă
sau instalează niciodată programe, nu solicită drepturi de administrator, nu
modifică registry și nu schimbă Windows.

O problemă după care se poate continua produce un singur mesaj cu Continue
anyway și Cancel. Continue anyway încearcă să pornească QQL; Cancel îl închide.
Dacă lipsește un fișier esențial al programului, mesajul oferă Close, deoarece
pachetul trebuie descărcat din nou și extras complet.

Asistența pentru Wine este Experimental. Lipsa Media Foundation în Wine poate
împiedica pornirea sau funcționarea caracteristicilor audio și media.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Pachetul complet include aceste fișiere runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Dacă unul lipsește, descărcați din nou pachetul Windows QuisquisLingo complet și
extrageți-l integral. Pentru runtime installer folosiți numai surse oficiale
Microsoft și nu descărcați niciodată fișiere DLL individuale de pe site-uri terțe.

Informații oficiale Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Edițiile Windows N pot necesita Microsoft Media Feature Pack pentru funcțiile
audio și media. Media Feature Pack este disponibil în mod normal în Windows
Optional Features. Pe unele versiuni de Windows N, Media Feature Pack poate să
nu fie disponibil în Optional Features. În acest caz, descărcați de pe site-ul
Microsoft pachetul Media Feature Pack potrivit pentru versiunea dumneavoastră de
Windows.

Reporniți Windows după instalarea Media Feature Pack. QuisquisLingo nu îl
descarcă și nu îl instalează automat și nu modifică setările sistemului.

TEXT-TO-SPEECH
--------------

QuisquisLingo folosește vocile instalate în Windows. Limbile și vocile disponibile
depind de componentele de limbă și voce Windows instalate pe computer. Dacă nu
este disponibilă o voce compatibilă, instalați componenta potrivită prin setările
Windows.

Audio Settings > Test Voice rostește numai textul introdus de dumneavoastră și
folosește limba vocii configurată de cursul selectat.

JURNALE ȘI DIAGNOSTICARE
-----------------------

Crash log principal este stocat aici:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log verificărilor la pornire este stocat aici:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug afișează opțiuni de diagnosticare. Log rămân pe computerul
local și nu sunt încărcate automat.

DEPANARE
--------

1. Extrageți complet întreaga arhivă ZIP.
2. Rulați QuisquisLingo.exe din pachetul extras.
3. Dacă este raportată lipsa unui runtime DLL, descărcați și extrageți din nou
   pachetul complet înainte de a lua în considerare runtime installer oficial
   Microsoft.
4. Dacă este necesar Media Feature Pack, urmați instrucțiunile de mai sus și
   reporniți Windows după instalare.
5. Dacă QQL tot nu pornește, păstrați mesajul de eroare complet și fișierele log
   disponibile pentru asistență.
