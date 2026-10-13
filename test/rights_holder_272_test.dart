import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/models/course_metadata_options.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_credits.dart';
import 'package:quisquislingo_app/services/course_import_check.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/publisher_course_export.dart';

/// Build 272 Revision 14 (owner decisions of 13 October 2026): a license
/// names its Rights Holder. New Course and the Course Wizard name the
/// author of the form; the Course Audit warns when a license has none;
/// Export as Publisher Course refuses without one; CC0 1.0 needs none.
void main() {
  const appName = '12345678-1234-4234-9234-123456789abc';
  const person = CourseRightsHolderType.person;

  CourseAuthor author(String name, [List<String> roles = const ['Author']]) =>
      CourseAuthor(name: name, roles: roles);

  List<String> names(List<CourseRightsHolder> holders) => [
    for (final holder in holders) holder.name,
  ];

  group('whether a license asks for a Rights Holder', () {
    test('a license that keeps rights does; CC0 1.0 and none do not', () {
      for (final license in CourseMetadataOptions.standardLicenses) {
        expect(
          CourseCredits.needsRightsHolder(license),
          license != 'CC0 1.0',
          reason: license,
        );
      }
      expect(CourseCredits.needsRightsHolder('Ask me first'), isTrue);
      expect(CourseCredits.needsRightsHolder(''), isFalse);
      expect(CourseCredits.needsRightsHolder('   '), isFalse);
      expect(CourseCredits.needsRightsHolder(' CC0 1.0 '), isFalse);
      expect(
        CourseMetadataOptions.standardLicenses,
        contains(CourseCredits.rightsGivenUp),
      );
    });
  });

  group('the Rights Holder a new Course names by default', () {
    test('the people credited as Author, as persons', () {
      final holders = CourseCredits.defaultRightsHolders([
        author('Maria Rossi'),
        author('Luca', const ['Illustrator']),
        author(' Anna Bianchi ', const ['Author', 'Editor']),
      ], 'All rights reserved');
      expect(names(holders), ['Maria Rossi', 'Anna Bianchi']);
      expect(holders.every((holder) => holder.type == person), isTrue);
    });

    test('a person credited in two rows is one Rights Holder', () {
      expect(
        names(
          CourseCredits.defaultRightsHolders([
            author('Maria Rossi'),
            author('Luca', const ['Illustrator']),
            author('Maria Rossi', const ['Author', 'Editor']),
          ], 'All rights reserved'),
        ),
        ['Maria Rossi'],
      );
    });

    test('the first person named when nobody is credited as Author', () {
      expect(
        names(
          CourseCredits.defaultRightsHolders([
            author('Luca', const ['Illustrator']),
            author('Gina', const ['Reviewer']),
          ], 'CC BY 4.0'),
        ),
        ['Luca'],
      );
    });

    test('nobody when no author is named, or the license needs none', () {
      expect(
        CourseCredits.defaultRightsHolders(const [], 'All rights reserved'),
        isEmpty,
      );
      expect(
        CourseCredits.defaultRightsHolders([author('Maria Rossi')], 'CC0 1.0'),
        isEmpty,
      );
      expect(
        CourseCredits.defaultRightsHolders([author('Maria Rossi')], ''),
        isEmpty,
      );
    });

    test('what the form names comes first', () {
      const school = CourseRightsHolder(
        type: CourseRightsHolderType.organization,
        name: 'Scuola Verde',
      );
      expect(
        CourseCredits.rightsHoldersOfNewCourse(
          named: const [school],
          authors: [author('Maria Rossi')],
          license: 'CC BY 4.0',
        ),
        const [school],
      );
      expect(
        names(
          CourseCredits.rightsHoldersOfNewCourse(
            named: const [],
            authors: [author('Maria Rossi')],
            license: 'CC BY 4.0',
          ),
        ),
        ['Maria Rossi'],
      );
    });

    test('the main authors: credited as Author, else the first named', () {
      List<String> main(List<CourseAuthor> authors) => [
        for (final found in CourseCredits.mainAuthors(authors)) found.name,
      ];
      expect(
        main([
          author('Luca', const ['Illustrator']),
          author('Maria Rossi'),
          author('Anna Bianchi', const ['Editor', 'Author']),
        ]),
        ['Maria Rossi', 'Anna Bianchi'],
      );
      expect(
        main([
          author('  ', const ['Author']),
          author('Luca', const ['Illustrator']),
          author('Gina', const ['Reviewer']),
        ]),
        ['Luca'],
      );
      expect(main(const []), isEmpty);
    });

    test('two lists of Rights Holders are the same by type and name', () {
      const a = CourseRightsHolder(type: person, name: 'Ada');
      const b = CourseRightsHolder(type: person, name: 'Ada');
      const org = CourseRightsHolder(
        type: CourseRightsHolderType.organization,
        name: 'Ada',
      );
      expect(CourseCredits.sameRightsHolders(const [a], const [b]), isTrue);
      expect(CourseCredits.sameRightsHolders(const [a], const [org]), isFalse);
      expect(CourseCredits.sameRightsHolders(const [a], const []), isFalse);
      expect(CourseCredits.sameRightsHolders(const [], const []), isTrue);
    });
  });

  group('New Course', () {
    final ops = CourseLibraryOperations(
      clock: () => DateTime.utc(2026, 10, 13),
    );
    // The name this person uses in the app is not the name they sign with.
    const creator = LearnerProfile(
      learnerProfileId: appName,
      displayName: 'mari_88',
    );

    Course create({
      String authorName = 'Maria Rossi',
      String license = 'All rights reserved',
      List<NewCourseRightsHolder> rightsHolders = const [],
    }) => ops.newCourse(
      creator: creator,
      maintainerProfileId: appName,
      title: 'Italian at the bar',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      credits: [
        (name: authorName, roles: const {'Author'}, customRoles: ''),
        (name: 'Luca', roles: const {'Illustrator'}, customRoles: ''),
      ],
      license: license,
      derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
      rightsHolders: rightsHolders,
      languageVariant: '',
      startLevel: '',
      targetLevel: '',
      courseDescription: '',
      buyACoffeeUrl: '',
      flag: const CourseFlagSelection.automatic(),
      lessonCount: 1,
      roundsPerLesson: 1,
    );

    test('names the Author of the form, not the name used in the app', () {
      final course = create();
      expect(names(course.rightsHolders), ['Maria Rossi']);
      expect(course.rightsHolders.single.type, person);
      expect(course.originalCourseCreator.displayName, 'mari_88');
    });

    test('keeps the Rights Holder the form names', () {
      final course = create(
        rightsHolders: [
          (type: CourseRightsHolderType.organization, name: 'Scuola Verde'),
        ],
      );
      expect(names(course.rightsHolders), ['Scuola Verde']);
      expect(
        course.rightsHolders.single.type,
        CourseRightsHolderType.organization,
      );
    });

    test('a blank row is no name: the default applies', () {
      final course = create(rightsHolders: [(type: person, name: '   ')]);
      expect(names(course.rightsHolders), ['Maria Rossi']);
    });

    test('names nobody for CC0 1.0', () {
      expect(create(license: 'CC0 1.0').rightsHolders, isEmpty);
    });

    test('its Audit has no Rights Holder warning', () {
      final codes = [
        for (final issue in CourseAuditService().auditCourse(create()).issues)
          issue.code,
      ];
      expect(codes, isNot(contains(AuditCode.licenseRightsHolderMissing.code)));
    });

    test('the Course Wizard starts with the name it has, the creator’s', () {
      final course = ops.newWizardCourse(
        creator: creator,
        title: 'Italian at the bar',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
      );
      expect(names(course.rightsHolders), ['mari_88']);
    });
  });

  group('the Course Wizard’s credits', () {
    final ops = CourseLibraryOperations(
      clock: () => DateTime.utc(2026, 10, 13),
    );
    const creator = LearnerProfile(
      learnerProfileId: appName,
      displayName: 'mari_88',
    );
    Course started() => ops.newWizardCourse(
      creator: creator,
      title: 'Italian at the bar',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
    );

    CourseWizardCredits credits(
      Course course, {
      List<CourseAuthor>? authors,
      String? license,
      List<CourseRightsHolder>? rightsHolders,
    }) {
      final now = CourseWizardCredits.of(course);
      return CourseWizardCredits(
        authors: authors ?? now.authors,
        license: license ?? now.license,
        derivativePolicy: now.derivativePolicy,
        rightsHolders: rightsHolders ?? now.rightsHolders,
        buyACoffeeUrl: now.buyACoffeeUrl,
        publisherContact: now.publisherContact,
      );
    }

    test('the Rights Holder follows the Author the author writes', () {
      final course = started();
      final signed = credits(
        course,
        authors: [author('Maria Rossi')],
      ).applyTo(course);
      expect(names(signed.rightsHolders), ['Maria Rossi']);

      // And again, as long as nobody wrote the Rights Holder by hand.
      final again = credits(
        signed,
        authors: [author('Maria Rossi'), author('Anna Bianchi')],
      ).applyTo(signed);
      expect(names(again.rightsHolders), ['Maria Rossi', 'Anna Bianchi']);
    });

    test('a Rights Holder the author wrote stays', () {
      final course = started();
      const school = CourseRightsHolder(
        type: CourseRightsHolderType.organization,
        name: 'Scuola Verde',
      );
      final named = credits(
        course,
        rightsHolders: const [school],
      ).applyTo(course);
      final renamed = credits(
        named,
        authors: [author('Maria Rossi')],
      ).applyTo(named);
      expect(names(renamed.rightsHolders), ['Scuola Verde']);
    });

    test('no Rights Holder left empty: the Author is named again', () {
      final course = started();
      final cleared = credits(course, rightsHolders: const []).applyTo(course);
      expect(names(cleared.rightsHolders), ['mari_88']);
    });

    test('CC0 1.0 needs none; another license names the Author again', () {
      final course = started();
      final free = credits(course, license: 'CC0 1.0').applyTo(course);
      expect(free.rightsHolders, isEmpty);
      final back = credits(free, license: 'CC BY 4.0').applyTo(free);
      expect(names(back.rightsHolders), ['mari_88']);
    });

    test('no author at all: nobody to name', () {
      final course = started();
      final nobody = credits(course, authors: const []).applyTo(course);
      expect(nobody.rightsHolders, isEmpty);
    });

    test('the form shows the Author’s default as rows left empty, and a '
        'Rights Holder written by hand as written', () {
      final course = started();
      expect(names(course.rightsHolders), ['mari_88']);
      expect(CourseCredits.rightsHoldersByHand(course), isEmpty);
      expect(CourseWizardCredits.of(course).rightsHolders, isEmpty);

      final named = credits(
        course,
        rightsHolders: const [
          CourseRightsHolder(
            type: CourseRightsHolderType.organization,
            name: 'Scuola Verde',
          ),
        ],
      ).applyTo(course);
      final shown = CourseWizardCredits.of(named).rightsHolders;
      expect(names(shown), ['Scuola Verde']);
      expect(shown.single.type, CourseRightsHolderType.organization);

      // The same name as the Author, but an organization: written by hand.
      final org = credits(
        course,
        rightsHolders: const [
          CourseRightsHolder(
            type: CourseRightsHolderType.organization,
            name: 'mari_88',
          ),
        ],
      ).applyTo(course);
      expect(names(CourseWizardCredits.of(org).rightsHolders), ['mari_88']);
    });

    test('the form read and stored again changes nothing', () {
      // The fault found before the review: the form showed the default as a
      // row, so a save that stayed on the step left the earlier name in the
      // row, and the next save stored it as a Rights Holder written by hand.
      String json(Course course) => jsonEncode(course.toJson());
      final course = started();
      final fields = credits(course, authors: [author('Maria Rossi')]);
      final signed = fields.applyTo(course);
      expect(names(signed.rightsHolders), ['Maria Rossi']);
      // The same fields, stored a second time.
      expect(json(fields.applyTo(signed)), json(signed));
      // The step opened again and stored untouched.
      expect(
        json(CourseWizardCredits.of(signed).applyTo(signed)),
        json(signed),
      );
      expect(
        json(CourseWizardCredits.of(course).applyTo(course)),
        json(course),
      );
    });

    group('a Course stored without a Rights Holder', () {
      // Made before a new Course named one, or emptied in Course Info
      // Editor. Found by the independent review: opening the step looked
      // like an unsaved change, and Next stored a Rights Holder nobody had
      // touched.
      String json(Course course) => jsonEncode(course.toJson());
      Course older({String license = 'All rights reserved'}) =>
          Course.fromJson({
            ...started().toJson(),
            'license': license,
            'rightsHolders': <Object>[],
          });

      test('keeps none while the step leaves authors and license as they '
          'are', () {
        final course = older();
        expect(course.rightsHolders, isEmpty);
        expect(
          names(
            CourseCredits.defaultRightsHolders(course.authors, course.license),
          ),
          ['mari_88'],
        );
        expect(
          json(CourseWizardCredits.of(course).applyTo(course)),
          json(course),
        );
        // Another field of the step changes: still no Rights Holder.
        final now = CourseWizardCredits.of(course);
        final coffee = CourseWizardCredits(
          authors: now.authors,
          license: now.license,
          derivativePolicy: now.derivativePolicy,
          rightsHolders: now.rightsHolders,
          buyACoffeeUrl: 'https://buymeacoffee.com/maria',
          publisherContact: now.publisherContact,
        ).applyTo(course);
        expect(coffee.buyACoffeeUrl, 'https://buymeacoffee.com/maria');
        expect(coffee.rightsHolders, isEmpty);
      });

      test('roles stored in another order are no change of the credits', () {
        // Found by the second review: a form writes the roles in its own
        // order, and that alone named the Author.
        final course = Course.fromJson({
          ...older().toJson(),
          'authors': [
            {
              'name': 'Ann',
              'roles': ['Editor', 'Voice', 'Author', 'Subtitles'],
            },
          ],
        });
        final asWritten = CourseCredits.authorsAsFormsWrite(course.authors);
        expect(asWritten.single.roles, [
          'Author',
          'Editor',
          'Voice',
          'Subtitles',
        ]);
        expect(
          CourseCredits.sameAuthors(course.authors, asWritten),
          isFalse,
          reason: 'the form does reorder them',
        );
        final passed = credits(course, authors: asWritten).applyTo(course);
        expect(passed.authors.single.roles, asWritten.single.roles);
        expect(passed.rightsHolders, isEmpty);
        // A role really added is a change.
        final added = credits(
          course,
          authors: [
            CourseAuthor(
              name: 'Ann',
              roles: [...asWritten.single.roles, 'Teacher'],
            ),
          ],
        ).applyTo(course);
        expect(names(added.rightsHolders), ['Ann']);
        // A row without a name is not written.
        expect(
          CourseCredits.authorsAsFormsWrite([author('  '), author('Bo')]),
          hasLength(1),
        );
      });

      test('names the Author when the Author changes', () {
        final course = older();
        final signed = credits(
          course,
          authors: [author('Maria Rossi')],
        ).applyTo(course);
        expect(names(signed.rightsHolders), ['Maria Rossi']);
        // A role is a change of the credits too.
        final first = course.authors.first;
        final roles = credits(
          course,
          authors: [
            CourseAuthor(name: first.name, roles: [...first.roles, 'Editor']),
          ],
        ).applyTo(course);
        expect(names(roles.rightsHolders), ['mari_88']);
      });

      test('names the Author when the license changes; not for CC0 1.0', () {
        final course = older();
        final open = credits(course, license: 'CC BY 4.0').applyTo(course);
        expect(names(open.rightsHolders), ['mari_88']);
        final free = credits(course, license: 'CC0 1.0').applyTo(course);
        expect(free.rightsHolders, isEmpty);
      });

      test('a Rights Holder written in a row is stored', () {
        final course = older();
        final named = credits(
          course,
          rightsHolders: const [
            CourseRightsHolder(type: person, name: 'Anna Bianchi'),
          ],
        ).applyTo(course);
        expect(names(named.rightsHolders), ['Anna Bianchi']);
      });

      test('the form says so instead of promising the Author', () {
        expect(
          CourseCredits.rightsHolderNoteFor(older()),
          CourseCredits.rightsHolderMissingNote,
        );
        expect(
          CourseCredits.rightsHolderNoteFor(started()),
          CourseCredits.rightsHolderDefaultNote,
        );
        // CC0 1.0 asks for none: nothing is missing.
        expect(
          CourseCredits.rightsHolderNoteFor(older(license: 'CC0 1.0')),
          CourseCredits.rightsHolderDefaultNote,
        );
      });

      test('two lists of authors are the same by name, roles and order', () {
        final a = [
          author('Ada'),
          author('Bo', const ['Editor', 'Author']),
        ];
        expect(
          CourseCredits.sameAuthors(a, [
            author('Ada'),
            author('Bo', const ['Editor', 'Author']),
          ]),
          isTrue,
        );
        expect(
          CourseCredits.sameAuthors(a, [
            author('Ada'),
            author('Bo', const ['Author', 'Editor']),
          ]),
          isFalse,
        );
        expect(CourseCredits.sameAuthors(a, [author('Ada')]), isFalse);
        expect(
          CourseCredits.sameAuthors(a, [
            author('Ada'),
            author('Bob', const ['Editor', 'Author']),
          ]),
          isFalse,
        );
        expect(CourseCredits.sameAuthors(const [], const []), isTrue);
      });
    });

    test('a Rights Holder typed with the Author’s own name is the default: '
        'the file cannot tell them apart', () {
      final course = started();
      final typed = credits(
        course,
        rightsHolders: const [
          CourseRightsHolder(type: person, name: 'mari_88'),
        ],
      ).applyTo(course);
      expect(names(typed.rightsHolders), ['mari_88']);
      expect(CourseWizardCredits.of(typed).rightsHolders, isEmpty);
    });

    test('a stored list that names a person twice is shown as written', () {
      final course = Course.fromJson({
        ...started().toJson(),
        'rightsHolders': [
          {'type': 'person', 'name': 'mari_88'},
          {'type': 'person', 'name': 'mari_88'},
        ],
      });
      expect(names(CourseCredits.rightsHoldersByHand(course)), [
        'mari_88',
        'mari_88',
      ]);
      final again = CourseWizardCredits.of(course).applyTo(course);
      expect(names(again.rightsHolders), ['mari_88', 'mari_88']);
    });

    test('the example leaves the rows empty: its Author is named', () {
      final sample = CourseWizardSample.credits('mari_88');
      expect(sample.rightsHolders, isEmpty);
      final course = started();
      final filled = sample.applyTo(course);
      expect(names(filled.rightsHolders), ['mari_88']);
      expect(filled.rightsHolders.single.type, person);
      expect(CourseWizardCredits.of(filled).rightsHolders, isEmpty);
    });
  });

  group('the Course Audit', () {
    Course course({
      String license = 'All rights reserved',
      List<CourseRightsHolder> rightsHolders = const [],
    }) => Course(
      courseId: 'audited',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Italian at the bar',
      ttsLanguage: 'it-IT',
      license: license,
      rightsHolders: rightsHolders,
      lessons: const [],
    );

    List<CourseAuditIssue> found(Course audited) => [
      for (final issue in CourseAuditService().auditCourse(audited).issues)
        if (issue.code == AuditCode.licenseRightsHolderMissing.code) issue,
    ];

    test('warns about a license without a Rights Holder', () {
      final issue = found(course()).single;
      expect(issue.severity, AuditSeverity.warning);
      expect(
        issue.message,
        'A license is stated (All rights reserved) but no Rights Holder is '
        'named.',
      );
      expect(issue.location, 'Course info');
      expect(
        found(course(license: 'Ask me first')).single.message,
        contains('(Ask me first)'),
      );
    });

    test(
      'says nothing when one is named, for CC0 1.0 or without a license',
      () {
        expect(
          found(
            course(
              rightsHolders: const [
                CourseRightsHolder(type: person, name: 'Maria Rossi'),
              ],
            ),
          ),
          isEmpty,
        );
        expect(found(course(license: 'CC0 1.0')), isEmpty);
        expect(found(course(license: '')), isEmpty);
      },
    );

    test('it is a warning: it never blocks', () {
      expect(
        AuditCode.licenseRightsHolderMissing.severity,
        AuditSeverity.warning,
      );
      expect(
        AuditCode.licenseRightsHolderMissing.code,
        'LICENSE_RIGHTS_HOLDER_MISSING',
      );
      // What blocks counts errors, and this Course has none.
      final audit = CourseAuditService().auditCourse(course());
      expect(found(course()), hasLength(1));
      expect(audit.count(AuditSeverity.error), 0);
    });

    test('a long custom license is written on one line, shortened', () {
      // The forms allow 2,000 characters over several lines, a file more.
      final license = [
        for (var line = 0; line < 40; line++) 'You may share this Course 😀',
      ].join('\n');
      final message = found(course(license: license)).single.message;
      expect(message, isNot(contains('\n')));
      expect(
        message,
        'A license is stated (${CourseImportCheck.shown(license)}) but no '
        'Rights Holder is named.',
      );
      expect(message.length, lessThan(160));
      expect(message, contains('…'));
    });
  });

  group('Export as Publisher Course', () {
    Course custom({
      String license = 'All rights reserved',
      List<CourseRightsHolder> rightsHolders = const [],
    }) => Course(
      courseId: 'to-publish',
      originType: CourseOriginType.custom,
      originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
        profileId: appName,
        displayName: 'mari_88',
      ),
      maintainer: const CourseMaintainer(appName),
      originalCreatedAtUtc: '2026-10-13T09:00:00.000Z',
      courseVersion: '1',
      publicationState: PublicationState.published,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Italian at the bar',
      ttsLanguage: 'it-IT',
      license: license,
      rightsHolders: rightsHolders,
      lessons: const [],
    );

    const refusal =
        'The Course names no Rights Holder for its License: name one in '
        'Course Info Editor.';

    List<String> refusals(Course course) =>
        PublisherCourseExport.refusals(course, hasOperationalAccess: true);

    test('refuses a license without a Rights Holder', () {
      expect(refusals(custom()), contains(refusal));
    });

    test('does not refuse for it when one is named, or for CC0 1.0', () {
      expect(
        refusals(
          custom(
            rightsHolders: const [
              CourseRightsHolder(type: person, name: 'Maria Rossi'),
            ],
          ),
        ),
        isNot(contains(refusal)),
      );
      expect(refusals(custom(license: 'CC0 1.0')), isNot(contains(refusal)));
    });
  });

  test('the import pop-up says it once: in words, not again among the '
      'Audit warnings', () {
    final course = Course.fromJson(
      jsonDecode(
            jsonEncode(
              Course(
                courseId: 'imported',
                originType: CourseOriginType.custom,
                originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
                  profileId: appName,
                  displayName: 'mari_88',
                ),
                maintainer: const CourseMaintainer(appName),
                originalCreatedAtUtc: '2026-10-13T09:00:00.000Z',
                courseVersion: '1',
                learningLanguage: 'Italian',
                interfaceLanguage: 'English',
                sourceLanguage: 'English',
                targetLanguage: 'Italian',
                title: 'Italian at the bar',
                ttsLanguage: 'it-IT',
                authors: [author('Maria Rossi')],
                lessons: const [],
              ).toJson(),
            ),
          )
          as Map<String, dynamic>,
    );
    final warnings = [
      for (final issue in CourseAuditService().auditCourse(course).issues)
        if (issue.severity == AuditSeverity.warning) issue,
    ];
    expect(
      warnings.map((issue) => issue.code),
      contains(AuditCode.licenseRightsHolderMissing.code),
    );
    final check = CourseImportCheck.of(course, warnings: warnings);
    expect(
      check.anomalies.where(
        (item) => item.kind == CourseImportAnomalyKind.noRightsHolder,
      ),
      hasLength(1),
    );
    // Said in words: the Rights Holder and the missing Lessons.
    final others = warnings
        .where(
          (issue) =>
              issue.code != AuditCode.licenseRightsHolderMissing.code &&
              issue.code != AuditCode.courseLessonsEmpty.code,
        )
        .length;
    final counted = [
      for (final item in check.anomalies)
        if (item.kind == CourseImportAnomalyKind.auditWarnings) item.text,
    ];
    expect(counted, hasLength(others > 0 ? 1 : 0));
    if (others > 0) {
      expect(counted.single, contains('$others other warning'));
    }
  });

  test('the import pop-up says it also for a file without a license, which '
      'is read as All rights reserved', () {
    // Found by the independent review: the Audit warned, the pop-up left
    // the warning out of its count and did not say it.
    final written =
        jsonDecode(
                jsonEncode(
                  Course(
                    courseId: 'no-license',
                    originType: CourseOriginType.custom,
                    originalCourseCreator:
                        const CourseProvenanceIdentity.qqlUser(
                          profileId: appName,
                          displayName: 'mari_88',
                        ),
                    maintainer: const CourseMaintainer(appName),
                    originalCreatedAtUtc: '2026-10-13T09:00:00.000Z',
                    courseVersion: '1',
                    learningLanguage: 'Italian',
                    interfaceLanguage: 'English',
                    sourceLanguage: 'English',
                    targetLanguage: 'Italian',
                    title: 'Italian at the bar',
                    ttsLanguage: 'it-IT',
                    authors: [author('Maria Rossi')],
                    lessons: const [],
                  ).toJson(),
                ),
              )
              as Map<String, dynamic>
          ..remove('license');
    final course = Course.fromJson(written);
    expect(course.license, 'All rights reserved');
    final warnings = [
      for (final issue in CourseAuditService().auditCourse(course).issues)
        if (issue.severity == AuditSeverity.warning) issue,
    ];
    expect(
      warnings.map((issue) => issue.code),
      contains(AuditCode.licenseRightsHolderMissing.code),
    );
    final check = CourseImportCheck.of(
      course,
      fileJson: written,
      warnings: warnings,
    );
    List<String> said(CourseImportAnomalyKind kind) => [
      for (final item in check.anomalies)
        if (item.kind == kind) item.text,
    ];
    expect(said(CourseImportAnomalyKind.noLicense), [
      'The file states no license: QuisquisLingo reads it as “All rights '
          'reserved”.',
    ]);
    expect(said(CourseImportAnomalyKind.noRightsHolder), [
      'No Rights Holder is named either.',
    ]);
    // Said in words, so not counted again among the Audit's warnings.
    final others = warnings
        .where(
          (issue) =>
              issue.code != AuditCode.licenseRightsHolderMissing.code &&
              issue.code != AuditCode.courseLessonsEmpty.code,
        )
        .length;
    expect(
      said(CourseImportAnomalyKind.auditWarnings),
      hasLength(others > 0 ? 1 : 0),
    );

    // A file that states an empty license keeps it empty: no license, and
    // nothing asks for a Rights Holder.
    final empty = Course.fromJson({...written, 'license': ''});
    expect(empty.license, isEmpty);
    final emptyWarnings = [
      for (final issue in CourseAuditService().auditCourse(empty).issues)
        if (issue.severity == AuditSeverity.warning) issue,
    ];
    expect(
      emptyWarnings.map((issue) => issue.code),
      isNot(contains(AuditCode.licenseRightsHolderMissing.code)),
    );
    final emptyCheck = CourseImportCheck.of(
      empty,
      fileJson: {...written, 'license': ''},
      warnings: emptyWarnings,
    );
    expect(
      emptyCheck.anomalies.map((item) => item.kind),
      isNot(contains(CourseImportAnomalyKind.noRightsHolder)),
    );
  });
}
