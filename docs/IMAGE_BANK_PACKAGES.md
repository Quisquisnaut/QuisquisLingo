# Separate Image Bank packages

QuisquisLingo 0.6.1 can import an Image Bank without recompiling the app.

An Image Bank is a ZIP containing only:

- `image_bank_manifest.json`
- the image files referenced by the manifest, normally under `assets/exercise_images/`

The manifest accepts the batch fields `id`, `primary_term`, `keywords`, `category`, and `filename`. Each entry may also contain `"attribution": {"author": "...", "license": "...", "title": "...", "source": "..."}`; author and license are required together, while title and source are optional. Admins can add or edit these credits later in the Shared Image Library's **Edit metadata** dialog. QuisquisLingo copies the bank into its application-support directory and records local paths for use by exercises and Lessons.

Import validation rejects duplicate IDs, missing image files, unsupported image formats, malformed manifests, and images larger than 50 KB. Recommended image resolution is 256 × 256 px and recommended size is 15 KB or less.

## Rules since Build 243 Revision 14

**Nothing else in the ZIP.** Every file must be the manifest or an image the manifest lists (folders are fine). A `CREDITS.txt`, `README` or any other extra file stops the import: put credits in the manifest's `attribution` fields instead.

**Manifest forms.** The manifest is either a list of entries, as above, or an object:

```json
{
  "name": "Garden tools",
  "attribution": {"author": "A. Artist", "license": "CC BY 4.0"},
  "images": [
    {"id": "rake", "primary_term": "rake", "keywords": ["rake"], "category": "garden_tools", "filename": "rake.webp"}
  ]
}
```

`attribution` there is the bank-wide default credit: every entry without its own `attribution` gets it, and an entry's own credit always wins. The same rules apply (author and license together; title and source optional). `name` (up to 120 characters) replaces the ZIP's file name as the bank's display name. No other top-level fields are allowed.

**Field limits.**

| Field | Rule |
|---|---|
| `id` | 1–128 of `A–Z a–z 0–9 . _ -` |
| `primary_term` / `label` | 1–200 characters |
| `keywords` / `tags` | at most 32, each 1–80 characters (the Shared Image Library needs at least one) |
| `category` | a QQL category, `food`/`home`, or a new name of 2–40 lowercase letters, digits or underscores starting with a letter; missing means `other` |
| any text | no control characters |

**New categories.** When a bank brings categories the device does not have yet, the Admin sees "This bank adds N new categories: …" and chooses **Add them**, **Put these images under Other** or **Cancel**. A bank may add at most 16 new categories, and the device keeps at most 64 of its own. An invalid category name rejects the whole bank. The bank's folder, images, records and new categories are written only after every check and the Admin's choice; a failure or Cancel leaves nothing behind. A bank imported into a Course's own library keeps its categories as Course-scoped text and asks nothing.

**Archive checks.** QQL refuses, before inflating anything: more than 5000 entries; declared sizes above 50 MB in total; absolute paths, drive letters, `.`/`..` or empty path segments and control characters; names that collide after `\` → `/` and case folding; links and special files; encrypted entries; compression other than stored or deflate; archives inside the archive. Each entry is then inflated only up to its declared size and its CRC-32 is checked.

## Duplicates and conflicts since Build 243 Revision 16

Duplicates are decided by content (SHA-256), never by file name. A bank image that is already in Shared Images byte for byte (one of QQL's own pictures, an earlier import, or an earlier entry of the same bank) is skipped without asking. When an entry's `id` is already used by a different picture, the Admin chooses **Skip**, **Replace** (the device's picture is swapped and the id kept; QQL's own images are never replaced) or **Keep both** (the new picture gets the id with `-2`, `-3`, …), optionally with **Apply to all**. Every imported image records its provenance: SHA-256, size, detected format, file name, source, bank, importing Admin and time; never a path.

If an imported bank is later removed while an exercise or Lesson still references one of its files, the app displays a missing-image warning rather than silently hiding the problem.
