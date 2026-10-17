# Localization: current state

12 October 2026, Build 271 Revision 5 (`2.0.71+271005`); brought up to date on 13 October 2026 for Build 272 Revision 17 (`2.0.72+272017`): the Welcome Wizard's second step, and the start page (section 6.10); on 16 October 2026 for Build 274 Revision 3 (`2.0.74+274003`): Listen and pick the missing word (its title, heading and two lines, the answers' Sound N, its Help); for Build 275 Revision 0 (`2.0.75+275000`): the Course kind's Help question and Course Info's same-language line; and on 17 October 2026 for Build 275 Revision 1 (`2.0.75+275001`): what learners read in a Course in the same language (the two tables "A Course in the same language"), and for Revision 3 (`2.0.75+275003`): four of those lines made neutral (a word, a phrase or a sentence).

This document says what QuisquisLingo shows in which language today, and lists the texts that are translated. The tables are generated from the catalogs in `lib/localization/` as they are in this revision.

## 1. The decision

Owner decisions of 12 October 2026, after seeing how the labels were shown in an Italian Course (some translated, some not, the same Lesson named "Lesson 2" on the learner path and "Lezione 2" in a Round):

1. **The app interface is in English.**
2. **The names of the main items of a Course are in English everywhere, as proper names**: Lesson, Round and the Round types, Story, Sequence, Duel (Language Duel, Final Duel), GuideBook, Review. This holds inside a translated sentence too: an Italian learner reads "Termina il Round", "Apri il GuideBook", "Prossima Review".
3. **A label an author chooses is shown as the author wrote it** (Lesson label and numbering, Round label and numbering). It is never translated.
4. **Two groups of texts are in the learner's language**: the exercise titles and instructions with the buttons and messages around an exercise (7 languages), and Help, the FAQ, App Info and Course Info (3 languages).
5. **Localization proper is a future project.** Until then no further text is translated and no language is added.

One page was added to the second group after these decisions: the start page of Build 272 Revision 17, which a learner without a Course sees. It explains how to import or create a Course, as the Welcome Wizard shown just before it does, so it was written in the three Help languages with its button names in English. Whether it stays translated is the owner's to confirm; English alone would be a one-line change.

## 2. What is in which language

| What | Languages | It follows | Where the texts are |
|---|---|---|---|
| The app interface: Home, Settings, Profile, Courses, Course Studio, the Course Editor, the wizards, dialogs, menus, error messages | English | Nothing: always English | In the screens |
| The names of a Course's items (section 3) | English | Nothing: always English | In the screens and inside the catalogs |
| Labels the author chooses for Lessons and Rounds | As the author wrote them | The Course | The Course file |
| Exercise titles, headings and instruction lines (137 texts) | English, Spanish, Italian, German, Portuguese, Dutch, French | The Course's Source language | `lib/localization/exercise_copy/` |
| The buttons and messages of a Round, the Duel and the Review page (135 texts) | The same seven | The Course's Source language | `lib/localization/learner_panel/` |
| Names of languages inside those lines, such as "Traduci in tedesco." (62 languages) | The same seven | The Course's Source language | `lib/localization/language_names.dart` |
| Help pages, the Editor Help questions and answers, the Help of each exercise type and of each form field, App Info, Course Info, the technical reference (836 texts) | English, Italian, Spanish | Each learner's Help Language | `lib/localization/help/` |
| The Welcome Wizard (15 texts) | English, Italian, Spanish | The language chosen in Create Profile (the Help Language) | `lib/localization/welcome_text.dart` |
| The start page, shown while a learner has no Course to study (27 texts) | English, Italian, Spanish | The Help Language | `lib/localization/start_page_text.dart` |
| The content of a Course | Whatever its author wrote | The Course | The Course file |

How the two choices work:

- **The Course's Source language** is the language the Course's learners read. When it is one of the seven, the texts around an exercise are in it; otherwise they are in English. A text that a language lacks is shown in English. The learner does not choose this language: it comes with the Course.
- **The Help Language** is each learner's own choice, made in Create Profile and changed in Settings › QQL Guide. It starts from the system language when that is English, Italian or Spanish.

The translations into Spanish, Italian, German, Portuguese, Dutch and French of the texts around an exercise were written by an AI and have not been reviewed by native speakers.

## 3. The names that stay in English

- **Lesson** (or the label its author chose in its place: any word, a number alone, or nothing).
- **Round**, and the Round types: Discover, Practice, Sequence, Listen, Read, Story, FlashCard, Test, Timed, Speak.
- **Story** and **Sequence** (also as the kind of Round being played: "Finish story", "Sequence completed").
- **Duel**, **Language Duel**, **Final Duel**.
- **GuideBook**.
- **Review** (the Review page).

In a translated sentence the name keeps its English form and its capital, and takes the article of the language around it. The same texts in the seven languages:

| Key | English | Italian | Spanish | German | Portuguese | Dutch | French |
|---|---|---|---|---|---|---|---|
| `finish.round` | Finish round | Termina il Round | Terminar el Round | Round beenden | Terminar o Round | Round afronden | Terminer le Round |
| `finish.story` | Finish story | Termina la Story | Terminar la Story | Story beenden | Terminar a Story | Story afronden | Terminer la Story |
| `finish.sequence` | Finish sequence | Termina la Sequence | Terminar la Sequence | Sequence beenden | Terminar a Sequence | Sequence afronden | Terminer la Sequence |
| `summary.lessonCompleted` | Lesson completed: +{xp} XP | Lesson completata: +{xp} XP | Lesson completada: +{xp} XP | Lesson abgeschlossen: +{xp} XP | Lesson concluída: +{xp} XP | Lesson voltooid: +{xp} XP | Lesson terminée : +{xp} XP |
| `duel.won` | Duel won | Duel vinto | Duel ganado | Duel gewonnen | Duel ganho | Duel gewonnen | Duel gagné |
| `openGuidebook` | Open Guidebook | Apri il GuideBook | Abrir el GuideBook | GuideBook öffnen | Abrir o GuideBook | GuideBook openen | Ouvrir le GuideBook |
| `review.next` | Next Review | Prossima Review | Siguiente Review | Nächstes Review | Próxima Review | Volgende Review | Review suivante |

Help already followed this rule before this revision ("il Round", "la Lesson", "el GuideBook"). Revision 5 corrected the few places where it did not.

What changed in Revision 5:

- In the six translated catalogs every text that names one of these items now writes the English name.
- A Round's top line names its Lesson exactly as the learner path does. Before, a Lesson with the default label was "Lezione 2" there and "Lesson 2" on the path.
- The catalogs no longer hold a Lesson label or a Round label (`lessonLine`, `review.lesson`, `review.round` are removed).

## 4. Still translated, on purpose

These were left as they are. They are for the future project to decide.

**"Course" as an ordinary word.** It was not in the list of names, and the catalogs write it as a common noun:

| Key | English | Italian |
|---|---|---|
| `seeCourseAnswer` | See the course answer. | Vedi la risposta del corso. |
| `duel.backToCourse` | Back to course | Torna al corso |
| `review.backToCourse` | Back to Course | Torna al corso |
| `review.noRounds` | There are no Rounds available for Review in this course. | In questo corso non ci sono Round per la Review. |
| `wordLookup.note` | One possible translation from this Course's GuideBook. | Una delle traduzioni possibili, dal GuideBook del Corso. |
| `wordLookup.notes` | Some possible translations from this Course's GuideBook. | Alcune delle traduzioni possibili, dal GuideBook del Corso. |
| `wordLookup.notice` | Tap a word with a dotted underline to see a translation from this Course's GuideBook. Only some exercise types have them. It is a hint, one possible translation: it does not always match the answer to the exercise. | Tocca una parola sottolineata a puntini per vederne una traduzione dal GuideBook del Corso. Solo alcuni tipi di esercizio le hanno. È un aiuto, una delle traduzioni possibili: non sempre coincide con la soluzione dell'esercizio. |

**A Round's own repetition of the exercises missed.** At the end of a Round QQL asks again the exercises answered wrongly. English calls this "review" too, but it is not the Review page, and the verb "to review" is an ordinary word:

| Key | English | Italian |
|---|---|---|
| `roundInReview` | {round} · Review | {round} · Ripasso |
| `reviewingMissed` | Reviewing exercises you missed | Ripasso degli esercizi sbagliati |
| `reviewMistakes` | Review mistakes | Rivedi gli errori |
| `reviewAgain` | Review again | Ripeti più tardi |
| `cardReviewed` | Card reviewed. | Scheda ripassata. |
| `reviewTheFlashcard` | Review the flashcard. | Ripassa la scheda. |

**The Laurel.** It is translated in the texts around an exercise, while the Welcome Wizard writes it in English ("Lesson, Round, Laurel"):

| Key | English | Italian |
|---|---|---|
| `summary.firstLaurel` | First Laurel: +{xp} XP | Primo alloro: +{xp} XP |

**The English texts themselves** keep their earlier spelling, with a small letter where the name is part of a sentence: "Finish round", "Open Guidebook", "Duel won". Only the six translations were changed.

## 5. In English only

- Everything of the app interface outside the two groups of section 2: Home, the learner path (Completed, Perfect, the Lesson selector), Settings, Profile, Statistics, Audio Settings, Courses, Course Studio, the Course Editor and its forms, the Course Wizard, the Round Wizard, the Story and Module wizards, Advanced (Admin), the Inventory, Debug, the Flag Game.
- Around an exercise: error messages, the audio set-up messages, messages about app versions, the results of a Preview or of View Only, Report a problem, Reset Word List and the Review page's Help.
- The Audit and its messages, and the Audit Codes reference.
- The one-time notices of the Course Editor (for instance the popup that introduces each exercise primitive).
- In translated Help, the names of commands, buttons, menus, settings and screens: they are written as they appear on screen, in English.

## 6. The translated texts

English, with the Italian translation as the example. Spanish has the same texts; German, Portuguese, Dutch and French have those of 6.1 and 6.2. Words in braces, such as `{xp}`, are filled in by the app.

### 6.1 Buttons and messages around an exercise (135 texts, 7 languages)

#### A Round (80)

