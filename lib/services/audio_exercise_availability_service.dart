import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'recorded_audio_service.dart';
import 'sound_answers.dart';

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

  Future<bool> hasRecordedSource(Course course, Exercise exercise) =>
      _recorded(course, _audioText(exercise));

  /// Whether recordings of [course] say [text] from end to end and their
  /// files are there.
  Future<bool> _recorded(Course course, String text) async {
    if (text.isEmpty) return false;
    final clips = _recordedAudio.segment(text, course.audioLibrary);
    if (clips == null || clips.isEmpty) return false;
    for (final clip in clips) {
      if (!await _hasFile(course, clip)) return false;
    }
    return true;
  }

  Future<bool> _hasFile(Course course, CourseAudioClip clip) async =>
      await _recordedAudio.resolveSourceForClip(
        clip,
        courseId: course.courseId,
      ) !=
      null;

  Future<bool> isAvailable(
    Course course,
    Exercise exercise, {
    required bool ttsEnabled,
  }) async {
    if (!isAudioExercise(exercise)) return true;
    final f = ExerciseFeatures(exercise);
    if (f.kind == LearnerExerciseKind.selectSounds) {
      return _soundsAvailable(course, exercise, f, ttsEnabled: ttsEnabled);
    }
    return switch (course.audioMode) {
      'recorded' => await hasRecordedSource(course, exercise),
      'hybrid' => await hasRecordedSource(course, exercise) || ttsEnabled,
      _ => ttsEnabled,
    };
  }

  /// A text spoken in [course]'s audio mode.
  Future<bool> _textAvailable(
    Course course,
    String text, {
    required bool ttsEnabled,
  }) async => switch (course.audioMode) {
    'recorded' => await _recorded(course, text),
    'hybrid' => await _recorded(course, text) || ttsEnabled,
    _ => ttsEnabled,
  };

  /// Answers that are sounds (Build 274 Revision 3): the spoken sentence and
  /// every answer can play. A recording named by its id needs its Audio
  /// Library entry and its file, and never plays in On-Device TTS (owner
  /// decision of 16 October 2026).
  Future<bool> _soundsAvailable(
    Course course,
    Exercise exercise,
    ExerciseFeatures f, {
    required bool ttsEnabled,
  }) async {
    final sentence = _audioText(exercise).trim();
    if (sentence.isNotEmpty &&
        !await _textAvailable(course, sentence, ttsEnabled: ttsEnabled)) {
      return false;
    }
    for (final item in exercise.items) {
      final sound = f.soundOf(item);
      if (sound == null) return false;
      if (sound.recording.isNotEmpty) {
        final clip = SoundAnswers.recordingOf(sound, course.audioLibrary);
        if (course.audioMode == 'tts' ||
            clip == null ||
            !await _hasFile(course, clip)) {
          return false;
        }
        continue;
      }
      final text = sound.text.trim();
      if (text.isEmpty ||
          !await _textAvailable(course, text, ttsEnabled: ttsEnabled)) {
        return false;
      }
    }
    return true;
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
