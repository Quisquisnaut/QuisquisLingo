import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';
const _learnerId = '22222222-2222-4222-8222-222222222222';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _adminId,
          displayName: 'Admin',
        ).encode(),
        const LearnerProfile(
          learnerProfileId: _learnerId,
          displayName: 'Learner',
        ).encode(),
      ],
      ProfileService.adminProfileIdsKey: [_adminId],
      'quisquislingo_custom_image_bank_v1': [
        jsonEncode({
          'id': 'obsolete-custom',
          'label': 'Must not load',
          'category': 'legacy',
          'tags': ['obsolete'],
          'assetPath': 'obsolete.png',
        }),
      ],
      'quisquislingo_imported_image_banks_v1': ['obsolete-bank'],
    });
  });

  test('new canonical catalog is the only metadata source', () async {
    final records = await ExerciseImageMetadataService().loadCatalog();

    expect(records, hasLength(111));
    expect(records.where((record) => record.id == 'obsolete-custom'), isEmpty);
    expect(
      records.map((record) => record.id).toSet(),
      hasLength(records.length),
    );
    expect(
      records.map((record) => record.assetPath).toSet(),
      hasLength(records.length),
    );
  });

  test('bundled schema is English-only and has no parallel namespaces', () {
    final document =
        jsonDecode(
              File(
                ExerciseImageMetadataService.bundledCatalogAsset,
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final records = (document['records'] as List).cast<Map<String, dynamic>>();

    expect(document['schemaVersion'], 1);
    for (final record in records) {
      expect(record.keys, {
        'id',
        'label',
        'category',
        'tags',
        'assetPath',
        'origin',
      });
      expect(
        record.keys.where((key) => key.toLowerCase().contains('ital')),
        isEmpty,
      );
      expect(
        record.keys.where((key) => key.toLowerCase().contains('locale')),
        isEmpty,
      );
      expect((record['category'] as String).trim(), isNotEmpty);
      expect((record['tags'] as List), isNotEmpty);
    }
    expect(records.every((record) => record['category'] != 'food'), isTrue);
  });

  test(
    'legacy Food category is normalized and persisted as Food Drinks',
    () async {
      final service = ExerciseImageMetadataService();
      final records = await service.loadCatalog();
      final raw = jsonEncode({
        'schemaVersion': 1,
        'records': records.map((record) {
          final value = record.toJson();
          if (value['category'] == 'food_drinks') {
            value['category'] = 'food';
          } else if (value['category'] == 'home_household') {
            value['category'] = 'home';
          }
          if (value['id'] == 'people_family_man') value['label'] = 'Uomo';
          return value;
        }).toList(),
      });
      SharedPreferences.setMockInitialValues({
        ExerciseImageMetadataService.preferencesKey: raw,
      });

      final migrated = await service.loadCatalog();
      expect(migrated.every((record) => record.category != 'food'), isTrue);
      expect(
        migrated.firstWhere((record) => record.id == 'people_family_man').label,
        'Man',
      );
      expect(migrated.any((record) => record.category == 'home'), isFalse);
      final persisted = (await SharedPreferences.getInstance()).getString(
        ExerciseImageMetadataService.preferencesKey,
      );
      expect(persisted, isNot(contains('"category":"food"')));
    },
  );

  test('Admin correction is global and survives a service restart', () async {
    final firstService = ExerciseImageMetadataService();
    final before = await firstService.metadataFor('people_family_man');
    expect(before.tags, containsAll(['man', 'friend']));

    await firstService.updateMetadata(
      actorProfileId: _adminId,
      imageId: before.id,
      category: 'people_family',
      tags: ['man', 'friend', 'adult man'],
    );

    final restarted = ExerciseImageMetadataService();
    final after = await restarted.metadataFor(before.id);
    expect(after.category, 'people_family');
    expect(after.tags, ['man', 'friend', 'adult man']);
    expect(
      (await restarted.loadCatalog()).where((record) => record.id == before.id),
      hasLength(1),
    );
  });

  test('Admin-added image attribution persists and can be cleared', () async {
    final service = ExerciseImageMetadataService();
    await service.addLocalRecord(
      actorProfileId: _adminId,
      record: const ExerciseImageMetadata(
        id: 'local_cat',
        label: 'Cat',
        category: 'animals',
        tags: ['cat'],
        assetPath: 'local_cat.webp',
        origin: 'local',
        attribution: ImageAttribution(
          author: 'A. Artist',
          license: 'CC BY 4.0',
          source: 'https://example.org/cat',
        ),
      ),
    );
    final restarted = ExerciseImageMetadataService();
    expect(
      (await restarted.metadataFor('local_cat')).attribution?.author,
      'A. Artist',
    );

    await restarted.updateMetadata(
      actorProfileId: _adminId,
      imageId: 'local_cat',
      category: 'animals',
      tags: ['cat'],
      attribution: null,
    );
    expect((await restarted.metadataFor('local_cat')).attribution, isNull);
  });

  test('attribution requires author and license and is device-only', () async {
    final service = ExerciseImageMetadataService();
    await expectLater(
      service.updateMetadata(
        actorProfileId: _adminId,
        imageId: 'actions_jump',
        category: 'actions',
        tags: const ['jump'],
        attribution: const ImageAttribution(
          author: 'A. Artist',
          license: 'CC BY 4.0',
        ),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      service.addLocalRecord(
        actorProfileId: _adminId,
        record: const ExerciseImageMetadata(
          id: 'incomplete_credit',
          label: 'Incomplete credit',
          category: 'other',
          tags: ['image'],
          assetPath: 'incomplete.webp',
          origin: 'local',
          attribution: ImageAttribution(author: '', license: 'CC BY 4.0'),
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'non-Admin may read but service rejects every metadata mutation',
    () async {
      final service = ExerciseImageMetadataService();
      expect(
        (await service.metadataFor('actions_jump')).tags,
        contains('jump'),
      );

      await expectLater(
        service.updateMetadata(
          actorProfileId: _learnerId,
          imageId: 'actions_jump',
          category: 'actions',
          tags: const ['jump'],
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('empty and exact duplicate tags are rejected', () async {
    final service = ExerciseImageMetadataService();
    for (final tags in <List<String>>[
      ['jump', ''],
      ['jump', 'jump'],
    ]) {
      await expectLater(
        service.updateMetadata(
          actorProfileId: _adminId,
          imageId: 'actions_jump',
          category: 'actions',
          tags: tags,
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test(
    'malformed current namespace is reported without bundled fallback',
    () async {
      SharedPreferences.setMockInitialValues({
        ExerciseImageMetadataService.preferencesKey: '{not-json',
      });

      await expectLater(
        ExerciseImageMetadataService().loadCatalog(),
        throwsA(isA<FormatException>()),
      );
    },
  );
}
