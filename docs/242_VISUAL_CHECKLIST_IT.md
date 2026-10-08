# QQL Build 242 Revision 0 — checklist visiva

Versione prevista: **2.0.42+242000**, **Build 242, Revision 0**.
Scadenza Beta: **20 ottobre 2026, ore 23:59:59 locali**.

Questa è una checklist **da eseguire**: le caselle non indicano prove manuali già
completate. I test automatici sono documentati in `242_VALIDATION.md`. Una build
installata prima dell'aggiornamento del codice non mostra Revision 0 di Build
242: occorre ricompilare.

La scadenza coincide con quella di Build 241 perché entrambe le release sono del
20 settembre 2026. È il calcolo corretto dei 30 giorni, non la vecchia scadenza
trascinata avanti.

## 0. Preparazione

- [ ] Usa un account Windows di collaudo, una VM o un dispositivo con soli dati
      sacrificabili, soprattutto per i reset.
- [ ] Prepara un corso Custom di prova con una Lesson, un Round, un esercizio
      pubblicato, **un'immagine importata** e **almeno un MP3 importato e
      associato a una parola**. Servono per le sezioni 2 e 3.
- [ ] Esegui prima versione e Help, poi le credit, poi il salvataggio con media
      mancante; lascia i reset per ultimi.

```powershell
cd C:\QQL\QuisquisLingo
C:\QQL\flutter\bin\flutter.bat build windows --release
```

## 1. Versione

- [ ] Settings / App Info mostra Version 2.0.42 e **Build 242, Revision 0**.
      La versione tecnica è **2.0.42+242000**.
- [ ] Il rapporto esportato da Course Audit riporta la stessa build e revisione.
- [ ] L'informativa Beta indica il 20 ottobre 2026.

## 2. Il problema risolto: registrazione mancante

Questa è la correzione più importante della release. Prima di Build 242 il corso
diventava **impossibile da salvare per sempre**.

- [ ] Nel corso di prova, apri Course Editor > Audio Library e controlla che
      l'MP3 importato sia associato a una parola e si ascolti in anteprima.
- [ ] Chiudi QQL. Con Esplora risorse **cancella il file MP3** dalla cartella
      dati dell'app (`<AppSupport>\quisquislingo_audio\course_<hash>\`). In
      alternativa usa Device Administration > Remove imported media > Audio
      files, che è il modo previsto per arrivare allo stesso stato.
- [ ] Riapri QQL e apri Audio Library: la riga della registrazione mostra
      **File missing** in rosso, con la spiegazione di come ripararla.
- [ ] Modifica qualcosa nel corso e usa **Confirm course changes**. **Deve
      riuscire.** Prima di questa release falliva con un errore e non c'era modo
      di uscirne dall'app.
- [ ] Cancella quella registrazione dalla Audio Library (icona cestino) e
      conferma di nuovo il corso: la riga sparisce e il salvataggio riesce.
- [ ] Riapri Version History: la versione precedente è presente. Il backup fatto
      quando il file mancava esiste comunque.
