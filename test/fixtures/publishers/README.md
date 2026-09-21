# Dummy publisher — TEST ONLY

The private key here is intentionally public test data, never a production credential.
The app bundles only the public key and trusts it only with explicit QQL_ENABLE_DUMMY_PUBLISHER=true.
Never distribute that configuration as a public production build.

`dummy-signed-media.json` and `dummy-signed-media.zip` are a signed Course
with one tiny MP3 fixture. The ZIP is tested for signature and media digest.
Since Build 243 Revision 13 the recording is a structurally valid synthetic
MP3 (eight silent-content MPEG-1 Layer III frames, `syntheticMp3()` in
`test/support/synthetic_mp3.dart`), because Course package import checks
every MP3. It is test data, not a lesson recording. To regenerate: remove
`publisherSignature`, then `tools/sign_course.dart prepare`, sign the payload
with `openssl pkeyutl -sign -inkey dummy-private.pem -rawin`, `attach`, and
`package`.