| Key | English | Italian |
|---|---|---|
| `check` | Check | Controlla |
| `checkMatches` | Check matches | Controlla le coppie |
| `continue` | Continue | Continua |
| `testResults` | Test results · {percent}% | Risultati del test · {percent}% |
| `testPassed` | Passed · {percent}% | Superato · {percent}% |
| `testBelowThreshold` | Below passing threshold · {percent}% | Sotto la soglia di superamento · {percent}% |
| `testQuestion` | Question {n}: {status} | Domanda {n}: {status} |
| `testNextQuestion` | Next question | Domanda successiva |
| `testSeeResults` | See results | Vedi risultati |
| `correct` | Correct | Corretto |
| `incorrect` | Incorrect | Sbagliato |
| `hint` | Hint: {hint} | Suggerimento: {hint} |
| `yourAnswer` | Your answer | La tua risposta |
| `missingWord` | Missing word | Parola mancante |
| `missingLetters` | Missing letters | Lettere mancanti |
| `correctAnswer` | Correct answer: {answer} | Risposta corretta: {answer} |
| `correctAnswerLabel` | Correct answer: | Risposta corretta: |
| `correctTranslations` | Correct translations: | Traduzioni corrette: |
| `otherCorrectTranslations` | Other correct translations: | Altre traduzioni corrette: |
| `somePossibleTranslations` | Some possible translations: | Alcune traduzioni possibili: |
| `acceptedDifference` | Accepted difference: {list} | Differenza accettata: {list} |
| `acceptedDifferences` | Accepted differences: {list} | Differenze accettate: {list} |
| `seeCourseAnswer` | See the course answer. | Vedi la risposta del corso. |
| `reviewTheFlashcard` | Review the flashcard. | Ripassa la scheda. |
| `playAudio` | Play audio | Riproduci l’audio |
| `playAudioAgain` | Play audio again | Riascolta |
| `soundNumber` | Sound {n} | Suono {n} |
| `playSound` | Play sound | Riproduci il suono |
| `play` | Play | Riproduci |
| `audioUnavailable` | Audio unavailable | Audio non disponibile |
| `audioOffNote` | Audio is turned off or unavailable. The exercise still works. | L’audio è spento o non disponibile. L’esercizio funziona comunque. |
| `audioNotOnDevice` | Audio not available on this device. | Audio non disponibile su questo dispositivo. |
| `listenToAnswer` | Listen to the answer | Ascolta la risposta |
| `listenFirst` | Listen first… | Prima ascolta… |
| `listen` | Listen… | Ascolta… |
| `usage` | Usage: | Uso: |
| `pronounceWord` | Pronounce word or phrase | Pronuncia la parola o la frase |
| `pronounceUsage` | Pronounce usage sentence | Pronuncia la frase d’esempio |
| `reviewAgain` | Review again | Ripeti più tardi |
| `gotIt` | Got it | Ho capito |
| `cardAgainLater` | This card will be shown again later in this round. | Questa scheda tornerà più avanti in questo Round. |
| `cardReviewed` | Card reviewed. | Scheda ripassata. |
| `turnOver` | Turn over | Gira |
| `tapToTurn` | Tap the card to turn it over | Tocca la scheda per girarla |
| `empty` | Empty | Vuoto |
| `nothingHereYet` | Nothing here yet | Ancora niente |
| `slotNumber` | Slot {n} | Casella {n} |
| `gapNumber` | Gap {n} | Spazio {n} |
| `groupNumber` | Group {n} | Gruppo {n} |
| `beforeYouStart` | Before you start | Prima di iniziare |
| `openGuidebook` | Open Guidebook | Apri il GuideBook |
| `continueToRound` | Continue to Round | Vai al Round |
| `roundInReview` | {round} · Review | {round} · Ripasso |
| `reviewOfRound` | Review · {round} | Review · {round} |
| `reviewingMissed` | Reviewing exercises you missed | Ripasso degli esercizi sbagliati |
| `reviewMistakesTitle` | Review your mistakes | Rivedi i tuoi errori |
| `reviewMistakesBody` | Let's try again the exercises you got wrong. | Riproviamo gli esercizi che hai sbagliato. |
| `reviewMistakes` | Review mistakes | Rivedi gli errori |
| `finish.round` | Finish round | Termina il Round |
| `finish.story` | Finish story | Termina la Story |
| `finish.sequence` | Finish sequence | Termina la Sequence |
| `finishing.round` | Finishing round… | Chiusura del Round… |
| `finishing.story` | Finishing story… | Chiusura della Story… |
| `finishing.sequence` | Finishing sequence… | Chiusura della Sequence… |
| `leave.round` | Leave round | Esci dal Round |
| `leave.story` | Leave story | Esci dalla Story |
| `leave.sequence` | Leave sequence | Esci dalla Sequence |
| `nothingToScore.round` | Nothing to score in this Round. | Niente da valutare in questo Round. |
| `nothingToScore.story` | Nothing to score in this Story. | Niente da valutare in questa Story. |
| `nothingToScore.sequence` | Nothing to score in this Sequence. | Niente da valutare in questa Sequence. |
| `steps.round` | Round · {n} steps | Round · {n} passi |
| `steps.story` | Story · {n} steps | Story · {n} passi |
| `steps.sequence` | Sequence · {n} steps | Sequence · {n} passi |
| `timed.timeLeft` | Time left: {time} | Tempo rimasto: {time} |
| `timed.timeUp` | Time is up | Tempo scaduto |
| `timed.incomplete` | This Round is incomplete. Unanswered activities stay unanswered. | Questo Round è incompleto. Le attività senza risposta restano tali. |
| `timed.correctXpKept` | Correct-answer XP kept: {xp} | XP conservati per le risposte corrette: {xp} |
| `timed.retrySaving` | Retry saving XP | Riprova a salvare gli XP |
| `timed.retry` | Retry Round | Riprova il Round |
| `weeklyGoalReached` | Weekly goal reached! | Obiettivo settimanale raggiunto! |

#### The end of a Round (10)

| Key | English | Italian |
|---|---|---|
| `completed.round` | Round completed | Round completato |
| `completed.story` | Story completed | Story completata |
| `completed.sequence` | Sequence completed | Sequence completata |
| `summary.correctAnswers` | Correct answers: {correct}/{total} — {xp} XP | Risposte corrette: {correct}/{total} — {xp} XP |
| `summary.difficultyBonus` | Difficulty bonus: +{xp} XP | Bonus difficoltà: +{xp} XP |
| `summary.onTimeBonus` | On Time bonus: +{xp} XP | Bonus puntualità: +{xp} XP |
| `summary.perfectBonus` | Perfect bonus: +{xp} XP | Bonus perfetto: +{xp} XP |
| `summary.firstLaurel` | First Laurel: +{xp} XP | Primo alloro: +{xp} XP |
| `summary.lessonCompleted` | Lesson completed: +{xp} XP | Lesson completata: +{xp} XP |
| `summary.total` | Total: {xp} XP | Totale: {xp} XP |

#### The Duel (13)

| Key | English | Italian |
|---|---|---|
| `duel.title` | Language Duel | Language Duel |
| `duel.finalTitle` | Final Duel | Final Duel |
| `duel.question` | Question {n}/{total} · 4 lives | Domanda {n}/{total} · 4 vite |
| `duel.listenChooseMeaning` | Listen and choose the meaning. | Ascolta e scegli il significato. |
| `duel.finishing` | Finishing duel… | Chiusura del Duel… |
| `duel.finish` | Finish duel | Termina il Duel |
| `duel.finalCompleted` | Final Duel completed! | Final Duel completato! |
| `duel.won` | Duel won | Duel vinto |
| `duel.lost` | Duel lost | Duel perso |
| `duel.wonBody` | Duel won: +{xp} XP<br><br>You proved your knowledge. The next Lesson can now unlock. | Duel vinto: +{xp} XP<br><br>Hai dimostrato quello che sai. Ora la Lesson successiva può sbloccarsi. |
| `duel.lostLives` | Duel lost. You have lost all four lives. | Duel perso. Hai perso tutte e quattro le vite. |
| `duel.endedEarly` | The duel ended before all 25 questions were completed. | Il Duel è finito prima di completare le 25 domande. |
| `duel.backToCourse` | Back to course | Torna al corso |

#### The Review page (17)

| Key | English | Italian |
|---|---|---|
| `review.title` | Review | Review |
| `review.beforeRound` | Before the Round | Prima del Round |
| `review.afterRound` | After the Round | Dopo il Round |
| `review.word` | Word {i} of {n} | Parola {i} di {n} |
| `review.showAnswer` | Show answer | Mostra la risposta |
| `review.nowIKnow` | Now I know it | Ora la so |
| `review.iKnowIt` | I know it | La so |
| `review.stillDontKnow` | I still don't know it | Ancora non la so |
| `review.showAgain` | Show it to me again | Fammela rivedere |
| `review.completed` | Review completed! | Review completata! |
| `review.ready` | Ready for Review | Pronto per la Review |
| `review.noMoreRounds` | No more Rounds are available in this Review session. | Non ci sono altri Round in questa sessione di Review. |
| `review.wordsToReview.one` | {n} word to review in the next Review. | {n} parola da ripassare nella prossima Review. |
| `review.wordsToReview.other` | {n} words to review in the next Review. | {n} parole da ripassare nella prossima Review. |
| `review.next` | Next Review | Prossima Review |
| `review.backToCourse` | Back to Course | Torna al corso |
| `review.noRounds` | There are no Rounds available for Review in this course. | In questo corso non ci sono Round per la Review. |

#### Word Lookup (4)

| Key | English | Italian |
|---|---|---|
| `wordLookup.note` | One possible translation from this Course's GuideBook. | Una delle traduzioni possibili, dal GuideBook del Corso. |
| `wordLookup.notes` | Some possible translations from this Course's GuideBook. | Alcune delle traduzioni possibili, dal GuideBook del Corso. |
| `wordLookup.notice` | Tap a word with a dotted underline to see a translation from this Course's GuideBook. Only some exercise types have them. It is a hint, one possible translation: it does not always match the answer to the exercise. | Tocca una parola sottolineata a puntini per vederne una traduzione dal GuideBook del Corso. Solo alcuni tipi di esercizio le hanno. È un aiuto, una delle traduzioni possibili: non sempre coincide con la soluzione dell'esercizio. |
| `wordLookup.action` | Vocabulary in this text | Vocaboli di questo testo |

#### Links on a Page (5)

| Key | English | Italian |
|---|---|---|
| `linkNotOpened` | The link could not be opened. | Impossibile aprire il link. |
| `linkAskTitle` | Open this link? | Aprire questo link? |
| `linkAskBody` | This page links to {site}. It opens in your browser, outside QuisquisLingo: | Questa pagina rimanda a {site}. Si apre nel browser, fuori da QuisquisLingo: |
| `linkAskOpen` | Open link | Apri il link |
| `linkAskCancel` | Cancel | Annulla |

#### A Course in the same language (Build 275 Revision 1) (6)

