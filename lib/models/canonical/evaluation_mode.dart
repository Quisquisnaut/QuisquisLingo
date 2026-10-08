/// How an exercise decides correctness (Course Model v12).
///
/// The registry ([PrimitiveCapabilityRegistry]) says which modes each
/// primitive may use; a mode is never legal merely because it exists here.
/// `manual` and `none` are shared by several primitives. Identifiers are
/// stable lowerCamelCase and parsing is strict.
enum EvaluationMode {
  // Select
  exactItem('exactItem'),
  exactSet('exactSet'),
  subset('subset'),
  orderedSelections('orderedSelections'),
  perSelection('perSelection'),
  // Input
  exactText('exactText'),
  acceptedTexts('acceptedTexts'),
  expression('expression'),
  numericExact('numericExact'),
  numericRange('numericRange'),
  numericTolerance('numericTolerance'),
  regex('regex'),
  // Arrange
  exactOrder('exactOrder'),
  acceptedOrders('acceptedOrders'),
  gapAssignments('gapAssignments'),
  // Match
  exactRelations('exactRelations'),
  requiredRelations('requiredRelations'),
  partialRelations('partialRelations'),
  // Assign
  exactAssignments('exactAssignments'),
  acceptedTargets('acceptedTargets'),
  categoryMembership('categoryMembership'),
  partialAssignments('partialAssignments'),
  // Speak
  transcriptionMatch('transcriptionMatch'),
  acceptedTranscriptions('acceptedTranscriptions'),
  pronunciation('pronunciation'),
  combined('combined'),
  // Ink
  recognition('recognition'),
  strokeMatch('strokeMatch'),
  shapeSimilarity('shapeSimilarity'),
  // Submit
  presence('presence'),
  // Shared
  manual('manual'),
  none('none');

  const EvaluationMode(this.serialized);

  /// The stable identifier written to Course JSON.
  final String serialized;

  /// Every stable identifier, in declaration order.
  static List<String> get serializedValues =>
      values.map((mode) => mode.serialized).toList(growable: false);

  /// The mode whose identifier is exactly [value], or null. Strict: only a
  /// String can match, with no trimming or case folding.
  static EvaluationMode? tryParse(Object? value) {
    if (value is! String) return null;
    for (final mode in values) {
      if (mode.serialized == value) return mode;
    }
    return null;
  }

  /// Like [tryParse] but throws a [FormatException] when nothing matches.
  static EvaluationMode parse(Object? value) =>
      tryParse(value) ??
      (throw FormatException(
        'Unknown evaluation mode: ${value ?? 'null'}. Course Model v12 '
        'evaluation modes are ${serializedValues.join(', ')}.',
      ));
}
