import 'bundled_asset.dart';

/// How a Course names its own pictures and recordings: by their content,
/// `media:<sha256>.<ext>`, never by a path on the author's device (Build 243
/// Revision 2).
///
/// One owner of that rule since Build 272 Revision 8. Before, the pattern
/// was written in nine places of the models, the media store, the package
/// service and the signing tool.
///
/// Pure Dart, no import but the bundled-asset rule: the tools that run with
/// `dart run` read it too.
abstract final class CourseMediaReference {
  /// The kinds of file a Course's recording may be.
  static const Set<String> audioExtensions = {'mp3'};

  /// The kinds of file a Course's picture may be. The patterns below name
  /// the same kinds, in this order (a test compares them).
  static const Set<String> imageExtensions = {'png', 'jpg', 'jpeg', 'webp'};

  static const String _digest = '[0-9a-f]{64}';
  static const String _imageExtensions = 'png|jpg|jpeg|webp';
  static const String _extensions = 'mp3|$_imageExtensions';

  /// A Course-owned picture without the anchors, for a pattern that accepts
  /// it beside something else (a Story avatar).
  static const String imageBody = 'media:$_digest\\.($_imageExtensions)';

  /// A Course-owned picture: `media:<sha256>.<png|jpg|jpeg|webp>`.
  static final RegExp image = RegExp('^$imageBody\$');

  /// A Course-owned recording: `media:<sha256>.mp3`.
  static final RegExp audio = RegExp('^media:$_digest\\.mp3\$');

  /// Any Course media. Group 1 is the SHA-256, group 2 the extension.
  static final RegExp any = RegExp('^media:($_digest)\\.($_extensions)\$');

  /// The name of the stored file: `<sha256>.<ext>`.
  static final RegExp fileName = RegExp('^$_digest\\.($_extensions)\$');

  /// The file's path inside a Course package: `media/<sha256>.<ext>`. Group 1
  /// is the SHA-256, group 2 the extension.
  static final RegExp packagePath = RegExp(
    '^media/($_digest)\\.($_extensions)\$',
  );

  static bool isImage(String value) => image.hasMatch(value);
  static bool isAudio(String value) => audio.hasMatch(value);
  static bool isAny(String value) => any.hasMatch(value);

  /// What a Course may name as a recording: nothing, a file of QQL's own
  /// bundle, or its own recording.
  static bool isValidAudio(String value) =>
      value.isEmpty || isBundledAsset(value) || isAudio(value);

  /// What a Course may name as a picture: nothing, a file of QQL's own
  /// bundle, a picture embedded in the Course file, or its own picture.
  static bool isValidImage(String value) =>
      value.isEmpty ||
      isBundledAsset(value) ||
      value.startsWith('data:image/') ||
      isImage(value);

  /// Refuses a Course file that names a recording, a picture or a QQL
  /// picture key in a way no device but the author's could resolve. Reads
  /// the file's own JSON: the Audio Library's recordings, and every image
  /// element and picture key of the Lessons.
  static void checkCourseJson(Map<String, dynamic> json) {
    final library = json['audioLibrary'];
    if (library is List) {
      for (final clip in library.whereType<Map>()) {
        final path = clip['filePath'];
        if (path is String && !isValidAudio(path)) {
          throw FormatException(
            'Audio Library recording "$path" is not supported. Recordings '
            'must be bundled assets or course media (media:<sha256>.mp3), '
            'never a path on one device.',
          );
        }
      }
    }
    void visit(Object? node) {
      if (node is Map) {
        final asset = node['asset'];
        if (node['type'] == 'image' &&
            asset is String &&
            !isValidImage(asset)) {
          throw FormatException(
            'Exercise image "${asset.length > 120 ? '${asset.substring(0, 120)}…' : asset}" '
            'is not supported. Images must be bundled assets, embedded images '
            'or course media (media:<sha256>.<png|jpg|jpeg|webp>), never a '
            'path on one device.',
          );
        }
        // A picture answer named by its QQL picture (an icon key) is drawn
        // from the bundle too.
        final text = node['text'];
        if (node['role'] == 'icon' &&
            text is String &&
            text.startsWith('assets/') &&
            !isBundledAsset(text)) {
          throw FormatException(
            'Picture key "${text.length > 120 ? '${text.substring(0, 120)}…' : text}" '
            'is not a QQL picture.',
          );
        }
        node.values.forEach(visit);
      } else if (node is List) {
        node.forEach(visit);
      }
    }

    visit(json['lessons']);
  }
}