| Key | English | Italian |
|---|---|---|
| `sameLanguage.correctAnswers` | Correct answers: | Risposte corrette: |
| `sameLanguage.otherCorrectAnswers` | Other correct answers: | Altre risposte corrette: |
| `sameLanguage.somePossibleAnswers` | Some possible answers: | Alcune risposte possibili: |
| `sameLanguage.wordLookup.note` | One possible meaning from this Course's GuideBook. | Uno dei significati possibili, dal GuideBook del Corso. |
| `sameLanguage.wordLookup.notes` | Some possible meanings from this Course's GuideBook. | Alcuni dei significati possibili, dal GuideBook del Corso. |
| `sameLanguage.wordLookup.notice` | Tap a word with a dotted underline to see its meaning from this Course's GuideBook. Only some exercise types have them. It is a hint, one possible meaning: it does not always match the answer to the exercise. | Tocca una parola sottolineata a puntini per vederne il significato dal GuideBook del Corso. Solo alcuni tipi di esercizio le hanno. È un aiuto, uno dei significati possibili: non sempre coincide con la soluzione dell'esercizio. |

### 6.2 Exercise titles, headings and instruction lines (137 texts, 7 languages)

#### Exercise titles (41)

| Key | English | Italian |
|---|---|---|
| `title.pick_the_translation` | PICK THE TRANSLATION | SCEGLI LA TRADUZIONE |
| `title.type_the_translation` | TYPE THE TRANSLATION | SCRIVI LA TRADUZIONE |
| `title.build_the_translation` | BUILD THE TRANSLATION | COMPONI LA TRADUZIONE |
| `title.match_the_words` | MATCH THE WORDS | ABBINA LE PAROLE |
| `title.match_by_meaning` | MATCH BY MEANING | ABBINA PER SIGNIFICATO |
| `title.flashcard` | FLASHCARD | FLASHCARD |
| `title.picture_flashcard` | PICTURE FLASHCARD | FLASHCARD CON IMMAGINE |
| `title.choose_the_answer` | CHOOSE THE ANSWER | SCEGLI LA RISPOSTA |
| `title.pick_the_missing_word` | PICK THE MISSING WORD | SCEGLI LA PAROLA MANCANTE |
| `title.type_the_missing_word` | TYPE THE MISSING WORD | SCRIVI LA PAROLA MANCANTE |
| `title.word_order` | WORD ORDER | ORDINE DELLE PAROLE |
| `title.true_or_false` | TRUE OR FALSE | VERO O FALSO |
| `title.pick_the_words_for_the_gaps` | PICK THE WORDS FOR THE GAPS | SCEGLI LE PAROLE PER GLI SPAZI |
| `title.one_word_fills_all` | ONE WORD FILLS ALL | UNA PAROLA PER TUTTI |
| `title.complete_the_text` | COMPLETE THE TEXT | COMPLETA IL TESTO |
| `title.missing_letters` | MISSING LETTERS | LETTERE MANCANTI |
| `title.put_the_sentences_in_order` | PUT THE SENTENCES IN ORDER | ORDINA LE FRASI |
| `title.sort_into_groups` | SORT INTO GROUPS | SMISTA IN GRUPPI |
| `title.fill_the_slots` | FILL THE SLOTS | RIEMPI LE CASELLE |
| `title.listen_and_choose` | LISTEN AND CHOOSE | ASCOLTA E SCEGLI |
| `title.listen_and_answer` | LISTEN AND ANSWER | ASCOLTA E RISPONDI |
| `title.type_what_you_hear` | TYPE WHAT YOU HEAR | SCRIVI CIÒ CHE SENTI |
| `title.listen_and_fill_the_gaps` | LISTEN AND FILL THE GAPS | ASCOLTA E RIEMPI GLI SPAZI |
| `title.listen_and_match` | LISTEN AND MATCH | ASCOLTA E ABBINA |
| `title.listen_and_pick_the_missing_word` | LISTEN AND PICK THE MISSING WORD | ASCOLTA E SCEGLI LA PAROLA MANCANTE |
| `title.listen_and_pick_the_image` | LISTEN AND PICK THE IMAGE | ASCOLTA E SCEGLI L’IMMAGINE |
| `title.spell_what_you_hear` | SPELL WHAT YOU HEAR | COMPONI CIÒ CHE SENTI |
| `title.read_and_answer` | READ AND ANSWER | LEGGI E RISPONDI |
| `title.select_the_image` | SELECT THE IMAGE | SCEGLI L’IMMAGINE |
| `title.recognize_characters` | RECOGNIZE CHARACTERS | RICONOSCI I CARATTERI |
| `title.spell_the_word_in_the_picture` | SPELL THE WORD IN THE PICTURE | COMPONI LA PAROLA DELL’IMMAGINE |
| `title.what_is_in_the_picture` | WHAT IS IN THE PICTURE? | COSA C’È NELL’IMMAGINE? |
| `title.type_what_you_see` | TYPE WHAT YOU SEE | SCRIVI CIÒ CHE VEDI |
| `title.name_what_you_see` | NAME WHAT YOU SEE | NOMINA CIÒ CHE VEDI |
| `title.spell_the_word` | SPELL THE WORD | COMPONI LA PAROLA |
| `title.match_pictures_to_words` | MATCH PICTURES TO WORDS | ABBINA IMMAGINI E PAROLE |
| `title.note_card` | NOTE CARD | NOTA |
| `title.dialogue_line` | DIALOGUE LINE | BATTUTA |
| `title.story_cover` | STORY COVER | COPERTINA DELLA STORY |
| `title.before_you_start` | BEFORE YOU START | PRIMA DI INIZIARE |
| `title.page` | PAGE | PAGINA |

#### Headings by kind of exercise (used when an exercise has no title of its own) (33)

| Key | English | Italian |
|---|---|---|
| `type.default` | EXERCISE | ESERCIZIO |
| `type.inputMissingWord` | TYPE THE MISSING WORD | SCRIVI LA PAROLA MANCANTE |
| `type.selectCharacter` | RECOGNIZE CHARACTERS | RICONOSCI I CARATTERI |
| `type.select` | CHOOSE | SCEGLI |
| `type.selectListen` | LISTEN AND CHOOSE | ASCOLTA E SCEGLI |
| `type.selectListenPassage` | LISTENING | ASCOLTO |
| `type.selectRead` | READING | LETTURA |
| `type.selectDialogue` | DIALOGUE | DIALOGO |
| `type.selectImage` | CHOOSE THE IMAGE | SCEGLI L’IMMAGINE |
| `type.presentation` | FLASHCARD | FLASHCARD |
| `type.dialogueLine` | DIALOGUE | DIALOGO |
| `type.storyCover` | STORY | STORY |
| `type.inputComplete` | COMPLETE | COMPLETA |
| `type.selectComplete` | COMPLETE THE SENTENCE | COMPLETA LA FRASE |
| `type.arrangeSentence` | BUILD THE SENTENCE | COMPONI LA FRASE |
| `type.arrangeLines` | PUT THE SENTENCES IN ORDER | ORDINA LE FRASI |
| `type.arrangeWord` | BUILD THE WORD | COMPONI LA PAROLA |
| `type.inputPictureName` | NAME WHAT YOU SEE | NOMINA CIÒ CHE VEDI |
| `type.arrangePictureName` | NAME WHAT YOU SEE | NOMINA CIÒ CHE VEDI |
| `type.matchTranslation` | MATCH | ABBINA |
| `type.match` | MATCH | ABBINA |
| `type.inputListenGaps` | COMPLETE | COMPLETA |
| `type.inputListenWrite` | WRITE WHAT YOU HEAR | SCRIVI CIÒ CHE SENTI |
| `type.matchAudio` | MATCH THE AUDIO | ABBINA L’AUDIO |
| `type.inputTranslation` | TYPE THE TRANSLATION | SCRIVI LA TRADUZIONE |
| `type.arrangeTranslation` | BUILD THE TRANSLATION | COMPONI LA TRADUZIONE |
| `type.selectContext` | CONTEXT | CONTESTO |
| `type.assignGroups` | SORT INTO GROUPS | SMISTA IN GRUPPI |
| `type.assignSlots` | FILL THE SLOTS | RIEMPI LE CASELLE |
| `type.assignGaps` | FILL THE GAPS | RIEMPI GLI SPAZI |
| `type.selectPicture` | WHAT IS IN THE PICTURE? | COSA C’È NELL’IMMAGINE? |
| `type.selectCompleteAll` | ONE WORD FILLS ALL | UNA PAROLA PER TUTTI |
| `type.selectSounds` | PICK THE SOUND | SCEGLI IL SUONO |

#### Instruction lines (49)

