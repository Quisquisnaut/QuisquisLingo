/// The canonical exercise data classes of Course Model v12 (Build 256
/// Session 2): targets, the neutral inline layout, the evaluation object,
/// feedback and the small attribute vocabularies of elements and items.
///
/// Everything here is serialized inside an exercise object. Parsing is
/// strict: unknown keys and values that are not in a vocabulary are a
/// [FormatException], never silently dropped or defaulted.
library;

import 'canonical/canonical.dart';

String _requiredString(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v is! String || v.trim().isEmpty) {
    throw FormatException('Missing or invalid $where.$key');
  }
  return v.trim();
}

String _optionalString(Map<String, dynamic> j, String key, String fallback) {
  final v = j[key];
  return v is String ? v.trim() : fallback;
}

List<String> _stringList(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v == null) return const [];
  if (v is! List) throw FormatException('$where.$key must be a list.');
  return [
    for (final x in v)
      if (x is String)
        x
      else
        throw FormatException('$where.$key must contain strings only.'),
  ];
}

List<T> _mapList<T>(
  Map<String, dynamic> j,
  String key,
  String where,
  T Function(Map<String, dynamic>) parser,
) {
  final v = j[key];
  if (v == null) return const [];
  if (v is! List) throw FormatException('$where.$key must be a list.');
  return [
    for (final x in v)
      if (x is Map)
        parser(Map<String, dynamic>.from(x))
      else
        throw FormatException('$where.$key contains a non-object value.'),
  ];
}

