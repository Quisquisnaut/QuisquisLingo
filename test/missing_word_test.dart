import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  test('Missing Word round-trips and audits cleanly', () {
    final ex = Exercise(
      id: 'missingword01', type: 'missing_word', prompt: 'Vorrei comprare un biglietto per Roma.',
      question: '', answers: const [], correct: null, tts: 'Vorrei comprare un biglietto per Roma.',
      accepted: const [], tokens: const [], orderAnswer: const [], pairs: const [], hint: '', icons: const [],
      missingWords: const ['biglietto'],
    );
    final content = LearningContent.fromExercise(ex);
    final parsed = LearningContent.fromJson(content.toJson()).exercise!;
    expect(parsed.missingWords, const ['biglietto']);
    expect(CourseAuditService().auditExercise(parsed).where((i) => i.severity == AuditSeverity.error), isEmpty);
  });

  test('Missing Word flags a word absent from transcript', () {
    final ex = Exercise(
      id: 'missingword02', type: 'missing_word', prompt: 'Vado a Roma.', question: '', answers: const [],
      correct: null, tts: 'Vado a Roma.', accepted: const [], tokens: const [], orderAnswer: const [], pairs: const [],
      hint: '', icons: const [], missingWords: const ['Milano'],
    );
    expect(CourseAuditService().auditExercise(ex).any((i) => i.severity == AuditSeverity.error), isTrue);
  });
}
