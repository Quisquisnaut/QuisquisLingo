import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/audio_exercise_availability_service.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_filter.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/import/mp3_validator.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/services/vocabulary_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _asset = 'assets/courses/edge_case_it_en.json';
const _courseId = 'course_6f6a1fa3-b834-4936-b324-92fb57f73502';
const _actor = '12345678-1234-4234-9234-123456789abc';
const _prefix = 'qql_edge_254_';
final _clock = DateTime.utc(2026, 9, 25, 10);

Iterable<Exercise> _exercises(Course course) => course.lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.exercises);

Exercise _exercise(Course course, String suffix) => _exercises(
  course,
).singleWhere((exercise) => exercise.id == '$_prefix$suffix');

Iterable<LearningContent> _contents(Course course) => course.lessons.expand(
  (lesson) => [
    ...lesson.guidebook.content,
    ...lesson.rounds.expand((round) => round.content),
  ],
);

Set<String> _ownedIds(Course course) => {
  course.courseId,
  for (final lesson in course.lessons) ...[
    lesson.lessonId,
    lesson.duel.id,
    for (final round in lesson.rounds) round.id,
  ],
  for (final content in _contents(course)) content.id,
  for (final exercise in _exercises(course))
    for (final item in exercise.interaction.items) item.id,
};

void _expectReferencesResolve(Course course) {
  final contentIds = _contents(course).map((content) => content.id).toSet();
  for (final content in _contents(course)) {
    expect(content.sourceRefs.every(contentIds.contains), isTrue);
  }
  for (final exercise in _exercises(course)) {
    final items = exercise.interaction.items.map((item) => item.id).toSet();
    final references = {
      ...exercise.evaluation.correctItemIds,
      ...exercise.evaluation.gapAssignments.values,
      for (final order in exercise.evaluation.correctOrders) ...order.itemIds,
    };
    expect(references.every(items.contains), isTrue, reason: exercise.id);
  }
}

