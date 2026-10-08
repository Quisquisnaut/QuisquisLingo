import 'dart:convert';

import '../models/course_models.dart';
import 'round_flow_authoring.dart';

abstract interface class AuthoringIdGenerator {
  String next(String kind);
}

class TimestampAuthoringIdGenerator implements AuthoringIdGenerator {
  TimestampAuthoringIdGenerator({int? seed})
    : _seed = seed ?? DateTime.now().microsecondsSinceEpoch;

  final int _seed;
  int _sequence = 0;

  @override
  String next(String kind) => 'custom_${kind}_${_seed}_${_sequence++}';
}

/// Creates independent authoring copies and remaps every owned identity.
///
/// Asset paths and references outside the duplicated subtree remain shared.
class AuthoringDuplicationService {
  AuthoringDuplicationService({
    AuthoringIdGenerator? ids,
    DateTime Function()? clock,
  }) : _ids = ids ?? TimestampAuthoringIdGenerator(),
       _clock = clock ?? DateTime.now;

  final AuthoringIdGenerator _ids;
  final DateTime Function() _clock;

  /// Starts a new independent Course lineage from existing content.
  Course copyCourseAsNew(
    Course source, {
    required String title,
    required CourseProvenanceIdentity originalCourseCreator,
    required CourseMaintainer maintainer,
  }) {
    if (source.originType.isOfficial) {
      throw StateError('Official courses require a licensed Fork.');
    }
    final createdAtUtc = _clock().toUtc().toIso8601String();
    return _copyCourse(
      source,
      title: title,
      originalCourseCreator: originalCourseCreator,
      originalCreatedAtUtc: createdAtUtc,
      maintainer: maintainer,
      lastVersionEditorProfileId: originalCourseCreator.id,
      lastVersionEditorDisplayName: originalCourseCreator.displayName,
      modifiedAtUtc: createdAtUtc,
    );
  }

  Course forkOfficialCourse(
    Course source, {
    required CourseForkProvenance provenance,
    required CourseMaintainer maintainer,
  }) {
    if (!source.originType.isOfficial ||
        source.derivativeWorksPolicy != DerivativeWorksPolicy.allowed ||
        !_matchesImmediateSource(source, provenance)) {
      throw StateError(
        'An official custom fork requires explicit derivative permission and matching provenance.',
      );
    }
    final fork = _copyCourse(
      source,
      title: '${source.title} fork',
      provenance: provenance,
      originalCourseCreator: source.originalCourseCreator,
      originalCreatedAtUtc: source.originalCreatedAtUtc,
      maintainer: maintainer,
      lastVersionEditorProfileId: provenance.forkCreatedByProfileId,
      lastVersionEditorDisplayName: provenance.forkCreatedByDisplayName,
      modifiedAtUtc: provenance.forkCreatedAtUtc,
    );
    // Detach any nested JSON metadata as well as the owned authoring objects.
    return Course.fromJson(
      jsonDecode(jsonEncode(fork.toJson())) as Map<String, dynamic>,
    );
  }

  Course forkCustomCourse(
    Course source, {
    required CourseForkProvenance provenance,
    required CourseMaintainer maintainer,
  }) {
    if (source.originType != CourseOriginType.custom ||
        source.derivativeWorksPolicy != DerivativeWorksPolicy.allowed ||
        !_matchesImmediateSource(source, provenance)) {
      throw StateError(
        'A custom-course fork requires explicit derivative permission.',
      );
    }
    return _copyCourse(
      source,
      title: '${source.title} fork',
      provenance: provenance,
      originalCourseCreator: source.originalCourseCreator,
      originalCreatedAtUtc: source.originalCreatedAtUtc,
      maintainer: maintainer,
      lastVersionEditorProfileId: provenance.forkCreatedByProfileId,
      lastVersionEditorDisplayName: provenance.forkCreatedByDisplayName,
      modifiedAtUtc: provenance.forkCreatedAtUtc,
    );
  }

  static bool _matchesImmediateSource(
    Course source,
    CourseForkProvenance provenance,
  ) {
    final sourceVersion = source.originType.isOfficial
        ? source.officialCourseVersion
        : source.courseVersion;
    return provenance.sourceCourseId == source.courseId &&
        provenance.sourceCourseTitle == source.title &&
        provenance.sourceCourseVersion == sourceVersion &&
        provenance.sourceOriginType == source.originType &&
        provenance.sourcePublisherId == source.publisherId &&
        provenance.sourcePublisherName == source.publisherName &&
        provenance.sourceOfficialChecksum == source.officialChecksum &&
        jsonEncode(
              provenance.sourceAuthors
                  .map((author) => author.toJson())
                  .toList(),
            ) ==
            jsonEncode(
              source.authors.map((author) => author.toJson()).toList(),
            );
  }

