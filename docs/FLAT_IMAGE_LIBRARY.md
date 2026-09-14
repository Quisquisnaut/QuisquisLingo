# Flat Image Library

QQL 234 ships 111 flat, lossless 256 × 256 WebP assets under `assets/exercise_images/` plus synchronized searchable manifests. The QQL 234 visual audit replaced 92 mistaken split/composite images in place and preserved their paths and semantic IDs. Five of the 19 retained already-correct images received padding-only normalization; every final image has transparency and a fully transparent outer border. The earlier `bicycle.webp` entry was removed because its artwork did not represent a bicycle clearly enough.

The Course Editor can:

- choose and reuse any bundled flat image;
- search by display label, stable ID, category and bilingual semantic tags;
- inspect the tags on library cards and in the selected-image preview;
- import a custom PNG, JPG/JPEG or WebP;
- change or remove the image assigned to an exercise;
- preview the selected image before saving.

Tags are authoring metadata only. They appear in the Course Editor Media Library and are never rendered on learner exercise cards. The existing stable paths remain authoritative: `people_family_man` is displayed as **Uomo** and `actions_jump` as **Saltare**, without renaming `man.webp` or `jump.webp` or changing exercise data.

Bundled assets are referenced by path and are not duplicated when reused. Custom images are copied into the app support directory. `python tools/validate_images.py` checks manifest parity, IDs/paths, exact casing, 256 × 256 lossless WebP encoding, transparency and the final 92-replacement/19-retained audit partition; Flutter integrity coverage also decodes all images and verifies the transparent border.

Sample-course policy: images are added only where they support recognition or meaning without exposing a hidden answer. Listening and reading comprehension items do not receive answer-revealing illustrations by default.
