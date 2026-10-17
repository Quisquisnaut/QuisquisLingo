import 'package:flutter/widgets.dart';

import '../models/course_flag_selection.dart';
import '../models/course_models.dart';
import '../services/course_credits.dart';
import '../services/course_info_update_service.dart';
import '../services/exercise_copy_service.dart';
import '../services/formal_name_policy.dart';
import 'course_credit_rows.dart';

/// One Media credit row of the Course Info Editor.
class CourseMediaCreditRow {
  CourseMediaCreditRow([CourseMediaAttribution? credit])
    : author = TextEditingController(text: credit?.author ?? ''),
      license = TextEditingController(text: credit?.license ?? ''),
      title = TextEditingController(text: credit?.title ?? ''),
      source = TextEditingController(text: credit?.source ?? ''),
      appliesTo = TextEditingController(text: credit?.appliesTo ?? '');

  final TextEditingController author;
  final TextEditingController license;
  final TextEditingController title;
  final TextEditingController source;
  final TextEditingController appliesTo;

  /// Whether the row reads exactly as [credit].
  bool shows(CourseMediaAttribution credit) =>
      author.text.trim() == credit.author &&
      license.text.trim() == credit.license &&
      title.text.trim() == credit.title &&
      source.text.trim() == credit.source &&
      appliesTo.text.trim() == credit.appliesTo;

  void fill(CourseMediaAttribution credit) {
    author.text = credit.author;
    license.text = credit.license;
    title.text = credit.title;
    source.text = credit.source;
    appliesTo.text = credit.appliesTo;
  }

  void clear() {
    author.clear();
    license.clear();
    title.clear();
    source.clear();
    appliesTo.clear();
  }

  void dispose() {
    author.dispose();
    license.dispose();
    title.dispose();
    source.dispose();
    appliesTo.dispose();
  }
}

/// What Apply in the Course Info Editor comes to.
sealed class CourseInfoSubmission {
  const CourseInfoSubmission();
}

/// The fields can be stored: [change] goes to [CourseInfoUpdateService].
final class CourseInfoAccepted extends CourseInfoSubmission {
  const CourseInfoAccepted(this.change);

  final CourseInfoChange change;
}

/// The fields cannot be stored. [message] is told to the author; without
/// one the form shows the reason itself, under the Media credits
/// ([CourseInfoForm.mediaCreditError]).
final class CourseInfoRefused extends CourseInfoSubmission {
  const CourseInfoRefused({this.message});

  final String? message;
}

