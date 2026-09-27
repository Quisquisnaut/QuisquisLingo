import '../models/course_models.dart';
import '../models/exercise_features.dart';
import '../models/exercise_authoring.dart';
import 'answer_engine.dart';
import 'first_letter_answer_service.dart';
import 'portable_exercise_image.dart';
import 'audit_code_registry.dart';
import 'duel_eligibility_service.dart';
import 'lesson_icon_catalog.dart';
import 'preset_recipes.dart';
import 'translation_choice_service.dart';

export 'audit_code_registry.dart' show AuditSeverity;

enum AuditSortMode { lesson, exerciseType, recentlyModified }

class CourseAuditIssue {
  final AuditSeverity severity;
  final String code;
  final String message;
  final String location;
  final String? roundId;
  final String? exerciseId;
  final String? exerciseType;
  final DateTime? updatedAt;
  const CourseAuditIssue({
    required this.severity,
    required this.message,
    required this.location,
    this.code = 'GENERAL',
    this.roundId,
    this.exerciseId,
    this.exerciseType,
    this.updatedAt,
  });

  /// Known production findings take their identity and severity from the registry.
  CourseAuditIssue.fromCode(
    AuditCode definition, {
    required this.message,
    required this.location,
    this.roundId,
    this.exerciseId,
    this.exerciseType,
    this.updatedAt,
  }) : severity = definition.severity,
       code = definition.code;

  CourseAuditIssue withUpdatedAt(DateTime? value) => CourseAuditIssue(
    severity: severity,
    code: code,
    message: message,
    location: location,
    roundId: roundId,
    exerciseId: exerciseId,
    exerciseType: exerciseType,
    updatedAt: value,
  );

  String get exercisePresetName => exerciseType == null
      ? 'General'
      : ExercisePresetRegistry.byId(exerciseType!)?.name ??
            exerciseType!.replaceAll('_', ' ');
}

class CourseAuditResult {
  final List<CourseAuditIssue> issues;
  final DateTime runAt;
  CourseAuditResult(this.issues) : runAt = DateTime.now();
  int count(AuditSeverity s) => issues.where((i) => i.severity == s).length;

  /// A sentence to append to an export confirmation, or null when the Course
  /// is clean.
  ///
  /// Export deliberately does not gate on Audit: an unfinished Course must stay
  /// movable between machines, and Draft content is audited by the same rules
  /// as finished content. Import, however, refuses any Course carrying an Audit
  /// Error. Without this notice an author can export a file that this same
  /// application will then decline to read back, with nothing said at the point
  /// the file was created.
  String? get exportNotice {
    final errors = count(AuditSeverity.error);
    if (errors > 0) {
      return 'Course Audit found $errors '
          '${errors == 1 ? 'error' : 'errors'}: importing this file will be '
          'refused until they are fixed.';
    }
    final warnings = count(AuditSeverity.warning);
    if (warnings > 0) {
      return 'Course Audit found $warnings '
          '${warnings == 1 ? 'warning' : 'warnings'}: the file imports, but '
          'review them before sharing it.';
    }
    return null;
  }

  List<CourseAuditIssue> sorted(AuditSortMode mode) {
    final indexed = issues.indexed.toList();
    indexed.sort((a, b) {
      final primary = switch (mode) {
        AuditSortMode.lesson => a.$2.location.compareTo(b.$2.location),
        AuditSortMode.exerciseType => a.$2.exercisePresetName.compareTo(
          b.$2.exercisePresetName,
        ),
        AuditSortMode.recentlyModified => _compareRecentlyModified(a.$2, b.$2),
      };
      return primary != 0 ? primary : a.$1.compareTo(b.$1);
    });
    return indexed.map((entry) => entry.$2).toList(growable: false);
  }

  List<NumberedAuditIssue> numbered(
    AuditSortMode mode, {
    AuditSeverity? severity,
  }) {
    final ordered = sorted(mode)
        .where((issue) => severity == null || issue.severity == severity)
        .toList(growable: false);
    final totals = {
      for (final value in AuditSeverity.values)
        value: ordered.where((issue) => issue.severity == value).length,
    };
    final positions = {for (final value in AuditSeverity.values) value: 0};
    return [
      for (final issue in ordered)
        NumberedAuditIssue(
          issue: issue,
          position: positions.update(issue.severity, (value) => value + 1),
          total: totals[issue.severity]!,
        ),
    ];
  }

  static int _compareRecentlyModified(
    CourseAuditIssue left,
    CourseAuditIssue right,
  ) {
    final leftTime =
        left.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final rightTime =
        right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final timestampOrder = rightTime.compareTo(leftTime);
    if (timestampOrder != 0) return timestampOrder;
    final locationOrder = left.location.compareTo(right.location);
    if (locationOrder != 0) return locationOrder;
    final codeOrder = left.code.compareTo(right.code);
    if (codeOrder != 0) return codeOrder;
    return left.message.compareTo(right.message);
  }
}

class NumberedAuditIssue {
  const NumberedAuditIssue({
    required this.issue,
    required this.position,
    required this.total,
  });

  final CourseAuditIssue issue;
  final int position;
  final int total;

  String get label {
    final name = issue.severity.name;
    return '${name[0].toUpperCase()}${name.substring(1)} $position of $total';
  }
}

/// Author-facing static audit.
///
/// This validates structure, editor invariants, common exercise mistakes and a
/// few high-confidence consistency rules. It intentionally does not claim to
/// certify grammar, translation quality or pedagogy.
class CourseAuditService {
  /// The learner kind each preset's recipe produces ([PresetRecipes.kinds]).
  /// An exercise whose derived kind differs from its preset's gets a
  /// non-blocking PRESET_CANONICAL_MISMATCH: the preset is authoring
  /// metadata and never changes what plays (Build 256, plan A.3 and A.5).
  static const presetKinds = PresetRecipes.kinds;

  String _courseSourceCode(Course course) {
    final source = course.sourceLanguage.trim().toLowerCase();
    const names = <String, String>{
      'english': 'EN',
      'spanish': 'ES',
      'italian': 'IT',
      'german': 'DE',
      'portuguese': 'PT',
      'dutch': 'NL',
      'finnish': 'FI',
      'welsh': 'CY',
      'korean': 'KO',
    };
    return names[source] ?? course.interfaceLanguage.trim().toUpperCase();
  }

  String _courseTargetCode(Course course) {
    final target = course.targetLanguage.trim().toLowerCase();
    const names = <String, String>{
      'english': 'EN',
      'spanish': 'ES',
      'italian': 'IT',
      'german': 'DE',
      'portuguese': 'PT',
      'dutch': 'NL',
      'finnish': 'FI',
      'welsh': 'CY',
      'korean': 'KO',
    };
    return names[target] ?? course.learningLanguage.trim().toUpperCase();
  }

  String? _legacyInstructionLanguage(String prompt) {
    const languages = <String, String>{
      'Choose the correct translation.': 'EN',
      'Build the target-language word shown in the image.': 'EN',
      'Build the word shown in the image.': 'EN',
      'Match each translation.': 'EN',
      'Match each sound to the word.': 'EN',
      'Match the opposites.': 'EN',
      'Abbina i contrari.': 'IT',
      'Ordne die Gegensätze zu.': 'DE',
      'Relaciona los contrarios.': 'ES',
      'Associe os opostos.': 'PT',
      'Koppel de tegenstellingen.': 'NL',
      'Yhdistä vastakohdat.': 'FI',
      'Parwch y geiriau croes.': 'CY',
    };
    return languages[prompt.trim()];
  }

