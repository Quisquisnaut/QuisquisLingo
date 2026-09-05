import 'dart:convert';
import 'dart:math';

/// QuisquisLingo Course Model v6.
///
/// The serialized course format is formatVersion 6. Course content is stored as
/// Course > Lesson > Guidebook + Round > Content. Exercises are one Content kind
/// and are represented through Prompt + Interaction + Evaluation primitives.
///
/// A few read-only convenience getters expose the author-friendly vocabulary
/// used by the existing learner/editor widgets. They are derived from the v6
/// primitives and are not a second runtime model.

enum PublicationState {
  draft,
  published;

  static PublicationState parseRequired(
    Map<String, dynamic> json,
    String location,
  ) {
    final value = json['publicationState'];
    return switch (value) {
      'draft' => PublicationState.draft,
      'published' => PublicationState.published,
      _ => throw FormatException(
        '$location.publicationState must be draft or published.',
      ),
    };
  }

  bool get isPublished => this == PublicationState.published;
}

enum CourseOriginType {
  custom,
  bundledOfficial,
  externalOfficial;

  static CourseOriginType parse(Map<String, dynamic> json) {
    final value = json['originType'];
    if (value == null) return CourseOriginType.custom;
    return CourseOriginType.values.firstWhere(
      (origin) => origin.name == value,
      orElse: () => throw const FormatException(
        'course.originType must be custom, bundledOfficial or externalOfficial.',
      ),
    );
  }

  bool get isOfficial => this != CourseOriginType.custom;
}

enum PublisherVerificationStatus {
  verified,
  unverified;

  static PublisherVerificationStatus parse(Map<String, dynamic> json) {
    final value = json['publisherVerificationStatus'];
    if (value == null) return PublisherVerificationStatus.unverified;
    return PublisherVerificationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw const FormatException(
        'course.publisherVerificationStatus must be verified or unverified.',
      ),
    );
  }
}

enum LessonNumberingMode {
  lesson,
  unit,
  topic,
  module,
  skill,
  chapter,
  stage,
  step,
  part,
  other,
  numberOnly,
  none;

  static LessonNumberingMode parseRequired(Map<String, dynamic> json) {
    final value = json['lessonNumberingMode'];
    return LessonNumberingMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => throw const FormatException(
        'course.lessonNumberingMode is missing or invalid.',
      ),
    );
  }
}

enum LessonFallbackIconStyle {
  monochrome,
  coloredLessonNumbers;

  static LessonFallbackIconStyle parseRequired(Map<String, dynamic> json) {
    final value = json['defaultLessonIconStyle'];
    return LessonFallbackIconStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => throw const FormatException(
        'course.defaultLessonIconStyle is missing or invalid.',
      ),
    );
  }
}

class CourseLessonIconAsset {
  static const referencePrefix = 'course-assets/lesson-icons/';

  final String assetId;
  final String base64Png;

  const CourseLessonIconAsset({required this.assetId, required this.base64Png});

  String get reference => '$referencePrefix$assetId.png';

  Map<String, dynamic> toJson() => {'assetId': assetId, 'base64Png': base64Png};

  factory CourseLessonIconAsset.fromJson(Map<String, dynamic> json) {
    final assetId = _requiredString(json, 'assetId', 'lessonIconAsset');
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(assetId)) {
      throw const FormatException(
        'lessonIconAsset.assetId may contain letters, numbers, underscores and hyphens only.',
      );
    }
    final base64Png = _requiredString(json, 'base64Png', 'lessonIconAsset');
    validateCanonicalPng(base64Png);
    return CourseLessonIconAsset(assetId: assetId, base64Png: base64Png);
  }

  static bool isManagedReference(String value) => RegExp(
    r'^course-assets/lesson-icons/[A-Za-z0-9_-]+\.png$',
  ).hasMatch(value.trim());

  static String? assetIdFromReference(String value) {
    final trimmed = value.trim();
    if (!isManagedReference(trimmed)) return null;
    return trimmed.substring(referencePrefix.length, trimmed.length - 4);
  }

  static void validateCanonicalPng(String value) {
    late final List<int> bytes;
    try {
      bytes = base64Decode(value);
    } catch (_) {
      throw const FormatException(
        'lessonIconAsset.base64Png must contain valid Base64.',
      );
    }
    const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    if (bytes.length < 24) {
      throw const FormatException(
        'lessonIconAsset.base64Png must contain a valid PNG.',
      );
    }
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        throw const FormatException(
          'lessonIconAsset.base64Png must contain a valid PNG.',
        );
      }
    }
    if (String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') {
      throw const FormatException(
        'lessonIconAsset.base64Png must contain a valid PNG header.',
      );
    }
    int uint32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    if (uint32(16) != 256 || uint32(20) != 256) {
      throw const FormatException(
        'Custom Lesson icons must use a 256x256 PNG canvas.',
      );
    }
  }
}

class CourseAuthor {
  final String name;
  final List<String> roles;
  const CourseAuthor({required this.name, this.roles = const ['Contributor']});
  String get role => roles.isEmpty ? 'Contributor' : roles.join(', ');
  Map<String, dynamic> toJson() => {'name': name, 'role': role, 'roles': roles};
  factory CourseAuthor.fromJson(Map<String, dynamic> json) {
    final parsed = <String>[];
    final raw = json['roles'];
    if (raw is List) {
      for (final v in raw) {
        if (v is String && v.trim().isNotEmpty) parsed.add(v.trim());
      }
    }
    if (parsed.isEmpty) {
      final legacy = _optionalString(json, 'role', '');
      for (final p in legacy.split(',')) {
        if (p.trim().isNotEmpty) parsed.add(p.trim());
      }
    }
    return CourseAuthor(
      name: _optionalString(json, 'name', ''),
      roles: parsed.isEmpty ? const ['Contributor'] : parsed,
    );
  }
}

class Course {
  static const int currentFormatVersion = 6;
  final int formatVersion;
  final String courseId;
  final CourseOriginType originType;
  final String publisherId;
  final String publisherName;
  final String officialCourseVersion;
  final String officialReleaseDateUtc;
  final String officialChecksum;
  final String officialReleaseNotes;
  final String distributionChannel;
  final PublisherVerificationStatus publisherVerificationStatus;
  final String publisherSignature;
  final String baseCourseId;
  final String basePublisherId;
  final String baseOfficialCourseVersion;
  final String baseOfficialChecksum;
  final int localCourseVersion;
  final String localAuthorProfileId;
  final String localAuthorUsername;
  final String localModifiedAtUtc;
  final String localVersionNotes;
  final String createdByProfileId;
  final String createdByUsername;
  final String createdAtUtc;
  final String lastModifiedByProfileId;
  final String lastModifiedByUsername;
  final String lastModifiedAtUtc;
  final String versionNotes;
  final int? restoredFromVersion;
  final PublicationState publicationState;
  final LessonNumberingMode lessonNumberingMode;
  final String customLessonLabel;
  final LessonFallbackIconStyle defaultLessonIconStyle;
  final String? parentCourseId;
  final String? derivedFromVersion;
  final String learningLanguage;
  final String interfaceLanguage;
  final String sourceLanguage;
  final String targetLanguage;
  final String title;
  final String ttsLanguage;
  final String version;
  final String contentRevision;
  final String updateSummary;
  final String audioMode;
  final String author;
  final List<CourseAuthor> authors;
  final String license;
  final String languageVariant;
  final String startLevel;
  final String targetLevel;
  final String courseVersion;
  final String lastUpdated;
  final String courseDescription;
  final String sourceLanguageTag;
  final String targetLanguageTag;
  final String textDirection;
  final String flagCode;
  final String flagImageBase64;
  final bool temporarySample;
  final String buyACoffeeUrl;
  final List<CourseLessonIconAsset> lessonIconAssets;
  final List<CourseAudioClip> audioLibrary;
  final List<Lesson> lessons;

