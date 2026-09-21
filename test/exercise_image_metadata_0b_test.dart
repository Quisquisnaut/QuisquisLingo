import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';

Map<String, Object> _profiles() => {
  ProfileService.profilesKey: [
    const LearnerProfile(
      learnerProfileId: _adminId,
      displayName: 'Admin',
    ).encode(),
  ],
  ProfileService.adminProfileIdsKey: [_adminId],
};

const _deviceCat = ExerciseImageMetadata(
  id: 'local_1000000000000000',
  label: 'Cat',
  category: 'animals',
  tags: ['cat'],
  assetPath: 'C:/images/cat.webp',
  origin: 'local',
);

Future<String?> _stored() async => (await SharedPreferences.getInstance())
    .getString(ExerciseImageMetadataService.preferencesKey);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(_profiles()));

  group('one-time conversion of the old whole-catalog snapshot', () {
    Future<List<ExerciseImageMetadata>> convert(
      Map<String, dynamic> Function(Map<String, dynamic> record) change, {
      bool dropJump = false,
      List<Map<String, dynamic>> extra = const [],
    }) async {
      final bundled = await ExerciseImageMetadataService().loadCatalog();
      final snapshot = jsonEncode({
        'schemaVersion': 1,
        'records': [
          for (final record in bundled)
            if (!(dropJump && record.id == 'actions_jump'))
              change(record.toJson()),
          ...extra,
        ],
      });
      SharedPreferences.setMockInitialValues({
        ..._profiles(),
        ExerciseImageMetadataService.preferencesKey: snapshot,
      });
      return ExerciseImageMetadataService().loadCatalog();
    }

    test(
      'added tags become Local words; removed tags and category return',
      () async {
        final seed = await ExerciseImageMetadataService().metadataFor(
          'people_family_man',
        );
        final catalog = await convert((record) {
          if (record['id'] == 'people_family_man') {
            record['tags'] = [seed.tags.first, 'colleague', 'Neighbour'];
            record['category'] = 'other';
          }
          return record;
        });
        final man = catalog.singleWhere((r) => r.id == 'people_family_man');
        expect(man.tags, seed.tags);
        expect(man.category, seed.category);
        expect(man.localWords, ['colleague', 'Neighbour']);
        final stored = jsonDecode((await _stored())!) as Map;
        expect(stored['schemaVersion'], 2);
        expect(stored['records'], isEmpty);
        expect(stored['localWords'], {
          'people_family_man': ['colleague', 'Neighbour'],
        });
      },
    );

    test('device images survive; unknown bundled records leave', () async {
      final catalog = await convert(
        (record) => record,
        extra: [
          _deviceCat.toJson(),
          {
            'id': 'retired_qql_image',
            'label': 'Retired',
            'category': 'other',
            'tags': ['retired'],
            'assetPath': 'assets/exercise_images/retired.webp',
            'origin': 'bundled',
          },
        ],
      );
      expect(catalog.map((r) => r.id), contains(_deviceCat.id));
      expect(catalog.map((r) => r.id), isNot(contains('retired_qql_image')));
    });

    test(
      'a snapshot missing a QQL image no longer breaks the library',
      () async {
        // Before Tranche 0b this threw "Current exercise-image metadata is
        // missing …" as soon as a release added a bundled image.
        final catalog = await convert((record) => record, dropJump: true);
        expect(catalog.map((r) => r.id), contains('actions_jump'));
        expect(catalog, hasLength(111));
      },
    );
  });

  test(
    'Local words for an image the app no longer ships are ignored',
    () async {
      SharedPreferences.setMockInitialValues({
        ..._profiles(),
        ExerciseImageMetadataService.preferencesKey: jsonEncode({
          'schemaVersion': 2,
          'records': [],
          'localWords': {
            'no_longer_shipped': ['x'],
            'actions_jump': ['hop'],
          },
        }),
      });
      final catalog = await ExerciseImageMetadataService().loadCatalog();
      expect(catalog, hasLength(111));
      expect(catalog.singleWhere((r) => r.id == 'actions_jump').localWords, [
        'hop',
      ]);
    },
  );

  group('device categories', () {
    test('add, use, rename and remove', () async {
      final service = ExerciseImageMetadataService();
      final name = await service.addDeviceCategory(
        actorProfileId: _adminId,
        name: ' Musical Instruments ',
      );
      expect(name, 'musical_instruments');
      expect(await service.allCategories(), contains(name));
      await service.addLocalRecord(
        actorProfileId: _adminId,
        record: const ExerciseImageMetadata(
          id: 'local_2000000000000000',
          label: 'Drum',
          category: 'musical_instruments',
          tags: ['drum'],
          assetPath: 'C:/images/drum.webp',
          origin: 'local',
        ),
      );
      // In use: cannot be removed.
      await expectLater(
        service.removeDeviceCategory(actorProfileId: _adminId, name: name),
        throwsFormatException,
      );
      final renamed = await service.renameDeviceCategory(
        actorProfileId: _adminId,
        from: name,
        to: 'instruments',
      );
      expect(
        (await service.metadataFor('local_2000000000000000')).category,
        renamed,
      );
      await service.removeLocalRecords(
        actorProfileId: _adminId,
        imageIds: {'local_2000000000000000'},
      );
      await service.removeDeviceCategory(
        actorProfileId: _adminId,
        name: renamed,
      );
      expect(await service.deviceCategories(), isEmpty);
    });

    test('names follow the rules and never clash', () async {
      final service = ExerciseImageMetadataService();
      for (final bad in ['a', '9lives', 'animals', 'food', 'home', 'x' * 41]) {
        await expectLater(
          service.addDeviceCategory(actorProfileId: _adminId, name: bad),
          throwsFormatException,
          reason: bad,
        );
      }
      await service.addDeviceCategory(actorProfileId: _adminId, name: 'sports');
      await expectLater(
        service.addDeviceCategory(actorProfileId: _adminId, name: 'Sports'),
        throwsFormatException,
      );
    });

    test('at most 64 device categories', () async {
      final service = ExerciseImageMetadataService();
      for (
        var i = 0;
        i < ExerciseImageMetadataService.maxDeviceCategories;
        i++
      ) {
        await service.addDeviceCategory(
          actorProfileId: _adminId,
          name: 'cat_$i',
        );
      }
      await expectLater(
        service.addDeviceCategory(actorProfileId: _adminId, name: 'one_more'),
        throwsFormatException,
      );
    });

    test('QQL categories cannot be renamed or removed', () async {
      final service = ExerciseImageMetadataService();
      await expectLater(
        service.renameDeviceCategory(
          actorProfileId: _adminId,
          from: 'animals',
          to: 'beasts',
        ),
        throwsStateError,
      );
      await expectLater(
        service.removeDeviceCategory(actorProfileId: _adminId, name: 'animals'),
        throwsStateError,
      );
    });
  });

  test('Local words: limits, and only for QQL images', () async {
    final service = ExerciseImageMetadataService();
    await expectLater(
      service.updateLocalWords(
        actorProfileId: _adminId,
        imageId: 'actions_jump',
        words: [for (var i = 0; i < 33; i++) 'w$i'],
      ),
      throwsFormatException,
    );
    await expectLater(
      service.updateLocalWords(
        actorProfileId: _adminId,
        imageId: 'actions_jump',
        words: ['x' * 81],
      ),
      throwsFormatException,
    );
    await service.addLocalRecord(actorProfileId: _adminId, record: _deviceCat);
    await expectLater(
      service.updateLocalWords(
        actorProfileId: _adminId,
        imageId: _deviceCat.id,
        words: const ['kitty'],
      ),
      throwsStateError,
    );
  });

  test('tile line and search include Local words', () {
    const item = ExerciseImageMetadata(
      id: 'actions_jump',
      label: 'Jump',
      category: 'actions',
      tags: ['Jump'],
      assetPath: 'assets/exercise_images/jump.webp',
      origin: 'bundled',
      localWords: ['Saltare'],
    );
    expect(imageTileTags(item), 'Tags: jump · Local: saltare');
    expect(imageTileTags(item.copyWith(tags: const [])), 'Local: saltare');
    expect(matchesImageSearch(item, normalizeImageSearchText('salt')), isTrue);
  });
}
