# QQL Build 241 Revision 2 — checklist visiva

Versione prevista: **2.0.41+241002**, **Build 241, Revision 2**.
Scadenza Beta: **20 ottobre 2026, ore 23:59:59 locali**.

Questa è una checklist da eseguire: le caselle non indicano prove manuali già completate. I test automatici mirati sono documentati in `241_VALIDATION.md`; la validazione finale completa è stata autorizzata ed è documentata nello stesso file. Una build installata prima dell’aggiornamento del codice non mostra Revision 2: occorre ricompilare.

## 0. Preparazione e ordine consigliato

- [ ] Usa un account Windows di collaudo, una VM o un dispositivo con soli dati sacrificabili, soprattutto per i reset. Un diverso profilo QQL non separa il file store dei corsi. Build normale e build Dummy possono leggere gli stessi dati dello stesso account Windows.
- [ ] Prepara un piccolo corso Custom di prova con una Lesson, un Round e almeno un esercizio pubblicato, più un elemento Draft. Se vuoi controllare i media, aggiungi un’immagine e un MP3 di prova.
- [ ] Tieni disponibili i tre file `dummy-signed-v1.json`, `dummy-signed-v2.json` e `dummy-unsigned.json`, presenti in `test/fixtures/publishers` o nello ZIP dei campioni.
- [ ] Esegui prima versione/Help, poi salvataggi e importazioni, poi firme/aggiornamenti; lascia i reset per ultimi.

Il codice da compilare è in `C:\QQL\QuisquisLingo`. Per una normale release Windows di prova:

```powershell
cd C:\QQL\QuisquisLingo
C:\QQL\flutter\bin\flutter.bat build windows --release
```

Per una release di collaudo che riconosca Dummy:

```powershell
C:\QQL\flutter\bin\flutter.bat build windows --release --dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true
```

L’output Windows è `build\windows\x64\runner\Release` nel progetto. Conserva l’intera cartella, non soltanto l’eseguibile. I due comandi scrivono nella stessa cartella di output: chiudi l’app e copia ogni risultato in una cartella distinta, chiaramente chiamata NORMALE o DUMMY, prima della compilazione successiva. Non unire i contenuti delle due build. Questi comandi sono istruzioni di collaudo, non una dichiarazione che una release sia già stata costruita o validata.

## 1. Versione, avvio e scadenza

- [ ] In Settings / App Info leggi Version 2.0.41 e **Build 241, Revision 2**. Dove compare la versione tecnica, deve essere **2.0.41+241002**.
- [ ] Il rapporto esportato da Course Audit riporta la stessa build/revisione, senza riferimenti correnti a Revision 0.
- [ ] L’informativa Beta mostra la scadenza del 20 ottobre 2026; non devono comparire blocchi di scadenza prima di quella data.
- [ ] Il Welcome e l’avviso Beta sono leggibili e i relativi pulsanti funzionano. Non devono riapparire continuamente dopo averli completati secondo le normali regole dell’app.
- [ ] Nella build normale non compare TEST ONLY. Nella build Dummy compare chiaramente il banner **TEST ONLY**, anche se compilata in modalità release.

Non è necessario alterare l’orologio del PC per il controllo visivo ordinario. I confini temporali della scadenza sono verificati dai test dedicati.

## 2. Course Types e Help — modifiche recenti

- [ ] Apri Editor Help in inglese: il testo indica tre tipi, Official Bundled, Publisher Course e Custom.
- [ ] La tabella ha **quattro colonne**: Aspetto/Aspect più i tre tipi; intestazioni e testi non sono troncati e non escono dalla scheda.
- [ ] Ripeti in italiano. Le definizioni cambiano lingua; i nomi di prodotto rimangono riconoscibili.
- [ ] Riduci la larghezza della finestra, poi prova il tema scuro e quello chiaro. Il carattere della tabella è più piccolo (12 punti), ma deve restare leggibile; i testi possono andare a capo. Controlla anche con l’ingrandimento del testo che usi normalmente.
- [ ] Da Technical reference / Riferimento tecnico apri **Publisher signing and approval**. La pagina è in inglese, indica che la verifica è implementata e distingue ciò che resta manuale.
- [ ] Espandi le sezioni su creazione chiavi, approvazione, firma, import e Dummy. I comandi si possono selezionare/copiare; nessun errore rosso aprendo o scorrendo le sezioni. Torna indietro: la lingua scelta nella pagina principale è conservata.

Risultato importante: verified/unverified è uno stato di autenticità, non un quarto tipo. La firma copre il JSON normalizzato e i dati incorporati, non i byte dei media esterni.

## 3. Salvataggio e riapertura — file store introdotto da Claude

