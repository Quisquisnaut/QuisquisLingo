# QuisquisLingo 2.0.23+223 release validation report

Date: 2 September 2026

## Release boundary

- Version: `2.0.23+223`.
- Mandatory 30-day Alpha expiry: end of 2 October 2026.
- Canonical course format: Course Model v5, `Course -> Lesson -> Round -> Exercise/content`.
- Scope: consolidated 223 Lesson-editor navigation, complete preinstalled theme-icon library, Section-block learner navigation, GuideBook refinement, learner-bottom IDDQD relocation, regenerated v5 samples, focused guards, regression validation, and Windows packaging.
- XP, Weekly XP, streak, Review, Duel mechanics, progression rules, learner identity, backup/import behavior, Flag Game, world flags, course flags, TTS, audio, and exercise semantics remain behaviorally unchanged.

## Course Model v5 and persistence

- Active source, services, screens, editor, tests, validators, generators, and canonical JSON now use Lesson terminology. V5 JSON uses root `lessons` and per-Lesson `lessonId`; `topics`, `topicId`, `id`, Chapters, and all non-v5 course formats are rejected rather than migrated or dual-read.
- Existing opaque bundled IDs and references were preserved byte-for-byte even where their historical string values happen to contain lowercase `topic` or `chapter`; changing those values would violate stable identity and progress/reference invariants.
- Lesson metadata adds `section`, canonical nullable `sectionName`, and canonical nullable `themeIconAsset`. A true Section requires a trimmed non-empty name; a false Section rejects a meaningful name and serializes without `sectionName`.
- Section remains consecutive-order presentation metadata only. There is no `sectionId`, Section state/navigation/locking/progress/XP, or persisted `sectionLessonNumber`; relative Lesson numbering is derived from course order and resets at each consecutive visual block.
- Lesson icon paths are controlled catalog references under `assets/lesson_icons/`. The 14 stable registry entries map IDs and author-facing labels to transparent, text-free, flat multicolor 256 x 256 RGBA PNGs with no more than four visible RGB colors; they are not embedded as Base64.
- The obsolete decorative Lesson `imageAsset` field is removed from the v5 model, serialization, editor, validators, generator and bundled samples. The parser rejects it rather than treating it as a theme-icon alias. Exercise images remain separate.
- Clean-cut persistence changes are `v4_completed_topics` to `v4_completed_lessons`, `last_topic_<encodedCourseId>` to `last_lesson_<encodedCourseId>`, and recent-round JSON field `topicId` to `lessonId`. The opaque `v4_recent_rounds` key and other non-semantic `v4_` namespace prefixes remain unchanged. Course Editor storage uses dedicated v5/build-223 keys.
- Learner backup schema remains v2 because its learner-state payload is an opaque key/value `data` map and defines no Topic/Lesson field. Export/restore carries the current suffixes without changing schema, format, UUID identity, collision, or copy behavior.

## Learner and editor behavior

- A Section header appears only before the first Lesson in each consecutive same-name Section block. It is non-card, non-interactive, has no lock/progress, and contributes no widget or spacing when Section metadata is absent.
- Courses with real Sections show one fixed Section selector. Consecutive equal names form one block, unsectioned runs become UI-only `Other lessons` blocks, selection/arrow navigation targets each block's first Lesson, and the most-visible Lesson updates the active block with a 10%-viewport hysteresis rule. Courses without real Sections show no selector and no Section state is persisted.
- Theme and fallback GuideBook icons share one fixed 84 x 84 left slot. Lesson identity remains left-aligned with existing typography and emphasis, now permits at most three lines with ellipsis, and the removed lower `Guidebook`/`Start Here` row is replaced by the exact direct right-side `GuideBook` action.
- The Course Editor provides a `Belongs to a Section` switch, conditionally required Section name, controlled all-registry visual grid with `None`, explicit selection state, and a contained preview. It provides no upload, free-form path, Base64, crop, or resize controls.
- The complete Round-management workflow now lives on one linked Lesson subpage. Lesson metadata and returned Round edits remain draft state until the parent form saves; create/edit/delete/reorder, Exercise access, validation, cancellation and existing IDs are preserved.
- Profile remains the primary learner-bottom action; Review, Course Info and IDDQD are compact 40 x 40 controls. IDDQD applies and persists immediately in its existing opaque-learner-ID plus course-ID namespace, while genuine progress and locks remain authoritative. Settings no longer duplicates the control.
- Every regenerated bundled sample course is v5 and preserves its instructional content and opaque IDs. All Lessons have Section/icon metadata in three consecutive groups; the Italian sample adds the representative Round 1 titles `Greetings and introductions`, `Ordering food` and `At the railway station` while retaining placeholder Round titles elsewhere.
- Empty or omitted Round titles remain valid, serialize without a title field, retain their stable Round IDs, and use a derived `Round N` presentation fallback.

