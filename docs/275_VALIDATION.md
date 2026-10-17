# Build 275 validation

## Revision 3 (2.0.75+275003), meanings and the Wizard's first step

- New tests: `test/same_language_meanings_275_test.dart`, **9 passed**: for
  each of the six translation presets, the meaning heard only in a
  same-language Course and the word side heard alike in both kinds,
  nothing before the answer; Pick the word says its meaning, Pick the
  meaning its right meaning; the Audio Library's texts and a recording's
  uses count the meanings of a same-language Course only; a meaning's
  words looked up only in a same-language Course (a word in both); on the
  Round screen, Pick the word's meaning with its speaker and as a
  `LookupText` in a same-language Course, no speaker for it in a
  translation Course, and Pick the meaning's word plain text; an option
  word marked as the source language heard only in a same-language
  Course; after the answer, in a learner's Round with audio off, the two
  speakers and the note once; the lookup proved with a GuideBook entry
  inside the meaning. In `test/same_language_courses_275_test.dart`,
  Continue with Wizard's question (Cancel stays on the editable first
  step; Continue goes on and the first step is read-only) and Continue by
  hand, which never asks. `test/same_language_learner_275_test.dart`
  checks the new lines in English and Italian. The three files run six
  times clean after the last change (43 tests each run).
- Run with them: `playback_on_request_274_test`, `audio_usage_270_test`,
  `audio_library_271_test`, `word_lookup_ui_265_test`,
  `word_lookup_265_test`, `exercise_mascot_256_test`,
  `owner_review_263_revision0_test` (the first-word rule in the seven
  catalogs), `exercise_laboratory_254_test` (the presentation baseline: a
  translation Course unchanged), `learner_panel_260_test`,
  `course_languages_260_test`, `course_wizard_267_test`,
  `wizard_wording_267_test`: all passed.
