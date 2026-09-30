# Build 259 validation

Plan: `CONTEXT_AND_HINT_PLAN.md`; change summary: `259_CHANGE_SUMMARY.md`;
handoff: `259_HANDOFF.md`.

## Revision 0 (2.0.59+259000, 30 September 2026): instructions and questions

**Generators and validator**
- Laboratory: 8 Lessons, 28 Rounds, 124 examples, `--check` reproducible.
- Piedmontese: 39 Lessons, 117 examples, `--check` reproducible.
- Edge Case: `--check` unchanged.
- v11 converter fixtures (`test/fixtures/v11/exercise_laboratory_en_it.json`,
  `piedmontais_en.json`) are written from `course_v11()` /
  `build_course_v11()` with their checksum (the method verified against
  the previous fixtures' checksums).
- `tools/validate_courses.py`: all three Courses pass after the Laboratory
  Lesson count was corrected to 8. It had failed on `main` since Build 258
  Revision 3.

**Laboratory presentation baseline**
- Record run (`QQL_RECORD_PRESENTATION`): 124 records, rebuilt into
  `test/support/laboratory_presentation_254.dart` and formatted.
- Compared record by record with the previous baseline: 87 unchanged and
  37 changed. Every change is deliberate:
  - **Instruction line replaced by the authored instruction** (the prompt
    line disappears): Word order (5), Drag the blocks into the gaps (6,
    including the two meanings "Anna reads a book." and "We drink
    water."), Spell the word in the picture (3), Type what you hear (2),
    Recognize characters image to text (2), Put the sentences in order
    (2), Listen and match (1), the story's word order (1).
  - **The Choose examples ask in their question** (5): the standard
    "Choose the correct answer." returns and the question moves to the
    body.
  - **Recognize characters text to image** asks in its question (1).
  - **The instruction is now visible** where it had not been shown at
    all: What is in the picture, Type what you see and Name what you see
    (3, "What is this?"), and the four Assign examples (4).
  - **Match by meaning's instructions are in English** (2).

**Tests**
- New: `test/instructions_and_questions_259_test.dart`, 36 tests:
  - the rule (instruction, material, standard line, the two spelling
    presets, Type what you see, an Assign);
  - the six fields that became Instruction or context (stored as
    `primary`, represented by their preset, field keys and title);
  - Choose the answer (to source) leaves its instruction unmarked;
  - a Published save refuses every required question or sentence, and
    the form shows the message;
  - the form's helper quotes the standard line;
  - Recognize characters (question, controller, Audit);
  - the Duel line appears with audio only.
- Updated to the new labels and roles: the field Help tests and the
  inventory of every form, the editor workflow and route tests, the
  wizard, the Choose editor fixture (a question is never optional), the
  Assign and Name what you see tests, and Match by meaning's English
  instruction.
- Focused batch of the 44 files that touch the change, first run before
  the test updates: 772 passed, 111 failed, all on old labels, old roles
  and the baseline. After the updates, the 18 failing files, the
  Laboratory test and the version and Help tests were rerun and pass; the
  complete suite covers the rest.
- `flutter analyze --no-pub`: no issues.
- **First complete suite** (10:13–10:53, `--concurrency=1`, keep-awake
  wrapper): 3377 passed, 1 skipped, 2 failed.
  - `fill_blank_hint_226_04_r1_test` pinned the old Pick the missing word
    helper text; it now expects the new one.
  - `authoring_hierarchy_indicators_226_02_test` failed to save because
    the longer helper made the form taller: its scroll step left Save
    8 pixels below the 1,200-pixel test window, so the tap missed (the
    log's hit-test warning). The helper now calls `ensureVisible` before
    tapping. The app itself was correct.

  Both files pass after the fix.
- **Second complete suite** (10:56–11:33, `--concurrency=1`, keep-awake
  wrapper): **3379 passed, 1 skipped, 0 failed**.
