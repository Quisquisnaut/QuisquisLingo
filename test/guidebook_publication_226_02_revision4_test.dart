import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';

void main() {
  test(
    'existing v6 Guidebook JSON remains implicitly Published and unchanged',
    () {
      final json = <String, dynamic>{
        'content': [_content('existing').toJson()],
      };
      final encoded = jsonEncode(json);
      final guidebook = Guidebook.fromJson(json);

      expect(guidebook.publicationState, PublicationState.published);
      expect(jsonEncode(guidebook.toJson()), encoded);
      expect(Guidebook.empty().toJson(), {'content': <Object>[]});
      expect(
        Guidebook.fromJson({...json, 'publicationState': 'published'}).toJson(),
        json,
      );
    },
  );

  test('explicit empty Draft Guidebook survives Course JSON round-trip', () {
    final guidebook = Guidebook(
      publicationState: PublicationState.draft,
      content: const [],
    );
    expect(guidebook.toJson(), {
      'publicationState': 'draft',
      'content': <Object>[],
    });
    final original = _course(guidebook);
    final restored = Course.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(restored.formatVersion, 7);
    expect(restored.courseId, original.courseId);
    expect(restored.lessons.single.lessonId, original.lessons.single.lessonId);
    expect(
      restored.lessons.single.guidebook.publicationState,
      PublicationState.draft,
    );
    expect(restored.lessons.single.guidebook.content, isEmpty);
    expect(restored.toJson(), original.toJson());
  });

  test('present invalid Guidebook publication values are rejected', () {
    for (final invalid in <Object?>[null, '', 'Draft', 'unreviewed', 1, true]) {
      expect(
        () => Guidebook.fromJson({
          'publicationState': invalid,
          'content': <Object>[],
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'guidebook.publicationState must be draft or published.',
          ),
        ),
      );
    }
  });

  test(
    'Draft Guidebook is hidden while its Lesson and Round remain learner-visible',
    () {
      final guidebook = Guidebook(
        publicationState: PublicationState.draft,
        content: [_content('reviewed'), _content('unfinished', draft: true)],
      );
      final original = _course(guidebook);
      final before = jsonEncode(original.toJson());
      final learner = const PublicationService().learnerCourse(original)!;

      expect(learner.lessons.map((lesson) => lesson.lessonId), ['lesson']);
      final lesson = learner.lessons.single;
      expect(lesson.rounds.map((round) => round.id), ['round']);
      expect(lesson.rounds.single.exercises.single.id, 'exercise');
      expect(lesson.guidebook.publicationState, PublicationState.draft);
      expect(lesson.guidebook.content, isEmpty);
      expect(lesson.guidebook.toJson(), {
        'publicationState': 'draft',
        'content': <Object>[],
      });
      expect(jsonEncode(original.toJson()), before);
    },
  );

  test(
    'publishing the Guidebook restores Published content and still filters Draft children',
    () {
      final content = [
        _content('reviewed'),
        _content('unfinished', draft: true),
      ];
      final original = _course(
        Guidebook(publicationState: PublicationState.draft, content: content),
      );
      final published = _course(Guidebook(content: content));
      final service = const PublicationService();

      expect(
        service.learnerCourse(original)!.lessons.single.guidebook.content,
        isEmpty,
      );
      final visible = service
          .learnerCourse(published)!
          .lessons
          .single
          .guidebook;
      expect(visible.publicationState, PublicationState.published);
      expect(visible.content.map((item) => item.id), ['reviewed']);
      expect(visible.content.single.toJson(), content.first.toJson());
      expect(
        published.lessons.single.guidebook.content.map((item) => item.id),
        ['reviewed', 'unfinished'],
      );
    },
  );

  test(
    'publication Audit resolves provenance against hidden authored Guidebook IDs',
    () {
      final authoredJson = _course(
        Guidebook(
          publicationState: PublicationState.draft,
          content: [_content('guide')],
        ),
      ).toJson();
      final lessonJson = (authoredJson['lessons'] as List).single as Map;
      final roundJson = (lessonJson['rounds'] as List).single as Map;
      final exerciseJson = (roundJson['content'] as List).single as Map;
      exerciseJson['sourceRefs'] = ['guide', 'deleted-guide-content'];
      final authored = Course.fromJson(authoredJson);
      final learner = const PublicationService().learnerCourse(authored)!;
      final audit = CourseAuditService();

      expect(learner.lessons.single.guidebook.content, isEmpty);
      expect(
        audit
            .auditLesson(learner, 'lesson')
            .issues
            .where((issue) => issue.code == 'SOURCE_REF_MISSING'),
        hasLength(2),
      );
      final publicationReferenceIssues = audit
          .auditLesson(learner, 'lesson', sourceReferenceCourse: authored)
          .issues
          .where((issue) => issue.code == 'SOURCE_REF_MISSING')
          .toList();
      expect(publicationReferenceIssues, hasLength(1));
      expect(
        publicationReferenceIssues.single.message,
        contains('deleted-guide-content'),
      );
    },
  );

  for (final empty in [false, true]) {
    test(
      'import-as-Draft includes ${empty ? 'empty' : 'populated'} Guidebook state',
      () {
        final source = _course(
          Guidebook(content: empty ? [] : [_content('guide')]),
        );
        final imported = const PublicationService().asDraftAuthoringTree(
          source,
        );
        final guidebook = imported.lessons.single.guidebook;

        expect(guidebook.publicationState, PublicationState.draft);
        expect(
          guidebook.content.map((item) => item.id),
          empty ? [] : ['guide'],
        );
        expect(
          guidebook.content.every(
            (item) => item.publicationState == PublicationState.draft,
          ),
          isTrue,
        );
        expect(imported.courseId, source.courseId);
        expect(
          imported.lessons.single.lessonId,
          source.lessons.single.lessonId,
        );
        expect(
          source.lessons.single.guidebook.publicationState,
          PublicationState.published,
        );
        expect(
          source.lessons.single.guidebook.content.every(
            (item) => item.publicationState.isPublished,
          ),
          isTrue,
        );
      },
    );
  }

  for (final sourceState in PublicationState.values) {
    for (final empty in [false, true]) {
      test(
        'Lesson and Course duplication make ${sourceState.name} ${empty ? 'empty' : 'populated'} Guidebooks Draft',
        () {
          final original = _course(
            Guidebook(
              publicationState: sourceState,
              content: empty ? [] : [_content('guide')],
            ),
          );
          final service = AuthoringDuplicationService(
            ids: TimestampAuthoringIdGenerator(seed: 226024),
          );
          final lessonCopy = service.duplicateLesson(original.lessons.single);
          final courseCopy = service.duplicateCourse(original, title: 'Copy');
          for (final lesson in [lessonCopy, courseCopy.lessons.single]) {
            expect(lesson.publicationState, PublicationState.draft);
            expect(lesson.guidebook.publicationState, PublicationState.draft);
            expect(lesson.guidebook.content, hasLength(empty ? 0 : 1));
            if (!empty) {
              final content = lesson.guidebook.content.single;
              expect(content.id, isNot('guide'));
              expect(content.text, 'Reviewed overview for guide.');
              expect(content.publicationState, PublicationState.draft);
            }
            expect(
              Guidebook.fromJson(lesson.guidebook.toJson()).publicationState,
              PublicationState.draft,
            );
          }
          expect(
            original.lessons.single.guidebook.publicationState,
            sourceState,
          );
        },
      );
    }
  }
}

LearningContent _content(String id, {bool draft = false}) =>
    LearningContent.textual(
      id: id,
      publicationState: draft
          ? PublicationState.draft
          : PublicationState.published,
      kind: 'explanation',
      role: 'overview',
      text: 'Reviewed overview for $id.',
    );

Course _course(Guidebook guidebook) => Course(
  courseId: 'guidebook-publication-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Guidebook publication',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      guidebook: guidebook,
      rounds: [
        LearningRound(
          id: 'round',
          title: 'Round',
          exercises: [
            Exercise.presentation(
              id: 'exercise',
              editorTemplate: 'text',
              term: 'Lesson content.',
              meaning: '',
            ),
          ],
        ),
      ],
    ),
  ],
);
