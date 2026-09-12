import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_editor_transaction.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _originalTime = DateTime.utc(2026, 9, 4, 10);
final _editTime = DateTime.utc(2026, 9, 5, 11);
const _profileId = '12345678-1234-4234-9234-123456789abc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CourseAuthoringTransferService transfers;

  setUp(() {
    transfers = CourseAuthoringTransferService(
      duplication: AuthoringDuplicationService(ids: _SequenceIds()),
      clock: () => _editTime,
    );
  });

  for (final state in PublicationState.values) {
    for (final id in [
      'select',
      'input',
      'arrange',
      'match',
      'presentation',
      'note',
    ]) {
      test('Move $id preserves all content and $state state', () {
        final source = _course(state: state);
        final before = jsonEncode(source.toJson());
        final original = _round(
          source,
          'source-round',
        ).content.singleWhere((content) => content.id == id);

        final result = transfers.moveExercise(
          source,
          sourceLessonId: 'source-lesson',
          sourceRoundId: 'source-round',
          exerciseId: id,
          destinationLessonId: 'destination-lesson',
          destinationRoundId: 'destination-round',
        );

        expect(jsonEncode(source.toJson()), before);
        expect(_allContent(result).where((c) => c.id == id), hasLength(1));
        expect(
          _round(result, 'source-round').content,
          isNot(contains(original)),
        );
        final moved = _round(result, 'destination-round').content.last;
        expect(moved, same(original));
        expect(moved.toJson(), original.toJson());
        expect(moved.publicationState, state);
        expect(
          moved.exercise?.publicationState,
          original.exercise?.publicationState,
        );
        expect(_round(result, 'source-round').updatedAt, _editTime);
        expect(_round(result, 'destination-round').updatedAt, _editTime);
        expect(
          _round(result, 'spare-round'),
          same(_round(source, 'spare-round')),
        );
        _expectCourseAndLessonMetadata(result, source);
      });
    }
  }

  test('Move Exercise between Rounds of the same Lesson removes once', () {
    final source = _course();
    final result = transfers.moveExercise(
      source,
      sourceLessonId: 'source-lesson',
      sourceRoundId: 'source-round',
      exerciseId: 'select',
      destinationLessonId: 'source-lesson',
      destinationRoundId: 'spare-round',
    );

    expect(_round(result, 'source-round').content.map((c) => c.id), [
      'note',
      'presentation',
      'arrange',
      'match',
      'input',
    ]);
    expect(_round(result, 'spare-round').content.map((c) => c.id), ['select']);
    expect(_allContent(result).where((c) => c.id == 'select'), hasLength(1));
    expect(result.lessons[1], same(source.lessons[1]));
  });

  test('Move preserves distinct in-memory wrapper and Exercise identities', () {
    final source = _course();
    final original = _round(source, 'source-round').content[2];
    _round(source, 'source-round').content[2] = LearningContent(
      id: 'distinct-wrapper',
      kind: original.kind,
      required: original.required,
      editorTemplate: original.editorTemplate,
      role: original.role,
      text: original.text,
      sourceRefs: original.sourceRefs,
      exercise: original.exercise,
    );

    final result = transfers.moveExercise(
      source,
      sourceLessonId: 'source-lesson',
      sourceRoundId: 'source-round',
      exerciseId: 'select',
      destinationLessonId: 'destination-lesson',
      destinationRoundId: 'destination-round',
    );

    final moved = _round(result, 'destination-round').content.last;
    expect(moved.id, 'distinct-wrapper');
    expect(moved.exercise!.id, 'select');
    expect(moved.exercise, same(original.exercise));
  });

  for (final id in [
    'select',
    'input',
    'arrange',
    'match',
    'presentation',
    'note',
  ]) {
    test(
      'Copy $id retains v9 metadata and creates independent Draft content',
      () {
        final source = _course();
        final before = jsonEncode(source.toJson());
        final original = _round(
          source,
          'source-round',
        ).content.singleWhere((content) => content.id == id);
        final result = transfers.copyExercise(
          source,
          sourceLessonId: 'source-lesson',
          sourceRoundId: 'source-round',
          exerciseId: id,
          destinationLessonId: 'destination-lesson',
          destinationRoundId: 'destination-round',
        );

        final copy = _round(result, 'destination-round').content.last;
        expect(copy.id, isNot(original.id));
        expect(
          _ownedContentIds(copy).intersection(_ownedContentIds(original)),
          isEmpty,
        );
        expect(copy.publicationState, PublicationState.draft);
        expect(copy.kind, original.kind);
        expect(copy.required, original.required);
        expect(copy.editorTemplate, original.editorTemplate);
        expect(copy.role, original.role);
        expect(copy.text, original.text);
        expect(copy.presentation?.toJson(), original.presentation?.toJson());
        expect(copy.sourceRefs, [
          for (final reference in original.sourceRefs)
            reference == original.id ? copy.id : reference,
        ]);
        if (copy.exercise case final exercise?) {
          expect(exercise.id, copy.id);
          expect(exercise.publicationState, PublicationState.draft);
          expect(exercise.updatedAt, _originalTime);
          expect(
            exercise.promptElements.map((p) => p.toJson()),
            original.exercise!.promptElements.map((p) => p.toJson()),
          );
          expect(exercise.hint, original.exercise!.hint);
          expect(exercise.feedback, original.exercise!.feedback);
          expect(exercise.missingWords, original.exercise!.missingWords);
          expect(
            exercise.evaluation.normalization,
            original.exercise!.evaluation.normalization,
          );
          expect(
            exercise.evaluation.accepted,
            original.exercise!.evaluation.accepted,
          );
          _expectEvaluationReferences(id, exercise);
          exercise.promptElements.add(
            const PromptElement(type: 'text', text: 'Copy only'),
          );
          exercise.interaction.items.firstOrNull?.content.add(
            const PromptElement(type: 'text', text: 'Copy item only'),
          );
          (exercise.evaluation.normalization['metadata'] as Map)['notes'][0] =
              'changed';
          exercise.feedback['correct'] = 'changed';
          exercise.evaluation.accepted.add('copy only');
          exercise.missingWords.add('copy only');
        }
        copy.sourceRefs.add('copy-only-reference');
        copy.presentation?.actions.add('copy-only-action');
        copy.presentation?.content.add(
          const PromptElement(type: 'text', text: 'Copy only'),
        );
        expect(jsonEncode(source.toJson()), before);
        expect(
          _round(result, 'source-round'),
          same(_round(source, 'source-round')),
        );
        _expectCourseAndLessonMetadata(result, source);
      },
    );
  }

  test(
    'Copy Exercise can append to the current Round without replacing source',
    () {
      final source = _course();
      final result = transfers.copyExercise(
        source,
        sourceLessonId: 'source-lesson',
        sourceRoundId: 'source-round',
        exerciseId: 'select',
        destinationLessonId: 'source-lesson',
        destinationRoundId: 'source-round',
      );

      final content = _round(result, 'source-round').content;
      expect(content, hasLength(7));
      expect(content[2].id, 'select');
      expect(content.last.id, isNot('select'));
      expect(content[2].publicationState, PublicationState.published);
      expect(content.last.publicationState, PublicationState.draft);
    },
  );

  for (final state in PublicationState.values) {
    test('Move Round preserves $state subtree and empty title', () {
      final source = _course(state: state);
      final before = jsonEncode(source.toJson());
      final original = _round(source, 'source-round');
      final result = transfers.moveRound(
        source,
        sourceLessonId: 'source-lesson',
        roundId: 'source-round',
        destinationLessonId: 'empty-lesson',
      );

      expect(result.lessons.first.rounds.map((r) => r.id), ['spare-round']);
      expect(result.lessons.last.rounds.single, same(original));
      expect(result.lessons.last.rounds.single.toJson(), original.toJson());
      expect(result.lessons.last.rounds.single.title, isEmpty);
      expect(result.lessons.last.rounds.single.publicationState, state);
      expect(result.lessons.last.rounds.single.updatedAt, _originalTime);
      expect(result.lessons.first.updatedAt, _editTime);
      expect(result.lessons.last.updatedAt, _editTime);
      expect(jsonEncode(source.toJson()), before);
      _expectCourseAndLessonMetadata(result, source);
    });
  }

  for (final destination in [
    'source-lesson',
    'destination-lesson',
    'empty-lesson',
  ]) {
    test(
      'Copy Round to $destination remaps subtree and internal sourceRefs',
      () {
        final source = _course();
        final before = jsonEncode(source.toJson());
        final original = _round(source, 'source-round');
        final result = transfers.copyRound(
          source,
          sourceLessonId: 'source-lesson',
          roundId: 'source-round',
          destinationLessonId: destination,
        );

        final copy = result.lessons
            .singleWhere((l) => l.lessonId == destination)
            .rounds
            .last;
        expect(copy.id, isNot(original.id));
        expect(copy.title, isEmpty);
        expect(copy.visualType, original.visualType);
        expect(copy.updatedAt, original.updatedAt);
        expect(copy.publicationState, PublicationState.draft);
        expect(copy.content, hasLength(original.content.length));
        final originalIds = {
          original.id,
          for (final c in original.content) ..._ownedContentIds(c),
        };
        final copiedIds = {
          copy.id,
          for (final c in copy.content) ..._ownedContentIds(c),
        };
        expect(copiedIds.intersection(originalIds), isEmpty);
        expect(copiedIds.length, originalIds.length);
        final copiedSelect = copy.content[2];
        expect(copiedSelect.sourceRefs, [
          'guide',
          copy.content[0].id,
          copiedSelect.id,
        ]);
        for (var index = 0; index < copy.content.length; index++) {
          final copiedContent = copy.content[index];
          final sourceContent = original.content[index];
          expect(copiedContent.publicationState, PublicationState.draft);
          expect(copiedContent.required, sourceContent.required);
          expect(copiedContent.role, sourceContent.role);
          expect(copiedContent.text, sourceContent.text);
          expect(copiedContent.editorTemplate, sourceContent.editorTemplate);
          expect(
            copiedContent.presentation?.toJson(),
            sourceContent.presentation?.toJson(),
          );
          if (copiedContent.exercise case final exercise?) {
            _expectEvaluationReferences(sourceContent.id, exercise);
            (exercise.evaluation.normalization['metadata'] as Map)['notes'][0] =
                'copy';
            exercise.evaluation.pairs.firstOrNull?.add('copy-only');
            exercise.evaluation.correctOrders.firstOrNull?.itemIds.add(
              'copy-only',
            );
          }
        }
        expect(jsonEncode(source.toJson()), before);
        _expectCourseAndLessonMetadata(result, source);
      },
    );
  }

  test('invalid or stale destinations fail without changing the source', () {
    final source = _course();
    final before = jsonEncode(source.toJson());
    for (final operation in <Course Function()>[
      () => transfers.moveExercise(
        source,
        sourceLessonId: 'source-lesson',
        sourceRoundId: 'source-round',
        exerciseId: 'select',
        destinationLessonId: 'source-lesson',
        destinationRoundId: 'source-round',
      ),
      () => transfers.moveExercise(
        source,
        sourceLessonId: 'source-lesson',
        sourceRoundId: 'source-round',
        exerciseId: 'missing',
        destinationLessonId: 'destination-lesson',
        destinationRoundId: 'destination-round',
      ),
      () => transfers.copyExercise(
        source,
        sourceLessonId: 'source-lesson',
        sourceRoundId: 'source-round',
        exerciseId: 'select',
        destinationLessonId: 'missing',
        destinationRoundId: 'destination-round',
      ),
      () => transfers.copyExercise(
        source,
        sourceLessonId: 'source-lesson',
        sourceRoundId: 'source-round',
        exerciseId: 'select',
        destinationLessonId: 'destination-lesson',
        destinationRoundId: 'spare-round',
      ),
      () => transfers.moveRound(
        source,
        sourceLessonId: 'source-lesson',
        roundId: 'source-round',
        destinationLessonId: 'source-lesson',
      ),
      () => transfers.copyRound(
        source,
        sourceLessonId: 'source-lesson',
        roundId: 'missing',
        destinationLessonId: 'empty-lesson',
      ),
      () => transfers.moveRound(
        source,
        sourceLessonId: 'destination-lesson',
        roundId: 'source-round',
        destinationLessonId: 'empty-lesson',
      ),
    ]) {
      expect(
        operation,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'actionable message',
            isNotEmpty,
          ),
        ),
      );
      expect(jsonEncode(source.toJson()), before);
    }
  });

  test('ambiguous Lesson, Round, Content and Item IDs fail atomically', () {
    final cases = <void Function(Course)>[
      (course) => course.lessons.add(course.lessons.first),
      (course) =>
          course.lessons[1].rounds.add(course.lessons.first.rounds.first),
      (course) => _round(
        course,
        'destination-round',
      ).content.add(_round(course, 'source-round').content[2]),
      (course) {
        final items = _round(
          course,
          'source-round',
        ).content[2].exercise!.interaction.items;
        items.add(items.first);
      },
    ];
    for (final corrupt in cases) {
      final source = _course();
      corrupt(source);
      final before = jsonEncode(source.toJson());
      expect(
        () => transfers.copyExercise(
          source,
          sourceLessonId: 'source-lesson',
          sourceRoundId: 'source-round',
          exerciseId: 'select',
          destinationLessonId: 'destination-lesson',
          destinationRoundId: 'destination-round',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'duplicate guidance',
            contains('duplicate'),
          ),
        ),
      );
      expect(jsonEncode(source.toJson()), before);
    }
  });

  for (final allocatedId in ['select', 'collapsed-copy-id']) {
    test(
      'ID allocation collision $allocatedId leaves the working copy unchanged',
      () {
        final source = _course();
        final before = jsonEncode(source.toJson());
        final collision = CourseAuthoringTransferService(
          duplication: AuthoringDuplicationService(
            ids: _CollidingIds(allocatedId),
          ),
          clock: () => _editTime,
        );
        expect(
          () => collision.copyRound(
            source,
            sourceLessonId: 'source-lesson',
            roundId: 'source-round',
            destinationLessonId: 'empty-lesson',
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'retry guidance',
              contains('fresh IDs'),
            ),
          ),
        );
        expect(jsonEncode(source.toJson()), before);
      },
    );
  }

  for (final origin in [
    CourseOriginType.bundledOfficial,
    CourseOriginType.externalOfficial,
  ]) {
    test('all transfers reject $origin before touching content', () {
      final json = _course().toJson()..remove('forkProvenance');
      json
        ..remove('maintainer')
        ..remove('assignedTeamId')
        ..remove('courseVersion')
        ..remove('versionNotes')
        ..remove('restoredFromVersion');
      final source = Course.fromJson({
        ...json,
        'originType': origin.name,
        'publisherId': 'test.publisher',
        'publisherName': 'Test publisher',
        'originalCourseCreator': const CourseProvenanceIdentity.publisher(
          publisherId: 'test.publisher',
          displayName: 'Test publisher',
        ).toJson(),
        'originalCreatedAtUtc': _originalTime.toIso8601String(),
        'officialCourseVersion': '3',
        'officialReleaseDateUtc': _originalTime.toIso8601String(),
        'officialChecksum': List.filled(64, 'a').join(),
        'distributionChannel': 'test-fixture',
      });
      final before = jsonEncode(source.toJson());
      for (final operation in <Course Function()>[
        () => transfers.moveExercise(
          source,
          sourceLessonId: 'source-lesson',
          sourceRoundId: 'source-round',
          exerciseId: 'select',
          destinationLessonId: 'destination-lesson',
          destinationRoundId: 'destination-round',
        ),
        () => transfers.copyExercise(
          source,
          sourceLessonId: 'source-lesson',
          sourceRoundId: 'source-round',
          exerciseId: 'select',
          destinationLessonId: 'destination-lesson',
          destinationRoundId: 'destination-round',
        ),
        () => transfers.moveRound(
          source,
          sourceLessonId: 'source-lesson',
          roundId: 'source-round',
          destinationLessonId: 'empty-lesson',
        ),
        () => transfers.copyRound(
          source,
          sourceLessonId: 'source-lesson',
          roundId: 'source-round',
          destinationLessonId: 'empty-lesson',
        ),
      ]) {
        expect(
          operation,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'official guidance',
              contains('read only'),
            ),
          ),
        );
        expect(jsonEncode(source.toJson()), before);
      }
    });
  }

  test(
    'all transfers stay in one transaction: Cancel writes nothing; Confirm versions once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'qql_transfer_22602_',
      );
      addTearDown(() => directory.delete(recursive: true));
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: _profileId,
            displayName: 'Transfer Author',
          ).encode(),
        ],
        ProfileService.activeProfileIdKey: _profileId,
        'learner-progress-sentinel': ['completed-round'],
        'learner-xp-sentinel': 321,
        'learner-review-sentinel': 'unchanged',
      });
      var writes = 0;
      final backups = CourseBackupService(
        documentsDirectoryProvider: () async => directory,
      );
      final storage = CourseEditorService(
        backupService: backups,
        clock: () => _editTime,
        preferenceWriter: (preferences, key, value) async {
          writes++;
          return preferences.setString(key, value);
        },
      );
      final source = _course();
      await storage.saveUserCourse(source);
      writes = 0;
      final preferences = await SharedPreferences.getInstance();
      final storedBefore = {
        for (final key in preferences.getKeys()) key: preferences.get(key),
      };
      final transaction = CourseEditorTransaction(source);

      void stageAll() {
        transaction.replaceWorkingCourse(
          transfers.moveExercise(
            transaction.workingCourse,
            sourceLessonId: 'source-lesson',
            sourceRoundId: 'source-round',
            exerciseId: 'select',
            destinationLessonId: 'destination-lesson',
            destinationRoundId: 'destination-round',
          ),
        );
        transaction.replaceWorkingCourse(
          transfers.copyExercise(
            transaction.workingCourse,
            sourceLessonId: 'source-lesson',
            sourceRoundId: 'source-round',
            exerciseId: 'arrange',
            destinationLessonId: 'destination-lesson',
            destinationRoundId: 'destination-round',
          ),
        );
        transaction.replaceWorkingCourse(
          transfers.copyRound(
            transaction.workingCourse,
            sourceLessonId: 'source-lesson',
            roundId: 'source-round',
            destinationLessonId: 'empty-lesson',
          ),
        );
        transaction.replaceWorkingCourse(
          transfers.moveRound(
            transaction.workingCourse,
            sourceLessonId: 'source-lesson',
            roundId: 'spare-round',
            destinationLessonId: 'empty-lesson',
          ),
        );
      }

      stageAll();
      expect(transaction.hasChanges, isTrue);
      expect(transaction.originalCourse.toJson(), source.toJson());
      expect(transaction.workingCourse.courseVersion, '7');
      expect(
        transaction.workingCourse.forkProvenance!.toJson(),
        source.forkProvenance!.toJson(),
      );
      expect(writes, 0);
      expect({
        for (final key in preferences.getKeys()) key: preferences.get(key),
      }, storedBefore);
      expect(await backups.listBackups(source.courseId), isEmpty);
      expect(
        (await storage.listUserCourses()).single.toJson(),
        source.toJson(),
      );
      transaction.cancel();
      expect(transaction.hasChanges, isFalse);
      expect(transaction.workingCourse.toJson(), source.toJson());
      expect(writes, 0);
      expect({
        for (final key in preferences.getKeys()) key: preferences.get(key),
      }, storedBefore);

      stageAll();
      final confirmed = await storage.confirmCourseTransaction(
        originalCourse: transaction.originalCourse,
        workingCourse: transaction.workingCourse,
        languageCode: 'IT',
        versionNotes: 'Reviewed transfers',
      );
      expect(confirmed.course.courseVersion, '8');
      expect(
        confirmed.course.forkProvenance!.toJson(),
        source.forkProvenance!.toJson(),
      );
      expect(writes, 1);
      expect(await backups.listBackups(source.courseId), hasLength(1));
      expect((await storage.listUserCourses()).single.courseVersion, '8');
      for (final key in storedBefore.keys.where(
        (key) => key.startsWith('learner-'),
      )) {
        expect(preferences.get(key), storedBefore[key]);
      }
    },
  );
}

