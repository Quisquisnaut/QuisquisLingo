# Optional recorded-audio packs

QuisquisLingo is local-first. System TTS remains the default where it is suitable,
but a course may eventually ship a recorded-audio pack when its authors prefer
human recordings or when good TTS is unavailable.

The intended distribution model is demand-driven:

1. The base app and course metadata remain small.
2. A recorded-audio pack is downloaded only when the learner actually starts a
   course that needs it.
3. The app must show the download size before starting a required pack.
4. Download failure must never corrupt progress. A course may declare a TTS
   fallback, or an exercise may remain unavailable until its recording exists.
5. Audio packs are stored per course and can be removed from a future Storage
   settings page without deleting course progress.
6. Updated packs should prefer incremental or per-file replacement rather than
   forcing a complete re-download.

Recorded files and their performers must have explicit rights documentation.
The Course Audit should eventually verify missing files, orphaned files,
duplicates, unsupported formats and declared fallback behavior.

This file documents the architecture. QuisquisLingo 0.5.0 does not yet include a
network downloader for recorded-audio packs.