- [ ] Crea il Custom di prova e conferma le modifiche al livello Course. Deve comparire in Course Manager.
- [ ] Cambia titolo o contenuto di un esercizio, salva nell’editor interno e conferma infine il Course. Riapri: trovi il valore nuovo, non una copia duplicata né un corso vuoto.
- [ ] Chiudi completamente l’app, riaprila e seleziona il corso: titolo, Lesson, Round, esercizi e media devono essere ancora disponibili.
- [ ] Prova l’annullamento: modifica un esercizio, poi annulla le modifiche del Course. Riaprendo devi ritrovare l’ultima versione confermata. Il salvataggio interno non deve aggirare il confine di conferma del Course.
- [ ] Crea o conserva un elemento Draft: in Editor resta visibile come Draft; nel percorso di studio compaiono solo i contenuti pubblicati.
- [ ] Cambia profilo QQL e torna al precedente. Verifica che permessi di Maintainer/Team e sola lettura restino coerenti: lo spostamento su file non deve concedere autorizzazioni nuove.

Il nuovo archivio usa `<AppSupport>/qql_courses_v1/custom` e `external_official`, con un JSON per corso. `v1` è la versione del formato di archivio, non del modello dei corsi. I vecchi blob SharedPreferences non vengono migrati automaticamente: se devi recuperare corsi presenti soltanto nella vecchia versione, conserva quella versione e i dati, esporta JSON supportati e prova l’import su dati di collaudo. Non considerare la mancata migrazione automatica come un salvataggio riuscito.

## 4. Import/export, copie, fork e cronologia

- [ ] Esporta un Custom, quindi importalo usando un ID nuovo oppure la scelta esplicita di copia separata. Titolo, struttura, Draft/Published, flag, autori e contenuti devono essere coerenti con il file.
- [ ] Prova sia la cartella Imports/import.json sia **Open from…**; entrambe devono applicare le stesse regole. Annullare un dialogo non deve importare o modificare nulla.
- [ ] Prova sia Export nella cartella fissa sia **Save to…**. Il JSON ottenuto deve essere leggibile e reimportabile secondo le regole del tipo di corso.
- [ ] Duplica un Custom autorizzato: la copia deve avere un’identità nuova, una storia indipendente e non condividere i progressi del corso sorgente.
- [ ] Su un corso ufficiale attendibile con derivati consentiti, prova Fork: il risultato è Custom e conserva la provenienza. Se i derivati non sono consentiti, il comando non deve consentire il fork. Un external non verificato richiede prima la verifica.
- [ ] Dopo una modifica confermata a un Custom già salvato, apri Version History: la versione precedente deve esserci. Il ripristino custom resta una modifica da confermare al livello Course.
- [ ] Controlla i media dopo riapertura ed export/import. Per MP3 o altri file esterni verifica che i file richiesti siano realmente disponibili: la firma del JSON non li rende automaticamente portabili o autenticati.

Open from… / Save to… e alcune operazioni sui media erano funzionalità precedenti: qui sono controlli di regressione, non nuove funzionalità attribuite a Claude o a questa revisione.

## 5. Firme — build di collaudo con Dummy

- [ ] Controlla il banner TEST ONLY, poi importa `dummy-signed-v1.json`.
- [ ] Compare **Install verified official course?**, con Dummy Publisher — TEST ONLY, ID e versione 1. Annulla una prima volta: il corso non deve comparire fra gli installati.
- [ ] Ripeti e conferma. Il corso compare in Course Manager; Course Info indica editore verificato, versione 1 e sola lettura. Deve essere disponibile per lo studio dei contenuti pubblicati.
- [ ] Completa un’attività del corso e annota lo stato/progresso visibile. Chiudi e riapri l’app: corso e stato devono essere conservati.
- [ ] Importa `dummy-signed-v2.json`: compare la conferma di aggiornamento firmato; dopo conferma trovi versione 2 e il relativo titolo. I progressi già registrati devono rimanere.
- [ ] In Version History trovi la versione 1 archiviata. Eventuali fork custom già creati devono rimanere indipendenti e invariati.
- [ ] Reimporta v2 oppure v1 dopo v2: stessa versione e downgrade devono essere rifiutati senza cambiare il corso installato.
- [ ] Importa `dummy-unsigned.json`: deve essere rifiutato per firma mancante. Non deve comparire un’opzione per installarlo comunque come ufficiale.
- [ ] Crea una copia di v1 e cambia soltanto il titolo nel JSON con un editor di testo: l’import deve essere rifiutato. La v2 installata deve rimanere intatta.
- [ ] Per simulare una chiave sconosciuta, in un’altra copia cambia solo `dummy-1` dentro `publisherSignature` in `unknown-key`: l’import deve essere rifiutato, senza approvazione automatica.