Uint8List _jsonBytes(Course course) =>
    Uint8List.fromList(utf8.encode(jsonEncode(course.toJson())));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late Course source;
  late CourseMediaStore media;
  late CoursePackageService packages;
  late CourseEditorService editor;
  late CustomCourseTransferService transfer;

  CourseEditorService editorAt(Directory directory, CourseMediaStore store) =>
      CourseEditorService(
        courseStore: CourseFileStore(supportDirectory: () async => directory),
        mediaStore: store,
        backupService: CourseBackupService(
          supportDirectoryProvider: () async => directory,
          mediaStore: store,
        ),
        clock: () => _clock,
      );

  setUp(() async {
    support = await Directory.systemTemp.createTemp('qql_edge_254_');
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _actor,
          displayName: 'Edge Case Reviewer',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _actor,
    });
    source = Course.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(await rootBundle.loadString(_asset)) as Map,
      ),
    );
    media = CourseMediaStore(supportDirectory: () async => support);
    packages = CoursePackageService(
      mediaStore: media,
      stager: ImportStager(supportDirectory: () async => support),
    );
    editor = editorAt(support, media);
    transfer = CustomCourseTransferService(
      directory: () async => support,
      packageService: packages,
    );
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  test(
    'shipped demo round-trips with exactly its two intentional warnings',
    () async {
      final raw = jsonDecode(await rootBundle.loadString(_asset));
      expect(source.toJson(), raw);
      expect(source.courseId, _courseId);
      expect(source.sourceLanguageTag, 'it-IT');
      expect(source.targetLanguageTag, 'en-GB');
      expect(source.lessons, hasLength(5));
      expect(source.lessons.expand((lesson) => lesson.rounds), hasLength(10));
      expect(_exercises(source), hasLength(31));
      expect(CourseChecksums.official(source), source.officialChecksum);
      final audit = CourseAuditService().auditCourse(source);
      expect(audit.count(AuditSeverity.error), 0);
      expect(
        audit.issues
            .where((issue) => issue.severity == AuditSeverity.warning)
            .map((issue) => '${issue.code}:${issue.exerciseId}'),
        unorderedEquals([
          'CHOICE_ANSWER_DUPLICATE:${_prefix}e04_duplicate',
          'EXERCISE_TEXT_LONG:${_prefix}e07_long',
        ]),
      );
      _expectReferencesResolve(source);
    },
  );

  test(
    'learner projection omits Draft ancestry and preserves independent vocabulary',
    () {
      expect(CourseLibraryFilter.isUnavailable(source), isTrue);
      final learner = const PublicationService().learnerCourse(source)!;
      expect(learner.lessons, hasLength(4));
      expect(_exercises(learner), hasLength(28));
      expect(learner.lessons.last.rounds, hasLength(1));
      expect(learner.lessons.last.rounds.single.title, isEmpty);
      expect(learner.lessons.last.rounds.single.displayTitle(0), 'Round 1');
      expect(learner.lessons.last.guidebook.content, isEmpty);
      expect(
        _exercises(
          learner,
        ).every((exercise) => exercise.publicationState.isPublished),
        isTrue,
      );
      for (final lesson in learner.lessons) {
        for (final round in lesson.rounds) {
          expect(
            RoundPlayabilityService().playableExerciseIndices(round),
            isNotEmpty,
          );
        }
      }
      final vocabulary = VocabularyReviewService();
      final entries = vocabulary.resolveEntries(source, source.lessons.first);
      expect(entries, hasLength(7));
      final repeated = entries
          .where((entry) => entry.prompt == 'hello')
          .toList();
      expect(repeated, hasLength(2));
      expect(repeated[0].identity, isNot(repeated[1].identity));
      expect(
        entries
            .singleWhere((entry) => entry.contentId == '${_prefix}v_caffè_日本語')
            .answer,
        'caffè',
      );
      expect(vocabulary.resolveEntries(source, source.lessons[3]), isEmpty);
    },
  );

  test(
    'repeated words, duplicate options and gap boundaries remain distinct',
    () {
      final repeated = _exercise(source, 'e11_repeat');
      final really = repeated.interaction.items
          .where((item) => item.text == 'really')
          .toList();
      expect(really, hasLength(2));
      expect(really[0].id, isNot(really[1].id));
      final order = repeated.evaluation.correctOrders.single;
      expect(order.itemIds.toSet(), hasLength(order.itemIds.length));
      expect(order.text, 'I really really like this book');
      final duplicates = _exercise(source, 'e04_duplicate');
      expect(duplicates.answers, ['red', 'blue', 'blue']);
      expect(duplicates.evaluation.correctItemIds, [
        '${_prefix}e04_duplicate_i1',
      ]);
      expect(
        duplicates.interaction.items.map((item) => item.id).toSet(),
        hasLength(3),
      );
      expect(_exercise(source, 'e02_max_translation').answers, hasLength(5));
      expect(_exercise(source, 'e03_many').answers, hasLength(12));
      final minimum = _exercise(source, 'e17_select_min');
      expect(minimum.hasSelectGaps, isTrue);
      expect(minimum.interaction.items, hasLength(1));
      final linked = _exercise(source, 'e18_select_linked');
      expect(linked.evaluation.gapAssignments, hasLength(2));
      expect(linked.evaluation.gapAssignments.values.toSet(), hasLength(1));
      final arrange = _exercise(source, 'e15_arrange_repeat');
      expect(arrange.evaluation.gapAssignments.values.toSet(), hasLength(2));
      expect(_exercise(source, 'e09_accents').accepted, [
        'caf\u00e9',
        'cafe\u0301',
      ]);
    },
  );

  test(
    'real bundled MP3s resolve and each Course audio mode selects the expected path',
    () async {
      final recorded = RecordedAudioService(
        supportDirectory: () async => support,
      );
      final availability = AudioExerciseAvailabilityService(
        recordedAudio: recorded,
      );
      for (final clip in source.audioLibrary) {
        final data = await rootBundle.load(clip.filePath);
        await Mp3Validator.validate(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        expect(
          await recorded.resolveSourceForClip(clip, courseId: source.courseId),
          isNotNull,
        );
      }
      final sequence = _exercise(source, 'e25_mp3_sequence');
      expect(
        recorded
            .segment(sequence.tts!, source.audioLibrary)
            ?.map((clip) => clip.id),
        ['${_prefix}audio_01', '${_prefix}audio_02'],
      );
      final mp3 = _exercise(source, 'e24_mp3');
      final tts = _exercise(source, 'e26_tts');
      expect(await availability.hasRecordedSource(source, mp3), isTrue);
      expect(await availability.hasRecordedSource(source, tts), isFalse);
      for (final mode in ['tts', 'recorded', 'hybrid']) {
        final course = Course.fromJson({...source.toJson(), 'audioMode': mode});
        for (final enabled in [false, true]) {
          expect(
            await availability.isAvailable(course, mp3, ttsEnabled: enabled),
            mode == 'tts' ? enabled : true,
            reason: '$mode / TTS $enabled / mapped',
          );
          expect(
            await availability.isAvailable(course, tts, ttsEnabled: enabled),
            mode == 'recorded' ? false : enabled,
            reason: '$mode / TTS $enabled / unmapped',
          );
        }
        expect(
          await availability.evaluateRound(
            course,
            course.lessons[2].rounds[1],
            audioExercisesEnabled: false,
            ttsEnabled: true,
          ),
          EffectiveRoundAudioAvailability.audioExercisesDisabled,
        );
      }
    },
  );

  test(
    'bundled ZIP exports faithfully and ordinary Import rejects bundled installation',
    () async {
      final payload = await transfer.buildCourseExport(source);
      final file = File('${support.path}/Original café_日本語 (1).zip');
      await file.writeAsBytes(payload.bytes);
      final parsed = await packages.parseFile(
        file,
        (bytes, _) async => Course.fromJson(
          Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
        ),
      );
      try {
        expect(parsed.course.toJson(), source.toJson());
        expect(
          parsed.mediaReferences,
          isEmpty,
          reason: 'Bundled asset references stay bundled',
        );
        expect(
          CourseChecksums.official(parsed.course),
          source.officialChecksum,
        );
      } finally {
        await parsed.discard();
      }
      await expectLater(
        packages.parseFile(file, transfer.courseFromBytes),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Bundled official courses are installed only'),
          ),
        ),
      );
    },
  );

  test(
    'Fork and Copy persist fresh identities and compatible revisions Merge',
    () async {
      final before = source.toJson();
      final officialRights = CourseAccessPolicy.evaluate(
        source,
        profileId: _actor,
      );
      expect(officialRights.canFork, isTrue);
      expect(officialRights.canCopyAsNewCourse, isFalse);
      final fork = (await editor.createFork(source: source)).course;
      expect(fork.courseId, isNot(source.courseId));
      expect(fork.originType, CourseOriginType.custom);
      expect(
        fork.originalCourseCreator.toJson(),
        source.originalCourseCreator.toJson(),
      );
      expect(fork.forkProvenance!.sourceCourseId, source.courseId);
      expect(
        fork.forkProvenance!.sourceOfficialChecksum,
        source.officialChecksum,
      );
      expect(fork.maintainer!.profileId, _actor);
      expect(fork.publicationState, PublicationState.draft);
      expect(_ownedIds(fork).intersection(_ownedIds(source)), isEmpty);
      _expectReferencesResolve(fork);
      final copy = (await editor.createCopyAsNewCourse(
        source: fork,
        title: 'Caffè_日本語 copy (1)',
      )).course;
      expect(copy.originalCourseCreator.id, _actor);
      expect(copy.forkProvenance, isNull);
      expect(_ownedIds(copy).intersection(_ownedIds(fork)), isEmpty);
      expect(
        copy.audioLibrary.map((clip) => clip.filePath),
        source.audioLibrary.map((clip) => clip.filePath),
      );
      _expectReferencesResolve(copy);
      final merge = CourseMergeService(
        clock: () => _clock.add(const Duration(hours: 2)),
      );
      expect(
        () => merge.validateCompatibility(fork, copy),
        throwsFormatException,
      );
      expect(
        () => merge.validateCompatibility(fork, fork),
        throwsFormatException,
      );
      final earlier = await packages.parse(
        (await transfer.buildCourseExport(fork)).bytes,
        transfer.courseFromBytes,
      );
      try {
        final working = Course.fromJson({
          ...fork.toJson(),
          'title': '${fork.title} revision 2',
        });
        final newer = (await editor.confirmCourseTransaction(
          originalCourse: fork,
          workingCourse: working,
          languageCode: 'EN',
          versionNotes: 'Edge fixture revision for same-ID Merge.',
          committedAt: _clock.add(const Duration(hours: 1)),
        )).course;
        expect(newer.courseId, earlier.course.courseId);
        expect(newer.courseVersion, isNot(earlier.course.courseVersion));
        final candidate = await merge.createMergedCourse(
          left: newer,
          right: earlier.course,
          choices: const [
            LessonMergeChoice.left,
            LessonMergeChoice.right,
            LessonMergeChoice.left,
            LessonMergeChoice.right,
            LessonMergeChoice.left,
          ],
          options: CourseMergeOptions.fromCourse(newer),
        );
        final merged = (await editor.confirmMergedCourse(
          left: newer,
          right: earlier.course,
          merged: candidate,
        )).course;
        expect(merged.courseId, isNot(fork.courseId));
        expect(
          merged.mergeProvenance!.leftSourceCourseVersion,
          newer.courseVersion,
        );
        expect(
          merged.mergeProvenance!.rightSourceCourseVersion,
          earlier.course.courseVersion,
        );
        expect(_exercises(merged), hasLength(31));
        expect(_ownedIds(merged).intersection(_ownedIds(fork)), isEmpty);
        _expectReferencesResolve(merged);
        expect(await editor.listUserCourses(), hasLength(3));
      } finally {
        await earlier.discard();
      }
      expect(source.toJson(), before);
    },
  );

  test(
    'personal fork imports a real package with shipped image and MP3 bytes',
    () async {
      final fork = (await editor.createFork(source: source)).course;
      final mp3 = await File(
        'assets/audio/en_sample/sample_1.mp3',
      ).readAsBytes();
      final picture = await File(
        'assets/exercise_images/cat.webp',
      ).readAsBytes();
      final mp3Ref = CourseMediaStore.referenceFor(mp3, 'mp3');
      final imageRef = CourseMediaStore.referenceFor(picture, 'webp');
      final raw = fork.toJson();
      ((raw['audioLibrary'] as List).first as Map)['filePath'] = mp3Ref;
      final lessons = raw['lessons'] as List;
      final imageRound = ((lessons[2] as Map)['rounds'] as List).first as Map;
      final imageExercise =
          ((imageRound['content'] as List).whereType<Map>().singleWhere(
                (content) => content['editorTemplate'] == 'image_word',
              ))['exercise']
              as Map;
      final imagePrompt = (imageExercise['prompt'] as List)
          .whereType<Map>()
          .singleWhere((part) => part['type'] == 'image');
      imagePrompt['asset'] = imageRef;
      final portable = Course.fromJson(raw);
      final zip = await packages.build(
        portable,
        _jsonBytes(portable),
        suppliedMedia: {mp3Ref: mp3, imageRef: picture},
      );
      final file = File('${support.path}/Caffè_日本語 edge-case (1).zip');
      await file.writeAsBytes(zip);
      final receiver = Directory('${support.path}/receiver');
      final receiverMedia = CourseMediaStore(
        supportDirectory: () async => receiver,
      );
      final receiverEditor = editorAt(receiver, receiverMedia);
      final receiverPackages = CoursePackageService(
        mediaStore: receiverMedia,
        stager: ImportStager(supportDirectory: () async => receiver),
      );
      final parsed = await receiverPackages.parseFile(
        file,
        transfer.courseFromBytes,
      );
      expect(parsed.mediaReferences.toSet(), {mp3Ref, imageRef});
      expect(await parsed.mediaBytes(mp3Ref), mp3);
      expect(await parsed.mediaBytes(imageRef), picture);
      expect(
        CourseAuditService()
            .auditCourse(parsed.course)
            .count(AuditSeverity.error),
        0,
      );
      await CoursePackageImport(
        parsed,
        editor: receiverEditor,
      ).installCustomCourse();
      final installed = (await receiverEditor.listUserCourses()).single;
      expect(installed.courseId, portable.courseId);
      expect(installed.publicationState, portable.publicationState);
      expect(_exercises(installed), hasLength(31));
      expect(
        await (await receiverMedia.existingFile(
          installed.courseId,
          mp3Ref,
        ))!.readAsBytes(),
        mp3,
      );
      expect(
        await (await receiverMedia.existingFile(
          installed.courseId,
          imageRef,
        ))!.readAsBytes(),
        picture,
      );
      _expectReferencesResolve(installed);
      final restored = await receiverPackages.parse(
        await receiverPackages.build(installed, _jsonBytes(installed)),
        transfer.courseFromBytes,
      );
      try {
        expect(restored.course.toJson(), installed.toJson());
        expect(await restored.mediaBytes(mp3Ref), mp3);
        expect(await restored.mediaBytes(imageRef), picture);
      } finally {
        await restored.discard();
      }
    },
  );
}
