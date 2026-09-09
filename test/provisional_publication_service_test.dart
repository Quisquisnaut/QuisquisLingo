import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:quisquislingo_app/services/provisional_publication_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';

const _service = ProvisionalPublicationService();
final _before = DateTime.utc(2026, 9, 7, 10);
final _saved = DateTime.utc(2026, 9, 7, 11);

void main() {
  test(
    'ready provisional parents publish bottom-up, preserving the complete tree',
    () {
      final source = _course();
      final untouched = jsonEncode(source.toJson());
      final result = _service.reconcile(source, updatedAt: _saved);
      final lesson = result.lessons.single;
      final round = lesson.rounds.single;
      expect(lesson.publicationState, PublicationState.published);
      expect(round.publicationState, PublicationState.published);
      expect(lesson.provisionalDraft, isFalse);
      expect(round.provisionalDraft, isFalse);
      expect(lesson.updatedAt, _saved);
      expect(round.updatedAt, _saved);
      expect(round.exercises.single.updatedAt, _before);
      expect(round.content.single.sourceRefs, ['guide-source']);
      expect(round.content.single.role, 'reviewed-example');
      expect(lesson.sectionName, 'Named section');
      expect(lesson.guidebookId, source.lessons.single.guidebookId);
      expect(lesson.duel.toJson(), source.lessons.single.duel.toJson());
      expect(result.publicationState, PublicationState.draft);
      expect(result.courseVersion, '7');
      expect(
        _withoutPublicationMetadata(result.toJson()),
        _withoutPublicationMetadata(source.toJson()),
      );
      expect(jsonEncode(source.toJson()), untouched);
      expect(
        _service.reconcile(
          result,
          updatedAt: _saved.add(const Duration(hours: 1)),
        ),
        same(result),
      );
    },
  );

  test(
    'Exercise Save promotes Round first; later GuideBook Save promotes Lesson',
    () {
      final source = _course(guidebook: Guidebook.empty());
      final roundSaved = _service.reconcile(source, updatedAt: _saved);
      expect(
        roundSaved.lessons.single.rounds.single.publicationState,
        PublicationState.published,
      );
      expect(
        roundSaved.lessons.single.publicationState,
        PublicationState.draft,
      );
      expect(roundSaved.lessons.single.provisionalDraft, isTrue);
      expect(roundSaved.lessons.single.updatedAt, _before);
      final withGuidebook = _replaceLesson(roundSaved, {
        'guidebook': _guidebook().toJson(),
      });
      final later = _saved.add(const Duration(minutes: 1));
      final guideSaved = _service.reconcile(withGuidebook, updatedAt: later);
      expect(
        guideSaved.lessons.single.publicationState,
        PublicationState.published,
      );
      expect(guideSaved.lessons.single.updatedAt, later);
      expect(guideSaved.lessons.single.rounds.single.updatedAt, _saved);
      expect(
        guideSaved.lessons.single.guidebook.toJson(),
        _guidebook().toJson(),
      );
    },
  );

  test(
    'Use GuideBook OFF permits empty GuideBook without modifying its contents',
    () {
      final source = _course(useGuidebook: false, guidebook: Guidebook.empty());
      final result = _service.reconcile(source, updatedAt: _saved);
      expect(
        result.lessons.single.publicationState,
        PublicationState.published,
      );
      expect(
        result.lessons.single.guidebook.toJson(),
        source.lessons.single.guidebook.toJson(),
      );
    },
  );

  for (final required in [false, true]) {
    test('Draft Exercise blocks regardless of required=$required', () {
      final source = _course(
        exerciseState: PublicationState.draft,
        requiredExercise: required,
      );
      expect(_service.reconcile(source, updatedAt: _saved), same(source));
    });
  }

  test('explicit and legacy Draft Rounds never auto-publish', () {
    final explicit = _course(provisionalRound: false);
    expect(_service.reconcile(explicit, updatedAt: _saved), same(explicit));
    final legacyJson = _course().toJson();
    final lessonJson = (legacyJson['lessons'] as List).single as Map;
    lessonJson.remove('provisionalDraft');
    ((lessonJson['rounds'] as List).single as Map).remove('provisionalDraft');
    final legacy = Course.fromJson(legacyJson);
    expect(legacy.lessons.single.provisionalDraft, isFalse);
    expect(legacy.lessons.single.rounds.single.provisionalDraft, isFalse);
    expect(_service.reconcile(legacy, updatedAt: _saved), same(legacy));
  });

  test(
    'explicit Draft Lesson remains Draft when its provisional Round becomes ready',
    () {
      final source = _course(provisionalLesson: false);
      final result = _service.reconcile(source, updatedAt: _saved);
      expect(result.lessons.single.publicationState, PublicationState.draft);
      expect(result.lessons.single.provisionalDraft, isFalse);
      expect(result.lessons.single.updatedAt, _before);
      expect(
        result.lessons.single.rounds.single.publicationState,
        PublicationState.published,
      );
    },
  );

  test('canonical Exercise Errors prevent Round and Lesson promotion', () {
    final source = _course(valid: false);
    expect(
      CourseAuditService()
          .auditRound(source, 'round')
          .count(AuditSeverity.error),
      greaterThan(0),
    );
    expect(_service.reconcile(source, updatedAt: _saved), same(source));
  });

  test(
    'empty Round and empty Lesson retain their canonical blocking state',
    () {
      final emptyRound = _replaceRound(_course(), {'content': <Object>[]});
      expect(
        CourseAuditService()
            .auditCourse(emptyRound)
            .issues
            .any((issue) => issue.code == 'ROUND_CONTENT_EMPTY'),
        isTrue,
      );
      expect(
        _service.reconcile(emptyRound, updatedAt: _saved),
        same(emptyRound),
      );
      final emptyLesson = _replaceLesson(_course(), {'rounds': <Object>[]});
      expect(
        CourseAuditService()
            .auditCourse(emptyLesson)
            .issues
            .any((issue) => issue.code == 'LESSON_ROUNDS_EMPTY'),
        isTrue,
      );
      expect(
        _service.reconcile(emptyLesson, updatedAt: _saved),
        same(emptyLesson),
      );
    },
  );

  test(
    'Info-only guidance does not prevent normal parent Save reconciliation',
    () {
      final source = _course();
      final audit = CourseAuditService().auditCourse(source);
      expect(audit.count(AuditSeverity.error), 0);
      expect(audit.count(AuditSeverity.warning), 0);
      expect(audit.count(AuditSeverity.info), greaterThan(0));
      expect(
        _service
            .reconcile(source, updatedAt: _saved)
            .lessons
            .single
            .publicationState,
        PublicationState.published,
      );
    },
  );

  test('nonblocking Warning keeps the existing normal Save admissibility', () {
    final base = _course();
    final source = _replaceRound(base, {
      'content': [
        ...base.lessons.single.rounds.single.content.map(
          (content) => content.toJson(),
        ),
        for (var index = 0; index < 10; index++)
          LearningContent.textual(
            id: 'pacing-note-$index',
            kind: 'text',
            role: 'lesson_intro',
            text: 'A reviewed pacing note.',
          ).toJson(),
      ],
    });
    final audit = CourseAuditService().auditLesson(source, 'lesson');
    expect(audit.count(AuditSeverity.error), 0);
    expect(audit.count(AuditSeverity.warning), greaterThan(0));
    expect(
      _service
          .reconcile(source, updatedAt: _saved)
          .lessons
          .single
          .publicationState,
      PublicationState.published,
    );
  });

  for (final guidebook in [
    Guidebook(
      publicationState: PublicationState.draft,
      content: _guidebook().content,
    ),
    Guidebook(
      content: [
        LearningContent.textual(
          id: 'guide-source',
          kind: 'text',
          role: 'overview',
          text: 'Required pending guide.',
          required: true,
          publicationState: PublicationState.draft,
        ),
      ],
    ),
  ]) {
    test(
      'Draft GuideBook or required content keeps provisional Lesson Draft ${guidebook.publicationState}',
      () {
        final source = _course(guidebook: guidebook);
        final result = _service.reconcile(source, updatedAt: _saved);
        expect(
          result.lessons.single.rounds.single.publicationState,
          PublicationState.published,
        );
        expect(result.lessons.single.publicationState, PublicationState.draft);
        expect(result.lessons.single.guidebook.toJson(), guidebook.toJson());
      },
    );
  }

  for (final required in [false, true]) {
    test(
      'non-runnable Draft Content required=$required has explicit readiness semantics',
      () {
        final source = _replaceRound(_course(), {
          'content': [
            ..._course().lessons.single.rounds.single.content.map(
              (content) => content.toJson(),
            ),
            LearningContent.textual(
              id: 'optional-intro',
              kind: 'text',
              role: 'lesson_intro',
              text: 'An optional author note.',
              required: required,
              publicationState: PublicationState.draft,
            ).toJson(),
          ],
        });
        final result = _service.reconcile(source, updatedAt: _saved);
        expect(
          result.lessons.single.publicationState,
          required ? PublicationState.draft : PublicationState.published,
        );
        expect(
          result.lessons.single.rounds.single.content.last.publicationState,
          PublicationState.draft,
        );
        if (required) expect(result, same(source));
      },
    );
  }

  test(
    'valid text-only Round can become Published without inventing Exercise minimums',
    () {
      final source = _replaceRound(_course(), {
        'content': [
          LearningContent.textual(
            id: 'text-only',
            kind: 'text',
            role: 'lesson_intro',
            text: 'A complete introduction.',
            required: true,
          ).toJson(),
        ],
      });
      expect(source.lessons.single.rounds.single.exercises, isEmpty);
      expect(
        _service
            .reconcile(source, updatedAt: _saved)
            .lessons
            .single
            .publicationState,
        PublicationState.published,
      );
    },
  );

  test(
    'optional Draft metadata errors stay stored outside normal Save evaluation',
    () {
      final source = _replaceRound(_course(), {
        'content': [
          ..._course().lessons.single.rounds.single.content.map(
            (content) => content.toJson(),
          ),
          const LearningContent(
            id: 'draft-note',
            kind: 'text',
            role: 'lesson_intro',
            text: 'An unfinished note.',
            publicationState: PublicationState.draft,
            required: false,
            sourceRefs: ['unresolved-author-reference'],
          ).toJson(),
        ],
      });
      expect(
        CourseAuditService()
            .auditRound(source, 'round')
            .count(AuditSeverity.error),
        greaterThan(0),
      );
      final result = _service.reconcile(source, updatedAt: _saved);
      expect(
        result.lessons.single.publicationState,
        PublicationState.published,
      );
      expect(
        result.lessons.single.rounds.single.content.last.toJson(),
        source.lessons.single.rounds.single.content.last.toJson(),
      );
    },
  );

  test(
    'only optional Draft Content leaves the projected Round canonically empty',
    () {
      final source = _replaceRound(_course(), {
        'content': [
          LearningContent.textual(
            id: 'only-draft-note',
            kind: 'text',
            role: 'lesson_intro',
            text: 'Not delivered yet.',
            publicationState: PublicationState.draft,
            required: false,
          ).toJson(),
        ],
      });
      expect(source.lessons.single.rounds.single.content, isNotEmpty);
      expect(_service.reconcile(source, updatedAt: _saved), same(source));
    },
  );

  test(
    'only optional Draft GuideBook Content leaves the learner GuideBook empty',
    () {
      final source = _course(
        guidebook: Guidebook(
          content: [
            LearningContent.textual(
              id: 'guide-source',
              kind: 'text',
              role: 'overview',
              text: 'Not delivered yet.',
              publicationState: PublicationState.draft,
              required: false,
            ),
          ],
        ),
      );
      final result = _service.reconcile(source, updatedAt: _saved);
      expect(
        result.lessons.single.rounds.single.publicationState,
        PublicationState.published,
      );
      expect(result.lessons.single.publicationState, PublicationState.draft);
      expect(
        result.lessons.single.guidebook.toJson(),
        source.lessons.single.guidebook.toJson(),
      );
    },
  );

  test(
    'unrelated Lesson error blocks its parent without blocking a clean Round',
    () {
      final base = _course();
      final source = _replaceLesson(base, {
        'themeIconAsset': 'assets/lesson_icons/missing.png',
      });
      expect(
        CourseAuditService()
            .auditLesson(source, 'lesson')
            .count(AuditSeverity.error),
        greaterThan(0),
      );
      final result = _service.reconcile(source, updatedAt: _saved);
      expect(
        result.lessons.single.rounds.single.publicationState,
        PublicationState.published,
      );
      expect(result.lessons.single.publicationState, PublicationState.draft);
    },
  );

  test(
    'official Courses are returned untouched even with marked Draft parents',
    () {
      final source = _course(origin: CourseOriginType.bundledOfficial);
      expect(_service.reconcile(source, updatedAt: _saved), same(source));
    },
  );

  test(
    'Course delivery choice is preserved for both Published and Not published',
    () {
      for (final state in PublicationState.values) {
        final source = Course.fromJson({
          ..._course().toJson(),
          'publicationState': state.name,
        });
        final result = _service.reconcile(source, updatedAt: _saved);
        expect(result.publicationState, state);
        expect(result.courseId, source.courseId);
        expect(result.courseVersion, source.courseVersion);
      }
    },
  );

  test(
    'intentional Course, Lesson and Round duplicates clear provisional eligibility',
    () {
      final source = _course();
      final duplicate = AuthoringDuplicationService();
      final courseCopy = duplicate.duplicateCourse(
        source,
        title: 'Intentional copy',
      );
      final lessonCopy = duplicate.duplicateLesson(source.lessons.single);
      final roundCopy = duplicate.duplicateRound(
        source.lessons.single.rounds.single,
      );
      expect(courseCopy.courseId, isNot(source.courseId));
      expect(
        courseCopy.lessons.single.lessonId,
        isNot(source.lessons.single.lessonId),
      );
      expect(lessonCopy.lessonId, isNot(source.lessons.single.lessonId));
      expect(roundCopy.id, isNot(source.lessons.single.rounds.single.id));
      for (final lesson in [courseCopy.lessons.single, lessonCopy]) {
        expect(lesson.publicationState, PublicationState.draft);
        expect(lesson.provisionalDraft, isFalse);
        expect(lesson.rounds.single.provisionalDraft, isFalse);
        expect(lesson.rounds.single.publicationState, PublicationState.draft);
      }
      expect(roundCopy.provisionalDraft, isFalse);
      expect(roundCopy.publicationState, PublicationState.draft);
      final reviewedChildren = _reviewChildren(courseCopy);
      expect(
        _service.reconcile(reviewedChildren, updatedAt: _saved),
        same(reviewedChildren),
      );
      expect(source.lessons.single.provisionalDraft, isTrue);
      expect(source.lessons.single.rounds.single.provisionalDraft, isTrue);
    },
  );

  test(
    'licensed official fork is an intentional Draft and keeps original provenance',
    () {
      final official = Course.fromJson({
        ..._course(origin: CourseOriginType.bundledOfficial).toJson(),
        'derivativeWorksPolicy': 'allowed',
      });
      final provenance = CourseForkProvenance(
        originalPublisherId: official.publisherId,
        originalPublisherName: official.publisherName,
        originalCourseId: official.courseId,
        originalOfficialCourseVersion: official.officialCourseVersion,
        originalOfficialChecksum: official.officialChecksum,
        originalCourseTitle: official.title,
        originalAuthor: official.author,
        originalAuthors: official.authors,
        forkCreatedByProfileId: '11111111-1111-4111-8111-111111111111',
        forkCreatedByUsername: 'Fork author',
        forkCreatedAtUtc: '2026-09-07T10:00:00.000Z',
      );
      final original = jsonEncode(official.toJson());
      final fork = AuthoringDuplicationService().forkOfficialCourse(
        official,
        provenance: provenance,
        creatorProfileId: '11111111-1111-4111-8111-111111111111',
        ownership: const CourseOwnership.individual(
          '11111111-1111-4111-8111-111111111111',
        ),
      );
      expect(fork.originType, CourseOriginType.custom);
      expect(fork.courseId, isNot(official.courseId));
      expect(fork.forkProvenance!.toJson(), provenance.toJson());
      expect(fork.lessons.single.provisionalDraft, isFalse);
      expect(fork.lessons.single.rounds.single.provisionalDraft, isFalse);
      final reviewed = _reviewChildren(fork);
      expect(_service.reconcile(reviewed, updatedAt: _saved), same(reviewed));
      expect(reviewed.lessons.single.publicationState, PublicationState.draft);
      expect(jsonEncode(official.toJson()), original);
    },
  );

  test(
    'import-to-Draft normalization clears incoming eligibility without changing IDs',
    () {
      final source = _course();
      final decoded = Course.fromJson(jsonDecode(jsonEncode(source.toJson())));
      final imported = const PublicationService().asDraftAuthoringTree(decoded);
      expect(imported.courseId, source.courseId);
      expect(imported.lessons.single.lessonId, source.lessons.single.lessonId);
      expect(
        imported.lessons.single.rounds.single.id,
        source.lessons.single.rounds.single.id,
      );
      expect(imported.lessons.single.provisionalDraft, isFalse);
      expect(imported.lessons.single.rounds.single.provisionalDraft, isFalse);
      expect(imported.lessons.single.publicationState, PublicationState.draft);
      expect(
        imported.lessons.single.rounds.single.publicationState,
        PublicationState.draft,
      );
      final reviewed = _reviewChildren(imported);
      expect(_service.reconcile(reviewed, updatedAt: _saved), same(reviewed));
      expect(source.lessons.single.provisionalDraft, isTrue);
    },
  );

  test(
    'Round Move and canonical title edits preserve provisional markers and stable IDs',
    () {
      final source = _course(useGuidebook: false);
      final destination = Lesson(
        lessonId: 'destination',
        title: 'Destination',
        publicationState: PublicationState.draft,
        provisionalDraft: true,
        updatedAt: _before,
        rounds: [],
      );
      final withDestination = Course.fromJson({
        ...source.toJson(),
        'lessons': [
          ...source.lessons.map((lesson) => lesson.toJson()),
          destination.toJson(),
        ],
      });
      final moved = CourseAuthoringTransferService(clock: () => _saved)
          .moveRound(
            withDestination,
            sourceLessonId: 'lesson',
            roundId: 'round',
            destinationLessonId: 'destination',
          );
      expect(moved.lessons.first.rounds, isEmpty);
      expect(moved.lessons.every((lesson) => lesson.provisionalDraft), isTrue);
      final movedRound = moved.lessons.last.rounds.single;
      expect(movedRound.id, 'round');
      expect(movedRound.provisionalDraft, isTrue);
      expect(movedRound.publicationState, PublicationState.draft);
      expect(movedRound.exercises.single.id, 'exercise');
      // There is no public Rename service: title edits use the canonical model
      // copy/serialization contract, which must retain these optional markers.
      final renamed = Course.fromJson({
        ...moved.toJson(),
        'lessons': [
          moved.lessons.first.toJson(),
          {
            ...moved.lessons.last.toJson(),
            'title': 'Renamed destination',
            'rounds': [
              {...movedRound.toJson(), 'title': 'Renamed Round'},
            ],
          },
        ],
      });
      expect(renamed.lessons.last.provisionalDraft, isTrue);
      expect(renamed.lessons.last.rounds.single.provisionalDraft, isTrue);
      expect(renamed.lessons.last.lessonId, 'destination');
      expect(renamed.lessons.last.rounds.single.id, 'round');
      final ready = _service.reconcile(renamed, updatedAt: _saved);
      expect(ready.lessons.first.publicationState, PublicationState.draft);
      expect(ready.lessons.last.publicationState, PublicationState.published);
      expect(ready.lessons.last.title, 'Renamed destination');
      expect(ready.lessons.last.rounds.single.title, 'Renamed Round');
    },
  );
}