- Independent read-only review: nothing blocking. Corrected: after an
  answer a same-language Course showed two speakers with one key and the
  audio-off note twice (the answer's speaker is now
  `translation-choice-answer-audio`, the note shown once); the Round
  screen test now proves the lookup with a GuideBook entry inside the
  meaning (and none in a translation Course); new tests of option words,
  of the two speakers after an answer, and that Continue by hand never
  asks; the Italian, Spanish and Portuguese Type the meaning lines no
  longer repeat their title ("Inserisci che cosa significa.", "Introduce
  qué significa.", "Introduza o que significa."); the Texts in this
  Course Help sentence; the Course Wizard Help names the question; doc
  comments; the renumbering in AGENTS and the handoff; the key's name in
  the documents; "learners of a translation Course see no change". Told to
  the owner: a Course of synonyms paired both ways can show the answer in
  a meaning's lookup. Its re-review of the corrections: right, nothing
  blocking; its points corrected: the note test ran in the Preview, where
  audio is always on (now a learner's Round with audio off, the note
  exactly once), the test counts, the question word (the longest, never
  an article). Left: the speakers' note keys off `PlaybackOnRequest`
  while the prompt block draws under `_promptShown` (equal in practice).
- `flutter analyze`: no issues, on the final tree.
- Complete suite on the final tree (`flutter test --concurrency=1`):
  **4,958 passed, 1 skipped**, 51 minutes.

## Revision 2 (2.0.75+275002), the creator's choice is stored

- `test/same_language_courses_275_test.dart`, **23 passed**: the kind
  stored, read back and absent from a translation Course's file; the same
  two languages without the choice a translation Course; a strict field
  (a string or `null` refused); `identicalChoices` (one language twice,
  capitals, accents and `_` ignored; any other name or tag accepted, also
  a hand-typed name with a tag on one side only); the minimum build
  stamped once and not raised for a translation Course; a real save through
  `CourseEditorService` stores the kind with `minimumAppBuild` 275002 and
  reads them back; a Merge of two kinds refused in both orders; Copy as New
  Course and a copied Round keep the kind; the Wizard refuses one language
  twice and goes on with English (UK) and English (US); New Course's form
  stores the kind chosen and none for two variants; Course Info's line
  follows the stored kind. `test/same_language_learner_275_test.dart`,
  **9 passed**, its Courses made In the same language;
  `new_course_form_272_test` expects no kind for prefilled languages
  without one. The two files run six times clean after the last change
  (32 tests each run).
- Independent read-only review: nothing blocking. Corrected: the Merge
  refused two kinds in one order only (`sameLanguage` is written only when
  true, and the comparison looped over the left Course's fields): an
  explicit refusal now comes first, tested both ways; the Help names the
  tag of each variant (en-GB, en-US) for the device's voice and the flag,
  and the English sentence on variants reads plainly; two comments still
  said the kind comes from the languages; New Course's form still picked a
  kind for two prefilled languages without one (`_kindOfLanguages`
  removed); `tools/validate_courses.py` refuses `sameLanguage: true` with
  two language names; the plan asks Revision 4's file for
  `minimumAppBuild` 275002 (an import does not stamp it); the numbering
  in the handoff and the 275000 entry; the tests above (null, the real
  save, the Merge, the hand-typed tag). Left as agreed: the same
  hand-typed name with a tag on one side only is two languages (the rule
  word for word); a hand-edited file with the flag and two languages reads
  as the file says. Its re-review of the corrections: right, nothing
  blocking; its last points (the plan's Revision 2 section, the Italian
  and Spanish clause on In the same language, a comment's wrapping) were
  corrected.
- `flutter analyze`: no issues, on the final tree.
- Complete suite on the final tree (`flutter test --concurrency=1`):
  **4,947 passed, 1 skipped**, 48 minutes.

## Revision 1 (2.0.75+275001), what learners read

- New tests: `test/same_language_learner_275_test.dart`, **9 passed**, the
  file run six times clean after its last change: every new text in the
  seven catalogs, each title and its line keeping Build 263's first-word
  rule; the seven same-language names; in an English to English Course
  holding the Laboratory's Lessons, each translation preset's title and
  line (both directions), the translation Course's differing; the Italian
  catalog in an Italian to Italian Course; every other preset unchanged
  and never saying "translation"; the feedback and Word Lookup texts; the
  Round Wizard's Build prompt in both kinds of Course; a Round on screen
  with the new title and line (the Duel and Review read the same service,
  `instructionForExercise` and `LearnerPanelText.of`, and are covered by
  that one switch, not by a widget test of their own). The Laboratory's
  presentation baseline (`exercise_laboratory_254_test`, 255 passed) shows
  a translation Course unchanged.
- Run with them: `course_languages_260_test`, `difficulty_bonus_260_test`,
  `exercise_titles_261_test`, `imported_course_v6_regression_test`,
  `labels_in_english_271_test`, `learner_panel_260_test`,
  `owner_review_263_revision0_test`, `two_sided_flashcards_268_test`,
  `same_language_courses_275_test`: all passed.
- Independent read-only review: nothing blocking. Corrected: the Round
  Wizard's Build prompt said "Build the translation of …" in a
  same-language Course; the French "Sélectionne le bon sens." (the idiom
  for common sense) is "Sélectionne le sens correct."; the typing verbs
  follow each catalog (Inserisci, Introduce, Saisis, Introduza instead of
  Digita, Teclea, Tape, Digite); the Dutch titles read TYP; the screen
  reader counts "correct answers"; the documents. Left for the owner (in
  the handoff): "word" also labels a sentence; the Flashcard line names
  the language. Its re-review of the corrections found nothing in the
  code or the catalogs; its two document points were corrected.
- `flutter analyze`: no issues, on the final tree.
- Complete suite on the final tree (`flutter test --concurrency=1`):
  **4,944 passed, 1 skipped**, 41 minutes.

## Revision 0 (2.0.75+275000), choosing the kind of Course

The owner's decisions of 16 October 2026.

- New tests: `test/same_language_courses_275_test.dart`, **20 passed**,
  the file run six times clean after its last change: the rule's table of
  tags (es/es, en/en-US, en-GB/en-US, sr-Latn/sr-Cyrl, sr-Latn/sr-RS,
  zh-Hant/zh-Hans, en/it, capitals and underscores) both ways round; names
  typed by hand, names of a listed language ("Français" and "French"), two
  variants typed by hand with their tags; a Course's kind from its stored
  languages (both English,
  a region on one side, two variants, Italian, a language by hand); a
  form's two languages; the Wizard: neither kind chosen at first and
  Continue saying so, In the same language with one field written on both
  sides (through Continue by hand, and through Continue with Wizard, read
  back on the Course's first step), Through another language refusing one
  language twice, Fill with an example following the kind (also on a
  resumed Wizard, from the Course's languages), the later
  steps' examples, the kind shown once the Course exists, Which should I
  choose? opening the answer; New Course's form prefilled In the same
  language making a same-language Course, refusing one language twice,
  writing what the field shows after a kind is switched, and saying when no
  kind is chosen; Course Info's line for a same-language Course only; the Help
  question in its topic, in the three languages, named by the two answers
  that point to it.
- Changed: the tests that create a Course by hand choose its kind first
  (`course_wizard_267_test`, `wizard_wording_267_test`,
  `new_course_form_272_test`, `new_course_dialog_272_test`,
  `course_credits_272_test`, `course_creation_flags_226_04_test`,
  `new_course_structure_226_04_test`, `provisional_mytest_workflow_test`,
  `course_editor_layout_regression_test`); `wizard_wording_267_test` reads
  the first step's new line; `editor_help_qa_256_test` and
  `editor_help_translation_test` count 91 questions. Run with
  `no_bundled_course_272_r17_test`: all passed.
- Independent read-only review: nothing blocking. Corrected: Fill with an
  example on a resumed Wizard gave a same-language Course the other kind's
  example; the Course Wizard's and the Course languages' Help still spoke
  of Source and Target only and of one sample Course; nothing said how to
  make a Course between two variants (the list holds languages, so
  English and American English were refused as one language twice: the
  refusal and the Help now say to type each variant by hand with its
  tag); a side stored without a tag now takes its listed language's tag
  ("Français" and "French"); a field the kind hides no longer counts as
  content; the cards are a radio group for screen readers; the Italian
  question is plainer ("quale Course creare?"); the localization
  document's counts; the plan's line on Continue by hand; four more tests.
  Not tested: the Course Info Editor's line (the same `if` on the same
  owner as Course Info's, which is tested). Known and left: the rule edges
  in the handoff; the FAQ describes the finished Build. The re-review of
  the corrections found one more fault: Course Info's Add the language
  tags from the list could still change a Course's kind (a tag chosen
  for a language typed by hand, or one that drops a region another field
  held); it is now refused (`CourseInfoUpdateService.keepsKind`, with a
  test), and the rule edge it found with tags typed by hand is an owner
  point in the handoff. Its last check found nothing; not tested: that
  `apply` refuses with `kindChangeRefusal` and that Add the language tags
  keeps the earlier tags (both one call of the tested `keepsKind`).
- `flutter analyze`: no issues, on the final tree.
- Complete suite on the final tree (`flutter test --concurrency=1`):
  **4,935 passed, 1 skipped**, 41 minutes.
