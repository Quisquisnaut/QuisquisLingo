import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/course_models.dart';
import 'app_metadata.dart';

enum ReportKind { bug, courseError }

class ReportService {
  static const String appVersion = AppMetadata.version;

  String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  Future<void> copyExerciseReport({
    required ReportKind kind,
    required Course course,
    required Lesson lesson,
    required LearningRound round,
    required Exercise exercise,
    required int exerciseIndex,
    String? screen,
    String? answerState,
  }) async {
    final label = kind == ReportKind.bug ? 'APP BUG' : 'COURSE ERROR';
    final buffer = StringBuffer()
      ..writeln('QuisquisLingo report: $label')
      ..writeln('Please describe the problem below:')
      ..writeln('[add details here]')
      ..writeln()
      ..writeln('App version: $appVersion')
      ..writeln('Platform: ${_platformName()}')
      ..writeln('Course: ${course.title} (${course.courseId})')
      ..writeln('Course version: ${course.version}')
      ..writeln('Lesson: ${lesson.lessonId} | ${lesson.title}')
      ..writeln('Round: ${round.id} | ${round.title}')
      ..writeln('Exercise: ${exercise.id}')
      ..writeln(
        'Exercise position: ${exerciseIndex + 1}/${round.exercises.length}',
      )
      ..writeln('Exercise type: ${exercise.type}');

    if (screen != null && screen.trim().isNotEmpty) {
      buffer.writeln('Screen: $screen');
    }
    if (answerState != null && answerState.trim().isNotEmpty) {
      buffer.writeln('Answer state: $answerState');
    }
    if (exercise.prompt.trim().isNotEmpty) {
      buffer.writeln('Prompt: ${exercise.prompt}');
    }
    if (exercise.question.trim().isNotEmpty) {
      buffer.writeln('Question: ${exercise.question}');
    }
    if (exercise.tts != null && exercise.tts!.trim().isNotEmpty) {
      buffer.writeln('TTS: ${exercise.tts}');
    }
    if (exercise.answers.isNotEmpty) {
      buffer.writeln('Choices: ${exercise.answers.join(' | ')}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trimRight()));
  }
}
