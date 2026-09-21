import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/editor_help_content.dart';
import 'package:quisquislingo_app/services/image_preview_tooltip.dart';
import 'package:quisquislingo_app/widgets/help_language_toggle.dart';

void main() {
  const bundled = ExerciseImageMetadata(
    id: 'apple',
    label: 'Apple',
    category: 'food_drinks',
    tags: ['apple'],
    assetPath: 'assets/exercise_images/apple.webp',
    origin: 'bundled',
  );

  test('bundled image names its asset and QQL inclusion', () {
    final message = imagePreviewTooltip(
      item: bundled,
      byteLength: 1536,
      width: 256,
      height: 128,
      format: 'WebP',
    );
    expect(message, contains('File: apple.webp'));
    expect(message, contains('Size: about 1.5 KB'));
    expect(message, contains('Dimensions: 256 × 128 pixels'));
    expect(message, contains('Format: WebP'));
    expect(message, contains('Included with QQL'));
  });

  test('new bank image shows recorded name, bank, date and attribution', () {
    const item = ExerciseImageMetadata(
      id: 'bank-apple',
      label: 'Apple',
      category: 'food_drinks',
      tags: ['apple'],
      assetPath: 'C:/images/stored-name.png',
      origin: 'bank:bank_1',
      provenance: ImageProvenance(
        sha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        sourceName: 'original-name.png',
        importedBy: 'admin-profile',
      ),
      attribution: ImageAttribution(
        author: 'A. Artist',
        license: 'CC BY 4.0',
        title: 'Apple study',
        source: 'Example Archive',
      ),
    );
    final message = imagePreviewTooltip(
      item: item,
      byteLength: 2 * 1024 * 1024,
      width: 300,
      height: 300,
      format: 'PNG',
      addedAt: DateTime.utc(2026, 9, 21),
      bankName: 'Fruit pictures',
      alsoStoredInCourse: true,
    );
    expect(message, contains('File: original-name.png'));
    expect(message, contains('Size: about 2.0 MB'));
    expect(message, contains('Added: 2026-09-21'));
    expect(message, contains('Bank: Fruit pictures'));
    expect(message, contains('Author: A. Artist'));
    expect(message, contains('License: CC BY 4.0'));
    expect(message, contains('Work: Apple study'));
    expect(message, contains('Source: Example Archive'));
    expect(message, contains('Also stored in this Course'));
    expect(message, isNot(contains('admin-profile')));
  });

  test('older device import falls back to stored name', () {
    const item = ExerciseImageMetadata(
      id: 'old',
      label: 'Old',
      category: 'other',
      tags: [],
      assetPath: 'C:/images/stored-name.png',
      origin: 'local',
    );
    final message = imagePreviewTooltip(item: item, format: 'PNG');
    expect(message, contains('File: stored-name.png'));
    expect(message, contains('Added: Unknown'));
  });

  test('Course media has a content-based name and a missing state', () {
    const item = ExerciseImageMetadata(
      id: 'course-one',
      label: 'Course image',
      category: 'other',
      tags: [],
      assetPath:
          'media:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.webp',
      origin: 'course',
    );
    final message = imagePreviewTooltip(item: item, format: 'WebP');
    expect(message, contains('File: Course file (named by content)'));
    expect(imagePreviewTooltip(item: item, missing: true), 'File missing');
  });

  test('the preview gesture guidance is in English Help only', () {
    final english = editorHelpSections(
      HelpLanguage.english,
    ).singleWhere((section) => section.title == 'Image Bank').body;
    final italian = editorHelpSections(
      HelpLanguage.italian,
    ).map((section) => section.body).join(' ');
    expect(english, contains('hover over the picture'));
    expect(english, contains('long-press it on a phone'));
    expect(italian, isNot(contains('hover over the picture')));
  });
}
