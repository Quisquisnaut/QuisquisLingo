import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';

Course _course({required String sourceLanguage, required String interfaceLanguage}) => Course(
      courseId: 'test',
      learningLanguage: 'XX',
      interfaceLanguage: interfaceLanguage,
      sourceLanguage: sourceLanguage,
      targetLanguage: 'Target',
      title: 'Test',
      ttsLanguage: 'xx-XX',
      version: '1',
      chapters: const [],
    );

void main() {
  test('exercise copy follows English source language', () {
    final course = _course(sourceLanguage: 'English', interfaceLanguage: 'EN');
    expect(ExerciseCopyService.typeLabel(course, 'audio_match'), 'MATCH THE AUDIO');
    expect(
      ExerciseCopyService.instruction(course, 'audio_match'),
      'Listen and match each sound with the correct word.',
    );
  });

  test('exercise copy follows Spanish source language', () {
    final course = _course(sourceLanguage: 'Spanish', interfaceLanguage: 'ES');
    expect(ExerciseCopyService.typeLabel(course, 'audio_match'), 'RELACIONA EL AUDIO');
    expect(
      ExerciseCopyService.instruction(course, 'audio_match'),
      'Escucha y relaciona cada audio con la palabra correcta.',
    );
  });

  test('legacy target-language instruction is suppressed', () {
    expect(ExerciseCopyService.isLegacyInstruction('Ordne die Gegensätze zu.'), isTrue);
    expect(ExerciseCopyService.isLegacyInstruction('Marco entra in un bar.'), isFalse);
  });
}
