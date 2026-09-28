# Build 254 Exercise Laboratory coverage

This document and the JSON are generated together by `tools/generate_exercise_laboratory_254.py`. Run its `--check` mode to detect drift. The current repository model, editor and learner are the source of truth; the Course does not add a new primitive or engine feature.

- Course: **Exercise Laboratory**, `course_50d68435-d2c2-4b63-9a0b-b23161357f1d`.
- Direction: English (`en-GB`) → Italian (`it-IT`); TTS `it-IT`.
- Model 11, official Course version 1.0.0; all Lessons, Rounds and Content are Published.
- Exactly six Lessons (five primitives and a Story), 26 Rounds and 122 runnable examples across all 46 authoring presets.
- Course rights explicitly allow Fork, so the bundled original can be inspected and a derivative can use the ordinary authoring/confirm/export/import paths.
- Create Duels is off: Presentation is non-evaluable and the Course is not padded to manufacture Duel pools. The required per-Lesson Duel metadata is retained.
- This Course leaves existing Course identities, learner data and media assets unchanged.

## Source inventory and supported modes

The authoring registry is `lib/models/exercise_authoring.dart`. Every one of its 46 presets has at least one example below.

| Lesson | Preset | Examples |
| --- | --- | ---: |
| Select | `choice` | 5 |
| Select | `gap_choice` | 1 |
| Select | `gap_choice_inline` | 4 |
| Select | `icon_choice` | 2 |
| Select | `script_recognition` | 3 |
| Select | `reading_comprehension` | 1 |
| Select | `dialogue_response` | 1 |
| Select | `contextual_comprehension` | 6 |
| Select | `listening_choice` | 1 |
| Select | `listening_comprehension` | 1 |
| Select | `translation_choice_to_target` | 2 |
| Select | `translation_choice_to_source` | 2 |
| Select | `choice_source` | 2 |
| Select | `true_false` | 3 |
| Select | `listening_answer_source` | 1 |
| Select | `reading_answer_source` | 1 |
| Select | `picture_choice` | 1 |
| Select | `listening_image_choice` | 1 |
| Input | `type_translation` | 10 |
| Input | `fill_blank` | 3 |
| Input | `type_missing_word` | 3 |
| Input | `listening_spelling` | 3 |
| Input | `missing_word` | 2 |
| Input | `type_translation_to_source` | 2 |
| Input | `complete_text` | 1 |
| Input | `missing_letters` | 2 |
| Input | `picture_name` | 1 |
| Arrange | `word_order` | 6 |
| Arrange | `gap_blocks` | 6 |
| Arrange | `build_translation` | 4 |
| Arrange | `image_word` | 3 |
| Arrange | `build_translation_to_source` | 2 |
| Arrange | `sentence_order` | 2 |
| Arrange | `spell_heard` | 2 |
| Arrange | `spell_word` | 2 |
| Match | `matching` | 2 |
| Match | `word_match` | 1 |
| Match | `super_match` | 2 |
| Match | `picture_word_match` | 1 |
| Match | `audio_match` | 1 |
| Presentation | `flashcard` | 6 |
| Presentation | `picture_flashcard` | 2 |
| Presentation | `note_card` | 2 |
| Story | `true_false` | 3 |
| Story | `word_order` | 6 |
| Story | `story_cover` | 2 |
| Story | `dialogue_line` | 10 |
| Story | `choice_target` | 1 |

## Case matrix and answer keys

The suffix below follows `qql_lab254_` in the stable Content/Exercise ID. Answer positions are deliberately not used as keys: Select and Match shuffle displayed options. Expression answers are examples of accepted variants, not necessarily their exhaustive expansion.

