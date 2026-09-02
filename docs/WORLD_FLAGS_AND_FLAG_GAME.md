# Learner identity, world flags and Flag Game

Updated for QuisquisLingo 2.0.22+222 on 2 September 2026.

## Stable learner identity

Every new local learner has an opaque UUIDv4 `learnerProfileId` generated from `Random.secure`, plus a presentation-only `displayName`. The ID is stable, is never derived from the name and is the sole identity used by learner-scoped persistence. Duplicate display names are allowed; the UI uses each learner's existing avatar as the primary visual distinction while the internal IDs remain separate.

`ProfileService` owns authoritative key construction. Learner data uses `learner_<learnerProfileId>_<key>`, the registry is `learner_profiles_v2`, and the active learner is stored in `active_learner_profile_id`. With no active learner, learner-scoped writes fail or use the normal no-active flow; no `learner_default_` namespace is created. Exact ID namespaces make deletion independent of display-name prefixes.

Build 222 is a deliberate clean cut. It does not read, migrate, copy or fall back to the former display-name registry, active-name key or name-derived learner namespaces. Old values may remain physically present but are inert to the new architecture.

Learner backups use schema version 2 and contain the source `learnerProfileId`, `displayName` and learner-data map. Restore/preserve identity recreates the exact ID when absent. If that ID already exists, the learner must explicitly Replace existing, Import as separate copy, or Cancel; Replace clears the exact current namespace before restoring and never silently merges. Separate copy is always available, generates a new UUIDv4, asks for a validated display name prefilled with the source name, copies data into the new namespace and rewrites only structured Flag Game score-record identity fields. It does not broadly replace text inside backup content.

## Dataset and provenance

The additive dataset lives in `assets/world_flags/` and is independent of QQL course flags. Its canonical `manifest.json` has 266 English-named entities: 193 UN Members, 56 other ISO 3166-1 entities, eight Shortlist entries and nine language-related community/regional entries. Gameplay pools and reference categories are both derived from these canonical records.

Lists were retrieved or verified on 2 September 2026:

- UN Members authority: <https://www.un.org/en/about-us/member-states>
- ISO 3166-1 authority: <https://www.iso.org/obp/ui/#iso:code:3166>
- Machine-readable ISO name/code cross-check maintained against ISO changes: <https://www.ripe.net/community/internet-governance/internet-technical-community/the-rir-system/list-of-country-codes-and-rirs/>

Flag SVGs come from `lipis/flag-icons` v7.5.0, pinned at commit `7aa5b2bdddd570ece62c812c0cb588ccdc099e2e`: <https://github.com/lipis/flag-icons/tree/v7.5.0>. They are redistributed under the MIT license copied to `assets/world_flags/LICENSE-flag-icons.txt`. ISO and UN pages establish entity lists; they are not treated as artwork licenses.

The nine language-related SVGs come from individually recorded Wikimedia Commons file pages. Sámi, Roma, Sorbian, Breton, Occitan and Cornish are declared Public Domain; Corsican is CC0 1.0; Friulian and Sardinian are CC BY-SA 3.0 with named attribution. Exact source pages, authors, licenses and pinned SHA-1 values are stored both on each manifest entity and in `assets/world_flags/LICENSE-language-related-flags.md`. These entries are modeled as `communityOrRegionalFlagAssociatedWithLanguage`; QQL does not describe them as universally official language flags.

Antarctica is included as the ISO `AQ` entity and uses the `aq.svg` representation supplied by that pinned flag-icons release. This is a consistent game/reference representation, not a claim that Antarctica has an official sovereign national flag.

The generator is `tools/generate_world_flags.py`. It requires exactly 249 ISO rows, validates IDs and canonical English names for uniqueness, copies every referenced asset and emits manifest counts/source metadata. It does not modify legacy course assets or mappings.

The pinned United States and United States Minor Outlying Islands SVG sources use `marker-mid` for their 50 stars. During dataset generation, QQL expands the same source star path at the same 50 coordinates because Flutter's current SVG compiler does not render marker constructs. The 4:3 proportions, stripes, canton, canonical identities, dataset memberships, source artwork and MIT provenance remain unchanged.

## Pools and references

The four cumulative gameplay pools are:

1. UN: the 193 United Nations Member States.
2. UN + ISO: all 249 ISO 3166-1 entities.
3. UN + ISO + Shortlist: ISO plus England, Scotland, Wales, Kosovo, Northern Ireland, Catalonia, Basque Country and Galicia (257).
4. All Flags: the previous pool plus Sámi, Roma, Sorbian, Breton, Corsican, Occitan, Cornish, Friulian and Sardinian (266).

The four read-only reference sections are non-overlapping layers: UN Members, ISO extras (the 56 ISO entities that are not UN Members), Shortlist, and Language-related flags. Each view is alphabetized by canonical English name, includes its own compact explanation, and supports live case-insensitive search over canonical English names and existing aliases. Search is scoped to the open category and cannot change game state or learner progress.

Existing course flags are frozen and separate. Legacy course `CY` continues to mean Wales, course `EN` keeps its established English/UK meaning, and ISO `CY`/`GB` in the world manifest mean Cyprus/United Kingdom. Existing `flagCode`, `flagImageBase64` priority, bundled JSON behavior and `FlagPainter` are unchanged.

## Flag Game

Five taps or mouse clicks within three seconds on the Settings title and subtle generic outlined-flag hint play the existing suspense sound and open Flag Game. The flag icon has the compact `Flag Game` tooltip; one to four taps still do nothing, stale sequences reset, and Close/Back naturally returns to Settings.

A game uses one of the four cumulative pools, selects 12 unique targets and gives five distinct English answers per question. Seedable/injectable randomness makes target and correct-answer positions testable. A fresh game avoids intentionally repeating the immediately previous exact target order when the pool allows it.

Distractors always come from the selected pool. Candidates are randomly shuffled before being ranked by shared color, geographic/RIR or regional metadata, giving variety among plausible candidates. Explicit symmetric `avoidAsDistractorWith` metadata prevents Romania/Chad, Monaco/Indonesia, Ireland/Côte d'Ivoire, Mali/Guinea and Netherlands/Luxembourg from being deliberate distractor pairs.

Elapsed time starts in a post-frame callback only after question one is visible and ends after question 12. The existing QQL sound service plays victory for a correct answer and defeat for a wrong answer. Immediate feedback appears in a reserved line directly below the flag: `Correct` for a correct choice, or `Correct answer: <canonical English name>` after an error. Correct answers advance after 800 ms (up from 700 ms); the wrong-answer delay remains 700 ms. Results show `X / 12`, elapsed time, Play again and Close; 12/12 receives a special congratulations state. No result awards XP, Weekly XP, streak, Laurel, Round/Lesson progress, Review or Duel credit.

## Local scorecards

Flag Game stores at most one best record per `learnerProfileId` and stable mode name (`unMembers`, `iso`, `isoPlusShortlist`, `allFlags`). Each record contains score, elapsed milliseconds and `achievedAt`. A candidate replaces the learner's previous record only when it ranks better by score descending, elapsed time ascending, then achievement time ascending; an equally scored/equally timed newer record does not replace the earlier one.

All four scorecard sections are always displayed and each lists at most five device-local learner profiles. Ranking uses the same score/time/date ordering. Each dense existing row shows its best record as `score/12 · elapsed s · DD Mon YYYY`, where the date is that record's `achievedAt`; card padding and row count are unchanged. Duplicate display names remain separate ID-keyed entries and retain their avatars. There is no network leaderboard or account service.
