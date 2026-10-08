import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `demo_image_banks/example_image_bank.zip` is the only example of an Image
/// Bank in the repository, so it has to be one that actually imports.
///
/// The file it replaced did not: `assets/exercise_images/image_bank_manifest.json`
/// listed the 111 bundled image IDs, and `importBankZip` refuses any ID the
/// application already has, so a bank built from it was rejected outright.
/// This test imports the example through the real importer so the same trap
/// cannot be set again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    support = await Directory.systemTemp.createTemp('qql_example_bank_');
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  test('the example bank ships outside assets/ and is not an app asset', () {
    expect(
      File('demo_image_banks/example_image_bank.zip').existsSync(),
      isTrue,
    );
    // Anything under assets/ is packed into the application; an author-facing
    // template must not be shipped to every learner.
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('demo_image_banks')),
    );
    // The obsolete in-app manifests were removed with it.
    for (final stale in const [
      'assets/exercise_images/manifest.json',
      'assets/exercise_images/manifest_external.json',
      'assets/exercise_images/image_bank_manifest.json',
    ]) {
      expect(File(stale).existsSync(), isFalse, reason: '$stale is obsolete');
    }
  });

  test('the example bank imports through the real importer', () async {
    final service = ImageBankService();
    final result = await IOOverrides.runZoned(
      () => service.importBankZip(
        File('demo_image_banks/example_image_bank.zip'),
        // Bundled IDs, as the app would pass them. The example must not
        // collide with any of them.
        existingIds: const {'bread', 'apple', 'house', 'people_family_man'},
      ),
      getCurrentDirectory: () => Directory.current,
    );

    expect(result.imported, 3);
    expect(result.warnings, isEmpty);
    expect(
      result.records.map((record) => record.id),
      containsAll(<String>[
        'example_bank_red',
        'example_bank_green',
        'example_bank_blue',
      ]),
      reason: 'example IDs must be distinct from the bundled catalogue',
    );
    for (final record in result.records) {
      expect(File(record.assetPath).existsSync(), isTrue);
      expect(record.origin, startsWith('bank:'));
    }
  });
}
