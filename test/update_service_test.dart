import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/update_service.dart';

void main() {
  group('UpdateService version comparison', () {
    test('accepts v-prefixed GitHub tags', () {
      expect(UpdateService.normalizeVersion('v1.5.6'), '1.5.6');
      expect(UpdateService.compareVersions('v1.5.6', '1.5.5'), greaterThan(0));
    });

    test('preserves and compares numeric QQL build metadata', () {
      expect(UpdateService.normalizeVersion('v2.0.29+2293'), '2.0.29+2293');
      expect(
        UpdateService.compareVersions('2.0.29+2293', '2.0.29+2292'),
        greaterThan(0),
      );
      expect(UpdateService.compareVersions('2.0.29+2293', '2.0.29+2293'), 0);
      expect(
        UpdateService.compareVersions('2.0.29+2292', '2.0.29+2293'),
        lessThan(0),
      );
    });

    test('semantic components take precedence over build metadata', () {
      expect(
        UpdateService.compareVersions('2.0.30+1', '2.0.29+9999'),
        greaterThan(0),
      );
      expect(
        UpdateService.compareVersions('2.0.29+1', '2.0.29'),
        greaterThan(0),
      );
    });

    test('compares semantic version components numerically', () {
      expect(UpdateService.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(UpdateService.compareVersions('2.0.0', '2.0.0'), 0);
      expect(UpdateService.compareVersions('1.4.9', '1.5.0'), lessThan(0));
    });
  });

  group('UpdateService URL hardening', () {
    test('accepts only official QuisquisLingo GitHub release URLs', () {
      expect(
        UpdateService.isTrustedReleaseUrl(
          'https://github.com/Quisquisnaut/QuisquisLingo/releases/tag/v1.5.6',
        ),
        isTrue,
      );
      expect(
        UpdateService.isTrustedReleaseUrl(
          'https://evil.example/Quisquisnaut/QuisquisLingo/releases/tag/v1.5.6',
        ),
        isFalse,
      );
      expect(
        UpdateService.isTrustedReleaseUrl(
          'http://github.com/Quisquisnaut/QuisquisLingo/releases/tag/v1.5.6',
        ),
        isFalse,
      );
      expect(
        UpdateService.isTrustedReleaseUrl(
          'https://github.com/Other/QuisquisLingo/releases/tag/v1.5.6',
        ),
        isFalse,
      );
      expect(
        UpdateService.isTrustedReleaseUrl(
          'https://github.com/Quisquisnaut/QuisquisLingo/releases/tag/v1.5.6?next=https://evil.example',
        ),
        isFalse,
      );
    });
  });

  group('UpdateService platform asset selection', () {
    const windows = UpdateAsset(
      name: 'quisquislingo_windows_alpha_232.zip',
      downloadUrl:
          'https://github.com/Quisquisnaut/QuisquisLingo/releases/download/v2.0.32%2B232/quisquislingo_windows_alpha_232.zip',
    );
    const linux = UpdateAsset(
      name: 'quisquislingo_linux_alpha_232.zip',
      downloadUrl:
          'https://github.com/Quisquisnaut/QuisquisLingo/releases/download/v2.0.32%2B232/quisquislingo_linux_alpha_232.zip',
    );
    const source = UpdateAsset(
      name: 'quisquislingo_alpha_232_source.zip',
      downloadUrl:
          'https://github.com/Quisquisnaut/QuisquisLingo/releases/download/v2.0.32%2B232/quisquislingo_alpha_232_source.zip',
    );

    UpdateRelease release(List<UpdateAsset> assets) => UpdateRelease(
      tagName: 'v2.0.32+232',
      version: '2.0.32+232',
      title: 'QuisquisLingo 2.0.32',
      notes: '',
      htmlUrl:
          'https://github.com/Quisquisnaut/QuisquisLingo/releases/tag/v2.0.32%2B232',
      assets: assets,
    );

    test('recognizes Linux and Windows operating systems', () {
      expect(UpdatePlatform.fromOperatingSystem('linux'), UpdatePlatform.linux);
      expect(
        UpdatePlatform.fromOperatingSystem('windows'),
        UpdatePlatform.windows,
      );
      expect(UpdatePlatform.fromOperatingSystem('freebsd'), isNull);
    });

    test('recognizes the actual QQL Linux release package', () {
      final service = UpdateService();
      final selected = service.compatibleAsset(
        release([linux]),
        UpdatePlatform.linux,
      );

      expect(selected, same(linux));
      expect(
        service.platformAvailable(release([linux]), UpdatePlatform.linux),
        isTrue,
      );
    });

    test('keeps recognizing the actual QQL Windows release package', () {
      final selected = UpdateService().compatibleAsset(
        release([windows]),
        UpdatePlatform.windows,
      );

      expect(selected, same(windows));
    });

    test('Linux never selects the Windows package', () {
      final service = UpdateService();

      expect(
        service.compatibleAsset(release([windows]), UpdatePlatform.linux),
        isNull,
      );
      expect(
        service.platformAvailable(release([windows]), UpdatePlatform.linux),
        isFalse,
      );
    });

    test('Windows never selects the Linux package', () {
      final service = UpdateService();

      expect(
        service.compatibleAsset(release([linux]), UpdatePlatform.windows),
        isNull,
      );
      expect(
        service.platformAvailable(release([linux]), UpdatePlatform.windows),
        isFalse,
      );
    });

    test('source and incompatible assets are not selected', () {
      final service = UpdateService();
      final incompatible = release([
        source,
        const UpdateAsset(
          name: 'quisquislingo_linux_alpha_232.dmg',
          downloadUrl:
              'https://github.com/Quisquisnaut/QuisquisLingo/releases/download/v2.0.32%2B232/quisquislingo_linux_alpha_232.dmg',
        ),
      ]);

      expect(
        service.compatibleAsset(incompatible, UpdatePlatform.linux),
        isNull,
      );
      expect(
        service.compatibleAsset(incompatible, UpdatePlatform.windows),
        isNull,
      );
    });

    test('release without a compatible package remains unavailable', () {
      final service = UpdateService();
      final onlyOtherPlatforms = release([linux]);

      expect(
        service.platformAvailable(onlyOtherPlatforms, UpdatePlatform.windows),
        isFalse,
      );
      expect(
        UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          release: onlyOtherPlatforms,
        ).status,
        UpdateCheckStatus.updateAvailable,
      );
    });
  });
}
