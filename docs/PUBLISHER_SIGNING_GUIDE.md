# Publisher signing and approval

## Status: signature verification implemented

Build 241 now verifies Ed25519 publisher signatures for Publisher Course imports, both from the Imports folder and from the system file dialog. The storage service checks again before installation. Missing, invalid, unknown or revoked signatures are rejected. The normal trusted publisher registry currently has no approved external publishers; the Dummy identity is for explicitly enabled test builds only.

Publisher approval is a manual owner process. The owner maintains the public-key registry in lib/services/trusted_publishers.dart and distributes changes with an app update. There is no approval portal or in-app signing button. A developer command and OpenSSL provide course signing outside the app.

The Course Model is v11 (Build 243); v9/v10 Publisher Courses must be converted with tools/convert_course_to_v11.dart and signed again. The signature protocol is qql-ed25519-v1. Focused verification does not constitute final release validation; Build 241 still awaits the owner's final validation approval.

## 1. Roles and tools

Publisher: creates and protects an Ed25519 key pair, requests approval, and signs its own releases. The QQL owner never receives private keys and does not sign each course for the publisher.

QQL owner: independently checks the publisher identity and key possession, assigns a stable publisherId and records the approved public key. Trust changes are shipped in the app registry; no online service is required.

Tools: a maintained OpenSSL 3.x installation, a terminal, a plain-text editor, a password manager, protected offline backup storage and an independently verified communication channel. Obtain OpenSSL from a trusted OS/package provider. Run openssl version to confirm it is on PATH. On Windows, an executable path containing spaces is invoked in PowerShell as & 'FULL PATH TO openssl.exe', followed by its arguments.

Course signing additionally uses the QQL repository, its compatible Dart SDK and tools/sign_course.dart. Run flutter pub get in the repository before first use. The tool prepares canonical signing bytes and attaches a checked signature; OpenSSL alone must not sign arbitrary course JSON. A learner's User Recovery Key is unrelated to publisher keys.

Use a separate private working folder per publisher, outside Git, app course/media folders and shared folders. Keep private keys there; commands run from the repository can use quoted absolute paths. Stop on every error. Choose fresh output names; never overwrite existing keys.

## 2. Publisher: create and protect the key

Check your installation:

```text
openssl version
```

It must report OpenSSL 3.x. Create an encrypted Ed25519 private key, entering a strong unique passphrase when prompted:

```text
openssl genpkey -algorithm ED25519 -aes-256-cbc -out publisher-private.pem
```

Export its public key (enter the private-key passphrase when prompted):

```text
openssl pkey -in publisher-private.pem -pubout -out publisher-public.pem
```

Calculate the public-key fingerprint using DER SubjectPublicKeyInfo, not the PEM text:

```text
openssl pkey -pubin -in publisher-public.pem -outform DER -out publisher-public.der
openssl dgst -sha256 publisher-public.der
```

Record the SHA-256 hexadecimal result. The private PEM is secret; the public PEM, public DER and fingerprint may be shared. Keep the passphrase in a password manager and an encrypted offline backup of the private PEM. Test restoring that backup in a separate secure folder: export the public key again and check that its fingerprint matches.

Never send the private PEM or passphrase to the QQL owner, put them in course JSON, commit them to Git, or include them in learner backups. Do not use online key generators or paste private keys into websites or chats. Losing both the key and backup prevents signing further releases with that key.

## 3. Publisher: request approval

Use the contact channel agreed directly with the QQL owner; this guide does not establish a public submission address. Send only:

- Publisher name and the person authorized to represent it.
- Website or other independently checkable identity evidence and a contact address.
- Requested publisherId, if any; the owner assigns the final stable identifier.
- publisher-public.pem and its SHA-256 fingerprint from section 2.
- Intended course IDs/titles, distribution channel and a statement that you can distribute the content and media under the declared licenses.

The owner will verify your identity and send a one-use challenge file. Check that its publisherId, fingerprint, purpose and expiry match your request before signing it. Do not sign arbitrary files from an unverified sender. Approval concerns a publisher/key association, not an endorsement of all its teaching content or licenses.

## 4. Owner: verify identity and issue a challenge

Keep a private approval record. Verify the representative through an independently established channel, such as a known business contact or a contact obtained from the publisher's official website. Possessing a key or an email address alone does not establish the publisher's identity.

Save the submitted public PEM in a separate request folder. Inspect it:

