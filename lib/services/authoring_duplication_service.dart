import 'dart:convert';

import '../models/course_models.dart';

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
  AuthoringDuplicationService({AuthoringIdGenerator? ids})
    : _ids = ids ?? TimestampAuthoringIdGenerator();

  final AuthoringIdGenerator _ids;

  Course duplicateCourse(Course source, {required String title}) {
    if (source.originType.isOfficial) {
      throw StateError('Official courses require a licensed custom fork.');
    }
    return _copyCourse(source, title: title, provenance: source.forkProvenance);
  }

  Course forkOfficialCourse(
    Course source, {
    required CourseForkProvenance provenance,
  }) {
    if (!source.originType.isOfficial ||
        source.derivativeWorksPolicy != DerivativeWorksPolicy.allowed ||
        provenance.originalCourseId != source.courseId ||
        provenance.originalOfficialChecksum != source.officialChecksum) {
      throw StateError(
        'An official custom fork requires explicit derivative permission and matching provenance.',
      );
    }
    final fork = _copyCourse(
      source,
      title: '${source.title} custom copy',
      provenance: provenance,
    );
    // Detach any nested JSON metadata as well as the owned authoring objects.
    return Course.fromJson(
      jsonDecode(jsonEncode(fork.toJson())) as Map<String, dynamic>,
    );
  }

  Course _copyCourse(
    Course source, {
    required String title,
    CourseForkProvenance? provenance,
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
      for (final content in lesson.guidebook.content) {
        _allocateContent(content, remap);
      }
      for (final round in lesson.rounds) {
        remap[round.id] = _ids.next('round');
        for (final content in round.content) {
          _allocateContent(content, remap);
        }
      }
    }
    return Course(
      courseId: newCourseId,
      publicationState: PublicationState.draft,
      lessonNumberingMode: source.lessonNumberingMode,
      customLessonLabel: source.customLessonLabel,
      defaultLessonIconStyle: source.defaultLessonIconStyle,
      parentCourseId: source.courseId,
      derivedFromVersion: source.originType.isOfficial
          ? source.officialCourseVersion
          : source.courseVersion.isNotEmpty
          ? source.courseVersion
          : source.version,
      learningLanguage: source.learningLanguage,
      interfaceLanguage: source.interfaceLanguage,
      sourceLanguage: source.sourceLanguage,
      targetLanguage: source.targetLanguage,
      title: title,
      ttsLanguage: source.ttsLanguage,
      version: source.version,
      contentRevision: source.contentRevision,
      updateSummary: source.updateSummary,
      audioMode: source.audioMode,
      author: source.author,
      authors: [
        for (final author in source.authors)
          CourseAuthor(name: author.name, roles: [...author.roles]),
      ],
      license: source.license,
      derivativeWorksPolicy: source.derivativeWorksPolicy,
      forkProvenance: provenance,
      languageVariant: source.languageVariant,
      startLevel: source.startLevel,
      targetLevel: source.targetLevel,
      courseVersion: '',
      lastUpdated: source.lastUpdated,
      courseDescription: source.courseDescription,
      sourceLanguageTag: source.sourceLanguageTag,
      targetLanguageTag: source.targetLanguageTag,
      textDirection: source.textDirection,
      flagCode: source.flagCode,
      flagImageBase64: source.flagImageBase64,
      temporarySample: source.temporarySample,
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

  LearningRound duplicateRound(LearningRound source) {
    final remap = <String, String>{source.id: _ids.next('round')};
    for (final content in source.content) {
      _allocateContent(content, remap);
    }
    return _copyRound(source, remap);
  }

  Lesson duplicateLesson(Lesson source) {
    final remap = <String, String>{
      source.lessonId: _ids.next('lesson'),
      source.duel.id: _ids.next('duel'),
    };
    for (final content in source.guidebook.content) {
      _allocateContent(content, remap);
    }
    for (final round in source.rounds) {
      remap.putIfAbsent(round.id, () => _ids.next('round'));
      for (final content in round.content) {
        _allocateContent(content, remap);
      }
    }
    return _copyLesson(source, remap);
  }

  Lesson _copyLesson(
    Lesson source,
    Map<String, String> remap, {
    Map<String, String> iconRemap = const {},
  }) {
    final managedIconId = source.themeIconAsset == null
        ? null
        : CourseLessonIconAsset.assetIdFromReference(source.themeIconAsset!);
    return Lesson(
      lessonId: remap[source.lessonId]!,
      publicationState: PublicationState.draft,
      updatedAt: source.updatedAt,
      title: source.title,
      rounds: [for (final round in source.rounds) _copyRound(round, remap)],
      section: source.section,
      sectionName: source.sectionName,
      themeIconAsset: managedIconId == null
          ? source.themeIconAsset
          : CourseLessonIconAsset(
              assetId: iconRemap[managedIconId] ?? managedIconId,
              base64Png: '',
            ).reference,
      guidebook: Guidebook(
        content: [
          for (final content in source.guidebook.content)
            _copyContent(content, remap),
        ],
      ),
      duel: Duel(id: remap[source.duel.id]!, title: source.duel.title),
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
    for (final item in exercise.interaction.items) {
      remap.putIfAbsent(item.id, () => _ids.next('item'));
    }
  }

  LearningRound _copyRound(LearningRound source, Map<String, String> remap) =>
      LearningRound(
        id: remap[source.id]!,
        publicationState: PublicationState.draft,
        updatedAt: source.updatedAt,
        title: source.title,
        visualType: source.visualType,
        content: [
          for (final content in source.content) _copyContent(content, remap),
        ],
      );

  LearningContent _copyContent(
    LearningContent source,
    Map<String, String> remap,
  ) => LearningContent(
    id: remap[source.id]!,
    publicationState: PublicationState.draft,
    kind: source.kind,
    required: source.required,
    editorTemplate: source.editorTemplate,
    role: source.role,
    exercise: source.exercise == null
        ? null
        : _copyExercise(source.exercise!, remap),
    presentation: source.presentation == null
        ? null
        : Presentation(
            content: [
              for (final element in source.presentation!.content)
                _copyPrompt(element),
            ],
            actions: [...source.presentation!.actions],
          ),
    text: source.text,
    sourceRefs: [
      for (final reference in source.sourceRefs) remap[reference] ?? reference,
    ],
  );

  Exercise _copyExercise(Exercise source, Map<String, String> remap) {
    String mapped(String id) => remap[id] ?? id;
    return Exercise.v2(
      id: mapped(source.id),
      publicationState: PublicationState.draft,
      updatedAt: source.updatedAt,
      editorTemplate: source.editorTemplate,
      promptElements: [
        for (final element in source.promptElements) _copyPrompt(element),
      ],
      interaction: ExerciseInteraction(
        kind: source.interaction.kind,
        inputType: source.interaction.inputType,
        minSelections: source.interaction.minSelections,
        maxSelections: source.interaction.maxSelections,
        items: [
          for (final item in source.interaction.items)
            ExerciseItem(
              id: mapped(item.id),
              content: [
                for (final element in item.content) _copyPrompt(element),
              ],
            ),
        ],
      ),
      evaluation: ExerciseEvaluation(
        kind: source.evaluation.kind,
        correctItemIds: source.evaluation.correctItemIds.map(mapped).toList(),
        accepted: [...source.evaluation.accepted],
        correctOrders: [
          for (final answer in source.evaluation.correctOrders)
            OrderedAnswer(
              text: answer.text,
              itemIds: answer.itemIds.map(mapped).toList(),
            ),
        ],
        pairs: [
          for (final pair in source.evaluation.pairs)
            [for (final id in pair) mapped(id)],
        ],
        normalization: {...source.evaluation.normalization},
      ),
      hint: source.hint,
      feedback: {...source.feedback},
      missingWords: [...source.missingWords],
    );
  }

  PromptElement _copyPrompt(PromptElement source) => PromptElement(
    role: source.role,
    type: source.type,
    text: source.text,
    asset: source.asset,
    speaker: source.speaker,
  );
}
