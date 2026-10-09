/// The typed option vocabulary of Course Model v12 exercises.
///
/// Every option is identified by an [OptionKey] with a stable serialized name
/// and a value kind. Enumerated options draw their values from the closed
/// vocabularies below; the capability registry restricts each vocabulary per
/// primitive (a `layout` of `columns` is legal for Match, never for Select).
/// Values that are not in a vocabulary never become canonical: parsing
/// returns null instead of guessing, so an unknown value cannot be mistaken
/// for a default.
library;

/// A closed-vocabulary option value with a stable serialized identifier.
abstract interface class OptionEnumValue {
  String get serialized;
}

enum SelectionMode implements OptionEnumValue {
  single('single'),
  multiple('multiple');

  const SelectionMode(this.serialized);
  @override
  final String serialized;
}

enum SelectionTarget implements OptionEnumValue {
  items('items'),
  textSpans('textSpans'),
  regions('regions'),
  cells('cells');

  const SelectionTarget(this.serialized);
  @override
  final String serialized;
}

enum ItemReuse implements OptionEnumValue {
  forbidden('forbidden'),
  allowed('allowed'),
  unlimited('unlimited');

  const ItemReuse(this.serialized);
  @override
  final String serialized;
}

/// The neutral layout vocabulary shared by every primitive. Each primitive
/// accepts its own subset (see the registry); the names never imply
/// ownership by one primitive.
enum LayoutValue implements OptionEnumValue {
  list('list'),
  grid('grid'),
  inline('inline'),
  field('field'),
  multiline('multiline'),
  inlineGaps('inlineGaps'),
  horizontal('horizontal'),
  vertical('vertical'),
  wrapped('wrapped'),
  columns('columns'),
  cards('cards'),
  free('free'),
  overlay('overlay');

  const LayoutValue(this.serialized);
  @override
  final String serialized;
}

enum EvaluationTiming implements OptionEnumValue {
  immediate('immediate'),
  explicit('explicit'),
  onCompletion('onCompletion'),
  none('none');

  const EvaluationTiming(this.serialized);
  @override
  final String serialized;
}

enum InputMode implements OptionEnumValue {
  text('text'),
  number('number'),
  date('date'),
  formula('formula'),
  code('code');

  const InputMode(this.serialized);
  @override
  final String serialized;
}

enum Cardinality implements OptionEnumValue {
  single('single'),
  multiple('multiple');

  const Cardinality(this.serialized);
  @override
  final String serialized;
}

enum CaseHandling implements OptionEnumValue {
  exact('exact'),
  ignore('ignore');

  const CaseHandling(this.serialized);
  @override
  final String serialized;
}

enum PunctuationHandling implements OptionEnumValue {
  exact('exact'),
  ignore('ignore');

  const PunctuationHandling(this.serialized);
  @override
  final String serialized;
}

enum WhitespaceHandling implements OptionEnumValue {
  exact('exact'),
  normalize('normalize');

  const WhitespaceHandling(this.serialized);
  @override
  final String serialized;
}

/// `missingAccentsAccepted` is today's behavior and the value every converted
/// exercise gets: "citta" is accepted for "città" when the learner typed no
/// accent at all, while a wrong accent is not. `exact` is new and strict.
enum AccentHandling implements OptionEnumValue {
  exact('exact'),
  missingAccentsAccepted('missingAccentsAccepted'),
  ignore('ignore');

  const AccentHandling(this.serialized);
  @override
  final String serialized;
}

enum TypoTolerance implements OptionEnumValue {
  none('none'),
  conservative('conservative');

  const TypoTolerance(this.serialized);
  @override
  final String serialized;
}

/// Shared by Arrange (sequence, inlineGaps, grid) and Assign (drag,
/// selectTarget, tapTarget); the registry keeps the two subsets apart.
enum PlacementMode implements OptionEnumValue {
  sequence('sequence'),
  inlineGaps('inlineGaps'),
  grid('grid'),
  drag('drag'),
  selectTarget('selectTarget'),
  tapTarget('tapTarget');

  const PlacementMode(this.serialized);
  @override
  final String serialized;
}

enum UnusedItems implements OptionEnumValue {
  forbidden('forbidden'),
  allowed('allowed');

  const UnusedItems(this.serialized);
  @override
  final String serialized;
}