| Key | English | Italian |
|---|---|---|
| `instruction.default` | Complete the exercise. | Completa l’esercizio. |
| `instruction.inputMissingWord` | The first letter is given: type the whole word. | La prima lettera è data: scrivi la parola intera. |
| `instruction.selectCharacter` | Choose the option that matches the character. | Scegli l’opzione che corrisponde al carattere. |
| `instruction.select` | Find the correct answer. | Trova la risposta corretta. |
| `instruction.selectListen` | Find the answer that matches what you hear. | Trova la risposta che corrisponde a ciò che senti. |
| `instruction.selectListenPassage` | Listen and choose the correct answer. | Ascolta e scegli la risposta corretta. |
| `instruction.selectRead` | Read and choose the correct answer. | Leggi e scegli la risposta corretta. |
| `instruction.selectDialogue` | Read the dialogue and choose the best response. | Leggi il dialogo e scegli la risposta migliore. |
| `instruction.selectImage` | Find the matching picture. | Trova l’immagine corrispondente. |
| `instruction.presentation` | Study the word and its usage. | Studia la parola e il suo uso. |
| `instruction.flashcardWordFirst` | Think of what it means, then turn the card. | Pensa a cosa significa, poi gira la scheda. |
| `instruction.flashcardMeaningFirst` | Think of the {language} word, then turn the card. | Pensa alla parola in {language}, poi gira la scheda. |
| `instruction.dialogueLine` | Read or listen, then continue. | Leggi o ascolta, poi continua. |
| `instruction.dialogueLineText` | Read, then continue. | Leggi, poi continua. |
| `instruction.dialogueLineAudio` | Listen, then continue. | Ascolta, poi continua. |
| `instruction.dialogueLineAfterAudio` | Listen first; the text appears after. | Ascolta prima; il testo compare dopo. |
| `instruction.storyCover` | A story begins. Continue when you are ready. | Inizia una Story. Continua quando sei pronto. |
| `instruction.inputComplete` | Write the words that fill the gaps. | Inserisci le parole che mancano nella frase. |
| `instruction.selectComplete` | Choose the block that fits the gap. | Seleziona il blocco adatto allo spazio vuoto. |
| `instruction.select_opposite` | Find the opposite. | Trova il contrario. |
| `instruction.arrangeSentence` | Arrange the words in the correct order. | Metti le parole nell’ordine corretto. |
| `instruction.arrangeLines` | Arrange the lines in a logical order. | Metti le righe in un ordine logico. |
| `instruction.arrangeWord` | Form the word the picture shows. | Compita ciò che mostra l’immagine. |
| `instruction.inputPictureName` | Write the name of the picture. | Inserisci il nome dell’immagine. |
| `instruction.arrangePictureName` | Put the blocks in order to name the picture. | Metti in ordine i blocchi per dare il nome all’immagine. |
| `instruction.matchTranslation` | Pair each word with its translation. | Accoppia ogni parola alla sua traduzione. |
| `instruction.match` | Pair the items that belong together. | Accoppia gli elementi che vanno insieme. |
| `instruction.assignGroups` | Tap an item, then the group it belongs to. | Tocca un elemento, poi il gruppo a cui appartiene. |
| `instruction.assignSlots` | Tap an item, then its slot. | Tocca un elemento, poi la sua casella. |
| `instruction.assignGaps` | Tap a word, then the gap it fills. | Tocca una parola, poi lo spazio che riempie. |
| `instruction.inputListenGaps` | Fill in the missing word you hear. | Inserisci la parola mancante che senti. |
| `instruction.inputListenWrite` | Transcribe every word you hear. | Trascrivi ogni parola che senti. |
| `instruction.matchAudio` | Pair each sound with its word. | Accoppia ogni audio alla sua parola. |
| `instruction.inputTranslation` | Translate into {language}. | Traduci in {language}. |
| `instruction.arrangeTranslation` | Translate into {language} with the word blocks. | Traduci in {language} con i blocchi di parole. |
| `instruction.selectContext` | Use the context to choose the correct answer. | Usa il contesto per scegliere la risposta corretta. |
| `instruction.inputCompleteOne` | Write the word that fills the gap. | Inserisci la parola che manca nella frase. |
| `instruction.inputCompleteLetters` | Write the missing letters. | Inserisci le lettere mancanti. |
| `instruction.selectListenQuestion` | Answer the question about what you hear. | Rispondi alla domanda su ciò che senti. |
| `instruction.selectListenHeard` | Select the sentence that you heard. | Seleziona la frase che hai sentito. |
| `instruction.selectListenMeaning` | Select the meaning of what you heard. | Seleziona il significato di ciò che hai sentito. |
| `instruction.selectPicture` | Choose the option that fits best. | Scegli l’opzione più adatta. |
| `instruction.arrangeWordHeard` | Form the word you hear. | Compita la parola che senti. |
| `instruction.arrangeWordClue` | Form the word the clue describes. | Compita la parola descritta dall’indizio. |
| `instruction.arrangeGaps` | Choose a word for each gap. | Metti una parola in ogni spazio. |
| `instruction.selectCompleteAll` | Choose the word that fills every gap. | Scegli la parola che completa tutti gli spazi. |
| `instruction.selectSounds` | Play each sound, then choose the right one. | Riproduci ogni suono, poi scegli quello giusto. |
| `instruction.selectSoundsGap` | Play each sound, then choose the one that fills the gap. | Riproduci ogni suono, poi scegli quello che completa lo spazio vuoto. |
| `instruction.selectTranslation` | Choose the correct {language} translation | Seleziona la traduzione corretta in {language} |

#### A Course in the same language (Build 275 Revision 1) (14)

| Key | English | Italian |
|---|---|---|
| `title.pick_the_word` | PICK THE WORD | SCEGLI LA PAROLA |
| `title.pick_the_meaning` | PICK THE MEANING | SCEGLI IL SIGNIFICATO |
| `title.type_the_word` | TYPE THE WORD | SCRIVI LA PAROLA |
| `title.type_the_meaning` | TYPE THE MEANING | SCRIVI IL SIGNIFICATO |
| `title.build_the_sentence` | BUILD THE SENTENCE | COMPONI LA FRASE |
| `title.build_the_meaning` | BUILD THE MEANING | COMPONI IL SIGNIFICATO |
| `title.match_words_and_meanings` | MATCH WORDS AND MEANINGS | ABBINA PAROLE E SIGNIFICATI |
| `instruction.sameLanguage.selectWord` | Choose the answer that fits this meaning. | Seleziona la risposta che corrisponde a questo significato. |
| `instruction.sameLanguage.selectMeaning` | Choose the correct meaning. | Seleziona il significato corretto. |
| `instruction.sameLanguage.inputWord` | Write the answer that fits this meaning. | Inserisci la risposta che corrisponde a questo significato. |
| `instruction.sameLanguage.inputMeaning` | Write what this means. | Inserisci che cosa significa. |
| `instruction.sameLanguage.arrangeSentence` | Form the sentence for this meaning with the word blocks. | Forma con i blocchi di parole la frase che corrisponde a questo significato. |
| `instruction.sameLanguage.arrangeMeaning` | Form the meaning of this sentence with the word blocks. | Forma con i blocchi di parole il significato di questa frase. |
| `instruction.sameLanguage.matchTranslation` | Pair each item with its meaning. | Accoppia ogni elemento al suo significato. |

### 6.3 The Welcome Wizard (15 texts, 3 languages)

| Key | English | Italian |
|---|---|---|
| `step` | Step {current} of {total} | Passo {current} di {total} |
| `back` | Back | Indietro |
| `skip` | Skip | Salta |
| `next` | Next | Avanti |
| `start` | Start learning | Inizia a imparare |
| `step1.title` | Welcome aboard! | Ti diamo il benvenuto! |
| `step1.body` | QuisquisLingo is a language school that fits in your pocket: no account, no ads, no cloud. Everything you learn stays on this device. | QuisquisLingo è una scuola di lingue che sta in tasca: niente account, niente pubblicità, niente cloud. Tutto quello che impari resta su questo dispositivo. |
| `step2.title` | Courses made by others | Corsi fatti da altri |
| `step2.body` | Courses are made by people: friends, teachers and publishers write them and share them as a file. Choose Import a Course on the start page, or later tap the flag at the top and choose Import Course, and start learning from what they made. | I corsi li fanno le persone: amici, insegnanti ed editori li scrivono e li condividono come file. Scegli Import a Course nella pagina iniziale, oppure più avanti tocca la bandiera in alto e scegli Import Course, e comincia a imparare da quello che hanno preparato. |
| `step3.title` | Lessons, Rounds, Laurels | Lesson, Round, Laurel |
| `step3.body` | A Lesson is a path of short Rounds. Finish a Round without mistakes to earn a Laurel. Feeling brave? Win the Lesson's Duel to jump ahead. | Una Lesson è un percorso di Round brevi. Completa un Round senza errori e guadagni un Laurel. Ti va una sfida? Vinci il Duel della Lesson per saltare avanti. |
| `step4.title` | Little and often | Poco ma spesso |
| `step4.body` | Five minutes a day keeps your streak alive and your Weekly XP growing. Review brings back the Rounds that gave you the most trouble. | Cinque minuti al giorno tengono viva la tua streak e fanno crescere i Weekly XP. Review ti ripropone i Round che ti hanno dato più filo da torcere. |
| `step5.title` | Make your own Course | Crea il tuo corso |
| `step5.body` | Anyone can write a Course with Course Studio, the editor QuisquisLingo keeps hidden. Psst: to wake it up, tap Version and Build in Settings ten times. | Chiunque può scrivere un corso con Course Studio, l'editor che QuisquisLingo tiene nascosto. Psst: per svegliarlo, tocca dieci volte Version and Build in Settings. |

### 6.4 Course Info (82 texts, 3 languages)

