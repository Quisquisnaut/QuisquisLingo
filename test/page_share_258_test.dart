import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/page_export.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/storage/file_system_storage.dart';
import 'package:quisquislingo_app/widgets/page_actions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 258 Revision 4 (owner decisions of 29 September 2026): a Page can
/// be shared, saved and printed as a PDF made from the page as drawn, when
/// its Course allows it (on by default); the PDF credits the Course, its
/// rights holder and licence.
final _stamp = DateTime.utc(2026, 9, 30);

const _blocks = [
  PromptElement(
    role: 'block',
    type: 'text',
    text: 'Il caffè',
    textStyle: BlockTextStyle.heading1,
  ),
  PromptElement(role: 'block', type: 'text', text: 'Say **buongiorno**.'),
  PromptElement(
    role: 'block',
    type: 'link',
    text: 'Watch',
    url: 'https://example.org/v',
  ),
];

Exercise _page() => Exercise.canonical(
  id: 'page',
  updatedAt: _stamp,
  primitive: ExercisePrimitive.presentation,
  promptElements: _blocks,
  canonicalEvaluation: CanonicalEvaluation.none,
);

Course _course({bool allow = true}) => Course(
  courseId: 'share-course',
  title: 'Coffee Italian',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  license: 'CC BY 4.0',
  rightsHolders: const [
    CourseRightsHolder(type: CourseRightsHolderType.person, name: 'Ada Rossi'),
  ],
  allowPageSharing: allow,
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: [
        LearningRound(
          id: 'round',
          title: 'Round',
          updatedAt: _stamp,
          exercises: [_page()],
        ),
      ],
    ),
  ],
);

Future<ui.Image> _image(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xff3366cc),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

int _pdfPages(Uint8List pdf) =>
    RegExp(r'/Type\s*/Page(?!s)').allMatches(latin1.decode(pdf)).length;