/// The state of the Course Info Editor: what its fields hold, starting from
/// a Course, and what Apply makes of them (Build 272 Revision 1; before,
/// this lived in one method of the Course Editor screen).
///
/// It shows nothing and stores nothing: the dialog draws it, and the Course
/// Editor stages the [CourseInfoChange] of an accepted [submit] in its
/// working copy. The dialog that draws a form disposes it when it leaves
/// the screen.
class CourseInfoForm {
  CourseInfoForm(this.course, {int? backupsKept})
    : initialBackupsKept = backupsKept,
      backupsKept = backupsKept,
      maintainerProfileId = course.maintainer!.profileId,
      assignedTeamId = course.assignedTeamId,
      authors = [
        for (final author in course.authors) CourseCreditRow.of(author),
      ],
      rightsHolders = [
        for (final holder in course.rightsHolders)
          CourseRightsHolderRow.of(holder),
      ],
      mediaCredits = [
        for (final credit in course.mediaAttributions)
          CourseMediaCreditRow(credit),
      ],
      title = TextEditingController(text: course.title),
      variant = TextEditingController(text: course.languageVariant),
      startLevel = TextEditingController(text: course.startLevel),
      targetLevel = TextEditingController(text: course.targetLevel),
      description = TextEditingController(text: course.courseDescription),
      buyACoffeeUrl = TextEditingController(text: course.buyACoffeeUrl),
      estimatedHours = TextEditingController(
        text: course.estimatedStudyHours?.toString() ?? '',
      ),
      keywords = TextEditingController(text: course.keywords.join(', ')),
      contactWebsite = TextEditingController(
        text: course.publisherContact?.websiteUrl ?? '',
      ),
      contactEmail = TextEditingController(
        text: course.publisherContact?.email ?? '',
      ),
      minimumAppBuild = TextEditingController(
        text: course.minimumAppBuild?.toString() ?? '',
      ),
      customLicense = TextEditingController(
        text: CourseCredits.customLicenseTextFor(course.license),
      ),
      learnerLanguageName = TextEditingController(
        text: course.targetLanguageNameForLearners,
      ),
      minimumAge = course.minimumAge,
      licenseChoice = CourseCredits.licenseChoiceFor(course.license),
      derivativePolicy = course.derivativeWorksPolicy,
      allowPageSharing = course.allowPageSharing,
      privateCourse = course.temporarySample,
      sourceTag = course.sourceLanguageTag,
      targetTag = course.targetLanguageTag,
      flag = CourseFlagSelection.fromCourse(course),
      coverImage = course.coverImage,
      defaultLearnerLanguageName = ExerciseCopyService.languageName(
        Course.fromJson({
          ...course.toJson(),
          'targetLanguageNameForLearners': '',
        }),
        intoSource: false,
      ) {
    // A list never shows empty: its blank row costs nothing, because Apply
    // drops rows left blank.
    if (authors.isEmpty) addAuthor();
    if (rightsHolders.isEmpty) addRightsHolder();
    if (mediaCredits.isEmpty) addMediaCredit();
  }

  /// The Course Editor's working copy the form opened on.
  final Course course;

  // ---- Course identity

  final TextEditingController title;
  String maintainerProfileId;
  String? assignedTeamId;

  // ---- Languages, flag and cover

  /// The tags of the Course's own languages ('' for none). An earlier Course
  /// may gain them (Build 260 Revision 0); a stored tag never changes.
  String sourceTag;
  String targetTag;
  final TextEditingController learnerLanguageName;

  /// QQL's own name of the learning language, shown while the field above
  /// is empty.
  final String defaultLearnerLanguageName;
  CourseFlagSelection flag;
  String coverImage;

  // ---- Authors and description

  final List<CourseCreditRow> authors;
  final TextEditingController variant;
  final TextEditingController startLevel;
  final TextEditingController targetLevel;
  final TextEditingController description;
  final TextEditingController buyACoffeeUrl;
  final TextEditingController estimatedHours;
  int? minimumAge;
  final TextEditingController keywords;
  final TextEditingController contactWebsite;
  final TextEditingController contactEmail;
  final TextEditingController minimumAppBuild;

  // ---- Licence and rights

  /// The entry chosen in the licence list.
  String licenseChoice;
  final TextEditingController customLicense;
  DerivativeWorksPolicy derivativePolicy;
  bool allowPageSharing;
  bool privateCourse;
  final List<CourseRightsHolderRow> rightsHolders;

  /// A setting of this device, saved with Apply and never in the Course
  /// file (Build 270 Revision 9): how many backups are kept, null for all.
  final int? initialBackupsKept;
  int? backupsKept;

  // ---- Media credits

  final List<CourseMediaCreditRow> mediaCredits;

  /// Why the Media credits cannot be stored, shown under them.
  String? mediaCreditError;

  /// The credit QQL added for the cover chosen last, and its row (Build 255
  /// Revision 7). It leaves again with the next cover while nobody has
  /// changed its row.
  CourseMediaAttribution? _coverCredit;
  CourseMediaCreditRow? _coverCreditRow;

  // ---- Rows

  /// A new credit row starts as Contributor.
  void addAuthor() => authors.add(CourseCreditRow());

  void removeAuthor(int index) => authors.removeAt(index).dispose();

  void addRightsHolder() => rightsHolders.add(CourseRightsHolderRow());

