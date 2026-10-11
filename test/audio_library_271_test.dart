import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_destinations.dart';
import 'package:quisquislingo_app/localization/help/help_en.dart';
import 'package:quisquislingo_app/localization/help/help_es.dart';
import 'package:quisquislingo_app/localization/help/help_it.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/audio_texts_screen.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/services/audio_library_index.dart';
import 'package:quisquislingo_app/services/audio_segmenter.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audio_texts.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/publisher_course_export.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:quisquislingo_app/widgets/folder_opener.dart';
import 'package:quisquislingo_app/widgets/library_save_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_file_dialog_backend.dart';
import 'support/pump_file_io.dart';

// Build 271 Revision 2 (owner decisions of 10 and 11 October 2026): the
// Audio Library like the Image Library. Three icons in its top bar, a fixed
// header, rows without file names, Associate recording with the file's
// names, Texts in this Course, and the name a recording's file came with.

const _alice = '11111111-1111-4111-8111-111111111111';
const _passage = 'Maria compra due mele e un chilo di pane al mercato.';
const _train = 'Il treno per Roma parte alle nove.';
final _stored = 'media:${'ab' * 32}.mp3';

typedef _Clip = ({String id, String text, String file, String original});

_Clip _clip(String id, String text, {String? file, String original = ''}) => (
  id: id,
  text: text,
  file: file ?? 'assets/audio_library_271_test/$id.mp3',
  original: original,
);