## Automated validation

- Focused Round-subpage, icon-picker, bottom-action, Section navigation and GuideBook responsive tests passed, including light/dark coverage at 320, 375, and 430 logical px.
- Final full suite: `flutter test --no-pub --reporter compact --timeout 60s` passed **406 tests** in **2 minutes 10 seconds**.
- `flutter analyze --no-pub`: **0 errors and 0 warnings**. It reports 81 info-only `curly_braces_in_flow_control_structures` findings in existing unbraced code; none were suppressed or changed as unrelated cleanup.
- `python tools\validate_courses.py`: all **8** bundled v5 courses passed.
- `python tools\validate_lesson_icons.py`: **14 assets, 0 issues**; exact catalog/disk set, PNG structure/CRC/decode, RGBA format, 256 x 256 dimensions, transparency, and the four-color maximum all passed.
- Sample v5 regeneration is idempotent: all eight course SHA-256 values remained unchanged after rerunning the generator.
- A recursive comparison against `HEAD` verified every collected Course/Lesson/Round/Content/item ID and stable reference in all eight sample files; all matched.
- The active-architecture terminology guard passed. Active Dart retains Topic spellings only in the v5 parser's explicit rejection messages/checks; historical prose and stable opaque data values are intentionally excluded.
- `python tools\validate_images.py` reports only the pre-existing missing `assets/exercise_images/hello.webp` among 113 Image Bank assets. It is unrelated to build 223 and remains deliberately unchanged.
- `flutter pub get` passed. `git diff --check` passed. Responsive widget coverage found no overflow or unintended horizontal scrolling. The normal Windows release build passed without changing the desktop resize policy.

## Icon provenance

- `speech_bubbles.png`, `family.png`, `home.png`, `food.png`, `coffee.png`, `shopping.png`, `directions.png`, `airport.png`, `train.png`, `hotel.png`, `work.png`, `school.png`, `time.png`, and `leisure.png` were generated specifically for QuisquisLingo with OpenAI ImageGen through Codex on 2 September 2026, then normalized to the documented asset standard. No third-party source artwork was used. Provenance and redistribution information is recorded in `assets/lesson_icons/LICENSE.md`.

## Windows release artifact

- `tools\package_windows_release.ps1` completed the Windows release build, added the VC runtime, validated staged contents, extracted the ZIP, and matched extracted files against staging.
- Staged directory: `build/packages/quisquislingo_alpha_223_dev_windows_x64/`.
- ZIP: `build/packages/quisquislingo_alpha_223_dev_windows_x64.zip`.
- ZIP size: **25,866,856 bytes**.
- ZIP SHA-256: `CF9FA2A97FB1981EDA87FF3EF0EF644EEF190EF8FB8D7B8D79AAC67A5192748E`.

## Remaining release boundary

The target-machine/manual checks in `docs/WINDOWS_RELEASE_TEST.md` remain the user's final visual and hardware validation boundary. No QQL 224 work was included.
