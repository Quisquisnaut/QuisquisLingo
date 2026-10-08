import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_en.dart';
import 'package:quisquislingo_app/localization/help/help_es.dart';
import 'package:quisquislingo_app/localization/help/help_it.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/models/guidebook_text.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/guidebook_module_sample.dart';
import 'package:quisquislingo_app/services/guidebook_paste_list.dart';
import 'package:quisquislingo_app/services/guidebook_picture_match.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';
import 'support/guidebook_fixtures.dart';

/// Build 266 Revision 1 (`docs/266_GUIDEBOOK_MODULES_PLAN.md` §5, owner
/// decisions of 6–8 October 2026): the module page's authoring aids. The
/// picture prefill (`GuidebookPictureIndex`), Paste list, Fill with an
/// example, Clear all, the Overview counter and hint, the field Help and the
/// two Editor Help questions.

ExerciseImageMetadata _record(Map<String, dynamic> record) =>
    ExerciseImageMetadata(
      id: record['id'] as String,
      label: record['label'] as String,
      category: record['category'] as String,
      tags: [for (final tag in record['tags'] as List) tag as String],
      assetPath: record['assetPath'] as String,
      origin: 'bundled',
    );

ExerciseImageMetadata _picture(
  String id,
  String label,
  String category, {
  String origin = 'bundled',
}) => ExerciseImageMetadata(
  id: id,
  label: label,
  category: category,
  tags: const ['tag'],
  assetPath: origin == 'bundled'
      ? 'assets/exercise_images/$id.webp'
      : '/device/$id.png',
  origin: origin,
);

/// A small catalog for the module page.
final _catalog = [
  _picture('apple', 'Apple', 'food_drinks'),
  _picture('cat', 'Cat', 'animals'),
  _picture('orange_fruit', 'Orange', 'food_drinks'),
  _picture('orange_colour', 'Orange', 'colors'),
  _picture('coffee', 'Coffee', 'food_drinks'),
  _picture('char_a', 'A', 'characters_latin'),
  _picture('lesson_icon_train', 'Train', 'lesson_icons'),
  _picture('device_pear', 'Pear', 'food_drinks', origin: 'local'),
];

class _FakeCatalog extends ExerciseImageMetadataService {
  _FakeCatalog(this.records);
  final List<ExerciseImageMetadata> records;

  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => records;
}

