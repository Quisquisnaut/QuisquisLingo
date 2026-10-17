# Build 276 change summary

Hearing every target-language text a Course has a voice for
(`docs/276_PLAN.md`, the owner's brief and answers of 17 October 2026).

## Revision 0 (2.0.76+276000): the apostrophe in a recording's text

### Before

- When QQL matched a text to the Audio Library's recordings, every mark at
  the edges of the text was dropped, apostrophes included: the article L'
  played the recording of the letter L, un' the recording of un, 'o the
  recording of o.
- A straight and a curly apostrophe were different characters: a recording
  of "dov'è" did not play "dov’è".
- The Course Audit's duplicate recordings compared texts trimmed and
  without capitals, so "L'" and "L’" were two texts.

### Now

- An apostrophe beside a letter at either end of a word counts (L', un',
  dell', 'n, 'o): such a text needs its own recording. «L'» keeps its
  apostrophe (guillemets close with their own mark); an apostrophe beside
  a digit (80') is still punctuation.
- Single quotes around a word or a phrase ('ciao', ‘come here’, ‚ciao‘)
  are quote marks and do not count: an opening mark pairs with the first
  closing mark after it when two letters or more lie between them, on the
  whole text, before it is cut into words. Around a single letter they are
  apostrophes (rock 'n' roll). An elision that opens a text and one that
  ends a later word ('O sole, pe' te) pair as a quotation too, so every
  run of words is looked up as written first (the recordings of 'O and
  pe'), then without the paired marks (o and pe, as before Build 276).
- A text without an apostrophe or a single quote at a word's edge keys
  exactly as before (the earlier rule is kept for it; a test compares
  every spoken and recorded text of the test Courses).
- ' ’ ʼ are one apostrophe, at the edges and inside words.
- The Audit's duplicate recordings read the three apostrophes as one and
  otherwise keep their rule: L' and L’ are the same text twice, L and L'
  two texts, "ciao!" and "ciao" two texts as before. A Course holding both
  L' and L’ (or dov'è and dov’è) now gets this Error: it cannot be
  published or imported until one recording goes or changes its text.
- In a Course with recordings, a text that borrowed a recording without
  its apostrophe may now have none: Hybrid reads it with the device's
  voice while Text-to-speech is on; in Recorded MP3 only an exercise that
  needs it is left out of the Round and a speaker says it cannot play;
  Texts in this Course lists it as missing (the part to record as the
  author wrote it), and the borrowed recording no longer counts it in Used
  in N exercises (Check unused MP3 files may then list that recording).

### Owner decisions (17 October 2026)

- The brief: keep an elision's apostrophe at either end of a word, the
  three apostrophes one character, every user of the key checked, Texts in
  this Course showing a lost recording as missing, the CHANGELOG saying so.
- The duplicate rule: today's rule plus the apostrophes, not the playback
  key.
- Stated and not objected to: a word quoted at both ends loses both marks.
- After the independent review and its re-read (the session's choice,
  within the brief): single quotes are paired on the whole text, so a
  quoted phrase keeps matching its words' recordings, and each run of
  words is looked up as written first, so Neapolitan 'o … pe' find their
  own recordings; ʼ (a letter for Unicode) is an apostrophe at the edges
  too.

### Where

- `lib/services/audio_segmenter.dart` (`key`, `_withoutQuotes`,
  `_trimmed`, `apostrophes`, `unifyApostrophes`, the words `segment` and
  `coverage` cut, `coverage`'s missing runs).
- `lib/services/course_audit_service.dart` (`AUDIO_MAPPING_DUPLICATE`),
  `lib/services/audit_code_registry.dart` (its condition).
- Help EN/IT/ES `editorHelp.qa.audioModes.a`.
- Every user of the key read: `RecordedAudioService.segment` (playback,
  the Audio Library's and the Course Editor's unused recordings, the Round
  screen's and `AudioExerciseAvailabilityService`'s audio checks,
  `CourseAudioUsage.usesByClip`), `CourseAudioTexts` (`coverage`,
  `ownRecordingOf` for Associate recording). Nothing else compares a text
  with a recording's text.
