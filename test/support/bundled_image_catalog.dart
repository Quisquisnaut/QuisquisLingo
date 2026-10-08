import 'dart:convert';
import 'dart:io';

import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';

// The QQL image catalog as the tests read it from disk.

/// How many images QQL ships. Pinned here and nowhere else (owner decision
/// of 5 October 2026, Build 264): a release that adds or removes images
/// changes this number on purpose, so an image lost by mistake fails.
/// Revision 1: 2,988 WebP pictures and the 284 World Flags; Revision 2
/// removed the two petting pictures; Revision 6 added the owner's series
/// 4, 5 and 6 (798 pictures); Revision 7 the objects of series 1 (110)
/// and the toy-block letters of series 3 (26); Revision 8 the 30 Lesson
/// icons as the category lesson_icons. Build 265 Revision 5 added ten
/// pictures (Artichoke … Friends), Revision 6 fifteen (the personal
/// pronouns, Friend (man/woman), Kid (boy/girl), Hello!, Bye!, Goodbye!),
/// Revision 10 forty historical figures and 22 landmarks and removed
/// Columbus; Revision 11 nine family scenes, Man 2 and 3, Woman 2 and 3 and
/// Friends (women).
const bundledImageCount = 4334;

/// Where the World Flags' drawings are; the library's flags point there
/// (Build 264 Revision 1).
const worldFlagFolder = 'assets/world_flags/flags/';

/// Where the Lesson icons are; the library's lesson_icons point there
/// (Build 264 Revision 8).
const lessonIconFolder = 'assets/lesson_icons/';

/// The records of `assets/exercise_images/metadata_v2.json`.
List<Map<String, dynamic>> readBundledImageRecords() {
  final document =
      jsonDecode(
            File(
              ExerciseImageMetadataService.bundledCatalogAsset,
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  return (document['records'] as List)
      .map((entry) => Map<String, dynamic>.from(entry as Map))
      .toList();
}

/// The categories that hold written characters (since Build 264 Revision
/// 2 all named `characters_…`). Their pictures may be opaque (owner
/// decision of 5 October 2026); every other picture uses transparency.
bool isCharacterImageCategory(String category) =>
    category.startsWith('characters_');

/// A name or tag as the rules compare it: capitals and spacing ignored,
/// accents kept (the library search keeps them too).
String imageWordKey(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
