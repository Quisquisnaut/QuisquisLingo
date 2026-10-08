import 'dart:convert';

import '../models/course_flag_selection.dart';
import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'authoring_duplication_service.dart';
import 'duel_eligibility_service.dart';
import 'guidebook_module_sample.dart';
import 'guidebook_round_generator.dart';
import 'guidebook_round_links.dart';
import 'lesson_icon_catalog.dart';

/// The Course Wizard (Build 267, `docs/267_COURSE_WIZARD_PLAN.md`): it guides
/// an author through creating a whole Course, step by step, and can stop at
/// any step and continue later. QQL writes no content: the Wizard arranges
/// what the author writes.
///
/// Everything here is pure Dart: the steps, the record of a paused Wizard,
/// each step's values and how they change a Course, the built-in example
/// and what the screen returns. Every save is an ordinary confirmed Course
/// save (owner decision of 6 October 2026); nothing of the Wizard is stored
/// in the Course file.

/// The Wizard's steps, in order. Revision 2 has the first seven; Check and
/// publish follows in Revision 3.
enum CourseWizardStep {
  basics('Basics'),
  about('About the Course'),
  credits('Credits and rights'),
  options('Course options'),
  lessons('Lessons'),
  guidebook('GuideBook'),
  rounds('Rounds');

  const CourseWizardStep(this.title);

  final String title;

  /// 1 for Basics.
  int get number => index + 1;

  CourseWizardStep? get next =>
      index + 1 < values.length ? values[index + 1] : null;

  CourseWizardStep? get previous => index == 0 ? null : values[index - 1];

  bool get isLast => next == null;

  /// The step numbered [number], or the last step for a larger number (a
  /// Wizard paused by a later build).
  static CourseWizardStep? byNumber(int number) {
    if (number < 1) return null;
    return number > values.length ? values.last : values[number - 1];
  }
}

/// Where a paused Wizard stands. Stored on the device, never in the Course
/// file (`CourseWizardMemory`).
class CourseWizardPause {
  const CourseWizardPause({
    required this.step,
    required this.savedAtUtc,
    this.lessonId,
  });

  final CourseWizardStep step;

  /// The Lesson of the GuideBook and Rounds steps.
  final String? lessonId;
  final DateTime savedAtUtc;

  Map<String, Object?> toJson() => {
    'step': step.number,
    if (lessonId != null) 'lessonId': lessonId,
    'savedAtUtc': savedAtUtc.toUtc().toIso8601String(),
  };

  /// The stored record, or null when it is not one this build can use.
  static CourseWizardPause? fromJson(Object? json) {
    if (json is! Map) return null;
    final number = json['step'];
    final saved = json['savedAtUtc'];
    final lessonId = json['lessonId'];
    if (number is! int || saved is! String) return null;
    if (lessonId != null && lessonId is! String) return null;
    final step = CourseWizardStep.byNumber(number);
    final savedAt = DateTime.tryParse(saved);
    if (step == null || savedAt == null) return null;
    return CourseWizardPause(
      step: step,
      savedAtUtc: savedAt.toUtc(),
      lessonId: lessonId as String?,
    );
  }

