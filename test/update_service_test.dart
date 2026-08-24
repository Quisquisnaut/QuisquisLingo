import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/update_service.dart';

void main() {
  group('UpdateService version comparison', () {
    test('accepts v-prefixed GitHub tags', () {
      expect(UpdateService.normalizeVersion('v1.5.6'), '1.5.6');
      expect(UpdateService.compareVersions('v1.5.6', '1.5.5'), greaterThan(0));
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

  test('platform availability is conservative and asset-based', () {
    const release = UpdateRelease(
      tagName: 'v1.5.6',
      version: '1.5.6',
      title: 'QuisquisLingo 1.5.6',
      notes: '',
      htmlUrl: 'https://github.com/Quisquisnaut/QuisquisLingo/releases/tag/v1.5.6',
      assets: [
        UpdateAsset(
          name: 'quisquislingo_windows_x64.zip',
          downloadUrl: 'https://github.com/Quisquisnaut/QuisquisLingo/releases/download/v1.5.6/quisquislingo_windows_x64.zip',
        ),
        UpdateAsset(
          name: 'quisquislingo_antix_1.5.6.deb',
          downloadUrl: 'https://github.com/Quisquisnaut/QuisquisLingo/releases/download/v1.5.6/quisquislingo_antix_1.5.6.deb',
        ),
      ],
    );
    final service = UpdateService();
    expect(service.platformAvailable(release, UpdatePlatform.windows), isTrue);
    expect(service.platformAvailable(release, UpdatePlatform.linuxAntix), isTrue);
    expect(service.platformAvailable(release, UpdatePlatform.macos), isFalse);
    expect(service.platformAvailable(release, UpdatePlatform.android), isFalse);
  });
}
