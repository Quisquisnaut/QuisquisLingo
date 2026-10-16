import '../models/course_models.dart';
import 'course_governance_service.dart';
import 'course_language_pair.dart';
import 'course_service.dart';
import 'language_catalog.dart';

/// Values accepted by the Course Info dialog after its field validation.
typedef CourseInfoChange = ({
  String title,
  List<CourseAuthor> authors,
  List<CourseRightsHolder> rightsHolders,
  List<CourseMediaAttribution> mediaAttributions,
  String license,
  DerivativeWorksPolicy derivativePolicy,
  // Build 258 Revision 4: learners may share, save and print Pages.
  bool allowPageSharing,
  // Build 259 Revision 8: a Private course (stored as temporarySample) is
  // visible only to its Maintainer and assigned Team.
  bool privateCourse,
  // Build 260 Revision 0: language tags an earlier Course gains from the
  // list (only the tags of its own languages), and the learners' name of the
  // learning language ('' for QQL's name).
  String sourceLanguageTag,
  String targetLanguageTag,
  String targetLanguageNameForLearners,
  String variant,
  String startLevel,
  String targetLevel,
  String description,
  String buyACoffeeUrl,
  int? estimatedStudyHours,
  int? minimumAge,
  List<String> keywords,
  CoursePublisherContact? publisherContact,
  int? minimumAppBuild,
  String flagCode,
  String flagImageBase64,
  String worldFlagId,
  // The Course's cover reference, or '' for none (Build 255 Revision 6).
  String coverImage,
  String maintainerProfileId,
  String? assignedTeamId,
});

typedef CourseInfoUpdateResult = ({Course course, bool governanceChanged});

/// Applies a validated Course Info edit to an Editor working copy.
///
/// The caller stages [CourseInfoUpdateResult.course] in its existing Course
/// transaction. This operation does not persist a Course or create a version.
class CourseInfoUpdateService {
  CourseInfoUpdateService({CourseGovernanceService? governanceService})
    : _governanceService = governanceService ?? CourseGovernanceService();

  final CourseGovernanceService _governanceService;

  /// A Course's languages never change after it is created (Build 260
  /// Revision 0, owner decision): Course Info may only add the tag of the
  /// language a side already names. A stored tag stays; an added learning
  /// language tag must keep the language code that language XP and streaks
  /// use, and an added base language tag must name the language the Course
  /// writes, when QQL knows it.
  static void _checkLanguageTags(Course course, CourseInfoChange change) {
    for (final (side, stored, requested, written) in [
      (
        'base',
        course.sourceLanguageTag,
        change.sourceLanguageTag.trim(),
        course.sourceLanguage,
      ),
      (
        'learning',
        course.targetLanguageTag,
        change.targetLanguageTag.trim(),
        course.targetLanguage,
      ),
    ]) {
      if (requested == stored) continue;
      if (stored.isNotEmpty) {
        throw ArgumentError('The $side language tag cannot change.');
      }
      if (!LanguageCatalog.isValidTag(requested)) {
        throw ArgumentError('“$requested” is not a language tag.');
      }
      final known = LanguageCatalog.resolve(written);
      final chosen = LanguageCatalog.byTag(requested);
      if (known != null && chosen?.tag != known.tag) {
        throw ArgumentError(
          '“${chosen?.englishName ?? requested}” is not “$written”: the $side language cannot change.',
        );
      }
    }
    if (!keepsLearningLanguage(course, change.targetLanguageTag)) {
      throw ArgumentError(
        'That tag would move the learning language’s XP and streak: the learning language cannot change.',
      );
    }
    if (!keepsKind(
      course,
      sourceTag: change.sourceLanguageTag,
      targetTag: change.targetLanguageTag,
    )) {
      throw ArgumentError(kindChangeRefusal);
    }
  }

  /// Build 275 Revision 0: what Course Info says of tags that would change
  /// the kind of Course.
  static const kindChangeRefusal =
      'Those tags would change the kind of Course (through another language, '
      'or in the same language): a Course’s kind cannot change.';