```text
openssl pkey -pubin -in publisher-public.pem -text -noout
```

Confirm it is an Ed25519 public key. Calculate its fingerprint with the two commands in section 2 and compare it through the independent channel. Reject a malformed key, wrong algorithm, identity mismatch or conflicting publisherId.

Assign a unique request ID and a stable publisherId. Generate a fresh random nonce:

```text
openssl rand -hex 32
```

In a plain-text editor, create qql-approval-challenge.txt as UTF-8 text with these fields, replacing every placeholder:

```text
Purpose: QQL publisher key approval only
Request ID: <unique request ID>
Publisher ID: <agreed stable publisherId>
Public key SHA-256: <fingerprint calculated by the owner>
Nonce: <fresh random hexadecimal output>
Expires UTC: <explicit UTC date and time>
```

Choose a short expiry, for example 48 hours. Store the exact file you send and its pending/used/expired status. Send it to the verified representative. Do not regenerate, reformat or reuse the challenge: verification requires the exact original bytes. The owner, not the requester, supplies the nonce and challenge.

## 5. Publisher and owner: prove key possession

Publisher: save the original challenge attachment without editing or changing line endings. Check its contents, then sign it locally:

```text
openssl pkeyutl -sign -rawin -inkey publisher-private.pem -in qql-approval-challenge.txt -out qql-approval-proof.sig
```

Enter the passphrase at the prompt. Return qql-approval-proof.sig and the request ID. Never return the private key. This signature proves possession for this challenge; it is not a QQL course signature.

Owner: use your stored original challenge, the previously checked public PEM and the returned binary signature:

```text
openssl pkeyutl -verify -rawin -pubin -inkey publisher-public.pem -in qql-approval-challenge.txt -sigfile qql-approval-proof.sig
```

Require a successful verification and exit code 0. In PowerShell, inspect $LASTEXITCODE immediately after the command. Also check that the request is pending, unexpired and unused, and its publisherId and fingerprint are still the ones verified independently. OpenSSL does not enforce these approval rules for you.

On failure, do not approve. Resolve the identity/key mismatch, or issue a new challenge if the attachment changed or expired. Do not modify the original challenge to make a signature pass. A valid proof establishes key control, not legal identity; both checks are required.

## 6. Owner: record approval and activate trust

Keep a private record of publisherId, approved display name, public PEM/fingerprint, representative/contact, identity-check method/date, original challenge and proof, decision date and key status. Mark accepted challenges used. Never publish identity evidence or private contact details in the app registry.

For an approved publisher, assign a stable keyId (1–64 ASCII letters, digits, dot, underscore or hyphen). Convert the public PEM to DER using section 2. An Ed25519 SubjectPublicKeyInfo DER is 44 bytes: the 12-byte header 302a300506032b6570032100 followed by the 32-byte public key. Store only the Base64 encoding of those 32 bytes in publicKeyBase64, not the entire DER or PEM.

In PowerShell, after checking the DER header and length, obtain the registry value with:

[Convert]::ToBase64String(([System.IO.File]::ReadAllBytes('C:/QQL-Publisher/publisher-public.der'))[12..43])

Add a TrustedPublisherKey to TrustedPublishers.application() in lib/services/trusted_publishers.dart: publisherId, publisherName (exact approved spelling), keyId, publicKeyBase64 and revoked: false. Duplicate publisherId/keyId entries are rejected by lookup. Keep Dummy outside the normal registry. Do not approve a key supplied only inside an imported course, and never approve by editing publisherVerificationStatus in a JSON file.

Review the registry change; test a course signed by that key plus altered, missing-signature and wrong-key cases. Build and distribute the app through the normal release process. Notify the publisher of the exact publisherId, publisherName, keyId, fingerprint and first app version containing the approval. Until users install it, their app will reject the unknown key.

Approval authenticates the publisher identity, not ownership of every course ID or content license. A new publisher cannot overwrite a course already installed under another publisher or take a bundled/custom course identity.

## 7. Publisher: sign and distribute a course

Start with a valid externalOfficial JSON for Course Model v11, with your exact approved publisherId and publisherName, publisher lineage, stable courseId and release metadata. For an update retain the course ID/provenance and increase officialCourseVersion. Resolve blocking Course Audit errors and check content/media licenses. The tool does not convert custom courses or invent publisher metadata.

