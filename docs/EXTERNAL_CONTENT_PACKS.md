# External content packs

QuisquisLingo is designed so full courses, image banks and recorded audio can be distributed independently of the application.

## Course Pack

A Course Model v9 file declares a stable `courseId`, origin, the applicable custom/official version, source and target languages, text direction, structured Authors/Contributors, License, optional Rights Holders and Course data. Every Course records immutable Original Course Creator/Created provenance; a custom Course additionally requires one individual Course Maintainer, while optional Assigned Team management uses a separate stable Team ID. Forks add immutable immediate-source and Fork Created By/Date provenance. These stable identities are distinct from visible attribution, rights metadata and optional Discord presentation. No v8 or older custom format is migrated, read as fallback, or assigned a Maintainer or Team from names. Authors choose the License for each Course. Languages are not restricted to a built-in list.

An ordinary imported course is `custom`. An `externalOfficial` file also declares a stable publisher ID and name, official course version, UTC release date, content checksum, release notes, distribution channel, and any supported signature or verification metadata. QQL verifies content integrity but does not invent publisher authenticity: when the publisher cannot be authenticated, installation requires an explicit warning and the course remains visibly **External official — unverified**.

An official update must match both the stable Course ID and publisher, must be newer, and must have a valid checksum. It archives the previous official source before atomically installing the new official source. Both official origins are locally read-only. Only explicit derivative permission enables a custom Fork with inherited Original Course Creator/Created lineage, structured attribution, Rights Holder and License plus separate immediate-source and Fork Created By/Date metadata; missing/forbidden permission blocks the action. For a custom import, the individual Maintainer or Assigned Team members can Edit and Copy as New Course regardless of License; only the Maintainer can transfer maintenance or assign/revoke a Team. All other profiles remain read-only and use the same derivative policy for Fork. Official updates never modify forks. Obsolete Build 225 local overrides are ignored, not migrated or deleted; their backup manifests are not exposed as publisher Version History.

## Image Bank
Shared across courses. The starter app may include the 113-image sample bank. External banks contain image_bank_manifest.json plus image files. Maximum image file size: 50 KB. Missing assets must be reported.

## Audio Pack
Audio packs are course-specific and declare course_id in audio_manifest.json. They contain MP3 files and text associations. Missing audio files and orphan files must be reported. The starter app may include a small number of sample MP3 files for each bundled sample language.

User-data export does not contain courses, image banks, course backup history, or audio packs. Export those separately. Course JSON export is a portable content file; automatic Course Editor backup manifests additionally retain version/provenance metadata and copies of referenced course-owned audio assets.