void _expectEvaluationReferences(String id, Exercise exercise) {
  final items = exercise.interaction.items;
  switch (id) {
    case 'select':
      expect(exercise.evaluation.correctItemIds, [items[1].id]);
    case 'arrange':
      expect(exercise.evaluation.correctOrders.single.text, 'B A');
      expect(exercise.evaluation.correctOrders.single.itemIds, [
        items[1].id,
        items[0].id,
      ]);
    case 'match':
      expect(exercise.evaluation.pairs, [
        [items[0].id, items[1].id],
        [items[2].id, items[3].id],
      ]);
    case 'input':
      expect(items, isEmpty);
      expect(exercise.evaluation.kind, 'text_match');
      expect(exercise.evaluation.accepted, ['Authored answer']);
  }
}

void _expectCourseAndLessonMetadata(Course result, Course source) {
  expect(
    result.toJson()..remove('lessons'),
    source.toJson()..remove('lessons'),
  );
  for (var i = 0; i < source.lessons.length; i++) {
    expect(
      result.lessons[i].toJson()
        ..remove('rounds')
        ..remove('updatedAt'),
      source.lessons[i].toJson()
        ..remove('rounds')
        ..remove('updatedAt'),
    );
  }
}

LearningRound _round(Course course, String id) => course.lessons
    .expand((lesson) => lesson.rounds)
    .singleWhere((round) => round.id == id);

