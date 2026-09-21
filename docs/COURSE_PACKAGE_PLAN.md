# Modello del corso v11 e pacchetto del corso (ZIP con media) — piano

Scritto il 2026-09-21 a partire da `efdf784` (Build 242 Revisione 0,
`2.0.42+242000`). **Stato: approvato. Tranche 0 implementata come Build 243
Revisione 0 (`2.0.43+243000`), correzione dei corsi illeggibili come Revisione
1 (`2.0.43+243001`) e Tranche 1 come Revisione 2 (`2.0.43+243002`), vedi
`docs/243_CHANGE_SUMMARY.md`. Le Tranche 2 e 3 saranno le Revisioni 3 e 4.
Lavoro sospeso dopo la Revisione 2: vedi §0 per riprendere.** Ogni tranche è una revisione con il proprio commit; i controlli finali
(analyzer, suite completa, validatori) si eseguono solo dopo l'approvazione del
proprietario.

Leggere prima `AGENTS.md`: le sue regole valgono per tutto questo lavoro (modifica
più piccola possibile, niente refactoring estranei, niente commit o push senza
richiesta, test mirati durante il lavoro e analyzer più suite completa una sola
volta alla fine, `rg`/git e mai `Get-Content`, ogni nuova chiave o cartella
aggiunta anche a `AppResetService`, `InventoryService` e
`docs/239_RESET_STORAGE_INVENTORY.md`).

Contesto: `docs/MEDIA_LIBRARIES_PLAN.md` §2.2 e §7 descrivono il problema. Oggi un
corso esportato è un solo file JSON: registrazioni MP3 e immagini normali degli
esercizi non viaggiano, perché il corso contiene il percorso del file sul
dispositivo dell'autore.

## 0. Punto di ripresa (aggiornato al 2026-09-21)

**Fatto e committato su `main` (nessun push):**

| Revisione | Versione | Contenuto |
|---|---|---|
| 0 | `2.0.43+243000` | Modello v11, nuovi campi facoltativi, conversione di corsi inclusi, demo e prove Dummy, cartelle `qql_courses_v2` e `Course Backups v11` |
| 1 | `2.0.43+243001` | Un corso salvato illeggibile non nasconde più gli altri |
| 2 | `2.0.43+243002` | Tranche 1: riferimenti `media:<sha256>.<ext>`, una cartella di media per corso, copia in Fork/Copia/Fusione, backup e ripristino dei media, pulizia per corso |

La validazione finale (suite completa, analyzer su tutto il repository, i
quattro validatori Python) è registrata in `docs/243_VALIDATION.md`.

**Da fare, nell'ordine:**

