# Verifica delle firme dei corsi — specifica proposta

Stato: implementazione autorizzata dal proprietario in conversazione e sviluppata nella working tree; validazione finale completa ancora in attesa di OK.

## Obiettivo e vincoli già concordati

QQL deve accettare un nuovo corso externalOfficial soltanto dopo aver verificato una firma Ed25519 mediante una chiave approvata dell’editore. Il nome dichiarato, il checksum e publisherVerificationStatus nel JSON non costituiscono prove di autenticità. Gli editori conservano le proprie chiavi private; il proprietario di QQL approva le chiavi pubbliche. Il registro iniziale viene distribuito con l’app e funziona offline.

Aggiungere l’editore Dummy e corsi campione per verifiche positive e negative. La chiave Dummy non deve essere attendibile nelle release normali. Conservare corsi, backup e progressi esistenti; nessuna conversione automatica in custom. Mantenere Course Model v9/v10 e la Build 241 Revision 1 ancora in preparazione. La validazione finale completa resta subordinata all’OK già richiesto dal proprietario.

## Risultati dell’ispezione

- CustomCourseTransferService.courseFromBytes è il validatore comune a importazione da cartella e dialogo nativo; attualmente non autentica il publisher.
- CourseEditorService.installExternalOfficialUpdate controlla il checksum e imposta unverified anche se il file dichiara verified. È il punto di persistenza da proteggere anche contro chiamate dirette.
- CourseEditorService.listUserCourses e officialSourceFor leggono gli originali dal file store. Devono derivare lo stato dalla verifica corrente, senza fidarsi dello stato persistito.
- CourseProjectsScreen permette esplicitamente Install as unverified: quel percorso va sostituito.
- CourseBackupService possiede già la canonicalizzazione ordinata usata da officialContentChecksum; esclude officialChecksum, publisherSignature e publisherVerificationStatus.
- CourseService controlla separatamente gli asset bundled: questa fonte di fiducia resta distinta.
- Course Info e la cronologia mostrano lo stato memorizzato. Devono mostrare l’esito effettivo della verifica.

## Approccio scelto e alternative

Raccomandazione: servizio di verifica locale in Dart, registro immutabile incorporato e firma del digest del payload QQL canonico. Riutilizza il checksum già definito, aggiungendo autenticazione e un prefisso che distingue inequivocabilmente le firme dei corsi dalle prove di possesso della chiave.

Un eseguibile OpenSSL invocato dall’app creerebbe dipendenze esterne e differenze fra piattaforme. Un servizio online di verifica introdurrebbe disponibilità di rete e gestione server non richieste. OpenSSL rimane utile per preparazione delle chiavi e verifica indipendente dei campioni.

Usare Ed25519 della libreria cryptography, fissando la versione risolta nel lockfile. Il pacchetto fornisce un’implementazione Dart; niente implementazione manuale dell’algoritmo. Verificare compatibilità con l’SDK e licenza prima di aggiungerlo.

## Protocollo qql-ed25519-v1

Il campo publisherSignature esistente rimane una stringa:

    qql-ed25519-v1:<keyId>:<signatureBase64>

keyId è un identificatore ASCII non vuoto, limitato a lettere, cifre, punto, trattino e underscore, massimo 64 caratteri. La firma è di 64 byte, codificata in Base64 standard canonico. Rifiutare protocolli sconosciuti, componenti aggiuntive, lunghezze errate, codifica non canonica e valori malformati.

I byte firmati sono UTF-8, senza BOM, di questo testo con newline LF finale:

    QQL-COURSE-SIGNATURE-V1
    <publisherId>
    <keyId>
    <officialChecksum>

