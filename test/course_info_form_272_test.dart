import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/controllers/course_info_form.dart';
import 'package:quisquislingo_app/models/course_metadata_options.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_info_update_service.dart';

/// Build 272 Revision 1: the Course Info Editor's form, without its dialog.
void main() {
  group('the form opens on a Course', () {
    test('with the Course\'s values', () {
      final form = CourseInfoForm(_full(), backupsKept: 10);
      addTearDown(form.dispose);
      expect(form.title.text, 'Full Course');
      expect(form.maintainerProfileId, _profileId);
      expect(form.assignedTeamId, isNull);
      expect(form.variant.text, 'Tuscan');
      expect(form.startLevel.text, 'A1');
      expect(form.targetLevel.text, 'A2');
      expect(form.description.text, 'About it');
      expect(form.buyACoffeeUrl.text, 'https://example.org/coffee');
      expect(form.estimatedHours.text, '12');
      expect(form.minimumAge, 9);
      expect(form.keywords.text, 'bar, travel');
      expect(form.contactWebsite.text, 'https://example.org');
      expect(form.contactEmail.text, 'ann@example.org');
      expect(form.minimumAppBuild.text, '270000');
      expect(form.learnerLanguageName.text, 'italiano');
      expect(form.defaultLearnerLanguageName, 'Italian');
      expect(form.sourceTag, 'en');
      expect(form.targetTag, 'it');
      expect(form.licenseChoice, 'CC BY 4.0');
      // The Custom license field is empty for a licence of the list.
      expect(form.customLicense.text, isEmpty);
      expect(form.derivativePolicy, DerivativeWorksPolicy.unspecified);
      expect(form.allowPageSharing, isFalse);
      expect(form.privateCourse, isTrue);
      expect(form.coverImage, 'media:${'a' * 64}.png');
      expect(form.backupsKept, 10);
      expect(form.initialBackupsKept, 10);
      expect(form.mediaCreditError, isNull);

      expect(form.authors.single.name.text, 'Ann');
      expect(form.authors.single.roles, {'Author', 'Editor'});
      expect(form.authors.single.customRoles.text, 'Voice');
      expect(form.rightsHolders.single.name.text, 'Org');
      expect(
        form.rightsHolders.single.type,
        CourseRightsHolderType.organization,
      );
      expect(form.mediaCredits.single.shows(_someone), isTrue);
    });

    test('with one blank row in each empty list', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      expect(form.authors.single.name.text, isEmpty);
      expect(form.authors.single.roles, {'Contributor'});
      expect(form.rightsHolders.single.name.text, isEmpty);
      expect(form.rightsHolders.single.type, CourseRightsHolderType.person);
      expect(form.mediaCredits.single.shows(_blank), isTrue);
      expect(form.licenseChoice, 'All rights reserved');
      expect(form.backupsKept, isNull);
      // A licence outside the list shows as Other / Custom license.
      final custom = CourseInfoForm(
        Course.fromJson({..._plain().toJson(), 'license': 'My terms'}),
      );
      addTearDown(custom.dispose);
      expect(custom.licenseChoice, CourseMetadataOptions.customLicense);
      expect(custom.customLicense.text, 'My terms');
    });
  });

  group('rows', () {
    test(
      'a credit row is added as Contributor and removed with its fields',
      () {
        final form = CourseInfoForm(_full());
        addTearDown(form.dispose);
        form.addAuthor();
        expect(form.authors, hasLength(2));
        expect(form.authors.last.roles, {'Contributor'});
        final removed = form.authors.first;
        form.removeAuthor(0);
        expect(form.authors.single.name.text, isEmpty);
        expect(() => removed.name.addListener(() {}), throwsFlutterError);
      },
    );

    test('a Rights Holder row is added as a person', () {
      final form = CourseInfoForm(_full());
      addTearDown(form.dispose);
      form.addRightsHolder();
      expect(form.rightsHolders.last.type, CourseRightsHolderType.person);
      form.removeRightsHolder(0);
      expect(form.rightsHolders.single.name.text, isEmpty);
    });

    test('removing a media credit row takes its message away', () {
      final form = CourseInfoForm(_full());
      addTearDown(form.dispose);
      form.addMediaCredit();
      form.mediaCredits.last.author.text = 'Half';
      expect(form.submit('Full Course'), isA<CourseInfoRefused>());
      expect(form.mediaCreditError, isNotNull);
      form.removeMediaCredit(1);
      expect(form.mediaCreditError, isNull);
      expect(form.mediaCredits.single.shows(_someone), isTrue);
    });
  });

  group('the cover\'s credit', () {
    test('takes the blank row when the list has nothing else', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      form.setCover(_cover, _qql);
      expect(form.coverImage, _cover);
      expect(form.mediaCredits.single.shows(_qql), isTrue);
    });

    test('gets a row of its own after the author\'s credits', () {
      final form = CourseInfoForm(_full());
      addTearDown(form.dispose);
      form.setCover(_cover, _qql);
      expect(form.mediaCredits, hasLength(2));
      expect(form.mediaCredits.first.shows(_someone), isTrue);
      expect(form.mediaCredits.last.shows(_qql), isTrue);
    });

    test('leaves with the next cover while its row is as QQL wrote it', () {
      final form = CourseInfoForm(_full());
      addTearDown(form.dispose);
      form.setCover(_cover, _qql);
      form.setCover(_cover, _ada);
      expect(form.mediaCredits, hasLength(2));
      expect(form.mediaCredits.last.shows(_ada), isTrue);
      // No cover, or a cover of unknown origin: the credit goes.
      form.setCover('', null);
      expect(form.mediaCredits.single.shows(_someone), isTrue);
    });

    test('stays when the author changed its row', () {
      final form = CourseInfoForm(_full());
      addTearDown(form.dispose);
      form.setCover(_cover, _ada);
      form.mediaCredits.last.title.text = 'Portrait';
      form.setCover(_cover, _qql);
      expect(form.mediaCredits, hasLength(3));
      expect(form.mediaCredits[1].title.text, 'Portrait');
      expect(form.mediaCredits[2].shows(_qql), isTrue);
    });

    test('is not written twice, and a row the author wrote is never taken', () {
      final form = CourseInfoForm(_full());
      addTearDown(form.dispose);
      // The author already credits the same picture.
      form.setCover(_cover, _someone);
      expect(form.mediaCredits.single.shows(_someone), isTrue);
      form.setCover('', null);
      expect(form.mediaCredits.single.shows(_someone), isTrue);
    });

    test('alone in the list, it is emptied instead of removed', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      form.setCover(_cover, _qql);
      form.setCover('', null);
      expect(form.coverImage, isEmpty);
      expect(form.mediaCredits.single.shows(_blank), isTrue);
    });

    test('a row the author removed is not looked for again', () {
      final form = CourseInfoForm(_full());
      addTearDown(form.dispose);
      form.setCover(_cover, _qql);
      form.removeMediaCredit(1);
      form.setCover(_cover, _ada);
      expect(form.mediaCredits, hasLength(2));
      expect(form.mediaCredits.first.shows(_someone), isTrue);
      expect(form.mediaCredits.last.shows(_ada), isTrue);
    });

    test('a new cover takes the Media credits message away', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      form.mediaCredits.single.author.text = 'Half';
      form.submit('Plain Course');
      expect(form.mediaCreditError, isNotNull);
      form.setCover(_cover, null);
      expect(form.mediaCreditError, isNull);
    });
  });

  group('the licence', () {
    test('a licence of the list brings its policy; a custom one keeps the '
        'policy shown', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      // A Course that stores no policy has "unspecified".
      expect(form.derivativePolicy, DerivativeWorksPolicy.unspecified);
      form.chooseLicense('All rights reserved');
      expect(form.derivativePolicy, DerivativeWorksPolicy.forbidden);
      form.chooseLicense('CC0 1.0');
      expect(form.licenseChoice, 'CC0 1.0');
      expect(form.derivativePolicy, DerivativeWorksPolicy.allowed);
      form.chooseLicense(CourseMetadataOptions.customLicense);
      expect(form.derivativePolicy, DerivativeWorksPolicy.allowed);
    });

    test('a custom licence without a text is refused with the reason', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      form.chooseLicense(CourseMetadataOptions.customLicense);
      form.customLicense.text = '  ';
      final refused = form.submit('Plain Course') as CourseInfoRefused;
      expect(
        refused.message,
        'Type the custom license, or choose a license from the list.',
      );
      expect(form.mediaCreditError, isNull);
      form.customLicense.text = ' My terms ';
      form.derivativePolicy = DerivativeWorksPolicy.unspecified;
      final change = (form.submit('Plain Course') as CourseInfoAccepted).change;
      expect(change.license, 'My terms');
      expect(change.derivativePolicy, DerivativeWorksPolicy.unspecified);
    });

    test('left as stored, it keeps the policy the Course stores', () {
      final form = CourseInfoForm(_full());
      addTearDown(form.dispose);
      // CC BY 4.0 allows derivative works; this Course stores "unspecified".
      var change = (form.submit('Full Course') as CourseInfoAccepted).change;
      expect(change.license, 'CC BY 4.0');
      expect(change.derivativePolicy, DerivativeWorksPolicy.unspecified);
      form.chooseLicense('CC BY-SA 4.0');
      change = (form.submit('Full Course') as CourseInfoAccepted).change;
      expect(change.derivativePolicy, DerivativeWorksPolicy.allowed);
    });
  });

  group('Apply', () {
    test('gives the change as the fields read, trimmed', () {
      final form = CourseInfoForm(_full(), backupsKept: 5);
      addTearDown(form.dispose);
      form.authors.single.customRoles.text = ' Sound , Author';
      form.addAuthor();
      form.authors.last.name.text = ' Bo ';
      form.authors.last.roles.clear();
      form.addAuthor();
      form.rightsHolders.single.name.text = ' New Org ';
      form.addRightsHolder();
      form.variant.text = ' Roman ';
      form.startLevel.text = ' A2 ';
      form.targetLevel.text = ' B1 ';
      form.description.text = ' New words ';
      form.buyACoffeeUrl.text = ' https://example.org/tea ';
      form.estimatedHours.text = ' 20 ';
      form.minimumAge = 13;
      form.keywords.text = ' bar , bar, food ';
      form.contactWebsite.text = '';
      form.contactEmail.text = '';
      form.minimumAppBuild.text = '';
      form.learnerLanguageName.text = ' taliano ';
      form.allowPageSharing = true;
      form.privateCourse = false;
      form.maintainerProfileId = _otherProfileId;
      form.assignedTeamId = 'team-1';
      form.backupsKept = 20;

      final change = (form.submit('New name') as CourseInfoAccepted).change;
      expect(change.title, 'New name');
      expect(
        {for (final a in change.authors) a.name: a.roles},
        {
          'Ann': ['Author', 'Editor', 'Sound'],
          'Bo': ['Contributor'],
        },
      );
      expect(change.rightsHolders.single.name, 'New Org');
      expect(change.mediaAttributions, [_someone]);
      expect(change.variant, 'Roman');
      expect(change.startLevel, 'A2');
      expect(change.targetLevel, 'B1');
      expect(change.description, 'New words');
      expect(change.buyACoffeeUrl, 'https://example.org/tea');
      expect(change.estimatedStudyHours, 20);
      expect(change.minimumAge, 13);
      expect(change.keywords, ['bar', 'food']);
      expect(change.publisherContact, isNull);
      expect(change.minimumAppBuild, isNull);
      expect(change.targetLanguageNameForLearners, 'taliano');
      expect(change.sourceLanguageTag, 'en');
      expect(change.targetLanguageTag, 'it');
      expect(change.allowPageSharing, isTrue);
      expect(change.privateCourse, isFalse);
      expect(change.coverImage, 'media:${'a' * 64}.png');
      expect(change.flagCode, form.flag.flagCode);
      expect(change.worldFlagId, form.flag.selectedWorldFlagId);
      expect(change.maintainerProfileId, _otherProfileId);
      expect(change.assignedTeamId, 'team-1');
      // The backups kept are the device's, not the Course's.
      expect(form.backupsKept, 20);
      expect(form.initialBackupsKept, 5);
    });

    test('says what cannot be stored', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      String? refusal() =>
          (form.submit('Plain Course') as CourseInfoRefused).message;

      form.estimatedHours.text = 'many';
      expect(refusal(), 'Estimated study hours must be a whole number.');
      form.estimatedHours.text = '2000';
      expect(
        refusal(),
        'course.estimatedStudyHours must be a whole number from 1 to 1000.',
      );
      form.estimatedHours.text = '';
      form.minimumAppBuild.text = 'new';
      expect(refusal(), 'Minimum QuisquisLingo build must be a whole number.');
      form.minimumAppBuild.text = '';
      form.buyACoffeeUrl.text = 'http://example.org';
      expect(refusal(), isNotNull);
      form.buyACoffeeUrl.text = '';
      form.keywords.text = List.filled(
        21,
        'k',
      ).indexed.map((entry) => 'k${entry.$1}').join(',');
      expect(refusal(), 'course.keywords accepts at most 20 keywords.');
      form.keywords.text = '';
      form.contactWebsite.text = 'http://example.org';
      expect(refusal(), isNotNull);
      form.contactWebsite.text = '';
      expect(form.submit('Plain Course'), isA<CourseInfoAccepted>());
    });

    test('a media credit needs an author and a licence, each credit once', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      CourseInfoRefused refused() =>
          form.submit('Plain Course') as CourseInfoRefused;

      form.mediaCredits.single.license.text = 'CC0';
      expect(refused().message, isNull);
      expect(
        form.mediaCreditError,
        'Each media credit needs both an author and a licence. '
        'Complete row 1 or clear it.',
      );
      form.mediaCredits.single.author.text = ' Ada ';
      form.addMediaCredit();
      form.addMediaCredit();
      form.mediaCredits[2]
        ..author.text = 'Ada'
        ..license.text = ' CC0';
      expect(refused().message, isNull);
      // Rows are counted as the author sees them, blank ones included.
      expect(form.mediaCreditError, 'Row 3 repeats an identical media credit.');
      form.mediaCredits[2].title.text = 'Another picture';
      final change = (form.submit('Plain Course') as CourseInfoAccepted).change;
      expect(change.mediaAttributions, const [
        CourseMediaAttribution(author: 'Ada', license: 'CC0'),
        CourseMediaAttribution(
          author: 'Ada',
          license: 'CC0',
          title: 'Another picture',
        ),
      ]);
    });
  });

  group('the Course name', () {
    test('is checked as QQL checks every name', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      form.title.text = 'Renamed';
      expect(form.validTitle(), 'Renamed');
      // Spaces before or after a name are refused, not removed.
      form.title.text = '  Renamed  ';
      expect(form.validTitle, throwsArgumentError);
      form.title.text = '   ';
      expect(form.validTitle, throwsArgumentError);
    });

    test('is taken when another Course has it, whatever the capitals', () {
      final form = CourseInfoForm(_plain());
      addTearDown(form.dispose);
      final others = [
        _plain(),
        Course.fromJson({
          ..._plain().toJson(),
          'courseId': 'another',
          'title': 'Taken Name',
        }),
      ];
      expect(form.titleTakenBy('taken name', others), isTrue);
      // The Course's own name is not another Course's.
      expect(form.titleTakenBy('Plain Course', others), isFalse);
      expect(form.titleTakenBy('Free', others), isFalse);
    });
  });

  test('a learning language tag is kept only while the language of XP and '
      'streaks stays', () {
    final form = CourseInfoForm(_plain());
    addTearDown(form.dispose);
    expect(form.keepsLearningLanguage('it'), isTrue);
    expect(form.keepsLearningLanguage('es'), isFalse);
    expect(CourseInfoUpdateService.keepsLearningLanguage(_plain(), ''), isTrue);
  });

  test('dispose releases every field', () {
    final form = CourseInfoForm(_full())
      ..addAuthor()
      ..addRightsHolder()
      ..addMediaCredit();
    final fields = <TextEditingController>[
      form.title,
      form.variant,
      form.startLevel,
      form.targetLevel,
      form.description,
      form.buyACoffeeUrl,
      form.estimatedHours,
      form.keywords,
      form.contactWebsite,
      form.contactEmail,
      form.minimumAppBuild,
      form.customLicense,
      form.learnerLanguageName,
      for (final row in form.authors) ...[row.name, row.customRoles],
      for (final row in form.rightsHolders) row.name,
      for (final row in form.mediaCredits) ...[
        row.author,
        row.license,
        row.title,
        row.source,
        row.appliesTo,
      ],
    ];
    form.dispose();
    for (final field in fields) {
      expect(() => field.addListener(() {}), throwsFlutterError);
    }
  });
}

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _otherProfileId = '22345678-1234-4234-9234-123456789abc';
const _cover =
    'media:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc.png';
