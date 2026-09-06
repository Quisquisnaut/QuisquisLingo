import '../models/course_models.dart';
import 'authoring_duplication_service.dart';

/// Moves or copies content inside one custom Course Editor working copy.
///
/// Every operation returns a replacement course without mutating its input.
/// The caller stages that value in the existing course transaction; only the
/// final course confirmation owns persistence, versioning and backups.
class CourseAuthoringTransferService {
  CourseAuthoringTransferService({
    AuthoringDuplicationService? duplication,
    DateTime Function()? clock,
  }) : _duplication = duplication ?? AuthoringDuplicationService(),
       _clock = clock ?? DateTime.now;

  final AuthoringDuplicationService _duplication;
  final DateTime Function() _clock;

  Course moveExercise(
    Course course, {
    required String sourceLessonId,
    required String sourceRoundId,
    required String exerciseId,
    required String destinationLessonId,
    required String destinationRoundId,
  }) => _transferExercise(
    course,
    sourceLessonId: sourceLessonId,
    sourceRoundId: sourceRoundId,
    exerciseId: exerciseId,
    destinationLessonId: destinationLessonId,
    destinationRoundId: destinationRoundId,
    copy: false,
  );

  /// Copies start as Draft, following the authoritative duplication workflow.
  Course copyExercise(
    Course course, {
    required String sourceLessonId,
    required String sourceRoundId,
    required String exerciseId,
    required String destinationLessonId,
    required String destinationRoundId,
  }) => _transferExercise(
    course,
    sourceLessonId: sourceLessonId,
    sourceRoundId: sourceRoundId,
    exerciseId: exerciseId,
    destinationLessonId: destinationLessonId,
    destinationRoundId: destinationRoundId,
    copy: true,
  );

  Course moveRound(
    Course course, {
    required String sourceLessonId,
    required String roundId,
    required String destinationLessonId,
  }) => _transferRound(
    course,
    sourceLessonId: sourceLessonId,
    roundId: roundId,
    destinationLessonId: destinationLessonId,
    copy: false,
  );

  /// Copies start as Draft, including their recursively duplicated Content.
  Course copyRound(
    Course course, {
    required String sourceLessonId,
    required String roundId,
    required String destinationLessonId,
  }) => _transferRound(
    course,
    sourceLessonId: sourceLessonId,
    roundId: roundId,
    destinationLessonId: destinationLessonId,
    copy: true,
  );

  Course _transferExercise(
    Course course, {
    required String sourceLessonId,
    required String sourceRoundId,
    required String exerciseId,
    required String destinationLessonId,
    required String destinationRoundId,
    required bool copy,
  }) {
    _requireCustom(course);
    final sourceLesson = _lesson(course, sourceLessonId);
    final destinationLesson = _lesson(course, destinationLessonId);
    final sourceRound = _round(course, sourceLesson, sourceRoundId);
    final destinationRound = _round(
      course,
      destinationLesson,
      destinationRoundId,
    );
    if (!copy && identical(sourceRound, destinationRound)) {
      throw StateError('Choose a different Round for Move Exercise.');
    }
    final source = _unique(
      sourceRound.content.where(
        (content) =>
            content.role != 'lesson_intro' &&
            content.asRunnableExercise()?.id == exerciseId,
      ),
      'Exercise',
      exerciseId,
    );
    _checkContentIdentity(course, source);
    final transferred = copy ? _duplication.duplicateContent(source) : source;
    if (copy) {
      _requireFreshIds(
        course,
        _contentIds(transferred),
        sourceIds: _contentIds(source),
      );
    }
    final now = _clock().toUtc();
    final replacements = <LearningRound, LearningRound>{
      if (!copy)
        sourceRound: _withContent(sourceRound, [
          for (final content in sourceRound.content)
            if (!identical(content, source)) content,
        ], now),
      destinationRound: _withContent(destinationRound, [
        ...destinationRound.content,
        transferred,
      ], now),
    };
    return _withLessons(course, [
      for (final lesson in course.lessons)
        if (lesson.rounds.any(replacements.containsKey))
          _withRounds(lesson, [
            for (final round in lesson.rounds) replacements[round] ?? round,
          ], now)
        else
          lesson,
    ]);
  }

