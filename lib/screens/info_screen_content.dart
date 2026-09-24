import '../services/app_metadata.dart';
import '../services/beta_lifecycle_service.dart';
import '../services/status_service.dart';
import '../widgets/help_language_toggle.dart';

/// One titled block of the App Info page.
typedef InfoSection = ({String title, String body});

/// The App Info text in the requested language.
///
/// The two lists are deliberately kept side by side so a change to one is an
/// obvious prompt to change the other. Names that appear on screen — Course
/// Selector, Profile > Statistics, Save as draft — stay in English inside the
/// Italian text, because the interface itself is English and the reader has to
/// find them there.
List<InfoSection> infoSections(HelpLanguage language) =>
    language == HelpLanguage.italian ? _italian() : _english();

String infoCreditsButtonLabel(HelpLanguage language) =>
    language == HelpLanguage.italian
    ? 'Crediti dell’app e delle immagini'
    : 'App and image credits';

List<InfoSection> _english() => [
  (title: 'Version and Build', body: AppMetadata.displayLabel),
  (
    title: 'Choosing and opening courses',
    body:
        'The learner page Course Selector lists the current course, recently opened courses, bundled courses and local courses. Every row has Course Info and Remove from my courses. Course Library lets you add courses again with preserved progress. Import Course opens directly and returns to study. When Animations are enabled, switching to a different course briefly shows its valid Course JSON flag before revealing the new Learner Panel. If no flag is declared, the same established course-code flag fallback used elsewhere is shown; invalid declared flag data does not receive that fallback. Selecting the current course again, normal startup and disabled Animations enter immediately. Each learner resumes the last Lesson selected in that course, or the first Lesson when no saved selection is valid. The bottom Lesson display control cycles through Expanded, Collapse completed and Focused while the Section selector remains the sole Section-level navigation.',
  ),
  (
    title: 'Course identity and progress',
    body:
        'Every course has an immutable globally unique Course ID. Updates to the same course keep that ID and retain course progress. Importing a course with an existing Course ID lets you replace or update it, create a separate derived copy with a new ID, or cancel. Derived copies may record their parent Course ID and source version. Course completions, Review history, laurels and Language Duel wins are separate per Course ID. Language XP, streaks and study days remain shared by target language, while Week XP remains a total across all courses and languages.',
  ),
  (
    title: 'Progress, Week XP and Gamification',
    body:
        'Language XP, streak, study days and Status are stored separately for each learner and target language. Profile > Statistics shows Total Study Days across languages and, for every studied language, its flag, name, canonical language ID, Study Days, Current Streak and Max Streak. Completed Rounds and laurel crowns are stored separately for each learner and Course ID. Week XP is different: it is the total XP earned by that learner across all courses during the current week. Profile > Gamification contains Weekly XP Target · All courses, Last Week XP · All courses and the Local leaderboard · All courses. Last Week XP refers to the previous completed week; tap your own Last Week XP to see the XP breakdown for each course. The local leaderboard ranks participating learner profiles on this device by their total XP across all courses during that same completed week. Participation can be turned off without deleting the learner’s XP history.',
  ),
  (
    title: 'Streak and the freeze rule',
    body:
        'Your streak increases when you study that language on a new day. If you spend a day studying a different language, this language streak is frozen: it does not increase and it does not reset. A full day with no study in any language breaks active streaks.',
  ),
  (
    title: 'Days studied',
    body:
        'A Study Day is one distinct local calendar day on which the learner completes study. Several Rounds on the same day still count as one Study Day. Total Study Days counts distinct study dates across all languages, so studying two languages on the same day still adds one total day.',
  ),
  (
    title: 'Laurel crowns',
    body:
        'A round earns a laurel crown when you complete one full attempt with zero errors. This can happen from the normal course path or from Review. Once earned, the crown is permanent even if a later attempt contains errors. A newly earned crown also plays the victory sound when sound effects are enabled.',
  ),
  (
    title: 'Audio Settings',
    body:
        'Settings > Audio Settings contains Enable Audio Exercises, Text-to-speech and the existing TTS voice selector with Test Voice, in that order. Enable Audio Exercises and Text-to-speech are stored per learner and initialize Off; TTS voice is also per learner and initializes System. Test Voice opens with an empty field and speaks only the text you enter, using the selected course language for voice resolution. While audio exercises are Off, recorded-MP3, TTS and hybrid exercises are excluded before their source or playback controller is initialized. When On, the Text-to-speech switch controls TTS availability without disabling valid recorded audio. Previous shared and negative audio-setting values remain untouched and unread. Authoring Preview ignores learner Audio Settings and remains no-write. Completing only the available non-audio part of a Round preserves the established leaf-style partial-audio completion behavior rather than awarding a full laurel crown.',
  ),
  (
    title: 'Beta expiry',
    body: BetaLifecycleService.isBetaBuild
        ? 'This is a time-limited beta build. It expires on ${BetaLifecycleService.expiryIsoDate}. After expiry, learner exercises and Review are blocked until a newer beta is installed. Local progress, courses, course edits and settings are not deleted, and Course Editor remains available.'
        : 'This is not a time-limited beta build.',
  ),
  (
    title: 'Status',
    body:
        '${StatusService.progressionExplanation} The levels are Apprentice, Wanderer, Squire, Wordsmith, Knight, Lorekeeper, Language Wizard, Grand Master, Sage and Guru.',
  ),
  (
    title: 'Avatar appearance',
    body:
        'Profile > Avatar Customization contains skin and hair choices. T-shirt color is not a customization preference: it always uses the vivid color assigned to the learner’s current Status for the selected learning language, and changes automatically when Status changes.',
  ),
  (
    title: 'Review',
    body:
        'QuisquisLingo remembers up to 50 distinct recent Rounds for each learner and Course ID. Review prioritizes Rounds where the latest attempt contained more errors. Ties are ordered by recency. Repeating a Round updates its latest error count and can also earn a permanent laurel crown.',
  ),
  (
    title: 'Guidebooks',
    body:
        'Every Lesson has its own GuideBook with explanations and reference material. The GuideBook is the first node on the current Lesson path and opens only when you select it.',
  ),
  (
    title: 'Language Duels',
    body:
        'Each Lesson has its own Duel. A standard Duel uses 25 suitable exercises from that Lesson and starts with 4 lives. Each incorrect answer costs one life. There is no score or separate pass threshold: complete all 25 questions before losing all four lives to win and unlock the next Lesson. If the Lesson does not contain 25 suitable exercises, its Duel is simply unavailable.',
  ),
  (
    title: 'Source and target languages',
    body:
        'The target language is the language you are learning. The source language is used for explanations and translations. Most sample courses use English as source; the English sample course uses Spanish as source.',
  ),
  (
    title: 'Export and import learner data',
    body:
        'Profile > User Data > Export my data creates a backup of the active learner profile, including learner-specific progress and preferences. It is saved directly in Documents/QuisquisLingo/Exports with an automatic filename; there is no Save As dialog. If that filename already exists, QuisquisLingo adds _2, _3 and later numeric suffixes. To import learner data, copy a supported backup to Documents/QuisquisLingo/Imports/learner_import.json and then choose Profile > User Data > Import my data. Course Editor projects, Image Bank packages and Audio Packs are separate authoring resources and are not part of this learner backup.',
  ),
  (
    title: 'Updates',
    body:
        'At the bottom of Settings, Version and Build are shown immediately before Update. Settings > Update displays the published QuisquisLingo source repository https://github.com/Quisquisnaut/QuisquisLingo, lets you check the latest packaged GitHub Release manually, and can optionally check automatically at startup. If no packaged GitHub Release exists, the page distinguishes that from the published source repository. Automatic checks are on by default. Update checks send no learner data or course data and never download or install software. If a newer release exists, the page shows release information and installation guidance in the fixed order Windows, macOS, Linux, Android, iOS and Web, marking platforms that have no matching published release asset as not currently available.',
  ),
  (
    title: 'Crash Log and Diagnostic Log',
    body:
        'Settings > Debug contains both logging tools and concise reporting guidance. Use the Crash Log for startup/runtime crashes or unexpected closes. For non-crashing runtime problems, reproduce the issue when possible and export the Diagnostic Log shortly afterward; clearing it first is optional and is useful only to isolate a specific reproducible problem, while intermittent evidence should be exported before clearing. Both files use Documents/QuisquisLingo/Logs. Learner audio diagnostics use short correlation IDs and bounded lifecycles with preparation, learner UI state, stable exercise ID/type, activation trigger, suppression, source, backend, playback, failure and disposal status. They are designed to avoid spoken text, answers, course content and full personal file paths.',
  ),
  (
    title: 'Course Studio and Course Editor',
    body:
        'Course Studio is opened from the learner Course Selector rather than Settings. It is the lifecycle hub: official courses provide read-only inspection, licensed Fork, Audit and supported Export; custom courses provide Edit, Copy as New Course, Merge, Audit, Export and Delete. Fork preserves the source lineage; Copy as New Course starts an independent Course lineage. Open Course Studio Help for library operations, and Editor Help from any Course Editor hierarchy page for authoring instructions.',
  ),
  (
    title: 'Course content and AI',
    body:
        'The bundled courses titled AI-Slop Demo are AI-generated, unreviewed demonstrations and are not reliable learning courses. Real QuisquisLingo course content is intended to be authored and reviewed by humans. This classification does not apply to other official or custom courses.',
  ),
];

