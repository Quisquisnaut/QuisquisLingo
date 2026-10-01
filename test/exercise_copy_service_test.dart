import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';

Course _course({
  required String sourceLanguage,
  required String interfaceLanguage,
}) => Course(
  courseId: 'test',
  learningLanguage: 'XX',
  interfaceLanguage: interfaceLanguage,
  sourceLanguage: sourceLanguage,
  targetLanguage: 'Target',
  title: 'Test',
  ttsLanguage: 'xx-XX',
  lessons: const [],
);

void main() {
  test('exercise copy follows English source language', () {
    final course = _course(sourceLanguage: 'English', interfaceLanguage: 'EN');
    expect(
      ExerciseCopyService.typeLabel(course, LearnerExerciseKind.matchAudio),
      'MATCH THE AUDIO',
    );
    expect(
      ExerciseCopyService.instruction(course, LearnerExerciseKind.matchAudio),
      // Build 259 Revision 7: no line repeats its title.
      'Pair each sound with its word.',
    );
  });

  test('exercise copy follows Spanish source language', () {
    final course = _course(sourceLanguage: 'Spanish', interfaceLanguage: 'ES');
    expect(
      ExerciseCopyService.typeLabel(course, LearnerExerciseKind.matchAudio),
      'RELACIONA EL AUDIO',
    );
    expect(
      ExerciseCopyService.instruction(course, LearnerExerciseKind.matchAudio),
      'Empareja cada audio con su palabra.',
    );
  });

  test('legacy target-language instruction is suppressed', () {
    expect(
      ExerciseCopyService.isLegacyInstruction('Ordne die Gegensätze zu.'),
      isTrue,
    );
    expect(
      ExerciseCopyService.isLegacyInstruction('Marco entra in un bar.'),
      isFalse,
    );
  });
}