  static CourseWizardPause? decode(String raw) {
    try {
      return fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// "Course Wizard paused: step 3 of 6 (Credits and rights)".
  String get description => describe(null);

  /// [description], naming the Lesson of the GuideBook or Rounds step when
  /// [course] still has it: "… step 6 of 7 (GuideBook, Lesson 2)".
  String describe(Course? course) {
    final index = lessonId == null || course == null
        ? -1
        : course.lessons.indexWhere((lesson) => lesson.lessonId == lessonId);
    final where = index < 0 ? step.title : '${step.title}, Lesson ${index + 1}';
    return 'Course Wizard paused: step ${step.number} of '
        '${CourseWizardStep.values.length} ($where)';
  }
}

/// What the Wizard screen hands back to the screen that opened it.
sealed class CourseWizardOutcome {
  const CourseWizardOutcome();
}

/// Create it myself: the New Course form, with the first screen's values.
final class CourseWizardCreateManually extends CourseWizardOutcome {
  const CourseWizardCreateManually(this.basics);
  final CourseWizardBasics basics;
}

/// Finish or Continue by hand: open the Course Editor on the stored Course.
final class CourseWizardOpenEditor extends CourseWizardOutcome {
  const CourseWizardOpenEditor(this.course);
  final Course course;
}

/// Save for now, or the Wizard closed: the Course is stored and the Wizard
/// can be continued from Course Studio.
final class CourseWizardPaused extends CourseWizardOutcome {
  const CourseWizardPaused(this.course);
  final Course course;
}

/// Step 1: what every Course needs.
class CourseWizardBasics {
  const CourseWizardBasics({
    this.title = '',
    this.sourceLanguage = '',
    this.sourceLanguageTag = '',
    this.targetLanguage = '',
    this.targetLanguageTag = '',
    this.variant = '',
  });

  final String title;
  final String sourceLanguage;
  final String sourceLanguageTag;
  final String targetLanguage;
  final String targetLanguageTag;
  final String variant;

  bool get isEmpty =>
      title.trim().isEmpty &&
      sourceLanguage.trim().isEmpty &&
      targetLanguage.trim().isEmpty &&
      variant.trim().isEmpty;

  /// After the Course exists only the title and the variant change: a
  /// Course's languages never change (Build 260 Revision 0).
  Course applyTo(Course course) => Course.fromJson({
    ...course.toJson(),
    'title': title.trim(),
    'languageVariant': variant.trim(),
  });
}

/// Step 2: what learners read about the Course.
class CourseWizardAbout {
  const CourseWizardAbout({
    this.description = '',
    this.startLevel = '',
    this.targetLevel = '',
    this.coverImage = '',
    this.coverCredit,
    this.studyHours,
    this.minimumAge,
    this.keywords = const [],
    this.flag = const CourseFlagSelection.automatic(),
  });

  factory CourseWizardAbout.of(Course course) => CourseWizardAbout(
    description: course.courseDescription,
    startLevel: course.startLevel,
    targetLevel: course.targetLevel,
    coverImage: course.coverImage,
    studyHours: course.estimatedStudyHours,
    minimumAge: course.minimumAge,
    keywords: course.keywords,
    flag: CourseFlagSelection.fromCourse(course),
  );

  final String description;
  final String startLevel;
  final String targetLevel;

  /// The cover's media reference, or '' for none.
  final String coverImage;

  /// The credit QQL knows for a newly chosen cover, added to Media credits.
  final CourseMediaAttribution? coverCredit;
  final int? studyHours;
  final int? minimumAge;
  final List<String> keywords;
  final CourseFlagSelection flag;

  bool get isEmpty =>
      description.trim().isEmpty &&
      startLevel.trim().isEmpty &&
      targetLevel.trim().isEmpty &&
      coverImage.isEmpty &&
      studyHours == null &&
      minimumAge == null &&
      keywords.isEmpty &&
      flag == const CourseFlagSelection.automatic();

  /// Why the typed study hours cannot be stored, or null.
  static String? studyHoursProblem(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    final hours = int.tryParse(value);
    if (hours == null ||
        '$hours' != value ||
        hours < 1 ||
        hours > Course.maxEstimatedStudyHours) {
      return 'A whole number from 1 to ${Course.maxEstimatedStudyHours}.';
    }
    return null;
  }

  /// The keywords typed with commas, trimmed and without repeats.
  static List<String> keywordsFrom(String text) =>
      Course.normalizeKeywords(text.split(','));

  /// Why the typed keywords cannot be stored, or null.
  static String? keywordsProblem(String text) {
    final keywords = keywordsFrom(text);
    if (keywords.length > Course.maxKeywords) {
      return 'At most ${Course.maxKeywords} keywords.';
    }
    for (final keyword in keywords) {
      if (keyword.length > Course.maxKeywordLength) {
        return '“$keyword” is longer than ${Course.maxKeywordLength} characters.';
      }
    }
    return null;
  }

  Course applyTo(Course course) {
    final json = {...course.toJson()}
      ..remove('estimatedStudyHours')
      ..remove('minimumAge')
      ..remove('keywords')
      ..remove('coverImage');
    final credits = [...course.mediaAttributions];
    final credit = coverCredit;
    if (coverImage.isNotEmpty &&
        credit != null &&
        !credits.any(
          (known) => jsonEncode(known.toJson()) == jsonEncode(credit.toJson()),
        )) {
      credits.add(credit);
    }
    return Course.fromJson(
      flag.applyToJson({
        ...json,
        'courseDescription': description.trim(),
        'startLevel': startLevel.trim(),
        'targetLevel': targetLevel.trim(),
        if (coverImage.isNotEmpty) 'coverImage': coverImage,
        'estimatedStudyHours': ?studyHours,
        'minimumAge': ?minimumAge,
        if (keywords.isNotEmpty) 'keywords': keywords,
        'mediaAttributions': [for (final known in credits) known.toJson()],
      }),
    );
  }
}

/// Step 3: who made the Course and what others may do with it.
class CourseWizardCredits {
  const CourseWizardCredits({
    this.authors = const [],
    this.license = defaultLicense,
    this.derivativePolicy = DerivativeWorksPolicy.forbidden,
    this.rightsHolders = const [],
    this.buyACoffeeUrl = '',
    this.publisherContact,
  });

  factory CourseWizardCredits.of(Course course) => CourseWizardCredits(
    authors: course.authors,
    license: course.license,
    derivativePolicy: course.derivativeWorksPolicy,
    rightsHolders: course.rightsHolders,
    buyACoffeeUrl: course.buyACoffeeUrl,
    publisherContact: course.publisherContact,
  );

  /// New Course's default until the author chooses another.
  static const defaultLicense = 'All rights reserved';

  final List<CourseAuthor> authors;
  final String license;
  final DerivativeWorksPolicy derivativePolicy;
  final List<CourseRightsHolder> rightsHolders;
  final String buyACoffeeUrl;
  final CoursePublisherContact? publisherContact;

  bool get isEmpty =>
      authors.isEmpty &&
      license == defaultLicense &&
      derivativePolicy == DerivativeWorksPolicy.forbidden &&
      rightsHolders.isEmpty &&
      buyACoffeeUrl.trim().isEmpty &&
      publisherContact == null;

  Course applyTo(Course course) {
    final json = {...course.toJson()}..remove('publisherContact');
    return Course.fromJson({
      ...json,
      'authors': [for (final author in authors) author.toJson()],
      'license': license,
      'derivativeWorksPolicy': derivativePolicy.name,
      'rightsHolders': [for (final holder in rightsHolders) holder.toJson()],
      'buyACoffeeUrl': buyACoffeeUrl.trim(),
      if (publisherContact != null)
        'publisherContact': publisherContact!.toJson(),
    });
  }
}

/// Step 4: the Lesson Options, except Use GuideBook, which the Wizard keeps
/// on (owner decision of 6 October 2026).
class CourseWizardOptions {
  const CourseWizardOptions({
    this.lessonNumbering = LessonNumberingMode.lesson,
    this.customLessonLabel = '',
    this.roundNumbering = RoundNumberingMode.off,
    this.customRoundLabel = '',
    this.wordLookup = true,
    this.createDuels = true,
    this.pictureAnswers = PictureAnswerStyle.standard,
    this.defaultTimedLimits = const [],
  });

  factory CourseWizardOptions.of(Course course) => CourseWizardOptions(
    lessonNumbering: course.lessonNumberingMode,
    customLessonLabel: course.customLessonLabel,
    roundNumbering: course.roundNumberingMode,
    customRoundLabel: course.customRoundLabel,
    wordLookup: course.wordLookup,
    createDuels: course.createDuels,
    pictureAnswers: course.pictureAnswers,
    defaultTimedLimits: course.defaultTimedLimitsSeconds,
  );

  /// What a new Course has: the options Clear all returns to.
  static const defaults = CourseWizardOptions();

  final LessonNumberingMode lessonNumbering;
  final String customLessonLabel;
  final RoundNumberingMode roundNumbering;
  final String customRoundLabel;
  final bool wordLookup;
  final bool createDuels;
  final PictureAnswerStyle pictureAnswers;

  /// In seconds, in the order new Timed Rounds take them.
  final List<int> defaultTimedLimits;

  bool get isDefault => _same(this, defaults);

  static bool _same(CourseWizardOptions a, CourseWizardOptions b) =>
      a.lessonNumbering == b.lessonNumbering &&
      a.customLessonLabel == b.customLessonLabel &&
      a.roundNumbering == b.roundNumbering &&
      a.customRoundLabel == b.customRoundLabel &&
      a.wordLookup == b.wordLookup &&
      a.createDuels == b.createDuels &&
      a.pictureAnswers == b.pictureAnswers &&
      a.defaultTimedLimits.join(',') == b.defaultTimedLimits.join(',');

  CourseWizardOptions copyWith({
    LessonNumberingMode? lessonNumbering,
    String? customLessonLabel,
    RoundNumberingMode? roundNumbering,
    String? customRoundLabel,
    bool? wordLookup,
    bool? createDuels,
    PictureAnswerStyle? pictureAnswers,
    List<int>? defaultTimedLimits,
  }) => CourseWizardOptions(
    lessonNumbering: lessonNumbering ?? this.lessonNumbering,
    customLessonLabel: customLessonLabel ?? this.customLessonLabel,
    roundNumbering: roundNumbering ?? this.roundNumbering,
    customRoundLabel: customRoundLabel ?? this.customRoundLabel,
    wordLookup: wordLookup ?? this.wordLookup,
    createDuels: createDuels ?? this.createDuels,
    pictureAnswers: pictureAnswers ?? this.pictureAnswers,
    defaultTimedLimits: defaultTimedLimits ?? this.defaultTimedLimits,
  );

  /// Why these options cannot be stored, or null.
  String? get problem {
    if (lessonNumbering == LessonNumberingMode.other &&
        customLessonLabel.trim().isEmpty) {
      return 'Type the custom Lesson label, or choose another numbering.';
    }
    if (roundNumbering == RoundNumberingMode.customAndNumber &&
        customRoundLabel.trim().isEmpty) {
      return 'Type the custom Round label, or choose another numbering.';
    }
    return null;
  }

  Course applyTo(Course course) {
    final json = {...course.toJson()}
      ..remove('pictureAnswers')
      ..remove('defaultTimedLimitsSeconds');
    return Course.fromJson({
      ...json,
      'lessonNumberingMode': lessonNumbering.name,
      'customLessonLabel': lessonNumbering == LessonNumberingMode.other
          ? customLessonLabel.trim()
          : '',
      'roundNumberingMode': roundNumbering.name,
      'customRoundLabel': roundNumbering == RoundNumberingMode.customAndNumber
          ? customRoundLabel.trim()
          : '',
      // The Wizard builds the Rounds from the GuideBook, so it stays on.
      'useGuidebook': true,
      'wordLookup': wordLookup,
      'createDuels': createDuels,
      if (!pictureAnswers.isStandard) 'pictureAnswers': pictureAnswers.toJson(),
      if (defaultTimedLimits.isNotEmpty)
        'defaultTimedLimitsSeconds': defaultTimedLimits,
    });
  }
}

/// One Lesson of step 5: an existing Lesson keeps its ID and everything the
/// step does not show (GuideBook, Rounds, Duel).
class CourseWizardLessonDraft {
  const CourseWizardLessonDraft({
    this.lessonId,
    this.title = '',
    this.iconAsset,
    this.sectionName = '',
  });

  factory CourseWizardLessonDraft.of(Lesson lesson) => CourseWizardLessonDraft(
    lessonId: lesson.lessonId,
    title: lesson.title,
    iconAsset: lesson.themeIconAsset,
    sectionName: lesson.sectionName ?? '',
  );

  /// Null for a Lesson the Wizard has not created yet.
  final String? lessonId;
  final String title;

  /// A preinstalled Lesson icon, a QQL picture or a Course-owned icon; null
  /// shows the Lesson's number.
  final String? iconAsset;

  /// '' when the Lesson belongs to no section.
  final String sectionName;
}

/// The Lessons step, applied to a Course.
abstract final class CourseWizardLessons {
  static const maxTitleLength = 120;
  static const maxSectionNameLength = 80;

  static List<CourseWizardLessonDraft> of(Course course) => [
    for (final lesson in course.lessons) CourseWizardLessonDraft.of(lesson),
  ];

  /// Why [drafts] cannot be stored, or null. Every Lesson needs its title:
  /// it is the one thing that never waits (owner decision of 6 October
  /// 2026).
  static String? problem(List<CourseWizardLessonDraft> drafts) {
    for (final (index, draft) in drafts.indexed) {
      if (draft.title.trim().isEmpty) {
        return 'Lesson ${index + 1} needs a title.';
      }
    }
    return null;
  }

  /// [course] with the Lessons of [drafts], in their order. A Lesson the
  /// drafts leave out is removed with its GuideBook and Rounds; a new one is
  /// a Draft with an empty GuideBook and no Rounds, as New Lesson makes it.
  static Course applyTo(
    Course course,
    List<CourseWizardLessonDraft> drafts, {
    required DateTime now,
    AuthoringIdGenerator? ids,
  }) {
    final generator = ids ?? TimestampAuthoringIdGenerator();
    final existing = {
      for (final lesson in course.lessons) lesson.lessonId: lesson,
    };
    final lessons = <Lesson>[];
    for (final draft in drafts) {
      final title = draft.title.trim();
      final sectionName = draft.sectionName.trim();
      final icon = draft.iconAsset?.trim();
      final stored = draft.lessonId == null ? null : existing[draft.lessonId];
      if (stored == null) {
        lessons.add(
          Lesson(
            lessonId: generator.next('lesson'),
            publicationState: PublicationState.draft,
            provisionalDraft: true,
            updatedAt: now,
            title: title,
            rounds: const [],
            section: sectionName.isNotEmpty,
            sectionName: sectionName.isEmpty ? null : sectionName,
            themeIconAsset: icon == null || icon.isEmpty ? null : icon,
            guidebook: Guidebook.empty(),
          ),
        );
        continue;
      }
      final unchanged =
          stored.title == title &&
          (stored.sectionName ?? '') == sectionName &&
          stored.themeIconAsset == (icon == null || icon.isEmpty ? null : icon);
      if (unchanged) {
        lessons.add(stored);
        continue;
      }
      final json = {...stored.toJson()}
        ..remove('sectionName')
        ..remove('themeIconAsset');
      lessons.add(
        Lesson.fromJson({
          ...json,
          'title': title,
          'section': sectionName.isNotEmpty,
          if (sectionName.isNotEmpty) 'sectionName': sectionName,
          if (icon != null && icon.isNotEmpty) 'themeIconAsset': icon,
          'updatedAt': now.toUtc().toIso8601String(),
        }),
      );
    }
    return Course.fromJson({
      ...course.toJson(),
      'lessons': [for (final lesson in lessons) lesson.toJson()],
    });
  }

  /// What removing [lesson] takes with it, as in "its GuideBook and 6
  /// Rounds"; null when it holds nothing yet.
  static String? contentOf(Lesson lesson) {
    final parts = [
      if (lesson.guidebook.modules.isNotEmpty) 'GuideBook',
      if (lesson.rounds.isNotEmpty)
        '${lesson.rounds.length} Round${lesson.rounds.length == 1 ? '' : 's'}',
    ];
    return parts.isEmpty ? null : 'its ${parts.join(' and ')}';
  }

  /// The stored Lessons [drafts] leave out that hold content, for Clear all
  /// and Remove to name, as in "Removing Lesson 3 removes its GuideBook and
  /// 6 Rounds."
  static List<String> removedContent(
    Course course,
    List<CourseWizardLessonDraft> drafts,
  ) {
    final kept = {
      for (final draft in drafts)
        if (draft.lessonId != null) draft.lessonId,
    };
    return [
      for (final (index, lesson) in course.lessons.indexed)
        if (!kept.contains(lesson.lessonId) && contentOf(lesson) != null)
          'Removing Lesson ${index + 1} (${lesson.title}) removes '
              '${contentOf(lesson)}.',
    ];
  }
}

/// The GuideBook step, Lesson by Lesson (Build 267 Revision 1): the Lesson's
/// modules are written on Build 266's module page and approved with "This
/// Lesson's GuideBook is ready", which saves the GuideBook as Published.
abstract final class CourseWizardGuidebook {
  /// The Round Wizard's minimum, so the Rounds step can use the module.
  static const minimumWords = GuidebookRoundGenerator.minimumWords;

  /// A module the Round Wizard can use.
  static bool hasUsableModule(Lesson lesson) => lesson.guidebook.modules.any(
    (module) => module.words.length >= minimumWords,
  );

  /// Done: a usable module, and the GuideBook approved (Published).
  static bool isReady(Lesson lesson) =>
      hasUsableModule(lesson) && lesson.guidebook.publicationState.isPublished;

  /// Why Lesson [index] (zero-based) is not done yet, or null.
  static String? problem(Lesson lesson, int index) {
    if (!hasUsableModule(lesson)) {
      return 'Lesson ${index + 1} (${lesson.title}) needs a module with at '
          'least $minimumWords Words & Expressions.';
    }
    if (!lesson.guidebook.publicationState.isPublished) {
      return 'Lesson ${index + 1} (${lesson.title}): press “This Lesson\'s '
          'GuideBook is ready” when its GuideBook is ready.';
    }
    return null;
  }

  /// The first Lesson not done yet, with its problem; null when every
  /// Lesson is done.
  static ({int index, String problem})? firstProblem(Course course) {
    for (final (index, lesson) in course.lessons.indexed) {
      final problem = CourseWizardGuidebook.problem(lesson, index);
      if (problem != null) return (index: index, problem: problem);
    }
    return null;
  }

  /// [course] with the modules of Lesson [lessonId] replaced, the GuideBook
  /// in [state]: a GuideBook being written is a Draft, one approved is
  /// Published. Rounds lose their links to removed modules, as after Save
  /// Guidebook in the Course Editor.
  static Course withModules(
    Course course,
    String lessonId,
    List<GuidebookModule> modules, {
    required PublicationState state,
    required DateTime now,
  }) => Course.fromJson({
    ...course.toJson(),
    'lessons': [
      for (final lesson in course.lessons)
        if (lesson.lessonId != lessonId)
          lesson.toJson()
        else
          _withModules(lesson, modules, state, now).toJson(),
    ],
  });

  static Lesson _withModules(
    Lesson lesson,
    List<GuidebookModule> modules,
    PublicationState state,
    DateTime now,
  ) {
    final guidebook = lesson.guidebook.copyWith(
      publicationState: state,
      modules: modules,
    );
    final rounds = GuidebookRoundLinks.afterGuidebookSave(
      lesson.guidebook,
      guidebook,
      lesson.rounds,
    );
    return Lesson.fromJson({
      ...lesson.toJson(),
      'guidebook': guidebook.toJson(),
      'rounds': [for (final round in rounds) round.toJson()],
      'updatedAt': now.toUtc().toIso8601String(),
    });
  }

  /// What replacing the modules of [lesson] does to its Rounds, as in
  /// "Lesson 2 has 6 Rounds. Clearing its modules does not remove them, but
  /// they lose their focus module."; null when no Round focuses on them.
  static String? roundsNote(Lesson lesson, int index, String doing) {
    final ids = {for (final module in lesson.guidebook.modules) module.id};
    final focusing = lesson.rounds
        .where((round) => ids.contains(round.focusModuleId))
        .length;
    if (focusing == 0) return null;
    final count = lesson.rounds.length;
    return 'Lesson ${index + 1} has $count Round${count == 1 ? '' : 's'}. '
        '$doing its modules does not remove '
        '${count == 1 ? 'it' : 'them'}, but $focusing '
        '${focusing == 1 ? 'loses its' : 'lose their'} focus module.';
  }
}

/// The Rounds step, Lesson by Lesson (Build 267 Revision 2): the Round
/// Wizard makes each Lesson's Rounds from its GuideBook, plan first.
abstract final class CourseWizardRounds {
  /// Why Lesson [index] (zero-based) is not done yet, or null.
  static String? problem(Lesson lesson, int index) => lesson.rounds.isEmpty
      ? 'Lesson ${index + 1} (${lesson.title}) has no Rounds yet: make them '
            'with the Round Wizard.'
      : null;

  /// The first Lesson without Rounds, with its problem; null when every
  /// Lesson has Rounds.
  static ({int index, String problem})? firstProblem(Course course) {
    for (final (index, lesson) in course.lessons.indexed) {
      final problem = CourseWizardRounds.problem(lesson, index);
      if (problem != null) return (index: index, problem: problem);
    }
    return null;
  }

  /// [course] with [rounds] after the Rounds of Lesson [lessonId] (or in
  /// their place, with [replace]).
  static Course withRounds(
    Course course,
    String lessonId,
    List<LearningRound> rounds, {
    required DateTime now,
    bool replace = false,
  }) => Course.fromJson({
    ...course.toJson(),
    'lessons': [
      for (final lesson in course.lessons)
        if (lesson.lessonId != lessonId)
          lesson.toJson()
        else
          {
            ...lesson.toJson(),
            'rounds': [
              if (!replace)
                for (final round in lesson.rounds) round.toJson(),
              for (final round in rounds) round.toJson(),
            ],
            'updatedAt': now.toUtc().toIso8601String(),
          },
    ],
  });

  /// The Lesson's Duel questions, Drafts included, as the Duel counts them
  /// (`DuelEligibilityService`); the ones that need audio apart.
  static ({int questions, int audio}) duelCount(Lesson lesson) {
    final candidates = const DuelEligibilityService()
        .evaluate(lesson, includeDrafts: true)
        .candidates;
    final audio = candidates
        .where(
          (candidate) => ExerciseFeatures(candidate.exercise).requiresAudio,
        )
        .length;
    return (questions: candidates.length - audio, audio: audio);
  }
}

/// Fill with an example: one built-in Course, so filling every step gives a
/// coherent whole (an English → Italian Course for the bar).
abstract final class CourseWizardSample {
  static const basics = CourseWizardBasics(
    title: 'Italian at the bar',
    sourceLanguage: 'English',
    sourceLanguageTag: 'en',
    targetLanguage: 'Italian',
    targetLanguageTag: 'it',
    variant: 'Italian of Italy',
  );

  static const about = CourseWizardAbout(
    description:
        'Order a coffee and a pastry in an Italian bar, ask for the bill and '
        'find your way back to the station. Short Lessons with pictures, for '
        'a first trip to Italy.',
    startLevel: 'A1',
    targetLevel: 'A2',
    studyHours: 4,
    keywords: ['Italian', 'bar', 'food and drink', 'travel'],
  );

  /// The active profile is the author and the rights holder; the license
  /// lets others Fork the Course.
  static CourseWizardCredits credits(String authorName) => CourseWizardCredits(
    authors: [
      if (authorName.trim().isNotEmpty)
        CourseAuthor(name: authorName.trim(), roles: const ['Author']),
    ],
    license: 'CC BY 4.0',
    derivativePolicy: DerivativeWorksPolicy.allowed,
    rightsHolders: [
      if (authorName.trim().isNotEmpty)
        CourseRightsHolder(
          type: CourseRightsHolderType.person,
          name: authorName.trim(),
        ),
    ],
  );

  /// The recommended options: Lessons numbered, Word Lookup and Duels on,
  /// the standard picture answers.
  static const options = CourseWizardOptions(
    lessonNumbering: LessonNumberingMode.lesson,
    roundNumbering: RoundNumberingMode.off,
    wordLookup: true,
    createDuels: true,
  );

  /// The GuideBook step's example: Build 266's sample module, in Italian and
  /// English whatever the Course's languages, every ID fresh.
  static List<GuidebookModule> guidebook(AuthoringIdGenerator ids) => [
    GuidebookModuleSample.module(id: ids.next('module'), ids: ids),
  ];

  static final lessons = [
    CourseWizardLessonDraft(
      title: 'Coffee and pastries',
      iconAsset: LessonIconCatalog.byId('coffee').assetPath,
      sectionName: 'At the bar',
    ),
    CourseWizardLessonDraft(
      title: 'Paying the bill',
      iconAsset: LessonIconCatalog.byId('shopping').assetPath,
      sectionName: 'At the bar',
    ),
    CourseWizardLessonDraft(
      title: 'Back to the station',
      iconAsset: LessonIconCatalog.byId('directions').assetPath,
      sectionName: 'In town',
    ),
  ];
}
