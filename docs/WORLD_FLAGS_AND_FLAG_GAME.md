# Learner identity, world flags and Flag Game

Updated for QuisquisLingo 2.0.34+234000 on 13 September 2026.

## Stable learner identity

Every new local learner has an opaque UUIDv4 `learnerProfileId` generated from `Random.secure`, plus a presentation-only `displayName`. The ID is stable, is never derived from the name and is the sole identity used by learner-scoped persistence. Duplicate display names are allowed; the UI uses each learner's existing avatar as the primary visual distinction while the internal IDs remain separate.

`ProfileService` owns authoritative key construction. Learner data uses `learner_<learnerProfileId>_<key>`, the registry is `learner_profiles_v2`, and the active learner is stored in `active_learner_profile_id`. With no active learner, learner-scoped writes fail or use the normal no-active flow; no `learner_default_` namespace is created. Exact ID namespaces make deletion independent of display-name prefixes.

Build 222 is a deliberate clean cut. It does not read, migrate, copy or fall back to the former display-name registry, active-name key or name-derived learner namespaces. Old values may remain physically present but are inert to the new architecture.

Learner backups use schema version 2 and contain the source `learnerProfileId`, `displayName` and learner-data map. Restore/preserve identity recreates the exact ID when absent. If that ID already exists, the learner must explicitly Replace existing, Import as separate copy, or Cancel; Replace clears the exact current namespace before restoring and never silently merges. Separate copy is always available, generates a new UUIDv4, asks for a validated display name prefilled with the source name, copies data into the new namespace and rewrites only structured Flag Game score-record identity fields. It does not broadly replace text inside backup content.

## Dataset and provenance

The additive dataset lives in `assets/world_flags/`. Its canonical `manifest.json` has 276 English-named entities: 193 UN Members, 56 other ISO 3166-1 entities, eight Shortlist entries and nineteen language-related community/regional entries. Gameplay pools, reference categories and the World Flag choices/suggestions in the shared Course flag picker derive from these canonical records. The older built-in `flagCode` namespace remains a separate compatibility surface.

Lists were retrieved or verified on 13 September 2026:

- UN Members authority: <https://www.un.org/en/about-us/member-states>
- ISO 3166-1 authority: <https://www.iso.org/obp/ui/#iso:code:3166>
- Machine-readable ISO name/code cross-check maintained against ISO changes: <https://www.ripe.net/community/internet-governance/internet-technical-community/the-rir-system/list-of-country-codes-and-rirs/>

Flag SVGs come from `lipis/flag-icons` v7.5.0, pinned at commit `7aa5b2bdddd570ece62c812c0cb588ccdc099e2e`: <https://github.com/lipis/flag-icons/tree/v7.5.0>. They are redistributed under the MIT license copied to `assets/world_flags/LICENSE-flag-icons.txt`. ISO and UN pages establish entity lists; they are not treated as artwork licenses.

The nineteen language-related SVGs come from individually recorded Wikimedia Commons file pages. QQL 234 adds Esperanto, Amazigh, Ladin, Asturian, Sicilian, Aragonese, Livonian, West Frisian, Piedmontese and Neapolitan associations to the previous nine. Aragonese, Friulian and Sardinian use CC BY-SA 3.0 with named attribution, Corsican uses CC0 1.0, and the other entries are declared Public Domain. Deterministic renderer-compatible markup normalization is limited to the new Aragonese, Livonian, Piedmontese, Sicilian and West Frisian assets; source and bundled SHA-1 values are recorded separately for those five. The historical Cornish, Corsican and Sardinian SVGs retain their baseline bytes and SHA-1 values. Exact source pages, authors, licenses and checksums are stored both on each manifest entity and in `assets/world_flags/LICENSE-language-related-flags.md`. These entries are modeled as `communityOrRegionalFlagAssociatedWithLanguage`; QQL does not describe them as universally official language flags.

Language-to-flag suggestions are explicit ordered manifest records. Matching normalizes case and underscore-separated BCP-47 tags, checks a complete tag before its base tag, and can match only the language names declared in the manifest. Regional/community artwork ranks before a related country flag where both are explicitly listed; an unknown language produces no inferred suggestion.

