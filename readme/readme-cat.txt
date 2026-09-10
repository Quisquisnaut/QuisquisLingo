QuisquisLingo - Guia per al Windows
==================================

QuisquisLingo és una aplicació d'aprenentatge d'idiomes per a estudiants i
creadors de cursos. Combina lliçons estructurades, exercicis interactius,
activitats d'àudio i eines de repàs, i també ofereix eines per crear i editar
cursos d'idiomes.

Està dissenyada tant per a persones que volen aprendre una llengua com per a
autors, docents o altres usuaris que volen crear els seus propis cursos.

Per obtenir una visió general ràpida i visual del funcionament de
QuisquisLingo, consulteu QQL infographic.png, inclosa en el paquet de
l'aplicació.

Per iniciar QuisquisLingo, executeu QuisquisLingo.exe.

ÚS DEL PAQUET
-------------

Aquest paquet conté l'aplicació QQL. Extraieu tot l'arxiu ZIP abans d'iniciar-la
i manteniu junts tots els fitxers subministrats i la carpeta data. No distribuïu,
moveu, suprimiu ni canvieu el nom de fitxers EXE o DLL individuals.

COMPROVACIONS D'INICI
---------------------

Abans d'iniciar-se, QuisquisLingo comprova els fitxers necessaris del paquet,
la compatibilitat amb el Windows i Media Foundation. Aquestes comprovacions no
descarreguen ni instal·len mai programari, no demanen permisos d'administrador,
no canvien el registry ni modifiquen el Windows.

Un problema que permet continuar produeix un únic missatge amb Continue anyway
i Cancel. Continue anyway intenta iniciar QQL; Cancel el tanca. Si falta un
fitxer essencial del programa, el missatge ofereix Close perquè cal tornar a
descarregar i extreure completament el paquet.

La compatibilitat amb Wine és Experimental. Si Media Foundation no està
disponible al Wine, pot impedir l'inici o el funcionament de les funcions d'àudio
i de contingut multimèdia.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

El paquet complet inclou aquests fitxers runtime del Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Si en falta cap, torneu a descarregar el paquet complet del QuisquisLingo per al
Windows i extraieu-lo completament. Per als runtime installer, feu servir només
fonts oficials de Microsoft i no descarregueu mai fitxers DLL individuals de
llocs web de tercers.

Informació oficial de Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Les edicions Windows N poden necessitar el Microsoft Media Feature Pack per a
les funcions d'àudio i contingut multimèdia. Normalment, Media Feature Pack està
disponible a Windows Optional Features. En algunes versions de Windows N, Media
Feature Pack pot no estar disponible a Optional Features. En aquest cas,
descarregueu del lloc web de Microsoft el Media Feature Pack adequat per a la
vostra versió del Windows.

Reinicieu el Windows després d'instal·lar Media Feature Pack. QuisquisLingo no
el descarrega ni l'instal·la automàticament i no canvia la configuració del
sistema.

TEXT-TO-SPEECH
--------------

QuisquisLingo utilitza les veus de parla instal·lades al Windows. Els idiomes i
les veus disponibles depenen dels components d'idioma i veu del Windows
instal·lats a l'ordinador. Si no hi ha cap veu compatible, instal·leu el component
adequat mitjançant la configuració del Windows.

Audio Settings > Test Voice només llegeix el text que introduïu i utilitza
l'idioma de veu configurat pel curs seleccionat.

REGISTRES I DIAGNÒSTIC
----------------------

El crash log principal s'emmagatzema a:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

El log de les comprovacions d'inici s'emmagatzema a:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug mostra opcions de diagnòstic. Els logs es mantenen a l'ordinador
local i no es carreguen automàticament.

RESOLUCIÓ DE PROBLEMES
----------------------

1. Extraieu completament tot l'arxiu ZIP.
2. Executeu QuisquisLingo.exe des del paquet extret.
3. Si s'informa que falta un runtime DLL, torneu a descarregar i extreure el
   paquet complet abans de plantejar-vos un runtime installer oficial de
   Microsoft.
4. Si cal Media Feature Pack, seguiu les indicacions anteriors i reinicieu el
   Windows després de la instal·lació.
5. Si QQL encara no s'inicia, conserveu el missatge d'error complet i els fitxers
   log disponibles per rebre assistència.