Run from the QQL repository. Replace dummy-1 with your approved keyId and use your actual input/output/key paths. The examples use a separate working folder named C:/QQL-Publisher:

```text
dart run tools/sign_course.dart prepare C:/QQL-Publisher/course.json dummy-1 C:/QQL-Publisher/payload.bin
```

The command validates the model and prepares the canonical digest-based signing payload. It does not read a private key. Sign those bytes with OpenSSL, entering the private-key passphrase interactively:

```text
openssl pkeyutl -sign -rawin -inkey C:/QQL-Publisher/publisher-private.pem -in C:/QQL-Publisher/payload.bin -out C:/QQL-Publisher/signature.bin
openssl pkey -pubin -in C:/QQL-Publisher/publisher-public.pem -outform DER -out C:/QQL-Publisher/publisher-public.der
```

Attach the signature. This verifies the signature against the supplied public key before writing the result:

```text
dart run tools/sign_course.dart attach C:/QQL-Publisher/course.json dummy-1 C:/QQL-Publisher/signature.bin C:/QQL-Publisher/publisher-public.der C:/QQL-Publisher/course-signed.json
```

Place each referenced recording or image in C:/QQL-Publisher/media/ under its SHA-256 filename, such as <sha256>.mp3. Then package the signed JSON:

```text
dart run tools/sign_course.dart package C:/QQL-Publisher/course-signed.json C:/QQL-Publisher/media C:/QQL-Publisher/publisher-public.der C:/QQL-Publisher/course-signed.zip
```

The package command checks the signature against the supplied key, checks every referenced media file and its SHA-256, and includes only files the Course uses. An empty media folder is sufficient when the Course uses no separate media.

Check exit code 0 after each command ($LASTEXITCODE in PowerShell). The Dart tool refuses an existing output name. OpenSSL can overwrite output files, so use fresh names. Do not modify course.json between prepare and attach; any content change requires preparing and signing again. Verification with the supplied key is not QQL registry approval.

Import course-signed.zip in a QQL version containing your approved key. Check the verified publisher, version, content and media. Test an update against the previous installed release and its progress. Distribute that exact ZIP. Re-exporting through QQL preserves the normalized signed content and signature; editing signed content invalidates it.

The signature covers the normalized Course JSON, including embedded data and each media: SHA-256 reference. The ZIP verifies each file against its signed reference, so replacing media bytes fails import. An in-app publishing interface is not implemented.

## 7a. Media a Publisher Course can and cannot carry

A portable Course ZIP contains course.json, a package manifest and each non-bundled media file actually used by the Course. The app supplies bundled assets/ media.

Embedded custom Lesson icons, custom flags and Recognize characters images travel inside course.json. Recorded MP3s and ordinary imported exercise images travel as content-addressed media: files in the ZIP. The ZIP includes Admin-added Shared Image Library images used by the Course, without importing them into the recipient's Shared Image Library.

The Publisher must have distribution rights for every included file. A Course with media: references cannot be installed from JSON alone; use its complete ZIP. Missing, altered or oversized media is refused before installation.

An update backs up the previous official Course and its media, then removes media no longer used by the new version. Uninstall keeps the Course media and backup for later reinstallation.

## 7b. Media credits

Record the author and licence of any third-party image or recording in Course Info Editor, under License / Rights. The entries are stored in the course's mediaAttributions and are inside the signed payload. Admin-added Shared Image Library images may also carry per-image attribution in their metadata; this travels in the Course and ZIP manifest when used. Course Audit raises a warning when a course carries media of its own and records no credit; the warning does not block export or import. Media supplied with QuisquisLingo is already credited in the application and needs no entry.

## 8. Import policy and existing courses

New externalOfficial imports require a valid signature from an active approved key. Missing, malformed, invalid, revoked or unknown signatures are blocked before storage. A Publisher Course with media: references must arrive as a complete ZIP; package validation checks every file against its signed digest before installation. The app computes verification status; a serialized verified flag is never proof. A lower/equal official version or another publisher cannot replace an installed official course. Unsigned imports cannot downgrade verified courses.

Custom courses remain unsigned and subject to ordinary import validation. Unverified official files are not automatically converted to custom. Existing Publisher Course files that cannot be verified remain on disk and in Course Studio with Verification required; their progress is preserved and they are excluded from learner delivery. To reactivate, import a newer valid signed release with matching identity/provenance and explicitly confirm association with the existing course.

