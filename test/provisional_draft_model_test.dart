import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/publication_service.dart';

void main() {
  test('parent constructors default false and omit the optional marker', () {
    final round = LearningRound(id: 'new-round', title: '', content: const []);
    final lesson = Lesson(
      lessonId: 'new-lesson',
      title: 'Lesson',
      rounds: [round],
    );
    expect(lesson.provisionalDraft, isFalse);
    expect(round.provisionalDraft, isFalse);
    expect(lesson.toJson(), isNot(contains('provisionalDraft')));
    expect(round.toJson(), isNot(contains('provisionalDraft')));
  });

  for (final state in PublicationState.values) {
    test(
      'legacy ${state.name} parents default to non-provisional without migration',
      () {
        final json = _courseJson();
        final rawLesson =
            (json['lessons'] as List).first as Map<String, dynamic>;
        final rawRound =
            (rawLesson['rounds'] as List).first as Map<String, dynamic>;
        rawLesson['publicationState'] = state.name;
        rawRound['publicationState'] = state.name;
        final course = Course.fromJson(json);
        final lesson = course.lessons.first;
        final round = lesson.rounds.first;
        expect(course.formatVersion, 6);
        expect(lesson.publicationState, state);
        expect(round.publicationState, state);
        expect(lesson.provisionalDraft, isFalse);
        expect(round.provisionalDraft, isFalse);
        expect(lesson.toJson(), isNot(contains('provisionalDraft')));
        expect(round.toJson(), isNot(contains('provisionalDraft')));
        expect(Course.fromJson(course.toJson()).toJson(), course.toJson());
      },
    );

    test(
      'true marker round trips with ${state.name} and complete v6 parent fields',
      () {
        final json = _courseJson();
        final rawLesson =
            (json['lessons'] as List).first as Map<String, dynamic>;
        final rawRound =
            (rawLesson['rounds'] as List).first as Map<String, dynamic>;
        rawLesson['publicationState'] = state.name;
        rawRound['publicationState'] = state.name;
        final before = Course.fromJson(json);
        rawLesson['provisionalDraft'] = true;
        rawRound['provisionalDraft'] = true;
        final marked = Course.fromJson(json);
        final reloaded = Course.fromJson(
          jsonDecode(jsonEncode(marked.toJson())) as Map<String, dynamic>,
        );
        final lesson = reloaded.lessons.first;
        final round = lesson.rounds.first;
        expect(reloaded.formatVersion, 6);
        expect(lesson.provisionalDraft, isTrue);
        expect(round.provisionalDraft, isTrue);
        expect(lesson.publicationState, state);
        expect(round.publicationState, state);
        expect(reloaded.toJson(), marked.toJson());
        // Removing only the two added fields recovers the entire prior canonical
        // Course: identities, timestamps, GuideBook, Duel, Sections, icon and
        // complete Exercise/Content data are not reconstructed or dropped.
        final withoutMarkers = reloaded.toJson();
        final restoredLesson = (withoutMarkers['lessons'] as List).first as Map;
        restoredLesson.remove('provisionalDraft');
        ((restoredLesson['rounds'] as List).first as Map).remove(
          'provisionalDraft',
        );
        expect(withoutMarkers, before.toJson());
      },
    );
  }

  test(
    'explicit false parses and canonical output omits only the false marker',
    () {
      final original = Course.fromJson(_courseJson());
      final json = original.toJson();
      final lesson = (json['lessons'] as List).first as Map;
      lesson['provisionalDraft'] = false;
      ((lesson['rounds'] as List).first as Map)['provisionalDraft'] = false;
      final parsed = Course.fromJson(json);
      expect(parsed.lessons.first.provisionalDraft, isFalse);
      expect(parsed.lessons.first.rounds.first.provisionalDraft, isFalse);
      expect(parsed.toJson(), original.toJson());
    },
  );

  test(
    'present malformed markers are rejected rather than coerced or defaulted',
    () {
      final course = Course.fromJson(_courseJson());
      for (final value in <Object?>[null, '', 'true', 'false', 0, 1, [], {}]) {
        expect(
          () => Lesson.fromJson({
            ...course.lessons.first.toJson(),
            'provisionalDraft': value,
          }),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'lesson.provisionalDraft must be a boolean.',
            ),
          ),
          reason: 'Lesson marker $value',
        );
        expect(
          () => LearningRound.fromJson({
            ...course.lessons.first.rounds.first.toJson(),
            'provisionalDraft': value,
          }),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'round.provisionalDraft must be a boolean.',
            ),
          ),
          reason: 'Round marker $value',
        );
      }
    },
  );

  test(
    'a provisional Lesson stays hidden until its publication state changes',
    () {
      final json = _courseJson();
      final lesson = (json['lessons'] as List).first as Map;
      lesson['publicationState'] = 'draft';
      lesson['provisionalDraft'] = true;
      final course = Course.fromJson(json);
      final visible = const PublicationService().learnerCourse(course)!;
      expect(
        visible.lessons.map((item) => item.lessonId),
        isNot(contains(course.lessons.first.lessonId)),
      );
      expect(course.lessons.first.publicationState, PublicationState.draft);
      expect(course.lessons.first.provisionalDraft, isTrue);
    },
  );

  test(
    'a provisional Round stays hidden inside an otherwise Published Lesson',
    () {
      final json = _courseJson();
      final lesson = (json['lessons'] as List).first as Map;
      final round = (lesson['rounds'] as List).first as Map;
      round['publicationState'] = 'draft';
      round['provisionalDraft'] = true;
      final course = Course.fromJson(json);
      final visible = const PublicationService().learnerCourse(course)!;
      expect(visible.lessons.first.lessonId, course.lessons.first.lessonId);
      expect(
        visible.lessons.first.rounds.map((item) => item.id),
        isNot(contains(course.lessons.first.rounds.first.id)),
      );
      expect(
        course.lessons.first.rounds.first.publicationState,
        PublicationState.draft,
      );
      expect(course.lessons.first.rounds.first.provisionalDraft, isTrue);
    },
  );
}

Map<String, dynamic> _courseJson() =>
    jsonDecode(File('assets/courses/italian_en.json').readAsStringSync())
        as Map<String, dynamic>;