| Key | English | Italian |
|---|---|---|
| `courseInfo.title` | Course Info | Course Info |
| `courseInfo.authorSupportMissing` | This course does not provide an author support link. | Questo corso non indica un link per sostenere gli autori. |
| `courseInfo.authorSupportOpenFailed` | The author support link could not open. | Non è stato possibile aprire il link per sostenere gli autori. |
| `courseInfo.authorsContributors` | Authors / Contributors: {value} | Authors / Contributors: {value} |
| `courseInfo.notSpecified` | Not specified | Non indicato |
| `courseInfo.notRecorded` | Not recorded | Non registrato |
| `courseInfo.contributors` | Contributors | Collaboratori |
| `courseInfo.illustrators` | Illustrators | Illustratori |
| `courseInfo.origin.bundledOfficial` | Bundled official | Bundled official |
| `courseInfo.origin.publisherCourse` | Publisher Course | Publisher Course |
| `courseInfo.origin.customCourse` | Custom course | Custom course |
| `courseInfo.origin.label` | Origin: {value} | Origine: {value} |
| `courseInfo.publisher` | Publisher: {value} | Editore: {value} |
| `courseInfo.originalCourseCreated` | Original Course Created: {value} | Original Course Created: {value} |
| `courseInfo.lastVersionEditor` | Last Version Editor: {value} | Last Version Editor: {value} |
| `courseInfo.modified` | Modified: {value} | Modified: {value} |
| `courseInfo.officialCourseVersion` | Official course version: {value} | Versione ufficiale del corso: {value} |
| `courseInfo.officialRelease` | Official release: {value} | Release ufficiale: {value} |
| `courseInfo.distributionChannel` | Distribution channel: {value} | Canale di distribuzione: {value} |
| `courseInfo.publisherVerification` | Publisher verification: {value} | Verifica dell’editore: {value} |
| `courseInfo.verificationRequired` | Verification required. The stored course and progress are preserved. Import a verified publisher release to reactivate it. | Verification required. Il corso salvato e i progressi restano. Importa una release verificata dell’editore per riattivarlo. |
| `courseInfo.signatureScope` | Signature covers the course JSON. Separate media files are not authenticated by this signature. | La firma copre il Course JSON. I file multimediali separati non sono autenticati da questa firma. |
| `courseInfo.officialChecksum` | Official checksum: {value} | Checksum ufficiale: {value} |
| `courseInfo.officialReadOnly` | Official course - read only | Official course - read only |
| `courseInfo.courseVersion` | Course version: {value} | Versione del corso: {value} |
| `courseInfo.unconfirmed` | Unconfirmed | Non confermata |
| `courseInfo.versionNotes` | Version notes:<br>{value} | Note della versione:<br>{value} |
| `courseInfo.internalCourseData` | Internal course data | Dati interni del corso |
| `courseInfo.enlargeImage` | Enlarge Course image | Ingrandisci l’immagine del corso |
| `courseInfo.courseModel` | Course Model: v{value} | Course Model: v{value} |
| `courseInfo.temporarySample.title` | Private course | Private course |
| `courseInfo.temporarySample.body` | This course is visible in QQL only to its Course Maintainer and the members of its assigned Team. Turn Private course off in Course Info to show it to everyone on this device. | Questo corso è visibile in QQL solo al suo Course Maintainer e ai membri del Team assegnato. Disattiva Private course in Course Info per mostrarlo a tutti su questo dispositivo. |
| `courseInfo.authorshipAndDescriptiveCredits` | Authorship and descriptive credits | Autori e riconoscimenti |
| `courseInfo.teamLeaderTooltip` | This is descriptive information only. To assign or change Team Leader roles in QQL, use Team Manager. | Queste informazioni sono solo descrittive. Per assegnare o cambiare i ruoli Team Leader in QQL, usa Team Manager. |
| `courseInfo.languages` | Languages | Lingue |
| `courseInfo.learningLanguage` | Learning language: {value} | Lingua studiata: {value} |
| `courseInfo.baseLanguage` | Base language: {value} | Lingua di partenza: {value} |
| `courseInfo.sameLanguage` | Same-language Course: everything is in the language being learned. | Corso nella stessa lingua: tutto è nella lingua che si studia. |
| `courseInfo.licenseRights` | License / Rights | License / Rights |
| `courseInfo.license` | License: {value} | Licenza: {value} |
| `courseInfo.rightsHolder` | Rights Holder: {value} | Rights Holder: {value} |
| `courseInfo.derivativeWorks` | Derivative works: {value} | Opere derivate: {value} |
| `courseInfo.rightsHolderDisclaimer` | Rights Holder is descriptive legal metadata and does not control QQL permissions. | Rights Holder è un dato legale descrittivo e non controlla i permessi QQL. |
| `courseInfo.mediaCredits` | Media credits | Crediti dei media |
| `courseInfo.mediaCreditsDisclaimer` | Media credits are descriptive and do not control QQL permissions. | I crediti dei media sono descrittivi e non controllano i permessi QQL. |
| `courseInfo.source` | Source: {value} | Fonte: {value} |
| `courseInfo.courseDetails` | Course details | Dettagli del corso |
| `courseInfo.lessons` | Lessons: {value} | Lessons: {value} |
| `courseInfo.estimatedStudyTime` | Estimated study time: {value} {unit} | Tempo di studio stimato: {value} {unit} |
| `courseInfo.hour` | hour | ora |
| `courseInfo.hours` | hours | ore |
| `courseInfo.minimumAge` | Minimum age: {value}+ | Età minima: {value}+ |
| `courseInfo.keywords` | Keywords: {value} | Parole chiave: {value} |
| `courseInfo.requiresBuild` | Requires QuisquisLingo build {value} or later | Richiede QuisquisLingo build {value} o successiva |
| `courseInfo.publisherContact` | Publisher contact | Contatti dell’editore |
| `courseInfo.website` | Website: {value} | Sito web: {value} |
| `courseInfo.email` | Email: {value} | Email: {value} |
| `courseInfo.buyACoffee` | Buy a Coffee | Buy a Coffee |
| `courseInfo.supportAuthors` | Support this course's authors. | Sostieni gli autori di questo corso. |
| `courseInfo.governance.title` | Course responsibility, Team assignment and authorization | Responsabilità del corso, Team assegnato e autorizzazioni |
| `courseInfo.governance.officialPublisher` | Official publisher: {value} | Editore ufficiale: {value} |
| `courseInfo.governance.originalCreator` | Original Course Creator: {value} | Original Course Creator: {value} |
| `courseInfo.governance.maintainer` | Course Maintainer: {value} | Course Maintainer: {value} |
| `courseInfo.governance.assignedTeam` | Assigned Team: {value} | Assigned Team: {value} |
| `courseInfo.governance.teamLeaders` | Team Leaders: {value} | Team Leaders: {value} |
| `courseInfo.governance.teamMembers` | Team Members: {value} | Team Members: {value} |
| `courseInfo.governance.none` | None | Nessuno |
| `courseInfo.governance.noneAvailable` | None available | Nessuno disponibile |
| `courseInfo.governance.disclaimer` | Course maintenance and Team governance are separate. Provenance, attribution and rights metadata do not grant editing permission. | La manutenzione del corso e la gestione del Team sono separate. Provenienza, attribuzioni e diritti non concedono permessi di modifica. |
| `courseInfo.fork.title` | Fork provenance | Provenienza del Fork |
| `courseInfo.fork.notRecorded` | Not recorded | Non registrata |
| `courseInfo.fork.fromCourseId` | Forked From Course ID: {value} | Forked From Course ID: {value} |
| `courseInfo.fork.sourceCourse` | Source Course: {value} | Corso di origine: {value} |
| `courseInfo.fork.sourceCourseVersion` | Source Course version: {value} | Versione del corso di origine: {value} |
| `courseInfo.fork.sourcePublisher` | Source publisher: {value} | Editore del corso di origine: {value} |
| `courseInfo.fork.sourcePublisherId` | Source publisher ID: {value} | ID dell’editore di origine: {value} |
| `courseInfo.fork.sourceAuthors` | Source Authors / Contributors:<br>{value} | Autori / collaboratori del corso di origine:<br>{value} |
| `courseInfo.fork.sourceOfficialChecksum` | Source official checksum: {value} | Checksum ufficiale di origine: {value} |
| `courseInfo.fork.createdBy` | Fork Created By: {value} | Fork creato da: {value} |
| `courseInfo.fork.createdDate` | Fork Created Date: {value} | Data di creazione del Fork: {value} |
| `courseInfo.fork.disclaimer` | Fork provenance is immutable. Rights Holder and attribution metadata remain separate from QQL permissions. | La provenienza del Fork non si può modificare. Rights Holder e attribuzioni restano separati dai permessi QQL. |
| `courseInfo.fork.creatorUser` | Fork creator user | Utente che ha creato il Fork |

### 6.5 The Help Language selector (4 texts)

| Key | English | Italian |
|---|---|---|
| `locale.label` | Locale | Locale |
| `locale.english` | English | English |
| `locale.italian` | Italiano | Italiano |
| `locale.spanish` | Español | Español |

### 6.6 Help: titles (141 texts, 3 languages)

The titles of the Help pages and of their sections.

#### App Info (23)

| Key | English | Italian |
|---|---|---|
| `appInfo.versionAndBuild.title` | Version and Build | Versione e build |
| `appInfo.choosingAndOpeningCourses.title` | Choosing and opening courses | Scegliere e aprire i corsi |
| `appInfo.courseIdentityAndProgress.title` | Course identity and progress | Identità del corso e progressi |
| `appInfo.progressWeekXpAndGamification.title` | Progress, Week XP and Gamification | Progressi, Week XP e Gamification |
| `appInfo.streakAndFreezeRule.title` | Streak and the freeze rule | Streak e regola del congelamento |
| `appInfo.daysStudied.title` | Days studied | Giorni di studio |
| `appInfo.laurelCrowns.title` | Laurel crowns | Corone d’alloro |
| `appInfo.pathColours.title` | Colour code of the path | Codice colori del percorso |
| `appInfo.audioSettings.title` | Audio Settings | Audio Settings |
| `appInfo.betaExpiry.title` | Beta expiry | Scadenza della beta |
| `appInfo.status.title` | Status | Status |
| `appInfo.avatarAppearance.title` | Avatar appearance | Aspetto dell’avatar |
| `appInfo.review.title` | Review | Review |
| `appInfo.guidebooks.title` | Guidebooks | GuideBook |
| `appInfo.wordLookup.title` | Word Lookup | Word Lookup |
| `appInfo.languageDuels.title` | Language Duels | Language Duel |
| `appInfo.sourceAndTargetLanguages.title` | Source and target languages | Lingua di partenza e lingua studiata |
| `appInfo.exportAndImportLearnerData.title` | Export and import learner data | Esportare e importare i tuoi dati |
| `appInfo.updates.title` | Updates | Aggiornamenti |
| `appInfo.crashLogAndDiagnosticLog.title` | Crash Log and Diagnostic Log | Crash Log e Diagnostic Log |
| `appInfo.courseStudioAndCourseEditor.title` | Course Studio and Course Editor | Course Studio e Course Editor |
| `appInfo.courseContentAndAi.title` | Course content and AI | Contenuti dei corsi e IA |
| `appInfo.title` | Info | Info |

#### All Courses Help and Course Library Help (9)

| Key | English | Italian |
|---|---|---|
| `allCoursesHelp.title` | Courses on this device | Corsi su questo dispositivo |
| `allCoursesHelp.categories.title` | Categories | Categorie |
| `allCoursesHelp.courseDetails.title` | Course details | Dettagli del Course |
| `allCoursesHelp.availability.title` | Availability | Disponibilità |
| `allCoursesHelp.sortingAndCompactView.title` | Sorting and section views | Ordinamento e viste delle sezioni |
| `allCoursesHelp.personalLibrary.title` | Personal library | Libreria personale |
| `allCoursesHelp.coursesInLearnerMode.title` | Courses in learner mode | Courses in learner mode |
| `allCoursesHelp.importing.title` | Importing | Importazione |
| `allCoursesHelp.removingPublisherCourse.title` | Removing a Publisher Course from the device | Rimuovere un Publisher Course dal dispositivo |

#### Course Studio Help (4)

| Key | English | Italian |
|---|---|---|
| `courseStudioHelp.title` | Course Studio Help | Guida al Course Studio |
| `courseStudioHelp.findingCourses.title` | Finding Courses | Trovare i corsi |
| `courseStudioHelp.courseOperations.title` | Course operations | Operazioni sui corsi |
| `courseStudioHelp.courseTypes.title` | Course types | Tipi di corso |

#### Editor Help (24)

