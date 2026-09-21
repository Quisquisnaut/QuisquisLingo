import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/exercise_image_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_file_dialog_backend.dart';
import 'support/unique_png.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';

String _sha(List<int> bytes) => sha256.convert(bytes).toString();

/// Build 243 Revision 16 (Tranche 5, part 1): duplicates are decided by
/// content, same-ID conflicts by the Admin, and every import records where it
/// came from.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  final metadata = ExerciseImageMetadataService();

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
    temp = await Directory.systemTemp.createTemp('qql_tranche5_');
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

  /// A bank of [images] (id → picture), read and checked.
  Future<ParsedImageBank> bank(Map<String, Uint8List> images) async {
    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes(
          'image_bank_manifest.json',
          utf8.encode(
            jsonEncode([
              for (final id in images.keys)
                {
                  'id': id,
                  'primary_term': 'Label $id',
                  'keywords': [id],
                  'filename': '$id.png',
                },
            ]),
          ),
        ),
      );
    for (final entry in images.entries) {
      archive.addFile(ArchiveFile.bytes('${entry.key}.png', entry.value));
    }
    final file = File(
      '${temp.path}${Platform.pathSeparator}bank_${images.length}.zip',
    );
    await file.writeAsBytes(ZipEncoder().encode(archive), flush: true);
    return ImageBankService().readBank(file);
  }

  Future<ImageBankImportResult> import(
    ParsedImageBank parsed, {
    Future<ConflictDecision> Function(BankIdConflict)? onConflict,
  }) async => (await ImageBankService().importToSharedLibrary(
    parsed,
    metadata: metadata,
    actorProfileId: _adminId,
    chooseNewCategories: (_) async => NewCategoryChoice.add,
    chooseConflict: onConflict,
  ))!;

  Future<ExerciseImageMetadata?> record(String id) async {
    for (final item in await metadata.loadCatalog()) {
      if (item.id == id) return item;
    }
    return null;
  }

  group('ImageProvenance', () {
    test('round-trips and refuses bad data', () {
      final at = DateTime.utc(2026, 9, 21, 12);
      final provenance = ImageProvenance(
        sha256: 'a' * 64,
        byteLength: 10,
        detectedFormat: 'png',
        sourceName: 'cat.png',
        source: ImageProvenance.singleImport,
        importedBy: _adminId,
        importedAtUtc: at,
      );
      final back = ImageProvenance.fromJson(provenance.toJson());
      expect(back.toJson(), provenance.toJson());
      expect(back.importedAtUtc, at);
      expect(ImageProvenance(sha256: 'b' * 64).toJson(), {'sha256': 'b' * 64});
      for (final bad in [
        {'sha256': 'not hex'},
        {'sha256': 'a' * 64, 'path': 'C:/x'},
        {'sha256': 'a' * 64, 'source': 'internet'},
        {'sha256': 'a' * 64, 'importedAtUtc': 'yesterday'},
      ]) {
        expect(() => ImageProvenance.fromJson(bad), throwsFormatException);
      }
    });

    test('the date sort uses the recorded import time', () {
      final at = DateTime.utc(2025, 1, 2);
      final item = ExerciseImageMetadata(
        id: 'local_1000000000000000',
        label: 'x',
        category: 'other',
        tags: const ['x'],
        assetPath: 'C:/x.png',
        origin: 'local',
        provenance: ImageProvenance(sha256: 'c' * 64, importedAtUtc: at),
      );
      expect(stampedAddedDate(item), at);
    });
  });

  group('Image Banks', () {
    test('records provenance for every image', () async {
      final picture = uniquePng(1);
      await import(await bank({'p1': picture}));
      final provenance = (await record('p1'))!.provenance!;
      expect(provenance.sha256, _sha(picture));
      expect(provenance.byteLength, picture.length);
      expect(provenance.detectedFormat, 'png');
      expect(provenance.sourceName, 'p1.png');
      expect(provenance.source, ImageProvenance.imageBank);
      expect(provenance.bankId, startsWith('bank_'));
      expect(provenance.importedBy, _adminId);
      expect(provenance.importedAtUtc, isNotNull);
    });

    test('a picture already here is skipped without asking', () async {
      await import(await bank({'d1': uniquePng(2)}));
      var asked = false;
      final result = await import(
        await bank({
          'd2': uniquePng(2), // same picture, other ID
          'd3': uniquePng(3),
          'd4': uniquePng(3), // same picture twice in one bank
          'd5': Uint8List.fromList(
            File('assets/exercise_images/apple.webp').readAsBytesSync(),
          ), // one of QQL's own pictures
        }),
        onConflict: (_) async {
          asked = true;
          return (choice: ConflictChoice.skip, applyToAll: false);
        },
      );
      expect(asked, isFalse);
      expect(result.imported, 1);
      expect(result.duplicatesSkipped, 3);
      expect(await record('d2'), isNull);
      expect(await record('d3'), isNotNull);
    });

    test('same ID, different picture: skip keeps the old one', () async {
      await import(await bank({'s1': uniquePng(4)}));
      final result = await import(
        await bank({'s1': uniquePng(5)}),
        onConflict: (_) async =>
            (choice: ConflictChoice.skip, applyToAll: false),
      );
      expect(result.conflictsSkipped, 1);
      expect((await record('s1'))!.provenance!.sha256, _sha(uniquePng(4)));
    });

    test('keep both stores the new one under a fresh ID', () async {
      await import(await bank({'k1': uniquePng(6)}));
      final result = await import(
        await bank({'k1': uniquePng(7)}),
        onConflict: (_) async =>
            (choice: ConflictChoice.keepBoth, applyToAll: false),
      );
      expect(result.keptBoth, 1);
      expect((await record('k1'))!.provenance!.sha256, _sha(uniquePng(6)));
      expect((await record('k1-2'))!.provenance!.sha256, _sha(uniquePng(7)));
    });

    test('replace swaps the picture and keeps the ID', () async {
      await import(await bank({'r1': uniquePng(8)}));
      final before = (await record('r1'))!;
      final result = await import(
        await bank({'r1': uniquePng(9)}),
        onConflict: (conflict) async {
          expect(conflict.canReplace, isTrue);
          expect(conflict.existing.id, 'r1');
          return (choice: ConflictChoice.replace, applyToAll: false);
        },
      );
      expect(result.replaced, 1);
      final after = (await record('r1'))!;
      expect(after.provenance!.sha256, _sha(uniquePng(9)));
      expect(after.origin, isNot(before.origin));
      expect(await File(after.assetPath).readAsBytes(), uniquePng(9));
      // Only one record for the ID.
      expect(
        (await metadata.loadCatalog()).where((item) => item.id == 'r1'),
        hasLength(1),
      );
    });

    test('Apply to all answers the remaining conflicts', () async {
      await import(await bank({'a1': uniquePng(10), 'a2': uniquePng(11)}));
      var asked = 0;
      final result = await import(
        await bank({'a1': uniquePng(12), 'a2': uniquePng(13)}),
        onConflict: (_) async {
          asked++;
          return (choice: ConflictChoice.keepBoth, applyToAll: true);
        },
      );
      expect(asked, 1);
      expect(result.keptBoth, 2);
      expect(await record('a1-2'), isNotNull);
      expect(await record('a2-2'), isNotNull);
    });

    test('QQL images are never replaced', () async {
      final result = await import(
        await bank({'bread': uniquePng(14)}),
        onConflict: (conflict) async {
          expect(conflict.canReplace, isFalse);
          return (choice: ConflictChoice.replace, applyToAll: true);
        },
      );
      expect(result.replaced, 0);
      expect(result.conflictsSkipped, 1);
      expect(isBundledImage((await record('bread'))!), isTrue);
    });

    test('without an answer, conflicts are skipped', () async {
      await import(await bank({'n1': uniquePng(15)}));
      final result = await import(await bank({'n1': uniquePng(16)}));
      expect(result.conflictsSkipped, 1);
      expect(result.imported, 0);
    });
  });

  group('single images', () {
    testWidgets('provenance is recorded and a second copy is skipped', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final backend = FakeFileDialogBackend();
        final images = ExerciseImageService(
          fileDialogs: FileDialogService(
            backend: backend,
            stager: testImportStager(),
          ),
          supportDirectory: () async => temp,
        );
        Future<PickedImage> pick(String name, Uint8List bytes) async {
          backend.onOpen = () async => FileDialogResult.opened(name, bytes);
          return (await images.readImageFromDialog()).picked!;
        }

        final picture = uniquePng(20);
        final added = await images.addToSharedLibrary(
          actorProfileId: _adminId,
          picked: await pick('My Cat.png', picture),
          metadata: metadata,
        );
        final provenance = (await record(added.id))!.provenance!;
        expect(provenance.sha256, _sha(picture));
        expect(provenance.sourceName, 'My Cat.png');
        expect(provenance.source, ImageProvenance.singleImport);
        expect(provenance.importedBy, _adminId);

        // The same picture under another name is a duplicate…
        await expectLater(
          images.addToSharedLibrary(
            actorProfileId: _adminId,
            picked: await pick('renamed.png', picture),
            metadata: metadata,
          ),
          throwsA(
            isA<DuplicateImageException>().having(
              (error) => error.existing.id,
              'existing',
              added.id,
            ),
          ),
        );
        // …and so is one of QQL's own pictures.
        await expectLater(
          images.addToSharedLibrary(
            actorProfileId: _adminId,
            picked: await pick(
              'apple copy.webp',
              File('assets/exercise_images/apple.webp').readAsBytesSync(),
            ),
            metadata: metadata,
          ),
          throwsA(isA<DuplicateImageException>()),
        );
      });
    });

    test('older records are hashed once and the hash is kept', () async {
      final file = File('${temp.path}${Platform.pathSeparator}old.png');
      await file.writeAsBytes(uniquePng(30));
      await metadata.addLocalRecord(
        actorProfileId: _adminId,
        record: ExerciseImageMetadata(
          id: 'local_1000000000000001',
          label: 'Old',
          category: 'other',
          tags: const ['old'],
          assetPath: file.path,
          origin: 'local',
        ),
      );
      expect((await record('local_1000000000000001'))!.provenance, isNull);
      final index = await metadata.contentIndex(actorProfileId: _adminId);
      expect(index[_sha(uniquePng(30))]?.id, 'local_1000000000000001');
      final stored = (await record('local_1000000000000001'))!.provenance!;
      expect(stored.sha256, _sha(uniquePng(30)));
      expect(stored.byteLength, uniquePng(30).length);
      expect(stored.source, isNull);
    });
  });
}