  Course _transferRound(
    Course course, {
    required String sourceLessonId,
    required String roundId,
    required String destinationLessonId,
    required bool copy,
  }) {
    _requireCustom(course);
    final sourceLesson = _lesson(course, sourceLessonId);
    final destinationLesson = _lesson(course, destinationLessonId);
    final source = _round(course, sourceLesson, roundId);
    if (!copy && identical(sourceLesson, destinationLesson)) {
      throw StateError('Choose a different Lesson for Move Round.');
    }
    for (final content in source.content) {
      _checkContentIdentity(course, content);
    }
    final transferred = copy ? _duplication.duplicateRound(source) : source;
    if (copy) {
      _requireFreshIds(
        course,
        [
          transferred.id,
          for (final content in transferred.content) ..._contentIds(content),
        ],
        sourceIds: [
          source.id,
          for (final content in source.content) ..._contentIds(content),
        ],
      );
    }
    final now = _clock().toUtc();
    return _withLessons(course, [
      for (final lesson in course.lessons)
        if (identical(lesson, destinationLesson))
          _withRounds(lesson, [...lesson.rounds, transferred], now)
        else if (!copy && identical(lesson, sourceLesson))
          _withRounds(lesson, [
            for (final round in lesson.rounds)
              if (!identical(round, source)) round,
          ], now)
        else
          lesson,
    ]);
  }

  void _requireCustom(Course course) {
    if (course.originType != CourseOriginType.custom) {
      throw StateError(
        'Official courses are read only. Open an editable custom course to move or copy content.',
      );
    }
  }

  Lesson _lesson(Course course, String id) => _unique(
    course.lessons.where((lesson) => lesson.lessonId == id),
    'Lesson',
    id,
  );

  LearningRound _round(Course course, Lesson lesson, String id) {
    final round = _unique(
      course.lessons.expand((lesson) => lesson.rounds).where((r) => r.id == id),
      'Round',
      id,
    );
    if (!lesson.rounds.contains(round)) {
      throw StateError(
        'Round "$id" is no longer in the selected Lesson. Choose its current location.',
      );
    }
    return round;
  }

  T _unique<T>(Iterable<T> matches, String kind, String id) {
    final values = matches.toList(growable: false);
    if (id.trim().isEmpty || values.isEmpty) {
      throw StateError(
        '$kind "$id" is missing from the current course. Choose an existing destination or reopen the source.',
      );
    }
    if (values.length != 1) {
      throw StateError(
        '$kind ID "$id" is duplicated. Resolve the duplicate IDs in Course Audit before transferring content.',
      );
    }
    return values.single;
  }

  Iterable<LearningContent> _allContent(Course course) sync* {
    for (final lesson in course.lessons) {
      yield* lesson.guidebook.content;
      for (final round in lesson.rounds) {
        yield* round.content;
      }
    }
  }

  void _checkContentIdentity(Course course, LearningContent content) {
    for (final id in {
      content.id,
      if (content.exercise != null) content.exercise!.id,
    }) {
      _unique(
        _allContent(course).where((c) => c.id == id || c.exercise?.id == id),
        'Content',
        id,
      );
    }
    final itemIds = content.exercise?.interaction.items.map((item) => item.id);
    if (itemIds != null &&
        (itemIds.any((id) => id.trim().isEmpty) ||
            itemIds.toSet().length != itemIds.length)) {
      throw StateError(
        'Exercise "${content.id}" has empty or duplicate Item IDs. Resolve them in Course Audit before transferring content.',
      );
    }
  }

  Iterable<String> _contentIds(LearningContent content) sync* {
    yield content.id;
    final exercise = content.exercise;
    if (exercise != null) {
      yield exercise.id;
      yield* exercise.interaction.items.map((item) => item.id);
    }
  }