  Course({
    this.formatVersion = currentFormatVersion,
    required this.courseId,
    this.originType = CourseOriginType.custom,
    this.publisherId = '',
    this.publisherName = '',
    this.officialCourseVersion = '',
    this.officialReleaseDateUtc = '',
    this.officialChecksum = '',
    this.officialReleaseNotes = '',
    this.distributionChannel = '',
    this.publisherVerificationStatus = PublisherVerificationStatus.unverified,
    this.publisherSignature = '',
    this.baseCourseId = '',
    this.basePublisherId = '',
    this.baseOfficialCourseVersion = '',
    this.baseOfficialChecksum = '',
    this.localCourseVersion = 0,
    this.localAuthorProfileId = '',
    this.localAuthorUsername = '',
    this.localModifiedAtUtc = '',
    this.localVersionNotes = '',
    this.createdByProfileId = '',
    this.createdByUsername = '',
    this.createdAtUtc = '',
    this.lastModifiedByProfileId = '',
    this.lastModifiedByUsername = '',
    this.lastModifiedAtUtc = '',
    this.versionNotes = '',
    this.restoredFromVersion,
    this.publicationState = PublicationState.published,
    this.lessonNumberingMode = LessonNumberingMode.lesson,
    String customLessonLabel = '',
    this.defaultLessonIconStyle = LessonFallbackIconStyle.monochrome,
    this.parentCourseId,
    this.derivedFromVersion,
    required this.learningLanguage,
    required this.interfaceLanguage,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.title,
    required this.ttsLanguage,
    required this.version,
    this.contentRevision = '1',
    this.updateSummary = '',
    this.audioMode = 'tts',
    this.author = '',
    this.authors = const [],
    this.license = 'All rights reserved',
    this.languageVariant = '',
    this.startLevel = '',
    this.targetLevel = '',
    this.courseVersion = '',
    this.lastUpdated = '',
    this.courseDescription = '',
    this.sourceLanguageTag = '',
    this.targetLanguageTag = '',
    this.textDirection = 'ltr',
    this.flagCode = '',
    this.flagImageBase64 = '',
    this.temporarySample = false,
    String buyACoffeeUrl = '',
    this.lessonIconAssets = const [],
    this.audioLibrary = const [],
    required this.lessons,
  }) : customLessonLabel = customLessonLabel.trim(),
       buyACoffeeUrl = normalizeBuyACoffeeUrl(buyACoffeeUrl) {
    if (lessonNumberingMode == LessonNumberingMode.other &&
        this.customLessonLabel.isEmpty) {
      throw const FormatException(
        'A non-empty custom Lesson label is required for Other.',
      );
    }
    if (originType.isOfficial &&
        (publisherId.trim().isEmpty ||
            publisherName.trim().isEmpty ||
            officialCourseVersion.trim().isEmpty ||
            officialReleaseDateUtc.trim().isEmpty ||
            officialChecksum.trim().isEmpty ||
            distributionChannel.trim().isEmpty)) {
      throw const FormatException(
        'Official courses require publisher, official version, release date, checksum and distribution channel provenance.',
      );
    }
    for (final timestamp in {
      'officialReleaseDateUtc': officialReleaseDateUtc,
      'createdAtUtc': createdAtUtc,
      'lastModifiedAtUtc': lastModifiedAtUtc,
      'localModifiedAtUtc': localModifiedAtUtc,
    }.entries) {
      if (timestamp.value.isEmpty) continue;
      final parsed = DateTime.tryParse(timestamp.value);
      if (!timestamp.value.endsWith('Z') || parsed == null || !parsed.isUtc) {
        throw FormatException(
          'course.${timestamp.key} must be an ISO 8601 UTC timestamp ending in Z.',
        );
      }
    }
    if (originType.isOfficial &&
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(officialChecksum)) {
      throw const FormatException(
        'course.officialChecksum must be a lowercase SHA-256 value.',
      );
    }
    if (localCourseVersion < 0) {
      throw const FormatException(
        'course.localCourseVersion cannot be negative.',
      );
    }
  }