| Lesson / Round | ID suffix | Preset | Capability | Correct response |
| --- | --- | --- | --- | --- |
| Select / Single and multiple answers | select_single | choice | Single selection; two text options; immediate feedback | grazie |
| Select / Single and multiple answers | select_image_prompt | choice | Single selection with a supplementary prompt image | la mela |
| Select / Single and multiple answers | select_multiple | choice | Multiple selection; exact correct set; minimum equals two correct answers | rosso + blu |
| Select / Single and multiple answers | select_minimum | choice | Multiple selection; minimum one permits partial submission but only the exact two-answer set is correct | gatto + cane |
| Select / Single and multiple answers | select_one_in_multi | choice | Multiple-selection presentation with one correct answer and an explicit Check | sì |
| Select / Fixed sentences and reusable choices | select_gap_preset | gap_choice | Fill in the blank preset; one ___ gap and non-revealing hint | dorme |
| Select / Fixed sentences and reusable choices | select_gap_one | gap_choice_inline | Inline Select; one gap; zero distractors | giorno |
| Select / Fixed sentences and reusable choices | select_gap_distinct | gap_choice_inline | Inline Select; two distinct options; one distractor | è / casa |
| Select / Fixed sentences and reusable choices | select_gap_reuse | gap_choice_inline | Inline Select; one reusable option assigned to two gaps; two distractors | è / è |
| Select / Fixed sentences and reusable choices | select_gap_audio | gap_choice_inline | Inline Select with optional spoken prompt | bevo / acqua |
| Select / Images and written characters | select_named_icons | icon_choice | Select the image; existing named icon vocabulary | sole |
| Select / Images and written characters | select_asset_options | icon_choice | Select the image; actual bundled image options | gatto |
| Select / Images and written characters | script_image_text | script_recognition | Recognize characters; one portable image to text | A |
| Select / Images and written characters | script_multiple_images | script_recognition | Recognize characters; two visual specimens of the same character to text | E |
| Select / Images and written characters | script_text_image | script_recognition | Recognize characters; text to image-only options; Italian accented character | Image È |
| Select / Reading and conversations | select_reading | reading_comprehension | Reading comprehension; passage plus separate question | In autobus. |
| Select / Reading and conversations | select_dialogue | dialogue_response | Dialogue response; exactly two alternatives | Sì, grazie. |
| Select / Reading and conversations | context_text | contextual_comprehension | Contextual comprehension; Text mode | Alle nove. |
| Select / Reading and conversations | context_dialogue | contextual_comprehension | Contextual comprehension; structured dialogue without prose context | Vicino al parco. |
| Select / Reading and conversations | context_text_dialogue_image | contextual_comprehension | Contextual comprehension; text, structured dialogue and supplementary image | Una mela. |
| Select / Listening and context | select_listening_word | listening_choice | What do you hear; audio prompt and written answers | Buongiorno. |
| Select / Listening and context | select_listening_passage | listening_comprehension | Listen and choose; passage audio and separate question | Al mercato. |
| Select / Listening and context | context_audio | contextual_comprehension | Contextual comprehension; Audio mode | Dal binario tre. |
| Select / Listening and context | context_text_audio | contextual_comprehension | Contextual comprehension; Text and audio mode | Un libro. |
| Select / Listening and context | context_all | contextual_comprehension | Contextual comprehension; text, audio, structured dialogue and image together | Senza zucchero. |
| Select / Two translation directions | translation_target_two | translation_choice_to_target | Pick translation to target; minimum two answers; no image | Buongiorno. |
| Select / Two translation directions | translation_target_five | translation_choice_to_target | Pick translation to target; maximum five answers; optional image | Il gatto dorme. |
| Select / Two translation directions | translation_source_two | translation_choice_to_source | Pick translation to source; minimum two answers; no image | Thank you. |
| Select / Two translation directions | translation_source_five | translation_choice_to_source | Pick translation to source; maximum five answers; optional image | The apple is red. |
| Select / Source-language answers, pictures and true or false | choice_source_meaning | choice_source | Choose the answer (to source); question and answers in the source language | thank you |
| Select / Source-language answers, pictures and true or false | choice_source_culture | choice_source | Choose the answer (to source); a culture question | From the afternoon on |
| Select / Source-language answers, pictures and true or false | true_false_true | true_false | True or false; a true statement, answers in the source language | True |
| Select / Source-language answers, pictures and true or false | true_false_spoken | true_false | True or false; a spoken false statement | False |
| Select / Source-language answers, pictures and true or false | listening_source | listening_answer_source | Listen and answer (to source); answers in the source language | Thank you very much |
| Select / Source-language answers, pictures and true or false | reading_source | reading_answer_source | Read and answer (to source); question and answers in the source language | By bus |
| Select / Source-language answers, pictures and true or false | picture_choice | picture_choice | What is in the picture; picture prompt, text answers | la mela |
| Select / Source-language answers, pictures and true or false | listening_image | listening_image_choice | Listen and pick the image; captioned picture answers | il gatto |
| Input / Translations and accepted variants | input_literal | type_translation | One literal accepted translation | grazie |
| Input / Translations and accepted variants | input_explicit | type_translation | Multiple explicit accepted translations and ranked feedback | ciao / salve / buongiorno |
| Input / Translations and accepted variants | input_optional | type_translation | Optional subject with {...} | mangio una mela / io mangio una mela |
| Input / Translations and accepted variants | input_alternatives | type_translation | Independent [a\|b] groups; four grammatical variants | il bambino è felice; il bimbo è contento; both other noun/adjective combinations |
| Input / Translations and accepted variants | input_linked | type_translation | Linked [*:a\|b] groups preserve grammatical agreement | il maestro è stanco / la maestra è stanca |
| Input / Flexible wording and written detail | input_reorder | type_translation | Whole-answer reorder with <>; proper name retained | domani vado a Roma / vado a Roma domani |
| Input / Flexible wording and written detail | input_scoped | type_translation | Scoped reorder inside fixed text | studio a casa la sera / studio la sera a casa |
| Input / Flexible wording and written detail | input_combined | type_translation | Optional wording plus independent alternative; separate reordered expression | compro pane e latte oggi / io acquisto pane e latte oggi / oggi compro pane e latte |
| Input / Flexible wording and written detail | input_accents | type_translation | Apostrophe, Italian accent and final punctuation; non-revealing hint | l'acqua è fredda. |
| Input / Flexible wording and written detail | input_repeat_letter | type_translation | Repeated-letter tolerance applies only to the established Input presets | il gatto è piccolo; one omitted/duplicated repeated letter is tolerated by existing evaluation |
| Input / Fragments and first letters | input_fragment | fill_blank | Type a missing word; fragment answer without audio | sera |
| Input / Fragments and first letters | input_fragment_audio | fill_blank | Type a missing word; audio supplements the clue and accepts a literal full phrase | giorno / buongiorno |
| Input / Fragments and first letters | input_gap_variants | fill_blank | Type a missing word; accepted-answer expression | felice / contento |
| Input / Fragments and first letters | input_first_letter | type_missing_word | Type the missing word; one ___ gap and full accepted word | gatto |
| Input / Fragments and first letters | input_first_alternatives | type_missing_word | Type the missing word; multiple complete words sharing the first grapheme | cane / cavallo |
| Input / Fragments and first letters | input_first_unicode | type_missing_word | Type the missing word; accented first Unicode grapheme and proper names | Émile / Étienne |
| Input / Transcriptions and missing words | input_listen_word | listening_spelling | Type what you hear; one word | grazie |
| Input / Transcriptions and missing words | input_listen_sentence | listening_spelling | Type what you hear; complete sentence and normal punctuation handling | il treno parte alle nove |
| Input / Transcriptions and missing words | input_listen_variants | listening_spelling | Type what you hear; more than one explicitly accepted transcription | sono felice / io sono felice |
| Input / Transcriptions and missing words | input_missing_one | missing_word | Listen for missing words; one transcript gap | mela |
| Input / Transcriptions and missing words | input_missing_many | missing_word | Listen for missing words; three distinct gaps in transcript order | 1 legge; 2 libro; 3 giardino |
| Input / Source answers, texts and pictures | type_source_literal | type_translation_to_source | Type the translation (to source); target text, source answers | thank you / thanks |
| Input / Source answers, texts and pictures | type_source_variants | type_translation_to_source | Type the translation (to source); two accepted answers | I would like a coffee / I'd like a coffee |
| Input / Source answers, texts and pictures | complete_text | complete_text | Complete the text; two typed gaps, no audio | caffè / treno |
| Input / Source answers, texts and pictures | missing_letters | missing_letters | Missing letters; letters inside two words | tt / van |
| Input / Source answers, texts and pictures | missing_letters_audio | missing_letters | Missing letters; spoken text and two gaps | ren / ove |
| Input / Source answers, texts and pictures | picture_name | picture_name | Name what you see; picture prompt, typed answers | il pane / pane |
| Arrange / Word and phrase blocks | arrange_zero | word_order | Word order; zero distractors | Il gatto dorme |
| Arrange / Word and phrase blocks | arrange_one | word_order | Word order; one distractor | Anna beve acqua |
| Arrange / Word and phrase blocks | arrange_two | word_order | Word order; two distinct target-language distractors | Il treno parte oggi |
| Arrange / Word and phrase blocks | arrange_repeat | word_order | Word order; repeated visible words use separate block occurrences | Anna mangia pane e Luca mangia riso |
| Arrange / Word and phrase blocks | arrange_phrases | word_order | Word order; multiword phrase blocks | Vado a scuola in autobus |
| Arrange / Fixed sentences and consumed blocks | arrange_gap_one | gap_blocks | Inline Arrange; one gap; no distractors | dorme |
| Arrange / Fixed sentences and consumed blocks | arrange_gap_many | gap_blocks | Inline Arrange; two gaps; one distractor | beve / acqua |
| Arrange / Fixed sentences and consumed blocks | arrange_gap_repeat | gap_blocks | Inline Arrange; repeated text requires distinct tile IDs; two distractors | è / è |
| Arrange / Fixed sentences and consumed blocks | arrange_gap_audio | gap_blocks | Inline Arrange; phrase blocks and spoken prompt | a scuola / in autobus |
| Arrange / Build translations | build_single | build_translation | Build translation; one literal answer and no distractors | Bevo acqua |
| Arrange / Build translations | build_multiple | build_translation | Build translation; multiple valid orders with optional subject; one block unused by every answer | mangio pane / Io mangio pane |
| Arrange / Build translations | build_phrase | build_translation | Build translation; phrase blocks and two distractors | Vado a scuola in treno |
| Arrange / Build translations | build_repeat | build_translation | Build translation; repeated word occurrences | Anna beve acqua e Luca beve latte |
| Arrange / Build translations | build_gap | gap_blocks | Build translation; inline gaps with one distractor | legge / libro |
| Arrange / Build translations | build_gap_audio | gap_blocks | Build translation; inline gaps and spoken prompt | beviamo / acqua |
| Arrange / Letters and syllables | image_letters | image_word | Image-prompt ordering; individual letter blocks | mela |
| Arrange / Letters and syllables | image_syllables | image_word | Image-prompt ordering; syllable blocks | gatto |
| Arrange / Letters and syllables | image_repeated_letters | image_word | Image-prompt ordering; repeated individual letters | banana |
| Arrange / Source blocks, sentences and spelling | build_source_single | build_translation_to_source | Build the translation (to source); target text, source blocks | I drink water |
| Arrange / Source blocks, sentences and spelling | build_source_distractor | build_translation_to_source | Build the translation (to source); one unused block | I go to school by train |
| Arrange / Source blocks, sentences and spelling | sentence_order_story | sentence_order | Put the sentences in order; three lines of a story | Anna entra nel bar. Ordina un caffè. Paga e saluta. |
| Arrange / Source blocks, sentences and spelling | sentence_order_dialogue | sentence_order | Put the sentences in order; four turns of a dialogue | Buongiorno, un caffè per favore. Subito. Zucchero? No, grazie. Ecco a lei. |
| Arrange / Source blocks, sentences and spelling | spell_heard_letters | spell_heard | Spell what you hear; letter tiles, no picture | pane |
| Arrange / Source blocks, sentences and spelling | spell_heard_syllables | spell_heard | Spell what you hear; syllable tiles | gatto |
| Arrange / Source blocks, sentences and spelling | spell_word_clue | spell_word | Spell the word; a source-language clue and letter tiles | gatto |
| Arrange / Source blocks, sentences and spelling | spell_word_definition | spell_word | Spell the word; a definition and syllable tiles | acqua |
| Match / Words, meanings and relationships | match_single | matching | Match the pairs; smallest supported one-pair form | ciao = hello |
| Match / Words, meanings and relationships | match_four | matching | Match the pairs; variable four-pair form with phrases | a domani = see you tomorrow; per favore = please; buon viaggio = have a good trip; a presto = see you soon |
| Match / Words, meanings and relationships | match_words | word_match | Match the words; exactly three source-to-target pairs | water = acqua; bread = pane; book = libro |
| Match / Words, meanings and relationships | match_synonyms | super_match | Match related words; exactly three target-language synonym pairs | felice = contento; veloce = rapido; grande = ampio |
| Match / Pictures and words | picture_word_match | picture_word_match | Match picture to word; picture left items | cat = il gatto; dog = il cane; house = la casa |
| Match / Listen and match | match_sounds | audio_match | Listen and match; three audio-to-text pairs with distinct sound and answer labels | acqua = water; pane = bread; libro = book |
| Match / Opposites | match_opposites | super_match | Match related words; exactly three target-language opposite pairs | caldo = freddo; alto = basso; aperto = chiuso |
| Presentation / Cards without pronunciation | card_minimal | flashcard | Term and meaning only; no usage or pronunciation | Got it; or Review again, then Got it on the repeated card |
| Presentation / Cards without pronunciation | card_usage | flashcard | Term, meaning and usage; no translation or pronunciation | Got it; or Review again, then Got it on the repeated card |
| Presentation / Cards without pronunciation | card_usage_translation | flashcard | Term, meaning, usage and usage translation; no pronunciation | Got it; or Review again, then Got it on the repeated card |
| Presentation / Cards with pronunciation | card_audio | flashcard | Term and meaning with pronunciation; no usage | Got it; or Review again, then Got it on the repeated card |
| Presentation / Cards with pronunciation | card_audio_usage | flashcard | Term, meaning, pronunciation and usage; no usage translation | Got it; or Review again, then Got it on the repeated card |
| Presentation / Cards with pronunciation | card_complete | flashcard | Term, meaning, pronunciation, usage and usage translation | Got it; or Review again, then Got it on the repeated card |
| Presentation / Picture flashcards and note cards | picture_card | picture_flashcard | Picture flashcard; picture, usage, translation and optional pronunciation | Got it; or Review again, then Got it on the repeated card |
| Presentation / Picture flashcards and note cards | picture_card_plain | picture_flashcard | Picture flashcard; picture, term and meaning only | Got it; or Review again, then Got it on the repeated card |
| Presentation / Picture flashcards and note cards | note_card_tip | note_card | Note card; a usage tip | Got it; or Review again, then Got it on the repeated card |
| Presentation / Picture flashcards and note cards | note_card_grammar | note_card | Note card; a grammar note | Got it; or Review again, then Got it on the repeated card |
| Story / A morning in Turin | story_cover | story_cover | Story cover; a bundled picture and a title line under the Story title | Continue |
| Story / A morning in Turin | story_narrator | dialogue_line | Dialogue line; the narrator in the source language, text and audio | Continue |
| Story / A morning in Turin | story_anna_order | dialogue_line | Dialogue line; a character in the target language, text and audio | Continue |
| Story / A morning in Turin | story_luca_offer | dialogue_line | Dialogue line; a character, text and audio | Continue |
| Story / A morning in Turin | story_choice | choice_target | Choose the answer between the lines of a Story | Un caffè |
| Story / A morning in Turin | story_anna_no | dialogue_line | Dialogue line; a character declines | Continue |
| Story / A morning in Turin | story_luca_serves | dialogue_line | Dialogue line; a character serves | Continue |
| Story / A morning in Turin | story_true_false | true_false | True or false between the lines of a Story; needs the Story's audio, so Audio Exercises off skips it | False |
| Story / A morning in Turin | story_order | word_order | Word order closing a Story | Un caffè, per favore. |
| Story / The same morning, line by line | options_cover | story_cover | Story cover of a Story without exercises | Continue |
| Story / The same morning, line by line | options_narrator | dialogue_line | Dialogue line; the narrator, text and audio, read on request as the Story says | Continue |
| Story / The same morning, line by line | options_after_audio | dialogue_line | Dialogue line; text shown after listening | Continue |
| Story / The same morning, line by line | options_text_only | dialogue_line | Dialogue line; text only | Continue |
| Story / The same morning, line by line | options_audio_only | dialogue_line | Dialogue line; audio only, read on request | Continue |
| Story / The same morning, line by line | options_automatic | dialogue_line | Dialogue line; read aloud automatically although the Story reads on request | Continue |

