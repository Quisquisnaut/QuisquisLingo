# Flat Image Library

Version 0.5.9 ships only flat WebP assets that have been manually checked for label-to-image correspondence under `assets/exercise_images/` plus a searchable `manifest.json`.

The Course Editor can:
- choose and reuse any bundled flat image;
- search by label and tags and filter by category;
- import a custom PNG, JPG/JPEG or WebP;
- change or remove the image assigned to an exercise;
- preview the selected image before saving.

Bundled assets are referenced by path and are not duplicated when reused. Custom images are copied into the app support directory.

Sample-course policy: images are added only where they support recognition or meaning without exposing a hidden answer. Listening and reading comprehension items do not receive answer-revealing illustrations by default.
