import 'canonical/canonical.dart';

/// How a Select draws the pictures on its answers (Build 263 Revision 2,
/// owner decisions of 4 October 2026): the Course's default, chosen in
/// Lesson Options, which each exercise may override with its own options
/// (`pictureSize`, `pictureShape`, `picturesPerRow`, and since Build 267
/// Revision 7 `pictureBorder`; their default `course` follows the Course).
final class PictureAnswerStyle {
  const PictureAnswerStyle({
    this.size = PictureSize.large,
    this.shape = PictureShape.square,
    this.perRow = PicturesPerRow.two,
    this.border = PictureBorder.none,
  }) : assert(size != PictureSize.course),
       assert(shape != PictureShape.course),
       assert(perRow != PicturesPerRow.course),
       assert(border != PictureBorder.course);

  /// The look a Course has until it chooses another (owner decision of 4
  /// October 2026, Revision 2 follow-up): large square pictures, two per
  /// row. The look before Build 263 was normal, round, as many as fit.
  static const standard = PictureAnswerStyle();

  /// What a new Course has (Build 267 Revision 7, owner decision of 9
  /// October 2026): the standard look with a thin grey line around each
  /// picture. Courses made before keep [standard], without the line.
  static const newCourse = PictureAnswerStyle(border: PictureBorder.thin);

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

  /// The first build that draws the line around pictures: a Course that
  /// asks for it records it as its `minimumAppBuild`.
  static const borderMinimumAppBuild = 267007;

  final PictureSize size;
  final PictureShape shape;
  final PicturesPerRow perRow;
  final PictureBorder border;

  /// Whether a thin grey line goes around each picture.
  bool get bordered => border == PictureBorder.thin;

  PictureAnswerStyle copyWith({
    PictureSize? size,
    PictureShape? shape,
    PicturesPerRow? perRow,
    PictureBorder? border,
  }) => PictureAnswerStyle(
    size: size ?? this.size,
    shape: shape ?? this.shape,
    perRow: perRow ?? this.perRow,
    border: border ?? this.border,
  );

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
    if (border != standard.border) 'border': border.serialized,
  };

  /// The Course's `pictureAnswers`; absent means [standard]. An unknown key
  /// or value is a format error, never a default.
  static PictureAnswerStyle fromJson(Object? json) {
    if (json == null) return standard;
    if (json is! Map) {
      throw const FormatException('course.pictureAnswers is invalid.');
    }
    for (final key in json.keys) {
      if (key != 'size' &&
          key != 'shape' &&
          key != 'perRow' &&
          key != 'border') {
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
      border: pick('border', PictureBorder.values, standard.border),
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
    final ownBorder = options.enumValue<PictureBorder>(OptionKey.pictureBorder);
    return PictureAnswerStyle(
      size: ownSize == null || ownSize == PictureSize.course ? size : ownSize,
      shape: ownShape == null || ownShape == PictureShape.course
          ? shape
          : ownShape,
      perRow: ownPerRow == null || ownPerRow == PicturesPerRow.course
          ? perRow
          : ownPerRow,
      border: ownBorder == null || ownBorder == PictureBorder.course
          ? border
          : ownBorder,
    );
  }

  /// Whether [options] choose a border of their own.
  static bool overridesBorder(PrimitiveOptions options) {
    final own = options.enumValue<PictureBorder>(OptionKey.pictureBorder);
    return own != null && own != PictureBorder.course;
  }

  /// Whether [options] choose a picture look of their own.
  static bool overrides(PrimitiveOptions options) => <OptionEnumValue?>[
    options.enumValue<PictureSize>(OptionKey.pictureSize),
    options.enumValue<PictureShape>(OptionKey.pictureShape),
    options.enumValue<PicturesPerRow>(OptionKey.picturesPerRow),
    options.enumValue<PictureBorder>(OptionKey.pictureBorder),
  ].any((value) => value != null && value.serialized != 'course');

  @override
  bool operator ==(Object other) =>
      other is PictureAnswerStyle &&
      other.size == size &&
      other.shape == shape &&
      other.perRow == perRow &&
      other.border == border;

  @override
  int get hashCode => Object.hash(size, shape, perRow, border);
}