/// How Arrange joins placed blocks into the compared text: with spaces
/// (sentences) or without (letters and syllables building one word).
enum Joiner implements OptionEnumValue {
  space('space'),
  none('none');

  const Joiner(this.serialized);
  @override
  final String serialized;
}

enum MatchRelationship implements OptionEnumValue {
  oneToOne('oneToOne'),
  oneToMany('oneToMany'),
  manyToOne('manyToOne'),
  manyToMany('manyToMany');

  const MatchRelationship(this.serialized);
  @override
  final String serialized;
}

enum MatchInteractionStyle implements OptionEnumValue {
  pair('pair'),
  dropdown('dropdown'),
  connect('connect'),
  memory('memory');

  const MatchInteractionStyle(this.serialized);
  @override
  final String serialized;
}

enum AssignTargetMode implements OptionEnumValue {
  categories('categories'),
  slots('slots'),
  gaps('gaps'),
  regions('regions'),
  cells('cells');

  const AssignTargetMode(this.serialized);
  @override
  final String serialized;
}

enum TargetCapacity implements OptionEnumValue {
  single('single'),
  multiple('multiple'),
  unlimited('unlimited');

  const TargetCapacity(this.serialized);
  @override
  final String serialized;
}

enum SpeechMode implements OptionEnumValue {
  repeat('repeat'),
  readAloud('readAloud'),
  freeResponse('freeResponse');

  const SpeechMode(this.serialized);
  @override
  final String serialized;
}

enum CaptureMode implements OptionEnumValue {
  microphone('microphone');

  const CaptureMode(this.serialized);
  @override
  final String serialized;
}

enum TranscriptionMode implements OptionEnumValue {
  none('none'),
  optional('optional'),
  required('required');

  const TranscriptionMode(this.serialized);
  @override
  final String serialized;
}

/// Speak's own `playback` option (whether the learner may or must replay the
/// recording); not the `playback` attribute of an audio media element.
enum SpeakPlayback implements OptionEnumValue {
  none('none'),
  allowed('allowed'),
  requiredBeforeSubmit('requiredBeforeSubmit');

  const SpeakPlayback(this.serialized);
  @override
  final String serialized;
}

enum InkMode implements OptionEnumValue {
  freehand('freehand'),
  trace('trace'),
  character('character'),
  diagram('diagram');

  const InkMode(this.serialized);
  @override
  final String serialized;
}

enum InputDevice implements OptionEnumValue {
  pointer('pointer'),
  touch('touch'),
  stylus('stylus'),
  any('any');

  const InputDevice(this.serialized);
  @override
  final String serialized;
}

enum StrokeOrder implements OptionEnumValue {
  ignored('ignored'),
  checked('checked');

  const StrokeOrder(this.serialized);
  @override
  final String serialized;
}

enum SubmissionType implements OptionEnumValue {
  audio('audio'),
  video('video'),
  image('image'),
  file('file'),
  textDocument('textDocument');

  const SubmissionType(this.serialized);
  @override
  final String serialized;
}

enum CaptureSource implements OptionEnumValue {
  device('device'),
  file('file'),
  either('either');

  const CaptureSource(this.serialized);
  @override
  final String serialized;
}

enum ReviewMode implements OptionEnumValue {
  self('self'),
  manual('manual'),
  external('external');

  const ReviewMode(this.serialized);
  @override
  final String serialized;
}

/// `proceed` serializes as `continue`, which is a reserved word in Dart.
enum CompletionMode implements OptionEnumValue {
  proceed('continue'),
  acknowledge('acknowledge'),
  understoodReview('understoodReview'),
  automatic('automatic');

  const CompletionMode(this.serialized);
  @override
  final String serialized;
}

enum PresentationNavigation implements OptionEnumValue {
  singlePage('singlePage'),
  paged('paged');

  const PresentationNavigation(this.serialized);
  @override
  final String serialized;
}

enum MediaPlayback implements OptionEnumValue {
  manual('manual'),
  automatic('automatic'),
  none('none');

  const MediaPlayback(this.serialized);
  @override
  final String serialized;
}

/// Build 256 Revision 5: when a presentation shows its text next to its
/// audio: at once, or only after the audio has played.
enum TextReveal implements OptionEnumValue {
  immediate('immediate'),
  afterAudio('afterAudio');