  static String normalizeBuyACoffeeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty) {
      throw const FormatException(
        'Buy a Coffee URL must be a valid HTTPS URL.',
      );
    }
    return trimmed;
  }

  Map<String, dynamic> toJson() => {
    'formatVersion': currentFormatVersion,
    'publicationState': publicationState.name,
    'lessonNumberingMode': lessonNumberingMode.name,
    if (lessonNumberingMode == LessonNumberingMode.other)
      'customLessonLabel': customLessonLabel,
    'defaultLessonIconStyle': defaultLessonIconStyle.name,
    'courseId': courseId,
    'originType': originType.name,
    if (publisherId.isNotEmpty) 'publisherId': publisherId,
    if (publisherName.isNotEmpty) 'publisherName': publisherName,
    if (officialCourseVersion.isNotEmpty)
      'officialCourseVersion': officialCourseVersion,
    if (officialReleaseDateUtc.isNotEmpty)
      'officialReleaseDateUtc': officialReleaseDateUtc,
    if (officialChecksum.isNotEmpty) 'officialChecksum': officialChecksum,
    if (officialReleaseNotes.isNotEmpty)
      'officialReleaseNotes': officialReleaseNotes,
    if (distributionChannel.isNotEmpty)
      'distributionChannel': distributionChannel,
    if (originType.isOfficial)
      'publisherVerificationStatus': publisherVerificationStatus.name,
    if (publisherSignature.isNotEmpty) 'publisherSignature': publisherSignature,
    if (baseCourseId.isNotEmpty) 'baseCourseId': baseCourseId,
    if (basePublisherId.isNotEmpty) 'basePublisherId': basePublisherId,
    if (baseOfficialCourseVersion.isNotEmpty)
      'baseOfficialCourseVersion': baseOfficialCourseVersion,
    if (baseOfficialChecksum.isNotEmpty)
      'baseOfficialChecksum': baseOfficialChecksum,
    if (localCourseVersion > 0) 'localCourseVersion': localCourseVersion,
    if (localAuthorProfileId.isNotEmpty)
      'localAuthorProfileId': localAuthorProfileId,
    if (localAuthorUsername.isNotEmpty)
      'localAuthorUsername': localAuthorUsername,
    if (localModifiedAtUtc.isNotEmpty) 'localModifiedAtUtc': localModifiedAtUtc,
    if (localVersionNotes.isNotEmpty) 'localVersionNotes': localVersionNotes,
    if (createdByProfileId.isNotEmpty) 'createdByProfileId': createdByProfileId,
    if (createdByUsername.isNotEmpty) 'createdByUsername': createdByUsername,
    if (createdAtUtc.isNotEmpty) 'createdAtUtc': createdAtUtc,
    if (lastModifiedByProfileId.isNotEmpty)
      'lastModifiedByProfileId': lastModifiedByProfileId,
    if (lastModifiedByUsername.isNotEmpty)
      'lastModifiedByUsername': lastModifiedByUsername,
    if (lastModifiedAtUtc.isNotEmpty) 'lastModifiedAtUtc': lastModifiedAtUtc,
    if (versionNotes.isNotEmpty) 'versionNotes': versionNotes,
    if (restoredFromVersion != null) 'restoredFromVersion': restoredFromVersion,
    if (parentCourseId?.isNotEmpty == true) 'parentCourseId': parentCourseId,
    if (derivedFromVersion?.isNotEmpty == true)
      'derivedFromVersion': derivedFromVersion,
    'learningLanguage': learningLanguage,
    'interfaceLanguage': interfaceLanguage,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'title': title,
    'ttsLanguage': ttsLanguage,
    'version': version,
    'contentRevision': contentRevision,
    'updateSummary': updateSummary,
    'audioMode': audioMode,
    if (author.isNotEmpty) 'author': author,
    if (authors.isNotEmpty) 'authors': authors.map((e) => e.toJson()).toList(),
    'license': license,
    if (languageVariant.isNotEmpty) 'languageVariant': languageVariant,
    if (startLevel.isNotEmpty) 'startLevel': startLevel,
    if (targetLevel.isNotEmpty) 'targetLevel': targetLevel,
    if (courseVersion.isNotEmpty) 'courseVersion': courseVersion,
    if (lastUpdated.isNotEmpty) 'lastUpdated': lastUpdated,
    if (courseDescription.isNotEmpty) 'courseDescription': courseDescription,
    if (sourceLanguageTag.isNotEmpty) 'sourceLanguageTag': sourceLanguageTag,
    if (targetLanguageTag.isNotEmpty) 'targetLanguageTag': targetLanguageTag,
    'textDirection': textDirection,
    if (flagCode.isNotEmpty) 'flagCode': flagCode,
    if (flagImageBase64.isNotEmpty) 'flagImageBase64': flagImageBase64,
    'temporarySample': temporarySample,
    if (buyACoffeeUrl.isNotEmpty) 'buyACoffeeUrl': buyACoffeeUrl,
    if (lessonIconAssets.isNotEmpty)
      'lessonIconAssets': lessonIconAssets.map((e) => e.toJson()).toList(),
    if (audioLibrary.isNotEmpty)
      'audioLibrary': audioLibrary.map((e) => e.toJson()).toList(),
    'lessons': lessons.map((e) => e.toJson()).toList(),
  };

  factory Course.fromJson(Map<String, dynamic> json) {
    final fv = json['formatVersion'];
    if (fv != currentFormatVersion) {
      throw FormatException(
        'Unsupported course formatVersion: $fv. This version of QuisquisLingo supports Course Model formatVersion 6 only. Older course formats are not migrated or partially loaded.',
      );
    }
    if (json.containsKey('topics')) {
      throw const FormatException(
        'Course Model formatVersion 6 does not support the legacy topics field.',
      );
    }
    if (json.containsKey('chapters')) {
      throw const FormatException(
        'Course Model formatVersion 6 does not support chapters.',
      );
    }
    if (json.containsKey('supportUrl')) {
      throw const FormatException(
        'Course Model formatVersion 6 uses buyACoffeeUrl, not supportUrl.',
      );
    }
    if (json.containsKey('buyACoffeeUrl') && json['buyACoffeeUrl'] is! String) {
      throw const FormatException('course.buyACoffeeUrl must be a string.');
    }
    final learning = _requiredString(json, 'learningLanguage', 'course');
    final interface = _requiredString(json, 'interfaceLanguage', 'course');
    return Course(
      formatVersion: currentFormatVersion,
      courseId: _requiredString(json, 'courseId', 'course'),
      originType: CourseOriginType.parse(json),
      publisherId: _optionalString(json, 'publisherId', ''),
      publisherName: _optionalString(json, 'publisherName', ''),
      officialCourseVersion: _optionalString(json, 'officialCourseVersion', ''),
      officialReleaseDateUtc: _optionalString(
        json,
        'officialReleaseDateUtc',
        '',
      ),
      officialChecksum: _optionalString(json, 'officialChecksum', ''),
      officialReleaseNotes: _optionalString(json, 'officialReleaseNotes', ''),
      distributionChannel: _optionalString(json, 'distributionChannel', ''),
      publisherVerificationStatus: PublisherVerificationStatus.parse(json),
      publisherSignature: _optionalString(json, 'publisherSignature', ''),
      baseCourseId: _optionalString(json, 'baseCourseId', ''),
      basePublisherId: _optionalString(json, 'basePublisherId', ''),
      baseOfficialCourseVersion: _optionalString(
        json,
        'baseOfficialCourseVersion',
        '',
      ),
      baseOfficialChecksum: _optionalString(json, 'baseOfficialChecksum', ''),
      localCourseVersion: _optionalInt(json, 'localCourseVersion', 0),
      localAuthorProfileId: _optionalString(json, 'localAuthorProfileId', ''),
      localAuthorUsername: _optionalString(json, 'localAuthorUsername', ''),
      localModifiedAtUtc: _optionalString(json, 'localModifiedAtUtc', ''),
      localVersionNotes: _optionalString(json, 'localVersionNotes', ''),
      createdByProfileId: _optionalString(json, 'createdByProfileId', ''),
      createdByUsername: _optionalString(json, 'createdByUsername', ''),
      createdAtUtc: _optionalString(json, 'createdAtUtc', ''),
      lastModifiedByProfileId: _optionalString(
        json,
        'lastModifiedByProfileId',
        '',
      ),
      lastModifiedByUsername: _optionalString(
        json,
        'lastModifiedByUsername',
        '',
      ),
      lastModifiedAtUtc: _optionalString(json, 'lastModifiedAtUtc', ''),
      versionNotes: _optionalString(json, 'versionNotes', ''),
      restoredFromVersion: json['restoredFromVersion'] is int
          ? json['restoredFromVersion'] as int
          : null,
      publicationState: PublicationState.parseRequired(json, 'course'),
      lessonNumberingMode: LessonNumberingMode.parseRequired(json),
      customLessonLabel: _optionalString(json, 'customLessonLabel', ''),
      defaultLessonIconStyle: LessonFallbackIconStyle.parseRequired(json),
      parentCourseId: _optionalString(json, 'parentCourseId', '').isEmpty
          ? null
          : _optionalString(json, 'parentCourseId', ''),
      derivedFromVersion:
          _optionalString(json, 'derivedFromVersion', '').isEmpty
          ? null
          : _optionalString(json, 'derivedFromVersion', ''),
      learningLanguage: learning,
      interfaceLanguage: interface,
      sourceLanguage: _optionalString(json, 'sourceLanguage', interface),
      targetLanguage: _optionalString(json, 'targetLanguage', learning),
      title: _requiredString(json, 'title', 'course'),
      ttsLanguage: _requiredString(json, 'ttsLanguage', 'course'),
      version: _optionalString(json, 'version', '1.0.0'),
      contentRevision: _optionalString(json, 'contentRevision', '1'),
      updateSummary: _optionalString(json, 'updateSummary', ''),
      audioMode: const {'tts', 'recorded', 'hybrid'}.contains(json['audioMode'])
          ? json['audioMode'] as String
          : 'tts',
      author: _optionalString(json, 'author', ''),
      authors: (json['authors'] is List)
          ? (json['authors'] as List)
                .whereType<Map>()
                .map((e) => CourseAuthor.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      license: _optionalString(json, 'license', 'All rights reserved'),
      languageVariant: _optionalString(json, 'languageVariant', ''),
      startLevel: _optionalString(json, 'startLevel', ''),
      targetLevel: _optionalString(json, 'targetLevel', ''),
      courseVersion: _optionalString(json, 'courseVersion', ''),
      lastUpdated: _optionalString(json, 'lastUpdated', ''),
      courseDescription: _optionalString(json, 'courseDescription', ''),
      sourceLanguageTag: _optionalString(json, 'sourceLanguageTag', ''),
      targetLanguageTag: _optionalString(json, 'targetLanguageTag', ''),
      textDirection: _optionalString(json, 'textDirection', 'ltr'),
      flagCode: _optionalString(json, 'flagCode', ''),
      flagImageBase64: _optionalString(json, 'flagImageBase64', ''),
      temporarySample: json['temporarySample'] == true,
      buyACoffeeUrl: _optionalString(json, 'buyACoffeeUrl', ''),
      lessonIconAssets: (json['lessonIconAssets'] is List)
          ? (json['lessonIconAssets'] as List).map((entry) {
              if (entry is! Map) {
                throw const FormatException(
                  'course.lessonIconAssets entries must be objects.',
                );
              }
              return CourseLessonIconAsset.fromJson(
                Map<String, dynamic>.from(entry),
              );
            }).toList()
          : json.containsKey('lessonIconAssets')
          ? throw const FormatException(
              'course.lessonIconAssets must be a list.',
            )
          : const [],
      audioLibrary: (json['audioLibrary'] is List)
          ? (json['audioLibrary'] as List)
                .whereType<Map>()
                .map(
                  (e) => CourseAudioClip.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      lessons: _parseLessons(json),
    );
  }

  /// Creates an immutable, globally unique identity for a new course or fork.
  static String newCourseId() {
    final random = Random.secure();
    String hex(int length) => List<String>.generate(
      length,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'course_${hex(8)}-${hex(4)}-4${hex(3)}-${(8 + random.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
  }

  Course fork() {
    final json = Map<String, dynamic>.from(toJson())
      ..['courseId'] = newCourseId()
      ..['originType'] = CourseOriginType.custom.name
      ..['publicationState'] = PublicationState.draft.name
      ..['parentCourseId'] = courseId
      ..['derivedFromVersion'] = originType.isOfficial
          ? officialCourseVersion
          : courseVersion
      ..['courseVersion'] = '';
    for (final key in const [
      'publisherId',
      'publisherName',
      'officialCourseVersion',
      'officialReleaseDateUtc',
      'officialChecksum',
      'officialReleaseNotes',
      'distributionChannel',
      'publisherVerificationStatus',
      'publisherSignature',
      'baseCourseId',
      'basePublisherId',
      'baseOfficialCourseVersion',
      'baseOfficialChecksum',
      'localCourseVersion',
      'localAuthorProfileId',
      'localAuthorUsername',
      'localModifiedAtUtc',
      'localVersionNotes',
      'createdByProfileId',
      'createdByUsername',
      'createdAtUtc',
      'lastModifiedByProfileId',
      'lastModifiedByUsername',
      'lastModifiedAtUtc',
      'versionNotes',
      'restoredFromVersion',
    ]) {
      json.remove(key);
    }
    return Course.fromJson(json);
  }
}

class CourseAudioClip {
  final String id;
  final String text;
  final String filePath;
  const CourseAudioClip({
    required this.id,
    required this.text,
    required this.filePath,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'filePath': filePath,
  };
  factory CourseAudioClip.fromJson(Map<String, dynamic> j) => CourseAudioClip(
    id: _requiredString(j, 'id', 'audio clip'),
    text: _optionalString(j, 'text', ''),
    filePath: _requiredString(j, 'filePath', 'audio clip'),
  );
}

List<Lesson> _parseLessons(Map<String, dynamic> j) {
  final raw = j['lessons'];
  if (raw is! List) {
    throw const FormatException('course.lessons must be a list.');
  }
  return [
    for (final value in raw)
      if (value is Map)
        Lesson.fromJson(Map<String, dynamic>.from(value))
      else
        throw const FormatException(
          'course.lessons contains a non-object value.',
        ),
  ];
}

class Guidebook {
  final List<LearningContent> content;
  Guidebook({
    List<LearningContent>? content,
    String overview = '',
    List<String> goals = const [],
    List<String> vocabulary = const [],
    List<String> grammar = const [],
    List<String> expressions = const [],
    List<String> examples = const [],
  }) : content =
           content ??
           _legacyGuidebookContent(
             overview,
             goals,
             vocabulary,
             grammar,
             expressions,
             examples,
           );
  factory Guidebook.empty() => Guidebook(content: const []);
  Map<String, dynamic> toJson() => {
    'content': content.map((e) => e.toJson()).toList(),
  };
  factory Guidebook.fromJson(Map<String, dynamic> j) => Guidebook(
    content: _mapList(j, 'content', 'guidebook', LearningContent.fromJson),
  );

  // Friendly compatibility views used by the existing authoring generator.
  String get overview => content
      .where((c) => c.kind == 'explanation' && c.role == 'overview')
      .map((c) => c.text)
      .join('\n');
  List<String> get goals => content
      .where((c) => c.kind == 'text' && c.role == 'goal')
      .map((c) => c.text)
      .toList();
  List<String> get vocabulary =>
      content.where((c) => c.kind == 'vocabulary').map((c) => c.text).toList();
  List<String> get grammar => content
      .where((c) => c.kind == 'explanation' && c.role == 'grammar')
      .map((c) => c.text)
      .toList();
  List<String> get expressions => content
      .where((c) => c.kind == 'example' && c.role == 'expression')
      .map((c) => c.text)
      .toList();
  List<String> get examples => content
      .where((c) => c.kind == 'example' && c.role != 'expression')
      .map((c) => c.text)
      .toList();
}

List<LearningContent> _legacyGuidebookContent(
  String overview,
  List<String> goals,
  List<String> vocabulary,
  List<String> grammar,
  List<String> expressions,
  List<String> examples,
) {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  var n = 0;
  String id(String role) => 'guide_${stamp}_${role}_${n++}';
  return [
    if (overview.trim().isNotEmpty)
      LearningContent.textual(
        id: id('overview'),
        kind: 'explanation',
        role: 'overview',
        text: overview,
      ),
    for (final v in goals)
      LearningContent.textual(
        id: id('goal'),
        kind: 'text',
        role: 'goal',
        text: v,
      ),
    for (final v in vocabulary)
      LearningContent.textual(
        id: id('vocab'),
        kind: 'vocabulary',
        role: 'vocabulary',
        text: v,
      ),
    for (final v in grammar)
      LearningContent.textual(
        id: id('grammar'),
        kind: 'explanation',
        role: 'grammar',
        text: v,
      ),
    for (final v in expressions)
      LearningContent.textual(
        id: id('expression'),
        kind: 'example',
        role: 'expression',
        text: v,
      ),
    for (final v in examples)
      LearningContent.textual(
        id: id('example'),
        kind: 'example',
        role: 'example',
        text: v,
      ),
  ];
}

class Lesson {
  final String lessonId;
  final PublicationState publicationState;
  final DateTime updatedAt;
  final String title;
  final List<LearningRound> rounds;
  final bool section;
  final String? sectionName;
  final String? themeIconAsset;
  final Guidebook guidebook;
  final Duel duel;
  Lesson({
    required this.lessonId,
    this.publicationState = PublicationState.published,
    DateTime? updatedAt,
    required this.title,
    required this.rounds,
    this.section = false,
    String? sectionName,
    String? themeIconAsset,
    Guidebook? guidebook,
    Duel? duel,
  }) : updatedAt = _canonicalUtcTimestamp(updatedAt),
       sectionName = section ? sectionName?.trim() : null,
       themeIconAsset = themeIconAsset?.trim().isEmpty == true
           ? null
           : themeIconAsset?.trim(),
       guidebook = guidebook ?? Guidebook.empty(),
       duel = duel ?? Duel(id: '${lessonId}_duel', title: 'Duel') {
    if (section && (this.sectionName == null || this.sectionName!.isEmpty)) {
      throw ArgumentError.value(
        sectionName,
        'sectionName',
        'Section name is required when section is true.',
      );
    }
    if (!section && sectionName?.trim().isNotEmpty == true) {
      throw ArgumentError.value(
        sectionName,
        'sectionName',
        'Section name must be absent when section is false.',
      );
    }
  }
  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'publicationState': publicationState.name,
    'updatedAt': _timestampToJson(updatedAt),
    'title': title,
    'section': section,
    if (section) 'sectionName': sectionName,
    if (themeIconAsset != null) 'themeIconAsset': themeIconAsset,
    'guidebook': guidebook.toJson(),
    'rounds': rounds.map((e) => e.toJson()).toList(),
    'duel': duel.toJson(),
  };
  factory Lesson.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('id') || j.containsKey('topicId')) {
      throw const FormatException(
        'Course Model formatVersion 6 Lessons require lessonId and reject legacy Lesson identity fields.',
      );
    }
    if (j.containsKey('role') || j.containsKey('assessment')) {
      throw const FormatException(
        'Course Model formatVersion 6 Lessons do not support role or assessment fields.',
      );
    }
    final rawGuidebook = j['guidebook'];
    if (rawGuidebook is! Map) {
      throw const FormatException('lesson.guidebook must be an object.');
    }
    final rawDuel = j['duel'];
    if (rawDuel is! Map) {
      throw const FormatException('lesson.duel must be an object.');
    }
    final section = j['section'] == true;
    final sectionName = _optionalString(j, 'sectionName', '').trim();
    if (j.containsKey('section') && j['section'] is! bool) {
      throw const FormatException('lesson.section must be a boolean.');
    }
    if (j.containsKey('imageAsset')) {
      throw const FormatException(
        'Course Model formatVersion 6 Lessons do not support the obsolete imageAsset field.',
      );
    }
    if (j.containsKey('sectionName') &&
        j['sectionName'] != null &&
        j['sectionName'] is! String) {
      throw const FormatException('lesson.sectionName must be a string.');
    }
    if (section && sectionName.isEmpty) {
      throw const FormatException(
        'lesson.sectionName must be non-empty when lesson.section is true.',
      );
    }
    if (!section && sectionName.isNotEmpty) {
      throw const FormatException(
        'lesson.sectionName must be absent when lesson.section is false.',
      );
    }
    final themeIconAsset = _optionalString(j, 'themeIconAsset', '').trim();
    if (j.containsKey('themeIconAsset') &&
        j['themeIconAsset'] != null &&
        j['themeIconAsset'] is! String) {
      throw const FormatException('lesson.themeIconAsset must be a string.');
    }
    if (themeIconAsset.isNotEmpty &&
        !CourseLessonIconAsset.isManagedReference(themeIconAsset) &&
        (!themeIconAsset.startsWith('assets/lesson_icons/') ||
            !themeIconAsset.toLowerCase().endsWith('.png'))) {
      throw const FormatException(
        'lesson.themeIconAsset must reference a preinstalled or managed Course-owned Lesson icon.',
      );
    }
    return Lesson(
      lessonId: _requiredString(j, 'lessonId', 'lesson'),
      publicationState: PublicationState.parseRequired(j, 'lesson'),
      updatedAt: _requiredUtcTimestamp(j, 'updatedAt', 'lesson'),
      title: _requiredString(j, 'title', 'lesson'),
      rounds: _mapList(j, 'rounds', 'lesson', LearningRound.fromJson),
      section: section,
      sectionName: sectionName.isEmpty ? null : sectionName,
      themeIconAsset: themeIconAsset.isEmpty ? null : themeIconAsset,
      guidebook: Guidebook.fromJson(Map<String, dynamic>.from(rawGuidebook)),
      duel: Duel.fromJson(Map<String, dynamic>.from(rawDuel)),
    );
  }
}

