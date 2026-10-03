import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/round_type_presentation.dart';

void main() {
  final round = LearningRound(
    id: 'round-1',
    title: 'Greetings',
    roundType: RoundType.practice,
  );

  test('Round numbering defaults to Off in an existing v12 Course', () {
    final course = Course(
      courseId: 'course-test',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Test Course',
      ttsLanguage: 'it',
      lessons: const [],
    );
    final oldJson = Map<String, dynamic>.of(course.toJson())
      ..remove('roundNumberingMode');
    expect(Course.fromJson(oldJson).roundNumberingMode, RoundNumberingMode.off);
  });

  test('all Round numbering modes preserve the author title', () {
    expect(
      RoundTypePresentation.title(round, 2, RoundNumberingMode.off),
      'Practice · Greetings',
    );
    expect(
      RoundTypePresentation.title(round, 2, RoundNumberingMode.roundAndNumber),
      'Round 2 · Practice · Greetings',
    );
    expect(
      RoundTypePresentation.title(round, 2, RoundNumberingMode.numberOnly),
      '2 · Practice · Greetings',
    );
    expect(
      RoundTypePresentation.title(
        round,
        2,
        RoundNumberingMode.customAndNumber,
        customPrefix: 'Step',
      ),
      'Step 2 · Practice · Greetings',
    );
    final numberedTitle = LearningRound(
      id: 'round-2',
      title: 'Round 2',
      roundType: RoundType.practice,
    );
    expect(
      RoundTypePresentation.title(numberedTitle, 2, RoundNumberingMode.off),
      'Practice · Round 2',
    );
  });

  test('the type labels and icons are distinct', () {
    expect(RoundTypePresentation.label(RoundType.listening), 'Listen');
    expect(RoundTypePresentation.label(RoundType.reading), 'Read');
    expect(RoundTypePresentation.label(RoundType.flashcard), 'FlashCard');
    expect(
      {
        for (final type in RoundType.values) RoundTypePresentation.icon(type),
      }.length,
      RoundType.values.length,
    );
  });
}