publisherId non può contenere CR/LF e deve corrispondere esattamente a una voce del registro. officialChecksum è SHA-256 esadecimale minuscolo, ricalcolato dal Course valido. La canonicalizzazione è quella attuale: Course.fromJson, quindi toJson, esclusione dei tre campi sopra indicati, ordinamento ricorsivo delle chiavi, ordine degli array invariato, JSON compatto e UTF-8. Non chiamarla RFC 8785/JCS: è il protocollo QQL sul modello normalizzato. I campi sconosciuti scartati dal modello non fanno parte del payload e non possono influenzare l’esecuzione. Aggiunte future al modello normalizzato richiedono una verifica esplicita di compatibilità del protocollo.

Estrarre la funzione pura del checksum in un modulo condiviso, conservando l’API di CourseBackupService e verificando digest identici sugli asset bundled. Il piccolo strumento di preparazione/signing deve usare questo stesso modello: non richiedere a un editore di replicare a mano la canonicalizzazione in Python o OpenSSL.

La firma copre il contenuto JSON normalizzato, inclusi identità, versione, licenza, provenienza e dati incorporati. Per media esterni autentica il riferimento contenuto nel JSON, non i byte del file/URL esterno. Help e UI non devono dichiarare quei media verificati. Un manifest di digest per allegati è un’estensione successiva, non inclusa in questa tranche.

## Registro e significato dell’approvazione

Ogni voce contiene publisherId, nome approvato, keyId, chiave pubblica Ed25519 di 32 byte e stato attivo/revocato. La chiave fornita dal corso non viene mai aggiunta automaticamente al registro. Il nome attendibile visualizzato deriva dal registro; verificare la coerenza con il nome firmato per evitare identità UI ambigue.

Un editore approvato può firmare nuovi corsi. Per aggiornare un corso già installato deve corrispondere il publisherId originario, oltre all’identità/provenienza e alla versione strettamente superiore. Rimangono i divieti di collisione con asset bundled o corsi custom. Questo autentica chi distribuisce il corso: non attesta l’esclusività mondiale di un courseId né la proprietà dei diritti.

Le chiavi ruotate rimangono distinte tramite keyId. Solo una modifica esplicita del registro può autorizzare una nuova chiave o revocarne una. Una chiave revocata non consente nuovi import né lo stato verificato alla rilettura. Non usare la data di rilascio dichiarata dal file come prova che una firma preceda la revoca.

Il registro di produzione iniziale non contiene editori esterni inventati. L’approvazione reale verrà aggiunta quando il proprietario disporrà della chiave pubblica verificata dell’editore. Gli asset bundled non dipendono da questo registro.

## Flusso, errori e conservazione dei dati

1. Parsing e controlli strutturali attuali.
2. Per externalOfficial: checksum, formato firma, lookup della chiave attiva, corrispondenza publisher e verifica crittografica.
3. Solo dopo verifica riuscita: dialogo con editore riconosciuto, versione e conferma di installazione.
4. Ripetere il controllo al confine di persistenza, prima di qualunque backup/scrittura. Non introdurre un parametro skipVerification.
5. Applicare i vincoli attuali su collisioni, versione e provenienza, quindi salvare e notificare il cambiamento. Cancellazione del dialogo o errore lascia file/progressi invariati.

I nuovi import ufficiali senza firma, alterati, con editore sconosciuto, chiave revocata o protocollo non supportato vengono bloccati con una spiegazione specifica. La casella verified presente nel file non modifica il risultato. L’import esterno di bundledOfficial rimane vietato. I custom validi e non firmati continuano a funzionare.

Alla rilettura, gli externalOfficial esistenti non verificabili rimangono sul disco e nel Course Manager con Verification required, senza etichetta di editore verificato. Non vengono offerti come corsi ufficiali utilizzabili nel percorso di apprendimento finché non sono riattivati. Non cancellare o azzerare i progressi; non far fallire l’intera lista per una sola firma non valida. Errori strutturali del file restano distinti dagli errori di autenticazione.

Per riattivare un corso preesistente non firmato, mostrare una conferma esplicita che colleghi courseId, publisher e versione vecchi/nuovi; il servizio deve richiedere questa scelta esplicita e la firma valida. Nessuna associazione automatica basata sul solo titolo. Applicare la stessa protezione alle vie di accesso diretto e alla cronologia; un backup storico non diventa verificato per il solo checksum e non aggira la verifica quando reimportato.