1. **Tranche 2 → Revisione 3 (`2.0.43+243003`).** Pacchetto ZIP: esportazione
   (solo ZIP) e importazione (`.zip` e `.json`) come descritto al §3, Tranche 2.
   Il codice su cui costruire:
   - `CourseMediaStore` (`lib/services/course_media_store.dart`): `referencesOf`,
     `existingFile`, `addBytes` (verifica l'impronta);
   - `CustomCourseTransferService` (`lib/services/custom_course_transfer_service.dart`):
     `buildCourseExport`, `exportCourse`, `exportCourseTo`, `courseFromBytes`
     (validatore unico), `importCourseFromDialog`, `mergeCourseFromDialog`;
   - `course_projects_screen.dart` → `_importCourse`: flusso esistente per il
     corso già presente (Sostituisci/Copia/Fork/Annulla) e per i publisher;
   - `ImageBankService.importBankZip`: esempio di lettura ZIP con `archive`.
   Poi lo ZIP del corso demo accanto al `.json` in `demo_courses/`.
2. **Tranche 3 → Revisione 4 (`2.0.43+243004`).** Publisher con media: togliere
   `CustomCourseTransferService.rejectUnreachablePublisherRecordings` (e
   riscrivere `test/publisher_recorded_audio_test.dart`), copiare i media
   all'installazione e all'aggiornamento di un corso publisher
   (`CourseEditorService.installExternalOfficialUpdate`), `tools/sign_course.dart`
   che produce lo ZIP, un Dummy firmato con media, documentazione finale
   (Help, guida alla firma, `docs/AUDIO_PACKS.md` superato,
   `docs/MEDIA_LIBRARIES_PLAN.md` §7).
3. Per ogni revisione: numero di build, stessa regola della scadenza Beta
   (30 giorni dalla data di rilascio), CHANGELOG, `docs/243_CHANGE_SUMMARY.md`,
   `docs/243_VALIDATION.md`, `AGENTS.md`, README; test mirati; commit. La suite
   completa solo dopo l'approvazione del proprietario.

**Note per chi riprende:**

- I controlli di copertura sono per corso: nessun file è condiviso tra corsi,
  quindi la pulizia legge solo il corso salvato.
- Per mostrare un'immagine di un corso usare `CourseMediaImage`; per le
  registrazioni `RecordedAudioService.resolveSourceForClip(clip, courseId:)`.
- La copertina (`coverImage`) è solo conservata: dimensioni (512×512) e peso
  (100 KB) si controllano all'importazione del pacchetto (Tranche 2).
- Gli script di modifica nella shell Bash di questa macchina falliscono con
  testi lunghi in heredoc: scrivere lo script in un file e poi eseguirlo.

## 1. Decisioni del proprietario (chiuse)

| Tema | Decisione |
|---|---|
| A quali corsi si applica | **Tutti**: publisher e custom. |
| Forma di distribuzione | Un file **`.zip`** con il corso e tutte le immagini e gli MP3 che usa. |
| Esportazione | **Solo ZIP.** Non si esporta più il `.json` singolo. |
| Importazione di `.json` singolo | Resta possibile (un corso senza media propri funziona così). |
| Corso già presente all'import | Resta la finestra attuale: Sostituisci/aggiorna, Copia come nuovo corso, Fork (solo se la licenza permette opere derivate), Annulla, secondo i permessi. Per i publisher resta la finestra di installazione/aggiornamento. |
| Come il corso indica un file | **Formato unico anche sul dispositivo**: un'"impronta" del contenuto (SHA-256), non un percorso. |
| Vecchi percorsi (`C:\…`, `/home/…`) | **Rifiutati** ("taglio netto"). Non ci sono corsi esistenti da convertire: l'app è nuova. |
| Dove stanno i file | **Una cartella per corso.** Cancellare il corso cancella la sua cartella. |
| Immagini arrivate con un corso importato | **Solo nel corso**, non nella Image Library condivisa. |
| Image Library | Resta il catalogo da cui l'autore sceglie; scegliere un'immagine ne **copia** una nel corso. |
| Limite del pacchetto | **300 MB** in tutto. Restano 50 KB per immagine, 50 MB per MP3, 10 MB per il testo del corso. |
| Formato del corso | **Nuovo modello unico v11** per tutti i corsi. v9 e v10 **rifiutati** (taglio netto, nessun codice di conversione nell'app). |
| Contenuto della v11 | Tutto ciò che c'è nella v9; informazioni di fusione (ex v10) **facoltative**; crediti media facoltativi (come nella Build 242); nuova regola sui media (§2); i nuovi campi facoltativi del §2bis. |
| Corsi v9/v10 esistenti | I corsi di prova del proprietario non hanno media esterni: basta cambiare `formatVersion` in `11`, a mano o con il programma di conversione in `tools/`. Lo stesso programma converte i corsi inclusi, il demo e le prove publisher. |

## 2. Come funzionerà, in parole semplici

**Riferimento ai media.** Dentro il corso, un'immagine o una registrazione
dell'autore è scritta così:

```text
media:3fa9…c1.mp3
```

dove `3fa9…c1` è l'impronta SHA-256 del file (64 caratteri esadecimali minuscoli)
e dopo il punto c'è l'estensione. Ogni dispositivo sa che quel file si trova nella
cartella del corso. I media forniti con l'app restano `assets/…` e non cambiano.
I media già incorporati nel corso (icone delle lezioni, bandiera personalizzata,
immagini `data:` di "Riconosci i caratteri") non cambiano: viaggiano già.

**Aggiungere media nell'editor.** Importare un MP3, importare un'immagine o
sceglierne una dalla Image Library copia il file nella cartella del corso con
l'impronta come nome. Se il file c'è già (stessa impronta), non si duplica.

**Esportare.** L'app crea uno ZIP con:

```text
qql-course-package.json   ← piccolo segno di riconoscimento: {"packageFormat": 1}
course.json               ← il corso, identico a quello salvato
media/3fa9…c1.mp3         ← ogni file usato dal corso, una volta sola
media/…
```

Il corso non viene trasformato: è già nel formato giusto.

**Importare.** L'app apre lo ZIP, controlla tutto *prima* di scrivere qualsiasi
cosa, poi installa il corso e copia i media nella sua cartella. Se un controllo
fallisce, non resta nulla di scritto a metà.

**Publisher.** Il corso firmato contiene le impronte. Cambiare anche un solo byte
di un'immagine o di un MP3 nello ZIP fa fallire il controllo dell'impronta: la
firma quindi protegge anche i media, cosa che oggi non avviene. Il rifiuto
introdotto nella Build 242 per i publisher con registrazioni proprie viene tolto,
perché le registrazioni ora arrivano dentro il pacchetto.

## 2bis. Nuovi campi della v11

Tutti **facoltativi**: un corso senza nessuno di questi campi è valido. Quando
sono vuoti non compaiono nel JSON. Valgono per tutti i corsi, publisher e custom.
I nomi JSON sono quelli implementati nella Tranche 0.

| Campo | Nome JSON proposto | Formato | Controlli | Nell'app |
|---|---|---|---|---|
| Versione minima dell'app | `minimumAppBuild` | Numero di build intero, lo stesso di `pubspec.yaml` (es. `243000`) | Intero positivo. Se l'app ha un numero di build più basso, il corso viene **rifiutato** con un messaggio "Aggiorna QuisquisLingo". | Editor e Course Info |
| Contatti dell'editore | `publisherContact` con `websiteUrl` e/o `email` | Testo | Sito solo `https://`; email in forma valida. L'app **mostra** i contatti e non si collega mai da sola. | Editor e Course Info |
| Durata stimata | `estimatedStudyHours` | Ore, intero | Da 1 a 1000 | Editor e Course Info |
| Età minima | `minimumAge` | Uno tra `4`, `9`, `13`, `16`, `18` (classi di App Store: 4+, 9+, 13+, 16+, 18+) | Solo quei valori | Editor e Course Info, mostrata come "4+" ecc. |
| Parole chiave | `keywords` | Elenco di testi | Massimo 20, ciascuna massimo 32 caratteri, spazi iniziali e finali tolti, niente doppioni (senza distinguere maiuscole e minuscole), niente parole vuote | Editor e Course Info. **La ricerca che le usa arriverà dopo.** |
| Copertina | `coverImage` | Riferimento `media:<sha256>.<ext>`, viaggia nello ZIP come le altre immagini | Quadrata **512×512**, PNG, JPEG o WEBP, massimo **100 KB** | **Solo controllata e conservata.** Scelta nell'editor e visualizzazione arriveranno dopo. |

`minimumAppBuild` è la protezione per il futuro: da qui in avanti ogni versione
dell'app lo rispetta, così un corso che usa novità recenti non verrà aperto male
da un'app vecchia. Nuovi campi futuri potranno appoggiarsi a questo meccanismo.

Tutti questi campi sono descrittivi: come licenza e crediti, **non danno mai
permessi** in QQL. Vengono portati da Fork, Copia come nuovo corso e Duplica come
gli altri metadati descrittivi. Nella Fusione il corso risultante prende i valori
del corso di sinistra, tranne `minimumAppBuild` che prende il più alto dei due;
valori diversi non bloccano mai la fusione.

## 3. Lavoro diviso in quattro tranche

Ogni tranche si chiude con test verdi e si può provare da sola.

### Tranche 0 — Modello v11

1. `formatVersion: 11` è l'unico valore accettato. v9 e v10 sono rifiutati con un
   messaggio chiaro. Le informazioni di fusione (`mergeProvenance`) diventano
   facoltative nella v11, con le stesse regole di oggi (solo corsi custom).
2. I nuovi campi del §2bis, con i loro controlli, le caselle nell'editor di
   Course Info e la visualizzazione in Course Info (copertina esclusa).
3. Programma di conversione in `tools/`: legge un `.json` v9 o v10, scrive v11.
   Se trova riferimenti a media fuori da `assets/` si ferma e li elenca: non li
   inventa e non li cancella in silenzio.
4. Con quel programma: rigenerare i 10 corsi inclusi in `assets/courses/`
   (versione ufficiale +1 minore, stessi `courseId` così i progressi restano), il
   corso demo in `demo_courses/`, e i corsi di prova publisher in
   `test/fixtures/publishers/` (v1 firmato, v2 firmato, non firmato),
   ri-firmando quelli firmati con la chiave Dummy. Aggiornare le impronte di
   controllo dei corsi inclusi.
4bis. Nuove cartelle (decisione del proprietario durante la Tranche 0): un solo
   corso v9 rimasto sul dispositivo bloccava l'intero elenco dei corsi e la
   cronologia delle versioni. I corsi vanno in `qql_courses_v2`, le copie di
   sicurezza in `Course Backups v11`; le vecchie cartelle restano intatte e non
   vengono più lette.
5. Aggiornare i test che citano il numero di formato e
   `docs/COURSE_JSON_FORMAT.md`.

La Tranche 0 non tocca ancora i media: la regola `media:` per MP3 e immagini
arriva con la Tranche 1. Il campo `coverImage` accetta già solo la forma
`media:<sha256>.<ext>`; dimensioni e peso si controllano quando il file
esisterà (Tranche 1–2). Lo ZIP del corso demo arriva con la Tranche 2.

### Revisione 1 — Un corso illeggibile non nasconde più gli altri (§3bis)

Scoperto durante la Tranche 0 e scelto dal proprietario come revisione a sé.
Oggi `CourseFileStore.readAll` e `CourseEditorService.listUserCourses` si
fermano al primo file che non riescono a leggere: un solo file rovinato blocca
Course Manager, il selettore dei corsi, l'importazione e il salvataggio, anche
se il commento del codice e il nome del test dicono il contrario.

1. Saltare i file illeggibili (JSON non valido, corso non valido, due file con lo
   stesso Course ID) ed elencare tutti i corsi leggibili.
2. Mostrare un avviso che nomina ogni file saltato e dice che è stato conservato.
3. Non cancellare né sovrascrivere mai un file saltato.
4. Allineare il commento del codice e il test al comportamento reale.

### Tranche 1 — Formato unico sul dispositivo

1. **Regola nel modello.** Per MP3 della Audio Library, immagini degli esercizi
   (`imageAsset`, elementi `image` dei prompt e degli item) sono validi solo:
   vuoto, `assets/…`, `media:<sha256>.<ext>`. Qualsiasi altro valore viene
   rifiutato alla lettura del corso con un messaggio chiaro. Estensioni: `mp3`,
   `png`, `jpg`, `jpeg`, `webp` (quelle già ammesse oggi). Un solo punto nel
   codice definisce e verifica questa forma.
2. **Cartella per corso.** Una cartella per corso sotto la cartella di supporto
   dell'app, per immagini e MP3 insieme, con lo stesso nome di cartella derivato
   dal `courseId` già usato oggi per l'audio
   (`RecordedAudioService.storageDirectoryForCourseId`). Da decidere il nome
   (§5, punto 2).
3. **Un solo "risolutore".** Dato un corso e un riferimento, restituisce il file
   o `assets/…`. Lo usano tutti i punti che oggi guardano `startsWith('assets/')`
   o `File(path)`: studio (`round_screen.dart`), anteprima e editor
   (`course_editor_screen.dart`), riproduzione (`recorded_audio_service.dart`),
   Audio Library, Image Library, Audit, copie di sicurezza, pulizia, Inventario.
4. **Editor.** Import MP3 (cartella fissa e Open from…), import immagine (cartella
   fissa e Open from…) e scelta dalla Image Library scrivono `media:…` e copiano
   il file nella cartella del corso.
5. **Fork, Copia come nuovo corso, Duplica, Fusione.** Il nuovo corso ha un nuovo
   `courseId`, quindi una nuova cartella: i file usati vengono copiati. Per la
   fusione, i media di entrambi i corsi di partenza. Oggi
   `course_merge_service.dart` non si occupa dei media: va verificato e coperto.
6. **Copie di sicurezza.** `CourseBackupService` conserva i file per impronta e
   mantiene i controlli rigorosi attuali (esistenza e SHA-256), compreso il caso
   "file mancante" introdotto nella Build 242.
7. **Pulizia.** Al salvataggio confermato e alla cancellazione del corso si
   cancellano i file della cartella del corso che il corso non usa più
   (`managed_media_cleanup.dart`). Con una cartella per corso non serve più
   controllare gli altri corsi.
8. **Reset e Inventario.** Nuova cartella in `AppResetService`, `InventoryService`
   e `docs/239_RESET_STORAGE_INVENTORY.md`. La vecchia `quisquislingo_audio` viene
   sostituita (§5, punto 2).
9. **Audit.** `MEDIA_ATTRIBUTION_MISSING` riconosce `media:` come media propri.
   Il numero di regole resta 104.

### Tranche 2 — Pacchetto ZIP

1. **Esportazione** (cartella fissa `Exports` e Save to…): solo `.zip`, con la
   struttura del §2. Si include ogni file `media:` usato dal corso. Se un file
   manca sul dispositivo, l'esportazione si ferma e dice quale file e dove è
   usato: meglio che distribuire un corso rotto.
2. **Importazione** (cartella fissa `Imports` e Open from…): accetta `.zip` e
   `.json`. Uno ZIP si riconosce come corso da `qql-course-package.json`; un
   archivio della Image Library resta un'altra cosa e segue la sua strada
   attuale.
3. **Controlli all'import, tutti prima di scrivere:**
   - dimensione totale ≤ 300 MB, anche calcolata sui dati decompressi;
   - solo nomi `course.json`, `qql-course-package.json`, `media/<sha256>.<ext>`:
     niente sottocartelle, niente `..`, niente percorsi assoluti, niente
     collegamenti; ogni altro file viene rifiutato;
   - ogni file media ha l'impronta uguale al proprio nome e rispetta i limiti di
     dimensione e di formato già in vigore;
   - ogni `media:` usato dal corso è presente nello ZIP; i file in più vengono
     ignorati e non copiati;
   - `course.json` passa lo stesso validatore unico di oggi
     (`CustomCourseTransferService.courseFromBytes`), compresa la firma per i
     publisher e l'Audit.
4. **Corso già presente.** La finestra attuale in `course_projects_screen.dart`
   resta com'è; ogni scelta (Sostituisci, Copia, Fork) porta con sé i media.
5. **Fusione (Merge From…)** accetta anche uno ZIP.
6. **Android e iOS:** senza finestra di sistema, si usa la cartella fissa, come
   oggi.

### Tranche 3 — Publisher e documentazione

1. Togliere `rejectUnreachablePublisherRecordings`.
2. Installazione e aggiornamento di un corso publisher copiano i media nella sua
   cartella; all'aggiornamento si tolgono quelli non più usati.
3. `tools/sign_course.dart` produce lo ZIP firmato. Aggiornare
   `docs/PUBLISHER_SIGNING_GUIDE.md`.
4. Aggiornare Help dell'editor (italiano e inglese), `docs/COURSE_JSON_FORMAT.md`,
   `docs/AUDIO_LIBRARY.md`, `docs/FLAT_IMAGE_LIBRARY.md`,
   `docs/MEDIA_LIBRARIES_PLAN.md` §7, `AGENTS.md`. `docs/AUDIO_PACKS.md` va
   segnato come superato: prevedeva download da internet, contrario alla regola
   "funziona senza rete".

## 4. Cosa NON fa questo lavoro

- L'app non converte corsi v9/v10: la conversione avviene solo fuori dall'app,
  con il programma in `tools/`.
- Non introduce la ricerca per parole chiave né la gestione della copertina
  nell'app: la v11 definisce solo i campi.
- Non cambia icone delle lezioni, bandiere o immagini `data:` già incorporate.
- Non cambia la Image Library condivisa né l'importazione degli archivi Image
  Bank, a parte il fatto che scegliere un'immagine ora la copia nel corso.
- Non implementa lo strumento "Rimuovi media inutilizzati"
  (`docs/240_REMOVE_UNUSED_MEDIA_PLAN.md`), né crediti legati al singolo file.
- Non scarica nulla da internet.

## 5. Decisioni ancora aperte

Nessuna. Decise:

1. **Nome della cartella dei media:** `quisquislingo_course_media/<corso>/`, che
   sostituisce `quisquislingo_audio/<corso>/`.
2. **Versioni dell'app:** Build 243 Revisione 0 per la Tranche 0, Revisione 1
   per la correzione dei corsi illeggibili (§3bis), Revisioni 2, 3 e 4 per le
   Tranche 1, 2 e 3, ciascuna con il proprio commit.

## 6. Verifiche

- Test mirati per ogni punto, in particolare:
  - v11 accettata, v9 e v10 rifiutate, fusione facoltativa nella v11;
  - ogni nuovo campo: valori validi, rifiutati, assenti, andata e ritorno nel
    JSON; `minimumAppBuild` superiore alla build dell'app rifiutato;
  - programma di conversione su un corso senza media e su uno con percorsi
    esterni;
  - regola del riferimento (valori validi e rifiutati);
  - risolutore;
  - copia dei media in Fork, Copia e Fusione;
  - copie di sicurezza e ripristino;
  - pulizia;
  - ZIP: andata e ritorno, file alterato, file mancante, nome pericoloso, file in
    più, superamento dei limiti, ZIP che non è un corso;
  - collisione di ID;
  - publisher firmato con media e con un media alterato;
  - reset e Inventario.
- I corsi Dummy firmati, convertiti in v11 e ri-firmati nella Tranche 0, devono
  risultare verificati; una versione alterata dopo la firma deve essere
  rifiutata. Nella Tranche 3 si aggiunge un Dummy firmato con media.
- Alla fine di ogni tranche: `flutter analyze`, suite completa una sola volta, i
  quattro validatori Python, `git diff --check`.
- Prova manuale: esportare un corso con immagini e MP3 su Windows, importarlo su
  Android, studiarlo.