class LearningRound {
  static const validVisualTypes = {'listening', 'story', 'generic', 'test'};
  final String id;
  final PublicationState publicationState;
  final DateTime updatedAt;
  final String title;
  final String visualType;
  final List<LearningContent> content;
  LearningRound({
    required this.id,
    this.publicationState = PublicationState.published,
    DateTime? updatedAt,
    required this.title,
    this.visualType = 'generic',
    List<LearningContent>? content,
    List<Exercise>? exercises,
  }) : updatedAt = _canonicalUtcTimestamp(updatedAt),
       content =
           content ??
           [
             for (final e in exercises ?? const <Exercise>[])
               LearningContent.fromExercise(e),
           ];
  Map<String, dynamic> toJson() => {
    'id': id,
    'publicationState': publicationState.name,
    'updatedAt': _timestampToJson(updatedAt),
    if (title.trim().isNotEmpty) 'title': title.trim(),
    'visualType': visualType,
    'content': content.map((e) => e.toJson()).toList(),
  };
  factory LearningRound.fromJson(Map<String, dynamic> j) {
    final visualType = j['visualType'];
    if (visualType is! String || !validVisualTypes.contains(visualType)) {
      throw FormatException(
        'round.visualType must be one of ${validVisualTypes.join(', ')}.',
      );
    }
    return LearningRound(
      id: _requiredString(j, 'id', 'round'),
      publicationState: PublicationState.parseRequired(j, 'round'),
      updatedAt: _requiredUtcTimestamp(j, 'updatedAt', 'round'),
      title: _optionalString(j, 'title', ''),
      visualType: visualType,
      content: _mapList(j, 'content', 'round', LearningContent.fromJson),
    );
  }