List<InfoSection> _italian() => [
  (title: 'Versione e build', body: AppMetadata.displayLabel),
  (
    title: 'Scegliere e aprire i corsi',
    body:
        'Il Course Selector, nella pagina di studio, elenca il corso attuale, quelli aperti di recente, quelli inclusi nell’app e quelli locali. Ogni riga offre Course Info e Remove from my courses. Course Library permette di aggiungere nuovamente i corsi con i progressi conservati. Import Course apre direttamente la pagina di importazione e torna allo studio. Se le animazioni sono attive, quando passi a un altro corso vedi per un attimo la bandiera dichiarata nel suo Course JSON, poi si apre il nuovo Learner Panel. Se il corso non dichiara nessuna bandiera, si usa quella ricavata dal codice della lingua, come altrove nell’app; se invece i dati della bandiera dichiarata non sono validi, quel ripiego non viene applicato. Se riselezioni il corso già attivo, o all’avvio normale, o con le animazioni disattivate, si entra subito. Ogni studente riprende dall’ultima Lesson aperta in quel corso, o dalla prima se non c’è una scelta valida salvata. Il comando in basso per la visualizzazione delle Lesson alterna Expanded, Collapse completed e Focused; per spostarti tra le Section c’è solo il Section selector.',
  ),
  (
    title: 'Identità del corso e progressi',
    body:
        'Ogni corso ha un Course ID unico che non cambia mai. Se aggiorni lo stesso corso, l’ID resta quello e i progressi restano al loro posto. Se importi un corso con un Course ID già presente, puoi sostituirlo o aggiornarlo, crearne una copia separata con un ID nuovo, oppure annullare. Le copie derivate possono conservare il Course ID di origine e la versione di partenza. Round completati, cronologia di Review, allori e vittorie nei Language Duel sono contati separatamente per ogni Course ID. XP della lingua, streak e giorni di studio restano invece condivisi per lingua studiata, e i Week XP restano un totale su tutti i corsi e tutte le lingue.',
  ),
  (
    title: 'Progressi, Week XP e Gamification',
    body:
        'XP della lingua, streak, giorni di studio e Status sono salvati separatamente per ogni studente e per ogni lingua studiata. In Profile > Statistics trovi i Total Study Days su tutte le lingue e, per ogni lingua studiata, la bandiera, il nome, l’identificativo ufficiale della lingua, gli Study Days, il Current Streak e il Max Streak. I Round completati e le corone d’alloro sono salvati separatamente per ogni studente e per ogni Course ID. I Week XP funzionano diversamente: sono il totale degli XP guadagnati da quello studente in tutti i corsi nella settimana in corso. In Profile > Gamification ci sono Weekly XP Target · All courses, Last Week XP · All courses e Local leaderboard · All courses. Last Week XP si riferisce all’ultima settimana conclusa; tocca il tuo Last Week XP per vedere quanti XP vengono da ciascun corso. La classifica locale mette in ordine i profili di questo dispositivo che partecipano, in base al totale di XP su tutti i corsi nella stessa settimana conclusa. Puoi smettere di partecipare senza perdere lo storico degli XP.',
  ),
  (
    title: 'Streak e regola del congelamento',
    body:
        'Lo streak di una lingua cresce quando studi quella lingua in un giorno nuovo. Se passi una giornata a studiare un’altra lingua, lo streak di questa lingua si congela: non sale, ma non si azzera. Se invece passa un giorno intero senza studiare nessuna lingua, gli streak attivi si interrompono.',
  ),
  (
    title: 'Giorni di studio',
    body:
        'Uno Study Day è un singolo giorno di calendario, secondo l’ora locale, in cui hai studiato. Più Round nello stesso giorno contano comunque come un solo Study Day. I Total Study Days contano i giorni diversi in cui hai studiato, su tutte le lingue: se in un giorno studi due lingue, il totale aumenta comunque di uno.',
  ),
  (
    title: 'Corone d’alloro',
    body:
        'Un Round ti fa guadagnare una corona d’alloro quando lo completi per intero senza nessun errore. Può succedere sia nel percorso normale del corso sia da Review. Una volta ottenuta, la corona resta per sempre, anche se in un tentativo successivo sbagli qualcosa. Quando ne guadagni una nuova senti anche il suono della vittoria, se gli effetti sonori sono attivi.',
  ),
  (
    title: 'Audio Settings',
    body:
        'In Settings > Audio Settings trovi, in quest’ordine, Enable Audio Exercises, Text-to-speech e il selettore della voce TTS con Test Voice. Enable Audio Exercises e Text-to-speech valgono per ogni studente separatamente e partono da Off; anche la voce TTS è per studente e parte da System. Test Voice si apre con il campo vuoto e legge solo il testo che scrivi tu, usando la lingua del corso selezionato per scegliere la voce. Se gli esercizi audio sono Off, gli esercizi con MP3 registrato, con TTS o misti vengono esclusi prima ancora di preparare la sorgente o il controller di riproduzione. Se sono On, l’interruttore Text-to-speech decide se il TTS è disponibile, senza disattivare gli audio registrati validi. I vecchi valori condivisi o negativi di queste impostazioni restano dove sono e non vengono letti. La Preview dell’Editor ignora le Audio Settings dello studente e non scrive nulla. Se completi solo la parte non audio di un Round, vale il comportamento già previsto per il completamento parziale: non ottieni la corona d’alloro piena.',
  ),
  (
    title: 'Scadenza della beta',
    body: BetaLifecycleService.isBetaBuild
        ? 'Questa è una beta a tempo. Scade il ${BetaLifecycleService.expiryIsoDate}. Dopo quella data gli esercizi e Review restano bloccati finché non installi una beta più recente. Progressi, corsi, modifiche ai corsi e impostazioni non vengono cancellati, e il Course Editor resta utilizzabile.'
        : 'Questa non è una beta a tempo.',
  ),
  (
    title: 'Status',
    body:
        'Lo Status è calcolato separatamente per ogni studente e per ogni lingua studiata. I punti Status sono i tuoi XP più 40 punti per ogni giorno di streak in corso, 25 per ogni giorno di studio, 15 per ogni Round completato e 20 per ogni alloro. Il tuo Status attuale è la soglia più alta che il totale ha raggiunto. Ogni Status ha un colore acceso che diventa automaticamente il colore della maglietta del tuo avatar. I livelli sono Apprentice, Wanderer, Squire, Wordsmith, Knight, Lorekeeper, Language Wizard, Grand Master, Sage e Guru.',
  ),
  (
    title: 'Aspetto dell’avatar',
    body:
        'In Profile > Avatar Customization scegli pelle e capelli. Il colore della maglietta non si sceglie: è sempre il colore acceso dello Status che hai in quel momento nella lingua selezionata, e cambia da solo quando cambia lo Status.',
  ),
  (
    title: 'Review',
    body:
        'QuisquisLingo ricorda fino a 50 Round recenti diversi per ogni studente e per ogni Course ID. Review propone per primi i Round in cui l’ultimo tentativo aveva più errori. A parità di errori vengono prima i più vecchi. Se rifai un Round, il conteggio degli errori si aggiorna e puoi anche guadagnare una corona d’alloro permanente.',
  ),
  (
    title: 'GuideBook',
    body:
        'Ogni Lesson ha il suo GuideBook, con spiegazioni e materiale di consultazione. Il GuideBook è il primo elemento del percorso della Lesson e si apre solo se lo selezioni.',
  ),
  (
    title: 'Language Duel',
    body:
        'Ogni Lesson ha il suo Duel. Un Duel normale usa 25 esercizi adatti presi da quella Lesson e parte con 4 vite. Ogni risposta sbagliata costa una vita. Non c’è un punteggio né una soglia di promozione: per vincere e sbloccare la Lesson successiva devi arrivare in fondo a tutte e 25 le domande prima di perdere le quattro vite. Se la Lesson non contiene 25 esercizi adatti, il suo Duel semplicemente non è disponibile.',
  ),
  (
    title: 'Lingua di partenza e lingua studiata',
    body:
        'La lingua studiata è quella che stai imparando. La lingua di partenza è quella usata per spiegazioni e traduzioni. Quasi tutti i corsi di esempio partono dall’inglese; il corso di esempio di inglese parte dallo spagnolo.',
  ),
  (
    title: 'Esportare e importare i tuoi dati',
    body:
        'Profile > User Data > Export my data crea una copia del profilo attivo, con i progressi e le preferenze di quello studente. Il file viene salvato direttamente in Documents/QuisquisLingo/Exports con un nome automatico: non c’è una finestra Salva con nome. Se quel nome esiste già, QuisquisLingo aggiunge _2, _3 e così via. Per importare, copia una copia compatibile in Documents/QuisquisLingo/Imports/learner_import.json e poi scegli Profile > User Data > Import my data. I progetti del Course Editor, i pacchetti Image Bank e gli Audio Pack sono materiale di authoring a parte e non rientrano in questa copia.',
  ),
  (
    title: 'Aggiornamenti',
    body:
        'In fondo a Settings, Version e Build compaiono subito prima di Update. Settings > Update mostra il repository pubblico del codice sorgente di QuisquisLingo, https://github.com/Quisquisnaut/QuisquisLingo, ti permette di controllare a mano l’ultima GitHub Release pacchettizzata e, se vuoi, può controllare da solo all’avvio. Se non esiste nessuna GitHub Release pacchettizzata, la pagina lo distingue chiaramente dal repository del codice. Il controllo automatico è attivo per impostazione predefinita. I controlli non inviano dati dello studente né dei corsi, e non scaricano né installano niente. Se esiste una versione più recente, la pagina mostra le informazioni sulla release e le istruzioni di installazione sempre nello stesso ordine — Windows, macOS, Linux, Android, iOS e Web — segnalando come non disponibili le piattaforme per cui non è stato pubblicato un file corrispondente.',
  ),
  (
    title: 'Crash Log e Diagnostic Log',
    body:
        'In Settings > Debug trovi sia gli strumenti di log sia una guida breve su come segnalare i problemi. Usa il Crash Log per i crash all’avvio o durante l’uso e per le chiusure inattese. Per i problemi che non fanno chiudere l’app, riproduci il problema quando puoi ed esporta il Diagnostic Log subito dopo; svuotarlo prima è facoltativo e serve solo a isolare un problema ben riproducibile, mentre se il problema è intermittente conviene esportare prima di svuotare. Entrambi i file stanno in Documents/QuisquisLingo/Logs. La diagnostica audio usa codici di correlazione brevi e cicli di vita delimitati, con preparazione, stato dell’interfaccia, ID e tipo stabile dell’esercizio, motivo di attivazione, soppressione, sorgente, backend, riproduzione, errore e chiusura. È pensata per non registrare il testo letto, le risposte, i contenuti dei corsi e i percorsi completi dei tuoi file.',
  ),
  (
    title: 'Course Studio e Course Editor',
    body:
        'Il Course Studio si apre dal Course Selector della pagina di studio, non da Settings. È il punto da cui si gestisce tutto il ciclo di vita dei corsi: quelli ufficiali permettono la consultazione in sola lettura, il Fork su licenza, l’Audit e l’Export supportato; quelli personalizzati permettono Edit, Copy as New Course, Merge, Audit, Export e Delete. Il Fork mantiene la discendenza dal corso di origine; Copy as New Course fa partire una discendenza indipendente. Per le operazioni della libreria apri Course Studio Help (Guida al Course Studio); per creare e modificare i corsi apri Editor Help da una pagina del Course Editor.',
  ),
  (
    title: 'Contenuti dei corsi e IA',
    body:
        'I corsi inclusi nell’app che si chiamano AI-Slop Demo sono dimostrazioni generate dall’IA e non revisionate: non sono corsi affidabili per studiare. I veri contenuti di QuisquisLingo sono pensati per essere scritti e revisionati da persone. Questa classificazione non riguarda gli altri corsi, ufficiali o personalizzati.',
  ),
];