void _refuseUnknownKeys(
  Map<String, dynamic> j,
  Set<String> known,
  String where,
) {
  final unknown = j.keys.where((key) => !known.contains(key)).toList();
  if (unknown.isNotEmpty) {
    throw FormatException(
      '$where contains unsupported fields: ${unknown.join(', ')}.',
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The language a text element is in, relative to the Course: its source
/// (explanation) language or its target (learning) language. Absent means
/// unspecified, which the runtime treats as the target language.
enum TextLanguage {
  source('source'),
  target('target');

  const TextLanguage(this.serialized);
  final String serialized;

  static TextLanguage? tryParse(Object? value) {
    if (value is! String) return null;
    for (final language in values) {
      if (language.serialized == value) return language;
    }
    return null;
  }
}

/// Whether an audio element plays by itself when its exercise becomes
/// active (`automatic`) or only when the learner asks (`manual`, the
/// default).
enum AudioPlayback {
  automatic('automatic'),
  manual('manual');

  const AudioPlayback(this.serialized);
  final String serialized;

  static AudioPlayback? tryParse(Object? value) {
    if (value is! String) return null;
    for (final playback in values) {
      if (playback.serialized == value) return playback;
    }
    return null;
  }
}

/// Build 258: how a text block of a Page is drawn.
enum BlockTextStyle {
  heading1('heading1'),
  heading2('heading2'),
  paragraph('paragraph'),
  quote('quote'),
  bulleted('bulleted'),
  numbered('numbered');

  const BlockTextStyle(this.serialized);
  final String serialized;

  /// A list block: one item per line.
  bool get isList => this == bulleted || this == numbered;

  /// A block whose text may be justified and carry inline marks.
  bool get isBody => this != heading1 && this != heading2;

  static BlockTextStyle? tryParse(Object? value) {
    for (final style in values) {
      if (style.serialized == value) return style;
    }
    return null;
  }
}

/// Build 258: where a Page block sits across the page. Start and end
/// follow the text direction; justify is for body text only.
enum BlockAlign {
  start('start'),
  center('center'),
  end('end'),
  justify('justify');

  const BlockAlign(this.serialized);
  final String serialized;

  static BlockAlign? tryParse(Object? value) {
    for (final align in values) {
      if (align.serialized == value) return align;
    }
    return null;
  }
}

/// Build 258: a Page text colour, a name the renderer maps to a readable
/// colour in the light and the dark theme (never a free colour code).
enum BlockColor {
  normal('default'),
  accent('accent'),
  red('red'),
  green('green'),
  blue('blue'),
  grey('grey');

  const BlockColor(this.serialized);
  final String serialized;

  static BlockColor? tryParse(Object? value) {
    for (final color in values) {
      if (color.serialized == value) return color;
    }
    return null;
  }
}

/// Build 258: how wide a Page picture is drawn.
enum BlockSize {
  small('small'),
  medium('medium'),
  large('large'),
  full('full');

  const BlockSize(this.serialized);
  final String serialized;

  static BlockSize? tryParse(Object? value) {
    for (final size in values) {
      if (size.serialized == value) return size;
    }
    return null;
  }
}

/// Build 258: the Page attributes a prompt element may carry and the
/// element types each applies to (the parser and the capability description
/// read this one table). `justify` is an alignment for text only.
///
/// Build 265 Revision 11: `plural` marks a picture the learner sees as
/// several (drawn as stacked copies): an image element, or the text element
/// with role `icon` that names a QQL picture ([pluralTextRoles]).
const pageElementAttributeTypes = <String, Set<String>>{
  'textStyle': {'text'},
  'align': {'text', 'image', 'link'},
  'color': {'text'},
  'size': {'image'},
  'readAloud': {'text'},
  'url': {'link'},
  'plural': {'image', 'text'},
};

/// The roles a text element must have to carry `plural`: only the icon key
/// of a picture answer is a picture.
const pluralTextRoles = {'icon'};

/// Which column of a Match an item belongs to.
enum MatchSide {
  left('left'),
  right('right');

  const MatchSide(this.serialized);
  final String serialized;

  static MatchSide? tryParse(Object? value) {
    if (value is! String) return null;
    for (final side in values) {
      if (side.serialized == value) return side;
    }
    return null;
  }
}

/// What a target shows before it is answered.
enum TargetReveal {
  /// The first Unicode grapheme of the answer, as Type the missing word does.
  firstGrapheme('firstGrapheme');

  const TargetReveal(this.serialized);
  final String serialized;

  static TargetReveal? tryParse(Object? value) {
    if (value is! String) return null;
    for (final reveal in values) {
      if (reveal.serialized == value) return reveal;
    }
    return null;
  }
}

/// A rectangle on the exercise's image, as fractions of its width and
/// height (0–1).
final class TargetRegion {
  const TargetRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  static const _keys = {'x', 'y', 'width', 'height'};

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory TargetRegion.fromJson(Map<String, dynamic> j) {
    _refuseUnknownKeys(j, _keys, 'target.region');
    double read(String key) {
      final v = j[key];
      if (v is! num) {
        throw FormatException('target.region.$key must be a number.');
      }
      return v.toDouble();
    }

    final region = TargetRegion(
      x: read('x'),
      y: read('y'),
      width: read('width'),
      height: read('height'),
    );
    if (region.x < 0 ||
        region.y < 0 ||
        region.width <= 0 ||
        region.height <= 0 ||
        region.x + region.width > 1 + 1e-9 ||
        region.y + region.height > 1 + 1e-9) {
      throw const FormatException(
        'target.region must lie within the image: x, y from 0, width and height above 0, and x + width and y + height at most 1.',
      );
    }
    return region;
  }

  @override
  bool operator ==(Object other) =>
      other is TargetRegion &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

/// A place a learner answers into: an inline gap, a region of an image, a
/// cell, a slot or a category. Layouts and evaluations refer to it by ID.
final class ExerciseTarget {
  const ExerciseTarget({required this.id, this.reveal, this.region});

  final String id;
  final TargetReveal? reveal;
  final TargetRegion? region;

  static const _keys = {'id', 'reveal', 'region'};

  Map<String, dynamic> toJson() => {
    'id': id,
    if (reveal != null) 'reveal': reveal!.serialized,
    if (region != null) 'region': region!.toJson(),
  };

  factory ExerciseTarget.fromJson(Map<String, dynamic> j) {
    _refuseUnknownKeys(j, _keys, 'target');
    TargetReveal? reveal;
    if (j.containsKey('reveal')) {
      reveal = TargetReveal.tryParse(j['reveal']);
      if (reveal == null) {
        throw FormatException(
          'target.reveal “${j['reveal']}” is not supported.',
        );
      }
    }
    final region = j['region'];
    if (j.containsKey('region') && region is! Map) {
      throw const FormatException('target.region must be an object.');
    }
    return ExerciseTarget(
      id: _requiredString(j, 'id', 'target'),
      reveal: reveal,
      region: region is Map
          ? TargetRegion.fromJson(Map<String, dynamic>.from(region))
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseTarget &&
      other.id == id &&
      other.reveal == reveal &&
      other.region == region;

  @override
  int get hashCode => Object.hash(id, reveal, region);
}

enum LayoutElementType {
  text('text'),
  target('target');

  const LayoutElementType(this.serialized);
  final String serialized;

  static LayoutElementType? tryParse(Object? value) {
    if (value is! String) return null;
    for (final type in values) {
      if (type.serialized == value) return type;
    }
    return null;
  }
}

/// One piece of the neutral inline layout: a fixed run of text or a target.
/// The primitive decides what happens at a target (Select fills it with a
/// reusable item, Arrange consumes an item occurrence, Assign places an
/// item, Input turns it into a field).
final class LayoutElement {
  const LayoutElement.text(this.text)
    : type = LayoutElementType.text,
      targetId = '';

  const LayoutElement.target(this.targetId)
    : type = LayoutElementType.target,
      text = '';

  final LayoutElementType type;
  final String text;
  final String targetId;

  bool get isTarget => type == LayoutElementType.target;
  bool get isText => type == LayoutElementType.text;

  Map<String, dynamic> toJson() => switch (type) {
    LayoutElementType.text => {'type': 'text', 'text': text},
    LayoutElementType.target => {'type': 'target', 'targetId': targetId},
  };

  factory LayoutElement.fromJson(Map<String, dynamic> j) {
    final type = LayoutElementType.tryParse(j['type']);
    if (type == null) {
      throw FormatException(
        'layout element type “${j['type']}” must be text or target.',
      );
    }
    switch (type) {
      case LayoutElementType.text:
        _refuseUnknownKeys(j, const {'type', 'text'}, 'layout text element');
        final text = j['text'];
        if (text is! String) {
          throw const FormatException('layout text element needs text.');
        }
        return LayoutElement.text(text);
      case LayoutElementType.target:
        _refuseUnknownKeys(j, const {
          'type',
          'targetId',
        }, 'layout target element');
        return LayoutElement.target(
          _requiredString(j, 'targetId', 'layout target element'),
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LayoutElement &&
      other.type == type &&
      other.text == text &&
      other.targetId == targetId;

  @override
  int get hashCode => Object.hash(type, text, targetId);
}

/// One complete ordered answer of an Arrange exercise: its literal text and
/// the exact block occurrences that build it.
final class OrderedAnswer {
  const OrderedAnswer({required this.text, required this.itemIds});

  final String text;
  final List<String> itemIds;

  Map<String, dynamic> toJson() => {'text': text, 'itemIds': itemIds};

  factory OrderedAnswer.fromJson(Map<String, dynamic> json) {
    _refuseUnknownKeys(json, const {'text', 'itemIds'}, 'ordered answer');
    return OrderedAnswer(
      text: _requiredString(json, 'text', 'ordered answer'),
      itemIds: _stringList(json, 'itemIds', 'ordered answer'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OrderedAnswer &&
      other.text == text &&
      _listEquals(other.itemIds, itemIds);

  @override
  int get hashCode => Object.hash(text, Object.hashAll(itemIds));
}

/// The items a target must hold (Select inline gaps, Arrange gap
/// assignments, Assign).
final class TargetAssignment {
  const TargetAssignment({required this.targetId, required this.itemIds});

  final String targetId;
  final List<String> itemIds;

  Map<String, dynamic> toJson() => {'targetId': targetId, 'itemIds': itemIds};

  factory TargetAssignment.fromJson(Map<String, dynamic> j) {
    _refuseUnknownKeys(j, const {'targetId', 'itemIds'}, 'assignment');
    return TargetAssignment(
      targetId: _requiredString(j, 'targetId', 'assignment'),
      itemIds: _stringList(j, 'itemIds', 'assignment'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TargetAssignment &&
      other.targetId == targetId &&
      _listEquals(other.itemIds, itemIds);

  @override
  int get hashCode => Object.hash(targetId, Object.hashAll(itemIds));
}

/// The accepted texts of one Input target (an inline gap).
final class TargetAnswers {
  const TargetAnswers({
    required this.targetId,
    required this.answers,
    this.literalAnswers = const [],
  });

  final String targetId;
  final List<String> answers;
  final List<String> literalAnswers;

  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'answers': answers,
    if (literalAnswers.isNotEmpty) 'literalAnswers': literalAnswers,
  };

  factory TargetAnswers.fromJson(Map<String, dynamic> j) {
    _refuseUnknownKeys(j, const {
      'targetId',
      'answers',
      'literalAnswers',
    }, 'target answers');
    return TargetAnswers(
      targetId: _requiredString(j, 'targetId', 'target answers'),
      answers: _stringList(j, 'answers', 'target answers'),
      literalAnswers: _stringList(j, 'literalAnswers', 'target answers'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TargetAnswers &&
      other.targetId == targetId &&
      _listEquals(other.answers, answers) &&
      _listEquals(other.literalAnswers, literalAnswers);

  @override
  int get hashCode => Object.hash(
    targetId,
    Object.hashAll(answers),
    Object.hashAll(literalAnswers),
  );
}

/// The expected number of a numeric Input: one value, a range, or a value
/// with a tolerance.
final class NumericAnswer {
  const NumericAnswer({this.value, this.minimum, this.maximum, this.tolerance});

  final double? value;
  final double? minimum;
  final double? maximum;
  final double? tolerance;

  static const _keys = {'value', 'minimum', 'maximum', 'tolerance'};

  Map<String, dynamic> toJson() => {
    if (value != null) 'value': value,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (tolerance != null) 'tolerance': tolerance,
  };

  factory NumericAnswer.fromJson(Map<String, dynamic> j) {
    _refuseUnknownKeys(j, _keys, 'evaluation.numeric');
    double? read(String key) {
      if (!j.containsKey(key)) return null;
      final v = j[key];
      if (v is! num) {
        throw FormatException('evaluation.numeric.$key must be a number.');
      }
      return v.toDouble();
    }

    return NumericAnswer(
      value: read('value'),
      minimum: read('minimum'),
      maximum: read('maximum'),
      tolerance: read('tolerance'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NumericAnswer &&
      other.value == value &&
      other.minimum == minimum &&
      other.maximum == maximum &&
      other.tolerance == tolerance;

  @override
  int get hashCode => Object.hash(value, minimum, maximum, tolerance);
}

/// The targets an item may go to (Assign acceptedTargets).
final class AcceptedTarget {
  const AcceptedTarget({required this.itemId, required this.targetIds});

  final String itemId;
  final List<String> targetIds;

  Map<String, dynamic> toJson() => {'itemId': itemId, 'targetIds': targetIds};

  factory AcceptedTarget.fromJson(Map<String, dynamic> j) {
    _refuseUnknownKeys(j, const {'itemId', 'targetIds'}, 'accepted target');
    return AcceptedTarget(
      itemId: _requiredString(j, 'itemId', 'accepted target'),
      targetIds: _stringList(j, 'targetIds', 'accepted target'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AcceptedTarget &&
      other.itemId == itemId &&
      _listEquals(other.targetIds, targetIds);

  @override
  int get hashCode => Object.hash(itemId, Object.hashAll(targetIds));
}

/// How an exercise decides correctness: the mode plus the data that mode
/// reads. Which keys a mode may use is a registry and Audit matter; parsing
/// checks structure and refuses unknown keys.
final class CanonicalEvaluation {
  const CanonicalEvaluation({
    required this.mode,
    this.correctItemIds = const [],
    this.assignments = const [],
    this.answers = const [],
    this.literalAnswers = const [],
    this.targetAnswers = const [],
    this.numeric,
    this.pattern = '',
    this.correctOrders = const [],
    this.relations = const [],
    this.acceptedTargets = const [],
  });

  static const none = CanonicalEvaluation(mode: EvaluationMode.none);

  final EvaluationMode mode;

  /// Select item modes.
  final List<String> correctItemIds;

  /// Select inline gaps, Arrange gapAssignments, Assign.
  final List<TargetAssignment> assignments;

  /// Input with one field (expressions in the expression mode, literal
  /// texts otherwise), Speak transcriptions.
  final List<String> answers;

  /// Extra accepted texts that are never parsed as expressions.
  final List<String> literalAnswers;

  /// Input with inline gaps: one entry per target.
  final List<TargetAnswers> targetAnswers;

  /// Input numeric modes.
  final NumericAnswer? numeric;

  /// Input regex mode.
  final String pattern;

  /// Arrange order modes.
  final List<OrderedAnswer> correctOrders;

  /// Match: `[leftId, rightId]` pairs.
  final List<List<String>> relations;

  /// Assign acceptedTargets.
  final List<AcceptedTarget> acceptedTargets;

  static const knownKeys = {
    'mode',
    'correctItemIds',
    'assignments',
    'answers',
    'literalAnswers',
    'targetAnswers',
    'numeric',
    'pattern',
    'correctOrders',
    'relations',
    'acceptedTargets',
  };

  /// The IDs of the items the evaluation refers to, in every field.
  Set<String> get referencedItemIds => {
    ...correctItemIds,
    for (final assignment in assignments) ...assignment.itemIds,
    for (final order in correctOrders) ...order.itemIds,
    for (final relation in relations) ...relation,
    for (final accepted in acceptedTargets) accepted.itemId,
  };

  /// The IDs of the targets the evaluation refers to, in every field.
  Set<String> get referencedTargetIds => {
    for (final assignment in assignments) assignment.targetId,
    for (final answers in targetAnswers) answers.targetId,
    for (final accepted in acceptedTargets) ...accepted.targetIds,
  };

  Map<String, dynamic> toJson() => {
    'mode': mode.serialized,
    if (correctItemIds.isNotEmpty) 'correctItemIds': correctItemIds,
    if (assignments.isNotEmpty)
      'assignments': assignments.map((a) => a.toJson()).toList(),
    if (answers.isNotEmpty) 'answers': answers,
    if (literalAnswers.isNotEmpty) 'literalAnswers': literalAnswers,
    if (targetAnswers.isNotEmpty)
      'targetAnswers': targetAnswers.map((a) => a.toJson()).toList(),
    if (numeric != null) 'numeric': numeric!.toJson(),
    if (pattern.isNotEmpty) 'pattern': pattern,
    if (correctOrders.isNotEmpty)
      'correctOrders': correctOrders.map((o) => o.toJson()).toList(),
    if (relations.isNotEmpty) 'relations': relations,
    if (acceptedTargets.isNotEmpty)
      'acceptedTargets': acceptedTargets.map((a) => a.toJson()).toList(),
  };

  factory CanonicalEvaluation.fromJson(Map<String, dynamic> j) {
    _refuseUnknownKeys(j, knownKeys, 'evaluation');
    final mode = EvaluationMode.tryParse(j['mode']);
    if (mode == null) {
      throw FormatException(
        'evaluation.mode “${j['mode'] ?? 'missing'}” is not a Course Model v12 evaluation mode.',
      );
    }
    final rawRelations = j['relations'];
    if (rawRelations != null && rawRelations is! List) {
      throw const FormatException('evaluation.relations must be a list.');
    }
    final relations = <List<String>>[
      if (rawRelations is List)
        for (final relation in rawRelations)
          if (relation is List &&
              relation.length == 2 &&
              relation.every((id) => id is String))
            [relation[0] as String, relation[1] as String]
          else
            throw const FormatException(
              'evaluation.relations entries must contain exactly two item IDs.',
            ),
    ];
    final numeric = j['numeric'];
    if (j.containsKey('numeric') && numeric is! Map) {
      throw const FormatException('evaluation.numeric must be an object.');
    }
    return CanonicalEvaluation(
      mode: mode,
      correctItemIds: _stringList(j, 'correctItemIds', 'evaluation'),
      assignments: _mapList(
        j,
        'assignments',
        'evaluation',
        TargetAssignment.fromJson,
      ),
      answers: _stringList(j, 'answers', 'evaluation'),
      literalAnswers: _stringList(j, 'literalAnswers', 'evaluation'),
      targetAnswers: _mapList(
        j,
        'targetAnswers',
        'evaluation',
        TargetAnswers.fromJson,
      ),
      numeric: numeric is Map
          ? NumericAnswer.fromJson(Map<String, dynamic>.from(numeric))
          : null,
      pattern: _optionalString(j, 'pattern', ''),
      correctOrders: _mapList(
        j,
        'correctOrders',
        'evaluation',
        OrderedAnswer.fromJson,
      ),
      relations: relations,
      acceptedTargets: _mapList(
        j,
        'acceptedTargets',
        'evaluation',
        AcceptedTarget.fromJson,
      ),
    );
  }

  CanonicalEvaluation copyWith({
    EvaluationMode? mode,
    List<String>? correctItemIds,
    List<TargetAssignment>? assignments,
    List<String>? answers,
    List<String>? literalAnswers,
    List<TargetAnswers>? targetAnswers,
    List<OrderedAnswer>? correctOrders,
    List<List<String>>? relations,
    List<AcceptedTarget>? acceptedTargets,
  }) => CanonicalEvaluation(
    mode: mode ?? this.mode,
    correctItemIds: correctItemIds ?? this.correctItemIds,
    assignments: assignments ?? this.assignments,
    answers: answers ?? this.answers,
    literalAnswers: literalAnswers ?? this.literalAnswers,
    targetAnswers: targetAnswers ?? this.targetAnswers,
    numeric: numeric,
    pattern: pattern,
    correctOrders: correctOrders ?? this.correctOrders,
    relations: relations ?? this.relations,
    acceptedTargets: acceptedTargets ?? this.acceptedTargets,
  );
}

/// Which other accepted answers the learner is shown after answering.
enum FeedbackAlternatives {
  none('none'),

  /// Up to three when wrong and two when right, ranked by similarity.
  ranked('ranked'),

  /// Every accepted answer, in author order.
  all('all');

  const FeedbackAlternatives(this.serialized);
  final String serialized;

  static FeedbackAlternatives? tryParse(Object? value) {
    if (value is! String) return null;
    for (final alternatives in values) {
      if (alternatives.serialized == value) return alternatives;
    }
    return null;
  }
}

final class ExerciseFeedback {
  const ExerciseFeedback({
    this.correct = '',
    this.incorrect = '',
    this.showAlternatives = FeedbackAlternatives.none,
  });

  static const empty = ExerciseFeedback();

  final String correct;
  final String incorrect;
  final FeedbackAlternatives showAlternatives;

  bool get isEmpty =>
      correct.isEmpty &&
      incorrect.isEmpty &&
      showAlternatives == FeedbackAlternatives.none;

  static const _keys = {'correct', 'incorrect', 'showAlternatives'};

  Map<String, dynamic> toJson() => {
    if (correct.isNotEmpty) 'correct': correct,
    if (incorrect.isNotEmpty) 'incorrect': incorrect,
    if (showAlternatives != FeedbackAlternatives.none)
      'showAlternatives': showAlternatives.serialized,
  };

  factory ExerciseFeedback.fromJson(Map<String, dynamic> j) {
    _refuseUnknownKeys(j, _keys, 'feedback');
    var alternatives = FeedbackAlternatives.none;
    if (j.containsKey('showAlternatives')) {
      final parsed = FeedbackAlternatives.tryParse(j['showAlternatives']);
      if (parsed == null) {
        throw FormatException(
          'feedback.showAlternatives “${j['showAlternatives']}” must be none, ranked or all.',
        );
      }
      alternatives = parsed;
    }
    return ExerciseFeedback(
      correct: _optionalString(j, 'correct', ''),
      incorrect: _optionalString(j, 'incorrect', ''),
      showAlternatives: alternatives,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseFeedback &&
      other.correct == correct &&
      other.incorrect == incorrect &&
      other.showAlternatives == showAlternatives;

  @override
  int get hashCode => Object.hash(correct, incorrect, showAlternatives);
}