| Key | English | Italian |
|---|---|---|
| `editorHelp.coursesInLearnerMode.title` | Courses in learner mode | I corsi in modalità studente |
| `editorHelp.courseOrigin.title` | Course origin | Origine del corso |
| `editorHelp.localCourseEditsAndBackups.title` | Local course edits and backups | Modifiche locali e backup |
| `editorHelp.androidDeviceBackupTechnical.title` | Android device backup (technical) | Backup del dispositivo Android (tecnico) |
| `editorHelp.officialCourseUpdates.title` | Official course updates | Aggiornamenti dei corsi ufficiali |
| `editorHelp.courseInfoEditorAndLicense.title` | Course Info Editor and license | Course Info Editor e licenza |
| `editorHelp.courseResponsibilityPermissionsAndTeams.title` | Course responsibility, permissions and Teams | Responsabilità del corso, permessi e Team |
| `editorHelp.importCustomCourse.title` | Import a custom course | Importare un corso personalizzato |
| `editorHelp.exportCustomCourse.title` | Export a custom course | Esportare un corso personalizzato |
| `editorHelp.exportAsPublisherCourse.title` | Export as Publisher Course | Esportare come Corso Editore |
| `editorHelp.courseCreationRules.title` | Course creation rules | Regole per creare i corsi |
| `editorHelp.auditSeverityAndCodes.title` | Audit severity and codes | Gravità e codici dell’Audit |
| `editorHelp.courseAudit.title` | Course Audit | Course Audit |
| `editorHelp.createNewCourse.title` | Create a new course | Creare un corso nuovo |
| `editorHelp.qa.gettingStarted.title` | Getting started | Per iniziare |
| `editorHelp.qa.savingAndVersions.title` | Saving and versions | Salvataggio e versioni |
| `editorHelp.qa.courseSettings.title` | Course settings | Impostazioni del Course |
| `editorHelp.qa.lessonsAndRounds.title` | Lessons and Rounds | Lesson e Round |
| `editorHelp.qa.roundTypes.title` | Round Types | Tipi di Round |
| `editorHelp.qa.exercises.title` | Exercises | Esercizi |
| `editorHelp.qa.picturesAndSound.title` | Pictures and sound | Immagini e audio |
| `editorHelp.qa.checkingTheCourse.title` | Checking the Course | Controllare il Course |
| `editorHelp.title` | Editor Help | Guida all’Editor |
| `editorHelp.technicalReference.title` | Technical reference | Riferimento tecnico |

#### Exercise Help, Exercise primitives Help and the field Help of the exercise forms (5)

| Key | English | Italian |
|---|---|---|
| `exerciseHelp.title` | Exercise Help | Guida agli esercizi |
| `exerciseHelp.supplement.canonicalEditor.title` | Canonical editor | Editor canonico |
| `exerciseHelp.supplement.answerVariants.title` | Answer variants | Varianti delle risposte |
| `exerciseHelp.supplement.textEvaluationAndCorrections.title` | Text evaluation and corrections | Valutazione del testo e correzioni |
| `exerciseHelp.supplement.contextualComprehensionExample.title` | Read and answer example | Esempio di Read and answer |

#### The field Help of the GuideBook module page (9)

| Key | English | Italian |
|---|---|---|
| `guidebookHelp.field.title.title` | Title | Title |
| `guidebookHelp.field.sentences.title` | Sentences | Sentences |
| `guidebookHelp.field.words.title` | Words & Expressions | Words & Expressions |
| `guidebookHelp.field.target.title` | Target | Target |
| `guidebookHelp.field.source.title` | Source | Source |
| `guidebookHelp.field.context.title` | Context (optional) | Context (facoltativo) |
| `guidebookHelp.field.picture.title` | Picture (optional) | Picture (facoltativa) |
| `guidebookHelp.field.overview.title` | Overview | Overview |
| `guidebookHelp.field.pasteList.title` | Paste list | Paste list |

#### Advanced (Admin) Help (12)

| Key | English | Italian |
|---|---|---|
| `deviceAdminHelp.title` | Advanced (Admin) Help | Guida ad Advanced (Admin) |
| `deviceAdminHelp.whatThisPageIs.title` | What this page is | A cosa serve questa pagina |
| `deviceAdminHelp.whoIsAnAdmin.title` | Who is an admin | Chi è un admin |
| `deviceAdminHelp.whatAdminsCanDo.title` | What admins CAN do | Cosa possono fare gli admin |
| `deviceAdminHelp.whatAdminsCannotDo.title` | What admins CANNOT do | Cosa non possono fare gli admin |
| `deviceAdminHelp.inventory.title` | Inventory | Inventory |
| `deviceAdminHelp.qqlTools.title` | QQL-Tools | QQL-Tools |
| `deviceAdminHelp.updates.title` | Updates | Updates |
| `deviceAdminHelp.askWhoIsLearningAtStartup.title` | Ask who is learning at startup | Ask who is learning at startup |
| `deviceAdminHelp.resetOptions.title` | The reset options | Opzioni di reset |
| `deviceAdminHelp.beforeResetBackups.title` | Before you reset: backups | Prima del reset: backup |
| `deviceAdminHelp.forgottenPin.title` | Forgotten PIN | PIN dimenticato |

#### Debug Help (4)

| Key | English | Italian |
|---|---|---|
| `debugHelp.title` | Debug Help | Guida a Debug |
| `debugHelp.crashLog.title` | Crash Log | Crash Log |
| `debugHelp.diagnosticLog.title` | Diagnostic Log | Diagnostic Log |
| `debugHelp.privacy.title` | Privacy | Privacy |

#### Publisher signing guide (15)

| Key | English | Italian |
|---|---|---|
| `publisherSigningHelp.title` | Publisher signing and approval | Firma e approvazione degli editori |
| `publisherSigningHelp.status.title` | Status: signature verification implemented | Stato: verifica delle firme implementata |
| `publisherSigningHelp.rolesAndTools.title` | 1. Roles and tools | 1. Ruoli e strumenti |
| `publisherSigningHelp.createAndProtectKey.title` | 2. Publisher: create and protect the key | 2. Publisher: creare e proteggere la chiave |
| `publisherSigningHelp.requestApproval.title` | 3. Publisher: request approval | 3. Publisher: chiedere l’approvazione |
| `publisherSigningHelp.verifyIdentityChallenge.title` | 4. Owner: verify identity and issue a challenge | 4. Proprietario: verificare l’identità e inviare il challenge |
| `publisherSigningHelp.proveKeyPossession.title` | 5. Publisher and owner: prove key possession | 5. Publisher e proprietario: dimostrare il possesso della chiave |
| `publisherSigningHelp.recordApproval.title` | 6. Owner: record approval and activate trust | 6. Proprietario: registrare l’approvazione e attivare la fiducia |
| `publisherSigningHelp.signAndDistribute.title` | 7. Publisher: sign and distribute a course | 7. Publisher: firmare e distribuire un Course |
| `publisherSigningHelp.mediaRules.title` | 7a. Media a Publisher Course can and cannot carry | 7a. Media ammessi in un Publisher Course |
| `publisherSigningHelp.mediaCredits.title` | 7b. Media credits | 7b. Crediti dei media |
| `publisherSigningHelp.importPolicy.title` | 8. Import policy and existing courses | 8. Regole d’importazione e Courses esistenti |
| `publisherSigningHelp.keyRotation.title` | 9. Lost keys, rotation and revocation | 9. Chiavi perse, rotazione e revoca |
| `publisherSigningHelp.protocolReferences.title` | 10. Protocol and references | 10. Protocollo e riferimenti |
| `publisherSigningHelp.dummyPublisherTesting.title` | 11. Dummy publisher: automated and manual tests | 11. Publisher Dummy: test automatici e manuali |

#### Technical reference (36)

| Key | English | Italian |
|---|---|---|
| `technical.courseModel.title` | QuisquisLingo Course Model v12 | QuisquisLingo Course Model v12 |
| `technical.courseModel.status.title` | Status | Stato |
| `technical.courseModel.hierarchy.title` | Hierarchy | Gerarchia |
| `technical.courseModel.content.title` | Content | Content |
| `technical.courseModel.guidebook.title` | Guidebook | GuideBook |
| `technical.courseModel.completionAndProgression.title` | Completion and progression | Completamento e progressione |
| `technical.courseModel.languageDuel.title` | Language Duel | Language Duel |
| `technical.courseModel.friendlyEditorTemplates.title` | Friendly Editor templates | Template dell’Editor |
| `technical.exercisePrimitives.title` | Exercise primitives | Primitive degli esercizi |
| `technical.exercisePrimitives.status.title` | Status | Stato |
| `technical.exercisePrimitives.exerciseAnatomy.title` | Exercise anatomy | Struttura di un esercizio |
| `technical.exercisePrimitives.primitives.title` | The nine primitives | Le nove primitive |
| `technical.exercisePrimitives.primitiveSelect.title` | Select | Select |
| `technical.exercisePrimitives.primitiveInput.title` | Input | Input |
| `technical.exercisePrimitives.primitiveArrange.title` | Arrange | Arrange |
| `technical.exercisePrimitives.primitiveMatch.title` | Match | Match |
| `technical.exercisePrimitives.primitiveAssign.title` | Assign | Assign |
| `technical.exercisePrimitives.primitiveSpeak.title` | Speak | Speak |
| `technical.exercisePrimitives.primitiveInk.title` | Ink | Ink |
| `technical.exercisePrimitives.primitiveSubmit.title` | Submit | Submit |
| `technical.exercisePrimitives.primitivePresentation.title` | Presentation | Presentation |
| `technical.exercisePrimitives.primitiveOptions.title` | Primitive options | Opzioni delle primitive |
| `technical.exercisePrimitives.layouts.title` | Layouts | Layout |
| `technical.exercisePrimitives.evaluationModes.title` | Evaluation modes | Modalità di valutazione |
| `technical.exercisePrimitives.promptAndItemMedia.title` | Prompt and Item media | Media di Prompt e Item |
| `technical.exercisePrimitives.presentationContent.title` | Presentation Content | Presentation Content |
| `technical.exercisePrimitives.presets.title` | Presets as recipes | Preset come ricette |
| `technical.exercisePrimitives.canonicalEditor.title` | The canonical editor | L’editor canonico |
| `technical.jsonStructure.title` | JSON data structure | Struttura dati JSON |
| `technical.jsonStructure.status.title` | Status | Stato |
| `technical.jsonStructure.root.title` | Root | Radice |
| `technical.jsonStructure.guidebook.title` | Guidebook | GuideBook |
| `technical.jsonStructure.lessonAndRound.title` | Lesson and Round | Lesson e Round |
| `technical.jsonStructure.exerciseContent.title` | Exercise Content | Exercise Content |
| `technical.jsonStructure.duel.title` | Duel | Duel |
| `technical.jsonStructure.compatibility.title` | Compatibility | Compatibilità |

### 6.7 Editor Help: the questions (91 texts, 3 languages)

Each question has an answer, translated as well (counted in 6.9).