  Course _copyCourse(
    Course source, {
    required String title,
    CourseForkProvenance? provenance,
    required CourseProvenanceIdentity originalCourseCreator,
    required String originalCreatedAtUtc,
    required CourseMaintainer maintainer,
    required String lastVersionEditorProfileId,
    required String lastVersionEditorDisplayName,
    required String modifiedAtUtc,
  }) {
    final newCourseId = Course.newCourseId();
    final remap = <String, String>{source.courseId: newCourseId};
    final iconRemap = <String, String>{};
    for (final asset in source.lessonIconAssets) {
      iconRemap[asset.assetId] = _ids.next('lesson_icon');
    }
    for (final clip in source.audioLibrary) {
      remap[clip.id] = _ids.next('audio');
    }
    for (final lesson in source.lessons) {
      remap[lesson.lessonId] = _ids.next('lesson');
      remap[lesson.duel.id] = _ids.next('duel');
      _allocateGuidebook(lesson.guidebook, remap);
      for (final round in lesson.rounds) {
        remap[round.id] = _ids.next('round');
        for (final content in round.content) {
          _allocateContent(content, remap);
        }
      }
    }
    return Course(
      courseId: newCourseId,
      originalCourseCreator: originalCourseCreator,
      maintainer: maintainer,
      originalCreatedAtUtc: originalCreatedAtUtc,
      lastVersionEditorProfileId: lastVersionEditorProfileId,
      lastVersionEditorDisplayName: lastVersionEditorDisplayName,
      modifiedAtUtc: modifiedAtUtc,
      publicationState: PublicationState.draft,
      lessonNumberingMode: source.lessonNumberingMode,
      customLessonLabel: source.customLessonLabel,
      roundNumberingMode: source.roundNumberingMode,
      customRoundLabel: source.customRoundLabel,
      defaultTimedLimitsSeconds: source.defaultTimedLimitsSeconds,
      pictureAnswers: source.pictureAnswers,
      defaultLessonIconStyle: source.defaultLessonIconStyle,
      createDuels: source.createDuels,
      useGuidebook: source.useGuidebook,
      allowPageSharing: source.allowPageSharing,
      wordLookup: source.wordLookup,
      sectionNames: source.sectionNames,
      learningLanguage: source.learningLanguage,
      interfaceLanguage: source.interfaceLanguage,
      sourceLanguage: source.sourceLanguage,
      targetLanguage: source.targetLanguage,
      title: title,
      ttsLanguage: source.ttsLanguage,
      audioMode: source.audioMode,
      authors: [
        for (final author in source.authors)
          CourseAuthor(name: author.name, roles: [...author.roles]),
      ],
      license: source.license,
      rightsHolders: [
        for (final holder in source.rightsHolders)
          CourseRightsHolder(type: holder.type, name: holder.name),
      ],
      // The fork carries the same media, so the credit for it must travel too.
      mediaAttributions: [...source.mediaAttributions],
      derivativeWorksPolicy: source.derivativeWorksPolicy,
      forkProvenance: provenance,
      minimumAppBuild: source.minimumAppBuild,
      publisherContact: source.publisherContact,
      estimatedStudyHours: source.estimatedStudyHours,
      minimumAge: source.minimumAge,
      keywords: [...source.keywords],
      coverImage: source.coverImage,
      imageLibrary: source.imageLibrary,
      storyNarrator: source.storyNarrator,
      storyCharacters: source.storyCharacters,
      languageVariant: source.languageVariant,
      startLevel: source.startLevel,
      targetLevel: source.targetLevel,
      courseVersion: '',
      courseDescription: source.courseDescription,
      sourceLanguageTag: source.sourceLanguageTag,
      targetLanguageTag: source.targetLanguageTag,
      targetLanguageNameForLearners: source.targetLanguageNameForLearners,
      textDirection: source.textDirection,
      flagCode: source.flagCode,
      flagImageBase64: source.flagImageBase64,
      worldFlagId: source.worldFlagId,
      // Fork and Copy as New Course start non-private (Build 259 Revision 8,
      // owner decision): the flag is shown as Private course.
      temporarySample: false,
      buyACoffeeUrl: source.buyACoffeeUrl,
      lessonIconAssets: [
        for (final asset in source.lessonIconAssets)
          CourseLessonIconAsset(
            assetId: iconRemap[asset.assetId]!,
            base64Png: asset.base64Png,
          ),
      ],
      audioLibrary: [
        for (final clip in source.audioLibrary)
          CourseAudioClip(
            id: remap[clip.id]!,
            text: clip.text,
            filePath: clip.filePath,
          ),
      ],
      lessons: [
        for (final lesson in source.lessons)
          _copyLesson(lesson, remap, iconRemap: iconRemap),
      ],
    );
  }

