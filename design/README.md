# Design sources

Pictures kept for their authors, not shipped in the app (Build 264,
Revision 1; `pubspec.yaml` does not list this folder).

- `mascots/`: the PNG originals of the mascots. The app ships WebP copies
  in `assets/mascots/` (quality 90, same size). After changing a mascot here,
  write its WebP again and run `tools/make_avatars.ps1`, which builds the
  Story avatars from these originals.
- `lesson_plants/`: six plant drawings no screen uses any more (see
  `docs/MEDIA_CREDITS.md`).
