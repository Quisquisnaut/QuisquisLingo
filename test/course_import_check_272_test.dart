import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_metadata_options.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_import_check.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 272 Revision 13: what the import of a Course file shows before it
/// stores anything. The cases read the file with the app's own reader and,
/// where the Course Audit decides, with the Audit itself, so each line of
/// the pop-up says what the import really does.
void main() {
  const author = '12345678-1234-4234-9234-123456789abc';
  const stranger = '99999999-1234-4234-9234-123456789abc';
  final time = DateTime.utc(2026, 10, 13, 9);
  final clip = 'media:${'a' * 64}.mp3';

  Exercise exercise(String id) => Exercise(
    id: id,
    publicationState: PublicationState.published,
    updatedAt: time,
    type: 'build_translation',
    prompt: 'How are you?',
    question: '',
    answers: const [],
    correct: null,
    tts: null,
    accepted: const [],
    tokens: const ['Come', 'stai'],
    orderAnswer: const [],
    correctTranslations: const ['Come stai?'],
    pairs: const [],
    hint: '',
    icons: const [],
  );

  LearningRound round(String id, {bool empty = false}) => LearningRound(
    id: 'round-$id',
    publicationState: PublicationState.published,
    updatedAt: time,
    title: '',
    exercises: empty ? const [] : [exercise('exercise-$id')],
  );

  Lesson lesson(String id, List<LearningRound> rounds) => Lesson(
    lessonId: 'lesson-$id',
    publicationState: PublicationState.published,
    updatedAt: time,
    title: 'Lesson $id',
    rounds: rounds,
  );

  /// A Course file with an author, a license, a Rights Holder and a Lesson
  /// with a Round with an exercise.
  Map<String, dynamic> file({
    Map<String, Object?> set = const {},
    List<String> remove = const [],
    List<Lesson>? lessons,
  }) {
    final course = Course(
      courseId: 'anomalies',
      originType: CourseOriginType.custom,
      originalCourseCreator: CourseProvenanceIdentity.qqlUser(
        profileId: author,
        displayName: 'Ada',
      ),
      maintainer: const CourseMaintainer(author),
      originalCreatedAtUtc: '2026-10-13T09:00:00.000Z',
      courseVersion: '1',
      publicationState: PublicationState.published,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Italian at the bar',
      ttsLanguage: 'it-IT',
      authors: const [
        CourseAuthor(name: 'Ada', roles: ['Author']),
      ],
      license: 'CC BY 4.0',
      rightsHolders: const [
        CourseRightsHolder(type: CourseRightsHolderType.person, name: 'Ada'),
      ],
      lessons:
          lessons ??
          [
            lesson('one', [round('one')]),
          ],
    );
    final json = jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>
      ..addAll(set);
    remove.forEach(json.remove);
    return json;
  }

  List<CourseAuditIssue> warningsOf(Course course) => [
    for (final issue in CourseAuditService().auditCourse(course).issues)
      if (issue.severity == AuditSeverity.warning) issue,
  ];

  List<String> errorsOf(Course course) => [
    for (final issue in CourseAuditService().auditCourse(course).issues)
      if (issue.severity == AuditSeverity.error) issue.code,
  ];

  /// The check of a file, as the import makes it: read by the Course's
  /// reader, compared with the file as written. [audited] adds the Course
  /// Audit's own warnings.
  CourseImportCheck of(
    Map<String, dynamic> written, {
    List<CourseAuditIssue> warnings = const [],
    bool audited = false,
    int notExecutable = 0,
  }) {
    final course = Course.fromJson(written);
    return CourseImportCheck.of(
      course,
      fileJson: written,
      warnings: audited ? warningsOf(course) : warnings,
      notExecutable: notExecutable,
    );
  }

  List<CourseImportAnomalyKind> kinds(CourseImportCheck found) => [
    for (final item in found.anomalies) item.kind,
  ];

  String text(CourseImportCheck found, CourseImportAnomalyKind kind) =>
      found.anomalies.singleWhere((item) => item.kind == kind).text;

  CourseAuditIssue warning(int n) => CourseAuditIssue.fromCode(
    AuditCode.choiceAllAnswersCorrect,
    message: 'Warning $n.',
    location: 'Lesson $n',
  );

  const deviceVoice =
      'The Course has no recordings: QuisquisLingo will use the device’s '
      'voice. Please check that Text-to-speech is set up correctly for '
      'Italian (Settings › Audio Settings).';

  group('a file with nothing missing or wrong', () {
    test('has no anomalies', () {
      final found = of(file());
      expect(found.anomalies, isEmpty);
      expect(found.hasAnomalies, isFalse);
    });

    test('with no recordings carries the reminder of the device’s voice, '
        'which is no anomaly', () {
      final found = of(file());
      expect(found.hasAnomalies, isFalse);
      expect(found.reminders, [deviceVoice]);
    });

    test('nothing is an anomaly without the file either', () {
      final found = CourseImportCheck.of(Course.fromJson(file()));
      expect(found.anomalies, isEmpty);
    });

    test('empty optional fields are normal', () {
      final found = of(
        file(
          set: {
            'sectionNames': <String>[],
            'keywords': <String>[],
            'lessonIconAssets': <Object>[],
            'audioLibrary': <Object>[],
            'courseDescription': '',
          },
        ),
      );
      expect(found.anomalies, isEmpty);
    });
  });

  group('credits and license', () {
    test('no author, left out or an empty list', () {
      for (final written in [
        file(remove: ['authors']),
        file(set: {'authors': <Object>[]}),
      ]) {
        final found = of(written);
        expect(kinds(found), [CourseImportAnomalyKind.noAuthor]);
        expect(found.anomalies.single.text, 'The file names no author.');
      }
    });

    test('no license: the file is read as All rights reserved, and the '
        'pop-up says so', () {
      for (final written in [
        file(remove: ['license']),
        file(set: {'license': 5}),
        file(set: {'license': null}),
      ]) {
        expect(Course.fromJson(written).license, 'All rights reserved');
        final found = of(written);
        expect(kinds(found), [CourseImportAnomalyKind.noLicense]);
        expect(
          found.anomalies.single.text,
          'The file states no license: QuisquisLingo reads it as “All rights '
          'reserved”.',
        );
      }
    });

    test('an empty license stays empty', () {
      for (final written in [
        file(set: {'license': ''}),
        file(set: {'license': '   '}),
      ]) {
        expect(Course.fromJson(written).license, '');
        final found = of(written);
        expect(kinds(found), [CourseImportAnomalyKind.noLicense]);
        expect(found.anomalies.single.text, 'The file states no license.');
      }
    });

    test('a license without a Rights Holder', () {
      for (final written in [
        file(remove: ['rightsHolders']),
        file(set: {'rightsHolders': <Object>[]}),
      ]) {
        final found = of(written);
        expect(kinds(found), [CourseImportAnomalyKind.noRightsHolder]);
        expect(
          found.anomalies.single.text,
          'A license is stated (CC BY 4.0) but no Rights Holder is named.',
        );
        expect(found.facts.license, 'CC BY 4.0 · Rights Holder: none named');
      }
    });

    test('what New Course writes today, All rights reserved and nobody '
        'named, is one', () {
      final found = of(
        file(set: {'license': 'All rights reserved', 'rightsHolders': []}),
      );
      expect(
        found.anomalies.single.text,
        'A license is stated (All rights reserved) but no Rights Holder is '
        'named.',
      );
    });

    test('a license the author wrote, without a Rights Holder', () {
      final found = of(
        file(set: {'license': 'Ask me first'}, remove: ['rightsHolders']),
      );
      expect(
        text(found, CourseImportAnomalyKind.noRightsHolder),
        'A license is stated (Ask me first) but no Rights Holder is named.',
      );
    });

    test('CC0 gives the rights up: no Rights Holder is asked for', () {
      final found = of(
        file(set: {'license': 'CC0 1.0'}, remove: ['rightsHolders']),
      );
      expect(found.anomalies, isEmpty);
      expect(
        CourseMetadataOptions.standardLicenses,
        contains(CourseImportCheck.rightsGivenUp),
      );
    });

    test('no license and no Rights Holder: one line, about the license', () {
      final found = of(file(remove: ['license', 'rightsHolders']));
      expect(kinds(found), [CourseImportAnomalyKind.noLicense]);
    });
  });

  group('audio', () {
    test('an audio mode QQL does not know is read as On-Device TTS', () {
      final written = file(set: {'audioMode': 'mp3'});
      expect(Course.fromJson(written).audioMode, 'tts');
      final found = of(written);
      expect(kinds(found), [CourseImportAnomalyKind.audioModeUnknown]);
      expect(
        found.anomalies.single.text,
        'The audio mode “mp3” is not one QuisquisLingo knows: the Course is '
        'read as On-Device TTS.',
      );
      expect(found.reminders, [deviceVoice]);
    });

    test('an audio mode that is no text, or an empty one', () {
      for (final wrong in <Object>[
        '',
        '  ',
        7,
        true,
        ['hybrid'],
        {'mode': 'hybrid'},
      ]) {
        final written = file(set: {'audioMode': wrong});
        expect(Course.fromJson(written).audioMode, 'tts', reason: '$wrong');
        expect(
          of(written).anomalies.single.text,
          'The audio mode is not written as QuisquisLingo expects: the '
          'Course is read as On-Device TTS.',
          reason: '$wrong',
        );
      }
    });

    test('a very long audio mode is shortened', () {
      final found = of(file(set: {'audioMode': 'x' * 100000}));
      expect(
        found.anomalies.single.text,
        'The audio mode “${'x' * 40}…” is not one QuisquisLingo knows: the '
        'Course is read as On-Device TTS.',
      );
    });

    test('the three audio modes, and none, are not anomalies', () {
      for (final mode in ['tts', 'recorded', 'hybrid']) {
        final written = file(
          set: {
            'audioMode': mode,
            'audioLibrary': [
              {'id': 'clip', 'text': 'ciao', 'filePath': clip},
            ],
          },
        );
        expect(Course.fromJson(written).audioMode, mode);
        expect(of(written).anomalies, isEmpty, reason: mode);
      }
      expect(of(file(remove: ['audioMode'])).anomalies, isEmpty);
      expect(of(file(set: {'audioMode': null})).anomalies, isEmpty);
    });

    test('an Audio Library that is not a list: imported without '
        'recordings', () {
      for (final wrong in <Object>[
        'clips',
        {'id': 'clip', 'text': 'ciao', 'filePath': clip},
        7,
      ]) {
        final written = file(set: {'audioLibrary': wrong});
        expect(Course.fromJson(written).audioLibrary, isEmpty);
        final found = of(written);
        expect(kinds(found), [CourseImportAnomalyKind.audioLibraryNotAList]);
        expect(
          found.anomalies.single.text,
          'The Audio Library is not written as a list: the Course will be '
          'imported without recordings.',
        );
        expect(found.reminders, [deviceVoice]);
      }
    });

    test('an Audio Library written as nothing is a Course without '
        'recordings', () {
      final found = of(file(set: {'audioLibrary': null}));
      expect(found.anomalies, isEmpty);
    });

    test('entries of the Audio Library that are not recordings are '
        'skipped', () {
      final one = file(
        set: {
          'audioMode': 'hybrid',
          'audioLibrary': [
            {'id': 'clip', 'text': 'ciao', 'filePath': clip},
            'ciao.mp3',
          ],
        },
      );
      expect(Course.fromJson(one).audioLibrary, hasLength(1));
      expect(
        of(one).anomalies.single.text,
        '1 entry of the Audio Library is not a recording and will be skipped.',
      );
      expect(of(one).reminders, isEmpty);

      final three = file(
        set: {
          'audioLibrary': ['a.mp3', 2, null],
        },
      );
      expect(Course.fromJson(three).audioLibrary, isEmpty);
      final found = of(three);
      expect(kinds(found), [
        CourseImportAnomalyKind.audioLibraryEntriesSkipped,
      ]);
      expect(
        found.anomalies.single.text,
        '3 entries of the Audio Library are not recordings and will be '
        'skipped.',
      );
    });

    test('recordings first, and none: the device’s voice reads', () {
      final found = of(file(set: {'audioMode': 'hybrid'}));
      expect(kinds(found), [CourseImportAnomalyKind.recordingsFirstAndNone]);
      expect(
        found.anomalies.single.text,
        'The Course is set to play its recordings first (Hybrid) and has '
        'none.',
      );
      expect(found.reminders, [deviceVoice]);
    });

    test('recordings first with a wrongly written Audio Library says it '
        'once', () {
      final found = of(
        file(set: {'audioMode': 'hybrid', 'audioLibrary': 'clips'}),
      );
      expect(kinds(found), [CourseImportAnomalyKind.audioLibraryNotAList]);
      expect(found.reminders, [deviceVoice]);
    });

    test('only recordings, and none, is refused by the Course Audit before '
        'the pop-up: no anomaly for it', () {
      for (final written in [
        file(set: {'audioMode': 'recorded'}),
        file(set: {'audioMode': 'recorded', 'audioLibrary': 'clips'}),
      ]) {
        expect(
          errorsOf(Course.fromJson(written)),
          contains(AuditCode.recordedAudioLibraryEmpty.code),
        );
        // Never promised the device's voice: that mode does not use it.
        expect(of(written).reminders, isEmpty);
      }
      expect(kinds(of(file(set: {'audioMode': 'recorded'}))), isEmpty);
    });

    test('recordings in a Course set to On-Device TTS are not played, and '
        'the reminder says so', () {
      final one = of(
        file(
          set: {
            'audioLibrary': [
              {'id': 'clip', 'text': 'ciao', 'filePath': clip},
            ],
          },
        ),
      );
      expect(one.anomalies, isEmpty);
      expect(one.reminders, [
        'The Course has 1 recording but its audio mode is On-Device TTS: it '
            'is not '
            'played, and the device’s voice reads every text. Please check '
            'that Text-to-speech is set up correctly for Italian (Settings › '
            'Audio Settings).',
      ]);

      // A file that leaves the audio mode out, or writes one QQL does not
      // know, loses its recordings this way.
      final two = of(
        file(
          set: {
            'audioMode': 'mp3',
            'audioLibrary': [
              {'id': 'one', 'text': 'ciao', 'filePath': clip},
              {'id': 'two', 'text': 'grazie', 'filePath': clip},
            ],
          },
        ),
      );
      expect(kinds(two), [CourseImportAnomalyKind.audioModeUnknown]);
      expect(
        two.reminders.single,
        startsWith(
          'The Course has 2 recordings but its audio mode is On-Device TTS: '
          'they are '
          'not played,',
        ),
      );
    });

    test('recordings that play carry no reminder', () {
      for (final mode in ['recorded', 'hybrid']) {
        final found = of(
          file(
            set: {
              'audioMode': mode,
              'audioLibrary': [
                {'id': 'clip', 'text': 'ciao', 'filePath': clip},
              ],
            },
          ),
        );
        expect(found.anomalies, isEmpty, reason: mode);
        expect(found.reminders, isEmpty, reason: mode);
      }
    });

    test('the reminder names the language studied, or says so', () {
      final named = of(file(set: {'targetLanguage': 'Neapolitan'}));
      expect(
        named.reminders.single,
        contains('correctly for Neapolitan (Settings'),
      );

      final written = file(set: {'targetLanguage': '  '});
      final course = Course.fromJson(written);
      expect(course.targetLanguage, '');
      expect(
        CourseImportCheck.of(course, fileJson: written).reminders.single,
        contains('correctly for the language studied (Settings'),
      );
    });

    test('a ZIP with its files in a folder of its name is reminded first', () {
      final found = CourseImportCheck.of(
        Course.fromJson(file()),
        matchingZipFolder: true,
      );
      expect(found.reminders, [
        'Accepted a matching ZIP folder. Course package files normally '
            'belong at the ZIP root.',
        deviceVoice,
      ]);
      expect(found.hasAnomalies, isFalse);
    });
  });

  group('Lessons', () {
    test('no Lessons', () {
      final found = of(file(lessons: const []));
      expect(kinds(found), [CourseImportAnomalyKind.noLessons]);
      expect(found.anomalies.single.text, 'The Course has no Lessons.');
    });

    test('Lessons without Rounds, one and several', () {
      final one = of(
        file(
          lessons: [
            lesson('one', [round('one')]),
            lesson('two', const []),
          ],
        ),
      );
      expect(kinds(one), [CourseImportAnomalyKind.lessonsWithoutRounds]);
      expect(one.anomalies.single.text, 'Lessons without Rounds: 1.');

      final two = of(
        file(lessons: [lesson('one', const []), lesson('two', const [])]),
      );
      expect(two.anomalies.single.text, 'Lessons without Rounds: 2.');
    });

    test('the Course Audit warns about both, and the pop-up does not say '
        'them twice', () {
      final empty = warningsOf(Course.fromJson(file(lessons: const [])));
      expect(
        empty.map((w) => w.code),
        contains(AuditCode.courseLessonsEmpty.code),
      );
      final none = of(file(lessons: const []), audited: true);
      expect(text(none, CourseImportAnomalyKind.noLessons), isNotEmpty);
      // That warning is not counted again among the Audit's.
      expect(
        kinds(none).contains(CourseImportAnomalyKind.auditWarnings),
        empty.length > 1,
      );
      if (empty.length > 1) {
        expect(
          text(none, CourseImportAnomalyKind.auditWarnings),
          startsWith('The Course Audit has ${empty.length - 1} other warning'),
        );
      }

      final written = file(
        lessons: [
          lesson('one', const []),
          lesson('two', const []),
          lesson('three', const []),
        ],
      );
      final all = warningsOf(Course.fromJson(written));
      final said = all
          .where((w) => w.code == AuditCode.lessonRoundsEmpty.code)
          .length;
      expect(said, 3);
      final found = of(written, audited: true);
      expect(
        text(found, CourseImportAnomalyKind.lessonsWithoutRounds),
        'Lessons without Rounds: 3.',
      );
      final others = all.length - said;
      expect(
        kinds(found).contains(CourseImportAnomalyKind.auditWarnings),
        others > 0,
        reason: 'only the warnings not said in words are counted',
      );
      if (others > 0) {
        expect(
          text(found, CourseImportAnomalyKind.auditWarnings),
          startsWith('The Course Audit has $others other warning'),
        );
      }
    });

    test('a Round without exercises is refused by the Course Audit before '
        'the pop-up: no anomaly for it', () {
      final written = file(
        lessons: [
          lesson('one', [round('one'), round('two', empty: true)]),
        ],
      );
      expect(
        errorsOf(Course.fromJson(written)),
        contains(AuditCode.roundContentEmpty.code),
      );
      expect(of(written).anomalies, isEmpty);
    });
  });

  group('the Course’s own labels for its Lessons and Rounds', () {
    const ownLabels = {
      'lessonNumberingMode': 'other',
      'customLessonLabel': 'Unità',
      'roundNumberingMode': 'customAndNumber',
      'customRoundLabel': 'Tappa',
    };

    test('QQL’s labels unless the Course has its own', () {
      final plain = Course.fromJson(file());
      expect(CourseImportFacts.lessonsLabel(plain), 'Lessons');
      expect(CourseImportFacts.roundsLabel(plain), 'Rounds');
      for (final mode in ['numberOnly', 'none']) {
        expect(
          CourseImportFacts.lessonsLabel(
            Course.fromJson(file(set: {'lessonNumberingMode': mode})),
          ),
          'Lessons',
          reason: mode,
        );
      }
      for (final mode in ['roundAndNumber', 'numberOnly', 'off']) {
        expect(
          CourseImportFacts.roundsLabel(
            Course.fromJson(file(set: {'roundNumberingMode': mode})),
          ),
          'Rounds',
          reason: mode,
        );
      }
    });

    test('one of QQL’s earlier Lesson labels, in the plural', () {
      const plurals = {
        'unit': 'Units',
        'topic': 'Topics',
        'module': 'Modules',
        'skill': 'Skills',
        'chapter': 'Chapters',
        'stage': 'Stages',
        'step': 'Steps',
        'part': 'Parts',
      };
      for (final entry in plurals.entries) {
        expect(
          CourseImportFacts.lessonsLabel(
            Course.fromJson(file(set: {'lessonNumberingMode': entry.key})),
          ),
          entry.value,
        );
      }
      // Every mode is one of the cases above.
      expect(
        {for (final mode in LessonNumberingMode.values) mode.name},
        {...plurals.keys, 'lesson', 'other', 'numberOnly', 'none'},
      );
      expect(
        {for (final mode in RoundNumberingMode.values) mode.name},
        {'off', 'roundAndNumber', 'numberOnly', 'customAndNumber'},
      );
    });

    test('a label the author chose is used as written', () {
      final course = Course.fromJson(file(set: ownLabels));
      expect(CourseImportFacts.lessonsLabel(course), 'Unità');
      expect(CourseImportFacts.roundsLabel(course), 'Tappa');
      expect(
        CourseImportFacts.of(course).content,
        'Unità: 1 · Tappa: 1 · Exercises: 1',
      );
    });

    test('the anomalies about Lessons use them', () {
      expect(
        of(file(set: ownLabels, lessons: const [])).anomalies.single.text,
        'The Course has no Unità.',
      );
      final found = of(
        file(
          set: ownLabels,
          lessons: [
            lesson('one', const []),
            lesson('two', [round('two')]),
          ],
        ),
      );
      expect(
        text(found, CourseImportAnomalyKind.lessonsWithoutRounds),
        'Unità without Tappa: 1.',
      );
    });

    test('a very long label is shortened', () {
      final course = Course.fromJson(
        file(set: {...ownLabels, 'customLessonLabel': 'U' * 5000}),
      );
      expect(CourseImportFacts.lessonsLabel(course), '${'U' * 40}…');
    });
  });

  group('what the pop-up tells about a Course without anomalies', () {
    test('authors with their roles, the license with its Rights Holder, the '
        'numbers', () {
      final facts = of(file()).facts;
      expect(facts.authors, 'Ada (Author)');
      expect(facts.license, 'CC BY 4.0 · Rights Holder: Ada');
      expect(facts.content, 'Lessons: 1 · Rounds: 1 · Exercises: 1');
    });

    test('several authors and Rights Holders, larger numbers', () {
      final facts = of(
        file(
          set: {
            'authors': [
              {
                'name': 'Ada',
                'roles': ['Author', 'Illustrator'],
              },
              {
                'name': 'Bob',
                'roles': ['Reviewer'],
              },
            ],
            'rightsHolders': [
              {'type': 'person', 'name': 'Ada'},
              {'type': 'organization', 'name': 'Scuola Verde'},
            ],
          },
          lessons: [
            lesson('one', [round('one'), round('two')]),
            lesson('two', [round('three')]),
          ],
        ),
      ).facts;
      expect(facts.authors, 'Ada (Author, Illustrator), Bob (Reviewer)');
      expect(facts.license, 'CC BY 4.0 · Rights Holder: Ada, Scuola Verde');
      expect(facts.content, 'Lessons: 2 · Rounds: 3 · Exercises: 3');
    });

    test('more names than fit, and a very long one', () {
      final facts = of(
        file(
          set: {
            'authors': [
              for (var n = 1; n <= 9; n++)
                {
                  'name': n == 1 ? 'A' * 500 : 'Author $n',
                  'roles': ['Author'],
                },
            ],
          },
        ),
      ).facts;
      expect(facts.authors, startsWith('${'A' * 80}…, Author 2 (Author), '));
      expect(facts.authors, endsWith('Author 6 (Author), and 3 more'));
      expect(CourseImportFacts.shownNames, 6);
    });

    test('nothing named, nothing stated', () {
      final facts = of(
        file(set: {'license': ''}, remove: ['authors', 'rightsHolders']),
      ).facts;
      expect(facts.authors, CourseImportFacts.noneNamed);
      expect(facts.license, CourseImportFacts.noneStated);
      expect(
        of(file(remove: ['rightsHolders'])).facts.license,
        'CC BY 4.0 · Rights Holder: none named',
      );
    });

    test('the Maintainer by the name this device has', () {
      final facts = CourseImportCheck.of(
        Course.fromJson(file()),
        maintainerOnDevice: 'Ada here',
      ).facts;
      expect(facts.maintainerLabel, 'Maintainer');
      expect(facts.maintainer, 'Ada here');
    });

    test('a Maintainer who is no learner of this device, by the name the '
        'file records for its creator', () {
      final facts = of(file()).facts;
      expect(facts.maintainer, 'Ada (not a learner on this device)');
    });

    test('or for its last editor', () {
      final facts = of(
        file(
          set: {
            'maintainer': {'profileId': stranger},
            'lastVersionEditorProfileId': stranger,
            'lastVersionEditorDisplayName': 'Bea',
          },
        ),
      ).facts;
      expect(facts.maintainer, 'Bea (not a learner on this device)');
      expect(facts.lastEditor, 'Bea');
    });

    test('or by no name at all', () {
      final facts = of(
        file(
          set: {
            'maintainer': {'profileId': stranger},
          },
        ),
      ).facts;
      expect(facts.maintainer, CourseImportFacts.notALearnerHere);
    });

    test('the Team: none, one of this device, one that is not here', () {
      const team = '22222222-2222-4222-8222-222222222222';
      expect(of(file()).facts.team, CourseImportFacts.noTeam);
      final assigned = Course.fromJson(file(set: {'assignedTeamId': team}));
      expect(
        CourseImportCheck.of(assigned, teamOnDevice: 'Green Team').facts.team,
        'Green Team',
      );
      expect(
        CourseImportCheck.of(assigned).facts.team,
        CourseImportFacts.teamNotHere,
      );
    });

    test('the last edit, in local time', () {
      final said = of(
        file(set: {'modifiedAtUtc': '2026-10-12T15:30:00.000Z'}),
      ).facts;
      expect(said.lastEdited, DateTime.utc(2026, 10, 12, 15, 30).toLocal());
      expect(said.lastEdited!.isUtc, isFalse);
      // A file without it never reaches the check: the reader refuses it.
      expect(
        () => Course.fromJson(file(remove: ['modifiedAtUtc'])),
        throwsFormatException,
      );
    });

    test('a Publisher Course has a Publisher, not a Maintainer, and no '
        'Team', () {
      final course = Course(
        courseId: 'official',
        originType: CourseOriginType.externalOfficial,
        originalCourseCreator: const CourseProvenanceIdentity.publisher(
          publisherId: 'org.example',
          displayName: 'Example Courses',
        ),
        originalCreatedAtUtc: '2026-10-13T09:00:00.000Z',
        publisherId: 'org.example',
        publisherName: 'Example Courses',
        officialCourseVersion: '3',
        officialReleaseDateUtc: '2026-10-13T09:00:00.000Z',
        officialChecksum: 'a' * 64,
        distributionChannel: 'publisher',
        publicationState: PublicationState.published,
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Official Italian',
        ttsLanguage: 'it-IT',
        lessons: [
          lesson('one', [round('one')]),
        ],
      );
      final facts = CourseImportFacts.of(course, maintainerOnDevice: 'Nobody');
      expect(facts.maintainerLabel, 'Publisher');
      expect(facts.maintainer, 'Example Courses');
      expect(facts.team, isNull);
    });
  });

  group('what the import knew already', () {
    test('one Audit warning', () {
      final found = of(file(), warnings: [warning(1)]);
      expect(kinds(found), [CourseImportAnomalyKind.auditWarnings]);
      expect(
        found.anomalies.single.text,
        'The Course Audit has 1 warning: the Course’s Audit lists it after '
        'the import.',
      );
    });

    test('several Audit warnings', () {
      final found = of(
        file(),
        warnings: [for (var n = 1; n <= 7; n++) warning(n)],
      );
      expect(
        found.anomalies.single.text,
        'The Course Audit has 7 warnings: the Course’s Audit lists them '
        'after the import.',
      );
    });

    test('warnings beside the ones said in words are "other"', () {
      final written = file(
        lessons: [
          lesson('one', const []),
          lesson('two', [round('two')]),
        ],
      );
      final found = of(
        written,
        warnings: [
          CourseAuditIssue.fromCode(
            AuditCode.lessonRoundsEmpty,
            message: 'Lesson has no rounds yet.',
            location: 'Lesson 1',
          ),
          warning(1),
        ],
      );
      expect(kinds(found), [
        CourseImportAnomalyKind.lessonsWithoutRounds,
        CourseImportAnomalyKind.auditWarnings,
      ]);
      expect(
        text(found, CourseImportAnomalyKind.auditWarnings),
        'The Course Audit has 1 other warning: the Course’s Audit lists it '
        'after the import.',
      );
    });

    test('Audit errors are counted only where the file is not refused for '
        'them, in a Merge', () {
      final written = file();
      final course = Course.fromJson(written);
      // An import is refused for them before the pop-up: never listed.
      expect(
        CourseImportCheck.of(
          course,
          fileJson: written,
          auditErrors: 2,
        ).anomalies,
        isEmpty,
      );
      final one = CourseImportCheck.of(
        course,
        use: CourseFileUse.merge,
        fileJson: written,
        auditErrors: 1,
      );
      expect(kinds(one), [CourseImportAnomalyKind.auditErrors]);
      expect(
        one.anomalies.single.text,
        'The Course Audit has 1 error in this Course: a Merge whose result '
        'has Audit errors is refused.',
      );
      expect(
        CourseImportCheck.of(
          course,
          use: CourseFileUse.merge,
          fileJson: written,
          auditErrors: 3,
        ).anomalies.single.text,
        startsWith('The Course Audit has 3 errors in this Course'),
      );
    });

    test('exercises this version cannot play: one wording, also in the '
        'import’s result', () {
      expect(
        of(file(), notExecutable: 1).anomalies.single.text,
        '1 exercise cannot be played by this version of QuisquisLingo and is '
        'kept unchanged.',
      );
      final three = of(file(), notExecutable: 3);
      expect(kinds(three), [CourseImportAnomalyKind.notExecutable]);
      expect(
        three.anomalies.single.text,
        '3 exercises cannot be played by this version of QuisquisLingo and '
        'are kept unchanged.',
      );
      expect(
        CourseLibraryReports.notExecutableNote(3),
        ' ${CourseImportCheck.notExecutableText(3)}',
      );
      expect(CourseLibraryReports.notExecutableNote(0), '');
    });
  });

  test('the order: credits, audio, Lessons, the Audit, what cannot be '
      'played', () {
    final written = file(
      set: {'audioMode': 'mp3', 'audioLibrary': 'clips'},
      remove: ['authors', 'license'],
      lessons: [
        lesson('one', const []),
        lesson('two', [round('two')]),
      ],
    );
    final found = of(written, warnings: [warning(1)], notExecutable: 2);
    expect(kinds(found), [
      CourseImportAnomalyKind.noAuthor,
      CourseImportAnomalyKind.noLicense,
      CourseImportAnomalyKind.audioModeUnknown,
      CourseImportAnomalyKind.audioLibraryNotAList,
      CourseImportAnomalyKind.lessonsWithoutRounds,
      CourseImportAnomalyKind.auditWarnings,
      CourseImportAnomalyKind.notExecutable,
    ]);
    expect(found.hasAnomalies, isTrue);
    expect(found.reminders, [deviceVoice]);
  });

  group('the second Course of a Merge', () {
    CourseImportCheck merging(
      Map<String, dynamic> written, {
      List<CourseAuditIssue> warnings = const [],
      int auditErrors = 0,
      bool matchingZipFolder = false,
    }) => CourseImportCheck.of(
      Course.fromJson(written),
      use: CourseFileUse.merge,
      fileJson: written,
      warnings: warnings,
      auditErrors: auditErrors,
      matchingZipFolder: matchingZipFolder,
    );

    test('its author and license anomalies are listed as at import; its '
        'audio is the stored Course’s: no anomaly and no reminder for it', () {
      final written = file(
        set: {'audioMode': 'mp3', 'audioLibrary': 'clips'},
        remove: ['authors', 'license', 'rightsHolders'],
      );
      expect(kinds(of(written)), [
        CourseImportAnomalyKind.noAuthor,
        CourseImportAnomalyKind.noLicense,
        CourseImportAnomalyKind.audioModeUnknown,
        CourseImportAnomalyKind.audioLibraryNotAList,
      ]);
      final found = merging(written);
      expect(kinds(found), [
        CourseImportAnomalyKind.noAuthor,
        CourseImportAnomalyKind.noLicense,
      ]);
      expect(found.reminders, isEmpty);

      final holder = merging(file(remove: ['rightsHolders']));
      expect(
        holder.anomalies.single.text,
        'A license is stated (CC BY 4.0) but no Rights Holder is named.',
      );
      expect(
        merging(file(set: {'audioMode': 'hybrid'})).anomalies,
        isEmpty,
        reason: 'no line about recordings in a Merge',
      );
    });

    test('what concerns its Lessons is an anomaly, in the words of a '
        'Merge', () {
      final found = merging(
        file(
          lessons: [
            lesson('one', const []),
            lesson('two', [round('two')]),
          ],
        ),
        warnings: [warning(1), warning(2)],
        auditErrors: 1,
        matchingZipFolder: true,
      );
      expect(kinds(found), [
        CourseImportAnomalyKind.lessonsWithoutRounds,
        CourseImportAnomalyKind.auditErrors,
        CourseImportAnomalyKind.auditWarnings,
      ]);
      expect(
        text(found, CourseImportAnomalyKind.auditWarnings),
        'The Course Audit has 2 warnings in this Course.',
      );
      expect(found.reminders, [CourseImportCheck.matchingZipFolderText]);
    });

    test('it tells the same facts', () {
      final facts = merging(file()).facts;
      expect(facts.authors, 'Ada (Author)');
      expect(facts.content, 'Lessons: 1 · Rounds: 1 · Exercises: 1');
    });

    test('the words of each use', () {
      expect(CourseFileUse.import.doing, 'importing');
      expect(CourseFileUse.import.goOn, 'Import');
      expect(CourseFileUse.merge.doing, 'merging');
      expect(CourseFileUse.merge.goOn, 'Continue');
    });
  });

  group('a text of the file as the pop-up shows it', () {
    test('one line, at most so many characters', () {
      expect(CourseImportCheck.shown('  CC BY 4.0  '), 'CC BY 4.0');
      expect(CourseImportCheck.shown('a\n\nb\tc'), 'a b c');
      expect(CourseImportCheck.shown('x' * 80), 'x' * 80);
      expect(CourseImportCheck.shown('x' * 81), '${'x' * 80}…');
      expect(CourseImportCheck.shown('abcdef', 3), 'abc…');
      expect(CourseImportCheck.shown(''), '');
    });

    test('the cut never falls inside a character', () {
      // An emoji is two code units; half of one cannot be drawn.
      final cut = CourseImportCheck.shown('${'a' * 79}😀 and more', 80);
      expect(cut, '${'a' * 79}😀…');
      expect(CourseImportCheck.shown('😀' * 5, 3), '😀😀😀…');
      // A family emoji is one character made of several.
      expect(CourseImportCheck.shown('👨‍👩‍👧 x y', 2), '👨‍👩‍👧 …');
    });

    test('a very long license is shortened in the anomaly and in the '
        'facts', () {
      final written = file(set: {'license': 'L' * 5000});
      expect(of(written).facts.license, '${'L' * 80}… · Rights Holder: Ada');
    });
  });

  group('the file as written', () {
    test('a JSON object is read', () {
      final written = file(set: {'audioLibrary': 'clips'});
      final read = CourseImportCheck.fileJsonOf(
        utf8.encode(jsonEncode(written)),
      );
      expect(read, isNotNull);
      expect(read!['audioLibrary'], 'clips');
    });

    test('anything else gives nothing to compare with', () {
      expect(CourseImportCheck.fileJsonOf(utf8.encode('[1, 2]')), isNull);
      expect(CourseImportCheck.fileJsonOf(utf8.encode('{"a":')), isNull);
      expect(CourseImportCheck.fileJsonOf([0xff, 0xfe, 0x00]), isNull);
      expect(CourseImportCheck.fileJsonOf(const []), isNull);
    });
  });

  group('through the review of an import', () {
    late ProfileService profiles;
    late CourseEditorService editor;
    late CourseLibraryOperations ops;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      profiles = ProfileService();
      await profiles.createProfile(
        'Ada here',
        learnerProfileId: author,
        generateScreenNameSuffix: false,
      );
      await profiles.setActiveProfileById(author);
      editor = CourseEditorService();
      ops = CourseLibraryOperations(editor: editor);
    });

    Future<CourseImportReview> review(
      Map<String, dynamic> written, {
      bool matchingZipFolder = false,
      CourseManagerLibrary? readBefore,
    }) async {
      final library = readBefore ?? await ops.load(importOnly: true);
      final attempt = CoursePackageImport(
        CoursePackage(
          Course.fromJson(written),
          Uint8List.fromList(utf8.encode(jsonEncode(written))),
          const {},
          hadMatchingFolderWrapper: matchingZipFolder,
        ),
        editor: editor,
      );
      try {
        return await ops.reviewImport(attempt, library);
      } finally {
        await attempt.close();
      }
    }

    test(
      'the check compares the read Course with the file as written',
      () async {
        final result = await review(file(remove: ['license']));
        expect(result.blocked, isFalse);
        expect(
          result.check!.anomalies.map((item) => item.kind),
          contains(CourseImportAnomalyKind.noLicense),
        );
        expect(
          result.check!.anomalies
              .firstWhere(
                (item) => item.kind == CourseImportAnomalyKind.noLicense,
              )
              .text,
          contains('reads it as “All rights reserved”'),
        );
      },
    );

    test('it counts the Course Audit’s warnings of the review', () async {
      final written = file(
        lessons: [
          lesson('one', const []),
          lesson('two', [round('two')]),
        ],
      );
      final result = await review(written);
      final others = result.warnings
          .where((w) => w.code != AuditCode.lessonRoundsEmpty.code)
          .length;
      final kindsFound = [
        for (final item in result.check!.anomalies) item.kind,
      ];
      expect(
        kindsFound,
        contains(CourseImportAnomalyKind.lessonsWithoutRounds),
      );
      expect(
        kindsFound.contains(CourseImportAnomalyKind.auditWarnings),
        others > 0,
      );
    });

    test('the Maintainer and the Team by the names of this device', () async {
      final team = await TeamService(
        profileService: profiles,
      ).createTeam(creatorProfileId: author, displayName: 'Green Team');
      final result = await review(file(set: {'assignedTeamId': team.teamId}));
      expect(result.check!.facts.maintainer, 'Ada here');
      expect(result.check!.facts.team, 'Green Team');
    });

    test('a Teams list that cannot be read never stops an import', () async {
      // Course Studio keeps the library it read before; the import page
      // works with it.
      final library = await ops.load(importOnly: true);
      await (await SharedPreferences.getInstance()).setString(
        TeamService.storageKey,
        'not a list of Teams',
      );
      await expectLater(
        TeamService(profileService: profiles).listTeams(),
        throwsFormatException,
      );
      final result = await review(
        file(set: {'assignedTeamId': '22222222-2222-4222-8222-222222222222'}),
        readBefore: library,
      );
      expect(result.blocked, isFalse);
      expect(result.check!.facts.team, CourseImportFacts.teamNotRead);
    });

    test('a ZIP with its files in a folder of its name is reminded', () async {
      final result = await review(file(), matchingZipFolder: true);
      expect(
        result.check!.reminders.first,
        CourseImportCheck.matchingZipFolderText,
      );
    });

    test(
      'a file the Course Audit refuses is still reviewed as refused',
      () async {
        final result = await review(file(set: {'audioMode': 'recorded'}));
        expect(result.blocked, isTrue);
        expect(
          result.errors.map((issue) => issue.code),
          contains(AuditCode.recordedAudioLibraryEmpty.code),
        );
      },
    );

    test(
      'the same check for a Merge counts the Audit errors of the file',
      () async {
        final written = file(
          lessons: [
            lesson('one', [round('one'), round('two', empty: true)]),
          ],
        );
        final check = await ops.checkCourseFile(
          Course.fromJson(written),
          use: CourseFileUse.merge,
          courseJsonBytes: utf8.encode(jsonEncode(written)),
        );
        expect(
          check!.anomalies.map((item) => item.kind),
          contains(CourseImportAnomalyKind.auditErrors),
        );
        expect(check.facts.maintainer, 'Ada here');
        // The same file at import: refused for the error, never listed.
        final atImport = await ops.checkCourseFile(
          Course.fromJson(written),
          use: CourseFileUse.import,
          courseJsonBytes: utf8.encode(jsonEncode(written)),
        );
        expect(
          atImport!.anomalies.map((item) => item.kind),
          isNot(contains(CourseImportAnomalyKind.auditErrors)),
        );
      },
    );
  });
}
