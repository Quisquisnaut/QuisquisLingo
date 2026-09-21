import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';

ExerciseImageMetadata _image(
  String id, {
  String label = 'Image',
  String origin = 'local',
  String assetPath = 'C:/images/x.png',
  List<String> tags = const ['tag'],
  String category = 'other',
}) => ExerciseImageMetadata(
  id: id,
  label: label,
  category: category,
  tags: tags,
  assetPath: assetPath,
  origin: origin,
);

final _bundled = _image(
  'apple',
  label: 'Apple',
  origin: 'bundled',
  assetPath: 'assets/exercise_images/apple.webp',
);
final _device = _image('local_2000000000000000', label: 'Cat');
final _bank = _image('b1', label: 'Bus', origin: 'bank:bank_1000000000000000');
final _course = _image('course_x', label: 'Map', origin: 'course');
final _courseCopy = _image('course_y', label: 'Cat', origin: 'course-device');

void main() {
  group('badges', () {
    test('each source gets its badge, IN USE last for now', () {
      expect(imageBadgesOf(_bundled), ['QQL']);
      expect(imageBadgesOf(_device), ['DEVICE']);
      expect(imageBadgesOf(_bank), ['DEVICE']);
      expect(imageBadgesOf(_course), ['COURSE']);
      expect(imageBadgesOf(_courseCopy), ['COURSE']);
      expect(imageBadgesOf(_bundled, used: true), ['QQL', 'IN USE']);
      expect(imageBadgesOf(_device, used: true, inCourse: true), [
        'DEVICE',
        'COURSE',
        'IN USE',
      ]);
      expect(imageSourceCode(['DEVICE', 'COURSE']), 'DEVICE · COURSE');
    });

    test('every badge has an explanation, in filter order', () {
      expect(imageBadgeOrder, ['QQL', 'DEVICE', 'COURSE', 'IN USE']);
      expect(imageBadgeMeanings.keys, unorderedEquals(imageBadgeOrder));
    });

    test('bundled and bank detection', () {
      expect(isBundledImage(_bundled), isTrue);
      expect(isBundledImage(_device), isFalse);
      expect(imageBankIdOf(_bank), 'bank_1000000000000000');
      expect(imageBankIdOf(_device), isNull);
    });
  });

  group('tile text and search', () {
    test('tags are lowercase and absent when empty', () {
      expect(
        imageTileTags(_image('t', tags: const ['Cat', 'PET'])),
        'Tags: cat, pet',
      );
      expect(imageTileTags(_image('t', tags: const [])), isNull);
    });

    test('search matches label, tags, ID and category, loosely', () {
      final item = _image(
        'people_family_man',
        label: 'Man',
        tags: const ['adult man'],
        category: 'people_family',
      );
      for (final query in ['man', 'ADULT', 'people family', 'family_man', '']) {
        expect(
          matchesImageSearch(item, normalizeImageSearchText(query)),
          isTrue,
          reason: query,
        );
      }
      expect(matchesImageSearch(item, 'zebra'), isFalse);
    });
  });

  group('added date and sorting', () {
    test('the added date comes from QQL-generated stamps only', () {
      expect(
        stampedAddedDate(_device),
        DateTime.fromMicrosecondsSinceEpoch(2000000000000000, isUtc: true),
      );
      expect(
        stampedAddedDate(_bank),
        DateTime.fromMicrosecondsSinceEpoch(1000000000000000, isUtc: true),
      );
      expect(stampedAddedDate(_bundled), isNull);
      expect(stampedAddedDate(_image('local_abc')), isNull);
    });

    List<String> sorted(
      ImageSort sort, {
      Map<String, DateTime> addedAt = const {},
      Map<String, int> fileBytes = const {},
    }) {
      final items = [_device, _bundled, _bank]
        ..sort(
          (a, b) => compareImages(
            a,
            b,
            sort: sort,
            addedAt: addedAt,
            fileBytes: fileBytes,
          ),
        );
      return items.map((item) => item.label).toList();
    }

    test('each order, with name as the tie-break', () {
      final dates = {
        for (final item in [_device, _bank]) item.id: stampedAddedDate(item)!,
      };
      expect(sorted(ImageSort.name), ['Apple', 'Bus', 'Cat']);
      expect(sorted(ImageSort.newest, addedAt: dates), ['Cat', 'Bus', 'Apple']);
      expect(sorted(ImageSort.oldest, addedAt: dates), ['Apple', 'Bus', 'Cat']);
      final sizes = {_device.id: 900, _bundled.id: 500};
      // An unmeasured file sorts last in both size orders.
      expect(sorted(ImageSort.largest, fileBytes: sizes), [
        'Cat',
        'Apple',
        'Bus',
      ]);
      expect(sorted(ImageSort.smallest, fileBytes: sizes), [
        'Apple',
        'Cat',
        'Bus',
      ]);
    });
  });

  group('device original and Course copy', () {
    test('the copy is absorbed while the original is on the device', () {
      final owned = [_courseCopy, _course];
      final copied = mergeCourseCopies(
        records: [_bundled, _device],
        owned: owned,
        ownedSources: {_courseCopy.id: _device.id, _course.id: null},
        isMissing: (_) => false,
      );
      expect(copied, {_device.id});
      expect(owned, [_course]);
    });

    test('the copy stays when the original is gone or its file is missing', () {
      for (final records in [
        [_bundled],
        [_bundled, _device],
      ]) {
        final owned = [_courseCopy];
        final copied = mergeCourseCopies(
          records: records,
          owned: owned,
          ownedSources: {_courseCopy.id: _device.id},
          isMissing: (item) => item.id == _device.id,
        );
        expect(copied, isEmpty);
        expect(owned, [_courseCopy]);
      }
    });
  });
}
