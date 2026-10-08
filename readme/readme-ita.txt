QuisquisLingo - Guida per Windows
================================

QuisquisLingo è un'applicazione per l'apprendimento delle lingue destinata sia
a chi studia sia a chi crea corsi. Riunisce lezioni strutturate, esercizi
interattivi, attività audio e strumenti di ripasso, e offre anche funzioni per
creare e modificare corsi di lingua.

È pensata sia per chi desidera studiare una lingua sia per autori, insegnanti
o altri utenti che vogliono realizzare i propri corsi.

Per una rapida panoramica visiva del funzionamento di QuisquisLingo, consulta
QQL infographic.png, inclusa nel package dell'applicazione.

Per avviare QuisquisLingo, esegui QuisquisLingo.exe.

USO DEL PACKAGE
---------------

Questo package contiene l'applicazione QQL. Estrai l'intero archivio ZIP prima
di avviarla e mantieni insieme tutti i file forniti e la cartella data. Non
distribuire, spostare, eliminare o rinominare singoli file EXE o DLL.

CONTROLLI ALL'AVVIO
-------------------

Prima dell'avvio, QuisquisLingo controlla i file necessari del package, la
compatibilità con Windows e Media Foundation. Questi controlli non scaricano
né installano software, non richiedono privilegi elevati, non cambiano il
registro e non modificano Windows.

In caso di problema recuperabile compare un unico messaggio con Continue
anyway e Cancel. Continue anyway prova ad avviare QQL; Cancel chiude il
programma. Se manca un file essenziale, il messaggio offre Close perché il
package deve essere scaricato ed estratto nuovamente.

Il supporto per Wine è sperimentale. Se Media Foundation non è disponibile in
Wine, l'avvio o le funzioni audio e multimediali potrebbero non funzionare.

RUNTIME MICROSOFT VISUAL C++
----------------------------

Il package completo include questi file di runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Se ne manca uno, scarica nuovamente il package Windows completo di
QuisquisLingo ed estrailo interamente. Usa soltanto fonti ufficiali Microsoft
per gli installer del runtime e non scaricare mai singole DLL da siti di terze
parti.

Informazioni ufficiali Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Le edizioni Windows N possono richiedere Microsoft Media Feature Pack per le
funzioni audio e multimediali. Normalmente Media Feature Pack è disponibile
nelle Funzionalità facoltative di Windows. In alcune versioni di Windows N
potrebbe non essere disponibile nelle Funzionalità facoltative. In tal caso,
scarica dal sito Microsoft il Media Feature Pack adatto alla tua versione di
Windows.

Dopo aver installato Media Feature Pack, riavvia Windows. QuisquisLingo non lo
scarica o installa automaticamente e non modifica le impostazioni di sistema.

SINTESI VOCALE
--------------

QuisquisLingo usa le voci installate in Windows. Le lingue e le voci disponibili
dipendono dai componenti lingua e voce installati nel computer. Se non è
disponibile una voce compatibile, installa il componente appropriato dalle
impostazioni di Windows.

Audio Settings > Test Voice pronuncia soltanto il testo inserito e usa la
lingua vocale configurata dal corso selezionato.

LOG E DIAGNOSTICA
-----------------

Il log principale degli arresti anomali si trova in:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Il log dei controlli di avvio si trova in:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug mostra le opzioni diagnostiche. I log restano nel computer
locale e non vengono caricati automaticamente.

RISOLUZIONE DEI PROBLEMI
------------------------

1. Estrai interamente l'archivio ZIP completo.
2. Esegui QuisquisLingo.exe dal package estratto.
3. Se viene segnalata una DLL di runtime mancante, scarica ed estrai di nuovo
   il package completo prima di valutare un installer runtime Microsoft
   ufficiale.
4. Se è richiesto Media Feature Pack, segui le indicazioni precedenti e riavvia
   Windows dopo l'installazione.
5. Se QQL non si avvia ancora, conserva il messaggio di errore completo e i
   file di log disponibili per l'assistenza.
