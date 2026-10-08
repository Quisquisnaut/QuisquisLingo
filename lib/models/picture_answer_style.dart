import 'canonical/canonical.dart';

/// How a Select draws the pictures on its answers (Build 263 Revision 2,
/// owner decisions of 4 October 2026): the Course's default, chosen in
/// Lesson Options, which each exercise may override with its own options
/// (`pictureSize`, `pictureShape`, `picturesPerRow`; their default `course`
/// follows the Course).
final class PictureAnswerStyle {
  const PictureAnswerStyle({
    this.size = PictureSize.large,
    this.shape = PictureShape.square,
    this.perRow = PicturesPerRow.two,
  }) : assert(size != PictureSize.course),
       assert(shape != PictureShape.course),
       assert(perRow != PicturesPerRow.course);

  /// The look a Course has until it chooses another (owner decision of 4
  /// October 2026, Revision 2 follow-up): large square pictures, two per
  /// row. The look before Build 263 was normal, round, as many as fit.
  static const standard = PictureAnswerStyle();

  /// The look before Build 263 Revision 2, which a Course or an exercise
  /// may still choose.
  static const earlier = PictureAnswerStyle(
    size: PictureSize.normal,
    shape: PictureShape.round,
    perRow: PicturesPerRow.automatic,
  );

  /// The first build that draws another look. A Course that asks for one,
  /// for itself or in an exercise, records it as its `minimumAppBuild`.
  static const minimumAppBuild = 263002;

  final PictureSize size;
  final PictureShape shape;
  final PicturesPerRow perRow;

  bool get isStandard => this == standard;

  /// Pictures per row, or null for as many as fit.
  int? get perRowCount => switch (perRow) {
    PicturesPerRow.one => 1,
    PicturesPerRow.two => 2,
    PicturesPerRow.three => 3,
    PicturesPerRow.automatic || PicturesPerRow.course => null,
  };

  /// The Course's `pictureAnswers`: only what differs from [standard].
  Map<String, Object?> toJson() => {
    if (size != standard.size) 'size': size.serialized,
    if (shape != standard.shape) 'shape': shape.serialized,
    if (perRow != standard.perRow) 'perRow': perRow.serialized,
  };

  /// The Course's `pictureAnswers`; absent means [standard]. An unknown key
  /// or value is a format error, never a default.
  static PictureAnswerStyle fromJson(Object? json) {
    if (json == null) return standard;
    if (json is! Map) {
      throw const FormatException('course.pictureAnswers is invalid.');
    }
    for (final key in json.keys) {
      if (key != 'size' && key != 'shape' && key != 'perRow') {
        throw FormatException('course.pictureAnswers.$key is unknown.');
      }
    }
    T pick<T extends OptionEnumValue>(String key, List<T> values, T absent) {
      final raw = json[key];
      if (raw == null) return absent;
      for (final value in values) {
        // `course` belongs to an exercise, never to the Course itself.
        if (value.serialized == raw && value.serialized != 'course') {
          return value;
        }
      }
      throw FormatException('course.pictureAnswers.$key is invalid.');
    }

    return PictureAnswerStyle(
      size: pick('size', PictureSize.values, standard.size),
      shape: pick('shape', PictureShape.values, standard.shape),
      perRow: pick('perRow', PicturesPerRow.values, standard.perRow),
    );
  }

  /// The look of an exercise whose options are [options]: its own choice
  /// where it names one, this Course style elsewhere.
  PictureAnswerStyle overriddenBy(PrimitiveOptions options) {
    final ownSize = options.enumValue<PictureSize>(OptionKey.pictureSize);
    final ownShape = options.enumValue<PictureShape>(OptionKey.pictureShape);
    final ownPerRow = options.enumValue<PicturesPerRow>(
      OptionKey.picturesPerRow,
    );
    return PictureAnswerStyle(
      size: ownSize == null || ownSize == PictureSize.course ? size : ownSize,
      shape: ownShape == null || ownShape == PictureShape.course
          ? shape
          : ownShape,
      perRow: ownPerRow == null || ownPerRow == PicturesPerRow.course
          ? perRow
          : ownPerRow,
    );
  }

  /// Whether [options] choose a picture look of their own.
  static bool overrides(PrimitiveOptions options) => <OptionEnumValue?>[
    options.enumValue<PictureSize>(OptionKey.pictureSize),
    options.enumValue<PictureShape>(OptionKey.pictureShape),
    options.enumValue<PicturesPerRow>(OptionKey.picturesPerRow),
  ].any((value) => value != null && value.serialized != 'course');

  @override
  bool operator ==(Object other) =>
      other is PictureAnswerStyle &&
      other.size == size &&
      other.shape == shape &&
      other.perRow == perRow;

  @override
  int get hashCode => Object.hash(size, shape, perRow);
}
