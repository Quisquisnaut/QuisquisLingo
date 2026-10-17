import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/controllers/new_course_form.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/models/course_metadata_options.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_language_pair.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/course_kind_choice.dart';

/// Build 272 Revision 3: New Course's form, without its dialog.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NewCourseForm open({CourseWizardBasics? prefill}) {
    final form = NewCourseForm(creator: _creator, prefill: prefill);
    addTearDown(form.dispose);
    return form;
  }

  NewCourseForm filled() => open()
    ..kind = CourseKind.otherLanguage
    ..title.text = 'By hand'
    ..source.text.text = 'English'
    ..target.text.text = 'Italian';

  final operations = CourseLibraryOperations(clock: () => _when);

  group('the form opens', () {
    test('empty, with the creator as Author and New Course\'s defaults', () {
      final form = open();
      expect(form.title.text, isEmpty);
      // Build 275 Revision 0: no kind of Course is chosen at first.
      expect(form.kind, isNull);
      expect(form.source.isEmpty, isTrue);
      expect(form.target.isEmpty, isTrue);
      expect(form.maintainerProfileId, _profileId);
      // The creator's own row: the name on the profile, as Author.
      expect(form.authors.single.name.text, 'Form Author');
      expect(form.authors.single.roles, {'Author'});
      expect(form.rightsHolders.single.name.text, isEmpty);
      expect(form.rightsHolders.single.type, CourseRightsHolderType.person);
      expect(form.licenseChoice, 'All rights reserved');
      expect(form.derivativePolicy, DerivativeWorksPolicy.forbidden);
      expect(form.customLicense.text, isEmpty);
      expect(form.lessonCount.text, '3');
      expect(form.roundsPerLesson.text, '1');
      expect(form.flag, const CourseFlagSelection.automatic());
      expect(form.coverImage, isEmpty);
      expect(form.coverStored, isFalse);
      expect(form.coverCredit, isNull);
      // The Course ID is allocated with the form, for a cover chosen in it.
      expect(form.courseId, isNotEmpty);
      expect(open().courseId, isNot(form.courseId));
    });

    test('with what the Course Wizard\'s first screen held', () {
      final form = open(
        prefill: const CourseWizardBasics(
          title: 'Italian at the bar',
          sourceLanguage: 'English',
          sourceLanguageTag: 'en',
          targetLanguage: 'Venexian',
          targetLanguageTag: 'vec',
          variant: 'Lagoon',
        ),
      );
      expect(form.title.text, 'Italian at the bar');
      // Two languages and no kind: the creator still chooses (Build 275
      // Revision 2: a kind is never worked out from the languages).
      expect(form.kind, isNull);
      expect(form.source.text.text, 'English');
      expect(form.target.text.text, 'Venexian');
      expect(form.variant.text, 'Lagoon');
      // A language typed by hand keeps its tag; a listed one has its own.
      expect(form.target.isHandEntered, isTrue);
      expect(form.target.tag.text, 'vec');
      expect(form.source.isHandEntered, isFalse);
    });
  });

  group('rows, licence and cover', () {
    test('a person added starts as Contributor', () {
      final form = open()..addAuthor();
      expect(form.authors.last.roles, {'Contributor'});
      form.removeAuthor(0);
      expect(form.authors.single.name.text, isEmpty);
      form
        ..addRightsHolder()
        ..removeRightsHolder(0);
      expect(form.rightsHolders, hasLength(1));
    });

    test('a licence of the list brings its policy; Other / Custom license '
        'keeps the policy shown', () {
      final form = open()..chooseLicense('CC BY-SA 4.0');
      expect(form.derivativePolicy, DerivativeWorksPolicy.allowed);
      form.chooseLicense(CourseMetadataOptions.customLicense);
      expect(form.derivativePolicy, DerivativeWorksPolicy.allowed);
      form.chooseLicense('All rights reserved');
      expect(form.derivativePolicy, DerivativeWorksPolicy.forbidden);
      form.chooseLicense(CourseMetadataOptions.customLicense);
      expect(form.derivativePolicy, DerivativeWorksPolicy.forbidden);
    });

    test('a cover once stored stays "stored", also when it is removed', () {
      const credit = CourseMediaAttribution(author: 'Ada', license: 'CC0');
      final form = open()..setCover(_cover, credit);
      expect(form.coverImage, _cover);
      expect(form.coverCredit, credit);
      expect(form.coverStored, isTrue);
      // Its file is in the Course's media folder until the form is closed.
      form.setCover('', null);
      expect(form.coverImage, isEmpty);
      expect(form.coverCredit, isNull);
      expect(form.coverStored, isTrue);
    });
  });

  test('the numbers of Lessons and Rounds must be usable', () {
    final form = open();
    expect(form.countsValid, isTrue);
    form.lessonCount.text = '0';
    expect(form.lessonCountProblem, isNotNull);
    expect(form.countsValid, isFalse);
    form.lessonCount.text = '100';
    expect(form.lessonCountProblem, isNull);
    form.lessonCount.text = '101';
    expect(form.countsValid, isFalse);
    form.lessonCount.text = '2';
    form.roundsPerLesson.text = '21';
    expect(form.roundCountProblem, isNotNull);
    expect(form.countsValid, isFalse);
    form.roundsPerLesson.text = '20';
    expect(form.countsValid, isTrue);
  });

  group('Continue to Editor', () {
    test('needs a name QQL accepts and both languages', () {
      final form = open();
      expect(form.validTitle, throwsArgumentError);
      form.title.text = 'By hand';
      expect(form.validTitle(), 'By hand');
      expect(form.languagesChosen, isFalse);
      // Build 275 Revision 0: without a kind the form says so.
      expect(form.kindProblem, CourseKindChoice.missing);
      expect(
        (form.submit('By hand', operations) as NewCourseRefused).message,
        CourseKindChoice.missing,
      );
      form.kind = CourseKind.otherLanguage;
      expect(form.kindProblem, isNull);
      // Without a language nothing is made and nothing is said: the
      // language fields show what is missing.
      final refused = form.submit('By hand', operations) as NewCourseRefused;
      expect(refused.message, isNull);
      form.source.text.text = 'English';
      expect(form.languagesChosen, isFalse);
      form.target.text.text = 'Italian';
      expect(form.languagesChosen, isTrue);
    });

    test('makes the Draft Course from the fields', () {
      const credit = CourseMediaAttribution(author: 'Ada', license: 'CC0');
      final form = filled()
        ..authors.single.customRoles.text = 'Voice, Author'
        ..addAuthor()
        ..rightsHolders.single.name.text = ' Org '
        ..rightsHolders.single.type = CourseRightsHolderType.organization
        ..variant.text = ' Tuscan '
        ..startLevel.text = ' A1 '
        ..targetLevel.text = ' A2 '
        ..description.text = ' About it '
        ..buyACoffeeUrl.text = ' https://example.org/coffee '
        ..lessonCount.text = ' 2 '
        ..roundsPerLesson.text = '3'
        ..maintainerProfileId = _otherProfileId
        ..chooseLicense('CC BY 4.0')
        ..setCover(_cover, credit);
      form.authors.last.name.text = ' Bo ';

      final course =
          (form.submit('By hand', operations) as NewCourseAccepted).course;
      expect(course.courseId, form.courseId);
      expect(course.title, 'By hand');
      expect(course.sourceLanguage, 'English');
      expect(course.targetLanguage, 'Italian');
      expect(course.sourceLanguageTag, 'en');
      expect(course.targetLanguageTag, 'it');
      expect(course.originType, CourseOriginType.custom);
      expect(course.publicationState, PublicationState.draft);
      expect(course.originalCourseCreator.id, _profileId);
      expect(course.maintainer?.profileId, _otherProfileId);
      expect(course.originalCreatedAtUtc, _when.toIso8601String());
      expect(
        {for (final a in course.authors) a.name: a.roles},
        {
          'Form Author': ['Author', 'Voice'],
          'Bo': ['Contributor'],
        },
      );
      expect(course.rightsHolders.single.name, 'Org');
      expect(
        course.rightsHolders.single.type,
        CourseRightsHolderType.organization,
      );
      expect(course.license, 'CC BY 4.0');
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
      expect(course.languageVariant, 'Tuscan');
      expect(course.startLevel, 'A1');
      expect(course.targetLevel, 'A2');
      expect(course.courseDescription, 'About it');
      expect(course.buyACoffeeUrl, 'https://example.org/coffee');
      expect(course.lessons, hasLength(2));
      expect(course.lessons.every((l) => l.rounds.length == 3), isTrue);
      expect(course.coverImage, _cover);
      expect(course.mediaAttributions, [credit]);
    });

    test('a custom licence needs a text, and keeps the policy chosen', () {
      final form = filled()..chooseLicense(CourseMetadataOptions.customLicense);
      final refused = form.submit('By hand', operations) as NewCourseRefused;
      expect(
        refused.message,
        'Type the custom license, or choose a license from the list.',
      );
      form
        ..customLicense.text = ' My terms '
        ..derivativePolicy = DerivativeWorksPolicy.unspecified;
      final course =
          (form.submit('By hand', operations) as NewCourseAccepted).course;
      expect(course.license, 'My terms');
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.unspecified);
    });

    test('Buy a Coffee must be HTTPS', () {
      final form = filled()..buyACoffeeUrl.text = 'http://example.org';
      final refused = form.submit('By hand', operations) as NewCourseRefused;
      expect(refused.message, isNotNull);
    });
  });

  test('dispose releases every field', () {
    final form = NewCourseForm(creator: _creator)
      ..addAuthor()
      ..addRightsHolder();
    final fields = <TextEditingController>[
      form.title,
      form.source.text,
      form.source.tag,
      form.target.text,
      form.target.tag,
      form.customLicense,
      form.variant,
      form.startLevel,
      form.targetLevel,
      form.description,
      form.buyACoffeeUrl,
      form.lessonCount,
      form.roundsPerLesson,
      for (final row in form.authors) ...[row.name, row.customRoles],
      for (final row in form.rightsHolders) row.name,
    ];
    form.dispose();
    for (final field in fields) {
      expect(() => field.addListener(() {}), throwsFlutterError);
    }
  });
}

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _otherProfileId = '22345678-1234-4234-9234-123456789abc';
const _creator = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Form Author',
);
final _when = DateTime.utc(2026, 10, 12, 9);
const _cover =
    'media:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc.png';
