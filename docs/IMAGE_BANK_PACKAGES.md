# Separate Image Bank packages

QuisquisLingo 0.6.1 can import an Image Bank without recompiling the app.

An Image Bank is a ZIP containing:

- `image_bank_manifest.json`
- the image files referenced by the manifest, normally under `assets/exercise_images/`

The manifest accepts the batch fields `id`, `primary_term`, `keywords`, `category`, and `filename`. QuisquisLingo copies the bank into its application-support directory and records local paths for use by exercises and Lessons.

Import validation rejects duplicate IDs, missing image files, unsupported image formats, malformed manifests, and images larger than 50 KB. Recommended image resolution is 256 × 256 px and recommended size is 15 KB or less.

If an imported bank is later removed while an exercise or Lesson still references one of its files, the app displays a missing-image warning rather than silently hiding the problem.