  /// Whether [course] with the tags [sourceTag] and [targetTag] ('' for
  /// none) is still the same kind of Course ([CourseLanguagePair]): a tag
  /// chosen for a language typed by hand, or one that drops a region
  /// another field holds, could make a translation Course a same-language
  /// one or the other way round.
  static bool keepsKind(
    Course course, {
    required String sourceTag,
    required String targetTag,
  }) {
    final tagged = Course.fromJson({
      ...course.toJson(),
      if (sourceTag.trim().isNotEmpty) 'sourceLanguageTag': sourceTag.trim(),
      if (targetTag.trim().isNotEmpty) 'targetLanguageTag': targetTag.trim(),
    });
    return CourseLanguagePair.kindOf(tagged) ==
        CourseLanguagePair.kindOf(course);
  }

  /// Whether [course] with the learning language tag [tag] ('' for none)
  /// still has the language code that language XP and streaks use. The
  /// Course Info Editor asks before it offers a tag; [apply] checks again.
  static bool keepsLearningLanguage(Course course, String tag) {
    final tagged = Course.fromJson({
      ...course.toJson(),
      if (tag.trim().isNotEmpty) 'targetLanguageTag': tag.trim(),
    });
    return CourseService.codeForCourse(tagged) ==
        CourseService.codeForCourse(course);
  }

  Future<CourseInfoUpdateResult> apply(
    Course currentCourse,
    CourseInfoChange change,
    String? actorProfileId,
  ) async {
    _checkLanguageTags(currentCourse, change);
    var governedCourse = currentCourse;
    if (governedCourse.assignedTeamId != change.assignedTeamId) {
      if (actorProfileId == null) {
        throw StateError('An active profile is required to assign a Team.');
      }
      governedCourse = await _governanceService.assignTeam(
        course: governedCourse,
        actorProfileId: actorProfileId,
        teamId: change.assignedTeamId,
        editMode: true,
        assignmentConfirmed: true,
      );
    }
    if (governedCourse.maintainer!.profileId != change.maintainerProfileId) {
      if (actorProfileId == null) {
        throw StateError(
          'An active profile is required to transfer the Course Maintainer.',
        );
      }
      governedCourse = await _governanceService.transferMaintainer(
        course: governedCourse,
        actorProfileId: actorProfileId,
        newMaintainerProfileId: change.maintainerProfileId,
        editMode: true,
      );
    }
    final governanceChanged =
        currentCourse.maintainer!.profileId !=
            governedCourse.maintainer!.profileId ||
        currentCourse.assignedTeamId != governedCourse.assignedTeamId;
    final descriptive = <String, Object?>{
      'sourceLanguageTag': change.sourceLanguageTag.trim().isEmpty
          ? null
          : change.sourceLanguageTag.trim(),
      'targetLanguageTag': change.targetLanguageTag.trim().isEmpty
          ? null
          : change.targetLanguageTag.trim(),
      'targetLanguageNameForLearners':
          change.targetLanguageNameForLearners.trim().isEmpty
          ? null
          : change.targetLanguageNameForLearners.trim(),
      'estimatedStudyHours': change.estimatedStudyHours,
      'minimumAge': change.minimumAge,
      'keywords': change.keywords.isEmpty ? null : change.keywords,
      'publisherContact': change.publisherContact?.toJson(),
      'minimumAppBuild': change.minimumAppBuild,
      'coverImage': change.coverImage.isEmpty ? null : change.coverImage,
    };
    final updated = Course.fromJson({
      // Cleared optional fields are omitted, never stored as null.
      ...governedCourse.toJson()
        ..removeWhere((key, _) => descriptive.containsKey(key)),
      for (final entry in descriptive.entries)
        if (entry.value != null) entry.key: entry.value,
      'title': change.title,
      'authors': change.authors.map((author) => author.toJson()).toList(),
      'rightsHolders': change.rightsHolders
          .map((holder) => holder.toJson())
          .toList(),
      'mediaAttributions': change.mediaAttributions
          .map((credit) => credit.toJson())
          .toList(),
      'license': change.license,
      'derivativeWorksPolicy': change.derivativePolicy.name,
      'allowPageSharing': change.allowPageSharing,
      'temporarySample': change.privateCourse,
      'languageVariant': change.variant,
      'startLevel': change.startLevel,
      'targetLevel': change.targetLevel,
      'courseDescription': change.description,
      'buyACoffeeUrl': change.buyACoffeeUrl,
      'flagCode': change.flagCode,
      'flagImageBase64': change.flagImageBase64,
      'worldFlagId': change.worldFlagId,
    });
    return (course: updated, governanceChanged: governanceChanged);
  }
}