## Editore Dummy e strumenti di prova

Identità proposta: org.quisquislingo.test.dummy; nome Dummy Publisher — TEST ONLY; chiave dummy-1. La chiave privata è un fixture dichiaratamente pubblico, utilizzabile esclusivamente nei test; non è un segreto reale e non va mai associata a un editore di produzione.

I test automatici iniettano un registro contenente Dummy. La costruzione predefinita di produzione non lo contiene. Per prove manuali, proposta opzionale: build di collaudo con flag esplicito QQL_ENABLE_DUMMY_PUBLISHER=true, anche in modalità release. Il proprietario ha chiarito questa distinzione: le release pubbliche devono omettere il flag. Mostrare chiaramente TEST ONLY nelle build abilitate. Non includere la chiave privata fra gli asset dell’app.

Creare un corso minimo Dummy valido, la versione successiva e varianti con testo alterato, firma assente e chiave sconosciuta. Il campione firmato deve avere una verifica indipendente con OpenSSL per evitare che signer e verifier condividano lo stesso errore.

Fornire un piccolo comando developer che prepara i byte da firmare e incorpora la firma nel JSON finale, usando OpenSSL con prompt per la chiave PEM protetta. Non aggiungere in questa tranche gestione delle chiavi nell’app o un portale editori. Non mettere password nella riga di comando. Documentare i comandi effettivamente implementati e il comportamento di release.

L’uso manuale del Dummy è stato chiesto al proprietario come preferenza opzionale; se non arriva una risposta, la proposta include entrambe le modalità con esclusione dalle release.

## Verifiche necessarie

- Vettore Ed25519 indipendente e fixture OpenSSL: firma valida accettata.
- Payload cambiato con checksum ricalcolato: rifiutato comunque dalla firma.
- Publisher/keyId sostituiti, protocollo ignoto, Base64 errata, firma troncata e chiave revocata: rifiutati.
- verified dichiarato nel JSON senza firma: rifiutato.
- Modifiche a ordine delle chiavi/spaziatura non cambiano la verifica; mutazioni dei campi effettivi sì.
- Import da cartella, dialogo e chiamata diretta al servizio condividono la protezione.
- Aggiornamento firmato più recente accettato; downgrade/cambio publisher/collisioni rifiutati; nessuna scrittura su rifiuto.
- Corsi legacy preservati e segnalati; riattivazione richiede conferma e conserva i progressi.
- Rilettura di file alterato o chiave revocata non restituisce verified.
- Dummy assente dalla configurazione normale e presente solo nella configurazione di collaudo esplicitamente abilitata, anche quando compilata in release.
- Custom, asset bundled, fork, backup, export e media esistenti mantengono i contratti documentati.
- Widget test aspettano il risultato della verifica/salvataggio o uno stato UI preciso; niente timeout aumentati indiscriminatamente né pumpAndSettle generalizzato.

Aggiornare guida operativa, Help, changelog e documento di validazione con lo stato realmente implementato. Eseguire test mirati e analisi dei file toccati durante lo sviluppo. L’analisi completa, la suite completa e la validazione finale attendono l’OK già concordato.

## Fonti tecniche

- Ed25519 nella libreria cryptography: https://pub.dev/documentation/cryptography/latest/cryptography/Ed25519-class.html
- Repository e implementazioni Dart: https://github.com/dint-dev/cryptography
- OpenSSL pkeyutl: https://docs.openssl.org/3.0/man1/openssl-pkeyutl/

## Prossimo passaggio

Implementazione autorizzata successivamente dal proprietario. Nessuna approvazione di editore reale né generazione di chiavi di produzione. I risultati dei controlli mirati sono registrati in docs/241_VALIDATION.md; la validazione finale resta in attesa di OK.
