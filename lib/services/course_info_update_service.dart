import '../models/course_models.dart';
import 'course_governance_service.dart';
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
    final tagged = Course.fromJson({
      ...course.toJson(),
      if (change.targetLanguageTag.trim().isNotEmpty)
        'targetLanguageTag': change.targetLanguageTag.trim(),
    });
    if (CourseService.codeForCourse(tagged) !=
        CourseService.codeForCourse(course)) {
      throw ArgumentError(
        'That tag would move the learning language’s XP and streak: the learning language cannot change.',
      );
    }
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