| Key | English | Italian |
|---|---|---|
| `editorHelp.qa.accessModes.q` | What do Locked, View only, Inspection mode and Edit do? | Che cosa fanno Locked, View only, Inspection mode ed Edit? |
| `editorHelp.qa.whyNoEdit.q` | Why can't I choose Edit? | Perché non posso scegliere Edit? |
| `editorHelp.qa.viewOnlyNotice.q` | Why does a notice appear the first time I open a Course in View only? | Perché compare un avviso la prima volta che apro un Course in View only? |
| `editorHelp.qa.structure.q` | How is a Course organized? | Come è organizzato un Course? |
| `editorHelp.qa.courseWizard.q` | How does the Course Wizard work? | Come funziona il Course Wizard? |
| `editorHelp.qa.search.q` | How do I find an exercise? | Come trovo un esercizio? |
| `editorHelp.qa.internalIds.q` | How do I see the internal IDs? | Come vedo gli ID interni? |
| `editorHelp.qa.findHelp.q` | Where do I find Help while editing? | Dove trovo l’Help mentre modifico? |
| `editorHelp.qa.workingCopy.q` | When are my changes saved? | Quando vengono salvate le mie modifiche? |
| `editorHelp.qa.saveOrDraft.q` | What is the difference between Apply and Apply as draft? | Che differenza c’è tra Apply e Apply as draft? |
| `editorHelp.qa.provisionalDraft.q` | Why is a new Lesson or Round a Draft although I never chose it? | Perché una Lesson o un Round nuovi sono Draft anche se non l’ho mai scelto? |
| `editorHelp.qa.leaveEditor.q` | What happens when I leave the Course Editor? | Che cosa succede quando esco dal Course Editor? |
| `editorHelp.qa.leaveExercise.q` | What happens if I leave an exercise without saving? | Che cosa succede se lascio un esercizio senza salvare? |
| `editorHelp.qa.publishCourse.q` | How do I make a Course available to learners? | Come rendo un Course disponibile agli studenti? |
| `editorHelp.qa.backups.q` | Where are the earlier versions kept? | Dove sono conservate le versioni precedenti? |
| `editorHelp.qa.restore.q` | How do I go back to an earlier version? | Come torno a una versione precedente? |
| `editorHelp.qa.privateCourse.q` | What is a Private course? | Che cos’è un Private course? |
| `editorHelp.qa.courseLanguages.q` | How do I choose the Course languages? | Come scelgo le lingue del Course? |
| `editorHelp.qa.courseKind.q` | Same language or another language: which Course should I make? | Nella stessa lingua o attraverso un’altra: quale Course creare? |
| `editorHelp.qa.courseInfo.q` | Where do I change the Course name and description? | Dove cambio il nome e la descrizione del Course? |
| `editorHelp.qa.license.q` | Which license can I choose? | Quale licenza posso scegliere? |
| `editorHelp.qa.authors.q` | How do I credit authors and rights holders? | Come do credito ad autori e titolari dei diritti? |
| `editorHelp.qa.mediaCredits.q` | How do I credit pictures and recordings made by others? | Come do credito a immagini e registrazioni fatte da altri? |
| `editorHelp.qa.cover.q` | How do I give the Course a cover picture? | Come do al Course un’immagine di copertina? |
| `editorHelp.qa.flag.q` | How do I choose the Course flag? | Come scelgo la bandiera del Course? |
| `editorHelp.qa.customFlag.q` | How do I use my own flag? | Come uso una bandiera mia? |
| `editorHelp.qa.lessonOptions.q` | Where are Use GuideBook, Word Lookup, Create Duels and the label options? | Dove sono Use GuideBook, Word Lookup, Create Duels e le opzioni per le etichette? |
| `editorHelp.qa.labelsAndNumbering.q` | How do Lesson label and numbering and Round label and numbering work? | Come funzionano Lesson label and numbering e Round label and numbering? |
| `editorHelp.qa.sections.q` | How do I group Lessons into Sections? | Come raggruppo le Lesson in Section? |
| `editorHelp.qa.lessonIcon.q` | How do I choose a Lesson icon? | Come scelgo l’icona di una Lesson? |
| `editorHelp.qa.whoMayEdit.q` | Who may edit a Course? | Chi può modificare un Course? |
| `editorHelp.qa.roundTypeContract.q` | What does a Round type control? | Che cosa controlla il tipo di Round? |
| `editorHelp.qa.discover.q` | When should I use Discover? | Quando uso Discover? |
| `editorHelp.qa.practice.q` | When should I use Practice? | Quando uso Practice? |
| `editorHelp.qa.listening.q` | What belongs in a Listen Round? | Che cosa va in un Round Listen? |
| `editorHelp.qa.reading.q` | What belongs in a Read Round? | Che cosa va in un Round Read? |
| `editorHelp.qa.flashcardRound.q` | What is a FlashCard Round? | Che cos’è un Round FlashCard? |
| `editorHelp.qa.testRound.q` | How does a Test work? | Come funziona un Test? |
| `editorHelp.qa.timedRound.q` | How does a Timed Round work? | Come funziona un Round Timed? |
| `editorHelp.qa.speakRound.q` | Can I create a Speak Round? | Posso creare un Round Speak? |
| `editorHelp.qa.roundCompatibility.q` | How are exercises checked against a Round type? | Come vengono controllati gli esercizi? |
| `editorHelp.qa.roundNumbering.q` | How do Round numbers work? | Come funzionano i numeri dei Round? |
| `editorHelp.qa.newRound.q` | How do I add a Round? | Come aggiungo un Round? |
| `editorHelp.qa.beforeYouStart.q` | How do I write the Before you start note of a Round? | Come scrivo la nota Before you start di un Round? |
| `editorHelp.qa.roundWizard.q` | How does the Round Wizard create Rounds? | Come crea i Round il Round Wizard? |
| `editorHelp.qa.sequence.q` | What is a Sequence Round? | Che cos’è un Round Sequence? |
| `editorHelp.qa.story.q` | What is a Story? | Che cos’è una Story? |
| `editorHelp.qa.newStory.q` | How do I build a Story? | Come costruisco una Story? |
| `editorHelp.qa.editStory.q` | How do I change a Story afterwards? | Come modifico una Story in seguito? |
| `editorHelp.qa.characters.q` | Where are the narrator and the characters? | Dove sono il narratore e i personaggi? |
| `editorHelp.qa.guidebook.q` | What goes into a Lesson GuideBook? | Che cosa va nel GuideBook di una Lesson? |
| `editorHelp.qa.guidebookEntries.q` | How do I write GuideBook entries? | Come scrivo le voci del GuideBook? |
| `editorHelp.qa.moduleLength.q` | How long should a module be? | Quanto deve essere lungo un modulo? |
| `editorHelp.qa.wordLookup.q` | How does Word Lookup use the GuideBook vocabulary? | Come usa Word Lookup il vocabolario del GuideBook? |
| `editorHelp.qa.duel.q` | When is a Lesson's Duel available? | Quando è disponibile il Duel di una Lesson? |
| `editorHelp.qa.copyMove.q` | How do I duplicate, copy or move Lessons, Rounds and exercises? | Come duplico, copio o sposto Lesson, Round ed esercizi? |
| `editorHelp.qa.preview.q` | How do I try the Course, a Lesson or a Round as a learner? | Come provo il Course, una Lesson o un Round come uno studente? |
| `editorHelp.qa.newExercise.q` | How do I add an exercise? | Come aggiungo un esercizio? |
| `editorHelp.qa.pageCards.q` | How do I make a textbook-like Page? | Come creo una Page simile a un libro di testo? |
| `editorHelp.qa.presetOrCanonical.q` | What is the difference between a preset and the canonical editor? | Che differenza c’è tra un preset e l’editor canonico? |
| `editorHelp.qa.changeType.q` | Can I change an exercise's type? | Posso cambiare il tipo di un esercizio? |
| `editorHelp.qa.exerciseWizard.q` | How does the Exercise Wizard work? | Come funziona l’Exercise Wizard? |
| `editorHelp.qa.previewExercise.q` | How do I preview an exercise? | Come vedo l’anteprima di un esercizio? |
| `editorHelp.qa.inspection.q` | What does Inspection show? | Che cosa mostra Inspection? |
| `editorHelp.qa.navigate.q` | How do I move between exercises? | Come passo da un esercizio all’altro? |
| `editorHelp.qa.fieldHelp.q` | What does the Help button beside a field explain? | Che cosa spiega il pulsante Help accanto a un campo? |
| `editorHelp.qa.editorNotes.q` | What are Editor notes? | Che cosa sono le Editor notes? |
| `editorHelp.qa.manyAnswers.q` | How do I accept several typed answers? | Come accetto più risposte digitate? |
| `editorHelp.qa.capitals.q` | Do capitals matter in answers built from blocks? | Le maiuscole contano nelle risposte composte con i blocchi? |
| `editorHelp.qa.distractors.q` | How many extra blocks may I add? | Quanti blocchi in più posso aggiungere? |
| `editorHelp.qa.difficulty.q` | What do the difficulty bars mean? | Che cosa indicano le barre di difficoltà? |
| `editorHelp.qa.firstLetter.q` | What does Show the first letter do in Type the missing word? | Che cosa fa Show the first letter in Type the missing word? |
| `editorHelp.qa.readAndAnswer.q` | How do I write a Read and answer exercise? | Come scrivo un esercizio Read and answer? |
| `editorHelp.qa.pictures.q` | Which exercises use a picture? | Quali esercizi usano un’immagine? |
| `editorHelp.qa.allTypes.q` | Where is every exercise type explained? | Dove è spiegato ogni tipo di esercizio? |
| `editorHelp.qa.audioModes.q` | Which audio modes can a Course use? | Quali modalità audio può usare un Course? |
| `editorHelp.qa.addRecordings.q` | How do I add recordings? | Come aggiungo delle registrazioni? |
| `editorHelp.qa.textsToRecord.q` | Which texts still need a recording? | Quali testi hanno ancora bisogno di una registrazione? |
| `editorHelp.qa.recordingsTravel.q` | Do recordings travel with the Course? | Le registrazioni viaggiano con il Course? |
| `editorHelp.qa.addPictures.q` | How do I add pictures to a Course? | Come aggiungo immagini a un Course? |
| `editorHelp.qa.findPicture.q` | How do I find a picture? | Come trovo un’immagine? |
| `editorHelp.qa.pictureBadges.q` | What do the badges on a picture mean? | Che cosa significano i badge su un’immagine? |
| `editorHelp.qa.pictureRules.q` | Which pictures does QQL accept? | Quali immagini accetta QQL? |
| `editorHelp.qa.imageBank.q` | What is an Image Bank? | Che cos’è un Image Bank? |
| `editorHelp.qa.pictureDetails.q` | How do I see a picture's details? | Come vedo i dettagli di un’immagine? |
| `editorHelp.qa.removePicture.q` | How do I remove a picture from a Course? | Come tolgo un’immagine da un Course? |
| `editorHelp.qa.runAudit.q` | How do I check a Course? | Come controllo un Course? |
| `editorHelp.qa.severities.q` | What is the difference between an Error, a Warning and Info? | Che differenza c’è tra Error, Warning e Info? |
| `editorHelp.qa.borders.q` | What do the red and green borders and the blue badge mean? | Che cosa significano i bordi rossi e verdi e il badge blu? |
| `editorHelp.qa.auditCodes.q` | Where are all the Audit codes listed? | Dove sono elencati tutti i codici dell’Audit? |
| `editorHelp.qa.auditLimits.q` | Does the Audit check grammar or translations? | L’Audit controlla la grammatica o le traduzioni? |

