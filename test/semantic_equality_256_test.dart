import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';

import 'support/canonical_course_256.dart';

/// Build 256 Revision 7 (plan A.13): semantic equality of exercises. Two
/// exercises are the same exercise when their canonical content is the
/// same with every default option filled in; authoring metadata, the
/// timestamp and the publication state do not count; IDs, item order and
/// texts do. A JSON round trip keeps the semantics.
Exercise _select({
  String id = 'q',
  Map<OptionKey, OptionValue> options = const {},
  List<String> choices = const ['gatto', 'cane'],
  Map<String, Object?> metadata = const {},
  DateTime? updatedAt,
  PublicationState publicationState = PublicationState.published,
}) => Exercise.canonical(
  id: id,
  publicationState: publicationState,
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 28),
  primitive: ExercisePrimitive.select,
  options: PrimitiveOptions(options),
  promptElements: const [
    PromptElement(type: 'text', role: 'question', text: 'Which is a cat?'),
  ],
  items: [
    for (var i = 0; i < choices.length; i++)
      ExerciseItem(
        id: '${id}_$i',
        content: [PromptElement(type: 'text', text: choices[i])],
      ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_0'],
  ),
  authoringMetadata: metadata,
);

void main() {
  test('an omitted option equals its explicit default', () {
    final omitted = _select();
    final explicit = _select(
      options: {
        OptionKey.selectionMode: const EnumOptionValue(SelectionMode.single),
        OptionKey.itemReuse: const EnumOptionValue(ItemReuse.forbidden),
      },
    );
    expect(omitted.options.isNotEmpty, isFalse);
    expect(explicit.options.isNotEmpty, isTrue);
    expect(omitted.semanticallyEquals(explicit), isTrue);
    expect(omitted.semanticJson(), explicit.semanticJson());
    expect(
      omitted.toJson(),
      isNot(explicit.toJson()),
      reason: 'the file keeps what was set',
    );
  });

  test('metadata, the timestamp and the publication state do not count', () {
    final plain = _select();
    expect(
      plain.semanticallyEquals(
        _select(metadata: const {'presetId': 'choice_target', 'tool': 'x'}),
      ),
      isTrue,
    );
    expect(
      plain.semanticallyEquals(_select(updatedAt: DateTime.utc(2027, 1, 1))),
      isTrue,
    );
    expect(
      plain.semanticallyEquals(
        _select(publicationState: PublicationState.draft),
      ),
      isTrue,
    );
    final json = plain.semanticJson();
    expect(json.containsKey('authoringMetadata'), isFalse);
    expect(json.containsKey('updatedAt'), isFalse);
    expect(json.containsKey('publicationState'), isFalse);
  });

  test('IDs, item order, texts and a real option count', () {
    final plain = _select();
    expect(plain.semanticallyEquals(_select(id: 'other')), isFalse);
    expect(
      plain.semanticallyEquals(_select(choices: const ['cane', 'gatto'])),
      isFalse,
      reason: 'the correct item changed with the order',
    );
    final reordered = plain.copyWith(items: [plain.items[1], plain.items[0]]);
    expect(
      plain.semanticallyEquals(reordered),
      isFalse,
      reason: 'item order counts',
    );
    expect(
      plain.semanticallyEquals(_select(choices: const ['gatto', 'casa'])),
      isFalse,
    );
    expect(
      plain.semanticallyEquals(
        _select(
          options: {OptionKey.layout: const EnumOptionValue(LayoutValue.grid)},
        ),
      ),
      isFalse,
    );
  });

  test('a JSON round trip keeps the semantics of every primitive', () {
    for (final exercise in canonicalCourse256().lessons.single.rounds.expand(
      (round) => round.exercises,
    )) {
      final restored = Exercise.fromJson(
        jsonDecode(jsonEncode(exercise.toJson())) as Map<String, dynamic>,
        contentId: exercise.id,
        publicationState: exercise.publicationState,
      );
      expect(
        restored.semanticallyEquals(exercise),
        isTrue,
        reason: exercise.id,
      );
      expect(
        restored
            .copyWith(authoringMetadata: const {'presetId': 'anything'})
            .semanticallyEquals(exercise),
        isTrue,
        reason: exercise.id,
      );
    }
  });
}
