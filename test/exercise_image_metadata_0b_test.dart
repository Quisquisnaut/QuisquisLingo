import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/models/image_categories.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

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
        expect(catalog, hasLength(bundledImageCount));
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
      expect(catalog, hasLength(bundledImageCount));
      expect(catalog.singleWhere((r) => r.id == 'actions_jump').localWords, [
        'hop',
      ]);
    },
  );

  // Build 264 Revision 2: an Admin no longer adds or renames categories.
  // A category added on a device before can still be read and removed.
  group('device categories', () {
    Future<void> storeLegacyCategory(List<Map<String, Object>> records) async =>
        SharedPreferences.setMockInitialValues({
          ..._profiles(),
          ExerciseImageMetadataService.preferencesKey: jsonEncode({
            'schemaVersion': 2,
            'records': records,
            'deviceCategories': ['musical_instruments'],
          }),
        });

    test('a category from before is read, used and removed', () async {
      await storeLegacyCategory([
        {
          'id': 'local_2000000000000000',
          'label': 'Drum',
          'category': 'musical_instruments',
          'tags': ['percussion'],
          'assetPath': 'C:/images/drum.webp',
          'origin': 'local',
        },
      ]);
      final service = ExerciseImageMetadataService();
      expect(await service.deviceCategories(), ['musical_instruments']);
      expect(await service.allCategories(), contains('musical_instruments'));
      // In use: cannot be removed.
      await expectLater(
        service.removeDeviceCategory(
          actorProfileId: _adminId,
          name: 'musical_instruments',
        ),
        throwsFormatException,
      );
      await service.removeLocalRecords(
        actorProfileId: _adminId,
        imageIds: {'local_2000000000000000'},
      );
      await service.removeDeviceCategory(
        actorProfileId: _adminId,
        name: 'musical_instruments',
      );
      expect(await service.deviceCategories(), isEmpty);
    });

    test('an Admin picture takes one of the library\'s categories', () async {
      final service = ExerciseImageMetadataService();
      expect(ExerciseImageMetadataService.categories, imageCategories);
      await expectLater(
        service.addLocalRecord(
          actorProfileId: _adminId,
          record: const ExerciseImageMetadata(
            id: 'local_3000000000000000',
            label: 'Drum',
            category: 'musical_instruments',
            tags: ['percussion'],
            assetPath: 'C:/images/drum.webp',
            origin: 'local',
          ),
        ),
        throwsFormatException,
      );
    });

    test(
      'a device picture filed under an earlier name moves with it',
      () async {
        SharedPreferences.setMockInitialValues({
          ..._profiles(),
          ExerciseImageMetadataService.preferencesKey: jsonEncode({
            'schemaVersion': 2,
            'records': [
              {
                'id': 'local_4000000000000000',
                'label': 'Hand-drawn A',
                'category': 'letters_latin',
                'tags': ['letter'],
                'assetPath': 'C:/images/a.webp',
                'origin': 'local',
              },
            ],
          }),
        });
        final record = await ExerciseImageMetadataService().metadataFor(
          'local_4000000000000000',
        );
        expect(record.category, 'characters_latin');
      },
    );

    test('QQL categories cannot be removed', () async {
      final service = ExerciseImageMetadataService();
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
