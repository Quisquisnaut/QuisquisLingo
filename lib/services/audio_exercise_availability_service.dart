import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'recorded_audio_service.dart';

enum EffectiveRoundAudioAvailability {
  none,
  available,
  audioExercisesDisabled,
  ttsDisabled,
  unavailable,
}

/// Resolves learner audio availability without creating a playback controller.
class AudioExerciseAvailabilityService {
  final RecordedAudioService _recordedAudio;

  AudioExerciseAvailabilityService({RecordedAudioService? recordedAudio})
    : _recordedAudio = recordedAudio ?? RecordedAudioService();

  /// An exercise the learner cannot solve without audio: one with a required
  /// audio element (the default for audio; optional audio, such as Pick the
  /// translation's, is stated with `required: false`). Canonical data only
  /// (Build 256).
  bool isAudioExercise(Exercise exercise) =>
      ExerciseFeatures(exercise).requiresAudio;

  Future<bool> hasRecordedSource(Course course, Exercise exercise) async {
    final text = _audioText(exercise);
    if (text.isEmpty) return false;
    final clips = _recordedAudio.segment(text, course.audioLibrary);
    if (clips == null || clips.isEmpty) return false;
    for (final clip in clips) {
      final source = await _recordedAudio.resolveSourceForClip(
        clip,
        courseId: course.courseId,
      );
      if (source == null) return false;
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

  Future<EffectiveRoundAudioAvailability> evaluateRound(
    Course course,
    LearningRound round, {
    required bool audioExercisesEnabled,
    required bool ttsEnabled,
  }) async {
    final audioExercises = round.exercises
        .where(isAudioExercise)
        .toList(growable: false);
    if (audioExercises.isEmpty) {
      return EffectiveRoundAudioAvailability.none;
    }
    if (!audioExercisesEnabled) {
      return EffectiveRoundAudioAvailability.audioExercisesDisabled;
    }
    for (final exercise in audioExercises) {
      if (await isAvailable(course, exercise, ttsEnabled: ttsEnabled)) {
        return EffectiveRoundAudioAvailability.available;
      }
    }
    if (!ttsEnabled) {
      for (final exercise in audioExercises) {
        if (await isAvailable(course, exercise, ttsEnabled: true)) {
          return EffectiveRoundAudioAvailability.ttsDisabled;
        }
      }
    }
    return EffectiveRoundAudioAvailability.unavailable;
  }

  String _audioText(Exercise exercise) {
    final features = ExerciseFeatures(exercise);
    final contextual = features.contextAudio.trim();
    if (contextual.isNotEmpty) return contextual;
    return features.primaryAudioText ?? '';
  }
}
