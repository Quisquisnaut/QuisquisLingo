# Plan: Publisher Courses and in-app signing

Status: **in progress.** Owner decisions of 2 October 2026. On 3 October
2026 the owner chose parts 4.1, 4.2 (structure and tests with a test key
only) and 4.3 for **Build 262** (`docs/262_CHANGE_SUMMARY.md`,
`docs/262_HANDOFF.md`); the private folder is
`D:\QQL_plus\Corsi_Privati`. The Build 262 draft
(`docs/262_BUNDLED_AUTHORING_PLAN.md`, editing bundled Courses as author)
is set aside: this plan takes another road.

## 1. The need

The owner wants to publish Courses outside the app's open-source code:
free demo Courses that can ship inside the app, and full Courses, possibly
copyrighted and sold, that learners download and import. The app stays
open source; the publisher is a separate identity.

## 2. Today

- The app source is MPL-2.0. Course content is separately licensed and is
  not covered by the MPL merely because the app reads it
  (`docs/LICENSING.md`).
- Publisher Courses (`externalOfficial`) already exist: Ed25519 signatures
  (`qql-ed25519-v1`), the trusted key registry in
  `lib/services/trusted_publishers.dart` (no production publisher yet),
  signed ZIP packages with media, verified import and updates that keep
  progress, revocation. See `docs/PUBLISHER_SIGNING_GUIDE.md`.
- Signing happens only outside the app: `tools/sign_course.dart` plus
  OpenSSL. The tool accepts only a file that is already `externalOfficial`;
  there is no way to turn an app Course into a Publisher Course.
- Four bundled Courses: QQL Demo: Exercise Laboratory (`IT`), QQL Demo:
  Piedmontese (sorted by exercise type) (`PMS`), QQL Demo: Piedmontese
  (`PMS_MIX`), QQL Demo: English from Italian (`EN_IT`).

## 3. Decisions of 2 October 2026

1. **A separate publisher.** The publisher is not the app. Proposed:
   publisher name **QuisquisLingo Courses**, `publisherId`
   **`com.quisquislingo`**, its own Ed25519 key. It is approved through the
   same steps as any external publisher (guide §§3–6), with a private
   approval record.
2. **Free demos ship in the app; full Courses are sold.** Demos are signed
   Publisher Course ZIPs bundled as app assets and installed automatically.
   Full Courses are downloaded from the publisher and imported with the
   existing signed ZIP import.
3. **Demo and full are separate Courses** (different Course IDs). Buying the
   full Course starts its own progress; nothing can overwrite anything.
4. **The two Italian Courses stay bundled** for now as QQL's own Courses:
   Exercise Laboratory (`IT`) and English from Italian (`EN_IT`).
5. **The two Piedmontese Courses leave the app and the public repo.** They
   are kept by the owner as local custom Courses, never committed. Their
   generators, tests and documents go with them. Git history is **not**
   rewritten (the old commits keep them).
6. **Signing in the app**, reading the key file created with OpenSSL
   (guide §2). The key is never stored by the app. The terminal tool stays.
7. **The signing key is created by the owner on their own computer**, never
   by an online service or an assistant. Only the public key, its
   fingerprint and its Base64 registry value are shared.

## 4. Work in the code

### 4.1 Remove the Piedmontese Courses

- Remove `PMS` and `PMS_MIX` from `CourseService.courseAssets`,
  `targetLabels`, `sourceLabels` and `_additionalBundledCodes`; keep their
  Course IDs reserved in `CourseEditorService`, as for earlier removed
  demos.
- Convert both Courses to custom Course files for the owner (one-off,
  output outside the repo).
- Move out of the repo, to the owner's private folder:
  `assets/courses/piedmontais_en.json`,
  `assets/courses/piedmontese_mixed_en.json`,
  `tools/generate_piedmontais_demo_254.py`,
  `tools/generate_piedmontese_mixed_259.py`,
  `test/piedmontais_course_254_test.dart`,
  `test/piedmontese_mixed_259_test.dart`,
  `docs/254_PIEDMONTAIS_COVERAGE.md`, `readme/readme-pms.txt` (check its
  content first).
- Clean every remaining reference (full-text search for `PMS`,
  `piedmont`, `piemont`): `tools/validate_courses.py`, tests, fixtures,
  README, Help.
- Learner progress already stored for these Courses stays on the device
  without a Course, as for the demos removed in Builds 254–259.

### 4.2 Register the publisher