  CourseAuditResult auditCourse(
    Course course, {
    Course? sourceReferenceCourse,
  }) {
    final issues = <CourseAuditIssue>[];
    final ids = <String>{};
    // Publication gates audit the learner projection so Draft descendants do
    // not block a Published ancestor. Guidebook sourceRefs are authoring
    // provenance, however, and remain valid while that Guidebook is Draft and
    // therefore absent from the learner projection.
    final authoredSourceIds = <String>{};
    if (sourceReferenceCourse != null) {
      for (final lesson in sourceReferenceCourse.lessons) {
        for (final content in lesson.guidebook.content) {
          if (content.id.trim().isNotEmpty) authoredSourceIds.add(content.id);
        }
      }
    }
    final pendingSourceRefs =
        <
          ({String ref, String location, String? roundId, String? exerciseId})
        >[];
    void idCheck(
      String id,
      String location, {
      String? roundId,
      String? exerciseId,
    }) {
      if (id.trim().isEmpty) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.idMissing,
            message: 'Missing ID.',
            location: location,
            roundId: roundId,
            exerciseId: exerciseId,
          ),
        );
      } else if (!ids.add(id)) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.idDuplicate,
            message: 'Duplicate ID: $id',
            location: location,
            roundId: roundId,
            exerciseId: exerciseId,
          ),
        );
      }
    }

    idCheck(course.courseId, 'Course');
    if (course.sourceLanguage.trim().isEmpty ||
        course.targetLanguage.trim().isEmpty) {
      issues.add(
        CourseAuditIssue.fromCode(
          AuditCode.courseLanguagesRequired,
          message: 'Source and target languages must be defined.',
          location: 'Course',
        ),
      );
    }
    if (course.sourceLanguage.toLowerCase() ==
        course.targetLanguage.toLowerCase()) {
      issues.add(
        CourseAuditIssue.fromCode(
          AuditCode.courseLanguagesIdentical,
          message: 'Source and target languages are identical.',
          location: 'Course',
        ),
      );
    }
    if (course.authors.length > 50) {
      issues.add(
        CourseAuditIssue.fromCode(
          AuditCode.courseAuthorsMany,
          message:
              'Course has more than 50 author entries. Check for accidental duplicates.',
          location: 'Course info',
        ),
      );
    }
    for (final author in course.authors) {
      if (author.name.trim().isEmpty) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.courseAuthorEmpty,
            message: 'Course author name is empty.',
            location: 'Course info',
          ),
        );
      }
      if (author.name.length > 120 || author.roles.any((r) => r.length > 120)) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.courseAuthorLong,
            message:
                'Course author name or role is unusually long and may not display well.',
            location: 'Course info',
          ),
        );
      }
      if (author.roles.isEmpty) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.courseAuthorRoleEmpty,
            message:
                'Course author has no role. Add at least one role or use Contributor.',
            location: 'Course info',
          ),
        );
      }
      if (author.roles.length > 12) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.courseAuthorRolesMany,
            message:
                'Course author has an unusually large number of roles. Check for accidental duplicates.',
            location: 'Course info',
          ),
        );
      }
    }
    if (course.courseDescription.length > 5000) {
      issues.add(
        CourseAuditIssue.fromCode(
          AuditCode.courseDescriptionLong,
          message:
              'Course description exceeds 5,000 characters and may be difficult to edit or display.',
          location: 'Course info',
        ),
      );
    }
    if (course.lessons.isEmpty) {
      issues.add(
        CourseAuditIssue.fromCode(
          AuditCode.courseLessonsEmpty,
          message:
              'Course has no Lessons yet. This is valid while a course is being authored.',
          location: 'Course',
        ),
      );
    }
    final audioKeys = <String>{};
    for (final clip in course.audioLibrary) {
      final key = clip.text.trim().toLowerCase();
      if (key.isEmpty) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.audioMappingTextEmpty,
            message:
                'Orphan MP3 is not associated with any word or expression.',
            location: 'Audio Library',
          ),
        );
        continue;
      }
      if (!audioKeys.add(key)) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.audioMappingDuplicate,
            message: 'Duplicate recorded-audio mapping for “${clip.text}”.',
            location: 'Audio Library',
          ),
        );
      }
    }
    if (course.audioMode == 'recorded' && course.audioLibrary.isEmpty) {
      issues.add(
        CourseAuditIssue.fromCode(
          AuditCode.recordedAudioLibraryEmpty,
          message:
              'Recorded MP3 mode is enabled but the Audio Library is empty.',
          location: 'Audio Library',
        ),
      );
    }

    if (course.mediaAttributions.isEmpty && _carriesOwnMedia(course)) {
      issues.add(
        CourseAuditIssue.fromCode(
          AuditCode.mediaAttributionMissing,
          message:
              'This course uses images or recordings that did not come with QuisquisLingo, but records no media credit.',
          location: 'Course Info',
        ),
      );
    }

    final lessonIconIds = <String>{};
    for (final asset in course.lessonIconAssets) {
      if (!lessonIconIds.add(asset.assetId)) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.lessonIconAssetIdDuplicate,
            message: 'Custom Lesson icon asset IDs must be unique.',
            location: 'Course assets',
          ),
        );
      }
      try {
        CourseLessonIconAsset.validateCanonicalPng(asset.base64Png);
      } on FormatException catch (error) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.lessonIconAssetInvalid,
            message: error.message.toString(),
            location: 'Course assets · ${asset.assetId}',
          ),
        );
      }
    }

    for (var ti = 0; ti < course.lessons.length; ti++) {
      final t = course.lessons[ti];
      final tl = 'Lesson ${ti + 1} · ${t.title}';
      idCheck(t.lessonId, tl);
      idCheck(t.duel.id, '$tl · Duel');
      if (t.section &&
          (t.sectionName == null || t.sectionName!.trim().isEmpty)) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.lessonSectionNameRequired,
            message:
                'Section name is required when Belongs to a Section is enabled.',
            location: tl,
          ),
        );
      }
      if (!t.section && t.sectionName?.trim().isNotEmpty == true) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.lessonSectionNameWithoutSection,
            message:
                'Section name must be absent when Belongs to a Section is disabled.',
            location: tl,
          ),
        );
      }
      if (t.themeIconAsset != null) {
        final icon = t.themeIconAsset!;
        final managedId = CourseLessonIconAsset.assetIdFromReference(icon);
        final valid =
            LessonIconCatalog.isApproved(icon) ||
            (managedId != null && lessonIconIds.contains(managedId));
        if (!valid) {
          issues.add(
            CourseAuditIssue.fromCode(
              AuditCode.lessonThemeIconInvalid,
              message:
                  'Lesson theme icon must reference the preinstalled library or a valid managed Course-owned icon.',
              location: tl,
            ),
          );
        }
      }
      final gb = t.guidebook;
      for (var gi = 0; gi < gb.content.length; gi++) {
        final content = gb.content[gi];
        final location = '$tl · Guidebook Content ${gi + 1}';
        idCheck(content.id, location);
        for (final ref in content.sourceRefs) {
          pendingSourceRefs.add((
            ref: ref,
            location: location,
            roundId: null,
            exerciseId: null,
          ));
        }
      }
      if (course.useGuidebook && gb.content.isEmpty) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.lessonGuidebookEmpty,
            message:
                'Lesson Guidebook is empty. Add learner-facing vocabulary, examples or explanations before generating Rounds.',
            location: '$tl · Guidebook',
          ),
        );
      }
      if (t.rounds.isEmpty) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.lessonRoundsEmpty,
            message: 'Lesson has no rounds yet.',
            location: tl,
          ),
        );
      }
      if (t.rounds.length < 3) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.lessonRoundGuidance,
            message:
                'A Lesson normally has at least 3 Rounds. This is friendly author guidance and does not block saving or publishing.',
            location: tl,
          ),
        );
      }
      if (t.rounds.isNotEmpty) {
        final intro = t.rounds.first.content
            .where((content) => content.role == 'lesson_intro')
            .toList();
        if (intro.isEmpty) {
          issues.add(
            CourseAuditIssue.fromCode(
              AuditCode.lessonIntroMissing,
              message:
                  'The first Round has no short Lesson introduction drawn from the Lesson Guidebook.',
              location: '$tl · Round 1',
            ),
          );
        }
      }
      for (var ri = 0; ri < t.rounds.length; ri++) {
        final r = t.rounds[ri];
        final rl = '$tl · ${r.displayTitle(ri)}';
        idCheck(r.id, rl, roundId: r.id);
        if (r.content.isEmpty) {
          issues.add(
            CourseAuditIssue.fromCode(
              AuditCode.roundContentEmpty,
              message: 'Round has no Content.',
              location: rl,
              roundId: r.id,
            ),
          );
        }
        if (r.content.length > 10) {
          issues.add(
            CourseAuditIssue.fromCode(
              AuditCode.roundContentLong,
              message:
                  'Round has ${r.content.length} Content items; review pacing for more than 10 items.',
              location: rl,
              roundId: r.id,
            ),
          );
        }
        for (
          var contentIndex = 0;
          contentIndex < r.content.length;
          contentIndex++
        ) {
          final content = r.content[contentIndex];
          final location = '$rl · Content ${contentIndex + 1}';
          idCheck(
            content.id,
            location,
            roundId: r.id,
            exerciseId: content.kind == 'exercise' ? content.id : null,
          );
          for (final ref in content.sourceRefs) {
            pendingSourceRefs.add((
              ref: ref,
              location: location,
              roundId: r.id,
              exerciseId: content.role == 'lesson_intro'
                  ? null
                  : content.asRunnableExercise()?.id,
            ));
          }
        }

        final duplicatePrompts = <String>{};
        for (var ei = 0; ei < r.exercises.length; ei++) {
          final ex = r.exercises[ei];
          final el = '$rl · Exercise ${ei + 1}';
          final features = ExerciseFeatures(ex);
          final instructionLanguage = _legacyInstructionLanguage(
            features.primaryText,
          );
          if (instructionLanguage != null &&
              instructionLanguage != _courseSourceCode(course)) {
            issues.add(
              CourseAuditIssue.fromCode(
                AuditCode.instructionLanguageMismatch,
                message:
                    'Exercise instruction appears to be in the wrong language. Learner instructions must use the course source language.',
                location: el,
                roundId: r.id,
                exerciseId: ex.id,
              ),
            );
          }
          issues.addAll(auditExercise(ex, location: el, roundId: r.id));
          final prompt = [
            features.primaryText,
            features.clueText,
            features.passageText,
            features.situationText,
            features.contextText,
          ].where((text) => text.trim().isNotEmpty).join(' ').trim();
          final isOpposite =
              (features.kind == LearnerExerciseKind.match &&
                  prompt.toLowerCase().contains('opposit')) ||
              prompt.toLowerCase().contains('contrar') ||
              prompt.toLowerCase().contains('gegenteil') ||
              prompt.toLowerCase().contains('opuesto');
          if (ri < 2 && isOpposite) {
            issues.add(
              CourseAuditIssue.fromCode(
                AuditCode.oppositeTooEarly,
                message:
                    'Opposite exercises should not be used in the first rounds of a Lesson.',
                location: el,
                roundId: r.id,
                exerciseId: ex.id,
              ),
            );
          }
          final isolated = [
            prompt,
            features.questionText.trim(),
            for (final item in ex.items) item.value,
          ].where((v) => v.isNotEmpty && !v.contains(RegExp(r'\s')));
          if (_courseTargetCode(course) != 'DE' &&
              isolated.any(
                (v) => RegExp(r'^\p{Lu}\p{L}*$', unicode: true).hasMatch(v),
              )) {
            issues.add(
              CourseAuditIssue.fromCode(
                AuditCode.singleWordCase,
                message:
                    'An isolated word starts with a capital letter. Use lowercase unless capitalization is linguistically required.',
                location: el,
                roundId: r.id,
                exerciseId: ex.id,
              ),
            );
          }
          final key = [
            features.kind.name,
            prompt,
            features.questionText,
            features.textOf('term'),
            features.textOf('meaning'),
            features.inlineSentence,
            features.primaryAudioText ?? '',
          ].map((text) => text.trim().toLowerCase()).join('|');
          if (!duplicatePrompts.add(key)) {
            issues.add(
              CourseAuditIssue.fromCode(
                AuditCode.roundDuplicateContent,
                message:
                    'Same exercise prompt/question appears more than once in this round.',
                location: el,
                roundId: r.id,
                exerciseId: ex.id,
              ),
            );
          }
        }
      }
      final eligibility = const DuelEligibilityService().evaluate(t);
      if (course.createDuels && !eligibility.isAvailable) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.duelUnavailable,
            message:
                'Duel is unavailable with ${eligibility.eligibleCount} suitable exercises; ${eligibility.requiredCount} are required. This is normal supported behavior.',
            location: '$tl · Duel',
          ),
        );
      }
    }
    for (final pending in pendingSourceRefs) {
      if (!ids.contains(pending.ref) &&
          !authoredSourceIds.contains(pending.ref)) {
        issues.add(
          CourseAuditIssue.fromCode(
            AuditCode.sourceRefMissing,
            message: 'sourceRefs references missing Content ID: ${pending.ref}',
            location: pending.location,
            roundId: pending.roundId,
            exerciseId: pending.exerciseId,
          ),
        );
      }
    }
    return CourseAuditResult(_attachContentTimestamps(course, issues));
  }

  /// Whether the Course uses any image or recording that did not ship inside
  /// the application.
  ///
  /// Anything under `assets/` is QQL's own media, credited on the app's own
  /// Credits page, so it never needs a Course-level entry. Everything else is
  /// either embedded in the Course (an `assets/`-less Lesson icon, a custom
  /// flag, a `data:` image) or imported by a creator and referenced by path.
  /// A cover is always the Course's own picture (Build 255 Revision 7).
  static bool _carriesOwnMedia(Course course) {
    bool isOwnMedia(String asset) {
      final value = asset.trim();
      return value.isNotEmpty && !value.startsWith('assets/');
    }

    if (course.lessonIconAssets.isNotEmpty) return true;
    if (course.flagImageBase64.trim().isNotEmpty) return true;
    if (isOwnMedia(course.coverImage)) return true;
    for (final clip in course.audioLibrary) {
      if (isOwnMedia(clip.filePath)) return true;
    }
    for (final lesson in course.lessons) {
      for (final round in lesson.rounds) {
        for (final exercise in round.exercises) {
          if (isOwnMedia(exercise.imageAsset)) return true;
          for (final element in exercise.promptElements) {
            if (element.type == 'image' && isOwnMedia(element.asset)) {
              return true;
            }
          }
          for (final item in exercise.interaction.items) {
            for (final element in item.content) {
              if (element.type == 'image' && isOwnMedia(element.asset)) {
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  List<CourseAuditIssue> _attachContentTimestamps(
    Course course,
    List<CourseAuditIssue> issues,
  ) {
    final lessonByPrefix = <String, Lesson>{};
    final roundById = <String, LearningRound>{};
    final exerciseById = <String, Exercise>{};
    for (
      var lessonIndex = 0;
      lessonIndex < course.lessons.length;
      lessonIndex++
    ) {
      final lesson = course.lessons[lessonIndex];
      lessonByPrefix['Lesson ${lessonIndex + 1} ·'] = lesson;
      for (final round in lesson.rounds) {
        roundById[round.id] = round;
        for (final exercise in round.exercises) {
          exerciseById[exercise.id] = exercise;
        }
      }
    }
    DateTime? lessonTimestamp(String location) {
      for (final entry in lessonByPrefix.entries) {
        if (location.startsWith(entry.key)) return entry.value.updatedAt;
      }
      return null;
    }

    return [
      for (final issue in issues)
        issue.withUpdatedAt(
          issue.exerciseId == null
              ? issue.roundId == null
                    ? lessonTimestamp(issue.location)
                    : roundById[issue.roundId]?.updatedAt
              : exerciseById[issue.exerciseId]?.updatedAt,
        ),
    ];
  }

  CourseAuditResult auditLesson(
    Course course,
    String lessonId, {
    Course? sourceReferenceCourse,
  }) {
    final lessonIndex = course.lessons.indexWhere(
      (lesson) => lesson.lessonId == lessonId,
    );
    if (lessonIndex < 0) return CourseAuditResult(const []);
    final prefix = 'Lesson ${lessonIndex + 1} ·';
    return CourseAuditResult(
      auditCourse(
        course,
        sourceReferenceCourse: sourceReferenceCourse,
      ).issues.where((issue) => issue.location.startsWith(prefix)).toList(),
    );
  }

  CourseAuditResult auditRound(
    Course course,
    String roundId, {
    Course? sourceReferenceCourse,
  }) => CourseAuditResult(
    auditCourse(
      course,
      sourceReferenceCourse: sourceReferenceCourse,
    ).issues.where((issue) => issue.roundId == roundId).toList(),
  );

  String? _languageHint(String raw) {
    final token = raw.toLowerCase().replaceAll(
      RegExp(r"[^a-zà-öø-ÿąćęłńóśźżäöüß']"),
      '',
    );
    if (token.isEmpty) return null;
    const sets = <String, Set<String>>{
      'en': {
        'the',
        'a',
        'an',
        'i',
        'you',
        'he',
        'she',
        'we',
        'they',
        'my',
        'your',
        'good',
        'morning',
        'hello',
        'thank',
        'please',
        'house',
        'water',
        'book',
        'friend',
        'woman',
        'man',
        'work',
        'study',
        'eat',
        'drink',
        'right',
        'left',
        'where',
        'what',
        'name',
        'am',
        'is',
        'are',
        'to',
        'from',
        'with',
        'yes',
        'no',
        'come',
      },
      'it': {
        'il',
        'lo',
        'la',
        'i',
        'gli',
        'le',
        'un',
        'una',
        'io',
        'tu',
        'grazie',
        'buongiorno',
        'piacere',
        'amico',
        'uomo',
        'donna',
        'acqua',
        'libro',
        'casa',
        'vado',
        'lavoro',
        'studio',
        'mangio',
        'bevo',
        'destra',
        'sinistra',
        'dove',
        'come',
        'sono',
      },
      'de': {
        'der',
        'die',
        'das',
        'ein',
        'eine',
        'ich',
        'du',
        'danke',
        'guten',
        'morgen',
        'freut',
        'mich',
        'freund',
        'mann',
        'frau',
        'wasser',
        'buch',
        'haus',
        'fahre',
        'arbeite',
        'lerne',
        'esse',
        'trinke',
        'rechts',
        'links',
        'wo',
        'wie',
        'bin',
        'am',
      },
      'es': {
        'el',
        'la',
        'los',
        'las',
        'un',
        'una',
        'yo',
        'tú',
        'hola',
        'gracias',
        'buenos',
        'buenas',
        'días',
        'tardes',
        'mujer',
        'hombre',
        'amigo',
        'libro',
        'casa',
        'agua',
        'café',
        'trabajar',
        'estudiar',
        'comer',
        'beber',
        'dónde',
        'qué',
        'soy',
        'me',
        'llamo',
        'por',
        'favor',
        'de',
      },
      'pt': {
        'o',
        'a',
        'os',
        'as',
        'um',
        'uma',
        'eu',
        'você',
        'olá',
        'obrigado',
        'obrigada',
        'bom',
        'dia',
        'casa',
        'água',
        'livro',
        'amigo',
        'mulher',
        'homem',
      },
      'nl': {
        'de',
        'het',
        'een',
        'ik',
        'jij',
        'hallo',
        'dank',
        'goed',
        'morgen',
        'huis',
        'water',
        'boek',
        'vriend',
        'vrouw',
        'man',
      },
      'fi': {
        'minä',
        'sinä',
        'hei',
        'kiitos',
        'hyvää',
        'huomenta',
        'talo',
        'vesi',
        'kirja',
        'ystävä',
        'nainen',
        'mies',
      },
      'cy': {
        'y',
        'yr',
        'un',
        'fi',
        'ti',
        'helo',
        'diolch',
        'bore',
        'da',
        'tŷ',
        'dŵr',
        'llyfr',
        'ffrind',
      },
    };
    String? hit;
    for (final entry in sets.entries) {
      if (!entry.value.contains(token)) continue;
      if (hit != null && hit != entry.key) return null;
      hit = entry.key;
    }
    return hit;
  }

  /// Validates a gap-based Arrange exercise: its inline layout must declare
  /// at least one gap, every declared gap must have exactly one assignment
  /// referencing an available block, and the same 0-2 distractor allowance
  /// as the whole-sentence Arrange exercises applies to unused blocks.
  /// Every inline-gap Select or Arrange: each gap in the layout needs
  /// exactly one required item that exists, and the items no gap needs are
  /// the 0–2 distractors the content rules allow. Unlike Arrange, the same
  /// option may be the required item of several Select gaps.
  void _auditGapFill(
    ExerciseFeatures f,
    Set<String> itemIdSet,
    void Function(AuditCode, String) add,
  ) {
    final noun = f.primitive == ExercisePrimitive.select ? 'option' : 'block';
    final gapIds = <String>[];
    for (final element in f.exercise.layout) {
      if (!element.isTarget) continue;
      if (element.targetId.trim().isEmpty) {
        add(
          AuditCode.wordBlockDataRequired,
          'A gap in the ${f.primitive.label} layout has no gap ID.',
        );
        continue;
      }
      gapIds.add(element.targetId);
    }
    if (gapIds.isEmpty || gapIds.toSet().length != gapIds.length) {
      add(
        AuditCode.wordBlockDataRequired,
        'Gap-fill ${f.primitive.label} exercise needs one or more uniquely identified gaps in its layout.',
      );
    }
    final assignments = f.targetAssignments;
    final assignedGapIds = assignments.keys.toSet();
    if (assignedGapIds.length != gapIds.toSet().length ||
        !assignedGapIds.containsAll(gapIds)) {
      add(
        AuditCode.buildTranslationInvalidSequence,
        'Every gap in the layout needs exactly one required $noun assignment.',
      );
    }
    if (assignments.values.any((id) => !itemIdSet.contains(id))) {
      add(
        AuditCode.buildTranslationInvalidSequence,
        'A gap assignment refers to a $noun that is not available on this exercise.',
      );
    }
    final extraCount = itemIdSet.difference(assignments.values.toSet()).length;
    if (extraCount < 0 || extraCount > 2) {
      add(
        AuditCode.wordBlockDistractorCount,
        'Gap-fill ${f.primitive.label} exercise may contain 0, 1 or 2 extra distractor ${noun}s; found $extraCount.',
      );
    }
  }

  /// High-confidence word-block language check for sentence building. It
  /// deliberately reports only cases where both the answer and the
  /// distractor contain unambiguous common words from different supported
  /// languages; ambiguous vocabulary is left to human review rather than
  /// guessed.
  void _auditWordBlockLanguage(
    ExerciseFeatures f,
    void Function(AuditCode, String) add,
  ) {
    final orders = f.evaluation.correctOrders;
    if (orders.isEmpty) return;
    final valueById = {for (final item in f.items) item.id: item.value};
    final answerValues = orders.first.itemIds
        .map((id) => valueById[id])
        .whereType<String>()
        .toList();
    final counts = <String, int>{};
    for (final item in f.items) {
      if (item.value.isNotEmpty) {
        counts[item.value] = (counts[item.value] ?? 0) + 1;
      }
    }
    for (final value in answerValues) {
      counts[value] = (counts[value] ?? 0) - 1;
    }
    final extras = counts.entries.where((e) => e.value > 0).toList();
    if (extras.isEmpty) return;
    final answerLanguages = answerValues
        .map(_languageHint)
        .whereType<String>()
        .toSet();
    if (answerLanguages.length != 1) return;
    for (final extra in extras) {
      final distractorLanguage = _languageHint(extra.key);
      if (distractorLanguage != null &&
          !answerLanguages.contains(distractorLanguage)) {
        add(
          AuditCode.wordBlockLanguageMismatch,
          'Word-block distractor appears to be in a different language from the answer blocks.',
        );
        return;
      }
    }
  }

  static AuditCode _violationCode(CapabilityViolation violation) =>
      switch (violation.code) {
        CapabilityViolationCode.unknownPrimitive ||
        CapabilityViolationCode.unknownOption ||
        CapabilityViolationCode.optionNotApplicable ||
        CapabilityViolationCode.illegalOptionValue ||
        CapabilityViolationCode.missingRequiredOption =>
          AuditCode.exerciseOptionInvalid,
        CapabilityViolationCode.illegalCombination =>
          AuditCode.exerciseCombinationIllegal,
        CapabilityViolationCode.missingEvaluationMode ||
        CapabilityViolationCode.illegalEvaluationMode ||
        CapabilityViolationCode.evaluationRequiresOption =>
          AuditCode.exerciseEvaluationModeInvalid,
        CapabilityViolationCode.selectionLimitsImpossible =>
          AuditCode.exerciseSelectionLimits,
      };

  /// The friendly English name of a learner kind, for messages and lists.
  static String kindLabel(LearnerExerciseKind kind) => switch (kind) {
    LearnerExerciseKind.select => 'a plain Choose',
    LearnerExerciseKind.selectComplete => 'Fill in the blank',
    LearnerExerciseKind.selectImage => 'Select the image',
    LearnerExerciseKind.selectCharacter => 'Recognize characters',
    LearnerExerciseKind.selectListen => 'What do you hear',
    LearnerExerciseKind.selectListenPassage => 'Listen and choose',
    LearnerExerciseKind.selectRead => 'Reading comprehension',
    LearnerExerciseKind.selectDialogue => 'Dialogue response',
    LearnerExerciseKind.selectContext => 'Contextual comprehension',
    LearnerExerciseKind.selectTranslation => 'Pick the translation',
    LearnerExerciseKind.inputComplete => 'Type a missing word',
    LearnerExerciseKind.inputTranslation => 'Type the translation',
    LearnerExerciseKind.inputListenWrite => 'Type what you hear',
    LearnerExerciseKind.inputListenGaps => 'Listen for missing words',
    LearnerExerciseKind.inputMissingWord => 'Type the missing word',
    LearnerExerciseKind.arrangeSentence => 'Build the sentence',
    LearnerExerciseKind.arrangeTranslation => 'Build the translation',
    LearnerExerciseKind.arrangeWord => 'Image-prompt ordering',
    LearnerExerciseKind.match => 'Match related words',
    LearnerExerciseKind.matchAudio => 'Listen and match',
    LearnerExerciseKind.matchTranslation => 'Match the words',
    LearnerExerciseKind.presentation => 'a Flashcard',
    LearnerExerciseKind.other => 'an exercise this version cannot play',
  };

  List<CourseAuditIssue> auditExercise(
    Exercise ex, {
    String location = 'Exercise',
    String? roundId,
  }) {
    final out = <CourseAuditIssue>[];
    void add(AuditCode definition, String m) => out.add(
      CourseAuditIssue.fromCode(
        definition,
        message: m,
        location: location,
        roundId: roundId,
        exerciseId: ex.id,
        exerciseType: ex.editorTemplate,
        updatedAt: ex.updatedAt,
      ),
    );
    final f = ExerciseFeatures(ex);
    final evaluation = ex.canonicalEvaluation;
    final kind = f.kind;
    final itemIds = ex.items.map((item) => item.id).toList();
    final itemIdSet = itemIds.toSet();
    final itemValues = ex.items.map((item) => item.value).toList();

    // 1. Canonical validity: options, evaluation mode and their
    // combinations through the capability registry (Errors).
    for (final violation in PrimitiveCapabilityRegistry.validate(
      primitive: ex.primitive,
      options: ex.options,
      evaluationMode: evaluation.mode,
    )) {
      add(_violationCode(violation), violation.message);
    }
    // Multiple selection: the registry's limit invariants (minimum ≤ correct
    // ≤ maximum ≤ items). A single selection has its own rule below.
    if (f.multipleSelection &&
        !f.selectInline &&
        evaluation.correctItemIds.isNotEmpty) {
      for (final violation in PrimitiveCapabilityRegistry.checkSelectionLimits(
        options: ex.options,
        evaluationMode: evaluation.mode,
        correctCount: evaluation.correctItemIds.length,
        itemCount: ex.items.length,
      )) {
        add(AuditCode.exerciseSelectionLimits, violation.message);
      }
    }

    // 2. Media and references (Errors).
    const promptMedia = {'text', 'audio', 'image'};
    final elements = [
      ...ex.promptElements,
      for (final item in ex.items) ...item.content,
    ];
    if (elements.any((element) => !promptMedia.contains(element.type))) {
      add(
        AuditCode.promptMediaUnsupported,
        'Prompt media must be text, audio or image.',
      );
    }
    if (elements.any(
      (element) => element.isAudio && element.text.trim().isEmpty,
    )) {
      add(
        AuditCode.promptMediaUnsupported,
        'An audio element needs the text it speaks.',
      );
    }
    if (itemIds.any((id) => id.trim().isEmpty) ||
        itemIdSet.length != itemIds.length) {
      add(
        AuditCode.exerciseItemIds,
        'Exercise Item IDs must be non-empty and unique.',
      );
    }
    if (evaluation.referencedItemIds.any((id) => !itemIdSet.contains(id))) {
      add(
        AuditCode.exerciseItemReference,
        'Exercise evaluation references an unknown Item ID.',
      );
    }
    final targetIds = ex.targets.map((target) => target.id).toList();
    final targetIdSet = targetIds.toSet();
    if (targetIds.any((id) => id.trim().isEmpty) ||
        targetIdSet.length != targetIds.length) {
      add(
        AuditCode.exerciseTargetReference,
        'Target IDs must be non-empty and unique.',
      );
    }
    final layoutTargets = ex.layout
        .where((element) => element.isTarget)
        .map((element) => element.targetId)
        .toList();
    if (layoutTargets.any((id) => !targetIdSet.contains(id))) {
      add(
        AuditCode.exerciseTargetReference,
        'The layout names a target the exercise does not declare.',
      );
    }
    if (layoutTargets.toSet().length != layoutTargets.length) {
      add(
        AuditCode.exerciseTargetReference,
        'A target appears more than once in the layout.',
      );
    }
    if (ex.layout.isNotEmpty &&
        targetIdSet.difference(layoutTargets.toSet()).isNotEmpty) {
      add(
        AuditCode.exerciseTargetReference,
        'A declared target has no place in the layout.',
      );
    }
    if (evaluation.referencedTargetIds.any((id) => !targetIdSet.contains(id))) {
      add(
        AuditCode.exerciseTargetReference,
        'Exercise evaluation references an unknown target ID.',
      );
    }
    final layoutOption = f.options.enumValue<LayoutValue>(OptionKey.layout);
    final inlineOption =
        layoutOption == LayoutValue.inline ||
        layoutOption == LayoutValue.inlineGaps ||
        f.options.enumValue<PlacementMode>(OptionKey.placementMode) ==
            PlacementMode.inlineGaps;
    if (inlineOption && layoutTargets.isEmpty) {
      add(
        AuditCode.exerciseTargetReference,
        'An inline layout needs at least one target.',
      );
    } else if (!inlineOption && ex.layout.isNotEmpty) {
      add(
        AuditCode.exerciseTargetReference,
        'Only an inline layout may carry layout elements; choose the inline layout or remove them.',
      );
    }
    final longest = [
      f.primaryText,
      f.clueText,
      f.passageText,
      f.situationText,
      f.contextText,
    ].fold(0, (max, text) => text.length > max ? text.length : max);
    if (longest > 1200 || f.questionText.length > 800) {
      add(
        AuditCode.exerciseTextLong,
        'Very long text may be difficult to read on small screens.',
      );
    }

    // 3. The preset is authoring metadata: what disagrees with it warns and
    // never blocks (plan A.5); an unknown preset is information.
    final presetId = ex.editorTemplate;
    if (presetId.isNotEmpty) {
      final preset = ExercisePresetRegistry.byId(presetId);
      if (preset == null) {
        add(
          AuditCode.exercisePresetUnknown,
          'Exercise preset “$presetId” is not available in this version; the exercise plays from its own data.',
        );
      } else {
        final expected = presetKinds[presetId];
        if (preset.primitive != ex.primitive) {
          add(
            AuditCode.presetCanonicalMismatch,
            '${preset.name} configures ${preset.primitive.label} exercises; this one is ${ex.primitive.label}.',
          );
        } else if (expected != null && expected != kind) {
          add(
            AuditCode.presetCanonicalMismatch,
            'This exercise no longer matches ${preset.name}: it plays as ${kindLabel(kind)}.',
          );
        }
        switch (presetId) {
          case 'dialogue_response':
            if (f.situationText.trim().isEmpty) {
              add(
                AuditCode.dialogueContextRequired,
                'Dialogue Response needs a context sentence.',
              );
            }
            if (f.questionText.trim().isEmpty) {
              add(
                AuditCode.dialogueQuestionRequired,
                'Dialogue Response needs a question.',
              );
            }
            if (ex.items.length != 2) {
              add(
                AuditCode.dialogueResponseOptionCount,
                'Dialogue Response requires exactly two response options.',
              );
            }
          case 'contextual_comprehension':
            if (f.questionText.trim().isEmpty) {
              add(
                AuditCode.contextQuestionRequired,
                'Contextual comprehension needs a separate question. Enter what the learner should answer about the context.',
              );
            }
            if (f.contextText.trim().isEmpty &&
                f.contextAudio.trim().isEmpty &&
                f.dialogueTurns.isEmpty) {
              add(
                AuditCode.contextRequired,
                'Contextual comprehension needs text, audio or dialogue context. Add the material the question refers to.',
              );
            }
          case 'reading_comprehension':
            if (_lexicalWordCount(f.passageText) == 0) {
              add(
                AuditCode.readingPassageRequired,
                'Reading Comprehension needs a Reading Passage containing words.',
              );
            }
          case 'listening_choice':
          case 'listening_comprehension':
          case 'listening_spelling':
          case 'missing_word':
            if ((f.automaticAudio?.text ?? '').trim().isEmpty) {
              add(
                AuditCode.listeningAudioRequired,
                'Listening exercise has no audio text. Enter the text the learner should hear.',
              );
            }
            if (presetId == 'listening_comprehension' &&
                f.passageAudio.trim().split(RegExp(r'\s+')).length < 5) {
              add(
                AuditCode.listeningPassageShort,
                'Listening comprehension passage is very short; make sure it tests comprehension.',
              );
            }
          case 'gap_choice':
            if (f.questionText.trim().isEmpty) {
              add(
                AuditCode.gapSentenceRequired,
                'Gap Choice needs a target-language sentence.',
              );
            } else if (!RegExp(r'___').hasMatch(f.questionText)) {
              add(
                AuditCode.gapMarkerMissing,
                'Gap Choice sentence must contain the ___ gap marker.',
              );
            }
          case 'translation_choice_to_target':
          case 'translation_choice_to_source':
            if (f.questionText.trim().isEmpty) {
              add(
                AuditCode.translationChoiceTextRequired,
                'Pick the translation needs the text to translate.',
              );
            }
            if (ex.items.length > TranslationChoice.maxAnswers) {
              add(
                AuditCode.translationChoiceTooManyAnswers,
                'Pick the translation accepts at most ${TranslationChoice.maxAnswers} answer options.',
              );
            }
            if (f.primaryText.trim().isNotEmpty || f.audioElements.isNotEmpty) {
              add(
                AuditCode.presetCanonicalMismatch,
                'Pick the translation shows only the text to translate and speaks it itself; remove the extra prompt text or spoken text.',
              );
            }
          case 'word_match':
          case 'super_match':
            if (evaluation.relations.length != 3) {
              add(
                AuditCode.matchPairCount,
                '${preset.name} requires exactly 3 pairs.',
              );
            }
          case 'audio_match':
            if (evaluation.relations.length != 3) {
              add(
                AuditCode.audioMatchPairCount,
                'Audio Match requires exactly 3 sound/text pairs.',
              );
            }
            if (f.rightItems.length != evaluation.relations.length) {
              add(
                AuditCode.audioMatchAnswerCount,
                'Audio Match must have one visible answer for each sound and no distractors.',
              );
            }
          case 'script_recognition':
            final imageItems = f.hasImageItems;
            if (evaluation.mode != EvaluationMode.exactItem ||
                f.multipleSelection ||
                evaluation.correctItemIds.length != 1) {
              add(
                AuditCode.presetCanonicalMismatch,
                'Recognize characters requires exactly one correct option and one selection.',
              );
            }
            if (imageItems) {
              if (f.primaryText.trim().isEmpty ||
                  f.characterImages.isNotEmpty ||
                  ex.items.any(
                    (item) =>
                        item.image.isEmpty ||
                        item.content.any((element) => !element.isImage),
                  )) {
                add(
                  AuditCode.presetCanonicalMismatch,
                  'Text to image requires a nonempty text prompt and at least two image-only options.',
                );
              }
            } else if (f.characterImages.isEmpty ||
                ex.items.any(
                  (item) =>
                      item.text.trim().isEmpty ||
                      item.content.any((element) => !element.isText),
                )) {
              add(
                AuditCode.presetCanonicalMismatch,
                'Image to text requires one or more prompt images and at least two text-only options.',
              );
            }
        }
      }
    }

    // 4. Content rules by primitive and kind, from canonical data.
    switch (ex.primitive) {
      case ExercisePrimitive.select:
        if (f.selectInline) {
          _auditGapFill(f, itemIdSet, add);
          break;
        }
        if (ex.items.length < 2) {
          add(
            AuditCode.choiceAnswersRequired,
            'Choice exercise needs at least two answers.',
          );
        }
        if (f.multipleSelection) {
          if (evaluation.correctItemIds.isEmpty) {
            add(
              AuditCode.choiceCorrectAnswerInvalid,
              'Multiple-selection Choice exercise needs at least one correct answer.',
            );
          }
        } else if (evaluation.correctItemIds.isEmpty ||
            !itemIdSet.contains(evaluation.correctItemIds.first)) {
          add(
            AuditCode.choiceCorrectAnswerInvalid,
            'Correct answer is missing or outside the answer list. Select a correct answer from the current options.',
          );
        } else if (evaluation.correctItemIds.length > 1) {
          add(
            AuditCode.choiceCorrectAnswerInvalid,
            'A single-selection exercise needs exactly one correct answer.',
          );
        }
        if (evaluation.correctItemIds.isNotEmpty &&
            !evaluation.correctItemIds.any(itemIdSet.contains)) {
          add(
            AuditCode.correctItemUnresolved,
            'Correct Item ID does not resolve to a visible answer option.',
          );
        }
        if (itemValues.any((value) => value.trim().isEmpty)) {
          add(AuditCode.choiceAnswerEmpty, 'Answer options cannot be blank.');
        }
        final repeated = f.isTranslationChoice
            ? TranslationChoice.hasRepeatedAnswers(itemValues)
            : itemValues.map((e) => e.trim().toLowerCase()).toSet().length !=
                  itemValues.length;
        if (repeated) {
          add(
            AuditCode.choiceAnswerDuplicate,
            'Answer options contain duplicates.',
          );
        }
        const placeholderAnswers = {
          'xyz',
          'abc',
          'placeholder',
          'test answer',
          'dummy',
        };
        if (itemValues.any(
          (e) => placeholderAnswers.contains(e.trim().toLowerCase()),
        )) {
          add(
            AuditCode.placeholderAnswer,
            'Answer options contain placeholder text. Replace it with a real course-language distractor.',
          );
        }
        final normalizedPrompt = f.primaryText.trim().toLowerCase();
        if (normalizedPrompt == 'choose the correct translation.' ||
            normalizedPrompt == 'elige la traducción correcta.') {
          add(
            AuditCode.translationPromptMissingSource,
            'Translation prompt does not identify the word or expression to translate.',
          );
        }
        if (kind == LearnerExerciseKind.selectRead) {
          final lexicalWords = _lexicalWordCount(f.passageText);
          if (lexicalWords > 0 && lexicalWords < 3) {
            add(
              AuditCode.readingPassageTooShort,
              'Reading Comprehension passages should contain at least three words.',
            );
          }
          final correct = evaluation.correctItemIds.firstOrNull;
          final correctText = ex.items
              .where((item) => item.id == correct)
              .map((item) => item.value.trim().toLowerCase())
              .firstOrNull;
          if (f.questionText.toLowerCase().contains(
                'which option best fits the lesson vocabulary',
              ) &&
              correctText != null &&
              correctText.isNotEmpty &&
              !f.passageText.trim().toLowerCase().contains(correctText)) {
            add(
              AuditCode.readingOptionNotInPassage,
              'The declared correct option does not occur in the reading passage. Review this generated Reading exercise for a likely vocabulary mismatch.',
            );
          }
        }
        if (kind == LearnerExerciseKind.selectComplete) {
          final sentence = ex.promptElements
              .where((e) => e.isText && RegExp(r'___').hasMatch(e.text))
              .map((e) => e.text)
              .first;
          final gapCount = RegExp(r'___').allMatches(sentence).length;
          if (gapCount > 1) {
            add(
              AuditCode.gapMarkerCount,
              'Gap Choice should normally contain exactly one gap.',
            );
          }
          final correct = evaluation.correctItemIds.firstOrNull;
          final correctAnswer = ex.items
              .where((item) => item.id == correct)
              .map((item) => item.value)
              .firstOrNull;
          if (correctAnswer != null && correctAnswer.isNotEmpty) {
            final completed = sentence.replaceFirst('___', correctAnswer);
            if (_lexicalWordCount(completed) < 2) {
              add(
                AuditCode.gapSentenceTooShort,
                'The completed sentence must contain at least 2 words.',
              );
            }
          }
        }
        if (f.dialogueTurns.any(
          (turn) => turn.speaker.trim().isEmpty || turn.text.trim().isEmpty,
        )) {
          add(
            AuditCode.dialogueTurnInvalid,
            'Every dialogue turn needs a speaker and text.',
          );
        }
        if (kind == LearnerExerciseKind.selectCharacter) {
          final assets = [
            ...f.characterImages.map((element) => element.asset),
            for (final item in ex.items)
              ...item.content
                  .where((element) => element.isImage)
                  .map((element) => element.asset),
          ];
          if (assets.any(
            (asset) => !PortableExerciseImageService.isPortable(asset),
          )) {
            add(
              AuditCode.promptMediaUnsupported,
              'Recognize characters images must be portable bundled assets or valid embedded PNG, JPEG or WebP images of at most 50 KB. Absolute local paths are not allowed.',
            );
          }
        }
      case ExercisePrimitive.input:
        final answers = f.acceptedAnswers;
        if (answers.isEmpty) {
          switch (kind) {
            case LearnerExerciseKind.inputTranslation:
              add(
                AuditCode.translationAnswerRequired,
                'Type the translation needs at least one accepted answer.',
              );
            case LearnerExerciseKind.inputListenWrite:
              add(
                AuditCode.listeningSpellingNoAnswer,
                'Listening Spelling needs at least one accepted text answer.',
              );
            case LearnerExerciseKind.inputListenGaps:
              add(
                AuditCode.missingWordAnswerRequired,
                'Missing Word exercise needs at least one missing word.',
              );
            case LearnerExerciseKind.inputMissingWord:
              add(
                AuditCode.fillBlankAnswerRequired,
                'Type the missing word needs a complete accepted word.',
              );
            default:
              add(
                AuditCode.fillBlankAnswerRequired,
                'Fill-in exercise needs at least one accepted answer.',
              );
          }
        }
        for (final expression in answers) {
          try {
            AnswerExpressionParser.expand(expression);
          } on AnswerExpressionException catch (error) {
            add(AuditCode.answerExpressionInvalid, error.message);
          }
        }
        if (answers.isNotEmpty) {
          try {
            AnswerExpressionParser.expandAll(answers);
          } on AnswerExpressionException catch (error) {
            add(AuditCode.answerExpansionLimit, error.message);
          }
        }
        if (kind == LearnerExerciseKind.inputMissingWord &&
            answers.isNotEmpty) {
          try {
            FirstLetterAnswerService.display(f.inlineSentence, answers);
          } on AnswerExpressionException catch (error) {
            add(AuditCode.answerExpressionInvalid, error.message);
          }
        }
        if (kind == LearnerExerciseKind.inputTranslation &&
            f.primaryText.trim().isEmpty &&
            f.clueText.trim().isEmpty) {
          add(
            AuditCode.translationSourceRequired,
            'Type the translation needs source text.',
          );
        }
        if (kind == LearnerExerciseKind.inputListenGaps &&
            ex.layout.every(
              (element) => element.isTarget || element.text.trim().isEmpty,
            )) {
          add(
            AuditCode.missingWordTranscriptRequired,
            'Missing Word exercise needs a passage transcript.',
          );
        }
      case ExercisePrimitive.arrange:
        if (f.arrangeInline) {
          _auditGapFill(f, itemIdSet, add);
          break;
        }
        final orders = evaluation.correctOrders;
        final translation = kind == LearnerExerciseKind.arrangeTranslation;
        if (ex.items.isEmpty || orders.isEmpty) {
          add(
            AuditCode.wordBlockDataRequired,
            translation
                ? 'Build the translation needs usable Language blocks and at least one correct translation.'
                : 'Word-block exercise needs available blocks and a correct answer. Enter the answer and select its blocks in order.',
          );
        }
        final normalizedAnswers = <String>{};
        final usedItemIds = <String>{};
        final itemValueById = {
          for (final item in ex.items) item.id: item.value,
        };
        final separator = f.joinsWithoutSpaces ? '' : ' ';
        for (final answer in orders) {
          final normalized = _orderedAnswerComparable(answer.text);
          if (normalized.isEmpty) {
            add(
              AuditCode.buildTranslationAnswerRequired,
              'Each correct answer must contain complete, non-empty literal text that its selected blocks can build.',
            );
          } else if (!normalizedAnswers.add(normalized)) {
            add(
              AuditCode.buildTranslationDuplicateAnswer,
              'Correct answers contain a duplicate after ignoring case, repeated spaces and final sentence punctuation. Keep one copy of that answer.',
            );
          }
          if (answer.itemIds.isEmpty ||
              answer.itemIds.any((id) => !itemIdSet.contains(id))) {
            add(
              AuditCode.buildTranslationInvalidSequence,
              'A correct answer has no block order or refers to unavailable blocks. Select its blocks from the current available list.',
            );
            continue;
          }
          if (answer.itemIds.toSet().length != answer.itemIds.length) {
            add(
              AuditCode.buildTranslationReusedBlock,
              'Repeated words require separate available block occurrences. Add another copy of the word and select each occurrence once.',
            );
          }
          usedItemIds.addAll(answer.itemIds);
          final constructed = answer.itemIds
              .map((id) => itemValueById[id])
              .whereType<String>()
              .join(separator);
          if (_orderedAnswerComparable(constructed) != normalized) {
            add(
              AuditCode.buildTranslationUnconstructable,
              'A correct answer cannot be built from its selected block order. Make the answer text and ordered blocks agree exactly, allowing the existing final sentence punctuation.',
            );
          }
        }
        final comparisonOrder = translation
            ? usedItemIds
            : orders.isEmpty
            ? const <String>{}
            : orders.first.itemIds.toSet();
        final extraCount = itemIdSet.difference(comparisonOrder).length;
        if (extraCount < 0 || extraCount > 2) {
          add(
            AuditCode.wordBlockDistractorCount,
            translation
                ? 'Build the translation may contain 0, 1 or 2 blocks unused by every correct translation; found $extraCount.'
                : 'Word-block exercise may contain 0, 1 or 2 extra distractor blocks; found $extraCount.',
          );
        } else if (kind == LearnerExerciseKind.arrangeWord &&
            extraCount > 0 &&
            presetId == 'image_word') {
          add(
            AuditCode.presetCanonicalMismatch,
            'Letter/syllable word-building exercises should contain only the blocks needed for the answer; found $extraCount extra ${extraCount == 1 ? 'block' : 'blocks'}.',
          );
        }
        if (kind == LearnerExerciseKind.arrangeSentence) {
          _auditWordBlockLanguage(f, add);
        }
        // Blocks joined without spaces build the word a picture shows: without
        // the picture the exercise cannot be solved, whatever authored it.
        if (kind == LearnerExerciseKind.arrangeWord &&
            f.illustrationAsset.trim().isEmpty) {
          add(
            AuditCode.imageWordImageRequired,
            'Image Word exercise requires an image.',
          );
        }
      case ExercisePrimitive.match:
        final relations = evaluation.relations;
        if (relations.isEmpty) {
          add(
            AuditCode.matchingPairsRequired,
            'Matching exercise needs at least one pair.',
          );
        }
        final valueById = {for (final item in ex.items) item.id: item.value};
        String normalizedMatchText(String value) => value
            .toLowerCase()
            .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final pairs = [
          for (final relation in relations)
            if (relation.length == 2)
              [valueById[relation[0]] ?? '', valueById[relation[1]] ?? ''],
        ];
        if (relations.any((relation) => relation.length != 2) ||
            pairs.any(
              (pair) => pair[0].trim().isEmpty || pair[1].trim().isEmpty,
            )) {
          add(
            kind == LearnerExerciseKind.matchAudio
                ? AuditCode.audioMatchPairEmpty
                : AuditCode.matchPairEmpty,
            kind == LearnerExerciseKind.matchAudio
                ? 'Audio Match contains an empty sound or match.'
                : 'Match exercise contains an empty pair.',
          );
        }
        final left = pairs.map((pair) => normalizedMatchText(pair[0])).toList();
        final right = pairs
            .map((pair) => normalizedMatchText(pair[1]))
            .toList();
        if (kind == LearnerExerciseKind.matchAudio) {
          final visibleKeys = f.rightItems
              .map((item) => item.value.trim().toLowerCase())
              .toList();
          final visible = visibleKeys.toSet();
          if (visible.length != visibleKeys.length) {
            add(
              AuditCode.audioMatchAnswerDuplicate,
              'Audio Match visible choices contain duplicates.',
            );
          }
          if (pairs.any(
            (pair) => !visible.contains(pair[1].trim().toLowerCase()),
          )) {
            add(
              AuditCode.audioMatchAnswerMissing,
              'Every Audio Match value must appear among the visible choices.',
            );
          }
          if (left.toSet().length != left.length) {
            add(
              AuditCode.audioMatchSoundDuplicate,
              'Audio Match repeats the same target audio.',
            );
          }
          if (right.toSet().length != right.length) {
            add(
              AuditCode.audioMatchTextDuplicate,
              'Audio Match repeats the same matching text.',
            );
          }
        } else {
          if (left.toSet().length != left.length) {
            add(
              AuditCode.matchLeftDuplicate,
              'Match exercise repeats the same left-side item after ignoring case and punctuation.',
            );
          }
          if (right.toSet().length != right.length) {
            add(
              AuditCode.matchRightDuplicate,
              'Match exercise repeats the same right-side item after ignoring case and punctuation.',
            );
          }
        }
      case ExercisePrimitive.presentation:
        if (f.textOf('term').trim().isEmpty) {
          add(
            AuditCode.flashcardTextRequired,
            'Flashcard needs a target word or phrase.',
          );
        }
        if (f.textOf('meaning').trim().isEmpty) {
          add(AuditCode.flashcardMeaningEmpty, 'Flashcard meaning is empty.');
        }
        if (f.textOf('usage').trim().isEmpty) {
          add(
            AuditCode.flashcardExampleEmpty,
            'Flashcard has no usage sentence.',
          );
        }
        if (f.audioOf('audio').trim().isEmpty) {
          add(
            AuditCode.flashcardAudioEmpty,
            'Flashcard has no pronunciation TTS text.',
          );
        }
      case ExercisePrimitive.assign:
      case ExercisePrimitive.speak:
      case ExercisePrimitive.ink:
      case ExercisePrimitive.submit:
        break;
    }

    // 5. Hints, from the canonical texts and answers.
    _auditRepeatingHint(ex.hint, [
      f.primaryText,
      f.clueText,
      f.questionText,
      f.passageText,
      f.situationText,
      f.contextText,
      f.contextAudio,
    ], add);
    _auditRevealingHint(ex.hint, [
      ...f.acceptedAnswers,
      ...f.literalAnswers,
      ...evaluation.correctOrders.map((answer) => answer.text),
      for (final correctId in [
        ...evaluation.correctItemIds,
        ...f.targetAssignments.values,
      ])
        ...ex.items
            .where((item) => item.id == correctId)
            .map((item) => item.value),
    ], add);
    return out;
  }

  int _lexicalWordCount(String value) => RegExp(
    r"\p{L}+(?:['’\-]\p{L}+)*|\p{N}+",
    unicode: true,
  ).allMatches(value).length;

  String _hintComparable(String value) => value
      .trim()
      .replaceAll(
        RegExp(r'^[\p{P}\p{S}\s]+|[\p{P}\p{S}\s]+$', unicode: true),
        '',
      )
      .trim()
      .toLowerCase();

  String _orderedAnswerComparable(String value) => value
      .trim()
      .replaceAll(RegExp(r'[.!?…]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();

  void _auditRepeatingHint(
    String hint,
    Iterable<String> promptParts,
    void Function(AuditCode, String) add,
  ) {
    final normalizedHint = _hintComparable(hint);
    if (normalizedHint.isEmpty) return;
    if (promptParts.any(
      (part) =>
          _hintComparable(part).isNotEmpty &&
          _hintComparable(part) == normalizedHint,
    )) {
      add(
        AuditCode.hintRepeatsPrompt,
        'The Hint repeats the prompt, source text or question instead of providing useful help.',
      );
    }
  }

  void _auditRevealingHint(
    String hint,
    Iterable<String> correctAlternatives,
    void Function(AuditCode, String) add,
  ) {
    final normalizedHint = _hintComparable(hint);
    if (normalizedHint.isEmpty) return;
    if (correctAlternatives.any(
      (answer) =>
          _hintComparable(answer).isNotEmpty &&
          _hintComparable(answer) == normalizedHint,
    )) {
      add(
        AuditCode.hintRevealsAnswer,
        'The Hint must not be the correct answer.',
      );
    }
  }
}
