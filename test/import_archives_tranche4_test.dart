import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/import/bounded_zip_reader.dart';
import 'package:quisquislingo_app/services/import/json_limits.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/user_recovery_key_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_file_dialog_backend.dart';
import 'support/pump_file_io.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';

Matcher _refused(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

Uint8List _zip(List<ArchiveFile> files) {
  final archive = Archive();
  for (final file in files) {
    archive.addFile(file);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

ArchiveFile _stored(String name, List<int> bytes) =>
    ArchiveFile.bytes(name, bytes)..compression = CompressionType.none;

BoundedZipReader _open(Uint8List zip, {int maxEntries = 100}) =>
    BoundedZipReader.open(
      InputMemoryStream(zip),
      label: 'Test ZIP',
      maxEntries: maxEntries,
      maxTotalBytes: 1024 * 1024,
    );

/// Offsets of every central-directory header in [zip].
List<int> _centralHeaders(Uint8List zip) {
  final view = ByteData.sublistView(zip);
  return [
    for (var i = 0; i + 4 <= zip.length; i++)
      if (view.getUint32(i, Endian.little) == 0x02014b50) i,
  ];
}

Uint8List _apple() =>
    File('assets/exercise_images/apple.webp').readAsBytesSync();

/// An Image Bank ZIP: the manifest plus [images] (name → bytes).
Uint8List _bank(Object manifest, Map<String, List<int>> images) => _zip([
  ArchiveFile.bytes(
    'image_bank_manifest.json',
    utf8.encode(jsonEncode(manifest)),
  ),
  for (final image in images.entries) ArchiveFile.bytes(image.key, image.value),
]);

Map<String, Object?> _entry(String id, {String? category, Object? extra}) => {
  'id': id,
  'primary_term': 'Label $id',
  'filename': '$id.webp',
  'keywords': [id],
  if (category != null) 'category': category,
  if (extra is Map<String, Object?>) ...extra,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _adminId,
          displayName: 'Admin',
        ).encode(),
      ],
      ProfileService.adminProfileIdsKey: [_adminId],
    });
    temp = await Directory.systemTemp.createTemp('qql_tranche4_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => temp.path);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    });
  });

  Future<File> write(Uint8List bytes, [String name = 'bank.zip']) async {
    final file = File('${temp.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  group('BoundedZipReader', () {
    test('lists files (not folders) and reads them', () {
      final reader = _open(
        _zip([
          ArchiveFile.directory('images/'),
          ArchiveFile.bytes('images/a.txt', utf8.encode('hello')),
          _stored('b.txt', utf8.encode('stored')),
        ]),
      );
      expect(reader.entries.map((e) => e.name), ['images/a.txt', 'b.txt']);
      expect(reader.entries.first.baseName, 'a.txt');
      expect(utf8.decode(reader.read(reader.entries.first)), 'hello');
      expect(utf8.decode(reader.read(reader.entry('b.txt')!)), 'stored');
      expect(
        () => reader.read(reader.entries.first, limit: 4),
        _refused('too large'),
      );
    });

    test('refuses unsafe names', () {
      for (final name in [
        '/abs.txt',
        'C:/drive.txt',
        'a/../b.txt',
        './here.txt',
        'a//b.txt',
        'bad\u0001name.txt',
      ]) {
        expect(
          () => _open(
            _zip([
              ArchiveFile.bytes(name, const [1]),
            ]),
          ),
          _refused('unsafe path'),
          reason: name,
        );
      }
    });

    test('refuses names that clash after case folding or slashes', () {
      expect(
        () => _open(
          _zip([
            ArchiveFile.bytes('A.txt', const [1]),
            ArchiveFile.bytes('a.txt', const [2]),
          ]),
        ),
        _refused('same name twice'),
      );
      expect(
        () => _open(
          _zip([
            ArchiveFile.bytes('x/a.txt', const [1]),
            ArchiveFile.bytes(r'x\a.txt', const [2]),
          ]),
        ),
        _refused('same name twice'),
      );
    });

    test('refuses links and special files', () {
      for (final mode in [0xa1ff, 0x21b6, 0x61b6, 0x11b6, 0xc1b6]) {
        final file = ArchiveFile.bytes('x.txt', const [1])..mode = mode;
        expect(
          () => _open(_zip([file])),
          _refused('link or special file'),
          reason: mode.toRadixString(16),
        );
      }
    });

    test('refuses encryption and unknown compression', () {
      var zip = _zip([
        ArchiveFile.bytes('x.txt', const [1, 2, 3]),
      ]);
      final header = _centralHeaders(zip).single;
      final view = ByteData.sublistView(zip);
      view.setUint16(header + 8, 1, Endian.little); // encrypted
      expect(() => _open(zip), _refused('encrypted'));

      zip = _zip([
        ArchiveFile.bytes('x.txt', const [1, 2, 3]),
      ]);
      ByteData.sublistView(
        zip,
      ).setUint16(_centralHeaders(zip).single + 10, 12, Endian.little);
      expect(() => _open(zip), _refused('compression method'));
    });

    test('refuses nested archives', () {
      for (final name in ['inner.zip', 'data.tar.gz', 'x.7z', 'y.RAR']) {
        expect(
          () => _open(
            _zip([
              ArchiveFile.bytes(name, const [1]),
            ]),
          ),
          _refused('another archive'),
          reason: name,
        );
      }
    });

    test('counts entries and declared sizes before inflating', () {
      expect(
        () => _open(
          _zip([
            for (var i = 0; i < 5; i++) ArchiveFile.bytes('$i.txt', [i]),
          ]),
          maxEntries: 4,
        ),
        _refused('too many entries'),
      );
      expect(
        () => _open(
          _zip([ArchiveFile.bytes('big.txt', Uint8List(1024 * 1024 + 1))]),
        ),
        _refused('expands beyond its 1 MB limit'),
      );
    });

    test('refuses a local name that differs and a wrong CRC', () {
      var zip = _zip([_stored('abc.txt', utf8.encode('payload'))]);
      // The local header's name starts 30 bytes in.
      zip[30] = 'x'.codeUnitAt(0);
      expect(() => _open(zip), _refused('is damaged'));

      zip = _zip([_stored('abc.txt', utf8.encode('payload'))]);
      final content = String.fromCharCodes(zip).indexOf('payload');
      zip[content] ^= 0xff;
      final reader = _open(zip);
      expect(() => reader.read(reader.entries.single), _refused('damaged'));
    });

    test('refuses bytes that are not a ZIP', () {
      expect(
        () => _open(Uint8List.fromList(utf8.encode('plain text'))),
        _refused('not a readable Test ZIP'),
      );
    });
  });

  group('Image Bank rules', () {
    Future<ParsedImageBank> read(
      Object manifest,
      Map<String, List<int>> files,
    ) => write(_bank(manifest, files)).then(ImageBankService().readBank);

    test('images may sit in folders; the manifest may be an object', () async {
      final bank = await read(
        {
          'name': 'Fruit',
          'attribution': {'author': 'Bank Artist', 'license': 'CC0'},
          'images': [
            _entry('apple', category: 'food'),
            _entry(
              'pear',
              extra: {
                'attribution': {'author': 'Own Artist', 'license': 'CC BY'},
              },
            ),
          ],
        },
        {
          'assets/exercise_images/apple.webp': _apple(),
          'assets/exercise_images/pear.webp': _apple(),
        },
      );
      expect(bank.name, 'Fruit');
      expect(bank.images.first.category, 'food_drinks');
      expect(bank.images.last.category, 'other');
      // The bank-wide credit fills in; an entry's own credit wins.
      expect(bank.images.first.attribution?.author, 'Bank Artist');
      expect(bank.images.last.attribution?.author, 'Own Artist');
    });

    test('anything besides the manifest and its images is refused', () {
      expect(
        read(
          [_entry('apple')],
          {'apple.webp': _apple(), 'CREDITS.txt': utf8.encode('by me')},
        ),
        _refused('"attribution" field'),
      );
    });

    test('manifest fields are bounded', () async {
      final cases = <Object, String>{
        [_entry('bad id!')]: 'Image Bank ID must be',
        [_entry('x' * 129)]: 'Image Bank ID must be',
        [
          {..._entry('apple'), 'primary_term': 'x' * 201},
        ]: '1–200 characters',
        [
          {..._entry('apple'), 'primary_term': 'Tab\there'},
        ]: 'control characters',
        [
          {
            ..._entry('apple'),
            'keywords': [for (var i = 0; i < 33; i++) 't$i'],
          },
        ]: 'more than 32 tags',
        [
          {
            ..._entry('apple'),
            'keywords': ['x' * 81],
          },
        ]: '1–80 characters',
        [_entry('apple', category: 'Not Valid')]: 'is not a valid name',
        {
          'images': [_entry('apple')],
          'extra': 1,
        }: 'nothing else',
        {
          'images': [_entry('apple')],
          'attribution': {'author': 'Only author'},
        }: 'license',
        {
          'images': [_entry('apple')],
          'name': 'n' * 121,
        }: '1–120 characters',
      };
      for (final entry in cases.entries) {
        final id = entry.key is List
            ? ((entry.key as List).single as Map)['id'] as String
            : 'apple';
        final filename = id.length <= 128 && !id.contains('!')
            ? '$id.webp'
            : 'apple.webp';
        await expectLater(
          read(entry.key, {filename: _apple()}),
          _refused(entry.value),
          reason: entry.value,
        );
      }
    });

    test('a deeply nested manifest is refused before decoding', () {
      final deep = '${'[' * 65}${']' * 65}';
      expect(
        write(
          _zip([
            ArchiveFile.bytes('image_bank_manifest.json', utf8.encode(deep)),
          ]),
        ).then(ImageBankService().readBank),
        _refused('nested more than 64 levels'),
      );
    });
  });

  group('Image Bank into the Shared Image Library', () {
    final metadata = ExerciseImageMetadataService();

    Future<ParsedImageBank> bank(List<Map<String, Object?>> entries) async =>
        ImageBankService().readBank(
          await write(
            _bank(entries, {
              for (final entry in entries)
                entry['filename'] as String: _apple(),
            }),
          ),
        );

    Directory banksFolder() =>
        Directory('${temp.path}${Platform.pathSeparator}image_banks');

    test('new categories are added when the Admin says so', () async {
      final asked = <List<String>>[];
      final result = await ImageBankService().importToSharedLibrary(
        await bank([
          _entry('b1', category: 'zeta_things'),
          _entry('b2', category: 'alpha_things'),
          _entry('b3', category: 'animals'),
        ]),
        metadata: metadata,
        actorProfileId: _adminId,
        chooseNewCategories: (names) async {
          asked.add(names);
          return NewCategoryChoice.add;
        },
      );
      expect(asked, [
        ['alpha_things', 'zeta_things'],
      ]);
      expect(result!.imported, 3);
      expect(
        await metadata.deviceCategories(),
        containsAll(['alpha_things', 'zeta_things']),
      );
      final catalog = await metadata.loadCatalog();
      expect(
        catalog.firstWhere((record) => record.id == 'b1').category,
        'zeta_things',
      );
    });

    test('or put under Other', () async {
      final result = await ImageBankService().importToSharedLibrary(
        await bank([_entry('o1', category: 'new_things')]),
        metadata: metadata,
        actorProfileId: _adminId,
        chooseNewCategories: (_) async => NewCategoryChoice.useOther,
      );
      expect(result!.records.single.category, 'other');
      expect(await metadata.deviceCategories(), isEmpty);
    });

    test('Cancel leaves nothing behind', () async {
      final result = await ImageBankService().importToSharedLibrary(
        await bank([_entry('c1', category: 'new_things')]),
        metadata: metadata,
        actorProfileId: _adminId,
        chooseNewCategories: (_) async => NewCategoryChoice.cancel,
      );
      expect(result, isNull);
      expect(banksFolder().existsSync(), isFalse);
      expect(await metadata.deviceCategories(), isEmpty);
      expect(
        (await metadata.loadCatalog()).where((record) => record.id == 'c1'),
        isEmpty,
      );
    });

    test('more than 16 new categories are refused before asking', () async {
      var asked = false;
      await expectLater(
        ImageBankService().importToSharedLibrary(
          await bank([
            for (var i = 0; i < 17; i++) _entry('m$i', category: 'cat_$i'),
          ]),
          metadata: metadata,
          actorProfileId: _adminId,
          chooseNewCategories: (_) async {
            asked = true;
            return NewCategoryChoice.add;
          },
        ),
        _refused('at most 16'),
      );
      expect(asked, isFalse);
      expect(banksFolder().existsSync(), isFalse);
    });

    test(
      'a failure after writing removes the bank and its categories',
      () async {
        // `bread` is a QQL image ID, so registering the records fails.
        await expectLater(
          ImageBankService().importToSharedLibrary(
            await bank([_entry('bread', category: 'new_things')]),
            metadata: metadata,
            actorProfileId: _adminId,
            chooseNewCategories: (_) async => NewCategoryChoice.add,
          ),
          throwsA(anything),
        );
        expect(await metadata.deviceCategories(), isEmpty);
        final folder = banksFolder();
        expect(folder.existsSync() ? folder.listSync() : const [], isEmpty);
        expect(await ImageBankService().banks(), isEmpty);
      },
    );

    test('an image without keywords is refused before writing', () async {
      await expectLater(
        ImageBankService().importToSharedLibrary(
          await bank([
            {..._entry('k1'), 'keywords': <String>[]},
          ]),
          metadata: metadata,
          actorProfileId: _adminId,
          chooseNewCategories: (_) async => NewCategoryChoice.add,
        ),
        _refused('at least one keyword'),
      );
      expect(banksFolder().existsSync(), isFalse);
    });

    testWidgets('the Admin is asked about new categories in the library', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final backend = FakeFileDialogBackend();
      final zip = _bank(
        [_entry('w1', category: 'garden_tools')],
        {'w1.webp': _apple()},
      );
      backend.onOpen = () async => FileDialogResult.opened('tools.zip', zip);
      await tester.pumpWidget(
        MaterialApp(
          home: FlatImageLibraryScreen(
            selectMode: false,
            metadataEditingEnabled: true,
            actorProfileId: _adminId,
            bankService: ImageBankService(
              fileDialogs: FileDialogService(
                backend: backend,
                stager: testImportStager(),
              ),
              temporaryDirectory: () async => temp,
            ),
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find.byTooltip('Import').evaluate().isNotEmpty,
      );
      await tester.tap(find.byTooltip('Import'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Image Bank ZIP from…'));
      await tester.pumpUntilFileIoState(
        () => find.text('New categories').evaluate().isNotEmpty,
      );
      expect(
        find.text('This bank adds 1 new category: garden_tools.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('bank-categories-add')));
      await tester.pumpUntilFileIoState(
        () => find.textContaining('Imported 1 images').evaluate().isNotEmpty,
      );
      expect(await tester.runAsync(metadata.deviceCategories), [
        'garden_tools',
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    test('only an Admin may import', () async {
      await expectLater(
        ImageBankService().importToSharedLibrary(
          await bank([_entry('n1')]),
          metadata: metadata,
          actorProfileId: '22222222-2222-4222-8222-222222222222',
          chooseNewCategories: (_) async => NewCategoryChoice.add,
        ),
        throwsA(anything),
      );
      expect(banksFolder().existsSync(), isFalse);
    });
  });

  group('JSON structural limits', () {
    const small = JsonLimits(
      maxDepth: 3,
      maxStringLength: 10,
      maxArrayLength: 3,
    );

    test('depth, string length and list length', () {
      expect(() => small.check('[[[1]]]'), returnsNormally);
      expect(() => small.check('[[[[1]]]]'), _refused('nested more than 3'));
      expect(() => small.check('{"a":{"b":{"c":{}}}}'), _refused('nested'));
      expect(() => small.check('["0123456789"]'), returnsNormally);
      expect(() => small.check('["01234567890"]'), _refused('text longer'));
      expect(() => small.check('[1,2,3]'), returnsNormally);
      expect(() => small.check('[1,2,3,4]'), _refused('more than 3 items'));
      expect(() => small.check('[["a"],"b",{}]'), returnsNormally);
      expect(() => small.check('[[],[],[],[]]'), _refused('more than 3'));
      // Brackets, commas and escaped quotes inside text do not count.
      expect(() => small.check(r'["[[[[,,,,\""]'), returnsNormally);
      // Object members are not list items.
      expect(() => small.check('{"a":1,"b":2,"c":3,"d":4}'), returnsNormally);
    });

    test('a Course is checked before it is built', () async {
      final transfer = CustomCourseTransferService();
      Future<void> refused(String json, String text) => expectLater(
        transfer.courseFromBytes(
          Uint8List.fromList(utf8.encode(json)),
          'course.json',
        ),
        _refused(text),
      );
      await refused('${'[' * 70}${']' * 70}', 'nested more than 64');
      await refused(
        jsonEncode({
          'lessons': [for (var i = 0; i < 501; i++) {}],
        }),
        'more than 500 Lessons',
      );
      await refused(
        jsonEncode({
          'lessons': [
            {
              'rounds': [for (var i = 0; i < 101; i++) {}],
            },
          ],
        }),
        'more than 100 Rounds',
      );
      await refused(
        jsonEncode({'courseId': 'a${String.fromCharCode(0)}b'}),
        'NUL character',
      );
    });

    test('learner backups and Recovery Keys are checked too', () {
      final bomb = utf8.encode('${'{"a":' * 70}1${'}' * 70}');
      expect(
        () => LearnerBackupService().decodeDocument(bomb),
        _refused('nested more than 64'),
      );
      expect(
        () => UserRecoveryKeyService().decodeDocument(bomb),
        _refused('nested more than 64'),
      );
      expect(
        () => LearnerBackupService().decodeDocument(
          utf8.encode(
            jsonEncode({'learnerProfileId': 'x${String.fromCharCode(0)}'}),
          ),
        ),
        _refused('NUL character'),
      );
    });

    test('the bundled Courses fit every limit', () {
      for (final file in [
        ...Directory('assets/courses').listSync(),
        ...Directory('demo_courses').listSync(),
      ].whereType<File>().where((f) => f.path.endsWith('.json'))) {
        final text = file.readAsStringSync();
        JsonLimits.imports.check(text);
        CourseShapeLimits.check(jsonDecode(text) as Map);
      }
    });
  });
}