  void _requireFreshIds(
    Course course,
    Iterable<String> copiedIds, {
    required Iterable<String> sourceIds,
  }) {
    final existing = {
      course.courseId,
      for (final asset in course.lessonIconAssets) asset.assetId,
      for (final audio in course.audioLibrary) audio.id,
      for (final lesson in course.lessons) ...[
        lesson.lessonId,
        lesson.duel.id,
        for (final round in lesson.rounds) round.id,
      ],
      for (final content in _allContent(course)) ..._contentIds(content),
    };
    final copied = copiedIds.toSet();
    if (copied.length != sourceIds.toSet().length ||
        copied.any((id) => id.trim().isEmpty || existing.contains(id))) {
      throw StateError(
        'Copy could not create fresh IDs. The working copy is unchanged; retry the copy.',
      );
    }
  }

  LearningRound _withContent(
    LearningRound source,
    List<LearningContent> content,
    DateTime now,
  ) => LearningRound(
    id: source.id,
    publicationState: source.publicationState,
    updatedAt: now,
    title: source.title,
    visualType: source.visualType,
    content: content,
  );

  Lesson _withRounds(Lesson source, List<LearningRound> rounds, DateTime now) =>
      Lesson(
        lessonId: source.lessonId,
        publicationState: source.publicationState,
        updatedAt: now,
        title: source.title,
        rounds: rounds,
        section: source.section,
        sectionName: source.sectionName,
        themeIconAsset: source.themeIconAsset,
        guidebook: source.guidebook,
        duel: source.duel,
      );

  Course _withLessons(Course source, List<Lesson> lessons) => Course(
    formatVersion: source.formatVersion,
    courseId: source.courseId,
    originType: source.originType,
    publisherId: source.publisherId,
    publisherName: source.publisherName,
    officialCourseVersion: source.officialCourseVersion,
    officialReleaseDateUtc: source.officialReleaseDateUtc,
    officialChecksum: source.officialChecksum,
    officialReleaseNotes: source.officialReleaseNotes,
    distributionChannel: source.distributionChannel,
    publisherVerificationStatus: source.publisherVerificationStatus,
    publisherSignature: source.publisherSignature,
    createdByProfileId: source.createdByProfileId,
    createdByUsername: source.createdByUsername,
    createdAtUtc: source.createdAtUtc,
    lastModifiedByProfileId: source.lastModifiedByProfileId,
    lastModifiedByUsername: source.lastModifiedByUsername,
    lastModifiedAtUtc: source.lastModifiedAtUtc,
    versionNotes: source.versionNotes,
    restoredFromVersion: source.restoredFromVersion,
    publicationState: source.publicationState,
    lessonNumberingMode: source.lessonNumberingMode,
    customLessonLabel: source.customLessonLabel,
    defaultLessonIconStyle: source.defaultLessonIconStyle,
    createDuels: source.createDuels,
    useGuidebook: source.useGuidebook,
    sectionNames: source.sectionNames,
    parentCourseId: source.parentCourseId,
    derivedFromVersion: source.derivedFromVersion,
    learningLanguage: source.learningLanguage,
    interfaceLanguage: source.interfaceLanguage,
    sourceLanguage: source.sourceLanguage,
    targetLanguage: source.targetLanguage,
    title: source.title,
    ttsLanguage: source.ttsLanguage,
    version: source.version,
    contentRevision: source.contentRevision,
    updateSummary: source.updateSummary,
    audioMode: source.audioMode,
    author: source.author,
    authors: source.authors,
    license: source.license,
    derivativeWorksPolicy: source.derivativeWorksPolicy,
    forkProvenance: source.forkProvenance,
    languageVariant: source.languageVariant,
    startLevel: source.startLevel,
    targetLevel: source.targetLevel,
    courseVersion: source.courseVersion,
    lastUpdated: source.lastUpdated,
    courseDescription: source.courseDescription,
    sourceLanguageTag: source.sourceLanguageTag,
    targetLanguageTag: source.targetLanguageTag,
    textDirection: source.textDirection,
    flagCode: source.flagCode,
    flagImageBase64: source.flagImageBase64,
    worldFlagId: source.worldFlagId,
    temporarySample: source.temporarySample,
    buyACoffeeUrl: source.buyACoffeeUrl,
    lessonIconAssets: source.lessonIconAssets,
    audioLibrary: source.audioLibrary,
    lessons: lessons,
  );
}
