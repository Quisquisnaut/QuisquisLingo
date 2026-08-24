enum AppErrorCode {
  courseFileMissing('COURSE-001', 'Course file missing.'),
  invalidCourseData('COURSE-002', 'Course data could not be read.'),
  unsupportedExerciseType('COURSE-003', 'This exercise type is not supported.'),

  ttsUnavailable('TTS-001', 'Text-to-speech is unavailable.'),
  ttsVoiceUnavailable('TTS-002', 'The selected voice or language is unavailable.'),
  ttsSynthesisFailed('TTS-003', 'Audio could not be generated.'),
  ttsCacheWriteFailed('TTS-004', 'Audio could not be saved to the local cache.'),

  localStorageError('DATA-001', 'Local data could not be saved or loaded.'),
  corruptedProgressData('DATA-002', 'Local progress data appears to be invalid.'),

  duelInsufficientExercises('DUEL-001', 'This Chapter does not contain enough exercises for a Language Duel.'),

  unexpectedError('APP-001', 'An unexpected internal error occurred.');

  final String code;
  final String userMessage;

  const AppErrorCode(this.code, this.userMessage);
}

class AppException implements Exception {
  final AppErrorCode error;
  final String? technicalMessage;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppException(
    this.error, {
    this.technicalMessage,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() =>
      '${error.code}: ${technicalMessage ?? error.userMessage}';
}
