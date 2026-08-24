# External content packs

QuisquisLingo is designed so full courses, image banks and recorded audio can be distributed independently of the application.

## Course Pack
A course pack declares a stable course_id, version, source and target languages using BCP 47 tags, text direction, author(s), license, and course data. Authors choose the license for each course. Custom licenses may include LICENSE.txt. Languages are not restricted to a built-in list.

## Image Bank
Shared across courses. The starter app may include the 113-image sample bank. External banks contain image_bank_manifest.json plus image files. Maximum image file size: 50 KB. Missing assets must be reported.

## Audio Pack
Audio packs are course-specific and declare course_id in audio_manifest.json. They contain MP3 files and text associations. Missing audio files and orphan files must be reported. The starter app may include a small number of sample MP3 files for each bundled sample language.

User-data export does not contain courses, image banks, or audio packs. Export those separately.
