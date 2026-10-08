QuisquisLingo - Vejledning til Windows
=====================================

QuisquisLingo er et program til sprogindlæring for elever og kursusskabere. Det
kombinerer strukturerede lektioner, interaktive øvelser, lydaktiviteter og
værktøjer til repetition, samtidig med at det indeholder værktøjer til at oprette
og redigere sprogkurser.

Det er udviklet både til personer, der vil lære et sprog, og til forfattere,
undervisere eller andre brugere, der vil opbygge deres egne kurser.

Du kan få et hurtigt visuelt overblik over, hvordan QuisquisLingo fungerer, i
QQL infographic.png, som følger med programpakken.

Start QuisquisLingo ved at køre QuisquisLingo.exe.

BRUG AF PAKKEN
--------------

Denne pakke indeholder QQL-programmet. Pak hele ZIP-arkivet ud, før du starter
det, og behold alle medfølgende filer og mappen data samlet. Du må ikke distribuere,
flytte, slette eller omdøbe enkelte EXE- eller DLL-filer.

KONTROL VED START
-----------------

Før start kontrollerer QuisquisLingo de nødvendige pakkefiler, kompatibilitet
med Windows og Media Foundation. Kontrollerne henter eller installerer aldrig
software, anmoder ikke om administratorrettigheder, ændrer ikke registry eller
Windows.

Et problem, hvor det er muligt at fortsætte, giver én meddelelse med Continue
anyway og Cancel. Continue anyway forsøger at starte QQL; Cancel lukker det. Hvis
en vigtig programfil mangler, viser meddelelsen Close, fordi pakken skal hentes
og pakkes helt ud igen.

Understøttelse af Wine er Experimental. Hvis Media Foundation mangler under Wine,
kan programmet muligvis ikke starte, eller lyd- og mediefunktioner virker måske
ikke.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Den komplette pakke indeholder følgende Microsoft Visual C++ x64 runtime-filer:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Hvis en af dem mangler, skal du hente den komplette QuisquisLingo-pakke til
Windows igen og pakke alt ud. Brug kun officielle Microsoft-kilder til runtime
installer, og hent aldrig enkelte DLL-filer fra tredjepartswebsteder.

Officielle oplysninger fra Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N-udgaver kan kræve Microsoft Media Feature Pack til lyd- og
mediefunktioner. Media Feature Pack findes normalt under Windows Optional
Features. I nogle versioner af Windows N er Media Feature Pack muligvis ikke
tilgængelig under Optional Features. I så fald skal du hente den Media Feature
Pack, der passer til din version af Windows, fra Microsofts websted.

Genstart Windows efter installation af Media Feature Pack. QuisquisLingo henter
eller installerer den ikke automatisk og ændrer ikke systemindstillinger.

TEKST TIL TALE
--------------

QuisquisLingo bruger de talestemmer, der er installeret i Windows. De tilgængelige
sprog og stemmer afhænger af de sprog- og stemmekomponenter til Windows, der er
installeret på computeren. Hvis der ikke findes en kompatibel stemme, skal du
installere den relevante komponent via indstillingerne i Windows.

Audio Settings > Test Voice læser kun den tekst op, du indtaster, og bruger det
stemmesprog, der er konfigureret for det valgte kursus.

LOGFILER OG DIAGNOSTIK
----------------------

Den primære crash log gemmes her:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Loggen fra startkontrollen gemmes her:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug viser diagnostiske muligheder. Logfilerne bliver på den lokale
computer og overføres ikke automatisk.

FEJLFINDING
-----------

1. Pak hele ZIP-arkivet helt ud.
2. Kør QuisquisLingo.exe fra den udpakkede pakke.
3. Hvis der meldes om en manglende runtime DLL, skal du hente og pakke hele
   pakken ud igen, før du overvejer en officiel Microsoft runtime installer.
4. Hvis Media Feature Pack er nødvendig, skal du følge vejledningen ovenfor og
   genstarte Windows efter installationen.
5. Hvis QQL stadig ikke starter, skal du gemme hele fejlmeddelelsen og de
   tilgængelige logfiler til support.