  /// Current learner/editor widgets consume this derived runnable view. It is
  /// generated from v6 Content and therefore does not preserve a legacy file model.
  List<Exercise> get exercises => content
      .where((c) => c.role != 'lesson_intro')
      .map((c) => c.asRunnableExercise())
      .whereType<Exercise>()
      .toList(growable: false);

  String displayTitle(int position) {
    final custom = title.trim();
    return custom.isEmpty ? 'Round ${position + 1}' : custom;
  }
}

class LearningContent {
  final String id;
  final PublicationState publicationState;
  final String kind;
  final bool required;
  final String editorTemplate;
  final String role;
  final Exercise? exercise;
  final Presentation? presentation;
  final String text;
  final List<String> sourceRefs;
  const LearningContent({
    required this.id,
    this.publicationState = PublicationState.published,
    required this.kind,
    this.required = true,
    this.editorTemplate = '',
    this.role = '',
    this.exercise,
    this.presentation,
    this.text = '',
    this.sourceRefs = const [],
  });
  factory LearningContent.fromExercise(Exercise e) {
    if (e.editorTemplate == 'flashcard') {
      return LearningContent(
        id: e.id,
        publicationState: e.publicationState,
        kind: 'presentation',
        editorTemplate: 'flashcard',
        presentation: Presentation.fromLegacyExercise(e),
      );
    }
    if (const {
      'explanation',
      'example',
      'vocabulary',
      'text',
      'dialogue',
    }.contains(e.editorTemplate)) {
      return LearningContent.textual(
        id: e.id,
        publicationState: e.publicationState,
        kind: e.editorTemplate,
        role: 'round_note',
        text: e.prompt.isNotEmpty ? e.prompt : e.question,
        required: true,
      );
    }
    return LearningContent(
      id: e.id,
      publicationState: e.publicationState,
      kind: 'exercise',
      editorTemplate: e.editorTemplate,
      exercise: e,
    );
  }
  factory LearningContent.textual({
    required String id,
    required String kind,
    required String role,
    required String text,
    bool required = false,
    PublicationState publicationState = PublicationState.published,
  }) => LearningContent(
    id: id,
    publicationState: publicationState,
    kind: kind,
    role: role,
    text: text,
    required: required,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'publicationState': publicationState.name,
    'kind': kind,
    'required': required,
    if (editorTemplate.isNotEmpty) 'editorTemplate': editorTemplate,
    if (role.isNotEmpty) 'role': role,
    if (sourceRefs.isNotEmpty) 'sourceRefs': sourceRefs,
    if (exercise != null) 'exercise': exercise!.toV2Json(),
    if (presentation != null) 'presentation': presentation!.toJson(),
    if (text.isNotEmpty) 'text': text,
  };
  factory LearningContent.fromJson(Map<String, dynamic> j) {
    final kind = _requiredString(j, 'kind', 'content');
    final publicationState = PublicationState.parseRequired(j, 'content');
    final ex = j['exercise'];
    final p = j['presentation'];
    return LearningContent(
      id: _requiredString(j, 'id', 'content'),
      publicationState: publicationState,
      kind: kind,
      required: j['required'] != false,
      editorTemplate: _optionalString(j, 'editorTemplate', ''),
      role: _optionalString(j, 'role', ''),
      exercise: ex is Map
          ? Exercise.fromV2Json(
              Map<String, dynamic>.from(ex),
              contentId: _requiredString(j, 'id', 'content'),
              editorTemplate: _optionalString(j, 'editorTemplate', ''),
              publicationState: publicationState,
            )
          : null,
      presentation: p is Map
          ? Presentation.fromJson(Map<String, dynamic>.from(p))
          : null,
      text: _optionalString(j, 'text', ''),
      sourceRefs: _stringList(j, 'sourceRefs'),
    );
  }
  Exercise? asRunnableExercise() {
    if (kind == 'exercise') return exercise;
    if (kind == 'presentation' && presentation != null) {
      return presentation!.asLegacyExercise(
        id: id,
        template: editorTemplate.isEmpty ? 'flashcard' : editorTemplate,
        publicationState: publicationState,
      );
    }
    // Non-evaluated textual learning material is displayed through the existing
    // presentation card path until dedicated v2 renderers are added.
    if (const {
          'explanation',
          'example',
          'vocabulary',
          'text',
          'dialogue',
        }.contains(kind) &&
        text.isNotEmpty) {
      return Exercise.presentation(
        id: id,
        editorTemplate: editorTemplate.isEmpty ? kind : editorTemplate,
        term: text,
        meaning: '',
        publicationState: publicationState,
      );
    }
    return null;
  }
}

