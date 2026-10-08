# Build 254 handoff

Build 254 Revision 0 is `2.0.54+254000`, dated 2026-09-25 (Europe/Rome).
Beta expiry is `2026-10-25 23:59:59` local time, preserving the 30-day policy.

## Bundled content

The Italian, Finnish and Dutch demonstration Course JSON files have been removed
from the app assets and discovery registry. Seven other bundled Courses retain
their identities and content. The new Courses have independently allocated
`Course.newCourseId()` identities; they do not inherit the removed Courses'
progress. Old progress and reserved official identities are left intact.

| Course | Direction | Structure | Coverage |
| --- | --- | --- | --- |
| Exercise Laboratory | English → Italian | 5 Lessons, 19 Rounds, 80 examples | Select, Input, Arrange, Match, Presentation; all 24 named presets and supported authoring variants |
| AI-Slop Demo: Edge Case Course | Italian → English | 5 Lessons, 10 Rounds, 31 Exercises | Long/Unicode text, repeated options and blocks, gaps, media, GuideBook vocabulary, empty optional fields, Draft ancestry and transfer operations |
| AI-Slop Demo: Piedmontais | English → Piedmontais | 24 Lessons, 24 Rounds, 72 examples | Exactly one current named exercise type per Lesson, with that type in the Lesson title |

The full case matrices, stable IDs and answer keys are in
[Laboratory coverage](254_LABORATORY_COVERAGE.md),
[Edge Case coverage](254_EDGE_CASE_COVERAGE.md), and
[Piedmontais coverage](254_PIEDMONTAIS_COVERAGE.md). Each Course has a dedicated
deterministic generator with a `--check` mode. Do not run the historical v9
regenerator to regenerate these v11 Courses.

All three are temporary AI-generated test content, not reviewed language
curricula. Existing bundled images and recordings are reused; small original
embedded PNGs provide legible character-recognition specimens. Credits identify
the original glyph images. No existing media bytes or integrity hashes change.

## Using the demos

Bundled originals are immutable. Their explicit derivative policy permits
**Fork**; use a personal fork for editing, saving, Copy as New Course, Merge and
ordinary package Import. Exporting an official bundle is supported, but ordinary
Import deliberately refuses to reinstall a bundled original. That restriction
has not changed.

Exercise Laboratory and Piedmontais are Published throughout. Edge Case Course
also contains intentional Draft content. Keep **Show unavailable** enabled in
Courses when inspecting it. Learner projection excludes Draft descendants and
their descendants; Studio, inspection and export must retain the full source.
Ordinary Lesson progression still applies; authoring Preview can run an isolated
case. Primitive/type Lessons do not artificially repeat choice questions to meet
the Duel threshold.

Laboratory uses Italian TTS and Piedmontais uses `pms-IT` TTS. Audio cases depend
on a compatible installed native voice and learner audio settings. Edge Case
Course uses Hybrid with existing MP3 fixtures and separate English TTS fallback
cases; its personal fork can be switched to Recorded MP3 or On-Device TTS to
exercise the mode matrix. The MP3 lookup labels are explicitly fixture labels,
not claimed transcripts. Audible playback and native voice availability remain
device checks.

## Integration corrections

English-target bundles now have separate selection references (`EN` and
`EN_EDGE`). The Course identity decides selection, restart, current-Course Hide
protection, official inspection and Fork source lookup. Language-scoped XP and
streaks continue to use `EN` for both; existing preference keys are unchanged.

The owner-approved Flashcard correction preserves usage sentences and usage
translations when converting canonical Presentation Content to the learner/editor
Exercise view and back. It uses the existing answer-item construction; Course
Model v11, Presentation JSON, scoring and the Course confirmation boundary are
unchanged. Flashcard images remain outside the currently supported round trip.

The active Course's learner projection must not replace the full immutable
bundled source in Course Studio. This matters for the Edge Course's Draft
structures and official checksum. The source-preservation regression checks
Studio loading, export and read-only opening.

## Delivery evidence

Commands, results, intentional Audit warnings and remaining device checks are
recorded in [254_VALIDATION.md](254_VALIDATION.md). The final commit is local;
publishing or pushing is not part of this task.

The owner confirmed **Round Attempt** as the next architecture task. Start from
this completed release and the current code, extracting pure attempt transitions
from `RoundScreen` while retaining persistence and awards in
`LearningCompletionService`. The architecture roadmap's sequence still applies,
but its completion/merge labels lag Builds 250–252. The Laboratory's authoring,
transfer and learner-completion matrix is available as characterization evidence.