- Add one `TrustedPublisherKey` to `TrustedPublishers.application()`:
  `publisherId: com.quisquislingo`, `publisherName: QuisquisLingo Courses`,
  a `keyId` such as `qqlc-2026-1`, the owner's `publicKeyBase64`.
- Tests: a Course signed by that key imports; altered, missing-signature
  and wrong-key cases are refused (guide §6).

### 4.3 Export as Publisher Course

- A Course Studio action that turns a Course the author may publish into
  an `externalOfficial` Course: chosen publisher (from the registry),
  `publisherName` exactly as registered, `officialCourseVersion` set or
  raised, every ID kept, no Maintainer / Team, not private.
- Course Audit errors refuse the export. The license must be stated.
- For an update of an already published Course: same Course ID, same
  publisher, higher version.

### 4.4 Sign in the app

- "Sign and export" in Course Studio: the author picks the encrypted key
  file and types the passphrase; the app signs with the same bytes as
  `PublisherVerificationService.signingBytes`, checks the result against
  the registry, and writes the ZIP as `tools/sign_course.dart package`
  does.
- Key file: only the format the guide's command creates
  (`openssl genpkey -algorithm ED25519 -aes-256-cbc`: encrypted PKCS#8,
  PBES2 with PBKDF2 and AES-256-CBC). Anything else is refused with a
  clear message. Uses the `cryptography` package already in the app; a
  small ASN.1 reader is new.
- The key and passphrase are held in memory only for the one signature,
  never written to storage, logs, backups or Inventory.
- Tests use key files made by OpenSSL as fixtures (wrong passphrase,
  unsupported format, unencrypted key, wrong key for the registry).

### 4.5 Publisher ZIPs shipped in the app

- Signed ZIPs in `assets/publisher_courses/`, with a note stating that the
  content belongs to its publisher and is not covered by the MPL.
- At startup the app installs a shipped ZIP through the normal import
  checks (signature, media, version) when the Course is not installed, or
  when the shipped version is newer than the installed one.
- The app remembers which version it offered: a Course the learner
  uninstalled is not reinstalled until a newer version ships.
- Wipe everything clears that record, so the demos come back.
- To check: whether Publisher Courses are installed per device or per
  profile, and whether a device-level record goes to `AppResetService`,
  `InventoryService` and `docs/239_RESET_STORAGE_INVENTORY.md`.

### 4.6 Documents

- `docs/PUBLISHER_SIGNING_GUIDE.md`: in-app signing, shipped Publisher
  ZIPs.
- `docs/LICENSING.md`: remove the outdated mention of ten "AI-Slop Demo"
  Courses; state how publisher content shipped in the app is licensed.
- README: two bundled Courses instead of four; publisher demos.

## 5. Owner tasks outside the code

1. Create the signing key with OpenSSL on the owner's computer (guide §2),
   in a private folder outside the repo; back it up and test the backup.
   Share only the fingerprint, the Base64 registry value and the public
   PEM.
2. Register the domains: `quisquislingo.org` (the app) and
   `quisquislingo.com` (the publisher). Both were unregistered on
   2 October 2026. Proposed: Cloudflare Registrar (renewal at cost, about
   $10–11 a year each).
3. Publisher site and downloads: free demos and the site on a free host
   (GitHub Pages forbids commercial sites, so Cloudflare Pages for the
   publisher site); paid Courses through a sales platform that handles EU
   VAT (for example Gumroad, Lemon Squeezy, Paddle). Contact address by
   email forwarding.
4. Tax and legal position of selling Courses in Italy (partita IVA,
   trademark on the name): to check with a professional.
5. A license text for the free demos that allows redistribution unmodified
   inside the app and the public repository; a restrictive license for the
   paid Courses.

## 6. Open points

- Build number.
- Final publisher name and `keyId` (proposed above).
- Whether 4.5 and the first demo Course ship in the same build.
- Where the owner's private folder for the Piedmontese material lives.

## 7. Known limits

- Signatures prove who published a Course; they do not stop a buyer from
  passing the file on (guide §8). Copy protection is not in this plan.
- Demos shipped in the app are public in the GitHub repository.
- The Piedmontese Courses remain in the old commits of the public
  repository.

## 8. Not in this plan

- Moving the two Italian Courses to Publisher Courses (possible later; it
  would need a deliberate handover keeping their Course IDs).
- Editing bundled Courses as author (the set-aside 262 draft).
- Payments, licence keys or accounts inside the app.
