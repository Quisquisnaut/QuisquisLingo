import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import 'image_library_rules.dart';

/// The credit QQL already knows for a picture chosen in the image library, or
/// null when it knows none (Build 255 Revision 7).
///
/// A QQL picture is an original QuisquisLingo asset, unless the catalog
/// records its own credit (the World Flags, Build 264 Revision 1). A Shared
/// Image Library picture, or one of a Course's own, is known by the
/// attribution the library records for it. Any other picture is of unknown
/// origin: its author is reminded to credit it instead.
CourseMediaAttribution? knownImageCredit(
  ExerciseImageMetadata image, {
  required String appliesTo,
}) {
  if (isBundledImage(image) && image.attribution == null) {
    return CourseMediaAttribution(
      author: 'QuisquisLingo',
      license: 'Original QuisquisLingo asset',
      title: _field(image.label),
      source: 'QuisquisLingo Flat Image Bank',
      appliesTo: appliesTo,
    );
  }
  final attribution = image.attribution;
  if (attribution == null) return null;
  return CourseMediaAttribution(
    author: attribution.author,
    license: attribution.license,
    title: attribution.title,
    source: attribution.source,
    appliesTo: appliesTo,
  );
}

/// A label as a credit field: one line of at most 200 characters.
String _field(String value) {
  final line = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return line.length <= 200 ? line : line.substring(0, 200).trimRight();
}