Course _course({
  String source = 'English',
  String target = 'Italian',
  String tts = 'it-IT',
}) => Course(
  courseId: 'aids',
  learningLanguage: target,
  interfaceLanguage: source,
  sourceLanguage: source,
  targetLanguage: target,
  title: 'Aids',
  ttsLanguage: tts,
  lessons: const [],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('GuidebookPictureIndex on the QQL catalog', () {
    final index = GuidebookPictureIndex([
      for (final record in readBundledImageRecords()) _record(record),
    ]);
    String? single(String word) {
      final match = index.find(word);
      return match.isSingle ? match.pictures.single.label : null;
    }

    test('a name equal to the word, capitals and a leading article aside', () {
      expect(single('apple'), 'Apple');
      expect(single('An apple'), 'Apple');
      expect(single('the bill'), 'Bill');
      expect(index.find('apple').plural, isFalse);
    });

    test('the singular, marked Plural; an exact name first', () {
      final cats = index.find('cats');
      expect(cats.pictures.single.label, 'Cat');
      expect(cats.plural, isTrue);
      final glasses = index.find('glasses');
      expect(glasses.pictures.single.label, 'Glasses');
      expect(glasses.plural, isFalse);
    });

    test('the name before a bracket, after an exact name', () {
      expect(
        index.find('baker').pictures.map((p) => p.label),
        unorderedEquals(['Baker (man)', 'Baker (woman)']),
      );
      expect(single('Africa'), 'Africa (map)');
      // The Father scene of Build 265, not Father (family tree).
      expect(single('father'), 'Father');
    });

    test('several pictures of one name are offered, not filled', () {
      final orange = index.find('orange');
      expect(orange.pictures, hasLength(2));
      expect(orange.isSingle, isFalse);
    });

    test('never characters, Lesson icons or one-letter names', () {
      expect(index.find('a').isEmpty, isTrue);
      expect(index.find('I').isEmpty, isTrue);
      expect(index.find('g').isEmpty, isTrue);
      final train = index.find('train');
      expect(train.pictures.single.category, isNot('lesson_icons'));
      expect(index.find('').isEmpty, isTrue);
      expect(index.find('zzzz nothing').isEmpty, isTrue);
    });

    test('device pictures never match', () {
      final small = GuidebookPictureIndex(_catalog);
      expect(small.find('pear').isEmpty, isTrue);
      expect(small.find('apple').isSingle, isTrue);
    });

    test('the side follows the Course languages', () {
      expect(
        GuidebookPictureIndex.sideFor(_course()),
        GuidebookPictureSide.source,
      );
      expect(
        GuidebookPictureIndex.sideFor(
          _course(source: 'Italian', target: 'English', tts: 'en-GB'),
        ),
        GuidebookPictureSide.target,
      );
      expect(
        GuidebookPictureIndex.sideFor(
          _course(source: 'Spanish', target: 'Italian'),
        ),
        isNull,
      );
      expect(
        GuidebookPictureIndex.wordsOf(
          GuidebookPictureSide.target,
          target: '{to} eat',
          source: 'mangiare',
        ),
        ['to eat', 'eat'],
      );
    });
  });

  group('GuidebookPasteList', () {
    test('reads target = source [context], one entry per line', () {
      final read = GuidebookPasteList.read(
        'il conto = the bill [restaurant]\n'
        '\n'
        'il conto → the account [bank]\n'
        'buongiorno - good morning\n'
        '{io} sono stanco = I am tired\r\n',
      );
      expect(read.unread, isEmpty);
      expect(read.entries, [
        (target: 'il conto', source: 'the bill', context: 'restaurant'),
        (target: 'il conto', source: 'the account', context: 'bank'),
        (target: 'buongiorno', source: 'good morning', context: ''),
        (target: '{io} sono stanco', source: 'I am tired', context: ''),
      ]);
    });

    test('names every line it cannot read, with the reason', () {
      final read = GuidebookPasteList.read(
        'casa = house\n'
        'just some words\n'
        '{io sono = I am\n'
        'pane = bread [${'x' * (GuidebookText.maxContextLength + 1)}]\n'
        'gatto = cat [pet] extra\n',
      );
      expect(read.entries.single.target, 'casa');
      expect([for (final line in read.unread) line.number], [2, 3, 4, 5]);
      expect(read.unread[0].reason, contains('target = source'));
      expect(read.unread[1].reason, startsWith('Target:'));
      expect(read.unread[2].reason, contains('40 characters'));
      expect(read.unread[3].reason, contains('[ ]'));
    });
  });

  test('the sample module shows every feature and reads back', () {
    final ids = TimestampAuthoringIdGenerator(seed: 2661);
    final sample = GuidebookModuleSample.module(id: 'm', ids: ids);
    final again = GuidebookModule.fromJson(sample.toJson());
    expect(again.toJson(), sample.toJson());
    final entryIds = [for (final entry in sample.entries) entry.id];
    expect(entryIds.toSet(), hasLength(entryIds.length));
    expect(sample.overview.length, lessThan(GuidebookText.longOverviewLength));
    expect(sample.sentences.any((e) => e.context.isNotEmpty), isTrue);
    expect(
      sample.entries.any((e) => GuidebookText.hasOptionalWords(e.target)),
      isTrue,
    );
    final conto = sample.words.where((e) => e.target == 'il conto').toList();
    expect(conto.map((e) => e.context), ['restaurant', 'bank']);
    final caffe = sample.words.firstWhere((e) => e.target == 'il caffè');
    expect(caffe.picture?.asset, GuidebookModuleSample.coffeePicture);
    final gatti = sample.words.firstWhere((e) => e.target == 'i gatti');
    expect(gatti.picture?.plural, isTrue);
    expect(gatti.picture?.asset, GuidebookModuleSample.catPicture);
    // The pictures exist; a second fill gets fresh IDs.
    final records = {
      for (final record in readBundledImageRecords()) record['assetPath'],
    };
    expect(records, contains(GuidebookModuleSample.coffeePicture));
    expect(records, contains(GuidebookModuleSample.catPicture));
    final second = GuidebookModuleSample.module(id: 'm', ids: ids);
    expect(
      {
        for (final entry in second.entries) entry.id,
      }.intersection(entryIds.toSet()),
      isEmpty,
    );
  });

  test('the Audit and the page share the 500-character limit', () {
    Course withOverview(int length) => Course(
      courseId: 'long',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Long',
      ttsLanguage: 'it-IT',
      useGuidebook: true,
      lessons: [
        Lesson(
          lessonId: 'l1',
          title: 'Lesson',
          guidebook: testGuidebook(
            wordLines: const ['casa = house'],
            overview: 'x' * length,
          ),
          rounds: const [],
        ),
      ],
    );
    bool long(int length) => CourseAuditService()
        .auditCourse(withOverview(length))
        .issues
        .any((issue) => issue.code == 'GUIDEBOOK_MODULE_OVERVIEW_LONG');
    expect(long(GuidebookText.longOverviewLength - 1), isFalse);
    expect(long(GuidebookText.longOverviewLength), isTrue);
  });

  test('every module field has its Help in EN, IT and ES', () {
    for (final catalog in [helpEn, helpIt, helpEs]) {
      for (final field in guidebookFieldHelpIds) {
        expect(catalog['guidebookHelp.field.$field.title'], isNotEmpty);
        expect(catalog['guidebookHelp.field.$field.body'], isNotEmpty);
      }
      for (final id in ['guidebookEntries', 'moduleLength']) {
        expect(catalog['editorHelp.qa.$id.q'], endsWith('?'));
        expect(catalog['editorHelp.qa.$id.a'], isNotEmpty);
      }
    }
    final lessons = editorHelpQuestionsByTopic['lessonsAndRounds']!;
    expect(
      lessons.sublist(
        lessons.indexOf('guidebook'),
        lessons.indexOf('guidebook') + 3,
      ),
      ['guidebook', 'guidebookEntries', 'moduleLength'],
    );
  });

  group('the module page', () {
    void viewport(WidgetTester tester, {double width = 1000}) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 2400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
    }

    Future<GuidebookModule? Function()> open(
      WidgetTester tester, {
      GuidebookModule? module,
      Course? course,
    }) async {
      GuidebookModule? done;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  done = await Navigator.of(context).push<GuidebookModule>(
                    MaterialPageRoute(
                      builder: (_) => GuidebookModuleEditorScreen(
                        module: module ?? GuidebookModule(id: 'm', title: ''),
                        course: course ?? _course(),
                        ids: TimestampAuthoringIdGenerator(seed: 2661),
                        metadataService: _FakeCatalog(_catalog),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return () => done;
    }

    Finder key(String value) => find.byKey(ValueKey(value));

    Future<void> leaveBoxes(WidgetTester tester) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    }

    Future<void> addWord(
      WidgetTester tester,
      int index,
      String target,
      String source,
    ) async {
      await tester.tap(key('guidebook-module-add-word'));
      await tester.pumpAndSettle();
      await tester.enterText(
        key('guidebook-module-word-$index-target'),
        target,
      );
      await tester.enterText(
        key('guidebook-module-word-$index-source'),
        source,
      );
      await leaveBoxes(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.enterText(key('guidebook-module-title'), 'Al bar');
      await tester.tap(key('guidebook-module-done'));
      await tester.pumpAndSettle();
    }

    testWidgets('one matching picture fills the row, marked Suggested', (
      tester,
    ) async {
      viewport(tester);
      final result = await open(tester);
      await addWord(tester, 0, 'la mela', 'an apple');
      expect(key('guidebook-module-word-0-picture-suggested'), findsOneWidget);
      expect(find.text('Suggested'), findsOneWidget);
      // The singular, marked Plural.
      await addWord(tester, 1, 'i gatti', 'cats');
      expect(find.text('Suggested, plural'), findsOneWidget);
      final plural = key('guidebook-module-word-1-picture-plural');
      expect(tester.widget<FilterChip>(plural).selected, isTrue);
      // Several: offered, not filled. None, character or device: nothing.
      await addWord(tester, 2, "l'arancia", 'orange');
      expect(find.text('2 matching pictures'), findsOneWidget);
      expect(key('guidebook-module-word-2-picture-remove'), findsNothing);
      await addWord(tester, 3, 'una', 'a');
      await addWord(tester, 4, 'la pera', 'pear');
      for (final i in [3, 4]) {
        expect(key('guidebook-module-word-$i-picture-remove'), findsNothing);
        expect(key('guidebook-module-word-$i-picture-matches'), findsNothing);
      }
      await done(tester);
      final words = result()!.words;
      expect(words[0].picture?.asset, 'assets/exercise_images/apple.webp');
      expect(words[0].picture?.plural, isFalse);
      expect(words[1].picture?.asset, 'assets/exercise_images/cat.webp');
      expect(words[1].picture?.plural, isTrue);
      expect(words[2].picture, isNull);
    });

    testWidgets('a removed picture stays removed until the word changes', (
      tester,
    ) async {
      viewport(tester);
      await open(tester);
      await addWord(tester, 0, 'la mela', 'apple');
      await tester.tap(key('guidebook-module-word-0-picture-remove'));
      await tester.pumpAndSettle();
      // Leaving the box again with the same word fills nothing.
      await tester.enterText(key('guidebook-module-word-0-source'), 'apple');
      await leaveBoxes(tester);
      expect(key('guidebook-module-word-0-picture-remove'), findsNothing);
      // A new word is read again.
      await tester.enterText(key('guidebook-module-word-0-source'), 'coffee');
      await leaveBoxes(tester);
      expect(key('guidebook-module-word-0-picture-suggested'), findsOneWidget);
      // A suggestion follows the word, a picture the author touched stays.
      await tester.tap(key('guidebook-module-word-0-picture-plural'));
      await tester.pumpAndSettle();
      expect(key('guidebook-module-word-0-picture-suggested'), findsNothing);
      await tester.enterText(key('guidebook-module-word-0-source'), 'apple');
      await leaveBoxes(tester);
      expect(key('guidebook-module-word-0-picture-suggested'), findsNothing);
      expect(key('guidebook-module-word-0-picture-remove'), findsOneWidget);
    });

    testWidgets('a suggestion follows its word; a reopened module is kept', (
      tester,
    ) async {
      viewport(tester);
      await open(tester);
      await addWord(tester, 0, 'la mela', 'apple');
      await tester.enterText(key('guidebook-module-word-0-source'), 'plum');
      await leaveBoxes(tester);
      expect(key('guidebook-module-word-0-picture-remove'), findsNothing);

      // Stored words without pictures are not prefilled when reopened.
      await tester.pumpWidget(const SizedBox());
      await open(
        tester,
        module: GuidebookModule(
          id: 'm',
          title: 'Frutta',
          words: [testEntry('mela', 'la mela = apple')],
        ),
      );
      await tester.tap(key('guidebook-module-word-0-target'));
      await leaveBoxes(tester);
      expect(key('guidebook-module-word-0-picture-remove'), findsNothing);
    });

    testWidgets('no prefill in a Course without English', (tester) async {
      viewport(tester);
      await open(tester, course: _course(source: 'Spanish'));
      await addWord(tester, 0, 'la mela', 'apple');
      expect(key('guidebook-module-word-0-picture-remove'), findsNothing);
    });

    testWidgets('Paste list appends rows and names the unread lines', (
      tester,
    ) async {
      viewport(tester);
      final result = await open(tester);
      await tester.tap(key('guidebook-module-paste-words'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('guidebook-module-paste-text')),
        'il conto = the bill [restaurant]\nnot a pair\nla mela = apple',
      );
      await tester.tap(find.byKey(const Key('guidebook-module-paste-add')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('guidebook-module-paste-unread')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Line 2: write it as target = source'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      // Pasted words get their suggested picture.
      expect(key('guidebook-module-word-1-picture-suggested'), findsOneWidget);
      await tester.tap(key('guidebook-module-paste-sentences'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('guidebook-module-paste-text')),
        'Lei è stanca? = Are you tired? [formal, to a woman]',
      );
      await tester.tap(find.byKey(const Key('guidebook-module-paste-add')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('guidebook-module-paste-unread')),
        findsNothing,
      );
      await done(tester);
      final module = result()!;
      expect(module.words.map((e) => e.target), ['il conto', 'la mela']);
      expect(module.words.first.context, 'restaurant');
      expect(module.sentences.single.context, 'formal, to a woman');
      expect({
        for (final entry in module.entries) entry.id,
      }, hasLength(module.entries.length));
    });

    testWidgets('Fill with an example, then Clear all, asking first', (
      tester,
    ) async {
      viewport(tester);
      final result = await open(tester);
      // A blank page fills at once.
      await tester.tap(find.byKey(const Key('guidebook-module-fill-example')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('guidebook-module-fill-example-confirm')),
        findsNothing,
      );
      expect(find.text('Al bar'), findsOneWidget);
      expect(key('guidebook-module-word-5-picture-plural'), findsOneWidget);
      // A filled page asks.
      await tester.tap(find.byKey(const Key('guidebook-module-fill-example')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('guidebook-module-fill-example-confirm')),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guidebook-module-clear-all')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('guidebook-module-clear-all-confirm')),
      );
      await tester.pumpAndSettle();
      expect(key('guidebook-module-word-0'), findsNothing);
      expect(key('guidebook-module-sentence-0'), findsNothing);
      // An empty page clears without asking.
      await tester.tap(find.byKey(const Key('guidebook-module-clear-all')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('guidebook-module-clear-all-confirm')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('guidebook-module-fill-example')));
      await tester.pumpAndSettle();
      await tester.tap(key('guidebook-module-done'));
      await tester.pumpAndSettle();
      final module = result()!;
      expect(module.id, 'm');
      expect(module.title, 'Al bar');
      expect(module.words, hasLength(6));
      expect(module.sentences, hasLength(4));
    });

    testWidgets('the Overview counter and the long hint', (tester) async {
      viewport(tester);
      await open(tester);
      final count = find.byKey(const Key('guidebook-module-overview-count'));
      expect(tester.widget<Text>(count).data, '0 characters');
      await tester.enterText(
        find.byKey(const Key('guidebook-module-overview')),
        'x' * (GuidebookText.longOverviewLength - 1),
      );
      await tester.pump();
      expect(tester.widget<Text>(count).data, '499 characters');
      expect(
        find.byKey(const Key('guidebook-module-overview-long')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const Key('guidebook-module-overview')),
        'x' * GuidebookText.longOverviewLength,
      );
      await tester.pump();
      expect(
        find.byKey(const Key('guidebook-module-overview-long')),
        findsOneWidget,
      );
    });

    testWidgets('field Help opens in the Help Language', (tester) async {
      viewport(tester);
      await open(tester);
      await tester.tap(
        find.byKey(const ValueKey('guidebook-field-help-title')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(helpEn['guidebookHelp.field.title.body']!),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(key('guidebook-module-add-word'));
      await tester.pumpAndSettle();
      for (final field in ['target', 'source', 'context']) {
        expect(key('guidebook-module-word-0-$field-help'), findsOneWidget);
      }
      for (final field in ['sentences', 'words', 'overview']) {
        expect(key('guidebook-field-help-$field'), findsOneWidget);
      }
      expect(key('guidebook-module-sentences-braces'), findsOneWidget);
    });

    // Owner request of 8 October 2026: opened from a word, the library is
    // searched for its English side, if and only if the Course is to or
    // from English.
    for (final (label, course, source, search) in [
      ('from English', _course(), 'an apple', 'apple'),
      (
        'to English',
        _course(source: 'Italian', target: 'English', tts: 'en-GB'),
        'la mela',
        'the cats',
      ),
      ('without English', _course(source: 'Spanish'), 'manzana', ''),
    ]) {
      testWidgets('the picture dialog searches the library: $label', (
        tester,
      ) async {
        viewport(tester);
        await open(tester, course: course);
        await tester.tap(key('guidebook-module-add-word'));
        await tester.pumpAndSettle();
        // The target side is read when the Course teaches English.
        await tester.enterText(
          key('guidebook-module-word-0-target'),
          label == 'to English' ? 'The cats.' : 'la mela',
        );
        await tester.enterText(key('guidebook-module-word-0-source'), source);
        await tester.tap(key('guidebook-module-word-0-picture'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose flat image'));
        // The library keeps loading under the test clock: read what it was
        // opened with.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final library = tester.widget<FlatImageLibraryScreen>(
          find.byType(FlatImageLibraryScreen),
        );
        expect(
          library.initialSearch ?? '',
          search == 'the cats' ? 'cats' : search,
        );
      });
    }

    testWidgets('N matching pictures searches the word without its article', (
      tester,
    ) async {
      viewport(tester);
      await open(tester);
      await addWord(tester, 0, "l'arancia", 'an orange');
      await tester.tap(key('guidebook-module-word-0-picture-matches'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final library = tester.widget<FlatImageLibraryScreen>(
        find.byType(FlatImageLibraryScreen),
      );
      expect(library.initialSearch, 'orange');
    });

    testWidgets('fits 360 pixels with the aids and a suggestion', (
      tester,
    ) async {
      viewport(tester, width: 360);
      await open(tester);
      await addWord(tester, 0, "l'arancia", 'orange');
      await addWord(tester, 1, 'i gatti', 'cats');
      expect(tester.takeException(), isNull);
      expect(find.text('Suggested, plural'), findsOneWidget);
    });
  });

  testWidgets('the image library can open already searched', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: FlatImageLibraryScreen(readOnly: true, initialSearch: 'baker'),
      ),
    );
    await tester.pumpAndSettle();
    final search = tester.widget<TextField>(
      find.byKey(const Key('exercise-image-search')),
    );
    expect(search.controller!.text, 'baker');
    expect(
      find.byKey(const ValueKey('exercise-image-jobs_professions_baker_man')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('exercise-image-cat')), findsNothing);
  });
}