  Exercise duplicateExercise(Exercise source) {
    final remap = <String, String>{source.id: _ids.next('exercise')};
    _allocateExerciseItems(source, remap);
    return _copyExercise(source, remap);
  }

  /// Duplicates the canonical wrapper as well as its runnable content.
  LearningContent duplicateContent(LearningContent source) {
    final remap = <String, String>{};
    _allocateContent(source, remap);
    return _copyContent(source, remap);
  }

  LearningRound duplicateRound(LearningRound source) {
    final remap = <String, String>{source.id: _ids.next('round')};
    for (final content in source.content) {
      _allocateContent(content, remap);
    }
    return _copyRound(source, remap);
  }

  Lesson duplicateLesson(
    Lesson source, {
    bool preservePublicationState = false,
  }) {
    final remap = <String, String>{
      source.lessonId: _ids.next('lesson'),
      source.duel.id: _ids.next('duel'),
    };
    _allocateGuidebook(source.guidebook, remap);
    for (final round in source.rounds) {
      remap.putIfAbsent(round.id, () => _ids.next('round'));
      for (final content in round.content) {
        _allocateContent(content, remap);
      }
    }
    return _copyLesson(
      source,
      remap,
      preservePublicationState: preservePublicationState,
    );
  }

  Lesson _copyLesson(
    Lesson source,
    Map<String, String> remap, {
    Map<String, String> iconRemap = const {},
    bool preservePublicationState = false,
  }) {
    final managedIconId = source.themeIconAsset == null
        ? null
        : CourseLessonIconAsset.assetIdFromReference(source.themeIconAsset!);
    return Lesson(
      lessonId: remap[source.lessonId]!,
      publicationState: preservePublicationState
          ? source.publicationState
          : PublicationState.draft,
      provisionalDraft: preservePublicationState
          ? source.provisionalDraft
          : false,
      updatedAt: source.updatedAt,
      title: source.title,
      rounds: [
        for (final round in source.rounds)
          _copyRound(
            round,
            remap,
            preservePublicationState: preservePublicationState,
          ),
      ],
      section: source.section,
      sectionName: source.sectionName,
      themeIconAsset: managedIconId == null
          ? source.themeIconAsset
          : CourseLessonIconAsset(
              assetId: iconRemap[managedIconId] ?? managedIconId,
              base64Png: '',
            ).reference,
      guidebook: Guidebook(
        publicationState: preservePublicationState
            ? source.guidebook.publicationState
            : PublicationState.draft,
        modules: [
          for (final module in source.guidebook.modules)
            _copyModule(module, remap),
        ],
      ),
      duel: Duel(id: remap[source.duel.id]!, title: source.duel.title),
    );
  }

  /// Build 266: a copied GuideBook's modules and entries get fresh IDs; the
  /// Lesson's Rounds follow them (focus, supporting, `sourceRefs`).
  void _allocateGuidebook(Guidebook guidebook, Map<String, String> remap) {
    for (final module in guidebook.modules) {
      remap.putIfAbsent(module.id, () => _ids.next('module'));
      for (final entry in module.entries) {
        remap.putIfAbsent(entry.id, () => _ids.next('entry'));
      }
    }
  }

  GuidebookModule _copyModule(
    GuidebookModule source,
    Map<String, String> remap,
  ) {
    GuidebookEntry entry(GuidebookEntry value) =>
        value.copyWith(id: remap[value.id] ?? value.id);
    return source.copyWith(
      id: remap[source.id] ?? source.id,
      sentences: [for (final value in source.sentences) entry(value)],
      words: [for (final value in source.words) entry(value)],
    );
  }

  void _allocateContent(LearningContent content, Map<String, String> remap) {
    remap.putIfAbsent(content.id, () => _ids.next('content'));
    final exercise = content.exercise;
    if (exercise != null) {
      remap.putIfAbsent(
        exercise.id,
        () => exercise.id == content.id
            ? remap[content.id]!
            : _ids.next('exercise'),
      );
      _allocateExerciseItems(exercise, remap);
    }
  }

