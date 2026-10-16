# Build 275 validation

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