Authenticity is checked again when stored external courses and backup history are read. Revocation or file tampering removes verified status without deleting the course. Backups do not bypass import verification.

Bundled official courses rely on app distribution and retain their existing provenance/checksum checks. They need no separate per-course signature in this phase. An external JSON claiming bundledOfficial is rejected. Imported courses cannot replace bundled identities.

Signatures do not encrypt content, prevent copying, enforce payment, prove teaching quality or establish copyright ownership. Import structure, audit and licensing rules still apply. Older app versions without this verifier provide no signature assurance.

## 9. Lost keys, rotation and revocation

Publisher: restore a lost key from its protected backup. If recovery fails or compromise is suspected, stop using the key and contact the owner through the independent channel. Provide publisherId, old fingerprint, affected releases and incident details; never send the private key.

Owner: record the incident, recheck the representative and require a new key pair plus a fresh challenge/proof. Never accept a replacement solely because its publisher name or ID matches. Assign a new keyId. For planned rotation, retain the old approved entry while adding the new one if historical signatures should remain trusted. For compromise, mark the old key revoked in the registry and publish an app update.

A revoked key is rejected for new imports and is treated as unverified on stored-course/history reads, regardless of the release date claimed by a file. A valid newer replacement and explicit association can reactivate the preserved course. There is no trusted timestamp system for accepting historical signatures from a revoked key.

Offline devices learn about revocation only after an app update. Tell publishers and users which app version contains the change. Immediate worldwide revocation is not possible with the bundled registry. Key handling never requires deleting learner progress.

## 10. Protocol and references

publisherSignature uses qql-ed25519-v1:<keyId>:<signatureBase64>. The signature is 64 bytes in canonical standard Base64. The signed UTF-8 message is QQL-COURSE-SIGNATURE-V1, publisherId, keyId and the lowercase officialChecksum, each on its own LF-terminated line, including the final newline. No BOM is included.

The checksum is SHA-256 over model-normalized Course.toJson() after excluding officialChecksum, publisherSignature and publisherVerificationStatus, sorting object keys recursively and writing compact JSON. Array order is preserved. This is QQL canonicalization, not RFC 8785/JCS. Unknown fields discarded by the model are outside the signed payload. Use the QQL preparation tool; other-language serialization is not assumed compatible.

Publisher checklist: protected key/backup; approved identity and key; completed audit and licenses; prepared payload; signed bytes; attached signature; packaged media; import/update checked on a trusted-registry app; distribute the tested ZIP.

Owner checklist: independent identity check; fingerprint and one-use challenge checked; decision recorded; registry entry reviewed; valid/invalid import tests passed; media limits respected and third-party media credited in mediaAttributions; publisher informed of the supported app version. Keep the normal build free of the Dummy test opt-in.

References:
https://docs.openssl.org/3.0/man1/openssl-genpkey/
https://docs.openssl.org/3.0/man1/openssl-pkey/
https://docs.openssl.org/3.0/man1/openssl-pkeyutl/
https://pub.dev/documentation/cryptography/latest/cryptography/Ed25519-class.html

## 11. Dummy publisher: automated and manual tests

Dummy Publisher — TEST ONLY has publisherId org.quisquislingo.test.dummy and keyId dummy-1. Its public test key pair and course fixtures live under test/fixtures/publishers. The private key is intentionally public test data: never use it for a real publisher. It is not an app asset.

Automated tests inject the Dummy registry explicitly. Normal app builds do not trust it. For manual testing, enable the compile-time flag:

```text
flutter run -d windows --dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true
```

A release-mode test build is also possible:

```text
flutter build windows --release --dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true
```

These builds show a TEST ONLY banner and recognize Dummy. Do not distribute them as public production releases. A public build must omit the flag; build into a clean output location so artifacts cannot be confused.

Import test/fixtures/publishers/dummy-signed-media.zip through Course Studio → Course Import → Open from… or copy it to Imports/import.zip. Expect the verified publisher confirmation and the packaged recording. Then import dummy-signed-v2.json to test an update that removes the unused recording. dummy-unsigned.json must be rejected; changing a signed title must also be rejected, even if an attacker recalculates the checksum. A normal build without the flag rejects the Dummy signed files as an unknown key.

Dummy testing requires no approval request to a real publisher. All dummy release files must retain their TEST ONLY identification.
