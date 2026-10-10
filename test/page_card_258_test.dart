import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/inline_marks.dart';
import 'package:quisquislingo_app/services/page_blocks.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/widgets/page_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 258 Revision 0: a Page is a presentation drawn from formatted
/// blocks (headings, paragraphs with bold and italic, quotes, lists,
/// pictures, audio and links), with alignment, a palette colour and an
/// optional read-aloud per text block (owner decisions of 29 September
/// 2026, `docs/258_PAGE_CARD_PLAN.md`).
final _stamp = DateTime.utc(2026, 9, 29);

PromptElement _block(
  String type, {
  String text = '',
  String asset = '',
  String url = '',
  BlockTextStyle? style,
  BlockAlign? align,
  BlockColor? color,
  BlockSize? size,
  bool? readAloud,
  TextLanguage? language,
}) => PromptElement(
  role: 'block',
  type: type,
  text: text,
  asset: asset,
  url: url,
  textStyle: style,
  align: align,
  color: color,
  size: size,
  readAloud: readAloud,
  language: language,
);

final _blocks = [
  _block(
    'text',
    text: 'Greetings',
    style: BlockTextStyle.heading1,
    align: BlockAlign.center,
  ),
  _block(
    'text',
    text: 'Say **buongiorno** until *noon*.',
    align: BlockAlign.justify,
    color: BlockColor.blue,
    readAloud: true,
    language: TextLanguage.target,
  ),
  _block('text', text: 'ciao\ngrazie', style: BlockTextStyle.numbered),
  _block(
    'image',
    asset: 'assets/avatars/robot.png',
    text: 'A friendly robot',
    size: BlockSize.small,
    align: BlockAlign.end,
  ),
  _block('link', text: 'Watch the greeting', url: 'https://example.org/v'),
];

Exercise _page(List<PromptElement> blocks, {String id = 'page'}) =>
    Exercise.canonical(
      id: id,
      updatedAt: _stamp,
      primitive: ExercisePrimitive.presentation,
      promptElements: blocks,
      canonicalEvaluation: CanonicalEvaluation.none,
    );

Set<String> _codes(Exercise exercise) =>
    CourseAuditService().auditExercise(exercise).map((i) => i.code).toSet();

Course _course(List<Exercise> exercises, {int? minimumAppBuild}) => Course(
  courseId: 'page-course',
  title: 'Page course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  minimumAppBuild: minimumAppBuild,
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: [
        LearningRound(
          id: 'round',
          title: 'Round',
          updatedAt: _stamp,
          exercises: exercises,
        ),
      ],
    ),
  ],
);

