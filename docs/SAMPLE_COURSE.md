# Bundled sample courses

Updated for Version 2.0.29+2293, Build 229 revision 3.

Bundled courses are locally read-only. Their existing content/license metadata remain unchanged and currently provide no explicit derivative-work permission, so custom forks are unavailable.

QuisquisLingo bundles nine deterministic Course Model v7 samples. They are AI-generated, unreviewed demonstrations rather than reliable learning courses. Real QuisquisLingo course content remains intended to be authored and reviewed by humans; this classification does not apply to other official or custom courses. Their exact titles are `AI-Slop Demo: Dutch for English Speakers`, `AI-Slop Demo: Inglés para hispanohablantes`, `AI-Slop Demo: Finnish for English Speakers`, `AI-Slop Demo: German for English Speakers`, `AI-Slop Demo: Italian for English Speakers`, `AI-Slop Demo: Korean for English Speakers`, `AI-Slop Demo: Portuguese for English Speakers`, `AI-Slop Demo: Spanish for English Speakers` and `AI-Slop Demo: Welsh for English Speakers`. Every course contains nine ordered Lessons with four playable Rounds per Lesson. Existing course identities and established semantic IDs are preserved where content already existed; new material uses deterministic globally unique IDs. Lesson titles are written in the course source language, and the course-level `temporarySample` flag marks development/demo content that can be progressively replaced by reviewed material. Course Info presents that guidance; the main Course Editor intentionally does not repeat it. The flag remains part of canonical export and is not changed by unrelated saves.

Every bundled file uses `formatVersion: 7`, required deterministic UTC `updatedAt` values on each Lesson, Round and Exercise, canonical stable Item-ID references, and no compatibility-only fields. Official files omit local custom ownership and remain publisher-owned immutable sources. Every Lesson contains its own structured Guidebook, ordered Rounds and stable Duel identity. The first Content item of Round 1 is a short non-exercise `lesson_intro` containing essential Guidebook information and a reminder to read the Lesson Guidebook for more. Every Lesson has valid Section metadata and a canonical theme icon. Each Lesson has at least 25 actual Duel-eligible exercises, every Round has at least one playable Exercise, and release Audit totals are exactly zero Errors and zero Warnings for all nine courses.

The nine Lessons of each source-English course use the consecutive groups `Foundations`, `Everyday Life` and `Travel`; `english_es.json` uses `Fundamentos`, `Vida cotidiana` and `Viajes`. Korean progresses from Hangul greetings and introductions through family, school, food, home, café language, directions, rail travel and airport/travel language, using polite beginner register and `ko-KR` TTS. Round titles intentionally mix authored names and empty titles so the position-derived `Round N` fallback remains covered without changing identity.

`tools/regenerate_bundled_courses_225_02.py` is the single deterministic generator. Its `--check` mode regenerates in memory and fails if any tracked asset differs. The two former generator entry points delegate to it so they cannot recreate obsolete formats. `tools/validate_courses.py` validates the exact nine-file registry, v7 schema, timestamps, locale/flag metadata, references, global identity, playability and Duel thresholds.

## Audio Match

Audio Match presents three independently playable target-language sounds and exactly three matching texts, with no distractors. The same spoken item or visible match must not be repeated inside one Audio Match. Course Audit reports duplicates as errors.

## Word Blocks

The learner builds the correct sentence and may leave zero, one or at most two distractor blocks unused. The Check button becomes available when the number of selected blocks equals the number required by the correct sentence, not when every available block has been selected.

## Flat image library

The editor can assign, change or remove an optional image on any exercise. Choose from the bundled verified flat WebP assets or import a custom PNG/JPG/WebP. Built-in assets are referenced by path and are not duplicated when reused. Sample courses use images only where they support the task without revealing an answer.