  void _allocateExerciseItems(Exercise exercise, Map<String, String> remap) {
    for (final item in exercise.items) {
      remap.putIfAbsent(item.id, () => _ids.next('item'));
    }
  }

  LearningRound _copyRound(
    LearningRound source,
    Map<String, String> remap, {
    bool preservePublicationState = false,
  }) => LearningRound(
    id: remap[source.id]!,
    publicationState: preservePublicationState
        ? source.publicationState
        : PublicationState.draft,
    updatedAt: source.updatedAt,
    title: source.title,
    visualType: source.visualType,
    roundType: source.roundType,
    testFixedOrder: source.testFixedOrder,
    testPassingPercent: source.testPassingPercent,
    timedLimitsSeconds: source.timedLimitsSeconds,
    content: [
      for (final content in source.content)
        _copyContent(
          content,
          remap,
          preservePublicationState: preservePublicationState,
        ),
    ],
    // A copied Story keeps its flow over the copied content's fresh IDs.
    flow: RoundFlowAuthoring.remapped(source.flow, remap),
    // A Round copied with its Lesson follows the copied modules; a Round
    // duplicated in its own Lesson keeps its links.
    focusModuleId: source.focusModuleId == null
        ? null
        : remap[source.focusModuleId] ?? source.focusModuleId,
    supportingModuleIds: [
      for (final id in source.supportingModuleIds) remap[id] ?? id,
    ],
  );

  LearningContent _copyContent(
    LearningContent source,
    Map<String, String> remap, {
    bool preservePublicationState = false,
  }) => LearningContent(
    id: remap[source.id]!,
    publicationState: preservePublicationState
        ? source.publicationState
        : PublicationState.draft,
    kind: source.kind,
    required: source.required,
    editorTemplate: source.editorTemplate,
    role: source.role,
    exercise: source.exercise == null
        ? null
        : _copyExercise(
            source.exercise!,
            remap,
            preservePublicationState: preservePublicationState,
          ),
    text: source.text,
    sourceRefs: [
      for (final reference in source.sourceRefs) remap[reference] ?? reference,
    ],
  );

  Exercise _copyExercise(
    Exercise source,
    Map<String, String> remap, {
    bool preservePublicationState = false,
  }) {
    String mapped(String id) => remap[id] ?? id;
    final evaluation = source.canonicalEvaluation;
    // Course Model v12: items get fresh IDs and every evaluation reference
    // follows them; targets are exercise-local and keep their IDs.
    return Exercise.canonical(
      id: mapped(source.id),
      publicationState: preservePublicationState
          ? source.publicationState
          : PublicationState.draft,
      updatedAt: source.updatedAt,
      primitive: source.primitive,
      options: source.options,
      promptElements: [
        for (final element in source.promptElements) _copyPrompt(element),
      ],
      items: [
        for (final item in source.items)
          item.copyWith(
            id: mapped(item.id),
            content: [for (final element in item.content) _copyPrompt(element)],
          ),
      ],
      targets: source.targets,
      layout: source.layout,
      canonicalEvaluation: evaluation.copyWith(
        correctItemIds: evaluation.correctItemIds.map(mapped).toList(),
        answers: [...evaluation.answers],
        literalAnswers: [...evaluation.literalAnswers],
        targetAnswers: [
          for (final answers in evaluation.targetAnswers)
            TargetAnswers(
              targetId: answers.targetId,
              answers: [...answers.answers],
              literalAnswers: [...answers.literalAnswers],
            ),
        ],
        assignments: [
          for (final assignment in evaluation.assignments)
            TargetAssignment(
              targetId: assignment.targetId,
              itemIds: assignment.itemIds.map(mapped).toList(),
            ),
        ],
        correctOrders: [
          for (final answer in evaluation.correctOrders)
            OrderedAnswer(
              text: answer.text,
              itemIds: answer.itemIds.map(mapped).toList(),
            ),
        ],
        relations: [
          for (final pair in evaluation.relations)
            [for (final id in pair) mapped(id)],
        ],
        acceptedTargets: [
          for (final accepted in evaluation.acceptedTargets)
            AcceptedTarget(
              itemId: mapped(accepted.itemId),
              targetIds: accepted.targetIds,
            ),
        ],
      ),
      feedback: source.feedback,
      hint: source.hint,
      authoringMetadata: source.authoringMetadata,
    );
  }

  /// A fresh element with every attribute, including the Course Model v12
  /// language, playback and required attributes.
  PromptElement _copyPrompt(PromptElement source) => source.copyWith();
}
