import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';

void main() {
  test(
    'v6 course export/import preserves timestamps and every block answer',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'qql_v6_transfer_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final service = CustomCourseTransferService(
        directory: () async => directory,
      );
      final original = _course();
      final exportPath = await service.exportCourse(original);
      await File(
        exportPath,
      ).rename('${directory.path}${Platform.pathSeparator}import.json');

      final restored = await service.importCourse();
      final exercise = restored.lessons.single.rounds.single.exercises.single;
      expect(restored.toJson(), original.toJson());
      expect(exercise.correctTranslationTexts, [
        'Come stai?',
        'Come va?',
        'Come te la passi?',
      ]);
      expect(exercise.updatedAt, DateTime.utc(2026, 9, 4, 12, 3));
    },
  );

  test(
    'old format import fails clearly and leaves the source file intact',
    () async {
      final directory = await Directory.systemTemp.createTemp('qql_v5_reject_');
      addTearDown(() => directory.delete(recursive: true));
      final service = CustomCourseTransferService(
        directory: () async => directory,
      );
      final importFile = File(
        '${directory.path}${Platform.pathSeparator}import.json',
      );
      await importFile.writeAsString(
        '{"formatVersion":5,"courseId":"legacy","lessons":[]}',
      );

      await expectLater(
        service.importCourse(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('formatVersion 6 only'),
          ),
        ),
      );
      expect(await importFile.exists(), isTrue);
      expect(await importFile.readAsString(), contains('"formatVersion":5'));
    },
  );
}

Course _course() {
  final lessonTime = DateTime.utc(2026, 9, 4, 12, 1);
  final roundTime = DateTime.utc(2026, 9, 4, 12, 2);
  final exerciseTime = DateTime.utc(2026, 9, 4, 12, 3);
  final exercise = Exercise(
    id: 'transfer-exercise',
    publicationState: PublicationState.draft,
    updatedAt: exerciseTime,
    type: 'build_translation',
    prompt: 'How are you?',
    question: '',
    answers: const [],
    correct: null,
    tts: null,
    accepted: const [],
    tokens: const ['Come', 'stai', 'va', 'te', 'la', 'passi'],
    orderAnswer: const [],
    correctTranslations: const ['Come stai?', 'Come va?', 'Come te la passi?'],
    pairs: const [],
    hint: '',
    icons: const [],
  );
  final round = LearningRound(
    id: 'transfer-round',
    publicationState: PublicationState.draft,
    updatedAt: roundTime,
    title: '',
    exercises: [exercise],
  );
  final lesson = Lesson(
    lessonId: 'transfer-lesson',
    publicationState: PublicationState.draft,
    updatedAt: lessonTime,
    title: 'Transfer',
    rounds: [round],
  );
  return Course(
    courseId: 'user_transfer_v6',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Transfer v6',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
}