  const TextReveal(this.serialized);
  @override
  final String serialized;
}

/// How big a Select draws the pictures on its answers (Build 263 Revision
/// 2). `course` follows the Course's choice in Lesson Options.
enum PictureSize implements OptionEnumValue {
  course('course'),
  normal('normal'),
  large('large');

  const PictureSize(this.serialized);
  @override
  final String serialized;
}

/// The shape of a Select's picture answers (Build 263 Revision 2): round,
/// as before, or a square the picture fills. `course` follows the Course.
enum PictureShape implements OptionEnumValue {
  course('course'),
  round('round'),
  square('square');

  const PictureShape(this.serialized);
  @override
  final String serialized;
}

/// How many picture answers a Select puts in a row (Build 263 Revision 2):
/// as many as fit, or one to three (owner decision: at most three). `course`
/// follows the Course.
enum PicturesPerRow implements OptionEnumValue {
  course('course'),
  automatic('automatic'),
  one('one'),
  two('two'),
  three('three');

  const PicturesPerRow(this.serialized);
  @override
  final String serialized;
}

/// A thin grey line around each picture answer (Build 267 Revision 7, owner
/// decisions of 9 October 2026), following its round or square shape.
/// `course` follows the Course.
enum PictureBorder implements OptionEnumValue {
  course('course'),
  none('none'),
  thin('thin');

  const PictureBorder(this.serialized);
  @override
  final String serialized;
}

enum Scoring implements OptionEnumValue {
  none('none');

  const Scoring(this.serialized);
  @override
  final String serialized;
}

/// The data type of an option's value.
enum OptionValueKind { enumeration, boolean, integer, language }

/// Every option key any primitive may use, with its stable serialized name,
/// its value kind and, for enumerations, the complete vocabulary (the union
/// over all primitives; the registry restricts it per primitive).
enum OptionKey {
  selectionMode(
    'selectionMode',
    OptionValueKind.enumeration,
    SelectionMode.values,
  ),
  selectionTarget(
    'selectionTarget',
    OptionValueKind.enumeration,
    SelectionTarget.values,
  ),
  minimumSelections('minimumSelections', OptionValueKind.integer),
  maximumSelections('maximumSelections', OptionValueKind.integer),
  itemReuse('itemReuse', OptionValueKind.enumeration, ItemReuse.values),
  layout('layout', OptionValueKind.enumeration, LayoutValue.values),
  evaluationTiming(
    'evaluationTiming',
    OptionValueKind.enumeration,
    EvaluationTiming.values,
  ),
  shuffleItems('shuffleItems', OptionValueKind.boolean),
  inputMode('inputMode', OptionValueKind.enumeration, InputMode.values),
  cardinality('cardinality', OptionValueKind.enumeration, Cardinality.values),
  caseHandling(
    'caseHandling',
    OptionValueKind.enumeration,
    CaseHandling.values,
  ),
  punctuationHandling(
    'punctuationHandling',
    OptionValueKind.enumeration,
    PunctuationHandling.values,
  ),
  whitespaceHandling(
    'whitespaceHandling',
    OptionValueKind.enumeration,
    WhitespaceHandling.values,
  ),
  accentHandling(
    'accentHandling',
    OptionValueKind.enumeration,
    AccentHandling.values,
  ),
  typoTolerance(
    'typoTolerance',
    OptionValueKind.enumeration,
    TypoTolerance.values,
  ),
  placementMode(
    'placementMode',
    OptionValueKind.enumeration,
    PlacementMode.values,
  ),
  unusedItems('unusedItems', OptionValueKind.enumeration, UnusedItems.values),
  joiner('joiner', OptionValueKind.enumeration, Joiner.values),
  relationship(
    'relationship',
    OptionValueKind.enumeration,
    MatchRelationship.values,
  ),
  interactionStyle(
    'interactionStyle',
    OptionValueKind.enumeration,
    MatchInteractionStyle.values,
  ),
  shuffleLeft('shuffleLeft', OptionValueKind.boolean),
  shuffleRight('shuffleRight', OptionValueKind.boolean),
  targetMode(
    'targetMode',
    OptionValueKind.enumeration,
    AssignTargetMode.values,
  ),
  targetCapacity(
    'targetCapacity',
    OptionValueKind.enumeration,
    TargetCapacity.values,
  ),
  speechMode('speechMode', OptionValueKind.enumeration, SpeechMode.values),
  captureMode('captureMode', OptionValueKind.enumeration, CaptureMode.values),
  language('language', OptionValueKind.language),
  transcription(
    'transcription',
    OptionValueKind.enumeration,
    TranscriptionMode.values,
  ),
  playback('playback', OptionValueKind.enumeration, SpeakPlayback.values),
  maxDurationSeconds('maxDurationSeconds', OptionValueKind.integer),
  inkMode('inkMode', OptionValueKind.enumeration, InkMode.values),
  inputDevice('inputDevice', OptionValueKind.enumeration, InputDevice.values),
  strokeOrder('strokeOrder', OptionValueKind.enumeration, StrokeOrder.values),
  templateVisible('templateVisible', OptionValueKind.boolean),
  eraseAllowed('eraseAllowed', OptionValueKind.boolean),
  submissionType(
    'submissionType',
    OptionValueKind.enumeration,
    SubmissionType.values,
  ),
  captureSource(
    'captureSource',
    OptionValueKind.enumeration,
    CaptureSource.values,
  ),
  reviewMode('reviewMode', OptionValueKind.enumeration, ReviewMode.values),
  completionMode(
    'completionMode',
    OptionValueKind.enumeration,
    CompletionMode.values,
  ),
  navigation(
    'navigation',
    OptionValueKind.enumeration,
    PresentationNavigation.values,
  ),
  mediaPlayback(
    'mediaPlayback',
    OptionValueKind.enumeration,
    MediaPlayback.values,
  ),
  scoring('scoring', OptionValueKind.enumeration, Scoring.values),
  textReveal('textReveal', OptionValueKind.enumeration, TextReveal.values),