Iterable<LearningContent> _allContent(Course course) => [
  for (final lesson in course.lessons) ...[
    ...lesson.guidebook.content,
    for (final round in lesson.rounds) ...round.content,
  ],
];

Set<String> _ownedContentIds(LearningContent content) => {
  content.id,
  if (content.exercise != null) ...{
    content.exercise!.id,
    for (final item in content.exercise!.interaction.items) item.id,
  },
};

Course _course({PublicationState state = PublicationState.published}) => Course(
  courseId: 'transfer-course',
  originalCourseCreator: const CourseProvenanceIdentity.publisher(
    publisherId: 'fixture.publisher',
    displayName: 'Fixture publisher',
  ),
  maintainer: const CourseMaintainer(_profileId),
  publicationState: PublicationState.draft,
  originalCreatedAtUtc: _originalTime.toIso8601String(),
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Earlier editor',
  modifiedAtUtc: _originalTime.toIso8601String(),
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Transfer fixture',
  ttsLanguage: 'it-IT',
  audioMode: 'hybrid',
  authors: const [
    CourseAuthor(name: 'Fixture author', roles: ['Author', 'Illustrator']),
  ],
  license: 'Fixture license',
  derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
  forkProvenance: CourseForkProvenance(
    sourceCourseId: 'official-parent',
    sourceCourseTitle: 'Original fixture',
    sourceCourseVersion: '3',
    sourceOriginType: CourseOriginType.bundledOfficial,
    sourcePublisherId: 'fixture.publisher',
    sourcePublisherName: 'Fixture publisher',
    sourceOfficialChecksum: List.filled(64, 'a').join(),
    sourceAuthors: const [
      CourseAuthor(name: 'Original fixture author', roles: ['Author']),
    ],
    forkCreatedByProfileId: _profileId,
    forkCreatedByDisplayName: 'Original fork creator',
    forkCreatedAtUtc: _originalTime.toIso8601String(),
  ),
  versionNotes: 'Existing version notes',
  restoredFromVersion: 2,
  courseVersion: '7',
  courseDescription: 'Existing description',
  sourceLanguageTag: 'en-GB',
  targetLanguageTag: 'it-IT',
  languageVariant: 'Standard',
  startLevel: 'A1',
  targetLevel: 'A2',
  flagCode: 'IT',
  buyACoffeeUrl: 'https://example.com/coffee',
  lessonNumberingMode: LessonNumberingMode.other,
  customLessonLabel: 'Unit',
  audioLibrary: const [
    CourseAudioClip(
      id: 'audio',
      text: 'ciao',
      filePath: 'assets/audio/ciao.mp3',
    ),
  ],
  lessons: [
    Lesson(
      lessonId: 'source-lesson',
      publicationState: state,
      updatedAt: _originalTime,
      title: 'Identical readable title',
      section: true,
      sectionName: 'Section A',
      themeIconAsset: 'assets/lesson_icons/home.png',
      guidebook: Guidebook(
        content: const [
          LearningContent(
            id: 'guide',
            kind: 'text',
            role: 'lesson_intro',
            text: 'GuideBook',
          ),
        ],
      ),
      duel: Duel(id: 'source-duel', title: 'Original Duel'),
      rounds: [
        LearningRound(
          id: 'source-round',
          publicationState: state,
          updatedAt: _originalTime,
          title: '',
          visualType: 'story',
          content: [
            LearningContent(
              id: 'note',
              publicationState: state,
              kind: 'text',
              required: false,
              editorTemplate: 'text',
              role: 'round_note',
              text: 'A note',
              sourceRefs: ['guide'],
            ),
            LearningContent(
              id: 'presentation',
              publicationState: state,
              kind: 'presentation',
              required: false,
              editorTemplate: 'flashcard',
              role: 'round_note',
              text: 'Creator metadata',
              sourceRefs: ['guide'],
              presentation: Presentation(
                content: [
                  const PromptElement(role: 'term', type: 'text', text: 'Casa'),
                  const PromptElement(
                    role: 'meaning',
                    type: 'text',
                    text: 'House',
                  ),
                  const PromptElement(
                    type: 'image',
                    asset: 'assets/exercise_images/house.png',
                  ),
                ],
                actions: ['understood'],
              ),
            ),
            _content('select', state),
            _content('arrange', state),
            _content('match', state),
            _content('input', state),
          ],
        ),
        LearningRound(
          id: 'spare-round',
          updatedAt: _originalTime,
          title: 'Spare',
          content: [],
        ),
      ],
    ),
    Lesson(
      lessonId: 'destination-lesson',
      publicationState: PublicationState.draft,
      updatedAt: _originalTime,
      title: 'Identical readable title',
      rounds: [
        LearningRound(
          id: 'destination-round',
          updatedAt: _originalTime,
          title: 'Destination',
          content: [
            const LearningContent(
              id: 'destination-note',
              kind: 'text',
              text: 'Keep me',
            ),
          ],
        ),
      ],
    ),
    Lesson(
      lessonId: 'empty-lesson',
      updatedAt: _originalTime,
      title: 'Empty Lesson',
      rounds: [],
    ),
  ],
);