const _blank = CourseMediaAttribution(author: '', license: '');
const _someone = CourseMediaAttribution(
  author: 'Someone',
  license: 'CC0',
  appliesTo: 'Lesson icons',
);
const _qql = CourseMediaAttribution(
  author: 'QuisquisLingo',
  license: 'Original QuisquisLingo asset',
  title: 'Red apple',
  source: 'QuisquisLingo Flat Image Bank',
  appliesTo: 'Course cover',
);
const _ada = CourseMediaAttribution(
  author: 'Ada',
  license: 'CC BY 4.0',
  appliesTo: 'Course cover',
);

Course _plain() => Course(
  courseId: 'form-plain',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Form Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Plain Course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: const [],
);

Course _full() => Course.fromJson({
  ..._plain().toJson(),
  'courseId': 'form-full',
  'title': 'Full Course',
  'sourceLanguageTag': 'en',
  'targetLanguageTag': 'it',
  'targetLanguageNameForLearners': 'italiano',
  'languageVariant': 'Tuscan',
  'startLevel': 'A1',
  'targetLevel': 'A2',
  'courseDescription': 'About it',
  'buyACoffeeUrl': 'https://example.org/coffee',
  'estimatedStudyHours': 12,
  'minimumAge': 9,
  'keywords': ['bar', 'travel'],
  'publisherContact': {
    'websiteUrl': 'https://example.org',
    'email': 'ann@example.org',
  },
  'minimumAppBuild': 270000,
  'license': 'CC BY 4.0',
  'derivativeWorksPolicy': 'unspecified',
  'allowPageSharing': false,
  'temporarySample': true,
  'coverImage': 'media:${'a' * 64}.png',
  'authors': [
    {
      'name': 'Ann',
      'roles': ['Editor', 'Voice', 'Author'],
    },
  ],
  'rightsHolders': [
    {'type': 'organization', 'name': 'Org'},
  ],
  'mediaAttributions': [_someone.toJson()],
});