Course _reviewChildren(Course source) => Course.fromJson({
  ...source.toJson(),
  'lessons': [
    for (final lesson in source.lessons)
      {
        ...lesson.toJson(),
        'guidebook': {
          ...lesson.guidebook.toJson(),
          'publicationState': 'published',
          'content': [
            for (final content in lesson.guidebook.content)
              {...content.toJson(), 'publicationState': 'published'},
          ],
        },
        'rounds': [
          for (final round in lesson.rounds)
            {
              ...round.toJson(),
              'publicationState': 'published',
              'content': [
                for (final content in round.content)
                  {...content.toJson(), 'publicationState': 'published'},
              ],
            },
        ],
      },
  ],
});

Course _course({
  bool provisionalLesson = true,
  bool provisionalRound = true,
  bool useGuidebook = true,
  bool valid = true,
  bool requiredExercise = true,
  PublicationState exerciseState = PublicationState.published,
  Guidebook? guidebook,
  CourseOriginType origin = CourseOriginType.custom,
}) => Course(
  courseId: 'course',
  originType: origin,
  publisherId: origin.isOfficial ? 'test.publisher' : '',
  publisherName: origin.isOfficial ? 'Synthetic publisher' : '',
  officialCourseVersion: origin.isOfficial ? '1' : '',
  officialReleaseDateUtc: origin.isOfficial ? '2026-09-07T10:00:00.000Z' : '',
  officialChecksum: origin.isOfficial ? List.filled(64, 'a').join() : '',
  distributionChannel: origin.isOfficial ? 'test-fixture' : '',
  publicationState: PublicationState.draft,
  sourceLanguage: 'English',
  interfaceLanguage: 'English',
  learningLanguage: 'Italian',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  title: 'Preserved course',
  version: '1',
  courseVersion: '7',
  courseDescription: 'Keep this metadata.',
  createDuels: false,
  useGuidebook: useGuidebook,
  lessonNumberingMode: LessonNumberingMode.module,
  sectionNames: ['Named section', 'Unused section'],
  authors: const [
    CourseAuthor(name: 'Test author', roles: ['Author', 'Illustrator']),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Preserved lesson',
      updatedAt: _before,
      publicationState: PublicationState.draft,
      provisionalDraft: provisionalLesson,
      section: true,
      sectionName: 'Named section',
      guidebook: guidebook ?? _guidebook(),
      duel: Duel(id: 'preserved-duel', title: 'Preserved Duel'),
      rounds: [
        LearningRound(
          id: 'round',
          title: '',
          visualType: 'story',
          updatedAt: _before,
          publicationState: PublicationState.draft,
          provisionalDraft: provisionalRound,
          content: [
            LearningContent(
              id: 'exercise',
              kind: 'exercise',
              editorTemplate: 'choice',
              publicationState: exerciseState,
              required: requiredExercise,
              role: 'reviewed-example',
              sourceRefs:
                  (guidebook ?? _guidebook()).content.any(
                    (content) => content.id == 'guide-source',
                  )
                  ? const ['guide-source']
                  : const [],
              exercise: Exercise(
                id: 'exercise',
                type: 'choice',
                updatedAt: _before,
                publicationState: exerciseState,
                prompt: 'Choose the translation.',
                question: 'water',
                answers: const ['acqua', 'libro'],
                correct: valid ? 0 : null,
                tts: null,
                accepted: const [],
                tokens: const [],
                orderAnswer: const [],
                pairs: const [],
                hint: '',
                icons: const [],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

Guidebook _guidebook() => Guidebook(
  content: [
    LearningContent.textual(
      id: 'guide-source',
      kind: 'text',
      role: 'overview',
      text: 'Reviewed guide content.',
      required: true,
    ),
  ],
);

Course _replaceLesson(Course source, Map<String, dynamic> changes) =>
    Course.fromJson({
      ...source.toJson(),
      'lessons': [
        {...source.lessons.single.toJson(), ...changes},
      ],
    });

Course _replaceRound(Course source, Map<String, dynamic> changes) =>
    _replaceLesson(source, {
      'rounds': [
        {...source.lessons.single.rounds.single.toJson(), ...changes},
      ],
    });

Object? _withoutPublicationMetadata(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (!const {
          'publicationState',
          'provisionalDraft',
          'updatedAt',
        }.contains(entry.key))
          entry.key: _withoutPublicationMetadata(entry.value),
    };
  }
  if (value is List) return value.map(_withoutPublicationMetadata).toList();
  return value;
}
