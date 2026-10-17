import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_change_summary.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/lesson_presentation_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/course_changes_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/test_directories.dart';

// Build 274 Revision 5 (owner decisions of 16 October 2026): the "Unsaved
// course changes" question names what changed since the last save, the
// areas first, each opening to its details; text only; in both questions
// (leaving the Course Editor and leaving Edit).

/// The importable Laboratory: a custom Course with Lessons, Rounds and
/// every kind of exercise.
Map<String, dynamic> _json() =>
    jsonDecode(
          File(
            'test_courses/exercise_laboratory_en_it.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

Course _course([void Function(Map<String, dynamic> json)? change]) {
  final json = _json();
  change?.call(json);
  return Course.fromJson(json);
}

List<Map<String, dynamic>> _lessons(Map<String, dynamic> json) =>
    (json['lessons'] as List).cast<Map<String, dynamic>>();

List<Map<String, dynamic>> _rounds(Map<String, dynamic> lesson) =>
    (lesson['rounds'] as List).cast<Map<String, dynamic>>();

List<Map<String, dynamic>> _content(Map<String, dynamic> round) =>
    (round['content'] as List).cast<Map<String, dynamic>>();

/// [course] with the step [contentId] of the Round [roundId] removed, its
/// flow written again as the Round editor writes it.
Course _withoutStep(Course course, String roundId, String contentId) {
  final json = course.toJson();
  for (final (l, lesson) in course.lessons.indexed) {
    for (final (r, round) in lesson.rounds.indexed) {
      if (round.id != roundId) continue;
      final kept = [
        for (final entry in round.content)
          if (entry.id != contentId) entry,
      ];
      final roundJson = _rounds(_lessons(json)[l])[r];
      roundJson['content'] = [for (final entry in kept) entry.toJson()];
      roundJson['flow'] = RoundFlowAuthoring.forContent(
        round.flow,
        kept,
      )!.toJson();
    }
  }
  return Course.fromJson(json);
}

Map<String, List<String>> _summary(Course saved, Course working) => {
  for (final area in CourseChangeSummary.between(saved, working))
    area.title: area.details,
};

void main() {
  final saved = _course();
  String lesson(Course course, int index) =>
      const LessonPresentationService().identity(course, index).fullText;

  test('nothing changed is nothing to name', () {
    expect(CourseChangeSummary.between(saved, _course()), isEmpty);
  });

  test('a time stamp is never a change, beside a real one either', () {
    void stamp(Map<String, dynamic> json) {
      for (final lessonJson in _lessons(json)) {
        lessonJson['updatedAt'] = '2030-01-01T00:00:00.000Z';
        for (final round in _rounds(lessonJson)) {
          round['updatedAt'] = '2030-01-01T00:00:00.000Z';
          for (final content in _content(round)) {
            final exercise = content['exercise'];
            if (exercise is Map) {
              exercise['updatedAt'] = '2030-01-01T00:00:00.000Z';
            }
          }
        }
      }
    }

    expect(CourseChangeSummary.between(saved, _course(stamp)), isEmpty);
    // The second Lesson renamed, every Lesson, Round and exercise stamped
    // (Rename and Apply stamp what they touch): one line.
    final working = _course((json) {
      stamp(json);
      _lessons(json)[1]['title'] = 'Renamed';
    });
    expect(_summary(saved, working), {
      CourseChangeSummary.lessons: ['${lesson(working, 1)}: its title'],
    });
  });

  test('Course Info in the form\'s order, Draft or Published, Lesson '
      'Options, Version history', () {
    final working = _course((json) {
      json['temporarySample'] = true;
      json['courseDescription'] = 'Another description';
      json['allowPageSharing'] = false;
      json['languageVariant'] = 'Tuscan';
      json['title'] = 'Another title';
      json['publicationState'] = 'draft';
      json['useGuidebook'] = false;
      json['lessonNumberingMode'] = 'numberOnly';
      json['restoredFromVersion'] = 1;
    });
    final summary = _summary(saved, working);
    expect(summary.keys, [
      CourseChangeSummary.courseInfo,
      CourseChangeSummary.versionHistory,
      CourseChangeSummary.courseState,
      CourseChangeSummary.lessonOptions,
    ]);
    expect(summary[CourseChangeSummary.courseInfo], [
      'Course name',
      'Language variant',
      'Course description',
      'Learners may share, save and print pages',
      'Private course',
    ]);
    expect(summary[CourseChangeSummary.versionHistory], [
      'Version 1 loaded from Version history',
    ]);
    expect(summary[CourseChangeSummary.courseState], [
      'The Course is now Draft',
    ]);
    expect(summary[CourseChangeSummary.lessonOptions], [
      'Lesson label and numbering',
      'Use GuideBook',
    ]);
  });

  test('the Audio Library: its source, each recording', () {
    final withClips = _course((json) {
      json['audioMode'] = 'hybrid';
      json['audioLibrary'] = [
        {'id': 'a', 'text': 'uno', 'filePath': 'assets/audio_274/a.mp3'},
        {'id': 'b', 'text': 'due', 'filePath': 'assets/audio_274/b.mp3'},
        {'id': 'c', 'text': '', 'filePath': 'assets/audio_274/c.mp3'},
      ];
    });
    final changed = _course((json) {
      json['audioMode'] = 'tts';
      json['audioLibrary'] = [
        {'id': 'a', 'text': 'UNO', 'filePath': 'assets/audio_274/a.mp3'},
        {'id': 'c', 'text': '', 'filePath': 'assets/audio_274/c.mp3'},
        {'id': 'd', 'text': 'tre', 'filePath': 'assets/audio_274/d.mp3'},
      ];
    });
    expect(_summary(withClips, changed)[CourseChangeSummary.audioLibrary], [
      'Audio source: Hybrid: MP3 + TTS fallback → On-Device TTS',
      'Recording “UNO”: changed',
      'Recording “tre”: added',
      'Recording “due”: removed',
    ]);
    final reordered = _course((json) {
      json['audioMode'] = 'hybrid';
      json['audioLibrary'] = [
        {'id': 'b', 'text': 'due', 'filePath': 'assets/audio_274/b.mp3'},
        {'id': 'a', 'text': 'uno', 'filePath': 'assets/audio_274/a.mp3'},
        {'id': 'c', 'text': '', 'filePath': 'assets/audio_274/c.mp3'},
      ];
    });
    expect(_summary(withClips, reordered)[CourseChangeSummary.audioLibrary], [
      'The order of the recordings',
    ]);
    // The owner's case: to MP3 and back, through the copy the Audio
    // Library makes, is no change.
    final there = _course((json) => json['audioMode'] = 'recorded');
    final back = Course.fromJson({
      ...there.toJson(),
      'audioMode': saved.audioMode,
    });
    expect(_summary(saved, there).keys, [CourseChangeSummary.audioLibrary]);
    expect(CourseChangeSummary.between(saved, back), isEmpty);
  });

  test('Story characters by name: added, changed, removed', () {
    final working = _course((json) {
      final characters = (json['storyCharacters'] as List)
          .cast<Map<String, dynamic>>();
      final anna = characters.first;
      json['storyCharacters'] = [
        {...anna, 'name': 'Anna Maria'},
        {
          'id': 'zz_new',
          'name': 'Zoe',
          'avatar': 'assets/avatars/cat.png',
          'language': 'target',
        },
      ];
    });
    expect(_summary(saved, working)[CourseChangeSummary.storyCharacters], [
      'Character “Anna Maria”: changed',
      'Character “Zoe”: added',
      'Character “Luca”: removed',
    ]);
  });

  test('Lessons, Rounds and exercises, named as the breadcrumbs name them', () {
    final working = _course((json) {
      final lessons = _lessons(json);
      final rounds = _rounds(lessons.first);
      // The second exercise of the first Round changes; the third goes.
      final content = _content(rounds.first);
      final exercise = content[1]['exercise'] as Map<String, dynamic>;
      exercise['hint'] = 'A new hint';
      content.removeAt(2);
      // A Round is added at the end of the second Lesson.
      final second = _rounds(lessons[1]);
      second.add({
        ...second.first,
        'id': 'r274_5_added',
        'title': 'An added Round',
        'content': <Object?>[],
      });
      // The second Round of the first Lesson gets a new title.
      rounds[1]['title'] = 'A new title';
      // The last Lesson goes.
      lessons.removeLast();
    });
    final first = lesson(saved, 0);
    final round = saved.lessons.first.rounds.first;
    // Round numbering is off in the Laboratory: the type, then the title.
    final roundName = 'Practice: ${round.title}';
    final lines = _summary(saved, working)[CourseChangeSummary.lessons]!;
    expect(lines, [
      '$first › $roundName › Exercise 2: changed',
      '$first › $roundName › Exercise 3: removed',
      '$first › Practice: A new title: its title',
      '${lesson(working, 1)} › Practice: An added Round: added',
      '${lesson(saved, saved.lessons.length - 1)}: removed',
    ]);
  });

  test('Round labels follow the Course\'s numbering', () {
    final numbered = _course(
      (json) => json['roundNumberingMode'] = 'roundAndNumber',
    );
    final working = Course.fromJson(
      numbered.toJson()..update('lessons', (lessons) {
        final round = _rounds(
          (lessons as List).first as Map<String, dynamic>,
        ).first;
        round['title'] = 'Coffee';
        return lessons;
      }),
    );
    final line = _summary(
      numbered,
      working,
    )[CourseChangeSummary.lessons]!.single;
    expect(
      line,
      '${lesson(numbered, 0)} › Round 1 · Practice: Coffee: its title',
    );
  });

  test('Rounds that would read alike are told apart by their place', () {
    Course untitled([void Function(List<Map<String, dynamic>> rounds)? more]) =>
        _course((json) {
          final rounds = _rounds(_lessons(json).first);
          rounds[0].remove('title');
          rounds[1].remove('title');
          more?.call(rounds);
        });
    final before = untitled();
    final after = untitled((rounds) {
      final exercise = _content(rounds[1])[1]['exercise'] as Map;
      exercise['hint'] = 'A new hint';
    });
    expect(_summary(before, after)[CourseChangeSummary.lessons], [
      '${lesson(before, 0)} › Practice (2nd in the list) › Exercise 2: changed',
    ]);
    // The first goes, the second changes and takes its place: the removed
    // one says the place it had.
    final shifted = untitled((rounds) {
      rounds.removeAt(0);
      final exercise = _content(rounds[0])[1]['exercise'] as Map;
      exercise['hint'] = 'A new hint';
    });
    expect(_summary(before, shifted)[CourseChangeSummary.lessons], [
      '${lesson(before, 0)} › Practice (1st in the list) › Exercise 2: changed',
      '${lesson(before, 0)} › Practice (was 1st in the list): removed',
    ]);
  });

  test('two Lessons sharing one ID are still a change', () {
    final twice = _course((json) {
      final lessons = _lessons(json);
      lessons[1]['lessonId'] = lessons[0]['lessonId'];
    });
    final working = _course((json) {
      final lessons = _lessons(json);
      lessons[1]['lessonId'] = lessons[0]['lessonId'];
      lessons[0] = {...lessons[1]};
      json['title'] = 'Another title';
    });
    final summary = _summary(twice, working);
    expect(summary[CourseChangeSummary.courseInfo], ['Course name']);
    expect(summary[CourseChangeSummary.lessons], [CourseChangeSummary.unnamed]);
  });

  test('the GuideBook, and a Story\'s steps apart from its options', () {
    final withGuidebook = _course((json) {
      final module =
          (((_lessons(json).first['guidebook'] as Map)['modules'] as List).first
              as Map<String, dynamic>);
      module['title'] = 'Another module title';
    });
    expect(_summary(saved, withGuidebook)[CourseChangeSummary.lessons], [
      '${lesson(saved, 0)} › GuideBook',
    ]);
    // A Story's line removed: the step goes, its flow is written again
    // from the content; that is no change of its options.
    final storyLesson = saved.lessons.indexWhere(
      (l) => l.rounds.any((r) => r.id == 'qql_lab254_round_story_cafe'),
    );
    const storyRound = 'qql_lab254_round_story_cafe';
    for (final (step, place) in [
      ('qql_lab254_story_cover', 2),
      // Marked "Needs the Story's audio": its mark goes with it.
      ('qql_lab254_story_true_false', 9),
    ]) {
      final story = _withoutStep(saved, storyRound, step);
      final lines = _summary(saved, story)[CourseChangeSummary.lessons]!;
      expect(lines, hasLength(1), reason: step);
      expect(lines.single, endsWith(' › Exercise $place: removed'));
    }
    // The mark itself, put on a step that stays, is an option.
    final marked = _course((json) {
      final round = _rounds(
        _lessons(json)[storyLesson],
      ).firstWhere((r) => r['id'] == storyRound);
      for (final node in (round['flow']['nodes'] as List).cast<Map>()) {
        if (node['contentId'] == 'qql_lab254_story_order') {
          node['requiresAudio'] = true;
        }
      }
    });
    expect(
      _summary(saved, marked)[CourseChangeSummary.lessons]!.single,
      endsWith(': its sequence or Story options'),
    );
    // Its title, which the flow keeps, is its title.
    final retitled = _course((json) {
      final round = _rounds(
        _lessons(json)[storyLesson],
      ).firstWhere((r) => r['id'] == storyRound);
      (round['flow'] as Map<String, dynamic>)['title'] = 'Another Story';
    });
    final retitledLines = _summary(
      saved,
      retitled,
    )[CourseChangeSummary.lessons]!;
    expect(retitledLines, hasLength(1));
    expect(retitledLines.single, endsWith(': its title'));
  });

  test('the order alone is said as the order', () {
    final working = _course((json) {
      final lessons = _lessons(json);
      final first = lessons.removeAt(0);
      lessons.insert(1, first);
    });
    expect(_summary(saved, working)[CourseChangeSummary.lessons], [
      'The order of the Lessons',
    ]);
  });

  test('a field no area names is still named', () {
    final working = _course((json) => json['versionNotes'] = 'Notes');
    expect(_summary(saved, working)[CourseChangeSummary.other], [
      'versionNotes',
    ]);
  });

  testWidgets('a Course never saved says so, with or without changes', (
    tester,
  ) async {
    Future<void> show(List<CourseChangeArea> areas) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CourseChangesList(areas: areas, neverSaved: true)),
      ),
    );
    await show(const []);
    expect(find.byKey(const Key('course-changes-never-saved')), findsOneWidget);
    expect(find.byKey(const Key('course-changes')), findsNothing);
    await show(const [
      CourseChangeArea(CourseChangeSummary.courseInfo, ['Course name']),
    ]);
    expect(find.byKey(const Key('course-changes-never-saved')), findsOneWidget);
    expect(find.text('What changed since it was created:'), findsOneWidget);
  });

  group('the question', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      _platforms();
      keepCrashLogUnavailable();
    });

    Future<bool Function()> open(WidgetTester tester) async {
      final course = _editable();
      final profiles = ProfileService();
      await profiles.createProfile('Author', learnerProfileId: _profileId);
      await profiles.setActiveProfileById(_profileId);
      await SettingsService().markAudioOrphanCheckRun('IT');
      await SettingsService().setCourseEditorMode(
        course.courseId,
        CourseEditorMode.edit,
      );
      await tester.runAsync(() => CourseEditorService().saveUserCourse(course));
      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                await Navigator.of(context).push<CourseConfirmationResult>(
                  MaterialPageRoute(
                    builder: (_) => CourseEditorScreen(
                      course: course,
                      access: CourseAccessPolicy.evaluate(
                        course,
                        profileId: _profileId,
                      ),
                    ),
                  ),
                );
                popped = true;
              },
              child: const Text('Open Course'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Course'));
      await tester.pumpAndSettle();
      return () => popped;
    }

    Future<void> applyStudyHours(WidgetTester tester) async {
      await tester.tap(find.text('Course Info Editor'));
      await tester.pumpAndSettle();
      final hours = find.byKey(const Key('course-info-estimated-hours'));
      await tester.ensureVisible(hours);
      await tester.enterText(hours, '12');
      await tester.pump();
      final apply = find.byKey(const Key('course-info-save'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpUntilFileIoState(() => apply.evaluate().isEmpty);
    }

    testWidgets('leaving names the areas; an area opens to its details', (
      tester,
    ) async {
      final popped = await open(tester);
      await applyStudyHours(tester);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      final dialog = find.byKey(const Key('course-transaction-confirmation'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.byKey(const Key('course-changes')),
        ),
        findsOneWidget,
      );
      final area = find.byKey(const ValueKey('course-change-area-0'));
      expect(
        find.descendant(of: area, matching: find.text('Course Info')),
        findsOneWidget,
      );
      // Closed at first: the details show when the area is opened.
      expect(
        find.byKey(const ValueKey('course-change-detail-0-0')),
        findsNothing,
      );
      await tester.tap(area);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('course-change-detail-0-0')),
            )
            .data,
        '• Estimated study hours',
      );
      await tester.tap(find.byKey(const Key('cancel-course-changes')));
      await tester.pumpUntilFileIoState(popped);
    });

    testWidgets('leaving Edit names them too', (tester) async {
      await open(tester);
      await applyStudyHours(tester);
      await tester.tap(find.byKey(const Key('course-editor-lock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(CourseEditorMode.viewOnly.label));
      await tester.pumpAndSettle();
      final dialog = find.byKey(const Key('course-transaction-confirmation'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.byKey(const ValueKey('course-change-area-0')),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
    });

    testWidgets('the audio source to MP3 and back asks nothing on leaving', (
      tester,
    ) async {
      final popped = await open(tester);
      // The Audio Library's tile is lower on the page (a lazy list).
      await tester.scrollUntilVisible(
        find.text('Audio Library'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Audio Library'));
      await tester.pumpUntilFileIoState(
        () => find.byKey(const Key('audio-source')).evaluate().isNotEmpty,
      );
      Future<void> choose(String source) async {
        await tester.tap(find.byKey(const Key('audio-source')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(source).last);
        await tester.pumpAndSettle();
      }

      String source() => tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('audio-source')),
          )
          .initialValue!;
      await choose('Recorded MP3 only');
      expect(source(), 'recorded');
      await choose('On-Device TTS');
      expect(source(), 'tts');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpUntilFileIoState(popped);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsNothing,
      );
    });
  });
}

const _profileId = '31111111-1111-4111-8111-111111111111';

/// The Course's media folder and the Audio Library's player.
void _platforms() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => testSupportDirectory.path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/${arguments['playerId']}',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

/// A custom Course of the learner [_profileId] with no Lessons.
Course _editable() => Course(
  courseId: 'course-changes-274',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course changes',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  license: 'All rights reserved',
  rightsHolders: const [
    CourseRightsHolder(
      type: CourseRightsHolderType.person,
      name: 'Test Author',
    ),
  ],
  derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
  lessons: const [],
);
