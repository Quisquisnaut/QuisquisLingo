import 'package:flutter/widgets.dart';

import '../models/course_flag_selection.dart';
import '../models/course_metadata_options.dart';
import '../models/course_models.dart';
import '../services/course_credits.dart';
import '../services/course_library_operations.dart';
import '../services/course_wizard.dart';
import '../services/formal_name_policy.dart';
import '../services/new_course_structure.dart';
import '../services/profile_service.dart';
import '../widgets/language_field.dart';
import 'course_credit_rows.dart';

/// What Continue to Editor in New Course's form comes to.
sealed class NewCourseSubmission {
  const NewCourseSubmission();
}

/// The fields make a Course: the unsaved Draft the Course Editor opens on.
final class NewCourseAccepted extends NewCourseSubmission {
  const NewCourseAccepted(this.course);

  final Course course;
}

/// The fields cannot make a Course. [message] is told to the author;
/// without one the form's own fields already show what is missing (a
/// language that is not chosen).
final class NewCourseRefused extends NewCourseSubmission {
  const NewCourseRefused({this.message});

  final String? message;
}

/// The state of New Course's form: what its fields hold and the Course
/// Continue to Editor makes of them (Build 272 Revision 3; before, one
/// method of the Course Studio screen).
///
/// It shows nothing and stores nothing; the Course is built by
/// [CourseLibraryOperations.newCourse] and saved only when the Course Editor
/// is confirmed. Whoever shows the form disposes it.
class NewCourseForm {
  NewCourseForm({required this.creator, CourseWizardBasics? prefill})
    : title = TextEditingController(text: prefill?.title ?? ''),
      // Build 260 Revision 0: languages come from the list (English names
      // and tags) or are typed by hand. Build 267 Revision 9: Source starts
      // empty, as in the Course Wizard.
      source = LanguageFieldController(name: prefill?.sourceLanguage ?? ''),
      target = LanguageFieldController(name: prefill?.targetLanguage ?? ''),
      // The creator's own row is an Author.
      authors = [
        CourseCreditRow(
          name: creator.displayName,
          roles: {CourseCredits.creatorRole},
        ),
      ],
      rightsHolders = [CourseRightsHolderRow()],
      variant = TextEditingController(text: prefill?.variant ?? ''),
      lessonCount = TextEditingController(
        text: '${NewCourseStructure.defaultLessons}',
      ),
      roundsPerLesson = TextEditingController(
        text: '${NewCourseStructure.defaultRoundsPerLesson}',
      ),
      maintainerProfileId = creator.learnerProfileId {
    if (prefill != null && source.isHandEntered) {
      source.tag.text = prefill.sourceLanguageTag;
    }
    if (prefill != null && target.isHandEntered) {
      target.tag.text = prefill.targetLanguageTag;
    }
  }

  /// The active learner: Original Course Creator and first Author.
  final LearnerProfile creator;

  final TextEditingController title;
  final LanguageFieldController source;
  final LanguageFieldController target;
  String maintainerProfileId;

  final List<CourseCreditRow> authors;
  final List<CourseRightsHolderRow> rightsHolders;

  /// The entry chosen in the licence list.
  String licenseChoice = CourseMetadataOptions.standardLicenses.first;
  final customLicense = TextEditingController();
  DerivativeWorksPolicy derivativePolicy = DerivativeWorksPolicy.forbidden;

  final TextEditingController variant;
  final startLevel = TextEditingController();
  final targetLevel = TextEditingController();
  final description = TextEditingController();
  final buyACoffeeUrl = TextEditingController();
  final TextEditingController lessonCount;
  final TextEditingController roundsPerLesson;
  CourseFlagSelection flag = const CourseFlagSelection.automatic();

  /// Build 255 Revision 7: a cover chosen in the form is stored before the
  /// Course exists, so the Course ID is allocated with the form. The Editor
  /// session of the new Course owns the cover; whoever shows the form
  /// deletes the Course's media folder when the form is cancelled and
  /// [coverStored].
  final String courseId = Course.newCourseId();
  String coverImage = '';
  bool coverStored = false;
  CourseMediaAttribution? coverCredit;

  // ---- Rows

  /// A person added after the creator starts as Contributor.
  void addAuthor() => authors.add(CourseCreditRow());

  void removeAuthor(int index) => authors.removeAt(index).dispose();