### 6.8 Help: short texts of the pages (21 texts, 3 languages)

Search boxes, group names, small buttons and notes of the Help pages.

| Key | English | Italian |
|---|---|---|
| `editorHelp.qa.searchLabel` | Search the questions | Cerca tra le domande |
| `editorHelp.qa.noResults` | No question matches your search. | Nessuna domanda corrisponde alla ricerca. |
| `courseStudioHelp.courseTypes.contact` | For bundled distribution or approval as an external publisher, contact the QQL team. The publisher signing guide explains the approval procedure. | Per la distribuzione insieme all’app o l’approvazione come editore esterno, contatta il team QQL. La guida sulle firme descrive la procedura di approvazione. |
| `appInfo.pathColours.enlarge` | Enlarge the picture | Ingrandisci l'immagine |
| `appInfo.pathColours.picture` | The eight Lesson colours in the light and the dark theme: a Round not completed, a completed Round and the word Completed. | Gli otto colori delle Lesson nel tema chiaro e in quello scuro: un Round non completato, un Round completato e la parola Completed. |
| `appInfo.betaExpiry.active` | This is a time-limited beta build. It expires on {expiryDate}. After expiry, learner exercises and Review are blocked until a newer beta is installed. Local progress, courses, course edits and settings are not deleted, and Course Editor remains available. | Questa è una beta a tempo. Scade il {expiryDate}. Dopo quella data gli esercizi e Review restano bloccati finché non installi una beta più recente. Progressi, corsi, modifiche ai corsi e impostazioni non vengono cancellati, e il Course Editor resta utilizzabile. |
| `appInfo.betaExpiry.inactive` | This is not a time-limited beta build. | Questa non è una beta a tempo. |
| `appInfo.creditsButton` | App and image credits | App and image credits |
| `allCoursesHelp.allCoursesPageTitle` | All Courses — Help | All Courses — Guida |
| `allCoursesHelp.courseLibraryPageTitle` | Course Library — Help | Course Library — Guida |
| `exerciseHelp.search` | Search Exercise Help | Search Exercise Help |
| `exerciseHelp.clearSearch` | Clear search | Clear search |
| `exerciseHelp.noResults` | No Exercise Help results match your search. | Nessun risultato in Exercise Help corrisponde alla ricerca. |
| `exerciseHelp.category.vocabulary` | Vocabulary | Vocabulary |
| `exerciseHelp.category.grammarAndSentences` | Grammar and sentences | Grammar and sentences |
| `exerciseHelp.category.listening` | Listening | Listening |
| `exerciseHelp.category.readingAndDialogue` | Reading and dialogue | Reading and dialogue |
| `exerciseHelp.category.picturesAndCharacters` | Pictures and characters | Pictures and characters |
| `exerciseHelp.category.cardsAndNotes` | Cards and notes | Cards and notes |
| `exerciseHelp.category.comingLater` | Coming later | Coming later |
| `exerciseHelp.comingLater` | In a later version: | In una versione futura: |

### 6.9 Help: the long texts (3 languages, not listed)

Answers, section bodies, the description of each exercise type and the Help of each form field. They are complete in English, Italian and Spanish.

| Part of Help | Long texts |
|---|---|
| Exercise Help, Exercise primitives Help and the field Help of the exercise forms | 203 |
| Editor Help | 106 |
| Course Studio Help | 54 |
| Advanced (Admin) Help | 43 |
| Technical reference | 33 |
| App Info | 21 |
| Publisher signing guide | 14 |
| All Courses Help and Course Library Help | 11 |
| The field Help of the GuideBook module page | 9 |
| Debug Help | 3 |
| Total | 497 |

### 6.10 The start page (27 texts, 3 languages)

Added in Build 272 Revision 17. `{count}` is a number and `{folderCourseImports}` the folder of Quick Import on the device.

| Key | English | Italian |
|---|---|---|
| `title` | Start here | Comincia da qui |
| `intro` | QuisquisLingo comes with no Course inside: you bring the Courses. Import one that someone made, or make your own. | QuisquisLingo non contiene nessun corso: i corsi li porti tu. Importane uno fatto da altri, oppure creane uno tuo. |
| `waiting.one` | You have 1 Course, but it cannot be studied yet: a Course must be Published before it can be studied, and a Publisher Course also needs its publisher verified. To publish a Course of your own, open it from Course Studio and choose Publish. | Hai 1 corso, ma non si può ancora studiare: un corso va pubblicato (Published) prima di poterlo studiare, e un Publisher Course richiede anche la verifica del suo editore. Per pubblicare un tuo corso, aprilo da Course Studio e scegli Publish. |
| `waiting.many` | You have {count} Courses, but none can be studied yet: a Course must be Published before it can be studied, and a Publisher Course also needs its publisher verified. To publish a Course of your own, open it from Course Studio and choose Publish. | Hai {count} corsi, ma nessuno si può ancora studiare: un corso va pubblicato (Published) prima di poterlo studiare, e un Publisher Course richiede anche la verifica del suo editore. Per pubblicare un tuo corso, aprilo da Course Studio e scegli Publish. |
| `where.title` | Where do Courses come from? | Da dove arrivano i corsi? |
| `where.body` | A Course is a file: a .zip package, or a .json file when it has no pictures or recordings of its own. Whoever made it gives it to you: a friend, a teacher, your Team, a publisher. It can reach you by e-mail or chat, on a USB stick or through a shared folder. QuisquisLingo has no shop and downloads no Course by itself: save the file on this device, then import it. | Un corso è un file: un pacchetto .zip, oppure un file .json quando non ha immagini o registrazioni proprie. Te lo dà chi lo ha creato: un amico, un insegnante, il tuo Team, un editore. Può arrivarti per e-mail o in chat, su una chiavetta USB o in una cartella condivisa. QuisquisLingo non ha un negozio e non scarica corsi da solo: salva il file su questo dispositivo, poi importalo. |
| `where.friend` | A friend | Un amico |
| `where.teacher` | A teacher | Un insegnante |
| `where.publisher` | A publisher | Un editore |
| `import.title` | Import a Course | Importare un corso |
| `import.step1` | Save the Course file on this device, for example in Downloads. | Salva il file del corso su questo dispositivo, per esempio in Download. |
| `import.step2` | Tap Import a Course below. | Tocca Import a Course qui sotto. |
| `import.step3` | Tap Open from… and choose the file. Or use Quick Import: it reads a file named import.zip (import.json for a .json file) from {folderCourseImports}. | Tocca Open from… e scegli il file. Oppure usa Quick Import: legge un file chiamato import.zip (import.json per un file .json) nella cartella {folderCourseImports}. |
| `import.step4` | QuisquisLingo checks the file, shows what it found and asks before it adds the Course. Once imported, a Published Course can be studied at once. | QuisquisLingo controlla il file, mostra che cosa ha trovato e chiede conferma prima di aggiungere il corso. Dopo l’importazione, un corso pubblicato (Published) si può studiare subito. |
| `create.title` | Make your own Course | Creare un tuo corso |
| `create.body` | Courses are written in Course Studio, with the Course Editor. Both stay hidden until you turn them on for your profile. | I corsi si scrivono in Course Studio, con il Course Editor. Tutti e due restano nascosti finché non li attivi per il tuo profilo. |
| `create.step1` | Open Settings: the gear at the top of this page. | Apri Settings: l’ingranaggio in alto in questa pagina. |
| `create.step2` | Tap Version and Build ten times, until QuisquisLingo says Course Studio unlocked. | Tocca Version and Build dieci volte, finché QuisquisLingo non dice Course Studio unlocked. |
| `create.step3` | Come back here and tap New Course. The Course Wizard asks for the two languages and a title, then guides you through Lessons, GuideBooks and Rounds. | Torna qui e tocca New Course. Il Course Wizard chiede le due lingue e un titolo, poi ti guida tra Lesson, GuideBook e Round. |
| `create.step4` | To change a Course later, open Course Studio and tap the Course: the Course Editor opens. Switch its access state to Edit to make changes. | Per modificare un corso in seguito, apri Course Studio e tocca il corso: si apre il Course Editor. Per fare modifiche, porta il suo stato di accesso su Edit. |
| `create.step5` | A new Course is a Draft and cannot be studied yet. Publish it (the Course Wizard’s last step, or Publish in the Course Editor): then it appears here, ready to study. | Un corso nuovo è un Draft e non si può ancora studiare. Pubblicalo (l’ultimo passo del Course Wizard, oppure Publish nel Course Editor): allora compare qui, pronto da studiare. |
| `create.on` | Course Studio is on for your profile. | Course Studio è attivo per il tuo profilo. |
| `create.off` | Course Studio is off for your profile: follow steps 1 and 2 first. | Course Studio non è attivo per il tuo profilo: segui prima i passi 1 e 2. |
| `device.title` | Courses already on this device | Corsi già presenti su questo dispositivo |
| `device.some.one` | This device already has 1 Course you can study that is not among your courses. Open All Courses and choose Add to my courses: no file is needed. | Su questo dispositivo c’è già 1 corso che puoi studiare e che non è tra i tuoi. Apri All Courses e scegli Add to my courses: non serve nessun file. |
| `device.some.many` | This device already has {count} Courses you can study that are not among your courses. Open All Courses and choose Add to my courses: no file is needed. | Su questo dispositivo ci sono già {count} corsi che puoi studiare e che non sono tra i tuoi. Apri All Courses e scegli Add to my courses: non serve nessun file. |
| `device.none` | All Courses lists the Courses of this device. When another learner of this device makes or imports one, you can add it to your courses there, without a file. Right now there is none to add and study. | All Courses elenca i corsi di questo dispositivo. Quando un altro studente di questo dispositivo ne crea o ne importa uno, lì puoi aggiungerlo ai tuoi, senza file. Per ora non ce n’è nessuno da aggiungere e studiare. |

## 7. For the future project

Not decided, only noted, so that the next person starts from the facts:

- Whether the names of section 3 stay English for ever or get an official translation in each language. Today they are proper names.
- "Course", the Round's own repetition and the Laurel (section 4).
- The capitals of the English texts ("Finish round" beside "Termina il Round").
- The app interface, which is English only.
- A review by native speakers of the six AI-written translations.
- Help in German, Portuguese, Dutch and French, which the texts around an exercise already have.
