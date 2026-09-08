import '../models/course_models.dart';
import 'recorded_audio_service.dart';

/// Resolves learner audio availability without creating a playback controller.
class AudioExerciseAvailabilityService {
  final RecordedAudioService _recordedAudio;

  AudioExerciseAvailabilityService({RecordedAudioService? recordedAudio})
    : _recordedAudio = recordedAudio ?? RecordedAudioService();

  bool isAudioExercise(Exercise exercise) {
    final spokenText = exercise.tts?.trim() ?? '';
    return exercise.type == 'audio_match' ||
        exercise.type == 'listening_choice' ||
        exercise.type == 'listening_comprehension' ||
        exercise.type == 'listening_spelling' ||
        exercise.type == 'missing_word' ||
        (exercise.type == 'contextual_comprehension' &&
            exercise.contextAudio.trim().isNotEmpty) ||
        spokenText.isNotEmpty;
  }

  Future<bool> hasRecordedSource(Course course, Exercise exercise) async {
    final text = _audioText(exercise);
    if (text.isEmpty) return false;
    final clips = _recordedAudio.segment(text, course.audioLibrary);
    if (clips == null || clips.isEmpty) return false;
    for (final clip in clips) {
      if (await _recordedAudio.resolveSourceForClip(clip) == null) return false;
    }
    return true;
  }

  Future<bool> isAvailable(
    Course course,
    Exercise exercise, {
    required bool ttsEnabled,
  }) async {
    if (!isAudioExercise(exercise)) return true;
    return switch (course.audioMode) {
      'recorded' => await hasRecordedSource(course, exercise),
      'hybrid' => await hasRecordedSource(course, exercise) || ttsEnabled,
      _ => ttsEnabled,
    };
  }

  String _audioText(Exercise exercise) {
    final contextual = exercise.contextAudio.trim();
    if (contextual.isNotEmpty) return contextual;
    return exercise.tts?.trim() ?? '';
  }
}
