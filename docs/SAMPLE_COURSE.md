# Bundled sample courses

Updated for the first controlled version 2.0.25+225 tranche.

QuisquisLingo currently bundles eight Course Model v5 sample courses: Italian, German, Spanish, Welsh, Dutch, Portuguese and Finnish from English, plus English from Spanish. Every bundled course contains nine deterministically ordered Lessons. In the first build-225 tranche, only Italian was regenerated: each Italian Lesson now has four Rounds, while every other bundled course remains byte-for-byte outside this change with two Rounds per Lesson. Existing semantic Lesson, Round and Exercise IDs are preserved; new Italian practice items use deterministic new IDs. Lesson titles are written in the course source language, and the course-level `temporarySample` flag marks the material as temporary development/demo content that can be progressively replaced by reviewed content from the course creators.

The bundled courses use `formatVersion: 5`. Every Lesson contains its own structured Guidebook, ordered Rounds and stable Duel identity. The first Content item of Round 1 is a short non-exercise `lesson_intro` containing essential information drawn from that Lesson Guidebook and a reminder to read the Lesson Guidebook for more. Every bundled Lesson has valid Section metadata and one icon from the canonical Lesson theme-icon registry; the obsolete decorative Lesson image field is absent. Italian Lessons now have 26 or 27 actual Duel-eligible exercises and therefore meet the 25-question threshold. The seven unchanged samples retain 10 or 11 eligible exercises per Lesson, so their Duels remain normally unavailable; this is supported temporary-sample behavior and is outside this tranche. The build-time course validator must report all eight bundled course JSON files as OK.

The v5 regeneration gives the nine Lessons of each source-English course the consecutive groups `Foundations`, `Everyday Life` and `Travel`; `english_es.json` uses `Fundamentos`, `Vida cotidiana` and `Viajes`. Their icons follow the reusable Conversation, Family, School, Food, Home, Café/Coffee, Directions/Map, Train and Airport/Travel sequence. The Italian sample demonstrates meaningful Round 1 titles with `Greetings and introductions`, `Ordering food` and `At the railway station`; placeholder `Round 2` titles remain present to cover both title styles. Stable pre-v5 opaque Lesson/Round/Content/Item IDs and their references are retained unchanged so existing progress and source references are not orphaned.

## Audio Match

Audio Match presents three independently playable target-language sounds and exactly three matching texts, with no distractors. The same spoken item or visible match must not be repeated inside one Audio Match. Course Audit reports duplicates as errors.

## Word Blocks

The learner builds the correct sentence and may leave zero, one or at most two distractor blocks unused. The Check button becomes available when the number of selected blocks equals the number required by the correct sentence, not when every available block has been selected.

## Flat image library

The editor can assign, change or remove an optional image on any exercise. Choose from the bundled verified flat WebP assets or import a custom PNG/JPG/WebP. Built-in assets are referenced by path and are not duplicated when reused. Sample courses use images only where they support the task without revealing an answer.