## Boundaries and intentionally excluded combinations

- Select single-answer questions check immediately. Choose multiple selection uses exact set equality: its minimum count controls whether Check is enabled, not how many answers are correct. Minimum counts above the correct-set size would make a valid response impossible and are excluded.
- Choose inline gaps and multiple selection are mutually exclusive authoring modes. Inline Select reuses an option in separate gaps; each tap fills one gap. Inline Arrange consumes an occurrence and therefore needs separate IDs for repeated words. Each mode demonstrates zero, one and two distractors; no more than two are allowed.
- Pick the translation has exactly one correct answer, two to five distinct text options, no inline gaps, no multiple selection, and no authored spoken prompt. Its optional target-language pronunciation never makes it an audio-dependent exercise.
- Recognize characters is Select in both directions. Image to text has one or more prompt images and text-only options; Text to image has a text prompt and image-only options. A/E/È specimens are original deterministic 160×160 PNGs embedded in the Course, below 50 KB each. They do not claim handwriting recognition, OCR or speech recognition. No new Image Bank entries are installed.
- Select the image uses the renderer's supported named icons and existing bundled image paths. Arbitrary Course-owned or embedded image options are not claimed for that legacy icon preset; portable image-only options are exercised by Recognize characters.
- Input uses the editor's normal case/punctuation/whitespace normalization with accents preserved. Answer expressions have a hard 128-result limit. The examples demonstrate literal lines, optional text, independent and linked alternatives, scoped/whole reorder, and combinations. Invalid syntax, zero-result/overflow expansions, arbitrary normalization settings and unexposed input modes are not learner exercises.
- Type the missing word expects a complete word whose first Unicode grapheme is shared by all accepted alternatives. It is not an Input-style character-recognition direction. Listen for missing words uses distinct complete transcript words in displayed order.
- Build the translation records literal complete answers and distinct block occurrences; expressions, typo tolerance and similarity-ranked acceptance do not apply. Word order and Image-prompt ordering each expose one correct authored order. Image-prompt ordering has no distractors.
- Match the pairs supports a variable count; the three named specialised Match presets require exactly three pairs. Images as matching operands and arbitrary many-to-many relationships are not exposed by the current authoring/learner paths.
- Flashcard coverage includes all six meaningful combinations of optional audio, usage, and usage translation (a translation requires usage). The learner buttons currently read Got it / Review again; JSON completion actions remain understood / review_later. Cards are non-evaluable and earn no correct-answer base XP. Optional omissions produce existing informational/warning Audit findings, not invalid content.
- Flashcard image content is excluded: the current Presentation↔Exercise projection does not preserve images on an authoring round trip. Rich textual explanation/example/vocabulary/text/dialogue kinds share the presentation path but are not additional current Exercise picker presets. GuideBook explanations and Round introductions demonstrate explanatory text through their normal authoring surfaces.
- Audio mode is On-Device TTS. Every spoken prompt is authored Italian, uses it-IT and needs an available native voice. Learner Enable Audio Exercises and Text-to-speech must be on to include every audio example; Authoring Preview ignores the learner switches. No recording transcript was guessed and no voice or MP3 is fabricated. Course audio modes and recorded-media transport are independent of the exercise primitive and covered by the separate Edge Cases Course.
- Existing bundled pictures remain references to the app's Image Bank; the four distinct character PNG payloads travel inside Course JSON. No absolute local file paths or missing media placeholders are used.