LearningContent _content(String id, PublicationState state) {
  final template = switch (id) {
    'select' => 'choice',
    'input' => 'type_translation',
    'arrange' => 'word_order',
    _ => 'match',
  };
  final items = [
    for (
      var i = 0;
      i <
          (id == 'input'
              ? 0
              : id == 'match'
              ? 4
              : 2);
      i++
    )
      ExerciseItem(
        id: '${id}_item_$i',
        content: [
          PromptElement(type: 'text', text: String.fromCharCode(65 + i)),
        ],
      ),
  ];
  return LearningContent(
    id: id,
    publicationState: state,
    kind: 'exercise',
    required: false,
    editorTemplate: template,
    role: 'round_note',
    text: 'Preserve wrapper text',
    sourceRefs: ['guide', 'note', id],
    exercise: Exercise.v2(
      id: id,
      publicationState: state,
      updatedAt: _originalTime,
      editorTemplate: template,
      promptElements: [
        const PromptElement(type: 'text', text: 'Question'),
        const PromptElement(
          type: 'audio',
          asset: 'assets/audio/ciao.mp3',
          text: 'Ciao',
          speaker: 'Fixture speaker',
        ),
      ],
      interaction: ExerciseInteraction(
        kind: id,
        inputType: id == 'input' ? 'text' : '',
        items: items,
        minSelections: 1,
        maxSelections: 1,
      ),
      evaluation: ExerciseEvaluation(
        kind: switch (id) {
          'select' => 'selected_items',
          'input' => 'text_match',
          'arrange' => 'ordered_items',
          _ => 'pairs',
        },
        correctItemIds: id == 'select' ? [items[1].id] : [],
        correctOrders: id == 'arrange'
            ? [
                OrderedAnswer(text: 'B A', itemIds: [items[1].id, items[0].id]),
              ]
            : [],
        pairs: id == 'match'
            ? [
                [items[0].id, items[1].id],
                [items[2].id, items[3].id],
              ]
            : [],
        accepted: ['Authored answer'],
        normalization: {
          'caseSensitive': false,
          'metadata': {
            'notes': ['original'],
          },
        },
      ),
      hint: 'Creator hint',
      feedback: {
        'correct': 'Correct feedback',
        'incorrect': 'Diagnostic feedback',
      },
      missingWords: ['authored'],
    ),
  );
}

class _SequenceIds implements AuthoringIdGenerator {
  var _sequence = 0;

  @override
  String next(String kind) => 'fresh_${kind}_${_sequence++}';
}

class _CollidingIds implements AuthoringIdGenerator {
  _CollidingIds(this.id);

  final String id;

  @override
  String next(String kind) => id;
}