Non modificare i fixture originali. I test automatici coprono anche l’attaccante che ricalcola il checksum dopo una modifica, le firme malformate, la sostituzione di editore e la rotazione/revoca delle chiavi: per questi casi non serve inventare prove crittografiche manuali.

## 6. Build normale e corsi già presenti senza verifica

- [ ] Avvia la build normale senza flag: niente banner TEST ONLY. Importare il Dummy firmato deve fallire perché la chiave non è approvata nella configurazione normale.
- [ ] Se nello stesso ambiente avevi già installato Dummy con la build di collaudo, nella build normale deve rimanere nel Course Manager con **Verification required**, senza essere offerto come corso ufficiale utilizzabile nello studio. File e progressi non devono sparire.
- [ ] Tornando alla build Dummy, la firma torna verificabile: il corso firmato deve riapparire nello studio con i progressi conservati. Questo prova la diversa configurazione di fiducia, non una cancellazione/reinstallazione del corso.
- [ ] Se hai un vero corso esterno già installato senza firma da una build precedente, controlla che rimanga nel Manager con Verification required. Per riattivarlo serve una release firmata più recente dello stesso corso/editore e una conferma esplicita di associazione.
- [ ] I corsi bundled continuano a funzionare senza una firma per ogni file. Un JSON importato dall’esterno che dichiara bundledOfficial non deve essere accettato.
- [ ] I normali Custom validi si importano ancora senza firma. Non devono diventare Official soltanto perché importati.

Il registro normale non contiene ancora editori esterni reali approvati. L’approvazione operativa e la distribuzione di un aggiornamento del registro sono descritte nella guida sulle firme.

## 7. Inventory — allineamento al nuovo file store

- [ ] Apri Inventory e cerca i corsi di prova: devono esserci percorsi reali sotto `qql_courses_v1/custom` e, nella build Dummy dopo l’import, `qql_courses_v1/external_official`.
- [ ] I dettagli devono mostrare file, dimensione in byte e data di modifica. Un corso non deve apparire soltanto come il vecchio blob nelle preferenze.
- [ ] Modifica e conferma un Custom, poi aggiorna Inventory: la data del suo file deve riflettere il salvataggio. La dimensione può restare uguale se la modifica ha la stessa lunghezza.
- [ ] Dopo l’aggiornamento Dummy a v2, Inventory deve continuare a mostrare il file del corso con lo stesso ID, senza duplicazioni spurie del corso attivo.

I file malformati vengono conservati ed elencati per diagnosi; le relative prove automatiche sono già presenti. Non corrompere manualmente un archivio che contiene dati utili.

## 8. Reset — soltanto alla fine e su dati sacrificabili

- [ ] Apri l’anteprima del reset e controlla che rilevi i file dei corsi anche senza le vecchie chiavi SharedPreferences. Annulla: nulla deve cambiare.
- [ ] Prova un reset limitato ai progressi: i corsi installati devono rimanere. Verifica gli effetti sui progressi in base alla scelta mostrata nel dialogo.
- [ ] Prova il reset dei corsi custom/locali: nell’architettura attuale questo ambito elimina **anche i corsi external_official installati**, oltre ai custom. Gli asset bundled devono restare disponibili. Leggi attentamente l’anteprima prima di confermare.
- [ ] Dopo riavvio, i corsi eliminati non devono ricomparire da vecchie preferenze. La cartella `qql_courses_v1` viene rimossa da questo reset; eventuali riferimenti a progressi orfani non devono ricreare i corsi.
- [ ] Il reset completo deve ripulire i dati locali previsti e consentire un avvio pulito con i corsi bundled. Le chiavi private degli editori, conservate fuori dai dati dell’app, non fanno parte del reset.

## 9. Controllo rapido dei flussi preesistenti

- [ ] Su un bundled e su un Custom pubblicato: apri Lesson e Round, rispondi a un esercizio, completa il Round e controlla che il progresso e gli XP siano registrati una sola volta.
- [ ] Cambia corso, torna indietro e riavvia: selezione e progressi non devono apparire duplicati o azzerati.
- [ ] Apri Review e, dove disponibile, Duel; verifica che la navigazione e i contenuti non siano stati compromessi dal nuovo caricamento dei file.
- [ ] Prova Preview dall’Editor: non deve registrare progressi di studio. Controlla almeno una schermata in tema chiaro e scuro.
- [ ] Se usi un Team, verifica un salvataggio autorizzato e una consultazione da utente esterno senza permessi di modifica.

## Cosa segnalare prima dell’OK finale

Per ogni problema annota: build normale o Dummy, schermata, passi, risultato atteso/ottenuto, courseId e versione se disponibili. Segnala subito corsi/progressi persi, import ufficiali non verificati accettati, salvataggi che non sopravvivono al riavvio, blocchi, errori rossi o colonne illeggibili.

