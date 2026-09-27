/// The nine canonical exercise primitives of Course Model v12 (Build 256).
///
/// A primitive names the fundamental action the learner performs. Everything
/// else about an exercise, how the primitive behaves, what it shows, how it is
/// graded, lives in its options, content, items, targets, layout and
/// evaluation. Presets are authoring recipes over these and never add a
/// primitive: translation, cloze, multiple choice, true/false, comprehension,
/// hotspot, dialogue and Stories are all expressed through these nine plus
/// options, media, layout, evaluation and content flow.
///
/// The serialized identifiers are stable and lowercase. Parsing is strict:
/// `Select` or `SELECT` are not accepted, and an unknown value never becomes
/// a primitive silently.
enum ExercisePrimitive {
  select(
    'select',
    'Select',
    'The learner selects one or more selectable entities.',
  ),
  input(
    'input',
    'Input',
    'The learner enters textual, symbolic or numeric information.',
  ),
  arrange(
    'arrange',
    'Arrange',
    'The learner orders or places item occurrences into an ordered result.',
  ),
  match(
    'match',
    'Match',
    'The learner establishes relationships between peer items.',
  ),
  assign(
    'assign',
    'Assign',
    'The learner places items into explicit targets, categories, gaps, '
        'regions or cells.',
  ),
  speak('speak', 'Speak', 'The learner produces speech.'),
  ink('ink', 'Ink', 'The learner produces spatial strokes.'),
  submit(
    'submit',
    'Submit',
    'The learner supplies an artifact that QQL does not necessarily '
        'interpret directly.',
  ),
  presentation(
    'presentation',
    'Presentation',
    'The learner consumes instructional material without an ordinary scored '
        'response.',
  );

  const ExercisePrimitive(this.serialized, this.label, this.learnerAction);

  /// The stable identifier written to Course JSON.
  final String serialized;

  /// The author-facing English name.
  final String label;

  /// The fundamental learner action, one sentence.
  final String learnerAction;

  /// The primitives whose learner runtime exists today. Kept here only as a
  /// documentation aid; executability is decided per exercise by the
  /// capability registry's runtime-support table, never by the primitive
  /// alone.
  static const executableToday = <ExercisePrimitive>[
    select,
    input,
    arrange,
    match,
    presentation,
  ];

  /// Every stable identifier, in declaration order.
  static List<String> get serializedValues =>
      values.map((primitive) => primitive.serialized).toList(growable: false);

  /// The primitive whose identifier is exactly [value], or null. Strict: no
  /// trimming, no case folding, and only a String can match.
  static ExercisePrimitive? tryParse(Object? value) {
    if (value is! String) return null;
    for (final primitive in values) {
      if (primitive.serialized == value) return primitive;
    }
    return null;
  }

  /// Like [tryParse] but throws a [FormatException] naming the value and the
  /// legal identifiers when nothing matches.
  static ExercisePrimitive parse(Object? value) =>
      tryParse(value) ??
      (throw FormatException(
        'Unknown exercise primitive: ${value ?? 'null'}. Course Model v12 '
        'primitives are ${serializedValues.join(', ')}.',
      ));
}