  void removeRightsHolder(int index) => rightsHolders.removeAt(index).dispose();

  void addMediaCredit() => mediaCredits.add(CourseMediaCreditRow());

  void removeMediaCredit(int index) {
    mediaCredits.removeAt(index).dispose();
    mediaCreditError = null;
  }

  // ---- Licence

  /// The author picked [choice] in the licence list: a licence that states
  /// its policy brings it; Other / Custom license keeps the policy shown.
  void chooseLicense(String choice) {
    licenseChoice = choice;
    derivativePolicy = CourseCredits.policyAfterChoosing(
      choice,
      derivativePolicy,
    );
  }

  // ---- Cover

  /// The author chose [cover] ('' for none), a picture whose [credit] QQL
  /// knows or does not (null).
  void setCover(String cover, CourseMediaAttribution? credit) {
    coverImage = cover;
    _creditCover(credit);
    mediaCreditError = null;
  }

  /// The credit of the cover before leaves with it while its row is as QQL
  /// wrote it; [credit] gets a row unless one already reads the same.
  void _creditCover(CourseMediaAttribution? credit) {
    final previous = _coverCredit;
    final previousRowObject = _coverCreditRow;
    final previousRow = previousRowObject == null
        ? -1
        : mediaCredits.indexOf(previousRowObject);
    _coverCredit = null;
    _coverCreditRow = null;
    if (previous != null &&
        previousRow >= 0 &&
        mediaCredits[previousRow].shows(previous)) {
      if (mediaCredits.length == 1) {
        mediaCredits.single.clear();
      } else {
        mediaCredits.removeAt(previousRow).dispose();
      }
    }
    if (credit == null) return;
    for (final row in mediaCredits) {
      if (row.shows(credit)) return;
    }
    final useBlank =
        mediaCredits.length == 1 &&
        mediaCredits.single.shows(
          const CourseMediaAttribution(author: '', license: ''),
        );
    if (!useBlank) addMediaCredit();
    final row = mediaCredits.last..fill(credit);
    _coverCredit = credit;
    _coverCreditRow = row;
  }

  // ---- Languages

  /// Whether the learning language may take the tag [candidate]: only when
  /// the language code of XP and streaks stays what it is, since a Course's
  /// languages never change.
  bool keepsLearningLanguage(String candidate) =>
      CourseInfoUpdateService.keepsLearningLanguage(course, candidate);

  // ---- Apply

  /// The Course name as typed, checked. Throws an [ArgumentError] whose
  /// message says what is wrong with it.
  String validTitle() => FormalNamePolicy.validatePresentationLabel(
    title.text,
    parameterName: 'courseName',
  );

  /// Whether another of [courses] already has the name [title] (capitals
  /// ignored). The author may go on anyway.
  bool titleTakenBy(String title, Iterable<Course> courses) => courses.any(
    (other) =>
        other.courseId != course.courseId &&
        FormalNamePolicy.comparisonKey(other.title) ==
            FormalNamePolicy.comparisonKey(title),
  );

