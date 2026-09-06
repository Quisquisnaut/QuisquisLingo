# Recorded audio library

QuisquisLingo 0.5.5 lets a course creator choose `System TTS`, `Recorded MP3 only`, or `Hybrid` audio in Course Editor > Audio Library.

Current 226.03 revision-1 workflow: in **What do you hear?**, **Spoken text** is the exact requested utterance, not a filename. System TTS sends it to the native speech engine. To use recordings, place MP3 files in `Documents/QuisquisLingo/Imports/Audio`, open **Course Editor > Audio Library > Import MP3**, then use **Associate recording > Word or expression** for each clip. Choose Recorded MP3 only or Hybrid. Exercises resolve their spoken text against these Course-level mappings; there is no per-exercise MP3 attachment.

Physical MP3 storage is grouped by learning language. Recording metadata and references belong to the Course. Verified Course-version backups copy referenced recordings; Course JSON and learner data exports do not embed MP3 bytes. Existing local recordings are not made portable merely by exporting Course JSON.

Imported MP3 files (maximum 50 MB each) are copied into application-owned support storage. Each recording is mapped to one word or expression. Playback segments a requested utterance using longest-match-first matching and concatenates the recordings with a short pause. In Hybrid mode, TTS is used only when a complete recorded sequence cannot be assembled. In Recorded MP3 mode, missing coverage is reported rather than silently falling back to TTS.

The editor checks for orphan MP3 files with no word/expression mapping when the Audio Library is opened manually, during Course Audit, after library changes, and periodically (no more than once every seven days per course when the editor is opened). Deletion is always user-confirmed. Before deletion, the current course is checked again so stale audit results cannot remove a newly used clip.

Current local authoring storage keeps the imported audio files outside SharedPreferences to avoid inflating the course JSON. A future distributable course-package exporter should copy these files into the course's optional downloadable audio pack and rewrite the local file paths to package-relative paths.
