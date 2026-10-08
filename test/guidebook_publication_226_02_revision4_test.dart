import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';

import 'support/guidebook_fixtures.dart';

/// GuideBook publication (Build 226.02 revision 4), in the module shape of
/// Build 266: the whole GuideBook is Draft or Published.
void main() {
  test('a GuideBook without publicationState is Published and unchanged', () {
    final json = <String, dynamic>{
      'modules': [_module('existing').toJson()],
    };
    final encoded = jsonEncode(json);
    final guidebook = Guidebook.fromJson(json);

    expect(guidebook.publicationState, PublicationState.published);
    expect(jsonEncode(guidebook.toJson()), encoded);
    expect(Guidebook.empty().toJson(), {'modules': <Object>[]});
    expect(
      Guidebook.fromJson({...json, 'publicationState': 'published'}).toJson(),
      json,
    );
  });

  test('explicit empty Draft Guidebook survives Course JSON round-trip', () {
    final guidebook = Guidebook(publicationState: PublicationState.draft);
    expect(guidebook.toJson(), {
      'publicationState': 'draft',
      'modules': <Object>[],
    });
    final original = _course(guidebook);
    final restored = Course.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(restored.formatVersion, 12);
    expect(restored.courseId, original.courseId);
    expect(restored.lessons.single.lessonId, original.lessons.single.lessonId);
    expect(
      restored.lessons.single.guidebook.publicationState,
      PublicationState.draft,
    );
    expect(restored.lessons.single.guidebook.modules, isEmpty);
    expect(restored.toJson(), original.toJson());
  });

  test('present invalid Guidebook publication values are rejected', () {
    for (final invalid in <Object?>[null, '', 'Draft', 'unreviewed', 1, true]) {
      expect(
        () => Guidebook.fromJson({
          'publicationState': invalid,
          'modules': <Object>[],
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
        modules: [_module('reviewed'), _module('unfinished')],
      );
      final original = _course(guidebook);
      final before = jsonEncode(original.toJson());
      final learner = const PublicationService().learnerCourse(original)!;

      expect(learner.lessons.map((lesson) => lesson.lessonId), ['lesson']);
      final lesson = learner.lessons.single;
      expect(lesson.rounds.map((round) => round.id), ['round']);
      expect(lesson.rounds.single.exercises.single.id, 'exercise');
      expect(lesson.guidebook.publicationState, PublicationState.draft);
      expect(lesson.guidebook.modules, isEmpty);
      expect(lesson.guidebook.toJson(), {
        'publicationState': 'draft',
        'modules': <Object>[],
      });
      expect(jsonEncode(original.toJson()), before);
    },
  );

  test('a Published Guidebook is delivered whole', () {
    final modules = [_module('reviewed'), _module('second')];
    final original = _course(
      Guidebook(publicationState: PublicationState.draft, modules: modules),
    );
    final published = _course(Guidebook(modules: modules));
    final service = const PublicationService();

    expect(
      service.learnerCourse(original)!.lessons.single.guidebook.modules,
      isEmpty,
    );
    final visible = service.learnerCourse(published)!.lessons.single.guidebook;
    expect(visible.publicationState, PublicationState.published);
    expect(visible.modules.map((module) => module.id), ['reviewed', 'second']);
    expect(visible.toJson(), published.lessons.single.guidebook.toJson());
  });

  test(
    'publication Audit resolves provenance against hidden authored GuideBook entries',
    () {
      final authoredJson = _course(
        Guidebook(
          publicationState: PublicationState.draft,
          modules: [_module('guide')],
        ),
      ).toJson();
      final lessonJson = (authoredJson['lessons'] as List).single as Map;
      final roundJson = (lessonJson['rounds'] as List).single as Map;
      final exerciseJson = (roundJson['content'] as List).single as Map;
      exerciseJson['sourceRefs'] = ['guide_w1', 'deleted-guide-entry'];
      final authored = Course.fromJson(authoredJson);
      final learner = const PublicationService().learnerCourse(authored)!;
      final audit = CourseAuditService();

      expect(learner.lessons.single.guidebook.modules, isEmpty);
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
        contains('deleted-guide-entry'),
      );
    },
  );

  for (final empty in [false, true]) {
    test(
      'import-as-Draft includes ${empty ? 'empty' : 'populated'} Guidebook state',
      () {
        final source = _course(
          Guidebook(modules: empty ? [] : [_module('guide')]),
        );
        final imported = const PublicationService().asDraftAuthoringTree(
          source,
        );
        final guidebook = imported.lessons.single.guidebook;

        expect(guidebook.publicationState, PublicationState.draft);
        expect(
          guidebook.modules.map((module) => module.id),
          empty ? [] : ['guide'],
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
              modules: empty ? [] : [_module('guide')],
            ),
          );
          final service = AuthoringDuplicationService(
            ids: TimestampAuthoringIdGenerator(seed: 226024),
          );
          final lessonCopy = service.duplicateLesson(original.lessons.single);
          final courseCopy = service.copyCourseAsNew(
            original,
            title: 'Copy',
            originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
              profileId: '11111111-1111-4111-8111-111111111111',
              displayName: 'Copy creator',
            ),
            maintainer: const CourseMaintainer(
              '11111111-1111-4111-8111-111111111111',
            ),
          );
          for (final lesson in [lessonCopy, courseCopy.lessons.single]) {
            expect(lesson.publicationState, PublicationState.draft);
            expect(lesson.guidebook.publicationState, PublicationState.draft);
            expect(lesson.guidebook.modules, hasLength(empty ? 0 : 1));
            if (!empty) {
              final module = lesson.guidebook.modules.single;
              expect(module.id, isNot('guide'));
              expect(module.words.single.id, isNot('guide_w1'));
              expect(module.overview, 'Reviewed overview for guide.');
              expect(module.words.single.target, 'casa');
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

GuidebookModule _module(String id) =>
    testGuidebook(
      moduleId: id,
      title: 'Module $id',
      overview: 'Reviewed overview for $id.',
      wordLines: const ['casa = house'],
    ).modules.single;

Course _course(Guidebook guidebook) => Course(
  courseId: 'guidebook-publication-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Guidebook publication',
  ttsLanguage: 'it-IT',
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