## Verification seams

1. `python -X utf8 tools/generate_exercise_laboratory_254.py --check`: deterministic JSON/checksum and coverage-document readback.
2. `python -X utf8 tools/validate_courses.py`: Course Model structure, timestamps, stable unique IDs, references, publication and official checksum.
3. `test/exercise_laboratory_254_test.dart` checks the actual asset's Audit and canonical model round trip, then rebuilds all 122 examples through ExerciseDraftBuilder (and ScriptRecognitionController for its image modes), comparing semantic fields and each result's model round trip. Separate preservation assertions cover Flashcard usage and usage translation. Editor route tests include `exercise_authoring_252_characterization_test.dart`, `select_editor_238_test.dart`, `arrange_gap_fill_editor_238_test.dart`, `script_recognition_226_03_test.dart` and `translation_choice_239_test.dart`.
4. The same Lab suite completes all 122 examples through RoundScreen Preview using actual controls and grading, including repeated blocks, reusable gaps, exact multiple-selection sets and audio matching. Additional cases finish an alternate Build translation answer and a Review again/Got it cycle. Speech is stubbed only at the playback seam; these tests do not establish native voice quality or normal progression persistence.
5. Export/import of the Course through the normal ZIP and embedded-image JSON routes preserves this Course's identity, content wrappers, answers and character PNG bytes. A Fork gets a new identity through the existing rights-aware operation.

These are verification seams, not a claim that commands have been run. Fresh integrated results are recorded in the Build 254 validation document.