  void addRightsHolder() => rightsHolders.add(CourseRightsHolderRow());

  void removeRightsHolder(int index) => rightsHolders.removeAt(index).dispose();

  // ---- Licence and cover

  /// The author picked [choice] in the licence list: a licence that states
  /// its policy brings it; Other / Custom license keeps the policy shown.
  void chooseLicense(String choice) {
    licenseChoice = choice;
    derivativePolicy = CourseCredits.policyAfterChoosing(
      choice,
      derivativePolicy,
    );
  }

  /// The author chose [cover] ('' for none), a picture whose [credit] QQL
  /// knows or does not (null).
  void setCover(String cover, CourseMediaAttribution? credit) {
    coverImage = cover;
    coverCredit = credit;
    coverStored = coverStored || cover.isNotEmpty;
  }

  // ---- Numbers of Lessons and Rounds

  /// Why the number of Lessons cannot be used (1 to 100), or null.
  String? get lessonCountProblem =>
      NewCourseStructure.validateCount(lessonCount.text, maximum: 100);

  /// Why the number of Rounds per Lesson cannot be used (1 to 20), or null.
  String? get roundCountProblem =>
      NewCourseStructure.validateCount(roundsPerLesson.text, maximum: 20);

  /// Continue to Editor is offered only with usable numbers.
  bool get countsValid =>
      lessonCountProblem == null && roundCountProblem == null;

  // ---- Continue to Editor

  /// The Course title as typed, checked. Throws an [ArgumentError] whose
  /// message says what is wrong with it.
  String validTitle() => FormalNamePolicy.validatePresentationLabel(
    title.text,
    parameterName: 'courseName',
  );

  /// Whether both languages are chosen; their fields show what is missing.
  bool get languagesChosen => source.choice != null && target.choice != null;

  /// What the fields come to, with the checked [title] (see [validTitle]).
  /// [operations] builds the Course (its clock stamps it).
  NewCourseSubmission submit(String title, CourseLibraryOperations operations) {
    final sourceLanguage = source.choice;
    final targetLanguage = target.choice;
    if (sourceLanguage == null || targetLanguage == null) {
      return const NewCourseRefused();
    }
    final license = CourseCredits.licenseOf(licenseChoice, customLicense.text);
    if (license.isEmpty) {
      return const NewCourseRefused(
        message: CourseCredits.customLicenseMissing,
      );
    }
    final String normalizedBuyACoffeeUrl;
    try {
      normalizedBuyACoffeeUrl = Course.normalizeBuyACoffeeUrl(
        buyACoffeeUrl.text,
      );
    } on FormatException catch (error) {
      return NewCourseRefused(message: error.message);
    }
    return NewCourseAccepted(
      operations.newCourse(
        creator: creator,
        maintainerProfileId: maintainerProfileId,
        title: title,
        sourceLanguage: sourceLanguage.name,
        targetLanguage: targetLanguage.name,
        sourceLanguageTag: sourceLanguage.tag,
        targetLanguageTag: targetLanguage.tag,
        credits: [
          for (final row in authors)
            (
              name: row.name.text,
              roles: row.roles,
              customRoles: row.customRoles.text,
            ),
        ],
        license: license,
        derivativeWorksPolicy: CourseCredits.policyOf(
          licenseChoice,
          derivativePolicy,
        ),
        rightsHolders: [
          for (final row in rightsHolders)
            (type: row.type, name: row.name.text),
        ],
        languageVariant: variant.text.trim(),
        startLevel: startLevel.text.trim(),
        targetLevel: targetLevel.text.trim(),
        courseDescription: description.text.trim(),
        buyACoffeeUrl: normalizedBuyACoffeeUrl,
        flag: flag,
        lessonCount: int.parse(lessonCount.text.trim()),
        roundsPerLesson: int.parse(roundsPerLesson.text.trim()),
        courseId: courseId,
        coverImage: coverImage,
        mediaAttributions: [?coverCredit],
      ),
    );
  }

  void dispose() {
    title.dispose();
    source.dispose();
    target.dispose();
    for (final row in authors) {
      row.dispose();
    }
    for (final row in rightsHolders) {
      row.dispose();
    }
    variant.dispose();
    startLevel.dispose();
    targetLevel.dispose();
    description.dispose();
    buyACoffeeUrl.dispose();
    customLicense.dispose();
    lessonCount.dispose();
    roundsPerLesson.dispose();
  }
}
