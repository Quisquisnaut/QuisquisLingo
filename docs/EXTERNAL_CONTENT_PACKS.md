# External content packs

QuisquisLingo is designed so full courses, image banks and recorded audio can be distributed independently of the application.

## Course Pack

A Course Model v6 file declares a stable `courseId`, origin, version, source and target languages, text direction, author(s), license, and course data. Authors choose the license for each course. Languages are not restricted to a built-in list.

An ordinary imported course is `custom`. An `externalOfficial` file also declares a stable publisher ID and name, official course version, UTC release date, content checksum, release notes, distribution channel, and any supported signature or verification metadata. QQL verifies content integrity but does not invent publisher authenticity: when the publisher cannot be authenticated, installation requires an explicit warning and the course remains visibly **External official — unverified**.

An official update must match both the stable course ID and publisher, must be newer, and must have a valid checksum. It archives the previous official source before atomically installing the new official source. Both official origins are locally read-only. Only explicit `derivativeWorksPolicy: allowed` enables an independent custom fork with permanent original authorship/provenance and separate creator identity; missing/forbidden permission blocks the action. The human-readable license remains attached. Official updates never modify forks. Obsolete Build 225 local overrides are ignored, not migrated or deleted; their backup manifests are not exposed as publisher Version History.

## Image Bank
Shared across courses. The starter app may include the 113-image sample bank. External banks contain image_bank_manifest.json plus image files. Maximum image file size: 50 KB. Missing assets must be reported.

## Audio Pack
Audio packs are course-specific and declare course_id in audio_manifest.json. They contain MP3 files and text associations. Missing audio files and orphan files must be reported. The starter app may include a small number of sample MP3 files for each bundled sample language.

User-data export does not contain courses, image banks, course backup history, or audio packs. Export those separately. Course JSON export is a portable content file; automatic Course Editor backup manifests additionally retain version/provenance metadata and copies of referenced course-owned audio assets.
