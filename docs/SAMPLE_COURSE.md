# Bundled sample courses

Updated for version 2.0.20+220.

QuisquisLingo currently bundles eight Course Model v4 sample courses: Italian, German, Spanish, Welsh, Dutch, Portuguese and Finnish from English, plus English from Spanish. Every bundled course contains nine deterministically ordered Topics with two Rounds per Topic. Topic and Round IDs remain stable, Topic titles are written in the course source language, and the course-level `temporarySample` flag marks the material as temporary development/demo content that can be progressively replaced by reviewed content from the course creators.

The bundled courses use `formatVersion: 4`. Every Topic contains its own structured Guidebook, ordered Rounds and stable Duel identity. The first Content item of Round 1 is a short non-exercise `topic_intro` containing essential information drawn from that Topic Guidebook and a reminder to read the Topic Guidebook for more. Topic images are used where appropriate. Each current Topic has 10 or 11 actual Duel-eligible exercises, so its 25-question Duel is normally unavailable; this is supported behavior for the temporary samples, not a validation error. The build-time course validator must report all eight bundled course JSON files as OK.

## Audio Match

Audio Match presents three independently playable target-language sounds and exactly three matching texts, with no distractors. The same spoken item or visible match must not be repeated inside one Audio Match. Course Audit reports duplicates as errors.

## Word Blocks

The learner builds the correct sentence and may leave zero, one or at most two distractor blocks unused. The Check button becomes available when the number of selected blocks equals the number required by the correct sentence, not when every available block has been selected.

## Flat image library

The editor can assign, change or remove an optional image on any exercise. Choose from the bundled verified flat WebP assets or import a custom PNG/JPG/WebP. Built-in assets are referenced by path and are not duplicated when reused. Sample courses use images only where they support the task without revealing an answer.
