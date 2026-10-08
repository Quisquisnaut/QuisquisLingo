import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Result of a GitHub release check.
enum UpdateCheckStatus { updateAvailable, upToDate, noPublishedRelease }

class UpdateAsset {
  final String name;
  final String downloadUrl;

  const UpdateAsset({required this.name, required this.downloadUrl});
}

class UpdateRelease {
  final String tagName;
  final String version;
  final String title;
  final String notes;
  final String htmlUrl;
  final List<UpdateAsset> assets;

  const UpdateRelease({
    required this.tagName,
    required this.version,
    required this.title,
    required this.notes,
    required this.htmlUrl,
    required this.assets,
  });
}

class UpdateCheckResult {
  final UpdateCheckStatus status;
  final UpdateRelease? release;

  const UpdateCheckResult(this.status, {this.release});
}

/// Checks only the official QuisquisLingo GitHub Releases endpoint.
///
/// Security properties:
/// - the repository and API URL are hard-coded and HTTPS-only;
/// - no credentials, cookies, course data or learner data are transmitted;
/// - responses are size-bounded and parsed as plain JSON;
/// - redirects are rejected;
/// - downloaded release assets are never fetched or executed by the app;
/// - external links are opened only after strict GitHub URL validation.
class UpdateService {
  static const repositoryUrl = 'https://github.com/Quisquisnaut/QuisquisLingo';
  static const releasesUrl = '$repositoryUrl/releases';
  static const latestReleaseApiUrl =
      'https://api.github.com/repos/Quisquisnaut/QuisquisLingo/releases/latest';
  static const _apiVersion = '2026-03-10';
  static const _maxResponseBytes = 256 * 1024;
  static const _maxNotesChars = 12000;