class Presentation {
  final List<PromptElement> content;
  final List<String> actions;
  const Presentation({
    required this.content,
    this.actions = const ['understood', 'review_later'],
  });
  Map<String, dynamic> toJson() => {
    'content': content.map((e) => e.toJson()).toList(),
    'completion': {'actions': actions},
  };
  factory Presentation.fromJson(Map<String, dynamic> j) {
    final comp = j['completion'];
    return Presentation(
      content: _mapList(j, 'content', 'presentation', PromptElement.fromJson),
      actions: comp is Map
          ? _stringList(Map<String, dynamic>.from(comp), 'actions')
          : const ['understood', 'review_later'],
    );
  }
  factory Presentation.fromLegacyExercise(Exercise e) => Presentation(
    content: [
      if (e.prompt.isNotEmpty)
        PromptElement(role: 'term', type: 'text', text: e.prompt),
      if (e.tts?.isNotEmpty == true)
        PromptElement(role: 'audio', type: 'audio', text: e.tts!),
      if (e.question.isNotEmpty)
        PromptElement(role: 'meaning', type: 'text', text: e.question),
      if (e.answers.isNotEmpty)
        PromptElement(role: 'usage', type: 'text', text: e.answers.first),
      if (e.answers.length > 1)
        PromptElement(
          role: 'usage_translation',
          type: 'text',
          text: e.answers[1],
        ),
    ],
  );
  Exercise asLegacyExercise({
    required String id,
    required String template,
    PublicationState publicationState = PublicationState.published,
  }) {
    String first(String role) =>
        content.where((e) => e.role == role).map((e) => e.text).firstOrNull ??
        '';
    final usage = first('usage');
    final usageTr = first('usage_translation');
    return Exercise(
      id: id,
      publicationState: publicationState,
      type: 'flashcard',
      editorTemplate: template,
      prompt: first('term'),
      question: first('meaning'),
      answers: [if (usage.isNotEmpty) usage, if (usageTr.isNotEmpty) usageTr],
      correct: null,
      tts: first('audio').isEmpty ? null : first('audio'),
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
  }
}

class PromptElement {
  final String role;
  final String type;
  final String text;
  final String asset;
  final String speaker;
  const PromptElement({
    this.role = 'primary',
    required this.type,
    this.text = '',
    this.asset = '',
    this.speaker = '',
  });
  Map<String, dynamic> toJson() => {
    'role': role,
    'type': type,
    if (text.isNotEmpty) 'text': text,
    if (asset.isNotEmpty) 'asset': asset,
    if (speaker.isNotEmpty) 'speaker': speaker,
  };
  factory PromptElement.fromJson(Map<String, dynamic> j) => PromptElement(
    role: _optionalString(j, 'role', 'primary'),
    type: _requiredString(j, 'type', 'prompt'),
    text: _optionalString(j, 'text', ''),
    asset: _optionalString(j, 'asset', ''),
    speaker: _optionalString(j, 'speaker', ''),
  );
}

class ExerciseItem {
  final String id;
  final List<PromptElement> content;
  const ExerciseItem({required this.id, required this.content});
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content.map((e) => e.toJson()).toList(),
  };
  factory ExerciseItem.fromJson(Map<String, dynamic> j) => ExerciseItem(
    id: _requiredString(j, 'id', 'item'),
    content: _mapList(j, 'content', 'item', PromptElement.fromJson),
  );
  String get text =>
      content.where((e) => e.type == 'text').map((e) => e.text).firstOrNull ??
      '';
  String get audio =>
      content.where((e) => e.type == 'audio').map((e) => e.text).firstOrNull ??
      '';
  String get image =>
      content.where((e) => e.type == 'image').map((e) => e.asset).firstOrNull ??
      '';
  String get value => text.isNotEmpty
      ? text
      : audio.isNotEmpty
      ? audio
      : image;
}

class ExerciseInteraction {
  final String kind;
  final String inputType;
  final int minSelections;
  final int maxSelections;
  final List<ExerciseItem> items;
  const ExerciseInteraction({
    required this.kind,
    this.inputType = 'text',
    this.minSelections = 1,
    this.maxSelections = 1,
    this.items = const [],
  });
  Map<String, dynamic> toJson() => {
    'kind': kind,
    if (kind == 'input') 'inputType': inputType,
    if (kind == 'select') 'minSelections': minSelections,
    if (kind == 'select') 'maxSelections': maxSelections,
    if (items.isNotEmpty) 'items': items.map((e) => e.toJson()).toList(),
  };
  factory ExerciseInteraction.fromJson(Map<String, dynamic> j) =>
      ExerciseInteraction(
        kind: _requiredString(j, 'kind', 'interaction'),
        inputType: _optionalString(j, 'inputType', 'text'),
        minSelections: _optionalInt(j, 'minSelections', 1),
        maxSelections: _optionalInt(j, 'maxSelections', 1),
        items: (j['items'] is List)
            ? _mapList(j, 'items', 'interaction', ExerciseItem.fromJson)
            : const [],
      );
}

class OrderedAnswer {
  final String text;
  final List<String> itemIds;

  const OrderedAnswer({required this.text, required this.itemIds});

  Map<String, dynamic> toJson() => {'text': text, 'itemIds': itemIds};

  factory OrderedAnswer.fromJson(Map<String, dynamic> json) {
    return OrderedAnswer(
      text: _requiredString(json, 'text', 'ordered answer'),
      itemIds: _stringList(json, 'itemIds'),
    );
  }
}

class ExerciseEvaluation {
  final String kind;
  final List<String> correctItemIds;
  final List<String> accepted;
  final List<OrderedAnswer> correctOrders;
  final List<List<String>> pairs;
  final Map<String, dynamic> normalization;
  const ExerciseEvaluation({
    required this.kind,
    this.correctItemIds = const [],
    this.accepted = const [],
    this.correctOrders = const [],
    this.pairs = const [],
    this.normalization = const {},
  });
  Map<String, dynamic> toJson() => {
    'kind': kind,
    if (correctItemIds.isNotEmpty) 'correctItemIds': correctItemIds,
    if (accepted.isNotEmpty) 'acceptedAnswers': accepted,
    if (correctOrders.isNotEmpty)
      'correctOrders': correctOrders.map((answer) => answer.toJson()).toList(),
    if (pairs.isNotEmpty) 'pairs': pairs,
    if (normalization.isNotEmpty) 'normalization': normalization,
  };
  factory ExerciseEvaluation.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('accepted')) {
      throw const FormatException(
        'Course Model formatVersion 6 uses acceptedAnswers and does not load the legacy accepted field.',
      );
    }
    if (j.containsKey('correctOrder')) {
      throw const FormatException(
        'Course Model formatVersion 6 requires correctOrders and does not load the legacy single correctOrder field.',
      );
    }
    if (j.containsKey('caseSensitive') ||
        j.containsKey('ignorePunctuation') ||
        j.containsKey('ignoreAccents')) {
      throw const FormatException(
        'Course Model formatVersion 6 requires the normalization object and does not load legacy normalization flags.',
      );
    }
    final normalization = j['normalization'] is Map
        ? Map<String, dynamic>.from(j['normalization'] as Map)
        : <String, dynamic>{};
    return ExerciseEvaluation(
      kind: _requiredString(j, 'kind', 'evaluation'),
      correctItemIds: _stringList(j, 'correctItemIds'),
      accepted: _stringList(j, 'acceptedAnswers'),
      correctOrders: j['correctOrders'] == null
          ? const []
          : _mapList(j, 'correctOrders', 'evaluation', OrderedAnswer.fromJson),
      pairs: _pairList(j, 'pairs'),
      normalization: normalization,
    );
  }
}

class Exercise {
  final String id;
  final PublicationState publicationState;
  final DateTime updatedAt;
  final String editorTemplate;
  final List<PromptElement> promptElements;
  final ExerciseInteraction interaction;
  final ExerciseEvaluation evaluation;
  final String hint;
  final Map<String, String> feedback;
  final List<String> missingWords;

  /// Compatibility constructor used by existing friendly Editor templates.
  Exercise({
    required this.id,
    this.publicationState = PublicationState.published,
    DateTime? updatedAt,
    required String type,
    String? editorTemplate,
    required String prompt,
    required String question,
    required List<String> answers,
    required int? correct,
    required String? tts,
    required List<String> accepted,
    required List<String> tokens,
    required List<String> orderAnswer,
    List<String> correctTranslations = const [],
    required List<List<String>> pairs,
    required this.hint,
    required List<String> icons,
    String imageAsset = '',
    this.missingWords = const [],
  }) : updatedAt = _canonicalUtcTimestamp(updatedAt),
       editorTemplate = editorTemplate ?? type,
       promptElements = _legacyPrompt(type, prompt, question, tts, imageAsset),
       interaction = _legacyInteraction(
         type,
         answers,
         correct,
         tokens,
         pairs,
         icons,
       ),
       evaluation = _legacyEvaluation(
         type,
         answers,
         correct,
         accepted,
         tokens,
         orderAnswer,
         correctTranslations,
         pairs,
       ),
       feedback = const {};

  Exercise.v2({
    required this.id,
    this.publicationState = PublicationState.published,
    DateTime? updatedAt,
    required this.editorTemplate,
    required this.promptElements,
    required this.interaction,
    required this.evaluation,
    this.hint = '',
    this.feedback = const {},
    this.missingWords = const [],
  }) : updatedAt = _canonicalUtcTimestamp(updatedAt);
  factory Exercise.presentation({
    required String id,
    required String editorTemplate,
    required String term,
    required String meaning,
    PublicationState publicationState = PublicationState.published,
  }) => Exercise(
    id: id,
    publicationState: publicationState,
    type: 'flashcard',
    editorTemplate: editorTemplate,
    prompt: term,
    question: meaning,
    answers: const [],
    correct: null,
    tts: null,
    accepted: const [],
    tokens: const [],
    orderAnswer: const [],
    pairs: const [],
    hint: '',
    icons: const [],
  );