Map<String, dynamic> _laboratoryJson() =>
    jsonDecode(
          File(
            'assets/courses/exercise_laboratory_en_it.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

/// The Laboratory with [clips] as its Audio Library.
Course _course(
  List<_Clip> clips, {
  String audioMode = 'recorded',
  Map<String, dynamic> changes = const {},
}) => Course.fromJson({
  ..._laboratoryJson(),
  'audioMode': audioMode,
  'audioLibrary': [
    for (final clip in clips)
      {
        'id': clip.id,
        'text': clip.text,
        'filePath': clip.file,
        if (clip.original.isNotEmpty) 'originalFileName': clip.original,
      },
  ],
  ...changes,
});

final _library = [
  _clip('maria', 'Maria compra'),
  _clip('mele', 'due mele'),
  _clip('pane', 'e un chilo di pane'),
  _clip('mercato', 'al mercato'),
  _clip('roma', 'per Roma'),
  _clip('giorno', 'buongiorno', original: 'buongiorno take 2.mp3'),
  _clip('new', '', original: 'grazie mille.mp3'),
];

CourseSpokenText _text(List<CourseSpokenText> texts, String text) =>
    texts.singleWhere((entry) => entry.text == text);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the name a recording’s file came with', () {
    test('is a label: the base name, no control characters, 120 characters '
        'at most', () {
      expect(CourseAudioClip.labelOf('buongiorno.mp3'), 'buongiorno.mp3');
      expect(
        CourseAudioClip.labelOf(r'C:\Users\Anna\Recordings\ciao.mp3'),
        'ciao.mp3',
      );
      expect(CourseAudioClip.labelOf('/home/anna/audio/ciao.mp3'), 'ciao.mp3');
      expect(CourseAudioClip.labelOf('ci\u0007ao\n.mp3'), 'ciao.mp3');
      final long = CourseAudioClip.labelOf('${'a' * 200}.mp3');
      expect(long, hasLength(CourseAudioClip.maxOriginalFileNameLength));
    });

    test('is stored only when known and read back', () {
      const known = CourseAudioClip(
        id: 'a',
        text: 'ciao',
        filePath: 'assets/a.mp3',
        originalFileName: 'ciao.mp3',
      );
      const unknown = CourseAudioClip(
        id: 'b',
        text: 'ciao',
        filePath: 'assets/b.mp3',
      );
      expect(known.toJson()['originalFileName'], 'ciao.mp3');
      expect(unknown.toJson().containsKey('originalFileName'), isFalse);
      expect(
        CourseAudioClip.fromJson(known.toJson()).originalFileName,
        'ciao.mp3',
      );
      expect(CourseAudioClip.fromJson(unknown.toJson()).originalFileName, '');
    });

    test('a path, a control character, a long name or another type is a '
        'format error', () {
      Map<String, dynamic> json(Object? name) => {
        'id': 'a',
        'text': 'ciao',
        'filePath': 'assets/a.mp3',
        'originalFileName': name,
      };
      for (final bad in <Object?>[
        'folder/ciao.mp3',
        r'folder\ciao.mp3',
        'ci\nao.mp3',
        'a' * 121,
        7,
        null,
      ]) {
        expect(
          () => CourseAudioClip.fromJson(json(bad)),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('a new text keeps it; a copy of the Course keeps it', () {
      const clip = CourseAudioClip(
        id: 'a',
        text: '',
        filePath: 'assets/a.mp3',
        originalFileName: 'ciao.mp3',
      );
      final texted = clip.withText('ciao');
      expect(texted.text, 'ciao');
      expect(texted.id, 'a');
      expect(texted.filePath, 'assets/a.mp3');
      expect(texted.originalFileName, 'ciao.mp3');

      final source = _custom(_course(_library));
      final copy = AuthoringDuplicationService().copyCourseAsNew(
        source,
        title: 'A copy',
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: _alice,
          displayName: 'Alice',
        ),
        maintainer: const CourseMaintainer(_alice),
      );
      expect(
        copy.audioLibrary.map((clip) => clip.originalFileName),
        source.audioLibrary.map((clip) => clip.originalFileName),
      );
    });

    test('Export as Publisher Course leaves it out', () {
      final exported = PublisherCourseExport.build(
        _custom(_course(_library)),
        const PublisherIdentity(
          publisherId: 'org.example.courses',
          publisherName: 'Example Courses',
        ),
        now: DateTime.utc(2026, 10, 11, 12),
      );
      expect(exported.audioLibrary, hasLength(_library.length));
      expect(
        exported.audioLibrary.every((clip) => clip.originalFileName.isEmpty),
        isTrue,
      );
      expect(jsonEncode(exported.toJson()), isNot(contains('take 2')));
    });
  });

  group('how far the recordings go in a text', () {
    final clips = _course(_library).audioLibrary;

    test('a text recordings say whole: the recordings playback joins', () {
      final coverage = AudioSegmenter.coverage(_passage, clips);
      expect(coverage.complete, isTrue);
      expect(coverage.missing, isEmpty);
      expect(coverage.clips.map((clip) => clip.id), [
        'maria',
        'mele',
        'pane',
        'mercato',
      ]);
      expect(
        RecordedAudioService().segment(_passage, clips)!.map((clip) => clip.id),
        coverage.clips.map((clip) => clip.id),
        reason: 'one rule for playback and for the list',
      );
    });

    test('a text with words no recording says: those words, as written', () {
      final coverage = AudioSegmenter.coverage(_train, clips);
      expect(coverage.complete, isFalse);
      expect(coverage.clips.map((clip) => clip.id), ['roma']);
      expect(coverage.missing, ['Il treno', 'parte alle nove']);
      expect(RecordedAudioService().segment(_train, clips), isNull);
    });

    test('capitals and the punctuation around a text do not count', () {
      for (final text in ['Buongiorno.', 'buongiorno', '«Buongiorno!»']) {
        final coverage = AudioSegmenter.coverage(text, clips);
        expect(coverage.complete, isTrue, reason: text);
        expect(coverage.clips.single.id, 'giorno', reason: text);
      }
      expect(AudioSegmenter.coverage('Grazie mille!', clips).clips, isEmpty);
      expect(AudioSegmenter.coverage('Grazie mille!', clips).missing, [
        'Grazie mille',
      ]);
    });
  });

  group('Texts in this Course', () {
    test('every spoken text with its state, in alphabetical order without '
        'regard to accents', () {
      final texts = CourseAudioTexts.of(_course(_library));
      expect(_text(texts, _passage).state, AudioTextState.allParts);
      expect(_text(texts, 'Buongiorno.').state, AudioTextState.ownRecording);
      final train = _text(texts, _train);
      expect(train.state, AudioTextState.someParts);
      expect(train.missing, ['Il treno', 'parte alle nove']);
      expect(
        CourseAudioTexts.stateLabel(train),
        'Some parts recorded, still missing: Il treno, parte alle nove',
      );
      final thanks = _text(texts, 'Grazie mille!');
      expect(thanks.state, AudioTextState.none);
      expect(thanks.complete, isFalse);
      expect(CourseAudioTexts.stateLabel(thanks), 'No recording');
      expect(thanks.exercises, greaterThanOrEqualTo(1));
      expect(thanks.draft, isFalse);

      final keys = [
        for (final text in texts) AudioLibraryIndex.sortKey(text.text),
      ];
      expect(keys, [...keys]..sort());
      final names = [for (final text in texts) text.text];
      expect(
        names.indexOf('È vicino al parco.'),
        greaterThan(names.indexOf("Dov'è la stazione?")),
      );
      expect(
        names.indexOf('È vicino al parco.'),
        lessThan(names.indexOf('gatto')),
        reason: 'È is filed with E, not after Z',
      );
    });

    test('a text only Draft content says is marked Draft', () {
      final json = _laboratoryJson();
      final lessons = (json['lessons'] as List).cast<Map<String, dynamic>>();
      final published = CourseAudioTexts.of(_course(const []));
      final draft = CourseAudioTexts.of(
        _course(
          const [],
          changes: {
            'lessons': [
              for (final lesson in lessons)
                {...lesson, 'publicationState': 'draft'},
            ],
          },
        ),
      );
      expect(published.any((text) => text.draft), isFalse);
      expect(draft, hasLength(published.length));
      expect(draft.every((text) => text.draft), isTrue);
      expect(CourseAudioTexts.line(draft.first), endsWith('\tDraft'));
    });

    test('the search ignores capitals and accents; the switch keeps what is '
        'still to record', () {
      final texts = CourseAudioTexts.of(_course(_library));
      expect(
        CourseAudioTexts.filtered(
          texts,
          query: 'E VICINO',
        ).map((text) => text.text),
        ['È vicino al parco.'],
      );
      final incomplete = CourseAudioTexts.filtered(texts, onlyIncomplete: true);
      expect(incomplete, isNotEmpty);
      expect(incomplete.every((text) => !text.complete), isTrue);
      expect(incomplete.map((text) => text.text), isNot(contains(_passage)));
      expect(incomplete.map((text) => text.text), contains(_train));
      expect(CourseAudioTexts.filtered(texts), texts);
    });

    test('Copy and Save as… give one text per line with its state', () {
      final texts = CourseAudioTexts.of(_course(_library));
      final lines = const LineSplitter().convert(
        CourseAudioTexts.export(texts),
      );
      expect(lines, hasLength(texts.length));
      expect(lines, contains('$_passage\tAll parts recorded'));
      expect(lines, contains('Buongiorno.\tIts own recording'));
      expect(
        lines,
        contains(
          '$_train\tSome parts recorded, still missing: Il treno, parte '
          'alle nove',
        ),
      );
      expect(CourseAudioTexts.export(const []), '');
      expect(
        CourseAudioTexts.line(
          const CourseSpokenText(
            text: 'Ciao.\n  Come stai?',
            exercises: 1,
            draft: false,
            state: AudioTextState.none,
            missing: [],
          ),
        ),
        'Ciao. Come stai?\tNo recording',
      );
      final name = CourseAudioTexts.exportFileName(_course(_library));
      expect(name, startsWith('QQL_EN_IT_'));
      expect(name, endsWith('_texts.txt'));
    });

    test('a text that already has its own recording is found, whatever its '
        'capitals', () {
      final clips = _course(_library).audioLibrary;
      expect(
        CourseAudioTexts.ownRecordingOf(
          'Buongiorno.',
          clips,
          except: 'new',
        )!.id,
        'giorno',
      );
      expect(
        CourseAudioTexts.ownRecordingOf('Buongiorno.', clips, except: 'giorno'),
        isNull,
      );
      expect(
        CourseAudioTexts.ownRecordingOf('Arrivederci', clips, except: 'new'),
        isNull,
      );
      expect(
        CourseAudioTexts.ownRecordingOf('…', clips, except: 'new'),
        isNull,
      );
    });

    testWidgets('the screen lists, searches, filters and copies', (
      tester,
    ) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final course = _course(_library);
      final all = CourseAudioTexts.of(course);
      final dialogs = FakeFileDialogBackend();
      await tester.pumpWidget(
        MaterialApp(
          home: AudioTextsScreen(
            course: course,
            dialogs: FileDialogService(
              backend: dialogs,
              stager: testImportStager(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      String count() =>
          tester.widget<Text>(find.byKey(const Key('audio-texts-count'))).data!;
      expect(count(), '${all.length} texts');

      await tester.enterText(
        find.byKey(const Key('audio-texts-search')),
        'treno',
      );
      await tester.pumpAndSettle();
      final found = CourseAudioTexts.filtered(all, query: 'treno');
      expect(count(), '${found.length} of ${all.length} texts');
      expect(find.text(_train), findsOneWidget);
      expect(
        find.textContaining('still missing: Il treno, parte alle nove'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('audio-texts-copy')));
      await tester.pump();
      expect(copied.single, CourseAudioTexts.export(found));
      expect(find.byKey(const Key('audio-texts-copied')), findsOneWidget);

      await tester.tap(find.byKey(const Key('audio-texts-save-as')));
      await tester.pumpUntilFileIoState(() => dialogs.saved.isNotEmpty);
      expect(
        dialogs.saved.single.name,
        CourseAudioTexts.exportFileName(course),
      );
      expect(
        utf8.decode(dialogs.saved.single.bytes),
        CourseAudioTexts.export(found),
      );

      await tester.enterText(find.byKey(const Key('audio-texts-search')), '');
      await tester.tap(find.byKey(const Key('audio-texts-only-incomplete')));
      await tester.pumpAndSettle();
      final incomplete = CourseAudioTexts.filtered(all, onlyIncomplete: true);
      expect(count(), '${incomplete.length} of ${all.length} texts');

      await tester.enterText(
        find.byKey(const Key('audio-texts-search')),
        'no such text anywhere',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('audio-texts-empty')), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('audio-texts-copy')))
            .onPressed,
        isNull,
      );
    });
  });

  group('the Audio Library', () {
    Future<void> open(
      WidgetTester tester,
      Course course, {
      Size size = const Size(900, 1400),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: AudioLibraryScreen(course: course)),
      );
      await tester.pumpAndSettle();
    }

    List<_Clip> many() => [
      for (final letter in 'abcdefghijklmnopqrst'.split(''))
        for (var i = 1; i <= 4; i++) _clip('$letter$i', '${letter}word $i'),
    ];

    testWidgets('three icons in the top bar: Help, Add to the Course, Check', (
      tester,
    ) async {
      await open(tester, _course(_library));
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.actions, hasLength(3));
      expect(find.byTooltip('Help: sound'), findsOneWidget);
      expect(find.byTooltip('Add to the Course'), findsOneWidget);
      expect(find.byTooltip('Check'), findsOneWidget);

      await tester.tap(find.byKey(const Key('audio-library-help')));
      await tester.pumpAndSettle();
      expect(find.byType(EditorHelpScreen), findsOneWidget);
      expect(
        find.byKey(const Key('editor-help-question-audioModes')),
        findsOneWidget,
      );
    });

    testWidgets('On-Device TTS greys the two menus and says why', (
      tester,
    ) async {
      await open(tester, _course(_library, audioMode: 'tts'));
      expect(
        find.byTooltip(
          'Add to the Course: choose Recorded MP3 only or Hybrid first',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Check: choose Recorded MP3 only or Hybrid first'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('audio-library-empty')), findsNothing);
    });

    testWidgets('the notice is the shared line; the header stays while the '
        'recordings scroll', (tester) async {
      await open(tester, _course(many()), size: const Size(900, 900));
      final notice = find.byKey(const Key('audio-library-save-notice'));
      expect(
        tester.widget<LibrarySaveNotice>(notice),
        isA<LibrarySaveNotice>(),
      );
      expect(
        find.text(
          'Changes are applied to the Course when you leave; Save now or '
          'Save course writes them.',
        ),
        findsOneWidget,
      );
      final before = tester.getTopLeft(notice).dy;
      expect(find.text('aword 1'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('audio-library-list')),
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();
      expect(find.text('aword 1'), findsNothing);
      expect(tester.getTopLeft(notice).dy, before);
      expect(find.byKey(const Key('audio-source')), findsOneWidget);
      expect(find.byKey(const Key('audio-library-letters')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a window too short for a fixed header scrolls it away', (
      tester,
    ) async {
      await open(tester, _course(many()), size: const Size(900, 440));
      final notice = find.byKey(const Key('audio-library-save-notice'));
      expect(notice, findsOneWidget);
      await tester.drag(
        find.byKey(const Key('audio-library-list')),
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();
      expect(notice, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a recording with a text shows no file name; one without '
        'asks for its text and shows the name its file came with', (
      tester,
    ) async {
      await open(tester, _course(_library));
      expect(find.text(AudioLibraryScreen.noTextLabel), findsOneWidget);
      expect(find.text('Tap to give it its text'), findsOneWidget);
      // Follow-up (owner decision of 11 October 2026): the original name in
      // grey on the row without text, and only there.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('audio-clip-original-new')))
            .data,
        'grazie mille.mp3',
      );
      expect(find.textContaining('.mp3'), findsOneWidget);
      expect(
        find.byKey(const Key('audio-clip-original-giorno')),
        findsNothing,
        reason: 'buongiorno has a text, so its file name stays in the dialog',
      );
      expect(find.textContaining('assets/'), findsNothing);
      expect(find.text('Unassigned MP3'), findsNothing);
    });

    testWidgets('a recording without text and without a known original name '
        'shows only the request', (tester) async {
      await open(tester, _course([_clip('old', '')]));
      expect(find.text(AudioLibraryScreen.noTextLabel), findsOneWidget);
      expect(find.byKey(const Key('audio-clip-original-old')), findsNothing);
      expect(find.textContaining('.mp3'), findsNothing);
    });

    testWidgets('an empty library in a recorded mode says how to add', (
      tester,
    ) async {
      await open(tester, _course(const []));
      expect(find.byKey(const Key('audio-library-empty')), findsOneWidget);
    });

    group('Associate recording', () {
      Future<void> tapRow(WidgetTester tester, String id) async {
        await tester.tap(find.byKey(Key('audio-clip-row-$id')));
        await tester.pumpAndSettle();
      }

      testWidgets('shows the name the file came with and the stored name in '
          'full; Apply waits for a text', (tester) async {
        await open(
          tester,
          _course([
            _clip('new', '', file: _stored, original: 'grazie mille.mp3'),
            _clip('old', 'pane'),
          ]),
        );
        await tester.pumpUntilFileIoState(
          () => find
              .byKey(const Key('audio-clip-missing-new'))
              .evaluate()
              .isNotEmpty,
        );
        await tapRow(tester, 'new');
        expect(find.byKey(const Key('audio-associate-dialog')), findsOneWidget);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('audio-associate-original')),
              )
              .data,
          'grazie mille.mp3',
        );
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('audio-associate-stored')),
              )
              .data,
          '${'ab' * 32}.mp3',
        );
        expect(find.byKey(const Key('audio-associate-missing')), findsOne);
        expect(find.byKey(const Key('audio-associate-play')), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const Key('audio-associate-apply')),
              )
              .onPressed,
          isNull,
        );

        // A recording imported before this build has only its stored name.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tapRow(tester, 'old');
        expect(find.byKey(const Key('audio-associate-original')), findsNothing);
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('audio-associate-stored')),
              )
              .data,
          'assets/audio_library_271_test/old.mp3',
        );
      });

      testWidgets('a text gives the recording its place in the list', (
        tester,
      ) async {
        await open(tester, _course(_library));
        await tapRow(tester, 'new');
        await tester.enterText(
          find.byKey(const Key('audio-associate-text')),
          'Grazie mille!',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('audio-associate-apply')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('audio-associate-dialog')), findsNothing);
        expect(find.text('Grazie mille!'), findsOneWidget);
        expect(find.text(AudioLibraryScreen.noTextLabel), findsNothing);
        expect(find.byKey(const Key('audio-clip-uses-new')), findsOneWidget);
      });

      testWidgets('a text that already has its own recording asks; Cancel '
          'changes nothing, Replace moves the old one under #', (tester) async {
        await open(tester, _course(_library));
        await tapRow(tester, 'new');
        await tester.enterText(
          find.byKey(const Key('audio-associate-text')),
          'Buongiorno.',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('audio-associate-apply')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('audio-replace-dialog')), findsOneWidget);
        expect(
          find.text(
            '“Buongiorno.” already has a recording. Replace it? The old '
            'one loses its text and moves under #.',
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('audio-replace-dialog')),
            matching: find.text('Cancel'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('audio-associate-dialog')),
          findsOneWidget,
          reason: 'the author can choose another text',
        );

        await tester.tap(find.byKey(const Key('audio-associate-apply')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('audio-replace-confirm')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('audio-associate-dialog')), findsNothing);
        expect(find.text('Buongiorno.'), findsOneWidget);
        expect(find.text('buongiorno'), findsNothing);
        // The old recording waits under #, with the name its file came with.
        expect(find.text(AudioLibraryScreen.noTextLabel), findsOneWidget);
        await tapRow(tester, 'giorno');
        expect(
          tester
              .widget<SelectableText>(
                find.byKey(const Key('audio-associate-original')),
              )
              .data,
          'buongiorno take 2.mp3',
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('audio-associate-text')))
              .controller!
              .text,
          '',
        );
      });

      testWidgets('Texts in this Course fills the field with the text '
          'tapped', (tester) async {
        await open(tester, _course(_library));
        await tapRow(tester, 'new');
        await tester.tap(find.byKey(const Key('audio-associate-texts')));
        await tester.pumpAndSettle();
        expect(find.byType(AudioTextsScreen), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('audio-texts-search')),
          'grazie mille',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Grazie mille!'));
        await tester.pumpAndSettle();
        expect(find.byType(AudioTextsScreen), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('audio-associate-text')))
              .controller!
              .text,
          'Grazie mille!',
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const Key('audio-associate-apply')),
              )
              .onPressed,
          isNotNull,
        );
      });

      testWidgets('Open folder is offered for a stored recording where the '
          'system opens folders, and says when it cannot', (tester) async {
        final available = FolderOpener.available;
        final opener = FolderOpener.open;
        addTearDown(() {
          FolderOpener.available = available;
          FolderOpener.open = opener;
        });
        final opened = <String>[];
        FolderOpener.available = () => true;
        FolderOpener.open = (folder) async {
          opened.add(folder);
          return true;
        };
        final course = _course([
          _clip('new', '', file: _stored, original: 'grazie mille.mp3'),
          _clip('bundled', 'pane'),
        ]);
        await open(tester, course);

        // A recording that is not in the Course's folder has no folder.
        await tapRow(tester, 'bundled');
        expect(
          find.byKey(const Key('audio-associate-open-folder')),
          findsNothing,
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // The folder does not exist yet: the dialog says so.
        await tapRow(tester, 'new');
        await tester.tap(find.byKey(const Key('audio-associate-open-folder')));
        await tester.pumpUntilFileIoState(
          () => find
              .byKey(const Key('audio-associate-folder-error'))
              .evaluate()
              .isNotEmpty,
        );
        expect(opened, isEmpty);

        final folder = (await tester.runAsync(
          () =>
              CourseMediaStore().courseDirectory(course.courseId, create: true),
        ))!;
        await tester.tap(find.byKey(const Key('audio-associate-open-folder')));
        await tester.pumpUntilFileIoState(() => opened.isNotEmpty);
        expect(opened.single, folder.path);
        expect(
          find.byKey(const Key('audio-associate-folder-error')),
          findsNothing,
        );

        FolderOpener.available = () => false;
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tapRow(tester, 'new');
        expect(
          find.byKey(const Key('audio-associate-open-folder')),
          findsNothing,
        );
      });
    });

    testWidgets('the screen, Associate recording and Texts in this Course '
        'fit a 360-pixel window', (tester) async {
      await open(tester, _course(_library), size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      for (final key in ['audio-library-add', 'audio-library-check']) {
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: key);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
      }
      // The first row: the test font's wide letters put the others below
      // the window.
      await tester.tap(find.byKey(const Key('audio-clip-row-new')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('audio-associate-dialog')), findsOneWidget);
      expect(find.byKey(const Key('audio-associate-original')), findsOne);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('audio-associate-texts')));
      await tester.pumpAndSettle();
      expect(find.byType(AudioTextsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Check › Texts in this Course opens the list', (tester) async {
      await open(tester, _course(_library));
      await tester.tap(find.byKey(const Key('audio-library-check')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('audio-check-texts')));
      await tester.pumpAndSettle();
      expect(find.byType(AudioTextsScreen), findsOneWidget);
      // Not opened to choose a text: a tap leaves the list open.
      await tester.tap(find.byKey(const Key('audio-text-0')));
      await tester.pumpAndSettle();
      expect(find.byType(AudioTextsScreen), findsOneWidget);
    });
  });

  group('the words on the screen', () {
    test('the one line under the audio source, as the owner wrote it', () {
      expect(
        AudioLibraryScreen.sourceLine('tts'),
        'The device’s voice reads every text; no recordings are needed.',
      );
      expect(
        AudioLibraryScreen.sourceLine('recorded'),
        'Only your recordings play; a text without a complete recording '
        'stays silent.',
      );
      expect(
        AudioLibraryScreen.sourceLine('hybrid'),
        'Your recordings play first; the device’s voice reads a text they '
        'don’t fully cover.',
      );
    });

    test('the Help on sound and pictures is in the Editor Help, in three '
        'languages', () {
      final questions = editorHelpQuestionsByTopic['picturesAndSound']!;
      expect(
        questions,
        containsAllInOrder([
          'audioModes',
          'addRecordings',
          'textsToRecord',
          'recordingsTravel',
          'addPictures',
          'findPicture',
          'pictureBadges',
        ]),
      );
      for (final catalog in [helpEn, helpIt, helpEs]) {
        for (final id in ['textsToRecord', 'pictureBadges']) {
          expect(catalog['editorHelp.qa.$id.q'], isNotEmpty);
          expect(catalog['editorHelp.qa.$id.a'], isNotEmpty);
        }
        expect(
          catalog.keys.where((key) => key.startsWith('imageLibraryHelp.')),
          isEmpty,
        );
        expect(
          catalog['editorHelp.qa.textsToRecord.a'],
          allOf(
            contains('Texts in this Course'),
            contains('Its own recording'),
            contains('All parts recorded'),
            contains('Some parts recorded'),
            contains('No recording'),
            contains('Only texts without a complete recording'),
            contains('Unused MP3 files'),
          ),
        );
        expect(
          catalog['editorHelp.qa.pictureBadges.a'],
          allOf(
            contains('QQL'),
            contains('DEVICE'),
            contains('COURSE'),
            contains('IN USE'),
          ),
        );
        expect(
          catalog['editorHelp.qa.addRecordings.a'],
          allOf(
            contains('Add to the Course'),
            contains('Tap to give it its text'),
            contains('Associate recording'),
            contains('Discard changes'),
          ),
        );
        expect(
          catalog['editorHelp.qa.internalIds.a'],
          contains('Show internal IDs'),
        );
      }
      expect(
        QqlGuideHelpDestinations.all.map((destination) => destination.id),
        isNot(contains('image-library')),
      );
    });
  });
}

/// [course] as a custom Course Alice maintains, version 3.
Course _custom(Course course) {
  final json = course.toJson();
  for (final key in const [
    'publisherId',
    'publisherName',
    'officialCourseVersion',
    'officialReleaseDateUtc',
    'officialReleaseNotes',
    'distributionChannel',
    'publisherVerificationStatus',
    'officialChecksum',
    'publisherSignature',
  ]) {
    json.remove(key);
  }
  return Course.fromJson({
    ...json,
    'courseId': 'course_7c1d2b9e-4f3a-4b6c-8d2e-1a5f9e3c7b41',
    'originType': 'custom',
    'originalCourseCreator': {
      'type': 'qqlUser',
      'id': _alice,
      'displayName': 'Alice',
    },
    'maintainer': {'profileId': _alice},
    'courseVersion': '3',
    'lastVersionEditorProfileId': _alice,
    'lastVersionEditorDisplayName': 'Alice',
  });
}