  Future<UpdateCheckResult> check(String currentVersion) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.parse(latestReleaseApiUrl);
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      request
        ..followRedirects = false
        ..maxRedirects = 0
        ..headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..headers.set(HttpHeaders.userAgentHeader, 'QuisquisLingo-Update-Check')
        ..headers.set('X-GitHub-Api-Version', _apiVersion);

      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode == HttpStatus.notFound) {
        await response.drain();
        return const UpdateCheckResult(UpdateCheckStatus.noPublishedRelease);
      }
      if (response.statusCode != HttpStatus.ok) {
        await response.drain();
        throw UpdateCheckException(
          'GitHub returned HTTP ${response.statusCode}.',
        );
      }
      final declaredLength = response.contentLength;
      if (declaredLength > _maxResponseBytes) {
        await response.drain();
        throw const UpdateCheckException(
          'GitHub response is unexpectedly large.',
        );
      }

      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 8))) {
        bytes.addAll(chunk);
        if (bytes.length > _maxResponseBytes) {
          throw const UpdateCheckException(
            'GitHub response exceeded the safety limit.',
          );
        }
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const UpdateCheckException(
          'GitHub returned an unexpected response format.',
        );
      }
      final release = _parseRelease(decoded);
      final comparison = compareVersions(release.version, currentVersion);
      return UpdateCheckResult(
        comparison > 0
            ? UpdateCheckStatus.updateAvailable
            : UpdateCheckStatus.upToDate,
        release: release,
      );
    } on TimeoutException {
      throw const UpdateCheckException('The GitHub update check timed out.');
    } on SocketException {
      throw const UpdateCheckException('GitHub could not be reached.');
    } on FormatException {
      throw const UpdateCheckException('GitHub returned invalid release data.');
    } finally {
      client.close(force: true);
    }
  }

  UpdateRelease _parseRelease(Map<String, dynamic> json) {
    final tag = _requiredShortString(json['tag_name'], 'tag_name', max: 80);
    final version = normalizeVersion(tag);
    if (_parseVersion(version) == null) {
      throw const UpdateCheckException(
        'The latest release tag is not a supported version number.',
      );
    }
    final htmlUrl = _requiredShortString(
      json['html_url'],
      'html_url',
      max: 400,
    );
    if (!isTrustedReleaseUrl(htmlUrl)) {
      throw const UpdateCheckException(
        'GitHub returned an unexpected release URL.',
      );
    }
    final rawTitle = json['name'];
    final title = rawTitle is String && rawTitle.trim().isNotEmpty
        ? _plainText(_truncate(rawTitle.trim(), 200))
        : 'QuisquisLingo $version';
    final rawNotes = json['body'];
    final notes = rawNotes is String
        ? _plainText(_truncate(rawNotes, _maxNotesChars)).trim()
        : '';

    final assets = <UpdateAsset>[];
    final rawAssets = json['assets'];
    if (rawAssets is List) {
      for (final raw in rawAssets.take(100)) {
        if (raw is! Map<String, dynamic>) continue;
        final name = raw['name'];
        final url = raw['browser_download_url'];
        if (name is! String || url is! String) continue;
        final safeName = name.trim();
        if (safeName.isEmpty || safeName.length > 220) continue;
        if (!_isTrustedDownloadUrl(url)) continue;
        assets.add(UpdateAsset(name: safeName, downloadUrl: url));
      }
    }
    return UpdateRelease(
      tagName: tag,
      version: version,
      title: title,
      notes: notes,
      htmlUrl: htmlUrl,
      assets: List.unmodifiable(assets),
    );
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  static String _plainText(String value) => value
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'[\u202A-\u202E\u2066-\u2069]'), '');

  static String _requiredShortString(
    Object? raw,
    String field, {
    required int max,
  }) {
    if (raw is! String) {
      throw UpdateCheckException('Missing GitHub release field: $field.');
    }
    final value = raw.trim();
    if (value.isEmpty || value.length > max) {
      throw UpdateCheckException('Invalid GitHub release field: $field.');
    }
    return value;
  }

  static String normalizeVersion(String value) {
    var normalized = value.trim();
    if (normalized.toLowerCase().startsWith('v')) {
      normalized = normalized.substring(1);
    }
    return normalized.trim();
  }

  static List<int>? _parseVersion(String value) {
    final match = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$',
    ).firstMatch(normalizeVersion(value));
    if (match == null) return null;
    final components = [
      match.group(1),
      match.group(2),
      match.group(3),
      match.group(4) ?? '0',
    ].map((component) => int.tryParse(component!)).toList();
    if (components.any((component) => component == null)) return null;
    return components.cast<int>();
  }

  static int compareVersions(String a, String b) {
    final av = _parseVersion(a);
    final bv = _parseVersion(b);
    if (av == null || bv == null) {
      throw const UpdateCheckException('Unable to compare version numbers.');
    }
    for (var i = 0; i < 4; i++) {
      if (av[i] != bv[i]) return av[i].compareTo(bv[i]);
    }
    return 0;
  }

  static bool isTrustedReleaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host != 'github.com') {
      return false;
    }
    if (uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.hasPort && uri.port != 443)) {
      return false;
    }
    final path = uri.path.toLowerCase();
    return path == '/quisquisnaut/quisquislingo/releases' ||
        path.startsWith('/quisquisnaut/quisquislingo/releases/');
  }

  static bool _isTrustedDownloadUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return false;
    return uri.host == 'github.com' ||
        uri.host == 'objects.githubusercontent.com';
  }

  Future<bool> openRepository() => _openTrustedGitHubUrl(repositoryUrl);
  Future<bool> openReleases() => _openTrustedGitHubUrl(releasesUrl);
  Future<bool> openRelease(UpdateRelease release) =>
      _openTrustedGitHubUrl(release.htmlUrl);

  Future<bool> _openTrustedGitHubUrl(String value) async {
    if (!isTrustedReleaseUrl(value) && value != repositoryUrl) return false;
    final uri = Uri.parse(value);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  UpdateAsset? compatibleAsset(UpdateRelease release, UpdatePlatform platform) {
    for (final asset in release.assets) {
      if (_isCompatibleAsset(asset.name.toLowerCase(), platform)) return asset;
    }
    return null;
  }

  bool platformAvailable(UpdateRelease release, UpdatePlatform platform) =>
      compatibleAsset(release, platform) != null;

  static bool _isCompatibleAsset(String name, UpdatePlatform platform) {
    bool hasAny(Iterable<String> markers) =>
        markers.any((marker) => name.contains(marker));
    bool hasExtension(Iterable<String> extensions) =>
        extensions.any(name.endsWith);
    bool conflictsWith(Iterable<String> allowedMarkers) {
      const platformMarkers = <String>{
        'windows',
        'win64',
        'linux',
        'antix',
        'macos',
        'osx',
        'android',
        'ios',
        'web',
      };
      return hasAny(platformMarkers.difference(allowedMarkers.toSet()));
    }

    return switch (platform) {
      UpdatePlatform.windows =>
        !conflictsWith(const {'windows', 'win64'}) &&
            (hasAny(const {'windows', 'win64'}) ||
                hasExtension(const {'.msi', '.exe'})),
      UpdatePlatform.macos =>
        !conflictsWith(const {'macos', 'osx'}) &&
            (hasAny(const {'macos', 'osx'}) ||
                hasExtension(const {'.dmg', '.pkg'})),
      UpdatePlatform.linux =>
        !conflictsWith(const {'linux', 'antix'}) &&
            hasAny(const {'linux', 'antix'}) &&
            hasExtension(const {'.deb', '.zip', '.tar.gz', '.appimage'}),
      UpdatePlatform.android =>
        !conflictsWith(const {'android'}) &&
            (name.contains('android') || hasExtension(const {'.apk', '.aab'})),
      UpdatePlatform.ios =>
        !conflictsWith(const {'ios'}) &&
            (name.contains('ios') || name.endsWith('.ipa')),
      UpdatePlatform.web =>
        !conflictsWith(const {'web'}) &&
            name.contains('web') &&
            hasExtension(const {'.zip', '.tar.gz'}),
    };
  }
}

enum UpdatePlatform {
  windows,
  macos,
  linux,
  android,
  ios,
  web;

  static UpdatePlatform? fromOperatingSystem(String operatingSystem) =>
      switch (operatingSystem.trim().toLowerCase()) {
        'windows' => UpdatePlatform.windows,
        'macos' => UpdatePlatform.macos,
        'linux' => UpdatePlatform.linux,
        'android' => UpdatePlatform.android,
        'ios' => UpdatePlatform.ios,
        _ => null,
      };
}

class UpdateCheckException implements Exception {
  final String message;
  const UpdateCheckException(this.message);
  @override
  String toString() => message;
}