  Map<String, dynamic> toV2Json() => {
    'updatedAt': _timestampToJson(updatedAt),
    'prompt': promptElements.map((e) => e.toJson()).toList(),
    'interaction': interaction.toJson(),
    'evaluation': evaluation.toJson(),
    if (hint.isNotEmpty) 'hint': hint,
    if (feedback.isNotEmpty) 'feedback': feedback,
    if (missingWords.isNotEmpty) 'missingWords': missingWords,
  };
  Map<String, dynamic> toJson() => toV2Json();
  factory Exercise.fromV2Json(
    Map<String, dynamic> j, {
    required String contentId,
    required String editorTemplate,
    required PublicationState publicationState,
  }) {
    final p = j['prompt'];
    final i = j['interaction'];
    final e = j['evaluation'];
    if (p is! List || i is! Map || e is! Map) {
      throw const FormatException(
        'Exercise requires prompt[], interaction and evaluation.',
      );
    }
    return Exercise.v2(
      id: contentId,
      publicationState: publicationState,
      updatedAt: _requiredUtcTimestamp(j, 'updatedAt', 'exercise'),
      editorTemplate: editorTemplate,
      promptElements: _mapList(j, 'prompt', 'exercise', PromptElement.fromJson),
      interaction: ExerciseInteraction.fromJson(Map<String, dynamic>.from(i)),
      evaluation: ExerciseEvaluation.fromJson(Map<String, dynamic>.from(e)),
      hint: _optionalString(j, 'hint', ''),
      feedback: j['feedback'] is Map
          ? Map<String, String>.from(
              (j['feedback'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : const {},
      missingWords: _stringList(j, 'missingWords'),
    );
  }

  // Author-friendly compatibility views. These are derived from primitives.
  String get type => _legacyTypeFromTemplate(editorTemplate, interaction.kind);
  String _promptRole(String role) =>
      promptElements
          .where((e) => e.role == role && e.type == 'text')
          .map((e) => e.text)
          .firstOrNull ??
      '';
  String get prompt => _promptRole('context').isNotEmpty
      ? _promptRole('context')
      : _promptRole('passage').isNotEmpty
      ? _promptRole('passage')
      : _promptRole('primary').isNotEmpty
      ? _promptRole('primary')
      : _promptRole('clue');
  String get question => _promptRole('question');
  String? get tts {
    final a = promptElements
        .where((e) => e.type == 'audio')
        .map((e) => e.text)
        .firstOrNull;
    return a == null || a.isEmpty ? null : a;
  }

  List<String> get answers {
    if (interaction.kind == 'match' && type == 'audio_match') {
      return evaluation.pairs
          .map((p) {
            if (p.length != 2) return '';
            final it = interaction.items.where((x) => x.id == p[1]).firstOrNull;
            return it?.value ?? '';
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (interaction.kind == 'match') return const [];
    return interaction.items
        .map((e) => e.value)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  int? get correct {
    if (evaluation.correctItemIds.isEmpty) return null;
    final id = evaluation.correctItemIds.first;
    final i = interaction.items.indexWhere((e) => e.id == id);
    return i < 0 ? null : i;
  }

  List<String> get accepted => evaluation.accepted;
  List<String> get tokens =>
      interaction.items.map((e) => e.value).where((e) => e.isNotEmpty).toList();
  List<String> get orderAnswer =>
      evaluation.correctOrders.firstOrNull?.itemIds
          .map((id) {
            final it = interaction.items.where((x) => x.id == id).firstOrNull;
            return it?.value ?? '';
          })
          .where((e) => e.isNotEmpty)
          .toList() ??
      const [];
  List<List<String>> get orderAnswers => evaluation.correctOrders
      .map(
        (answer) => answer.itemIds
            .map((id) {
              final it = interaction.items.where((x) => x.id == id).firstOrNull;
              return it?.value ?? '';
            })
            .where((e) => e.isNotEmpty)
            .toList(growable: false),
      )
      .toList(growable: false);
  List<String> get correctTranslationTexts => evaluation.correctOrders
      .map((answer) => answer.text)
      .toList(growable: false);
  List<List<String>> get pairs => evaluation.pairs
      .map((p) {
        if (p.length != 2) return <String>[];
        String val(String id) =>
            interaction.items
                .where((x) => x.id == id)
                .map((x) => x.value)
                .firstOrNull ??
            id;
        return [val(p[0]), val(p[1])];
      })
      .where((p) => p.length == 2)
      .toList();
  List<String> get icons => interaction.items
      .map(
        (e) => e.image.isNotEmpty
            ? e.image
            : (e.content
                      .where((c) => c.role == 'icon')
                      .map((c) => c.text)
                      .firstOrNull ??
                  ''),
      )
      .toList();
  String get imageAsset =>
      promptElements
          .where((e) => e.type == 'image')
          .map((e) => e.asset)
          .firstOrNull ??
      '';

  String get contextText =>
      promptElements
          .where((e) => e.role == 'context' && e.type == 'text')
          .map((e) => e.text)
          .firstOrNull ??
      '';
  String get contextAudio =>
      promptElements
          .where((e) => e.role == 'context' && e.type == 'audio')
          .map((e) => e.text)
          .firstOrNull ??
      '';
  List<PromptElement> get dialogueTurns => promptElements
      .where((e) => e.role == 'dialogue_turn' && e.type == 'text')
      .toList(growable: false);
  String get contextMode {
    final hasText = contextText.isNotEmpty || dialogueTurns.isNotEmpty;
    final hasAudio = contextAudio.isNotEmpty;
    if (hasText && hasAudio) return 'textAndAudio';
    if (hasAudio) return 'audio';
    return 'text';
  }
}

List<PromptElement> _legacyPrompt(
  String type,
  String prompt,
  String question,
  String? tts,
  String imageAsset,
) {
  final out = <PromptElement>[];
  if (prompt.isNotEmpty) {
    final role = type == 'contextual_comprehension'
        ? 'context'
        : const {'reading_comprehension', 'dialogue_response'}.contains(type)
        ? 'passage'
        : const {'word_order', 'image_word'}.contains(type)
        ? 'clue'
        : 'primary';
    out.add(PromptElement(role: role, type: 'text', text: prompt));
  }
  if (question.isNotEmpty) {
    out.add(PromptElement(role: 'question', type: 'text', text: question));
  }
  if (tts != null && tts.isNotEmpty) {
    out.add(
      PromptElement(
        role: type == 'contextual_comprehension'
            ? 'context'
            : const {'listening_comprehension'}.contains(type)
            ? 'passage'
            : 'primary',
        type: 'audio',
        text: tts,
      ),
    );
  }
  if (imageAsset.isNotEmpty) {
    out.add(PromptElement(role: 'clue', type: 'image', asset: imageAsset));
  }
  return out;
}

ExerciseInteraction _legacyInteraction(
  String type,
  List<String> answers,
  int? correct,
  List<String> tokens,
  List<List<String>> pairs,
  List<String> icons,
) {
  if (const {
    'choice',
    'gap_choice',
    'icon_choice',
    'listening_choice',
    'listening_comprehension',
    'reading_comprehension',
    'dialogue_response',
    'contextual_comprehension',
  }.contains(type)) {
    final items = <ExerciseItem>[];
    for (var i = 0; i < answers.length; i++) {
      items.add(
        ExerciseItem(
          id: 'item_$i',
          content: [
            PromptElement(type: 'text', text: answers[i]),
            if (i < icons.length && icons[i].isNotEmpty)
              PromptElement(role: 'icon', type: 'text', text: icons[i]),
          ],
        ),
      );
    }
    return ExerciseInteraction(kind: 'select', items: items);
  }
  if (const {
    'fill_blank',
    'listening_spelling',
    'missing_word',
    'type_translation',
  }.contains(type)) {
    return const ExerciseInteraction(kind: 'input', inputType: 'text');
  }
  if (const {'word_order', 'image_word', 'build_translation'}.contains(type)) {
    return ExerciseInteraction(
      kind: 'arrange',
      items: [
        for (var i = 0; i < tokens.length; i++)
          ExerciseItem(
            id: 'item_$i',
            content: [PromptElement(type: 'text', text: tokens[i])],
          ),
      ],
    );
  }
  if (const {
    'matching',
    'audio_match',
    'word_match',
    'super_match',
  }.contains(type)) {
    final items = <ExerciseItem>[];
    var n = 0;
    for (final p in pairs) {
      if (p.length == 2) {
        items.add(
          ExerciseItem(
            id: 'item_${n++}',
            content: [
              PromptElement(
                type: type == 'audio_match' ? 'audio' : 'text',
                text: p[0],
              ),
            ],
          ),
        );
        items.add(
          ExerciseItem(
            id: 'item_${n++}',
            content: [PromptElement(type: 'text', text: p[1])],
          ),
        );
      }
    }
    return ExerciseInteraction(kind: 'match', items: items);
  }
  return const ExerciseInteraction(kind: 'select');
}

ExerciseEvaluation _legacyEvaluation(
  String type,
  List<String> answers,
  int? correct,
  List<String> accepted,
  List<String> tokens,
  List<String> order,
  List<String> correctTranslations,
  List<List<String>> pairs,
) {
  if (const {
    'choice',
    'gap_choice',
    'icon_choice',
    'listening_choice',
    'listening_comprehension',
    'reading_comprehension',
    'dialogue_response',
    'contextual_comprehension',
  }.contains(type)) {
    return ExerciseEvaluation(
      kind: 'selected_items',
      correctItemIds:
          correct != null && correct >= 0 && correct < answers.length
          ? ['item_$correct']
          : const [],
    );
  }
  if (const {
    'fill_blank',
    'listening_spelling',
    'missing_word',
    'type_translation',
  }.contains(type)) {
    return ExerciseEvaluation(
      kind: 'text_match',
      accepted: accepted,
      normalization: const {
        'case': 'ignore',
        'punctuation': 'ignore',
        'whitespace': 'normalize',
        'accents': 'preserve',
      },
    );
  }
  if (const {'word_order', 'image_word'}.contains(type)) {
    final itemIds = _resolveOrderedItemIds(tokens, order);
    return ExerciseEvaluation(
      kind: 'ordered_items',
      correctOrders: [
        if (itemIds.isNotEmpty)
          OrderedAnswer(
            text: (type == 'image_word' ? order.join() : order.join(' '))
                .trim(),
            itemIds: itemIds,
          ),
      ],
    );
  }
  if (type == 'build_translation') {
    return ExerciseEvaluation(
      kind: 'ordered_items',
      correctOrders: [
        for (final translation in correctTranslations)
          if (translation.trim().isNotEmpty)
            OrderedAnswer(
              text: translation.trim(),
              itemIds: _resolveOrderedItemIds(tokens, [translation]),
            ),
      ],
    );
  }
  if (const {
    'matching',
    'audio_match',
    'word_match',
    'super_match',
  }.contains(type)) {
    final pp = <List<String>>[];
    for (var i = 0; i < pairs.length; i++) {
      pp.add(['item_${i * 2}', 'item_${i * 2 + 1}']);
    }
    return ExerciseEvaluation(kind: 'matched_items', pairs: pp);
  }
  return const ExerciseEvaluation(kind: 'selected_items');
}

List<String> _resolveOrderedItemIds(
  List<String> tokens,
  List<String> authoredOrder,
) {
  if (tokens.isEmpty || authoredOrder.isEmpty) return const [];

  String comparable(String value) => value
      .trim()
      .replaceAll(RegExp(r'[.!?…]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  List<int>? matchEntries(List<String> entries) {
    final used = <int>{};
    final indexes = <int>[];
    for (final entry in entries) {
      final expected = comparable(entry);
      final index = List<int>.generate(tokens.length, (i) => i).firstWhere(
        (i) => !used.contains(i) && comparable(tokens[i]) == expected,
        orElse: () => -1,
      );
      if (index < 0) return null;
      used.add(index);
      indexes.add(index);
    }
    return indexes;
  }

  var indexes = matchEntries(authoredOrder);
  if (indexes == null) {
    final sentence = comparable(authoredOrder.join(' '));
    List<int>? visit(String remaining, Set<int> used) {
      if (remaining.isEmpty) return const [];
      for (var index = 0; index < tokens.length; index++) {
        if (used.contains(index)) continue;
        final token = comparable(tokens[index]);
        if (token.isEmpty ||
            (remaining != token && !remaining.startsWith('$token '))) {
          continue;
        }
        final rest = remaining == token
            ? ''
            : remaining.substring(token.length).trimLeft();
        final tail = visit(rest, {...used, index});
        if (tail != null) return [index, ...tail];
      }
      return null;
    }

    indexes = visit(sentence, const <int>{});
  }
  if (indexes == null || indexes.isEmpty) return const [];
  return indexes.map((index) => 'item_$index').toList(growable: false);
}

String _legacyTypeFromTemplate(String template, String interaction) {
  const map = {
    'choose_answer': 'choice',
    'choose_picture': 'icon_choice',
    'what_do_you_hear': 'listening_choice',
    'build_sentence': 'word_order',
    'build_word': 'image_word',
    'match_words': 'word_match',
    'match_sounds': 'audio_match',
    'flashcard': 'flashcard',
    'explanation': 'flashcard',
    'example': 'flashcard',
    'vocabulary': 'flashcard',
    'text': 'flashcard',
    'dialogue': 'flashcard',
  };
  if (map.containsKey(template)) return map[template]!;
  if (template.isNotEmpty) return template;
  return switch (interaction) {
    'select' => 'choice',
    'input' => 'fill_blank',
    'arrange' => 'word_order',
    'match' => 'matching',
    _ => 'choice',
  };
}

class Duel {
  final String id;
  final String title;
  Duel({required this.id, required this.title});
  Map<String, dynamic> toJson() => {'id': id, 'title': title};
  factory Duel.fromJson(Map<String, dynamic> j) {
    final unsupported = j.keys
        .where((key) => key != 'id' && key != 'title')
        .toList();
    if (unsupported.isNotEmpty) {
      throw FormatException(
        'duel contains unsupported fields: ${unsupported.join(', ')}.',
      );
    }
    return Duel(
      id: _requiredString(j, 'id', 'duel'),
      title: _requiredString(j, 'title', 'duel'),
    );
  }
}

DateTime _canonicalUtcTimestamp(DateTime? value) =>
    (value ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)).toUtc();

String _timestampToJson(DateTime value) => value.toUtc().toIso8601String();

DateTime _requiredUtcTimestamp(
  Map<String, dynamic> json,
  String key,
  String location,
) {
  final raw = json[key];
  if (raw is! String || !raw.endsWith('Z')) {
    throw FormatException(
      '$location.$key must be an ISO 8601 UTC timestamp ending in Z.',
    );
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException(
      '$location.$key must be an unambiguous ISO 8601 UTC timestamp.',
    );
  }
  return parsed;
}

String _requiredString(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v is! String || v.trim().isEmpty) {
    throw FormatException('Missing or invalid $where.$key');
  }
  return v.trim();
}

String _optionalString(Map<String, dynamic> j, String key, String fallback) {
  final v = j[key];
  return v is String ? v.trim() : fallback;
}

int _optionalInt(Map<String, dynamic> j, String key, int fallback) {
  final v = j[key];
  return v is int ? v : fallback;
}

List<String> _stringList(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return const [];
  if (v is! List) throw FormatException('$key must be a list.');
  return [
    for (final x in v)
      if (x is String)
        x
      else
        throw FormatException('$key must contain strings only.'),
  ];
}

List<List<String>> _pairList(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v == null) return const [];
  if (v is! List) throw FormatException('$key must be a list.');
  return [
    for (final x in v)
      if (x is List && x.length == 2 && x.every((e) => e is String))
        [x[0] as String, x[1] as String]
      else
        throw FormatException('$key entries must contain exactly two strings.'),
  ];
}

List<T> _mapList<T>(
  Map<String, dynamic> j,
  String key,
  String where,
  T Function(Map<String, dynamic>) parser,
) {
  final v = j[key];
  if (v is! List) throw FormatException('$where.$key must be a list.');
  return [
    for (final x in v)
      if (x is Map)
        parser(Map<String, dynamic>.from(x))
      else
        throw FormatException('$where.$key contains a non-object value.'),
  ];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