void main() {
  group('the Course setting', () {
    test('is on by default and only its off state is stored', () {
      final on = _course();
      expect(on.allowPageSharing, isTrue);
      expect(on.toJson().containsKey('allowPageSharing'), isFalse);
      final off = Course.fromJson({...on.toJson(), 'allowPageSharing': false});
      expect(off.allowPageSharing, isFalse);
      expect(off.toJson()['allowPageSharing'], isFalse);
      expect(
        () => Course.fromJson({...on.toJson(), 'allowPageSharing': 'no'}),
        throwsFormatException,
      );
    });
  });

  group('PageExport', () {
    test('text, credits and file name', () {
      expect(
        PageExport.plainText(_blocks),
        'Il caffè\n\nSay buongiorno.\n\nWatch: https://example.org/v',
      );
      expect(
        PageExport.credits(_course()),
        'Coffee Italian · © Ada Rossi · CC BY 4.0 · QuisquisLingo',
      );
      expect(
        PageExport.baseName(_course(), _blocks),
        'QQL_page_coffee_italian_il_caff',
      );
    });

    testWidgets('a tall page becomes several A4 pages', (tester) async {
      await tester.runAsync(() async {
        final short = await _image(1000, 800);
        final tall = await _image(1000, 3000);
        final one = await PageExport.pdfFromImage(short, title: 'Short');
        final three = await PageExport.pdfFromImage(tall, title: 'Tall');
        short.dispose();
        tall.dispose();
        expect(latin1.decode(one.sublist(0, 5)), '%PDF-');
        expect(_pdfPages(one), 1);
        expect(_pdfPages(three), 3);
      });
    });
  });

  group('the Page actions', () {
    late Directory temp;
    final shared = <ShareParams>[];
    final opened = <Uri>[];

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Share learner');
      _platforms();
      keepCrashLogUnavailable();
      temp = await Directory.systemTemp.createTemp('qql_page_share_');
      shared.clear();
      opened.clear();
      // A fresh picture each time: the export disposes what it draws.
      PageActionsBar.capture = (context, page) => _image(1400, 1200);
      PageActionsBar.share = (params) async => shared.add(params);
      PageActionsBar.openFile = (uri) async {
        opened.add(uri);
        return true;
      };
      PageActionsBar.temporaryDirectory = () async => temp;
      PageActionsBar.exportFolder = () async => FileSystemExportFolder(temp);
      PageActionsBar.isDesktop = () => true;
      PageActionsBar.sharesTextOnly = () => false;
    });
    tearDown(() async {
      PageActionsBar.capture = PageCapture.capture;
      // Windows may still hold a PDF it is scanning; the folder is in the
      // system temp directory anyway.
      try {
        if (await temp.exists()) await temp.delete(recursive: true);
      } on FileSystemException {
        // Left for the system to clean.
      }
    });

    testWidgets('hidden when the Course does not allow it', (tester) async {
      await _pump(tester, _course(allow: false));
      expect(find.byKey(const Key('page-card')), findsOneWidget);
      expect(find.byKey(const Key('page-actions')), findsNothing);
    });

    testWidgets('Share, Save PDF and Print hand over a PDF', (tester) async {
      await _pump(tester, _course());
      expect(find.byKey(const Key('page-actions')), findsOneWidget);

      await _tapAndWait(
        tester,
        find.byKey(const Key('page-share')),
        () => shared.isNotEmpty,
      );
      final files = shared.single.files!;
      expect(shared.single.fileNameOverrides, [
        'QQL_page_coffee_italian_il_caff.pdf',
      ]);
      expect(files.single.mimeType, 'application/pdf');
      final sharedBytes = await tester.runAsync(files.single.readAsBytes);
      expect(latin1.decode(sharedBytes!.sublist(0, 5)), '%PDF-');

      await _tapAndWait(
        tester,
        find.byKey(const Key('page-print')),
        () => opened.isNotEmpty,
      );
      final printed = File.fromUri(opened.single);
      expect(printed.existsSync(), isTrue);
      expect(latin1.decode(printed.readAsBytesSync().sublist(0, 5)), '%PDF-');

      await tester.tap(find.byKey(const Key('page-save')));
      await tester.pumpAndSettle();
      await _tapAndWait(
        tester,
        find.byKey(const Key('page-quick-export')),
        () =>
            temp
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.pdf'))
                .length ==
            2,
      );
    });

    testWidgets('the real capture draws the page off screen', (tester) async {
      PageActionsBar.capture = PageCapture.capture;
      await _pump(tester, _course());
      await _tapAndWait(
        tester,
        find.byKey(const Key('page-share')),
        () => shared.isNotEmpty,
      );
      final bytes = await tester.runAsync(
        shared.single.files!.single.readAsBytes,
      );
      expect(_pdfPages(bytes!), 1);
      // The off-screen copy is gone once the page is drawn.
      expect(find.byKey(const Key('page-export-credits')), findsNothing);
    });

    testWidgets('on Linux Share sends the text and the credits', (
      tester,
    ) async {
      PageActionsBar.sharesTextOnly = () => true;
      await _pump(tester, _course());
      await _tapAndWait(
        tester,
        find.byKey(const Key('page-share')),
        () => shared.isNotEmpty,
      );
      expect(shared.single.files, isNull);
      expect(shared.single.text, contains('Say buongiorno.'));
      expect(shared.single.text, contains('© Ada Rossi'));
    });
  });
}

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
    (_) async => null,
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

Future<void> _frames(WidgetTester tester, {int count = 30}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _tapAndWait(
  WidgetTester tester,
  Finder target,
  bool Function() done,
) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out after $target');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pump();
}

Future<void> _pump(WidgetTester tester, Course course) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: course.lessons.single,
        round: course.lessons.single.rounds.single,
        ttsLanguage: 'it-IT',
        roundIndex: 0,
        previewMode: true,
      ),
    ),
  );
  await _frames(tester);
}
