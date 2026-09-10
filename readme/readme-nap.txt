QuisquisLingo - Guida pe Windows
===============================

QuisquisLingo è n'applicazzione pe 'mparà 'e llengue, penzata pe chi studia e
pe chi crea curze. Mette nzieme lezziune strutturate, esercizie interattive,
attività audio e strumiente pe repassà, e dà pure 'e strumiente pe crià e
cagnà curze 'e lengua.

È fatta sia pe chi vò 'mparà na lengua, sia pe ll'auture, 'e prufessure e
ll'ate utente ca vonno custruì 'e curze lloro.

Pe vedé ambressa cu 'e mmagene comme funziona QuisquisLingo, guarda
QQL infographic.png, ca sta dint'ô package 'e ll'applicazzione.

Pe accummincià QuisquisLingo, avvia QuisquisLingo.exe.

COMME SE USA 'O PACKAGE
-----------------------

Stu package cuntene ll'applicazzione QQL. Primma 'e ll'avvio, estrai tutto
l'archivio ZIP e tiene nzieme tutt''e file date e 'a cartella data. Nun spartì,
nun spustà, nun scancellà e nun cagnà 'o nomme ê singule file EXE o DLL.

CONTROLLE A LL'AVVIO
-------------------

Primma 'e partì, QuisquisLingo controlla 'e file necessarie d'ô package, 'a
cumpatibilità cu Windows e Media Foundation. Sti controlle nun scarrecano e nun
nstallano software, nun cercano permisse 'e amministratore, nun cagnano 'o
registry e nun fanno cagnamiente a Windows.

Si 'o problema permette 'e continuà, esce nu sulo messaggio cu Continue anyway
e Cancel. Continue anyway prova a avvià QQL; Cancel 'o chiude. Si manca nu file
essenziale d'ô programma, 'o messaggio fa vedé Close, pecché s'ha da scarrecà
n'ata vota 'o package e s'ha da estrarre tutto.

'O supporto pe Wine è Experimental. Si Media Foundation manca dint'a Wine,
l'avvio pò nun riuscì oppure 'e funzione audio e media ponno nun funzionà.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

'O package cumpleto cuntene sti file runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Si ne manca uno, scarreca n'ata vota 'o package Windows cumpleto 'e
QuisquisLingo e estrailo tutto. Pe runtime installer ausa sulo 'e fonte
ufficiale Microsoft e nun scarrecà maje singule file DLL 'a site 'e terze parte.

Nfurmaziune ufficiale Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Ll'edizze Windows N ponno avé bisogno d'ô Microsoft Media Feature Pack pe 'e
funzione audio e media. Normalmente Media Feature Pack se trova int'a Windows
Optional Features. Int'a cierti versione 'e Windows N, Media Feature Pack pò nun
esserce int'a Optional Features. Int'a stu caso, scarreca d'ô sito Microsoft 'o
Media Feature Pack adatto â versione 'e Windows toja.

Doppo ca haje nstallato Media Feature Pack, riavvia Windows. QuisquisLingo nun
'o scarreca e nun 'o nstalla automaticamente e nun cagna 'e 'mpustaziune d'ô
sistema.

TEXT-TO-SPEECH
--------------

QuisquisLingo ausa 'e voce nstallate dint'a Windows. 'E llengue e 'e voce
dispunibbele dipenneno d'ê cumpunente 'e lengua e 'e voce Windows nstallate
ncopp'ô computer. Si nun ce sta na voce cumpatebbele, nstalla 'o cumpunente
adatto cu 'e 'mpustaziune 'e Windows.

Audio Settings > Test Voice dice sulo 'o testo ca scrive tu e ausa 'a lengua
d'â voce cunfigurata d'ô curso scigliuto.

LOG E DIAGNOSTECA
-----------------

'O crash log principale se sarva ccà:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

'O log d'ê controlle a ll'avvio se sarva ccà:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug fa vedé 'e opzione 'e diagnosteca. 'E log restano ncopp'ô
computer locale e nun se carrecano automaticamente.

COMME RISÒLVERE 'E PROBLEME
--------------------------

1. Estrai tutto l'archivio ZIP.
2. Avvia QuisquisLingo.exe d'ô package estratto.
3. Si vene signalato ca manca nu runtime DLL, scarreca e estrai n'ata vota 'o
   package cumpleto primma 'e penzà a nu runtime installer ufficiale Microsoft.
4. Si serve Media Feature Pack, sicuta 'e nfurmaziune ccà ncoppa e riavvia
   Windows doppo 'a nstallazzione.
5. Si QQL ancora nun s'avvia, cunserva tutto 'o messaggio d'errore e 'e file log
   dispunibbele pe ll'assistenza.