  /// Build 257: a presentation card offers an Open GuideBook button.
  guidebookButton('guidebookButton', OptionValueKind.boolean),

  /// Build 263 Revision 2: how a Select draws the pictures on its answers.
  pictureSize('pictureSize', OptionValueKind.enumeration, PictureSize.values),
  pictureShape(
    'pictureShape',
    OptionValueKind.enumeration,
    PictureShape.values,
  ),
  picturesPerRow(
    'picturesPerRow',
    OptionValueKind.enumeration,
    PicturesPerRow.values,
  ),

  /// Build 267 Revision 7: a thin grey line around each picture answer.
  pictureBorder(
    'pictureBorder',
    OptionValueKind.enumeration,
    PictureBorder.values,
  );

  const OptionKey(this.serialized, this.kind, [this.vocabulary = const []]);

  /// The stable JSON name.
  final String serialized;
  final OptionValueKind kind;

  /// For an enumeration: every value any primitive may use. Empty otherwise.
  final List<OptionEnumValue> vocabulary;

  /// The key whose serialized name is exactly [value], or null.
  static OptionKey? tryParse(Object? value) {
    if (value is! String) return null;
    for (final key in values) {
      if (key.serialized == value) return key;
    }
    return null;
  }

  /// The vocabulary value whose identifier is exactly [value], or null.
  OptionEnumValue? enumValueFor(Object? value) {
    if (value is! String) return null;
    for (final candidate in vocabulary) {
      if (candidate.serialized == value) return candidate;
    }
    return null;
  }
}

/// A language tag as QQL accepts it: a primary subtag of two to eight
/// letters, optionally followed by `-` subtags (`it`, `pt-BR`, `zh-Hant`).
final RegExp languageTagPattern = RegExp(
  r'^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$',
);

/// A typed option value. Equality is by kind and value.
sealed class OptionValue {
  const OptionValue();

  /// The JSON form: a String, bool or int.
  Object get serialized;

  /// The typed value for [key] parsed from raw JSON, or null when [raw] is not
  /// exactly the kind the key expects or, for an enumeration, not in the
  /// key's vocabulary. Nothing is coerced: `"true"` is not a boolean, `1.0`
  /// is not an integer and `"Single"` is not `single`.
  static OptionValue? parse(OptionKey key, Object? raw) {
    switch (key.kind) {
      case OptionValueKind.enumeration:
        final value = key.enumValueFor(raw);
        return value == null ? null : EnumOptionValue(value);
      case OptionValueKind.boolean:
        return raw is bool ? BoolOptionValue(raw) : null;
      case OptionValueKind.integer:
        return raw is int ? IntOptionValue(raw) : null;
      case OptionValueKind.language:
        return raw is String && languageTagPattern.hasMatch(raw)
            ? LanguageOptionValue(raw)
            : null;
    }
  }
}