  /// What the fields come to, with the checked [title] (see [validTitle]).
  CourseInfoSubmission submit(String title) {
    final license = CourseCredits.licenseOf(licenseChoice, customLicense.text);
    if (license.isEmpty) {
      return const CourseInfoRefused(
        message: CourseCredits.customLicenseMissing,
      );
    }
    final String normalizedBuyACoffeeUrl;
    final int? parsedHours;
    final int? parsedMinimumBuild;
    final List<String> parsedKeywords;
    final CoursePublisherContact? parsedContact;
    try {
      normalizedBuyACoffeeUrl = Course.normalizeBuyACoffeeUrl(
        buyACoffeeUrl.text,
      );
      parsedHours = _wholeNumber(estimatedHours.text, 'Estimated study hours');
      parsedMinimumBuild = _wholeNumber(
        minimumAppBuild.text,
        'Minimum QuisquisLingo build',
      );
      parsedKeywords = Course.normalizeKeywords(keywords.text.split(','));
      parsedContact = CoursePublisherContact.fromFields(
        contactWebsite.text,
        contactEmail.text,
      );
      // The model is the one authority on the limits.
      Course.validateDescriptiveMetadata(
        minimumAppBuild: parsedMinimumBuild,
        estimatedStudyHours: parsedHours,
        minimumAge: minimumAge,
        keywords: parsedKeywords,
      );
    } on FormatException catch (error) {
      return CourseInfoRefused(message: error.message);
    }
    final mediaAttributions = <CourseMediaAttribution>[];
    for (final (index, row) in mediaCredits.indexed) {
      final author = row.author.text.trim();
      final mediaLicense = row.license.text.trim();
      // Both identifying fields are required; a row with neither is an
      // untouched blank and is simply dropped.
      if (author.isEmpty && mediaLicense.isEmpty) continue;
      if (author.isEmpty || mediaLicense.isEmpty) {
        mediaCreditError =
            'Each media credit needs both an author and a licence. '
            'Complete row ${index + 1} or clear it.';
        return const CourseInfoRefused();
      }
      final candidate = CourseMediaAttribution(
        author: author,
        license: mediaLicense,
        title: row.title.text.trim(),
        source: row.source.text.trim(),
        appliesTo: row.appliesTo.text.trim(),
      );
      if (mediaAttributions.contains(candidate)) {
        mediaCreditError =
            'Row ${index + 1} repeats an identical media credit.';
        return const CourseInfoRefused();
      }
      mediaAttributions.add(candidate);
    }
    return CourseInfoAccepted((
      title: title,
      authors: [
        for (final row in authors)
          if (row.value case final author?) author,
      ],
      rightsHolders: [
        for (final row in rightsHolders)
          if (row.value case final holder?) holder,
      ],
      mediaAttributions: mediaAttributions,
      license: license,
      derivativePolicy: CourseCredits.policyKeepingStored(
        licenseChoice,
        derivativePolicy,
        storedLicense: course.license,
        storedPolicy: course.derivativeWorksPolicy,
      ),
      allowPageSharing: allowPageSharing,
      privateCourse: privateCourse,
      sourceLanguageTag: sourceTag,
      targetLanguageTag: targetTag,
      targetLanguageNameForLearners: learnerLanguageName.text.trim(),
      variant: variant.text.trim(),
      startLevel: startLevel.text.trim(),
      targetLevel: targetLevel.text.trim(),
      description: description.text.trim(),
      buyACoffeeUrl: normalizedBuyACoffeeUrl,
      estimatedStudyHours: parsedHours,
      minimumAge: minimumAge,
      keywords: parsedKeywords,
      publisherContact: parsedContact,
      minimumAppBuild: parsedMinimumBuild,
      flagCode: flag.flagCode,
      flagImageBase64: flag.flagImageBase64,
      worldFlagId: flag.selectedWorldFlagId,
      coverImage: coverImage,
      maintainerProfileId: maintainerProfileId,
      assignedTeamId: assignedTeamId,
    ));
  }

  static int? _wholeNumber(String text, String label) {
    final value = text.trim();
    if (value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw FormatException('$label must be a whole number.');
    }
    return parsed;
  }

  void dispose() {
    for (final row in authors) {
      row.dispose();
    }
    for (final row in rightsHolders) {
      row.dispose();
    }
    for (final row in mediaCredits) {
      row.dispose();
    }
    title.dispose();
    variant.dispose();
    startLevel.dispose();
    targetLevel.dispose();
    description.dispose();
    buyACoffeeUrl.dispose();
    estimatedHours.dispose();
    keywords.dispose();
    contactWebsite.dispose();
    contactEmail.dispose();
    minimumAppBuild.dispose();
    customLicense.dispose();
    learnerLanguageName.dispose();
  }
}