L’esito positivo di questa checklist non sostituisce la suite completa e l’analisi finale: sono passaggi distinti. La loro esecuzione finale resta in attesa dell’OK del proprietario.


## Libreria personale e Available on this device

- [ ] In fondo al Course Selector apri **Available on this device**. Controlla l’ordine: Bundled Courses, Publisher Courses, My Custom Courses, Other Custom Courses, comprese le sezioni vuote.
- [ ] Apri **Help** nella nuova pagina: testo scorrevole e leggibile anche su schermo stretto; spiega Add, Remove, Maintainer, ordine alfabetico e disinstallazione admin.
- [ ] Importa un Publisher come utente A. Come utente B trovalo nella pagina del dispositivo e usa **Add to my courses**. Compare nei suoi Selector e Manager; la pagina indica **Added**.
- [ ] Verifica un Custom creato da A nella sezione Other Custom Courses di B. Aggiungerlo non deve concedere a B permessi di modifica.
- [ ] Non devono esistere Hide, Unhide o Hidden courses. I corsi precedentemente nascosti tornano visibili se inclusi nella libreria personale.
- [ ] Usa **Remove from my courses** prima dal Selector, poi dal Manager: scompare da entrambi solo per il profilo attivo. La casella di reset è inizialmente deselezionata.
- [ ] Aggiungi nuovamente il corso: i progressi conservati ritornano. Ripeti selezionando il reset, annulla la conferma finale e controlla che nulla cambi; poi conferma e verifica che solo quel profilo e quel corso siano azzerati.
- [ ] Rimuovi il corso corrente: lo studio passa a un altro corso personale. Rimuovi tutti i corsi studiabili: appare una pagina vuota con accesso ad Available on this device, senza caricamento infinito.
- [ ] Un utente non admin non vede **Remove Publisher Course from device**. L’admin lo vede solo sui Publisher nel Manager. Se B ha ancora il corso nella propria libreria, la disinstallazione deve essere bloccata.
- [ ] Dopo che B lo ha rimosso dalla propria libreria, l’admin può disinstallarlo. Scompare dalla pagina del dispositivo. Reinstallandolo con lo stesso ID, progressi conservati e backup delle versioni rimangono disponibili.
- [ ] Controlla Editor Help in entrambe le lingue e la tabella Course Types aggiornata.
- [ ] Nuovo corso: **Continue to Editor** spiega che il corso verrà salvato alla conferma nell’editor; annullando non viene creato alcun corso salvato.

La build resta 241 Revision 2, con expiry 20 ottobre 2026 alle 23:59:59 locali. La validazione finale completa e la generazione della release restano in attesa dell’OK del proprietario.


## Rifiniture della pagina e import diretto

- [ ] Ogni corso mostra **Maintainer**: nome del profilo per i Custom, editore per Bundled/Publisher. Per un profilo non presente sul dispositivo appare un’indicazione esplicita con ID.
- [ ] Ogni sezione è in ordine alfabetico, senza distinguere maiuscole e minuscole.
- [ ] **Added · Remove** permette di rimuovere il corso direttamente dalla pagina; Cancel conserva tutto, confermando riappare Add to my courses.
- [ ] Con Course Manager disattivato apri **Import Course** dal Selector. Back torna allo studio, anche dopo un import; non deve apparire Course Manager né essere attivato.
- [ ] Importando `dummy-unsigned.json`, il messaggio deve dire **This file cannot be imported as a Publisher Course.**, senza usare official.

## Chiarezza del reset durante la rimozione

- [ ] Con Reset my progress selezionato, entrambe le conferme chiariscono che tutti gli XP, inclusi quelli settimanali e quelli guadagnati nel corso, i giorni di studio totali e per lingua e la streak restano. Vengono azzerati soltanto i completamenti e risultati del corso per il profilo attivo.
- [ ] Lo stesso comportamento è spiegato nel Help della pagina e nel Course Editor Help in inglese e italiano.

## Libreria vuota

- [ ] Rimuovi tutti i corsi: Home mostra My courses senza bandiera, conserva Settings e mostra Course Manager solo se attivato per quel profilo.
- [ ] Da Settings restano disponibili Profile, User Data, Audio Settings e Device Administration per admin. Senza corso corrente, reset del corso e Test Voice sono disabilitati e spiegati.
- [ ] Available on this device permette di riaggiungere un corso; nessun corso rimosso viene riaggiunto automaticamente.

## Stati non disponibili

- [ ] In Available on this device, Not published · Draft e Verification required hanno una cornice blu e possono comparire insieme; leggibili in tema chiaro/scuro e a larghezza telefono.

- [ ] Titoli in grassetto: Bundled neri in tema chiaro, bianchi su nero in tema scuro, Publisher viola, Custom arancioni. Sui display stretti Add/Remove sta sotto le informazioni per lasciare spazio a titoli e stati.