Antarctica is included as the ISO `AQ` entity and uses the `aq.svg` representation supplied by that pinned flag-icons release. This is a consistent game/reference representation, not a claim that Antarctica has an official sovereign national flag.

The generator is `tools/generate_world_flags.py`. It requires exactly 249 ISO rows, validates IDs and canonical English names for uniqueness, validates suggestion tags, names and ordered flag references, copies every referenced asset and emits manifest counts/source metadata. It does not modify legacy course assets or mappings.

The pinned United States and United States Minor Outlying Islands SVG sources use `marker-mid` for their 50 stars. During dataset generation, QQL expands the same source star path at the same 50 coordinates because Flutter's current SVG compiler does not render marker constructs. The 4:3 proportions, stripes, canton, canonical identities, dataset memberships, source artwork and MIT provenance remain unchanged.

## Pools and references

The four cumulative gameplay pools are:

1. UN: the 193 United Nations Member States.
2. UN + ISO: all 249 ISO 3166-1 entities.
3. UN + ISO + Shortlist: ISO plus England, Scotland, Wales, Kosovo, Northern Ireland, Catalonia, Basque Country and Galicia (257).
4. All Flags: the previous pool plus the nineteen language-related community/regional entries (276).

The four read-only reference sections are non-overlapping layers: UN Members, ISO extras (the 56 ISO entities that are not UN Members), Shortlist, and Language-related flags. Each view is alphabetized by canonical English name, includes its own compact explanation, and supports live case-insensitive search over canonical English names and existing aliases. Search is scoped to the open category and cannot change game state or learner progress.

Legacy built-in course flags are frozen and separate: course `CY` continues to mean Wales, course `EN` keeps its established English/UK meaning, and ISO `CY`/`GB` in the world manifest mean Cyprus/United Kingdom. QQL 234 adds the independent Course Model v9 `worldFlagId` choice through the shared picker while preserving existing `flagCode` and portable `flagImageBase64` behavior, priority and rendering.

## Flag Game

Five taps or mouse clicks within three seconds on the Settings title and subtle generic outlined-flag hint play the existing suspense sound and open Flag Game. The flag icon has the exact `Tap tap... Flag Game` tooltip and waves gently while the mouse hovers over it; one to four taps still do nothing, stale sequences reset, and Close/Back naturally returns to Settings.

A game uses one of the four cumulative pools, selects 12 unique targets and gives five distinct English answers per question. Seedable/injectable randomness makes target and correct-answer positions testable. A fresh game avoids intentionally repeating the immediately previous exact target order when the pool allows it.

Distractors always come from the selected pool. Candidates are randomly shuffled before being ranked by shared color, geographic/RIR or regional metadata, giving variety among plausible candidates. Explicit symmetric `avoidAsDistractorWith` metadata prevents Romania/Chad, Monaco/Indonesia, Ireland/Côte d'Ivoire, Mali/Guinea and Netherlands/Luxembourg from being deliberate distractor pairs.

Elapsed time starts in a post-frame callback only after question one is visible and ends after question 12. The existing QQL sound service plays victory for a correct answer and defeat for a wrong answer. Immediate feedback appears in a reserved line directly below the flag: `Correct` for a correct choice, or `Correct answer: <canonical English name>` after an error. Correct answers advance after 800 ms (up from 700 ms); the wrong-answer delay remains 700 ms. Results show `X / 12`, elapsed time, Play again and Close; 12/12 receives a special congratulations state. No result awards XP, Weekly XP, streak, Laurel, Round/Lesson progress, Review or Duel credit.

## Local scorecards

Flag Game stores at most one best record per `learnerProfileId` and stable mode name (`unMembers`, `iso`, `isoPlusShortlist`, `allFlags`). Each record contains score, elapsed milliseconds and `achievedAt`. A candidate replaces the learner's previous record only when it ranks better by score descending, elapsed time ascending, then achievement time ascending; an equally scored/equally timed newer record does not replace the earlier one.

All four scorecard sections are always displayed and each lists at most five device-local learner profiles. Ranking uses the same score/time/date ordering. Each dense existing row shows its best record as `score/12 · elapsed s · DD Mon YYYY`, where the date is that record's `achievedAt`; card padding and row count are unchanged. Duplicate display names remain separate ID-keyed entries and retain their avatars. There is no network leaderboard or account service.
