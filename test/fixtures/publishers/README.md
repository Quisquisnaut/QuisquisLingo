# Dummy publisher — TEST ONLY

The private key here is intentionally public test data, never a production credential.
The app bundles only the public key and trusts it only with explicit QQL_ENABLE_DUMMY_PUBLISHER=true.
Never distribute that configuration as a public production build.

`dummy-signed-media.json` and `dummy-signed-media.zip` are a signed Course
with one tiny MP3 fixture. The ZIP is tested for signature and media digest;
its bytes are test data, not a playable lesson recording.