final class EnumOptionValue extends OptionValue {
  const EnumOptionValue(this.value);
  final OptionEnumValue value;
  @override
  Object get serialized => value.serialized;
  @override
  bool operator ==(Object other) =>
      other is EnumOptionValue && other.value == value;
  @override
  int get hashCode => Object.hash(EnumOptionValue, value);
  @override
  String toString() => 'EnumOptionValue(${value.serialized})';
}

final class BoolOptionValue extends OptionValue {
  const BoolOptionValue(this.value);
  final bool value;
  @override
  Object get serialized => value;
  @override
  bool operator ==(Object other) =>
      other is BoolOptionValue && other.value == value;
  @override
  int get hashCode => Object.hash(BoolOptionValue, value);
  @override
  String toString() => 'BoolOptionValue($value)';
}

final class IntOptionValue extends OptionValue {
  const IntOptionValue(this.value);
  final int value;
  @override
  Object get serialized => value;
  @override
  bool operator ==(Object other) =>
      other is IntOptionValue && other.value == value;
  @override
  int get hashCode => Object.hash(IntOptionValue, value);
  @override
  String toString() => 'IntOptionValue($value)';
}

final class LanguageOptionValue extends OptionValue {
  const LanguageOptionValue(this.value);
  final String value;
  @override
  Object get serialized => value;
  @override
  bool operator ==(Object other) =>
      other is LanguageOptionValue && other.value == value;
  @override
  int get hashCode => Object.hash(LanguageOptionValue, value);
  @override
  String toString() => 'LanguageOptionValue($value)';
}

/// The options set on one exercise: an immutable map from key to typed value.
/// Absent keys mean "the primitive's default" (the registry resolves them);
/// the map itself never stores a default it was not given.
final class PrimitiveOptions {
  PrimitiveOptions([Map<OptionKey, OptionValue> values = const {}])
    : _values = Map.unmodifiable(
        Map.fromEntries(
          values.entries.toList()
            ..sort((a, b) => a.key.index.compareTo(b.key.index)),
        ),
      );

  static final PrimitiveOptions empty = PrimitiveOptions();

  final Map<OptionKey, OptionValue> _values;

  Map<OptionKey, OptionValue> get values => _values;
  Iterable<OptionKey> get keys => _values.keys;
  bool get isEmpty => _values.isEmpty;
  bool get isNotEmpty => _values.isNotEmpty;
  int get length => _values.length;

  OptionValue? operator [](OptionKey key) => _values[key];
  bool contains(OptionKey key) => _values.containsKey(key);

  /// The enumerated value of [key] as [T], or null when absent or of another
  /// kind or enumeration.
  T? enumValue<T extends OptionEnumValue>(OptionKey key) {
    final value = _values[key];
    return value is EnumOptionValue && value.value is T
        ? value.value as T
        : null;
  }

  bool? boolValue(OptionKey key) {
    final value = _values[key];
    return value is BoolOptionValue ? value.value : null;
  }

  int? intValue(OptionKey key) {
    final value = _values[key];
    return value is IntOptionValue ? value.value : null;
  }

  String? languageValue(OptionKey key) {
    final value = _values[key];
    return value is LanguageOptionValue ? value.value : null;
  }

  PrimitiveOptions withOption(OptionKey key, OptionValue value) =>
      PrimitiveOptions({..._values, key: value});

  PrimitiveOptions withEnum(OptionKey key, OptionEnumValue value) =>
      withOption(key, EnumOptionValue(value));

  PrimitiveOptions without(OptionKey key) =>
      PrimitiveOptions({..._values}..remove(key));

  /// The JSON object, keys in [OptionKey] declaration order.
  Map<String, Object> toJson() => {
    for (final entry in _values.entries)
      entry.key.serialized: entry.value.serialized,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PrimitiveOptions || other._values.length != _values.length) {
      return false;
    }
    for (final entry in _values.entries) {
      if (other._values[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    for (final entry in _values.entries) Object.hash(entry.key, entry.value),
  ]);

  @override
  String toString() => 'PrimitiveOptions(${toJson()})';
}