- [ ] Con un MP3 **presente**, verifica che il backup continui a copiarlo:
      in `Documents\QuisquisLingo\Exports\Course Backups v9\<corso>\` deve
      esserci la cartella `..._assets` con il file.

## 3. Media credits

- [ ] Apri Course Info Editor di un corso che puoi modificare. Sotto
      **License / Rights** c'è la nuova sezione **Media credits**, con il testo
      che spiega che i media inclusi in QQL sono già accreditati nell'app.
- [ ] Premi **Add media credit**: compaiono Author, Licence, Title (optional),
      Source (optional), Applies to (optional).
- [ ] Salva lasciando compilato solo Author: deve comparire un errore che chiede
      anche la licenza. Compila entrambi e salva: ora riesce.
- [ ] Aggiungi due credit identiche: la seconda viene rifiutata con un messaggio
      esplicito.
- [ ] Conferma le modifiche al Course, riapri: le credit sono ancora lì.
- [ ] Apri **Course Info** (sola lettura): compare la scheda **Media credits**
      con le voci inserite e la frase che non concedono permessi QQL.
- [ ] Apri Settings > App Info > Credits con quel corso attivo: nella scheda del
      corso corrente compaiono le stesse credit.
- [ ] Esporta il corso in JSON e aprilo con un editor di testo: c'è il campo
      `mediaAttributions`. Esporta un corso **senza** credit: il campo **non**
      deve comparire affatto.
- [ ] Duplica il corso (Copy as New Course) e, se possibile, fanne un Fork: la
      copia conserva le credit.

## 4. Course Audit

- [ ] Su un corso con un'immagine importata o un MP3 importato e **senza** media
      credit, esegui Course Audit: compare l'avviso **MEDIA_ATTRIBUTION_MISSING**
      come **Warning**, non come Error, e l'export resta possibile.
- [ ] Aggiungi una media credit e riesegui l'audit: l'avviso sparisce.
- [ ] Su un corso che usa solo immagini incluse in QQL, l'avviso non compare.
- [ ] Course Editor > Help > **Audit Codes**: l'intestazione conta **104** codici
      (prima 103). Cerca `MEDIA_ATTRIBUTION_MISSING` e leggi la sua scheda.

## 5. Credit delle bandiere dell'app

- [ ] Settings > App Info > Credits > **Image credits**, sezione
      *World and language-related flags*.
- [ ] Il testo dice **Twenty-four** bandiere comunitarie o regionali (prima
      diceva Nineteen).
- [ ] L'elenco delle opere con attribuzione obbligatoria contiene **cinque**
      voci, incluse le due che prima mancavano: **Mirandese: ItsGandaM1ke —
      CC BY 4.0** e **Venetian: F l a n k e r — CC BY-SA 3.0**.
- [ ] Il testo finale parla delle **altre diciannove** come pubblico dominio o
      CC0, e non più di "tutte le rimanenti".

## 6. Editor Help

- [ ] Editor Help in inglese, voce **Audio Library**: cita sia la cartella
      `Documents/QuisquisLingo/Imports/Audio` sia **Open from…**.
- [ ] Voce **Image Bank**: cita la cartella fissa, **Open single image from…** e
      **Open Image Bank ZIP from…**. Non deve più dire che non c'è un selettore
      di file.
- [ ] Ripeti in italiano: stesse informazioni, e non deve comparire "senza
      finestra di selezione file".
- [ ] Apri la guida tecnica Publisher dall'Help: le sezioni **7a. Media a
      Publisher Course can and cannot carry** e **7b. Media credits** spiegano
      i limiti del JSON, il rifiuto delle registrazioni Publisher fuori da
      `assets/` e i crediti. Verifica apertura, scorrimento e leggibilità su
      schermo stretto, in tema chiaro e scuro.
- [ ] Ripeti i controlli di layout su Android. I nuovi pulsanti dei dialoghi
      nativi **Open from… / Save to…** restano nascosti su Android, dove il
      backend non è ancora implementato; su Windows devono essere disponibili.

## 7. Libreria immagini condivisa

- [ ] Come admin apri **Shared Image Library (admin)** da Course Manager o da
      Device Administration.
- [ ] Importa un'immagine, usala in un esercizio di un corso, conferma il corso.
- [ ] Torna alla libreria e prova a cancellare quell'immagine: la conferma deve
      **elencare il corso** che la usa ancora.
- [ ] Annulla, poi cancella davvero: l'immagine sparisce e l'esercizio mostra la
      notifica di immagine mancante. Il comportamento è voluto: la cancellazione
      resta permessa, ma non è più invisibile.
- [ ] Prova lo stesso con **Remove imported Image Bank**.
- [ ] Un utente non admin non deve vedere i comandi di gestione.

## 8. Esempio di Image Bank

- [ ] Nel repository, non nell'app, c'è `demo_image_banks\example_image_bank.zip`.
- [ ] Copialo in `Documents\QuisquisLingo\Imports\Images` (tenendo lì solo
      quello) e usa **Import Image Bank ZIP**, oppure **Open Image Bank ZIP
      from…**.
- [ ] L'import deve **riuscire** e aggiungere tre immagini di esempio. Il file
      che c'era prima dentro l'app non poteva essere importato: tutti i suoi ID
      appartenevano già al catalogo incluso.
- [ ] In `assets\exercise_images` non devono più esistere `manifest.json`,
      `manifest_external.json` e `image_bank_manifest.json`. Le 111 immagini
      incluse e la ricerca per etichette e tag devono funzionare come prima.

## 9. Publisher Course e registrazioni

Serve la build di collaudo con Dummy:

```powershell
C:\QQL\flutter\bin\flutter.bat build windows --release --dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true
```

- [ ] Importa `dummy-signed-v1.json`: deve funzionare come prima.
- [ ] Fai una copia del file e aggiungi a mano un `audioLibrary` con un percorso
      locale (per esempio `C:/qualcosa/audio.mp3`). L'import deve essere
      **rifiutato** con un messaggio che parla di registrazioni non consegnabili
      dentro un file di corso, **non** con un errore di firma.
- [ ] Un corso **Custom** con registrazioni locali continua a importarsi
      normalmente.

## 10. Reset

- [ ] Device Administration > **Remove imported media**: il riquadro ora avverte
      che i corsi che usavano le registrazioni rimosse andranno riparati in
      Audio Library.
- [ ] Esegui il reset solo audio: le immagini importate restano, i corsi restano,
      e vale quanto verificato nella sezione 2.
- [ ] Controlla in Inventory che i file audio siano effettivamente spariti.

## 11. Regressione rapida

- [ ] Su un bundled e su un Custom pubblicato: apri Lesson e Round, rispondi a un
      esercizio con immagine, completa il Round, verifica XP e progressi una sola
      volta.
- [ ] Le immagini degli esercizi si vedono correttamente in tema chiaro e scuro e
      su finestra stretta. Il caricamento è ora limitato nelle dimensioni di
      decodifica: le immagini devono restare nitide come prima.
- [ ] Review e, dove disponibile, Duel funzionano.
- [ ] Preview dall'Editor non registra progressi.
- [ ] Aprendo due corsi diversi, **Audio Library** mostra le registrazioni del
      corso aperto: resta una libreria per corso.

## Cosa segnalare

Per ogni problema annota: build normale o Dummy, schermata, passi, risultato
atteso e ottenuto, courseId e versione. Segnala subito corsi o progressi persi,
salvataggi che non sopravvivono al riavvio, immagini che spariscono, blocchi o
errori rossi.

L'esito positivo di questa checklist non sostituisce la suite completa e
l'analisi finale: sono passaggi distinti, documentati in `242_VALIDATION.md`.