void main() {
  group('model', () {
    test('blocks keep their attributes through JSON', () {
      final page = _page(_blocks);
      final json = page.toJson();
      final prompt = json['prompt'] as List;
      expect(prompt[0], {
        'role': 'block',
        'type': 'text',
        'text': 'Greetings',
        'textStyle': 'heading1',
        'align': 'center',
      });
      expect((prompt[1] as Map)['color'], 'blue');
      expect((prompt[1] as Map)['readAloud'], true);
      expect((prompt[3] as Map)['size'], 'small');
      expect((prompt[4] as Map)['url'], 'https://example.org/v');
      final back = Exercise.fromJson(
        json,
        contentId: 'page',
        publicationState: PublicationState.published,
      );
      expect(back.semanticallyEquals(page), isTrue);
      expect(back.promptElements[1].align, BlockAlign.justify);
      expect(ExerciseFeatures(back).kind, LearnerExerciseKind.page);
      expect(ExerciseFeatures(back).pageBlocks, hasLength(5));
      expect(
        ExerciseFeatures(back).illustrationImages,
        isEmpty,
        reason: 'a Page draws its pictures among its blocks',
      );
    });

    test(
      'an attribute on the wrong element or an unknown value is refused',
      () {
        for (final element in <Map<String, dynamic>>[
          {'type': 'text', 'size': 'small'},
          {'type': 'image', 'textStyle': 'heading1'},
          {'type': 'image', 'align': 'justify'},
          {'type': 'text', 'url': 'https://example.org'},
          {'type': 'text', 'color': 'purple'},
          {'type': 'text', 'textStyle': 'Heading1'},
          {'type': 'text', 'readAloud': 'yes'},
          {'type': 'audio', 'color': 'red'},
        ]) {
          expect(
            () => PromptElement.fromJson({'role': 'block', ...element}),
            throwsFormatException,
            reason: '$element',
          );
        }
        expect(
          PromptElement.fromJson({
            'role': 'block',
            'type': 'link',
            'url': 'https://example.org',
            'align': 'end',
          }).isLink,
          isTrue,
        );
      },
    );
  });

  group('inline marks', () {
    test('bold, italic, both, escapes and stars that mark nothing', () {
      expect(InlineMarks.parse('Say **ciao** now'), const [
        InlineRun('Say '),
        InlineRun('ciao', bold: true),
        InlineRun(' now'),
      ]);
      expect(InlineMarks.parse('*a* and ***b***'), const [
        InlineRun('a', italic: true),
        InlineRun(' and '),
        InlineRun('b', bold: true, italic: true),
      ]);
      expect(InlineMarks.parse('2 * 3 = 6'), const [InlineRun('2 * 3 = 6')]);
      expect(InlineMarks.hasUnmatched('2 * 3 = 6'), isTrue);
      expect(InlineMarks.parse(r'a \*star\*'), const [InlineRun('a *star*')]);
      expect(InlineMarks.hasUnmatched(r'a \*star\*'), isFalse);
      expect(InlineMarks.hasUnmatched('**open'), isTrue);
      expect(InlineMarks.parse('**open'), const [InlineRun('**open')]);
      expect(InlineMarks.plain('Say **ciao** *now*'), 'Say ciao now');
      expect(InlineMarks.hasUnmatched('Say **ciao** *now*'), isFalse);
    });
  });

  group('Audit and saving', () {
    test('an empty page, an unmatched mark and a link that is not https', () {
      expect(_codes(_page(_blocks)), isNot(contains('PAGE_EMPTY')));
      expect(_codes(_page(_blocks)), isNot(contains('PAGE_LINK_INVALID')));
      expect(_codes(_page([_block('text', text: '  ')])), {'PAGE_EMPTY'});
      expect(
        _codes(_page([_block('text', text: 'Say **ciao')])),
        contains('PAGE_MARK_UNMATCHED'),
      );
      expect(
        _codes(
          _page([
            _block('text', text: '**Heading**', style: BlockTextStyle.heading2),
          ]),
        ),
        isNot(contains('PAGE_MARK_UNMATCHED')),
        reason: 'headings take no marks',
      );
      expect(
        _codes(_page([_block('link', url: 'http://example.org')])),
        contains('PAGE_LINK_INVALID'),
      );
      expect(PageBlocks.isAcceptableLink('https://'), isFalse);
      expect(PageBlocks.isAcceptableLink('https://example.org/x'), isTrue);
    });

    test('a Page is never a playable step to skip, and never scored', () {
      final round = _course([_page(_blocks)]).lessons.single.rounds.single;
      expect(RoundPlayabilityService().playableExerciseIndices(round), [0]);
      expect(
        RoundPlayabilityService().laurelEligibleRoundIds(
          _course([_page(_blocks)]),
        ),
        isEmpty,
      );
    });

    test('a Course with a Page records the build that draws Pages', () {
      final raised = PageBlocks.withMinimumAppBuild(_course([_page(_blocks)]));
      expect(raised.minimumAppBuild, PageBlocks.minimumAppBuild);
      final plain = _course([
        Exercise.beforeYouStart(id: 'intro', text: 'Hello.'),
      ]);
      expect(identical(PageBlocks.withMinimumAppBuild(plain), plain), isTrue);
      final already = _course([
        _page(_blocks),
      ], minimumAppBuild: PageBlocks.minimumAppBuild);
      expect(
        identical(PageBlocks.withMinimumAppBuild(already), already),
        isTrue,
      );
    });
  });

  group('PageCardView', () {
    testWidgets('styles, marks, alignment, palette, list, picture, link', (
      tester,
    ) async {
      final spoken = <PromptElement>[];
      final opened = <String>[];
      final widths = <double>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: PageCardView(
                  blocks: [
                    ..._blocks,
                    _block('link', text: 'Bad', url: 'http://example.org'),
                  ],
                  pictureBuilder: (picture, width) {
                    widths.add(width);
                    return SizedBox(width: width, height: 40);
                  },
                  onSpeak: spoken.add,
                  onOpenLink: opened.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      RichText richIn(int block) => tester.widget<RichText>(
        find
            .descendant(
              of: find.byKey(ValueKey('page-block-$block')),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(richIn(0).textAlign, TextAlign.center);
      final paragraph = richIn(1);
      expect(paragraph.text.toPlainText(), 'Say buongiorno until noon.');
      expect(paragraph.textAlign, TextAlign.justify);
      expect(paragraph.text.style?.color, Colors.blue.shade800);
      TextStyle? styleOf(String word) {
        TextStyle? found;
        paragraph.text.visitChildren((span) {
          if (span is TextSpan && span.text == word) found = span.style;
          return found == null;
        });
        return found;
      }

      expect(styleOf('buongiorno')?.fontWeight, FontWeight.w700);
      expect(styleOf('noon')?.fontStyle, FontStyle.italic);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('A friendly robot'), findsOneWidget);
      expect(widths.single, closeTo((600 - 40) * .35, .01));

      await tester.tap(find.byKey(const ValueKey('page-read-aloud-1')));
      expect(spoken.single.text, 'Say **buongiorno** until *noon*.');
      expect(find.byKey(const ValueKey('page-read-aloud-0')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('page-link-4')));
      expect(opened, ['https://example.org/v']);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('page-link-5')))
            .onPressed,
        isNull,
      );
    });

    test('the palette stays readable in both themes', () {
      final light = ThemeData(brightness: Brightness.light);
      final dark = ThemeData(brightness: Brightness.dark);
      expect(PageCardView.colorOf(BlockColor.normal, light), isNull);
      expect(PageCardView.colorOf(null, dark), isNull);
      for (final color in BlockColor.values.skip(1)) {
        expect(
          PageCardView.colorOf(color, light),
          isNot(PageCardView.colorOf(color, dark)),
          reason: color.serialized,
        );
      }
    });
  });

  group('Round screen', () {
    late Future<bool> Function(Uri) originalOpener;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Page learner');
      _platforms();
      keepCrashLogUnavailable();
      originalOpener = RoundScreen.openLink;
    });
    tearDown(() => RoundScreen.openLink = originalOpener);

    testWidgets('a Page plays with no heading, opens links and continues', (
      tester,
    ) async {
      final opened = <Uri>[];
      RoundScreen.openLink = (uri) async {
        opened.add(uri);
        return true;
      };
      final course = _course([_page(_blocks)]);
      await _pump(tester, course, preview: true);
      expect(find.byKey(const Key('page-card')), findsOneWidget);
      expect(find.text('Greetings'), findsOneWidget);
      expect(find.byKey(const Key('exercise-heading')), findsNothing);
      expect(find.byKey(const Key('exercise-instruction')), findsNothing);
      expect(find.byKey(const Key('exercise-image')), findsNothing);
      expect(find.byKey(const ValueKey('page-read-aloud-1')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('page-link-4')));
      await tester.tap(find.byKey(const ValueKey('page-link-4')));
      await _frames(tester);
      // Build 270 Revision 10: the link asks first, naming the site and the
      // whole address; Cancel opens nothing.
      expect(find.byKey(const Key('page-link-confirm')), findsOneWidget);
      expect(
        find.text(
          'This page links to example.org. It opens in your browser, '
          'outside QuisquisLingo:',
        ),
        findsOneWidget,
      );
      expect(find.text('https://example.org/v'), findsOneWidget);
      await tester.tap(find.byKey(const Key('page-link-confirm-cancel')));
      await _frames(tester);
      expect(opened, isEmpty);
      await tester.tap(find.byKey(const ValueKey('page-link-4')));
      await _frames(tester);
      await tester.tap(find.byKey(const Key('page-link-confirm-open')));
      await _frames(tester);
      expect(opened, [Uri.parse('https://example.org/v')]);
      await tester.ensureVisible(find.byKey(const Key('page-continue')));
      await tester.tap(find.byKey(const Key('page-continue')));
      await _frames(tester);
      // The last card of a practice Round waits for Finish round.
      if (find.text('Preview complete').evaluate().isEmpty) {
        final finish = find.widgetWithText(FilledButton, 'Finish round');
        await tester.ensureVisible(finish);
        await tester.tap(finish);
        await _frames(tester);
      }
      expect(find.text('Preview complete'), findsOneWidget);
    });

    testWidgets('with Audio Exercises off a Page still plays, silently', (
      tester,
    ) async {
      final course = _course([
        _page([
          ..._blocks,
          PromptElement(role: 'block', type: 'audio', text: 'Buongiorno!'),
        ]),
      ]);
      await _pump(tester, course, preview: false);
      expect(find.byKey(const Key('page-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('page-read-aloud-1')), findsNothing);
      expect(find.byKey(const ValueKey('page-audio-5')), findsNothing);
    });
  });

  group('Generic Primitive Editor', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    });

    testWidgets('editing an element keeps the attributes it has no field for', (
      tester,
    ) async {
      final page = _page([
        _block(
          'text',
          text: 'Old heading',
          style: BlockTextStyle.heading2,
          align: BlockAlign.end,
          color: BlockColor.red,
          readAloud: true,
        ),
        PromptElement(
          role: 'line',
          type: 'text',
          text: 'Buongiorno!',
          speakerId: 'character_anna',
        ),
      ]);
      Exercise? saved;
      tester.view.physicalSize = const Size(1400, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PrimitiveEditorScreen(
            exercise: page.withPublicationState(PublicationState.draft),
            title: 'Canonical',
            isNew: false,
            clock: () => DateTime.utc(2026, 9, 29, 12),
            onExerciseSaved: (value) => saved = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('element-text')).first,
        'New heading',
      );
      await tester.enterText(
        find.byKey(const Key('element-text')).at(1),
        'Buonasera!',
      );
      await tester.tap(find.byKey(const Key('primitive-save-draft')));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      final heading = saved!.promptElements.first;
      expect(heading.text, 'New heading');
      expect(heading.textStyle, BlockTextStyle.heading2);
      expect(heading.align, BlockAlign.end);
      expect(heading.color, BlockColor.red);
      expect(heading.readAloud, isTrue);
      final line = saved!.promptElements[1];
      expect(line.text, 'Buonasera!');
      expect(line.speakerId, 'character_anna');
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

Future<void> _pump(
  WidgetTester tester,
  Course course, {
  required bool preview,
}) async {
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
        previewMode: preview,
      ),
    ),
  );
  await _frames(tester);
}
