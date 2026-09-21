# Phase 20 import fixtures

Regenerate these files from the repository root with
`python tools/generate_import_matrix_fixtures.py`. The generator uses only the
Python standard library. All media is synthetic; no third-party recording or
image is included.

`valid_flag.png`, `valid_icon.png`, `valid_cover.png`, `valid.mp3`, and `valid_bank.zip` are
positive controls. The remaining files exercise animation, oversized image
headers, mislabeled files, truncated audio, embedded MP3 artwork, malformed
JSON, missing manifests, and unsafe ZIP paths. The header-only oversized PNG
remains tiny: import must reject its claimed dimensions before rasterizing.

The route assertions live in `test/import_route_matrix_revision19_test.dart`.
They map to the plan's §5 routes as follows:

| Route numbers | Artifact | Paths asserted |
|---|---|---|
| 1–2, 13 | Course JSON, Merge source, Course ZIP | Fixed folder, Open from…, JSON inside ZIP |
| 3–4 | Learner backup, Recovery Key | Fixed folder, Open from… |
| 5 | Image Bank ZIP | Fixed folder, Open from…, direct reader |
| 6–7 | Shared and Course Editor image | Fixed folder, single and batch Open from…, Course media storage |
| 8–10 | Recognize image, Lesson icon, custom flag | Fixed folder, applicable Open from…, embedded Course JSON |
| 11–12 | Recorded and generated MP3 hook | Fixed folder, single and batch Open from…, Course ZIP, direct validator |
| 14 | Course cover | Course ZIP, fixed folder and Open from… |
