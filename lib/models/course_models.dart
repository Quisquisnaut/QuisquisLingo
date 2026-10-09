import 'dart:convert';
import 'dart:math';

import 'canonical/canonical.dart';
import 'exercise_canonical.dart';
import 'exercise_image_metadata.dart';
import 'guidebook_text.dart';
import 'picture_answer_style.dart';
import 'preset_successors.dart';
import '../services/app_metadata.dart';
import '../services/lesson_icon_catalog.dart';
import '../services/round_type_compatibility.dart';

export 'canonical/canonical.dart';
export 'exercise_canonical.dart';
export 'picture_answer_style.dart';

/// QuisquisLingo Course Model v11.
///
/// The serialized course format is formatVersion 12, the single accepted
/// format: v9 and v10 are clean-cut and never read. A merged Course is an
/// ordinary v11 Course that also carries mergeProvenance. Course content is stored as
/// Course > Lesson > Guidebook + Round > Content. Exercises are one Content kind
/// and are represented through Prompt + Interaction + Evaluation primitives.
///
/// A few read-only convenience getters expose the author-friendly vocabulary
/// used by the existing learner/editor widgets. They are derived from the v11
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
    if (value is! String) {
      throw const FormatException(
        'course.originType must be custom, bundledOfficial or externalOfficial.',
      );
    }
    return CourseOriginType.values.firstWhere(
      (origin) => origin.name == value,
      orElse: () => throw const FormatException(
        'course.originType must be custom, bundledOfficial or externalOfficial.',
      ),
    );
  }

  bool get isOfficial => this != CourseOriginType.custom;
}

final RegExp _stableUuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

enum CourseProvenanceIdentityType {
  qqlUser,
  publisher;

  static CourseProvenanceIdentityType parse(Object? value) => values.firstWhere(
    (type) => type.name == value,
    orElse: () => throw const FormatException(
      'course.originalCourseCreator.type must be qqlUser or publisher.',
    ),
  );
}

/// Immutable identity at the beginning of a Course lineage.
///
/// This is provenance only. It never grants QQL authorization.
class CourseProvenanceIdentity {
  final CourseProvenanceIdentityType type;
  final String id;
  final String displayName;

  const CourseProvenanceIdentity({
    required this.type,
    required this.id,
    required this.displayName,
  });

  const CourseProvenanceIdentity.qqlUser({
    required String profileId,
    required this.displayName,
  }) : type = CourseProvenanceIdentityType.qqlUser,
       id = profileId;

  const CourseProvenanceIdentity.publisher({
    required String publisherId,
    required this.displayName,
  }) : type = CourseProvenanceIdentityType.publisher,
       id = publisherId;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'displayName': displayName,
  };

  factory CourseProvenanceIdentity.fromJson(Map<String, dynamic> json) {
    final type = CourseProvenanceIdentityType.parse(json['type']);
    final id = _requiredString(json, 'id', 'course.originalCourseCreator');
    final displayName = _requiredString(
      json,
      'displayName',
      'course.originalCourseCreator',
    );
    if (type == CourseProvenanceIdentityType.qqlUser &&
        !_stableUuidV4.hasMatch(id)) {
      throw const FormatException(
        'course.originalCourseCreator.id must be a stable UUIDv4 QQL identity.',
      );
    }
    return CourseProvenanceIdentity(
      type: type,
      id: id,
      displayName: displayName,
    );
  }
}

/// Stable operational responsibility for one custom Course instance.
///
/// Maintainer status is separate from provenance, attribution and legal
/// rights metadata.
class CourseMaintainer {
  final String profileId;

  const CourseMaintainer(this.profileId);

  Map<String, dynamic> toJson() => {'profileId': profileId};

  factory CourseMaintainer.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('type')) {
      throw const FormatException(
        'course.maintainer identifies an individual QQL profile and does not support a type field.',
      );
    }
    final profileId = _requiredString(json, 'profileId', 'course.maintainer');
    if (!_stableUuidV4.hasMatch(profileId)) {
      throw const FormatException(
        'course.maintainer.profileId must be a stable UUIDv4 identity.',
      );
    }
    return CourseMaintainer(profileId);
  }
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

enum RoundNumberingMode {
  off,
  roundAndNumber,
  numberOnly,
  customAndNumber;

  static RoundNumberingMode parse(Map<String, dynamic> json) {
    if (!json.containsKey('roundNumberingMode')) return off;
    for (final mode in values) {
      if (mode.name == json['roundNumberingMode']) return mode;
    }
    throw const FormatException('course.roundNumberingMode is invalid.');
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
  Map<String, dynamic> toJson() => {'name': name, 'roles': roles};
  factory CourseAuthor.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('role')) {
      throw const FormatException(
        'Course Model v11 uses author.roles and does not support author.role.',
      );
    }
    final parsed = <String>[];
    final raw = json['roles'];
    if (raw is! List) {
      throw const FormatException('author.roles must be a list of strings.');
    }
    for (final v in raw) {
      if (v is String && v.trim().isNotEmpty) {
        parsed.add(v.trim());
      } else {
        throw const FormatException(
          'author.roles must contain non-empty strings.',
        );
      }
    }
    if (parsed.isEmpty) {
      throw const FormatException(
        'author.roles must contain at least one role.',
      );
    }
    return CourseAuthor(
      name: _requiredString(json, 'name', 'author'),
      roles: parsed,
    );
  }
}

enum CourseRightsHolderType {
  person,
  organization;

  static CourseRightsHolderType parse(Object? value) => values.firstWhere(
    (type) => type.name == value,
    orElse: () => throw const FormatException(
      'rightsHolder.type must be person or organization.',
    ),
  );
}

/// Descriptive legal metadata. It never grants QQL authorization.
class CourseRightsHolder {
  final CourseRightsHolderType type;
  final String name;

  const CourseRightsHolder({required this.type, required this.name});

  Map<String, dynamic> toJson() => {'type': type.name, 'name': name};

  factory CourseRightsHolder.fromJson(Map<String, dynamic> json) =>
      CourseRightsHolder(
        type: CourseRightsHolderType.parse(json['type']),
        name: _requiredString(json, 'name', 'rightsHolder'),
      );
}

/// Credit for third-party media a Course carries or references: images a
/// creator imported, recordings someone else performed, an embedded Lesson
/// icon or custom flag.
///
/// Descriptive metadata only. Like [CourseRightsHolder] and [CourseAuthor] it
/// never grants QQL authorization, and QQL never checks a licence for the
/// creator — it only gives the credit somewhere to live and travel.
///
/// The Course-level list is omitted from JSON when empty, so a Course that
/// records no attribution serialises and checksums exactly as before.
class CourseMediaAttribution {
  static const maxEntries = 200;
  static const _maxShortField = 200;
  static const _maxSourceField = 500;

  /// Who must be credited.
  final String author;

  /// The licence the work is used under, as the creator states it.
  final String license;

  /// The work's own name, when it has one.
  final String title;

  /// Where it came from: a page reference or a URL. Held and shown as plain
  /// text, never as a tappable link — it can arrive inside an imported Course,
  /// and QQL stays offline-first.
  final String source;

  /// Which media in this Course the credit covers.
  final String appliesTo;

  const CourseMediaAttribution({
    required this.author,
    required this.license,
    this.title = '',
    this.source = '',
    this.appliesTo = '',
  });

  Map<String, dynamic> toJson() => {
    'author': author,
    'license': license,
    if (title.isNotEmpty) 'title': title,
    if (source.isNotEmpty) 'source': source,
    if (appliesTo.isNotEmpty) 'appliesTo': appliesTo,
  };

  factory CourseMediaAttribution.fromJson(
    Map<String, dynamic> json,
  ) => CourseMediaAttribution(
    author: _mediaAttributionField(json['author'], 'author', required: true),
    license: _mediaAttributionField(json['license'], 'license', required: true),
    title: _mediaAttributionField(json['title'], 'title'),
    source: _mediaAttributionField(
      json['source'],
      'source',
      limit: _maxSourceField,
    ),
    appliesTo: _mediaAttributionField(json['appliesTo'], 'appliesTo'),
  );

  /// Equality by content, so duplicate entries can be rejected.
  @override
  bool operator ==(Object other) =>
      other is CourseMediaAttribution &&
      other.author == author &&
      other.license == license &&
      other.title == title &&
      other.source == source &&
      other.appliesTo == appliesTo;

  @override
  int get hashCode => Object.hash(author, license, title, source, appliesTo);

  static String _mediaAttributionField(
    Object? value,
    String field, {
    bool required = false,
    int limit = _maxShortField,
  }) {
    final normalized = (value ?? '').toString().trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalized.isEmpty) {
      if (required) {
        throw FormatException('mediaAttribution.$field must not be empty.');
      }
      return '';
    }
    if (normalized.length > limit) {
      throw FormatException(
        'mediaAttribution.$field must not exceed $limit characters.',
      );
    }
    return normalized;
  }

  /// Parses and validates the whole Course-level list.
  static List<CourseMediaAttribution> parseList(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const FormatException('course.mediaAttributions must be a list.');
    }
    if (raw.length > maxEntries) {
      throw const FormatException(
        'course.mediaAttributions must not exceed $maxEntries entries.',
      );
    }
    final parsed = <CourseMediaAttribution>[];
    for (final entry in raw) {
      if (entry is! Map) {
        throw const FormatException(
          'course.mediaAttributions entries must be objects.',
        );
      }
      final attribution = CourseMediaAttribution.fromJson(
        Map<String, dynamic>.from(entry),
      );
      if (parsed.contains(attribution)) {
        throw const FormatException(
          'course.mediaAttributions must not repeat an identical entry.',
        );
      }
      parsed.add(attribution);
    }
    return List.unmodifiable(parsed);
  }
}

enum DerivativeWorksPolicy {
  allowed,
  forbidden,
  unspecified;

  static DerivativeWorksPolicy parse(Object? value) {
    if (value == null) return unspecified;
    return values.firstWhere(
      (policy) => policy.name == value,
      orElse: () => throw const FormatException(
        'course.derivativeWorksPolicy must be allowed, forbidden or unspecified.',
      ),
    );
  }
}

/// Immutable provenance for this specific fork and its immediate source.
class CourseForkProvenance {
  final String sourceCourseId;
  final String sourceCourseTitle;
  final String sourceCourseVersion;
  final CourseOriginType sourceOriginType;
  final String sourcePublisherId;
  final String sourcePublisherName;
  final String sourceOfficialChecksum;
  final List<CourseAuthor> sourceAuthors;
  final String forkCreatedByProfileId;
  final String forkCreatedByDisplayName;
  final String forkCreatedAtUtc;

  CourseForkProvenance({
    required this.sourceCourseId,
    required this.sourceCourseTitle,
    required this.sourceCourseVersion,
    required this.sourceOriginType,
    this.sourcePublisherId = '',
    this.sourcePublisherName = '',
    this.sourceOfficialChecksum = '',
    List<CourseAuthor> sourceAuthors = const [],
    required this.forkCreatedByProfileId,
    required this.forkCreatedByDisplayName,
    required this.forkCreatedAtUtc,
  }) : sourceAuthors = List.unmodifiable([
         for (final author in sourceAuthors)
           CourseAuthor(
             name: author.name,
             roles: List.unmodifiable(author.roles),
           ),
       ]) {
    if ([
          sourceCourseId,
          sourceCourseTitle,
          forkCreatedByProfileId,
          forkCreatedByDisplayName,
        ].any((value) => value.trim().isEmpty) ||
        !_stableUuidV4.hasMatch(forkCreatedByProfileId) ||
        (sourceOfficialChecksum.isNotEmpty &&
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(sourceOfficialChecksum)) ||
        !forkCreatedAtUtc.endsWith('Z') ||
        DateTime.tryParse(forkCreatedAtUtc)?.isUtc != true) {
      throw const FormatException(
        'Course fork provenance is incomplete or invalid.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'sourceCourseId': sourceCourseId,
    'sourceCourseTitle': sourceCourseTitle,
    if (sourceCourseVersion.isNotEmpty)
      'sourceCourseVersion': sourceCourseVersion,
    'sourceOriginType': sourceOriginType.name,
    if (sourcePublisherId.isNotEmpty) 'sourcePublisherId': sourcePublisherId,
    if (sourcePublisherName.isNotEmpty)
      'sourcePublisherName': sourcePublisherName,
    if (sourceOfficialChecksum.isNotEmpty)
      'sourceOfficialChecksum': sourceOfficialChecksum,
    if (sourceAuthors.isNotEmpty)
      'sourceAuthors': sourceAuthors.map((author) => author.toJson()).toList(),
    'forkCreatedByProfileId': forkCreatedByProfileId,
    'forkCreatedByDisplayName': forkCreatedByDisplayName,
    'forkCreatedAtUtc': forkCreatedAtUtc,
  };

  factory CourseForkProvenance.fromJson(Map<String, dynamic> json) {
    for (final removed in const [
      'originalPublisherId',
      'originalPublisherName',
      'originalCourseId',
      'originalOfficialCourseVersion',
      'originalOfficialChecksum',
      'originalCourseTitle',
      'originalAuthor',
      'originalAuthors',
      'forkCreatedByUsername',
    ]) {
      if (json.containsKey(removed)) {
        throw FormatException(
          'Course Model v11 does not support forkProvenance.$removed.',
        );
      }
    }
    final authors = json['sourceAuthors'] ?? const <Object>[];
    if (authors is! List || authors.any((author) => author is! Map)) {
      throw const FormatException(
        'forkProvenance.sourceAuthors must be a list of authors.',
      );
    }
    final sourceOriginType = CourseOriginType.values.firstWhere(
      (type) => type.name == json['sourceOriginType'],
      orElse: () => throw const FormatException(
        'forkProvenance.sourceOriginType is missing or invalid.',
      ),
    );
    return CourseForkProvenance(
      sourceCourseId: _requiredString(json, 'sourceCourseId', 'forkProvenance'),
      sourceCourseTitle: _requiredString(
        json,
        'sourceCourseTitle',
        'forkProvenance',
      ),
      sourceCourseVersion: _optionalString(json, 'sourceCourseVersion', ''),
      sourceOriginType: sourceOriginType,
      sourcePublisherId: _optionalString(json, 'sourcePublisherId', ''),
      sourcePublisherName: _optionalString(json, 'sourcePublisherName', ''),
      sourceOfficialChecksum: _optionalString(
        json,
        'sourceOfficialChecksum',
        '',
      ),
      sourceAuthors: authors
          .map(
            (author) =>
                CourseAuthor.fromJson(Map<String, dynamic>.from(author as Map)),
          )
          .toList(),
      forkCreatedByProfileId: _requiredString(
        json,
        'forkCreatedByProfileId',
        'forkProvenance',
      ),
      forkCreatedByDisplayName: _requiredString(
        json,
        'forkCreatedByDisplayName',
        'forkProvenance',
      ),
      forkCreatedAtUtc: _requiredString(
        json,
        'forkCreatedAtUtc',
        'forkProvenance',
      ),
    );
  }
}

/// Immutable references to the two immediate sources of a merged Course.
class CourseMergeProvenance {
  final String leftSourceCourseId;
  final String leftSourceCourseVersion;
  final String leftSourceModifiedAtUtc;
  final String rightSourceCourseId;
  final String rightSourceCourseVersion;
  final String rightSourceModifiedAtUtc;
  final String mergedAtUtc;

  const CourseMergeProvenance({
    required this.leftSourceCourseId,
    required this.leftSourceCourseVersion,
    required this.leftSourceModifiedAtUtc,
    required this.rightSourceCourseId,
    required this.rightSourceCourseVersion,
    required this.rightSourceModifiedAtUtc,
    required this.mergedAtUtc,
  });

  Map<String, dynamic> toJson() => {
    'leftSourceCourseId': leftSourceCourseId,
    'leftSourceCourseVersion': leftSourceCourseVersion,
    'leftSourceModifiedAtUtc': leftSourceModifiedAtUtc,
    'rightSourceCourseId': rightSourceCourseId,
    'rightSourceCourseVersion': rightSourceCourseVersion,
    'rightSourceModifiedAtUtc': rightSourceModifiedAtUtc,
    'mergedAtUtc': mergedAtUtc,
  };

  factory CourseMergeProvenance.fromJson(Map<String, dynamic> json) {
    final provenance = CourseMergeProvenance(
      leftSourceCourseId: _requiredString(
        json,
        'leftSourceCourseId',
        'mergeProvenance',
      ),
      leftSourceCourseVersion: _requiredString(
        json,
        'leftSourceCourseVersion',
        'mergeProvenance',
      ),
      leftSourceModifiedAtUtc: _optionalString(
        json,
        'leftSourceModifiedAtUtc',
        '',
      ),
      rightSourceCourseId: _requiredString(
        json,
        'rightSourceCourseId',
        'mergeProvenance',
      ),
      rightSourceCourseVersion: _requiredString(
        json,
        'rightSourceCourseVersion',
        'mergeProvenance',
      ),
      rightSourceModifiedAtUtc: _optionalString(
        json,
        'rightSourceModifiedAtUtc',
        '',
      ),
      mergedAtUtc: _requiredString(json, 'mergedAtUtc', 'mergeProvenance'),
    );
    final sameCourseRevision =
        provenance.leftSourceCourseId == provenance.rightSourceCourseId &&
        provenance.leftSourceCourseVersion ==
            provenance.rightSourceCourseVersion;
    final sourceTimestampsAreValid =
        provenance.leftSourceModifiedAtUtc.isNotEmpty &&
        provenance.rightSourceModifiedAtUtc.isNotEmpty &&
        provenance.leftSourceModifiedAtUtc.endsWith('Z') &&
        provenance.rightSourceModifiedAtUtc.endsWith('Z') &&
        DateTime.tryParse(provenance.leftSourceModifiedAtUtc)?.isUtc == true &&
        DateTime.tryParse(provenance.rightSourceModifiedAtUtc)?.isUtc == true;
    if ((sameCourseRevision &&
            (!sourceTimestampsAreValid ||
                provenance.leftSourceModifiedAtUtc ==
                    provenance.rightSourceModifiedAtUtc)) ||
        !provenance.mergedAtUtc.endsWith('Z') ||
        DateTime.tryParse(provenance.mergedAtUtc)?.isUtc != true) {
      throw const FormatException('Course merge provenance is invalid.');
    }
    return provenance;
  }
}

/// How to reach a Course's publisher or author. Descriptive only: the
/// application shows it as plain text and never contacts anyone by itself.
class CoursePublisherContact {
  final String websiteUrl;
  final String email;

  CoursePublisherContact({String websiteUrl = '', String email = ''})
    : websiteUrl = websiteUrl.trim(),
      email = email.trim() {
    if (this.websiteUrl.isEmpty && this.email.isEmpty) {
      throw const FormatException(
        'course.publisherContact needs a website or an email.',
      );
    }
    if (this.websiteUrl.isNotEmpty) {
      final uri = Uri.tryParse(this.websiteUrl);
      if (this.websiteUrl.length > 500 ||
          uri == null ||
          uri.scheme.toLowerCase() != 'https' ||
          !uri.hasAuthority ||
          uri.host.isEmpty) {
        throw const FormatException(
          'Publisher website must be a valid HTTPS URL.',
        );
      }
    }
    if (this.email.isNotEmpty &&
        (this.email.length > 254 ||
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(this.email))) {
      throw const FormatException('Publisher email is not a valid address.');
    }
  }

  /// Null when both values are blank, so an empty editor form clears it.
  static CoursePublisherContact? fromFields(String websiteUrl, String email) =>
      websiteUrl.trim().isEmpty && email.trim().isEmpty
      ? null
      : CoursePublisherContact(websiteUrl: websiteUrl, email: email);

  Map<String, dynamic> toJson() => {
    if (websiteUrl.isNotEmpty) 'websiteUrl': websiteUrl,
    if (email.isNotEmpty) 'email': email,
  };

  factory CoursePublisherContact.fromJson(Map<String, dynamic> json) {
    for (final key in const ['websiteUrl', 'email']) {
      if (json.containsKey(key) && json[key] is! String) {
        throw FormatException('course.publisherContact.$key must be a string.');
      }
    }
    return CoursePublisherContact(
      websiteUrl: json['websiteUrl'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class Course {
  static const int currentFormatVersion = 12;

  /// App Store age-rating classes accepted by [minimumAge].
  static const List<int> minimumAgeClasses = [4, 9, 13, 16, 18];
  static const int maxEstimatedStudyHours = 1000;
  static const int maxKeywords = 20;
  static const int maxKeywordLength = 32;

  /// A cover is a course-media reference: `media:<sha256>.<ext>`.
  static final RegExp coverImagePattern = RegExp(
    r'^media:[0-9a-f]{64}\.(png|jpg|jpeg|webp)$',
  );

  /// This application's build, compared with [minimumAppBuild].
  static final int appBuildNumber = int.parse(AppMetadata.buildNumber);

  /// In-memory fixture identity used only by direct Dart constructors.
  /// Serialized v11 custom JSON must still provide lineage and Maintainer
  /// metadata explicitly,
  /// and storage authorization never grants this detached identity rights.
  static const String detachedInMemoryProfileId =
      '00000000-0000-4000-8000-000000000000';
  static const String detachedInMemoryTimestamp = '1970-01-01T00:00:00.000Z';
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
  final CourseProvenanceIdentity originalCourseCreator;
  final CourseMaintainer? maintainer;
  final String? assignedTeamId;
  final String originalCreatedAtUtc;
  final String lastVersionEditorProfileId;
  final String lastVersionEditorDisplayName;
  final String modifiedAtUtc;
  final String versionNotes;
  final int? restoredFromVersion;
  final PublicationState publicationState;
  final LessonNumberingMode lessonNumberingMode;
  final String customLessonLabel;
  final RoundNumberingMode roundNumberingMode;
  final String customRoundLabel;
  final List<int> defaultTimedLimitsSeconds;

  /// How a Select draws the pictures on its answers unless an exercise
  /// chooses otherwise (Build 263 Revision 2; JSON `pictureAnswers`, stored
  /// only when it differs from the standard look).
  final PictureAnswerStyle pictureAnswers;
  final LessonFallbackIconStyle defaultLessonIconStyle;
  final bool createDuels;
  final bool useGuidebook;

  /// Build 258 Revision 4 (owner decision, 29 September 2026): whether
  /// learners may share, save and print this Course's Pages. On by default;
  /// a courtesy the author sets, never inferred from the licence text.
  final bool allowPageSharing;

  /// Build 265 (owner decision, 5 October 2026): whether learners may tap a
  /// word to see its GuideBook translation (Word Lookup). On by default and
  /// meaningful only while [useGuidebook] is on.
  final bool wordLookup;

  /// Explicit reusable names; legacy Lesson assignments remain available too.
  final List<String> sectionNames;
  final String learningLanguage;
  final String interfaceLanguage;
  final String sourceLanguage;
  final String targetLanguage;
  final String title;
  final String ttsLanguage;
  final String audioMode;
  final List<CourseAuthor> authors;
  final String license;
  final List<CourseRightsHolder> rightsHolders;

  /// Credit for third-party media this Course carries or references.
  /// Descriptive only; it never grants QQL authorization.
  final List<CourseMediaAttribution> mediaAttributions;
  final DerivativeWorksPolicy derivativeWorksPolicy;
  final CourseForkProvenance? forkProvenance;
  final CourseMergeProvenance? mergeProvenance;

  /// Lowest application build that may open this Course; null when unset.
  final int? minimumAppBuild;
  final CoursePublisherContact? publisherContact;
  final int? estimatedStudyHours;

  /// Minimum suitable age as an App Store class (4, 9, 13, 16 or 18).
  final int? minimumAge;
  final List<String> keywords;

  /// Shown as the Course's artwork in the Course Library, with the Course
  /// flag as fallback.
  final String coverImage;
  final String languageVariant;
  final String startLevel;
  final String targetLevel;
  final String courseVersion;
  final String courseDescription;
  final String sourceLanguageTag;
  final String targetLanguageTag;

  /// How this Course's learners call the language they learn, in the
  /// Course's base language, for lines such as "Translate into …" (Build 260
  /// Revision 0). Empty: QQL's name for the language. Stored only when set.
  final String targetLanguageNameForLearners;
  final String textDirection;
  final String flagCode;
  final String flagImageBase64;

  /// Stable World Flags entity identity, independent from legacy flagCode.
  final String worldFlagId;
  final bool temporarySample;
  final String buyACoffeeUrl;
  final List<CourseLessonIconAsset> lessonIconAssets;
  final List<CourseAudioClip> audioLibrary;

  /// Images the Course keeps in its own library even while no exercise uses
  /// them, so a confirmed save does not remove them.
  final List<CourseImageLibraryEntry> imageLibrary;

  /// Build 256 Revision 5: the Story narrator's name, avatar, language and
  /// voice; null means the default narrator.
  final StorySpeaker? storyNarrator;

  /// Build 256 Revision 5: the Story characters that dialogue lines refer to
  /// by id.
  final List<StorySpeaker> storyCharacters;
  final List<Lesson> lessons;

  /// The narrator, customized or default.
  StorySpeaker get narrator => storyNarrator ?? StorySpeaker.defaultNarrator;

  /// The speaker of a line: the narrator for an empty [speakerId], the
  /// character with that id, or null when the Course has no such character.
  StorySpeaker? speakerOf(String speakerId) {
    if (speakerId.isEmpty) return narrator;
    for (final character in storyCharacters) {
      if (character.id == speakerId) return character;
    }
    return null;
  }

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
    CourseProvenanceIdentity? originalCourseCreator,
    CourseMaintainer? maintainer,
    String? assignedTeamId,
    String? originalCreatedAtUtc,
    String? lastVersionEditorProfileId,
    String? lastVersionEditorDisplayName,
    String? modifiedAtUtc,
    this.versionNotes = '',
    this.restoredFromVersion,
    this.publicationState = PublicationState.published,
    this.lessonNumberingMode = LessonNumberingMode.lesson,
    String customLessonLabel = '',
    this.roundNumberingMode = RoundNumberingMode.off,
    String customRoundLabel = '',
    this.defaultTimedLimitsSeconds = const [],
    this.pictureAnswers = PictureAnswerStyle.standard,
    this.defaultLessonIconStyle = LessonFallbackIconStyle.monochrome,
    this.createDuels = true,
    this.useGuidebook = true,
    this.allowPageSharing = true,
    this.wordLookup = true,
    List<String> sectionNames = const [],
    required this.learningLanguage,
    required this.interfaceLanguage,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.title,
    required this.ttsLanguage,
    this.audioMode = 'tts',
    this.authors = const [],
    this.license = 'All rights reserved',
    this.rightsHolders = const [],
    this.mediaAttributions = const [],
    this.derivativeWorksPolicy = DerivativeWorksPolicy.unspecified,
    this.forkProvenance,
    this.mergeProvenance,
    this.minimumAppBuild,
    this.publisherContact,
    this.estimatedStudyHours,
    this.minimumAge,
    List<String> keywords = const [],
    this.coverImage = '',
    this.languageVariant = '',
    this.startLevel = '',
    this.targetLevel = '',
    this.courseVersion = '',
    this.courseDescription = '',
    this.sourceLanguageTag = '',
    this.targetLanguageTag = '',
    this.targetLanguageNameForLearners = '',
    this.textDirection = 'ltr',
    this.flagCode = '',
    this.flagImageBase64 = '',
    String worldFlagId = '',
    this.temporarySample = false,
    String buyACoffeeUrl = '',
    this.lessonIconAssets = const [],
    this.audioLibrary = const [],
    this.imageLibrary = const [],
    this.storyNarrator,
    this.storyCharacters = const [],
    required this.lessons,
  }) : customRoundLabel = customRoundLabel.trim(),
       originalCourseCreator =
           originalCourseCreator ??
           (originType == CourseOriginType.custom
               ? const CourseProvenanceIdentity.qqlUser(
                   profileId: detachedInMemoryProfileId,
                   displayName: 'Detached in-memory profile',
                 )
               : CourseProvenanceIdentity.publisher(
                   publisherId: publisherId,
                   displayName: publisherName,
                 )),
       maintainer =
           maintainer ??
           (originType == CourseOriginType.custom
               ? const CourseMaintainer(detachedInMemoryProfileId)
               : null),
       assignedTeamId = assignedTeamId?.trim().isEmpty == true
           ? null
           : assignedTeamId?.trim(),
       originalCreatedAtUtc =
           originalCreatedAtUtc ??
           (originType == CourseOriginType.custom
               ? detachedInMemoryTimestamp
               : officialReleaseDateUtc),
       lastVersionEditorProfileId =
           lastVersionEditorProfileId ??
           (originType == CourseOriginType.custom
               ? detachedInMemoryProfileId
               : ''),
       lastVersionEditorDisplayName =
           lastVersionEditorDisplayName ??
           (originType == CourseOriginType.custom
               ? 'Detached in-memory profile'
               : ''),
       modifiedAtUtc =
           modifiedAtUtc ??
           (originType == CourseOriginType.custom
               ? detachedInMemoryTimestamp
               : officialReleaseDateUtc),
       sectionNames = _normalizeSectionNames(sectionNames),
       keywords = List.unmodifiable(keywords),
       worldFlagId = worldFlagId.trim(),
       customLessonLabel = customLessonLabel.trim(),
       buyACoffeeUrl = normalizeBuyACoffeeUrl(buyACoffeeUrl) {
    if (formatVersion != currentFormatVersion) {
      throw FormatException(
        'Unsupported course formatVersion: $formatVersion.',
      );
    }
    if (mergeProvenance != null && originType != CourseOriginType.custom) {
      throw const FormatException(
        'Only custom Courses can have merge provenance.',
      );
    }
    validateDescriptiveMetadata(
      minimumAppBuild: minimumAppBuild,
      estimatedStudyHours: estimatedStudyHours,
      minimumAge: minimumAge,
      keywords: this.keywords,
      coverImage: coverImage,
    );
    if (originType.isOfficial && forkProvenance != null) {
      throw const FormatException(
        'Only custom courses can have fork provenance.',
      );
    }
    if (originType.isOfficial &&
        (this.maintainer != null || this.assignedTeamId != null)) {
      throw const FormatException(
        'Official courses use publisher provenance and cannot have a custom Course Maintainer or assigned Team.',
      );
    }
    if (originType.isOfficial &&
        (this.originalCourseCreator.type !=
                CourseProvenanceIdentityType.publisher ||
            this.originalCourseCreator.id != publisherId)) {
      throw const FormatException(
        'Official Course lineage must identify its authoritative publisher.',
      );
    }
    if (originType == CourseOriginType.custom &&
        forkProvenance == null &&
        this.originalCourseCreator.type !=
            CourseProvenanceIdentityType.qqlUser) {
      throw const FormatException(
        'A non-forked custom Course must begin with a QQL user as Original Course Creator.',
      );
    }
    if (lessonNumberingMode == LessonNumberingMode.other &&
        this.customLessonLabel.isEmpty) {
      throw const FormatException(
        'A non-empty custom Lesson label is required for Other.',
      );
    }
    if (roundNumberingMode == RoundNumberingMode.customAndNumber &&
        this.customRoundLabel.isEmpty) {
      throw const FormatException('A custom Round label is required.');
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
    if (originType == CourseOriginType.custom && this.maintainer != null) {
      if (!_stableUuidV4.hasMatch(this.maintainer!.profileId) ||
          (this.assignedTeamId != null &&
              !_stableUuidV4.hasMatch(this.assignedTeamId!))) {
        throw const FormatException(
          'A custom Course Maintainer and assigned Team must use stable UUIDv4 identities.',
        );
      }
    }
    if (originType == CourseOriginType.custom &&
        (publisherId.isNotEmpty ||
            publisherName.isNotEmpty ||
            officialCourseVersion.isNotEmpty ||
            officialReleaseDateUtc.isNotEmpty ||
            officialChecksum.isNotEmpty ||
            officialReleaseNotes.isNotEmpty ||
            distributionChannel.isNotEmpty ||
            publisherVerificationStatus !=
                PublisherVerificationStatus.unverified ||
            publisherSignature.isNotEmpty)) {
      throw const FormatException(
        'Custom courses cannot contain official publisher or release metadata.',
      );
    }
    if (originType.isOfficial &&
        (courseVersion.isNotEmpty ||
            versionNotes.isNotEmpty ||
            restoredFromVersion != null)) {
      throw const FormatException(
        'Official courses cannot contain custom Course version or restore metadata.',
      );
    }
    if (this.lastVersionEditorProfileId.isEmpty !=
        this.lastVersionEditorDisplayName.isEmpty) {
      throw const FormatException(
        'Last Version Editor identity and display name must be present together.',
      );
    }
    if (originType == CourseOriginType.custom &&
        this.lastVersionEditorProfileId.isNotEmpty &&
        !_stableUuidV4.hasMatch(this.lastVersionEditorProfileId)) {
      throw const FormatException(
        'course.lastVersionEditorProfileId must be a stable UUIDv4 identity.',
      );
    }
    if (originType == CourseOriginType.custom &&
        courseVersion.isNotEmpty &&
        !RegExp(r'^[1-9][0-9]*$').hasMatch(courseVersion)) {
      throw const FormatException(
        'course.courseVersion must be a positive integer stored as a string.',
      );
    }
    for (final timestamp in {
      'officialReleaseDateUtc': officialReleaseDateUtc,
      'originalCreatedAtUtc': this.originalCreatedAtUtc,
      'modifiedAtUtc': this.modifiedAtUtc,
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
  }

  /// The one validator for the optional v11 descriptive fields, shared by the
  /// constructor and the Course Info Editor.
  static void validateDescriptiveMetadata({
    int? minimumAppBuild,
    int? estimatedStudyHours,
    int? minimumAge,
    List<String> keywords = const [],
    String coverImage = '',
  }) {
    final build = minimumAppBuild;
    if (build != null) {
      if (build < 1) {
        throw const FormatException(
          'course.minimumAppBuild must be a positive whole number.',
        );
      }
      if (build > appBuildNumber) {
        throw FormatException(
          'This Course requires QuisquisLingo build $build or later. '
          'This is build $appBuildNumber. Update QuisquisLingo to use it.',
        );
      }
    }
    final hours = estimatedStudyHours;
    if (hours != null && (hours < 1 || hours > maxEstimatedStudyHours)) {
      throw const FormatException(
        'course.estimatedStudyHours must be a whole number from 1 to 1000.',
      );
    }
    if (minimumAge != null && !minimumAgeClasses.contains(minimumAge)) {
      throw const FormatException(
        'course.minimumAge must be one of 4, 9, 13, 16 or 18.',
      );
    }
    if (keywords.length > maxKeywords) {
      throw const FormatException(
        'course.keywords accepts at most 20 keywords.',
      );
    }
    final seen = <String>{};
    for (final keyword in keywords) {
      if (keyword.isEmpty || keyword != keyword.trim()) {
        throw const FormatException(
          'course.keywords entries must be non-empty and trimmed.',
        );
      }
      if (keyword.length > maxKeywordLength) {
        throw const FormatException(
          'course.keywords entries must be at most 32 characters.',
        );
      }
      if (!seen.add(keyword.toLowerCase())) {
        throw FormatException('course.keywords repeats "$keyword".');
      }
    }
    if (coverImage.isNotEmpty && !coverImagePattern.hasMatch(coverImage)) {
      throw const FormatException(
        'course.coverImage must be a media:<sha256>.<png|jpg|jpeg|webp> reference.',
      );
    }
  }

  /// A Course's own images and recordings are named by content
  /// (`media:<sha256>.<ext>`, see `CourseMediaStore`), never by a path on the
  /// author's device. Bundled `assets/` media and embedded `data:image/`
  /// images remain valid.
  static final RegExp _audioReference = RegExp(r'^media:[0-9a-f]{64}\.mp3$');
  static final RegExp _imageReference = RegExp(
    r'^media:[0-9a-f]{64}\.(png|jpg|jpeg|webp)$',
  );

  static bool isValidAudioReference(String value) =>
      value.isEmpty ||
      value.startsWith('assets/') ||
      _audioReference.hasMatch(value);

  static bool isValidImageReference(String value) =>
      value.isEmpty ||
      value.startsWith('assets/') ||
      value.startsWith('data:image/') ||
      _imageReference.hasMatch(value);

  static void _validateMediaReferences(Map<String, dynamic> json) {
    final library = json['audioLibrary'];
    if (library is List) {
      for (final clip in library.whereType<Map>()) {
        final path = clip['filePath'];
        if (path is String && !isValidAudioReference(path)) {
          throw FormatException(
            'Audio Library recording "$path" is not supported. Recordings '
            'must be bundled assets or course media (media:<sha256>.mp3), '
            'never a path on one device.',
          );
        }
      }
    }
    void visit(Object? node) {
      if (node is Map) {
        final asset = node['asset'];
        if (node['type'] == 'image' &&
            asset is String &&
            !isValidImageReference(asset)) {
          throw FormatException(
            'Exercise image "${asset.length > 120 ? '${asset.substring(0, 120)}…' : asset}" '
            'is not supported. Images must be bundled assets, embedded images '
            'or course media (media:<sha256>.<png|jpg|jpeg|webp>), never a '
            'path on one device.',
          );
        }
        node.values.forEach(visit);
      } else if (node is List) {
        node.forEach(visit);
      }
    }

    visit(json['lessons']);
  }

  /// Trims keywords, drops blank ones and keeps the first spelling of any
  /// case-insensitive duplicate. Limits are still enforced by the constructor.
  static List<String> normalizeKeywords(Iterable<String> values) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (value.trim().isNotEmpty && seen.add(value.trim().toLowerCase()))
          value.trim(),
    ];
  }

  /// Exposes existing Lesson assignments without adding redundant Course data.
  List<String> get availableSectionNames => _normalizeSectionNames([
    ...sectionNames,
    for (final lesson in lessons)
      if (lesson.section && lesson.sectionName != null) lesson.sectionName!,
  ]);

  static List<String> _normalizeSectionNames(Iterable<String> names) {
    final normalized = <String>{};
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const FormatException(
          'course.sectionNames must contain non-empty names.',
        );
      }
      normalized.add(trimmed);
    }
    return List.unmodifiable(normalized);
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
    'formatVersion': formatVersion,
    'publicationState': publicationState.name,
    'lessonNumberingMode': lessonNumberingMode.name,
    if (lessonNumberingMode == LessonNumberingMode.other)
      'customLessonLabel': customLessonLabel,
    'roundNumberingMode': roundNumberingMode.name,
    if (roundNumberingMode == RoundNumberingMode.customAndNumber)
      'customRoundLabel': customRoundLabel,
    if (defaultTimedLimitsSeconds.isNotEmpty)
      'defaultTimedLimitsSeconds': defaultTimedLimitsSeconds,
    if (!pictureAnswers.isStandard) 'pictureAnswers': pictureAnswers.toJson(),
    'defaultLessonIconStyle': defaultLessonIconStyle.name,
    if (!createDuels) 'createDuels': false,
    if (!useGuidebook) 'useGuidebook': false,
    if (!allowPageSharing) 'allowPageSharing': false,
    if (!wordLookup) 'wordLookup': false,
    if (sectionNames.isNotEmpty) 'sectionNames': sectionNames,
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
    'originalCourseCreator': originalCourseCreator.toJson(),
    if (maintainer != null) 'maintainer': maintainer!.toJson(),
    if (assignedTeamId != null) 'assignedTeamId': assignedTeamId,
    if (originalCreatedAtUtc.isNotEmpty)
      'originalCreatedAtUtc': originalCreatedAtUtc,
    if (lastVersionEditorProfileId.isNotEmpty)
      'lastVersionEditorProfileId': lastVersionEditorProfileId,
    if (lastVersionEditorDisplayName.isNotEmpty)
      'lastVersionEditorDisplayName': lastVersionEditorDisplayName,
    if (modifiedAtUtc.isNotEmpty) 'modifiedAtUtc': modifiedAtUtc,
    if (versionNotes.isNotEmpty) 'versionNotes': versionNotes,
    if (restoredFromVersion != null) 'restoredFromVersion': restoredFromVersion,
    'learningLanguage': learningLanguage,
    'interfaceLanguage': interfaceLanguage,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'title': title,
    'ttsLanguage': ttsLanguage,
    'audioMode': audioMode,
    if (authors.isNotEmpty) 'authors': authors.map((e) => e.toJson()).toList(),
    'license': license,
    if (rightsHolders.isNotEmpty)
      'rightsHolders': rightsHolders.map((holder) => holder.toJson()).toList(),
    // Omitted when empty: a Course that records no media attribution keeps
    // exactly the JSON and the checksum it had before this field existed,
    // including every signed Publisher course.
    if (mediaAttributions.isNotEmpty)
      'mediaAttributions': mediaAttributions
          .map((attribution) => attribution.toJson())
          .toList(),
    if (derivativeWorksPolicy != DerivativeWorksPolicy.unspecified)
      'derivativeWorksPolicy': derivativeWorksPolicy.name,
    if (forkProvenance != null) 'forkProvenance': forkProvenance!.toJson(),
    if (mergeProvenance != null) 'mergeProvenance': mergeProvenance!.toJson(),
    if (minimumAppBuild != null) 'minimumAppBuild': minimumAppBuild,
    if (publisherContact != null)
      'publisherContact': publisherContact!.toJson(),
    if (estimatedStudyHours != null) 'estimatedStudyHours': estimatedStudyHours,
    if (minimumAge != null) 'minimumAge': minimumAge,
    if (keywords.isNotEmpty) 'keywords': keywords,
    if (coverImage.isNotEmpty) 'coverImage': coverImage,
    if (languageVariant.isNotEmpty) 'languageVariant': languageVariant,
    if (startLevel.isNotEmpty) 'startLevel': startLevel,
    if (targetLevel.isNotEmpty) 'targetLevel': targetLevel,
    if (courseVersion.isNotEmpty) 'courseVersion': courseVersion,
    if (courseDescription.isNotEmpty) 'courseDescription': courseDescription,
    if (sourceLanguageTag.isNotEmpty) 'sourceLanguageTag': sourceLanguageTag,
    if (targetLanguageTag.isNotEmpty) 'targetLanguageTag': targetLanguageTag,
    if (targetLanguageNameForLearners.isNotEmpty)
      'targetLanguageNameForLearners': targetLanguageNameForLearners,
    'textDirection': textDirection,
    if (flagCode.isNotEmpty) 'flagCode': flagCode,
    if (flagImageBase64.isNotEmpty) 'flagImageBase64': flagImageBase64,
    if (worldFlagId.isNotEmpty) 'worldFlagId': worldFlagId,
    'temporarySample': temporarySample,
    if (buyACoffeeUrl.isNotEmpty) 'buyACoffeeUrl': buyACoffeeUrl,
    if (lessonIconAssets.isNotEmpty)
      'lessonIconAssets': lessonIconAssets.map((e) => e.toJson()).toList(),
    if (audioLibrary.isNotEmpty)
      'audioLibrary': audioLibrary.map((e) => e.toJson()).toList(),
    if (imageLibrary.isNotEmpty)
      'imageLibrary': imageLibrary.map((e) => e.toJson()).toList(),
    if (storyNarrator != null) 'storyNarrator': storyNarrator!.toJson(),
    if (storyCharacters.isNotEmpty)
      'storyCharacters': storyCharacters.map((e) => e.toJson()).toList(),
    'lessons': lessons.map((e) => e.toJson()).toList(),
  };

  factory Course.fromJson(Map<String, dynamic> json) {
    for (final key in [
      'createDuels',
      'useGuidebook',
      'allowPageSharing',
      'wordLookup',
    ]) {
      if (json.containsKey(key) && json[key] is! bool) {
        throw FormatException('course.$key must be a boolean.');
      }
    }
    if (json.containsKey('worldFlagId') && json['worldFlagId'] is! String) {
      throw const FormatException('course.worldFlagId must be a string.');
    }
    if (json.containsKey('sectionNames') && json['sectionNames'] is! List) {
      throw const FormatException(
        'course.sectionNames must be a list of strings.',
      );
    }
    final fv = json['formatVersion'];
    if (fv != currentFormatVersion) {
      throw FormatException(
        'Unsupported course formatVersion: $fv. This version of QuisquisLingo supports Course Model format 12 only. Older course formats are not migrated or partially loaded; convert them with tools/convert_course_to_v12.dart.',
      );
    }
    if (json.containsKey('mergeProvenance') &&
        (json['mergeProvenance'] is! Map ||
            CourseOriginType.parse(json) != CourseOriginType.custom)) {
      throw const FormatException(
        'course.mergeProvenance must be an object on a custom Course.',
      );
    }
    for (final key in const [
      'minimumAppBuild',
      'estimatedStudyHours',
      'minimumAge',
    ]) {
      if (json.containsKey(key) && json[key] is! int) {
        throw FormatException('course.$key must be a whole number.');
      }
    }
    if (json.containsKey('keywords') &&
        (json['keywords'] is! List ||
            (json['keywords'] as List).any((entry) => entry is! String))) {
      throw const FormatException('course.keywords must be a list of strings.');
    }
    if (json.containsKey('coverImage') && json['coverImage'] is! String) {
      throw const FormatException('course.coverImage must be a string.');
    }
    if (json.containsKey('publisherContact') &&
        json['publisherContact'] is! Map) {
      throw const FormatException('course.publisherContact must be an object.');
    }
    _validateMediaReferences(json);
    for (final removed in const [
      'creatorProfileId',
      'ownership',
      'createdByProfileId',
      'createdByUsername',
      'createdAtUtc',
      'lastModifiedByProfileId',
      'lastModifiedByUsername',
      'lastModifiedAtUtc',
      'lastUpdated',
      'author',
      'version',
      'updateSummary',
      'contentRevision',
      'parentCourseId',
      'derivedFromVersion',
    ]) {
      if (json.containsKey(removed)) {
        throw FormatException(
          'Course Model formatVersion 12 does not support the obsolete course.$removed field.',
        );
      }
    }
    if (json.containsKey('topics')) {
      throw const FormatException(
        'Course Model formatVersion 12 does not support the legacy topics field.',
      );
    }
    if (json.containsKey('chapters')) {
      throw const FormatException(
        'Course Model formatVersion 12 does not support chapters.',
      );
    }
    if (json.containsKey('supportUrl')) {
      throw const FormatException(
        'Course Model formatVersion 12 uses buyACoffeeUrl, not supportUrl.',
      );
    }
    if (json.containsKey('buyACoffeeUrl') && json['buyACoffeeUrl'] is! String) {
      throw const FormatException('course.buyACoffeeUrl must be a string.');
    }
    for (final key in const ['courseVersion', 'versionNotes']) {
      if (json.containsKey(key) && json[key] is! String) {
        throw FormatException('course.$key must be a string.');
      }
    }
    if (json.containsKey('courseVersion') &&
        !RegExp(r'^[1-9][0-9]*$').hasMatch(json['courseVersion'] as String)) {
      throw const FormatException(
        'course.courseVersion must be a positive integer stored as a string.',
      );
    }
    if (json.containsKey('restoredFromVersion') &&
        (json['restoredFromVersion'] is! int ||
            (json['restoredFromVersion'] as int) < 1)) {
      throw const FormatException(
        'course.restoredFromVersion must be a positive integer.',
      );
    }
    final learning = _requiredString(json, 'learningLanguage', 'course');
    final interface = _requiredString(json, 'interfaceLanguage', 'course');
    final originType = CourseOriginType.parse(json);
    if (originType == CourseOriginType.custom) {
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
      ]) {
        if (json.containsKey(key)) {
          throw FormatException(
            'Course Model v11 custom courses do not support course.$key.',
          );
        }
      }
    } else {
      for (final key in const [
        'courseVersion',
        'versionNotes',
        'restoredFromVersion',
      ]) {
        if (json.containsKey(key)) {
          throw FormatException(
            'Course Model v11 official courses do not support course.$key.',
          );
        }
      }
    }
    final originalCourseCreator = json['originalCourseCreator'];
    if (originalCourseCreator is! Map) {
      throw const FormatException(
        'Course Model v11 requires course.originalCourseCreator.',
      );
    }
    final maintainer = json['maintainer'];
    if (json.containsKey('assignedTeamId') &&
        json['assignedTeamId'] is! String) {
      throw const FormatException('course.assignedTeamId must be a string.');
    }
    if (originType == CourseOriginType.custom && maintainer is! Map) {
      throw const FormatException(
        'Course Model v11 custom courses require an explicit course.maintainer.',
      );
    }
    if (originType.isOfficial && maintainer != null) {
      throw const FormatException(
        'Official courses cannot contain a custom Course Maintainer.',
      );
    }
    final originalCreatedAtUtc = _requiredString(
      json,
      'originalCreatedAtUtc',
      'course',
    );
    final modifiedAtUtc = _requiredString(json, 'modifiedAtUtc', 'course');
    final lastVersionEditorProfileId = originType == CourseOriginType.custom
        ? _requiredString(json, 'lastVersionEditorProfileId', 'course')
        : _optionalString(json, 'lastVersionEditorProfileId', '');
    final lastVersionEditorDisplayName = originType == CourseOriginType.custom
        ? _requiredString(json, 'lastVersionEditorDisplayName', 'course')
        : _optionalString(json, 'lastVersionEditorDisplayName', '');
    if (lastVersionEditorProfileId.isEmpty !=
        lastVersionEditorDisplayName.isEmpty) {
      throw const FormatException(
        'Course Model v11 requires both Last Version Editor identity fields when either is present.',
      );
    }
    return Course(
      formatVersion: fv as int,
      courseId: _requiredString(json, 'courseId', 'course'),
      originType: originType,
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
      originalCourseCreator: CourseProvenanceIdentity.fromJson(
        Map<String, dynamic>.from(originalCourseCreator),
      ),
      maintainer: maintainer is Map
          ? CourseMaintainer.fromJson(Map<String, dynamic>.from(maintainer))
          : null,
      assignedTeamId: _optionalString(json, 'assignedTeamId', '').isEmpty
          ? null
          : _optionalString(json, 'assignedTeamId', ''),
      originalCreatedAtUtc: originalCreatedAtUtc,
      lastVersionEditorProfileId: lastVersionEditorProfileId,
      lastVersionEditorDisplayName: lastVersionEditorDisplayName,
      modifiedAtUtc: modifiedAtUtc,
      versionNotes: _optionalString(json, 'versionNotes', ''),
      restoredFromVersion: json['restoredFromVersion'] as int?,
      publicationState: PublicationState.parseRequired(json, 'course'),
      lessonNumberingMode: LessonNumberingMode.parseRequired(json),
      customLessonLabel: _optionalString(json, 'customLessonLabel', ''),
      roundNumberingMode: RoundNumberingMode.parse(json),
      customRoundLabel: _optionalString(json, 'customRoundLabel', ''),
      defaultTimedLimitsSeconds:
          (json['defaultTimedLimitsSeconds'] as List<dynamic>? ?? const [])
              .map((value) => value as int)
              .toList(),
      pictureAnswers: PictureAnswerStyle.fromJson(json['pictureAnswers']),
      defaultLessonIconStyle: LessonFallbackIconStyle.parseRequired(json),
      createDuels: json['createDuels'] as bool? ?? true,
      useGuidebook: json['useGuidebook'] as bool? ?? true,
      allowPageSharing: json['allowPageSharing'] as bool? ?? true,
      wordLookup: json['wordLookup'] as bool? ?? true,
      sectionNames: _stringList(json, 'sectionNames'),
      learningLanguage: learning,
      interfaceLanguage: interface,
      sourceLanguage: _optionalString(json, 'sourceLanguage', interface),
      targetLanguage: _optionalString(json, 'targetLanguage', learning),
      title: _requiredString(json, 'title', 'course'),
      ttsLanguage: _requiredString(json, 'ttsLanguage', 'course'),
      audioMode: const {'tts', 'recorded', 'hybrid'}.contains(json['audioMode'])
          ? json['audioMode'] as String
          : 'tts',
      authors: json.containsKey('authors')
          ? json['authors'] is List
                ? (json['authors'] as List).map((entry) {
                    if (entry is! Map) {
                      throw const FormatException(
                        'course.authors entries must be objects.',
                      );
                    }
                    return CourseAuthor.fromJson(
                      Map<String, dynamic>.from(entry),
                    );
                  }).toList()
                : throw const FormatException('course.authors must be a list.')
          : const [],
      license: _optionalString(json, 'license', 'All rights reserved'),
      rightsHolders: (json['rightsHolders'] is List)
          ? (json['rightsHolders'] as List).map((entry) {
              if (entry is! Map) {
                throw const FormatException(
                  'course.rightsHolders entries must be objects.',
                );
              }
              return CourseRightsHolder.fromJson(
                Map<String, dynamic>.from(entry),
              );
            }).toList()
          : json.containsKey('rightsHolders')
          ? throw const FormatException('course.rightsHolders must be a list.')
          : const [],
      mediaAttributions: CourseMediaAttribution.parseList(
        json['mediaAttributions'],
      ),
      derivativeWorksPolicy: DerivativeWorksPolicy.parse(
        json['derivativeWorksPolicy'],
      ),
      forkProvenance: json.containsKey('forkProvenance')
          ? json['forkProvenance'] is Map
                ? CourseForkProvenance.fromJson(
                    Map<String, dynamic>.from(json['forkProvenance'] as Map),
                  )
                : throw const FormatException(
                    'course.forkProvenance must be an object.',
                  )
          : null,
      mergeProvenance: json.containsKey('mergeProvenance')
          ? CourseMergeProvenance.fromJson(
              Map<String, dynamic>.from(json['mergeProvenance'] as Map),
            )
          : null,
      minimumAppBuild: json['minimumAppBuild'] as int?,
      publisherContact: json.containsKey('publisherContact')
          ? CoursePublisherContact.fromJson(
              Map<String, dynamic>.from(json['publisherContact'] as Map),
            )
          : null,
      estimatedStudyHours: json['estimatedStudyHours'] as int?,
      minimumAge: json['minimumAge'] as int?,
      keywords: [...(json['keywords'] as List? ?? const []).cast<String>()],
      coverImage: _optionalString(json, 'coverImage', ''),
      languageVariant: _optionalString(json, 'languageVariant', ''),
      startLevel: _optionalString(json, 'startLevel', ''),
      targetLevel: _optionalString(json, 'targetLevel', ''),
      courseVersion: _optionalString(json, 'courseVersion', ''),
      courseDescription: _optionalString(json, 'courseDescription', ''),
      sourceLanguageTag: _optionalString(json, 'sourceLanguageTag', ''),
      targetLanguageTag: _optionalString(json, 'targetLanguageTag', ''),
      targetLanguageNameForLearners: _optionalString(
        json,
        'targetLanguageNameForLearners',
        '',
      ),
      textDirection: _optionalString(json, 'textDirection', 'ltr'),
      flagCode: _optionalString(json, 'flagCode', ''),
      flagImageBase64: _optionalString(json, 'flagImageBase64', ''),
      worldFlagId: _optionalString(json, 'worldFlagId', ''),
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
      imageLibrary: CourseImageLibraryEntry.parseList(json['imageLibrary']),
      storyNarrator: StorySpeaker.parseNarrator(json['storyNarrator']),
      storyCharacters: StorySpeaker.parseCharacters(json['storyCharacters']),
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

/// The picture a Words & Expressions entry stands for (Build 266): stored
/// like an exercise picture, a QQL picture (`assets/…`) or the Course's own
/// (`media:…`), with the Shared Image Library record it was copied from.
/// [plural] (Build 266, as exercise pictures since Build 265 Revision 11)
/// draws it as stacked copies: "i gatti = the cats".
class GuidebookPicture {
  final String asset;
  final SharedImageSource? sharedImageSource;
  final bool plural;

  const GuidebookPicture({
    required this.asset,
    this.sharedImageSource,
    this.plural = false,
  });

  /// The picture as an image element, as exercise pictures are: what the
  /// image walkers (`CourseImageUsage`) report.
  PromptElement get asImageElement => PromptElement(
    role: 'picture',
    type: 'image',
    asset: asset,
    sharedImageSource: sharedImageSource,
    plural: plural ? true : null,
  );

  GuidebookPicture withPlural(bool value) => GuidebookPicture(
    asset: asset,
    sharedImageSource: sharedImageSource,
    plural: value,
  );

  Map<String, dynamic> toJson() => {
    'asset': asset,
    if (sharedImageSource != null)
      'sharedImageSource': sharedImageSource!.toJson(),
    if (plural) 'plural': true,
  };

  static const _keys = {'asset', 'sharedImageSource', 'plural'};

  factory GuidebookPicture.fromJson(Map<String, dynamic> j, String where) {
    final unknown = j.keys.toSet().difference(_keys);
    if (unknown.isNotEmpty) {
      throw FormatException(
        '$where.picture has unknown keys: ${unknown.join(', ')}.',
      );
    }
    final asset = j['asset'];
    if (asset is! String ||
        asset.trim().isEmpty ||
        !Course.isValidImageReference(asset.trim())) {
      throw FormatException(
        '$where.picture.asset must be a QQL picture (assets/…), an embedded '
        'image or course media (media:<sha256>.<png|jpg|jpeg|webp>).',
      );
    }
    final plural = j['plural'];
    if (j.containsKey('plural') && plural is! bool) {
      throw FormatException('$where.picture.plural must be true or false.');
    }
    final shared = j['sharedImageSource'];
    if (j.containsKey('sharedImageSource') && shared is! Map) {
      throw FormatException(
        '$where.picture.sharedImageSource must be an object.',
      );
    }
    return GuidebookPicture(
      asset: asset.trim(),
      sharedImageSource: shared is Map
          ? SharedImageSource.fromJson(Map<String, dynamic>.from(shared))
          : null,
      plural: plural == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GuidebookPicture &&
      other.asset == asset &&
      other.plural == plural &&
      jsonEncode(other.sharedImageSource?.toJson()) ==
          jsonEncode(sharedImageSource?.toJson());

  @override
  int get hashCode => Object.hash(asset, plural);
}

/// One entry of a GuideBook module (Build 266): a sentence of Sentences or a
/// word or fixed expression of Words & Expressions.
///
/// [target] is in the language being learned and may mark optional words
/// with `{…}` (`GuidebookText`); [source] is its translation in the
/// learners' language; [context] (optional, at most 40 characters, in the
/// learners' language) names the sense, subject area, formality or who
/// speaks, and is never matched, read aloud or part of an answer. Only a
/// Words & Expressions entry may have a [picture].
class GuidebookEntry {
  final String id;
  final String target;
  final String source;
  final String context;
  final GuidebookPicture? picture;

  const GuidebookEntry({
    required this.id,
    required this.target,
    required this.source,
    this.context = '',
    this.picture,
  });

  GuidebookEntry copyWith({
    String? id,
    String? target,
    String? source,
    String? context,
    GuidebookPicture? picture,
    bool clearPicture = false,
  }) => GuidebookEntry(
    id: id ?? this.id,
    target: target ?? this.target,
    source: source ?? this.source,
    context: context ?? this.context,
    picture: clearPicture ? null : picture ?? this.picture,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'target': target,
    'source': source,
    if (context.isNotEmpty) 'context': context,
    if (picture != null) 'picture': picture!.toJson(),
  };

  static const _keys = {'id', 'target', 'source', 'context', 'picture'};

  factory GuidebookEntry.fromJson(
    Map<String, dynamic> j,
    String where, {
    required bool allowPicture,
  }) {
    final unknown = j.keys.toSet().difference(_keys);
    if (unknown.isNotEmpty) {
      throw FormatException('$where has unknown keys: ${unknown.join(', ')}.');
    }
    final target = _requiredString(j, 'target', where);
    final problem = GuidebookText.targetProblem(target);
    if (problem != null) {
      throw FormatException('$where.target “$target”: $problem.');
    }
    if (j.containsKey('context') && j['context'] is! String) {
      throw FormatException('$where.context must be a string.');
    }
    final context = _optionalString(j, 'context', '');
    if (context.length > GuidebookText.maxContextLength) {
      throw FormatException(
        '$where.context must be at most ${GuidebookText.maxContextLength} characters.',
      );
    }
    final rawPicture = j['picture'];
    if (j.containsKey('picture')) {
      if (!allowPicture) {
        throw FormatException(
          '$where cannot have a picture: only Words & Expressions entries do.',
        );
      }
      if (rawPicture is! Map) {
        throw FormatException('$where.picture must be an object.');
      }
    }
    return GuidebookEntry(
      id: _requiredString(j, 'id', where),
      target: target,
      source: _requiredString(j, 'source', where),
      context: context,
      picture: rawPicture is Map
          ? GuidebookPicture.fromJson(
              Map<String, dynamic>.from(rawPicture),
              where,
            )
          : null,
    );
  }
}

/// One short, coherent topic of a Lesson GuideBook (Build 266), its fields
/// in the owner's order: Title, Sentences, Words & Expressions, Overview.
class GuidebookModule {
  final String id;
  final String title;
  final List<GuidebookEntry> sentences;
  final List<GuidebookEntry> words;
  final String overview;

  GuidebookModule({
    required this.id,
    required this.title,
    List<GuidebookEntry> sentences = const [],
    List<GuidebookEntry> words = const [],
    this.overview = '',
  }) : sentences = List.unmodifiable(sentences),
       words = List.unmodifiable(words);

  /// Every entry, Sentences first, in order.
  Iterable<GuidebookEntry> get entries sync* {
    yield* sentences;
    yield* words;
  }

  /// No sentence and no Words & Expressions entry.
  bool get hasNoEntries => sentences.isEmpty && words.isEmpty;

  GuidebookModule copyWith({
    String? id,
    String? title,
    List<GuidebookEntry>? sentences,
    List<GuidebookEntry>? words,
    String? overview,
  }) => GuidebookModule(
    id: id ?? this.id,
    title: title ?? this.title,
    sentences: sentences ?? this.sentences,
    words: words ?? this.words,
    overview: overview ?? this.overview,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sentences': sentences.map((e) => e.toJson()).toList(),
    'words': words.map((e) => e.toJson()).toList(),
    'overview': overview,
  };

  static const _keys = {'id', 'title', 'sentences', 'words', 'overview'};

  factory GuidebookModule.fromJson(Map<String, dynamic> j) {
    final unknown = j.keys.toSet().difference(_keys);
    if (unknown.isNotEmpty) {
      throw FormatException(
        'guidebook module has unknown keys: ${unknown.join(', ')}.',
      );
    }
    if (j.containsKey('overview') && j['overview'] is! String) {
      throw const FormatException(
        'guidebook module.overview must be a string.',
      );
    }
    List<GuidebookEntry> entries(String key, {required bool allowPicture}) {
      if (!j.containsKey(key)) return const [];
      return _mapList(
        j,
        key,
        'guidebook module',
        (value) => GuidebookEntry.fromJson(
          value,
          'guidebook module.$key entry',
          allowPicture: allowPicture,
        ),
      );
    }

    return GuidebookModule(
      id: _requiredString(j, 'id', 'guidebook module'),
      title: _requiredString(j, 'title', 'guidebook module'),
      sentences: entries('sentences', allowPicture: false),
      words: entries('words', allowPicture: true),
      overview: (j['overview'] as String? ?? '').trim(),
    );
  }
}

/// A Lesson's GuideBook (Build 266, GuideBook Modules): an ordered list of
/// modules in teaching order. The whole GuideBook is Draft or Published;
/// there is no module-level or entry-level Draft.
class Guidebook {
  final PublicationState publicationState;
  final List<GuidebookModule> modules;

  Guidebook({
    this.publicationState = PublicationState.published,
    List<GuidebookModule> modules = const [],
  }) : modules = List.unmodifiable(modules);

  factory Guidebook.empty() => Guidebook();

  /// The message for a file in the shape before Build 266.
  static const earlierShapeMessage =
      'This Course\'s GuideBooks use the earlier shape. Since build 266 a '
      'GuideBook is a list of modules: regenerate the Course.';

  /// No module has an entry (or there is no module).
  bool get hasNoEntries => modules.every((module) => module.hasNoEntries);

  /// Every entry of every module, module by module.
  Iterable<GuidebookEntry> get entries =>
      modules.expand((module) => module.entries);

  /// Every Words & Expressions entry, module by module.
  Iterable<GuidebookEntry> get words =>
      modules.expand((module) => module.words);

  /// Every sentence, module by module.
  Iterable<GuidebookEntry> get sentences =>
      modules.expand((module) => module.sentences);

  /// The IDs of the modules and of their entries.
  Set<String> get ids => {
    for (final module in modules) ...[
      module.id,
      for (final entry in module.entries) entry.id,
    ],
  };

  GuidebookModule? moduleById(String id) {
    for (final module in modules) {
      if (module.id == id) return module;
    }
    return null;
  }

  Guidebook copyWith({
    PublicationState? publicationState,
    List<GuidebookModule>? modules,
  }) => Guidebook(
    publicationState: publicationState ?? this.publicationState,
    modules: modules ?? this.modules,
  );

  Map<String, dynamic> toJson() => {
    if (!publicationState.isPublished)
      'publicationState': publicationState.name,
    'modules': modules.map((e) => e.toJson()).toList(),
  };

  static const _keys = {'publicationState', 'modules'};

  factory Guidebook.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('content') || j.containsKey('insights')) {
      throw const FormatException(earlierShapeMessage);
    }
    final unknown = j.keys.toSet().difference(_keys);
    if (unknown.isNotEmpty) {
      throw FormatException(
        'guidebook has unknown keys: ${unknown.join(', ')}.',
      );
    }
    return Guidebook(
      publicationState: j.containsKey('publicationState')
          ? PublicationState.parseRequired(j, 'guidebook')
          : PublicationState.published,
      modules: _mapList(j, 'modules', 'guidebook', GuidebookModule.fromJson),
    );
  }
}

class Lesson {
  final String lessonId;
  final PublicationState publicationState;

  /// Marks an automatically created Draft eligible for explicit-save
  /// reconciliation. Missing legacy values are false; this never changes
  /// learner visibility without a publication-state transition.
  final bool provisionalDraft;
  final DateTime updatedAt;
  final String title;
  final List<LearningRound> rounds;
  final bool section;
  final String? sectionName;
  final String? themeIconAsset;
  final Guidebook guidebook;
  final Duel duel;

  /// A Lesson owns exactly one GuideBook. This newly defined internal identity
  /// derives from that immutable ownership; it is not a stored Content ID.
  /// Rename/reorder/Move preserve it, while a copied Lesson receives a new one.
  String get guidebookId => '${lessonId}_guidebook';
  Lesson({
    required this.lessonId,
    this.publicationState = PublicationState.published,
    this.provisionalDraft = false,
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
    if (provisionalDraft) 'provisionalDraft': true,
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
    if (j.containsKey('provisionalDraft') && j['provisionalDraft'] is! bool) {
      throw const FormatException('lesson.provisionalDraft must be a boolean.');
    }
    if (j.containsKey('id') || j.containsKey('topicId')) {
      throw const FormatException(
        'Course Model formatVersion 12 Lessons require lessonId and reject legacy Lesson identity fields.',
      );
    }
    if (j.containsKey('role') || j.containsKey('assessment')) {
      throw const FormatException(
        'Course Model formatVersion 12 Lessons do not support role or assessment fields.',
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
        'Course Model formatVersion 12 Lessons do not support the obsolete imageAsset field.',
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
        !LessonIconCatalog.isLibraryPicture(themeIconAsset) &&
        (!themeIconAsset.startsWith('assets/lesson_icons/') ||
            !themeIconAsset.toLowerCase().endsWith('.png'))) {
      throw const FormatException(
        'lesson.themeIconAsset must reference a preinstalled Lesson icon, a QQL picture of the image library or a managed Course-owned Lesson icon.',
      );
    }
    return Lesson(
      lessonId: _requiredString(j, 'lessonId', 'lesson'),
      publicationState: PublicationState.parseRequired(j, 'lesson'),
      provisionalDraft: j['provisionalDraft'] as bool? ?? false,
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

enum RoundType {
  discover,
  practice,
  sequence,
  listening,
  reading,
  story,
  flashcard,
  test,
  timed,
  speak;

  static RoundType fromJson(Object? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    throw const FormatException('round.roundType is invalid.');
  }
}

class LearningRound {
  static const validVisualTypes = {'listening', 'story', 'generic', 'test'};
  final String id;
  final PublicationState publicationState;

  /// Automatic-publication eligibility, independent from the current state.
  /// Explicit Draft saves clear this marker; legacy missing values stay false.
  final bool provisionalDraft;
  final DateTime updatedAt;
  final String title;
  final String visualType;
  final RoundType roundType;

  /// Test-only presentation settings. Neither changes completion or XP.
  final bool testFixedOrder;
  final int? testPassingPercent;

  /// Ordered author-defined time limits; the learner unlocks them in order.
  final List<int> timedLimitsSeconds;
  final List<LearningContent> content;

  /// Course Model v12: how the content and exercise nodes are ordered or
  /// branched. Null means today's practice Round (lesson_intro first, then
  /// shuffled exercises, then the mistake review).
  final ContentFlow? flow;

  /// Build 266 (GuideBook Modules): the module of the Lesson's GuideBook
  /// this Round is about, and the earlier modules whose material it also
  /// uses. Stored only when set; only Open GuideBook reads them (it scrolls
  /// to the focus module). They change no scoring, progression, order,
  /// Review or Duel.
  final String? focusModuleId;
  final List<String> supportingModuleIds;
  LearningRound({
    required this.id,
    this.publicationState = PublicationState.published,
    this.provisionalDraft = false,
    DateTime? updatedAt,
    required this.title,
    this.visualType = 'generic',
    RoundType? roundType,
    this.testFixedOrder = false,
    this.testPassingPercent,
    this.timedLimitsSeconds = const [],
    List<LearningContent>? content,
    List<Exercise>? exercises,
    this.flow,
    String? focusModuleId,
    List<String> supportingModuleIds = const [],
  }) : focusModuleId = focusModuleId?.trim().isEmpty == true
           ? null
           : focusModuleId?.trim(),
       supportingModuleIds = List.unmodifiable(supportingModuleIds),
       assert(
         testPassingPercent == null ||
             (testPassingPercent >= 0 && testPassingPercent <= 100),
       ),
       updatedAt = _canonicalUtcTimestamp(updatedAt),
       roundType =
           roundType ??
           (flow == null
               ? RoundType.practice
               : visualType == storyVisualType
               ? RoundType.story
               : RoundType.sequence),
       content =
           content ??
           [
             for (final e in exercises ?? const <Exercise>[])
               LearningContent.fromExercise(e),
           ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'publicationState': publicationState.name,
    if (provisionalDraft) 'provisionalDraft': true,
    'updatedAt': _timestampToJson(updatedAt),
    if (title.trim().isNotEmpty) 'title': title.trim(),
    'visualType': visualType,
    'roundType': roundType.name,
    if (roundType == RoundType.test) 'testFixedOrder': testFixedOrder,
    if (roundType == RoundType.test && testPassingPercent != null)
      'testPassingPercent': testPassingPercent,
    if (roundType == RoundType.timed) 'timedLimitsSeconds': timedLimitsSeconds,
    'content': content.map((e) => e.toJson()).toList(),
    if (flow != null) 'flow': flow!.toJson(),
    if (focusModuleId != null) 'focusModuleId': focusModuleId,
    if (supportingModuleIds.isNotEmpty)
      'supportingModuleIds': supportingModuleIds,
  };

  /// This Round with its module links changed (Build 266).
  LearningRound withModules({
    required String? focusModuleId,
    required List<String> supportingModuleIds,
  }) => LearningRound.fromJson({
    ...toJson()
      ..remove('focusModuleId')
      ..remove('supportingModuleIds'),
    if (focusModuleId != null && focusModuleId.trim().isNotEmpty)
      'focusModuleId': focusModuleId.trim(),
    if (supportingModuleIds.isNotEmpty)
      'supportingModuleIds': supportingModuleIds,
  });

  factory LearningRound.fromJson(Map<String, dynamic> j) {
    final rawFlow = j['flow'];
    if (j.containsKey('flow') && rawFlow is! Map) {
      throw const FormatException('round.flow must be an object.');
    }
    if (j.containsKey('provisionalDraft') && j['provisionalDraft'] is! bool) {
      throw const FormatException('round.provisionalDraft must be a boolean.');
    }
    final visualType = j['visualType'];
    if (visualType is! String || !validVisualTypes.contains(visualType)) {
      throw FormatException(
        'round.visualType must be one of ${validVisualTypes.join(', ')}.',
      );
    }
    final content = _mapList(j, 'content', 'round', LearningContent.fromJson);
    final roundType = j.containsKey('roundType')
        ? RoundType.fromJson(j['roundType'])
        : rawFlow == null &&
              visualType == 'listening' &&
              content.where((entry) => entry.required).isNotEmpty &&
              content.where((entry) => entry.required).every((entry) {
                final exercise = entry.asRunnableExercise();
                return exercise != null &&
                    RoundTypeCompatibility.audioEssential(exercise);
              })
        ? RoundType.listening
        : null;
    final passing = j['testPassingPercent'];
    if (passing != null && (passing is! int || passing < 0 || passing > 100)) {
      throw const FormatException('round.testPassingPercent must be 0–100.');
    }
    if (j.containsKey('testFixedOrder') && j['testFixedOrder'] is! bool) {
      throw const FormatException('round.testFixedOrder must be a boolean.');
    }
    final rawFocus = j['focusModuleId'];
    if (j.containsKey('focusModuleId') &&
        (rawFocus is! String || rawFocus.trim().isEmpty)) {
      throw const FormatException(
        'round.focusModuleId must be a non-empty string.',
      );
    }
    final rawSupporting = j['supportingModuleIds'];
    if (j.containsKey('supportingModuleIds')) {
      if (rawSupporting is! List ||
          rawSupporting.any((v) => v is! String || v.trim().isEmpty)) {
        throw const FormatException(
          'round.supportingModuleIds must be a list of module IDs.',
        );
      }
      final ids = [for (final v in rawSupporting) (v as String).trim()];
      if (ids.toSet().length != ids.length) {
        throw const FormatException(
          'round.supportingModuleIds must not repeat a module.',
        );
      }
      if (rawFocus is String && ids.contains(rawFocus.trim())) {
        throw const FormatException(
          'round.supportingModuleIds must not contain the focus module.',
        );
      }
    }
    final rawTimedLimits = j['timedLimitsSeconds'];
    if (rawTimedLimits != null &&
        (rawTimedLimits is! List ||
            rawTimedLimits.any((value) => value is! int))) {
      throw const FormatException(
        'round.timedLimitsSeconds must be an integer list.',
      );
    }
    return LearningRound(
      id: _requiredString(j, 'id', 'round'),
      publicationState: PublicationState.parseRequired(j, 'round'),
      provisionalDraft: j['provisionalDraft'] as bool? ?? false,
      updatedAt: _requiredUtcTimestamp(j, 'updatedAt', 'round'),
      title: _optionalString(j, 'title', ''),
      visualType: visualType,
      roundType: roundType,
      testFixedOrder: j['testFixedOrder'] as bool? ?? false,
      testPassingPercent: passing as int?,
      timedLimitsSeconds: rawTimedLimits == null
          ? const []
          : List<int>.from(rawTimedLimits as List),
      content: content,
      flow: rawFlow is Map
          ? ContentFlow.fromJson(Map<String, dynamic>.from(rawFlow))
          : null,
      focusModuleId: rawFocus as String?,
      supportingModuleIds: rawSupporting == null
          ? const []
          : [for (final v in rawSupporting as List) (v as String).trim()],
    );
  }

  /// Current learner/editor widgets consume this derived runnable view. It is
  /// generated from v6 Content and therefore does not preserve a legacy file model.
  List<Exercise> get exercises => content
      .where((c) => c.role != 'lesson_intro')
      .map((c) => c.asRunnableExercise())
      .whereType<Exercise>()
      .toList(growable: false);

  /// The prefix every list shows before a Story's title (Build 256
  /// Revision 5 follow-up); derived here, never stored in [title].
  static const storyTitlePrefix = 'Story: ';

  /// The prefix every list shows before a sequence's title (Build 256
  /// Revision 7, third follow-up); derived like the Story prefix.
  static const sequenceTitlePrefix = 'Sequence: ';

  /// The visual type New Story gives a Story.
  static const storyVisualType = 'story';

  /// A Round with a content flow and the `story` visual type is a Story:
  /// what New Story creates (owner decision, 29 September 2026).
  bool get isStory => flow != null && roundType == RoundType.story;

  /// A Round with a content flow and any other visual type is a sequence: a
  /// plain Round played in the authored order (New Round with Play as a
  /// sequence).
  bool get isSequence => flow != null && roundType == RoundType.sequence;

  /// A Story's own title, or a sequence's optional one: the flow's, else the
  /// Round title without a prefix an earlier build stored.
  String get storyTitle {
    final own = flow?.title.trim() ?? '';
    return own.isNotEmpty ? own : withoutStoryPrefix(title);
  }

  static String withoutStoryPrefix(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith(storyTitlePrefix)
        ? trimmed.substring(storyTitlePrefix.length).trim()
        : trimmed;
  }

  /// What lists, the Lesson path, Search, Review and the Round screen call
  /// this Round: "Story: <title>" for a Story, "Sequence: <title>" for a
  /// sequence, else the title or "Round N".
  String displayTitle(int position) {
    if (flow != null) {
      final own = storyTitle;
      final prefix = isStory ? storyTitlePrefix : sequenceTitlePrefix;
      return '$prefix${own.isEmpty ? 'Round ${position + 1}' : own}';
    }
    final custom = title.trim();
    return custom.isEmpty ? 'Round ${position + 1}' : custom;
  }
}

class LearningContent {
  final String id;
  final PublicationState publicationState;
  final String _kind;
  final bool required;
  final String role;
  final Exercise? _exercise;
  final String text;
  final List<String> sourceRefs;
  final String _editorTemplate;
  final Map<String, Object?> _authoringMetadata;

  /// The v11 presentation shape, kept only as a construction helper: since
  /// Course Model v12 a Presentation is an exercise whose primitive is
  /// `presentation`, which [exercise] returns.
  final Presentation? _presentation;

  /// Course Model v12: every exercise, Presentation included, is
  /// `kind: exercise`. A [presentation] or a `presentation` kind given here
  /// reads back as an exercise, and an [editorTemplate] reads back as the
  /// `presetId` of [authoringMetadata]; both views are derived so this
  /// constructor stays const.
  const LearningContent({
    required this.id,
    this.publicationState = PublicationState.published,
    required String kind,
    this.required = true,
    String editorTemplate = '',
    Map<String, Object?>? authoringMetadata,
    this.role = '',
    Exercise? exercise,
    Presentation? presentation,
    this.text = '',
    this.sourceRefs = const [],
  }) : _kind = kind,
       _exercise = exercise,
       _presentation = presentation,
       _editorTemplate = editorTemplate,
       _authoringMetadata = authoringMetadata ?? const {};

  static bool _sameMetadata(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// The metadata this Content was given: its own map plus the preset named
  /// by the constructor's `editorTemplate`.
  Map<String, Object?> get _givenMetadata => _editorTemplate.isEmpty
      ? _authoringMetadata
      : {
          ..._authoringMetadata,
          'presetId': presetSuccessorOf[_editorTemplate] ?? _editorTemplate,
        };

  String get kind =>
      (_presentation != null && _exercise == null) || _kind == 'presentation'
      ? 'exercise'
      : _kind;

  /// The exercise this Content holds, with the constructor's preset and
  /// metadata applied; a given [Presentation] becomes a `presentation`
  /// exercise here.
  Exercise? get exercise {
    final given = _givenMetadata;
    final exercise = _exercise;
    if (exercise != null) {
      return given.isEmpty || _sameMetadata(given, exercise.authoringMetadata)
          ? exercise
          : exercise.withAuthoringMetadata(given);
    }
    final presentation = _presentation;
    if (presentation == null) return null;
    return presentation.toExercise(
      id: id,
      publicationState: publicationState,
      authoringMetadata: given.isEmpty
          ? const {'presetId': 'flashcard'}
          : given,
    );
  }

  /// The authoring metadata this Content carries: the exercise's when it
  /// has one, else its own (textual Content rarely has any).
  Map<String, Object?> get authoringMetadata =>
      exercise?.authoringMetadata ?? _givenMetadata;

  /// The preset that authored this Content's exercise, or an empty string.
  /// Never read by anything learners see.
  String get editorTemplate {
    final preset = authoringMetadata['presetId'];
    return preset is String ? preset.trim() : '';
  }

  /// A Presentation view of a `presentation`-primitive exercise, for callers
  /// that still copy presentations; null otherwise.
  Presentation? get presentation {
    final exercise = this.exercise;
    return exercise?.primitive == ExercisePrimitive.presentation
        ? Presentation.fromExercise(exercise!)
        : null;
  }

  factory LearningContent.fromExercise(Exercise e) {
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
    if (authoringMetadata.isNotEmpty) 'authoringMetadata': authoringMetadata,
    // Build 267 Revision 8: the author's notes, only when there are some.
    if (exercise?.editorNotes.isNotEmpty ?? false)
      'editorNotes': exercise!.editorNotes,
    if (role.isNotEmpty) 'role': role,
    if (sourceRefs.isNotEmpty) 'sourceRefs': sourceRefs,
    if (exercise != null) 'exercise': exercise!.toJson(),
    if (text.isNotEmpty) 'text': text,
  };
  factory LearningContent.fromJson(Map<String, dynamic> j) {
    final kind = _requiredString(j, 'kind', 'content');
    if (j.containsKey('editorTemplate')) {
      throw const FormatException(
        'Course Model formatVersion 12 records the authoring preset in content.authoringMetadata.presetId, not editorTemplate. Convert the Course with tools/convert_course_to_v12.dart.',
      );
    }
    if (kind == 'presentation' || j.containsKey('presentation')) {
      throw const FormatException(
        'Course Model formatVersion 12 has no presentation Content: a Presentation is an exercise whose primitive is presentation. Convert the Course with tools/convert_course_to_v12.dart.',
      );
    }
    final publicationState = PublicationState.parseRequired(j, 'content');
    final rawMetadata = j['authoringMetadata'];
    if (j.containsKey('authoringMetadata') && rawMetadata is! Map) {
      throw const FormatException(
        'content.authoringMetadata must be an object.',
      );
    }
    final metadata = <String, Object?>{
      if (rawMetadata is Map)
        for (final entry in rawMetadata.entries)
          entry.key.toString(): entry.value,
    };
    if (metadata.containsKey('presetId') && metadata['presetId'] is! String) {
      throw const FormatException(
        'content.authoringMetadata.presetId must be a string.',
      );
    }
    final ex = j['exercise'];
    if (kind == 'exercise' && ex is! Map) {
      throw const FormatException('Exercise Content needs an exercise object.');
    }
    final notes = j['editorNotes'];
    if (j.containsKey('editorNotes')) {
      if (notes is! String) {
        throw const FormatException('content.editorNotes must be a string.');
      }
      if (notes.length > Exercise.maxEditorNotesLength) {
        throw const FormatException(
          'content.editorNotes is longer than '
          '${Exercise.maxEditorNotesLength} characters.',
        );
      }
      if (ex is! Map) {
        throw const FormatException(
          'content.editorNotes belongs to Content with an exercise.',
        );
      }
    }
    if (kind != 'exercise' && ex != null) {
      throw FormatException('Content of kind $kind cannot carry an exercise.');
    }
    return LearningContent(
      id: _requiredString(j, 'id', 'content'),
      publicationState: publicationState,
      kind: kind,
      required: j['required'] != false,
      authoringMetadata: metadata,
      role: _optionalString(j, 'role', ''),
      exercise: ex is Map
          ? Exercise.fromJson(
              Map<String, dynamic>.from(ex),
              contentId: _requiredString(j, 'id', 'content'),
              authoringMetadata: metadata,
              publicationState: publicationState,
              editorNotes: notes is String ? notes : '',
            )
          : null,
      text: _optionalString(j, 'text', ''),
      sourceRefs: _stringList(j, 'sourceRefs'),
    );
  }
  Exercise? asRunnableExercise() {
    if (kind == 'exercise') return exercise;
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

/// The v11 presentation shape. Since Course Model v12 a Presentation is an
/// exercise whose primitive is `presentation`; this class remains the
/// converter's input and a construction helper, and [toExercise] is the one
/// mapping between the two.
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

  /// The v11 view of a `presentation`-primitive exercise. An omitted
  /// completion mode is the registry default, `proceed`, as the runtime
  /// reads it.
  factory Presentation.fromExercise(Exercise e) => Presentation(
    content: e.promptElements,
    actions: switch (e.options.enumValue<CompletionMode>(
      OptionKey.completionMode,
    )) {
      CompletionMode.understoodReview => const ['understood', 'review_later'],
      CompletionMode.proceed || null => const ['continue'],
      CompletionMode.acknowledge => const ['acknowledge'],
      CompletionMode.automatic => const [],
    },
  );

  /// The completion mode the v11 actions mean.
  CompletionMode get completionMode {
    if (actions.contains('understood') || actions.contains('review_later')) {
      return CompletionMode.understoodReview;
    }
    if (actions.isEmpty) return CompletionMode.automatic;
    if (actions.contains('acknowledge')) return CompletionMode.acknowledge;
    return CompletionMode.proceed;
  }

  /// The canonical exercise this presentation is.
  Exercise toExercise({
    required String id,
    PublicationState publicationState = PublicationState.published,
    DateTime? updatedAt,
    Map<String, Object?> authoringMetadata = const {'presetId': 'flashcard'},
  }) => Exercise.canonical(
    id: id,
    publicationState: publicationState,
    updatedAt: updatedAt,
    primitive: ExercisePrimitive.presentation,
    options: completionMode == CompletionMode.proceed
        ? PrimitiveOptions.empty
        : PrimitiveOptions({
            OptionKey.completionMode: EnumOptionValue(completionMode),
          }),
    promptElements: content,
    canonicalEvaluation: CanonicalEvaluation.none,
    authoringMetadata: authoringMetadata,
  );

  Exercise asLegacyExercise({
    required String id,
    required String template,
    PublicationState publicationState = PublicationState.published,
  }) => toExercise(
    id: id,
    publicationState: publicationState,
    authoringMetadata: template.isEmpty
        ? const {'presetId': 'flashcard'}
        : {'presetId': template},
  );
}

class SharedImageSource {
  final String id;
  final String label;
  final String category;
  final List<String> tags;
  final String origin;
  final ImageAttribution? attribution;

  const SharedImageSource({
    required this.id,
    required this.label,
    required this.category,
    required this.tags,
    required this.origin,
    this.attribution,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category,
    'tags': tags,
    'origin': origin,
    if (attribution != null) 'attribution': attribution!.toJson(),
  };

  factory SharedImageSource.fromJson(Map<String, dynamic> json) {
    if (json.keys.toSet().difference({
      'id',
      'label',
      'category',
      'tags',
      'origin',
      'attribution',
    }).isNotEmpty) {
      throw const FormatException('sharedImageSource has unsupported fields.');
    }
    final id = _requiredString(json, 'id', 'sharedImageSource');
    final label = _requiredString(json, 'label', 'sharedImageSource');
    final category = _requiredString(json, 'category', 'sharedImageSource');
    final origin = _requiredString(json, 'origin', 'sharedImageSource');
    final tags = _stringList(json, 'tags');
    final rawAttribution = json['attribution'];
    Map<String, dynamic>? attributionJson;
    if (rawAttribution != null) {
      if (rawAttribution is! Map) {
        throw const FormatException('Invalid shared image attribution.');
      }
      try {
        attributionJson = Map<String, dynamic>.from(rawAttribution);
      } catch (_) {
        throw const FormatException('Invalid shared image attribution.');
      }
    }
    if (origin == 'bundled' ||
        tags.isEmpty ||
        [id, label, category, origin].any((value) => value.length > 500) ||
        tags.length > 100 ||
        tags.any((tag) => tag.trim().isEmpty || tag.length > 500)) {
      throw const FormatException('Invalid sharedImageSource metadata.');
    }
    return SharedImageSource(
      id: id,
      label: label,
      category: category,
      tags: List.unmodifiable(tags),
      origin: origin,
      attribution: attributionJson == null
          ? null
          : ImageAttribution.fromJson(attributionJson),
    );
  }
}

/// An image a Course keeps in its own library without using it yet.
class CourseImageLibraryEntry {
  const CourseImageLibraryEntry({
    required this.asset,
    this.sharedImageSource,
    this.label = '',
    this.category = '',
    this.tags = const [],
    this.attribution,
  });

  /// A Course media image: `media:<sha256>.<png|jpg|jpeg|webp>`.
  final String asset;

  /// The Shared Image Library record the image was copied from, if any.
  final SharedImageSource? sharedImageSource;

  /// Optional name, category and tags, for example from an Image Bank
  /// imported into this Course. Course-scoped: they never change a device's
  /// Shared Image Library.
  final String label;
  final String category;
  final List<String> tags;
  final ImageAttribution? attribution;

  static const maxLabelLength = 200;
  static const maxTags = 32;
  static const maxTagLength = 80;
  static final _category = RegExp(r'^[a-z][a-z0-9_]{1,39}$');
  static final _control = RegExp(r'[\x00-\x1F\x7F]');

  Map<String, dynamic> toJson() => {
    'asset': asset,
    if (sharedImageSource != null)
      'sharedImageSource': sharedImageSource!.toJson(),
    if (label.isNotEmpty) 'label': label,
    if (category.isNotEmpty) 'category': category,
    if (tags.isNotEmpty) 'tags': tags,
    if (attribution != null) 'attribution': attribution!.toJson(),
  };

  factory CourseImageLibraryEntry.fromJson(Map<String, dynamic> json) {
    if (json.keys.toSet().difference({
      'asset',
      'sharedImageSource',
      'label',
      'category',
      'tags',
      'attribution',
    }).isNotEmpty) {
      throw const FormatException('imageLibrary entry has unsupported fields.');
    }
    final asset = json['asset'];
    if (asset is! String || !Course.coverImagePattern.hasMatch(asset)) {
      throw const FormatException(
        'imageLibrary entries must be media:<sha256>.<png|jpg|jpeg|webp> images.',
      );
    }
    final source = json['sharedImageSource'];
    if (source != null && source is! Map) {
      throw const FormatException(
        'imageLibrary sharedImageSource must be an object.',
      );
    }
    final attribution = json['attribution'];
    if (attribution != null && attribution is! Map) {
      throw const FormatException(
        'imageLibrary attribution must be an object.',
      );
    }
    final tags = json['tags'] ?? const [];
    if (tags is! List || tags.any((tag) => tag is! String)) {
      throw const FormatException('imageLibrary tags must be strings.');
    }
    return CourseImageLibraryEntry.checked(
      asset: asset,
      sharedImageSource: source == null
          ? null
          : SharedImageSource.fromJson(Map<String, dynamic>.from(source)),
      label: json['label'] is String ? json['label'] as String : '',
      category: json['category'] is String ? json['category'] as String : '',
      tags: tags.cast<String>(),
      attribution: attribution == null
          ? null
          : ImageAttribution.fromJson(Map<String, dynamic>.from(attribution)),
    );
  }

  /// Builds an entry from outside data (JSON or an Image Bank manifest),
  /// enforcing the limits: label 1–200 characters, category a lowercase
  /// name, at most 32 tags of 80 characters, no control characters.
  factory CourseImageLibraryEntry.checked({
    required String asset,
    SharedImageSource? sharedImageSource,
    String label = '',
    String category = '',
    List<String> tags = const [],
    ImageAttribution? attribution,
  }) {
    final cleanLabel = label.trim();
    final cleanTags = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    if (cleanLabel.length > maxLabelLength ||
        _control.hasMatch(cleanLabel) ||
        (category.isNotEmpty && !_category.hasMatch(category)) ||
        cleanTags.length > maxTags ||
        cleanTags.any(
          (tag) => tag.length > maxTagLength || _control.hasMatch(tag),
        )) {
      throw FormatException('imageLibrary metadata for $asset is invalid.');
    }
    return CourseImageLibraryEntry(
      asset: asset,
      sharedImageSource: sharedImageSource,
      label: cleanLabel,
      category: category,
      tags: List.unmodifiable(cleanTags),
      attribution: attribution,
    );
  }

  /// Parses the optional `imageLibrary` list: each asset at most once.
  static List<CourseImageLibraryEntry> parseList(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('course.imageLibrary must be a list.');
    }
    final out = <CourseImageLibraryEntry>[];
    final seen = <String>{};
    for (final entry in value) {
      if (entry is! Map) {
        throw const FormatException(
          'course.imageLibrary entries must be objects.',
        );
      }
      final parsed = CourseImageLibraryEntry.fromJson(
        Map<String, dynamic>.from(entry),
      );
      if (!seen.add(parsed.asset)) {
        throw FormatException(
          'course.imageLibrary lists ${parsed.asset} more than once.',
        );
      }
      out.add(parsed);
    }
    return List.unmodifiable(out);
  }
}

class PromptElement {
  final String role;
  final String type;
  final String text;
  final String asset;
  final String speaker;

  /// Build 256 Revision 5: the Story character who says a dialogue line
  /// (`Course.storyCharacters`); empty means the narrator.
  final String speakerId;
  final SharedImageSource? sharedImageSource;

  /// Course Model v12: the language a text element is in (absent means
  /// unspecified, treated as the target language).
  final TextLanguage? language;

  /// Course Model v12: whether an audio element plays by itself when the
  /// exercise becomes active. Absent means manual.
  final AudioPlayback? playback;

  /// Course Model v12: whether an audio element is needed to solve the
  /// exercise, so the exercise is skipped when audio is unavailable. Absent
  /// means true.
  final bool? required;

  /// Build 258 (Page blocks): how a text element is drawn; absent means a
  /// paragraph. Text elements only.
  final BlockTextStyle? textStyle;

  /// Build 258: where a text, picture or link sits across the page; absent
  /// means start for text and links, center for pictures. Justify is for
  /// body text only.
  final BlockAlign? align;

  /// Build 258: a text element's colour from the named palette; absent
  /// means the theme's text colour.
  final BlockColor? color;

  /// Build 258: how wide a picture is drawn; absent means medium.
  final BlockSize? size;

  /// Build 258: whether a text element offers a read-aloud button; absent
  /// means no.
  final bool? readAloud;

  /// Build 258: the web address of a `link` element (a video or a page on
  /// the web, opened in the browser); its label is [text].
  final String url;

  /// Build 265 Revision 11 (owner decision of 7 October 2026): the picture
  /// stands for several things ("cats", not "cat") and is drawn as stacked
  /// copies. Image elements and `icon` elements only; absent means one.
  final bool? plural;

  const PromptElement({
    this.role = 'primary',
    required this.type,
    this.text = '',
    this.asset = '',
    this.speaker = '',
    this.speakerId = '',
    this.sharedImageSource,
    this.language,
    this.playback,
    this.required,
    this.textStyle,
    this.align,
    this.color,
    this.size,
    this.readAloud,
    this.url = '',
    this.plural,
  });

  bool get isAudio => type == 'audio';

  /// Whether the picture is drawn as several (Build 265 Revision 11).
  bool get isPlural => plural ?? false;

  /// This element marked plural, or with the mark removed (a plain copy
  /// cannot clear it).
  PromptElement withPlural(bool value) => PromptElement(
    role: role,
    type: type,
    text: text,
    asset: asset,
    speaker: speaker,
    speakerId: speakerId,
    sharedImageSource: sharedImageSource,
    language: language,
    playback: playback,
    required: required,
    textStyle: textStyle,
    align: align,
    color: color,
    size: size,
    readAloud: readAloud,
    url: url,
    plural: value ? true : null,
  );
  bool get isText => type == 'text';
  bool get isImage => type == 'image';

  /// Build 258: a web link (label in [text], address in [url]).
  bool get isLink => type == 'link';

  /// The effective playback of an audio element.
  AudioPlayback get effectivePlayback => playback ?? AudioPlayback.manual;

  /// The effective requirement of an audio element.
  bool get isRequired => required ?? true;

  PromptElement copyWith({
    String? role,
    String? type,
    String? text,
    String? asset,
    String? speaker,
    String? speakerId,
    SharedImageSource? sharedImageSource,
    TextLanguage? language,
    AudioPlayback? playback,
    bool? required,
    BlockTextStyle? textStyle,
    BlockAlign? align,
    BlockColor? color,
    BlockSize? size,
    bool? readAloud,
    String? url,
    bool? plural,
  }) => PromptElement(
    role: role ?? this.role,
    type: type ?? this.type,
    text: text ?? this.text,
    asset: asset ?? this.asset,
    speaker: speaker ?? this.speaker,
    speakerId: speakerId ?? this.speakerId,
    sharedImageSource: sharedImageSource ?? this.sharedImageSource,
    language: language ?? this.language,
    playback: playback ?? this.playback,
    required: required ?? this.required,
    textStyle: textStyle ?? this.textStyle,
    align: align ?? this.align,
    color: color ?? this.color,
    size: size ?? this.size,
    readAloud: readAloud ?? this.readAloud,
    url: url ?? this.url,
    plural: plural ?? this.plural,
  );

  Map<String, dynamic> toJson() => {
    'role': role,
    'type': type,
    if (text.isNotEmpty) 'text': text,
    if (asset.isNotEmpty) 'asset': asset,
    if (speaker.isNotEmpty) 'speaker': speaker,
    if (speakerId.isNotEmpty) 'speakerId': speakerId,
    if (sharedImageSource != null)
      'sharedImageSource': sharedImageSource!.toJson(),
    if (language != null) 'language': language!.serialized,
    if (playback != null) 'playback': playback!.serialized,
    if (required != null) 'required': required,
    if (textStyle != null) 'textStyle': textStyle!.serialized,
    if (align != null) 'align': align!.serialized,
    if (color != null) 'color': color!.serialized,
    if (size != null) 'size': size!.serialized,
    if (readAloud != null) 'readAloud': readAloud,
    if (url.isNotEmpty) 'url': url,
    if (plural != null) 'plural': plural,
  };
  factory PromptElement.fromJson(Map<String, dynamic> j) {
    final source = j['sharedImageSource'];
    if (source != null &&
        (source is! Map ||
            j['type'] != 'image' ||
            !RegExp(
              r'^media:[0-9a-f]{64}\.(png|jpg|jpeg|webp)$',
            ).hasMatch(j['asset']?.toString() ?? ''))) {
      throw const FormatException(
        'sharedImageSource requires a Course-owned image.',
      );
    }
    TextLanguage? language;
    if (j.containsKey('language')) {
      language = TextLanguage.tryParse(j['language']);
      if (language == null) {
        throw FormatException(
          'element.language “${j['language']}” must be source or target.',
        );
      }
    }
    AudioPlayback? playback;
    if (j.containsKey('playback')) {
      playback = AudioPlayback.tryParse(j['playback']);
      if (playback == null) {
        throw FormatException(
          'element.playback “${j['playback']}” must be automatic or manual.',
        );
      }
    }
    final required = j['required'];
    if (j.containsKey('required') && required is! bool) {
      throw const FormatException('element.required must be true or false.');
    }
    // Build 258 (Page blocks): each attribute belongs to the element types
    // it can shape, and only a value of its vocabulary is read.
    final type = _requiredString(j, 'type', 'prompt');
    T? attribute<T>(
      String key,
      T? Function(Object?) parse,
      Set<String> types,
      String legal,
    ) {
      if (!j.containsKey(key)) return null;
      if (!types.contains(type)) {
        throw FormatException(
          'element.$key does not apply to an element of type $type.',
        );
      }
      final value = parse(j[key]);
      if (value == null) {
        throw FormatException('element.$key “${j[key]}” must be $legal.');
      }
      return value;
    }

    final textStyle = attribute(
      'textStyle',
      BlockTextStyle.tryParse,
      pageElementAttributeTypes['textStyle']!,
      BlockTextStyle.values.map((v) => v.serialized).join(', '),
    );
    final align = attribute(
      'align',
      BlockAlign.tryParse,
      pageElementAttributeTypes['align']!,
      BlockAlign.values.map((v) => v.serialized).join(', '),
    );
    if (align == BlockAlign.justify && type != 'text') {
      throw const FormatException(
        'element.align justify applies to text elements only.',
      );
    }
    final color = attribute(
      'color',
      BlockColor.tryParse,
      pageElementAttributeTypes['color']!,
      BlockColor.values.map((v) => v.serialized).join(', '),
    );
    final size = attribute(
      'size',
      BlockSize.tryParse,
      pageElementAttributeTypes['size']!,
      BlockSize.values.map((v) => v.serialized).join(', '),
    );
    final readAloud = attribute(
      'readAloud',
      (value) => value is bool ? value : null,
      pageElementAttributeTypes['readAloud']!,
      'true or false',
    );
    final url = attribute(
      'url',
      (value) => value is String ? value : null,
      pageElementAttributeTypes['url']!,
      'a string',
    );
    final role = _optionalString(j, 'role', 'primary');
    final plural = attribute(
      'plural',
      (value) => value is bool ? value : null,
      pageElementAttributeTypes['plural']!,
      'true or false',
    );
    if (plural != null && type == 'text' && !pluralTextRoles.contains(role)) {
      throw const FormatException(
        'element.plural applies to a picture: an image element or an icon element.',
      );
    }
    return PromptElement(
      role: role,
      type: type,
      text: _optionalString(j, 'text', ''),
      asset: _optionalString(j, 'asset', ''),
      speaker: _optionalString(j, 'speaker', ''),
      speakerId: _optionalString(j, 'speakerId', ''),
      sharedImageSource: source == null
          ? null
          : SharedImageSource.fromJson(
              Map<String, dynamic>.from(source as Map),
            ),
      language: language,
      playback: playback,
      required: required as bool?,
      textStyle: textStyle,
      align: align,
      color: color,
      size: size,
      readAloud: readAloud,
      url: url ?? '',
      plural: plural,
    );
  }
}

/// Build 256 Revision 5: the voice a Story speaker prefers. It is matched
/// against the voices installed on the learner's device; a miss never
/// blocks speech.
enum StoryVoice {
  any('any'),
  male('male'),
  female('female');

  const StoryVoice(this.serialized);
  final String serialized;

  static StoryVoice? tryParse(Object? value) {
    for (final voice in values) {
      if (voice.serialized == value) return voice;
    }
    return null;
  }
}

/// Build 256 Revision 5: who speaks a Story's lines. The narrator speaks
/// every line without a `speakerId`; characters are reusable Course data
/// (`Course.storyCharacters`) that lines reference by their stable IDs.
class StorySpeaker {
  const StorySpeaker({
    this.id = '',
    this.name = '',
    this.avatar = '',
    required this.language,
    this.voice = StoryVoice.any,
  });

  /// Empty for the narrator; a stable `character_…` ID for a character.
  final String id;
  final String name;

  /// A bundled avatar (`assets/avatars/<name>.png`) or a Course medium
  /// (`media:<sha256>.<png|jpg|jpeg|webp>`); empty for none.
  final String avatar;
  final TextLanguage language;
  final StoryVoice voice;

  bool get isNarrator => id.isEmpty;

  /// The default narrator: no name, no avatar, the source language.
  static const StorySpeaker defaultNarrator = StorySpeaker(
    language: TextLanguage.source,
  );

  static final RegExp avatarPattern = RegExp(
    r'^(assets/avatars/[a-z0-9_]+\.png|media:[0-9a-f]{64}\.(png|jpg|jpeg|webp))$',
  );

  StorySpeaker copyWith({
    String? id,
    String? name,
    String? avatar,
    TextLanguage? language,
    StoryVoice? voice,
  }) => StorySpeaker(
    id: id ?? this.id,
    name: name ?? this.name,
    avatar: avatar ?? this.avatar,
    language: language ?? this.language,
    voice: voice ?? this.voice,
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    if (name.isNotEmpty) 'name': name,
    if (avatar.isNotEmpty) 'avatar': avatar,
    'language': language.serialized,
    if (voice != StoryVoice.any) 'voice': voice.serialized,
  };

  /// Parses a narrator (no `id`) or a character (an `id`), strictly.
  factory StorySpeaker.fromJson(
    Map<String, dynamic> j, {
    required bool character,
  }) {
    const allowed = {'id', 'name', 'avatar', 'language', 'voice'};
    final unknown = j.keys.where((key) => !allowed.contains(key)).toList();
    if (unknown.isNotEmpty) {
      throw FormatException(
        'story speaker has unsupported fields: ${unknown.join(', ')}.',
      );
    }
    final id = _optionalString(j, 'id', '').trim();
    if (character && id.isEmpty) {
      throw const FormatException('storyCharacters entries need an id.');
    }
    if (!character && id.isNotEmpty) {
      throw const FormatException('storyNarrator has no id.');
    }
    final avatar = _optionalString(j, 'avatar', '').trim();
    if (avatar.isNotEmpty && !avatarPattern.hasMatch(avatar)) {
      throw FormatException(
        'story avatar “$avatar” must be assets/avatars/<name>.png or a '
        'Course-owned media image.',
      );
    }
    final language = TextLanguage.tryParse(j['language']);
    if (language == null) {
      throw FormatException(
        'story speaker language “${j['language']}” must be source or target.',
      );
    }
    var voice = StoryVoice.any;
    if (j.containsKey('voice')) {
      final parsed = StoryVoice.tryParse(j['voice']);
      if (parsed == null) {
        throw FormatException(
          'story speaker voice “${j['voice']}” must be any, male or female.',
        );
      }
      voice = parsed;
    }
    return StorySpeaker(
      id: id,
      name: _optionalString(j, 'name', '').trim(),
      avatar: avatar,
      language: language,
      voice: voice,
    );
  }

  /// The optional `storyNarrator` object; null when absent.
  static StorySpeaker? parseNarrator(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) {
      throw const FormatException('course.storyNarrator must be an object.');
    }
    return StorySpeaker.fromJson(
      Map<String, dynamic>.from(raw),
      character: false,
    );
  }

  /// The optional `storyCharacters` list: objects with unique IDs.
  static List<StorySpeaker> parseCharacters(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const FormatException('course.storyCharacters must be a list.');
    }
    final ids = <String>{};
    return [
      for (final entry in raw)
        if (entry is Map)
          _uniqueCharacter(
            StorySpeaker.fromJson(
              Map<String, dynamic>.from(entry),
              character: true,
            ),
            ids,
          )
        else
          throw const FormatException(
            'course.storyCharacters entries must be objects.',
          ),
    ];
  }

  static StorySpeaker _uniqueCharacter(StorySpeaker speaker, Set<String> ids) {
    if (!ids.add(speaker.id)) {
      throw FormatException(
        'course.storyCharacters repeats the id “${speaker.id}”.',
      );
    }
    return speaker;
  }
}

class ExerciseItem {
  final String id;
  final List<PromptElement> content;

  /// Course Model v12: the column of a Match item. Null for other
  /// primitives.
  final MatchSide? side;
  const ExerciseItem({required this.id, required this.content, this.side});
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content.map((e) => e.toJson()).toList(),
    if (side != null) 'side': side!.serialized,
  };
  factory ExerciseItem.fromJson(Map<String, dynamic> j) {
    MatchSide? side;
    if (j.containsKey('side')) {
      side = MatchSide.tryParse(j['side']);
      if (side == null) {
        throw FormatException(
          'item.side “${j['side']}” must be left or right.',
        );
      }
    }
    return ExerciseItem(
      id: _requiredString(j, 'id', 'item'),
      content: _mapList(j, 'content', 'item', PromptElement.fromJson),
      side: side,
    );
  }
  ExerciseItem copyWith({
    String? id,
    List<PromptElement>? content,
    MatchSide? side,
  }) => ExerciseItem(
    id: id ?? this.id,
    content: content ?? this.content,
    side: side ?? this.side,
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

  /// What a learner may read for this item: its text, else its spoken text;
  /// never a picture's asset path (Build 259 Revision 4).
  String get label => text.isNotEmpty ? text : audio;

  /// Whether the item's picture, or its QQL picture's icon key, shows
  /// several (Build 265 Revision 11).
  bool get pictureIsPlural => content.any(
    (e) => (e.isImage || (e.isText && e.role == 'icon')) && e.isPlural,
  );
}

class ExerciseInteraction {
  final String kind;
  final String inputType;
  final int minSelections;
  final int maxSelections;
  final List<ExerciseItem> items;

  /// Optional ordered fixed-text/gap layout used by Arrange (and, later,
  /// linked-gap Select) exercises to embed one or more inline gaps inside
  /// otherwise fixed text. Each element is either `type: 'text'` (a fixed,
  /// non-editable run of text) or `type: 'gap'` (a fillable slot whose
  /// `text` is a stable gap ID). Empty by default, which preserves every
  /// existing Arrange exercise's whole-sentence, gap-free behavior.
  final List<PromptElement> layout;
  const ExerciseInteraction({
    required this.kind,
    this.inputType = 'text',
    this.minSelections = 1,
    this.maxSelections = 1,
    this.items = const [],
    this.layout = const [],
  });
  Map<String, dynamic> toJson() => {
    'kind': kind,
    if (kind == 'input') 'inputType': inputType,
    if (kind == 'select') 'minSelections': minSelections,
    if (kind == 'select') 'maxSelections': maxSelections,
    if (items.isNotEmpty) 'items': items.map((e) => e.toJson()).toList(),
    if (layout.isNotEmpty) 'layout': layout.map((e) => e.toJson()).toList(),
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
        layout: (j['layout'] is List)
            ? _mapList(j, 'layout', 'interaction', PromptElement.fromJson)
            : const [],
      );
}

class ExerciseEvaluation {
  final String kind;
  final List<String> correctItemIds;
  final List<String> accepted;
  final List<OrderedAnswer> correctOrders;
  final List<List<String>> pairs;
  final Map<String, dynamic> normalization;

  /// Optional gap ID -> required item ID map used by gap-based Arrange (and,
  /// later, linked-gap Select) exercises. Empty by default, which preserves
  /// every existing Arrange exercise's whole-sentence `correctOrders`
  /// evaluation unchanged.
  final Map<String, String> gapAssignments;
  const ExerciseEvaluation({
    required this.kind,
    this.correctItemIds = const [],
    this.accepted = const [],
    this.correctOrders = const [],
    this.pairs = const [],
    this.normalization = const {},
    this.gapAssignments = const {},
  });
  Map<String, dynamic> toJson() => {
    'kind': kind,
    if (correctItemIds.isNotEmpty) 'correctItemIds': correctItemIds,
    if (accepted.isNotEmpty) 'acceptedAnswers': accepted,
    if (correctOrders.isNotEmpty)
      'correctOrders': correctOrders.map((answer) => answer.toJson()).toList(),
    if (pairs.isNotEmpty) 'pairs': pairs,
    if (normalization.isNotEmpty) 'normalization': normalization,
    if (gapAssignments.isNotEmpty) 'gapAssignments': gapAssignments,
  };
  factory ExerciseEvaluation.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('accepted')) {
      throw const FormatException(
        'Course Model formatVersion 12 uses acceptedAnswers and does not load the legacy accepted field.',
      );
    }
    if (j.containsKey('correctOrder')) {
      throw const FormatException(
        'Course Model formatVersion 12 requires correctOrders and does not load the legacy single correctOrder field.',
      );
    }
    if (j.containsKey('caseSensitive') ||
        j.containsKey('ignorePunctuation') ||
        j.containsKey('ignoreAccents')) {
      throw const FormatException(
        'Course Model formatVersion 12 requires the normalization object and does not load legacy normalization flags.',
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
      gapAssignments: j['gapAssignments'] is Map
          ? Map<String, String>.from(
              (j['gapAssignments'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : const {},
    );
  }
}

/// The result of mapping a v11-shaped exercise to Course Model v12.
class V11ExerciseConversion {
  const V11ExerciseConversion({required this.exercise, required this.notes});

  final Exercise exercise;

  /// Everything the mapping could not carry over exactly, in plain words.
  final List<String> notes;
}

/// One exercise of Course Model v12: a primitive, its options, media,
/// items, targets, a neutral layout, an evaluation and feedback. Presets are
/// authoring metadata only.
///
/// The v11 views below (`interaction`, `evaluation`, `type`, `prompt`,
/// `answers`, …) are derived from the canonical fields for the learner
/// runtime, Audit and editor that Build 256 Sessions 3 and 4 move onto the
/// canonical fields; they are read-only and will go.
class Exercise {
  final String id;
  final PublicationState publicationState;
  final DateTime updatedAt;
  final ExercisePrimitive primitive;

  /// Explicitly set options only; the registry supplies defaults.
  final PrimitiveOptions options;
  final List<PromptElement> promptElements;
  final List<ExerciseItem> items;
  final List<ExerciseTarget> targets;

  /// The neutral inline layout (text runs and targets); empty unless the
  /// exercise uses an inline layout.
  final List<LayoutElement> layout;
  final CanonicalEvaluation canonicalEvaluation;
  final ExerciseFeedback feedback;
  final String hint;

  /// Optional authoring metadata (`presetId` and anything else an editor
  /// stores). Preserved, never read by anything learners see.
  final Map<String, Object?> authoringMetadata;

  /// The author's own notes on this exercise (Build 267 Revision 8, owner
  /// decisions of 9 October 2026): stored on its Content as `editorNotes`,
  /// never shown to learners, outside the semantic comparison and preset
  /// recognition, kept through every edit, Copy and Fork, removed by Export
  /// as Publisher Course.
  final String editorNotes;

  /// The longest [editorNotes] a Course may store.
  static const maxEditorNotesLength = 2000;

  Exercise.canonical({
    required this.id,
    this.publicationState = PublicationState.published,
    DateTime? updatedAt,
    required this.primitive,
    PrimitiveOptions? options,
    this.promptElements = const [],
    this.items = const [],
    this.targets = const [],
    this.layout = const [],
    required this.canonicalEvaluation,
    this.feedback = ExerciseFeedback.empty,
    this.hint = '',
    Map<String, Object?>? authoringMetadata,
    this.editorNotes = '',
  }) : updatedAt = _canonicalUtcTimestamp(updatedAt),
       options = options ?? PrimitiveOptions.empty,
       authoringMetadata = Map.unmodifiable(
         Map<String, Object?>.from(authoringMetadata ?? const {}),
       );

  /// Compatibility constructor used by existing friendly Editor templates.
  /// It builds the v11 shape from the template fields and converts it.
  factory Exercise({
    required String id,
    PublicationState publicationState = PublicationState.published,
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
    required String hint,
    required List<String> icons,
    String imageAsset = '',
    List<String> missingWords = const [],
  }) => Exercise.v2(
    id: id,
    publicationState: publicationState,
    updatedAt: updatedAt,
    editorTemplate: editorTemplate ?? type,
    promptElements: _legacyPrompt(type, prompt, question, tts, imageAsset),
    interaction: _legacyInteraction(
      type,
      answers,
      correct,
      tokens,
      pairs,
      icons,
    ),
    evaluation: _legacyEvaluation(
      type,
      answers,
      correct,
      accepted,
      tokens,
      orderAnswer,
      correctTranslations,
      pairs,
    ),
    hint: hint,
    missingWords: missingWords,
  );

  /// The v11 shape (prompt elements, interaction, evaluation), converted to
  /// Course Model v12 through the same mapping as the converter tool.
  factory Exercise.v2({
    required String id,
    PublicationState publicationState = PublicationState.published,
    DateTime? updatedAt,
    required String editorTemplate,
    required List<PromptElement> promptElements,
    required ExerciseInteraction interaction,
    required ExerciseEvaluation evaluation,
    String hint = '',
    ExerciseFeedback feedback = ExerciseFeedback.empty,
    List<String> missingWords = const [],
    Map<String, Object?> authoringMetadata = const {},
  }) => convertV11(
    id: id,
    publicationState: publicationState,
    updatedAt: updatedAt,
    editorTemplate: editorTemplate,
    promptElements: promptElements,
    interaction: interaction,
    evaluation: evaluation,
    hint: hint,
    feedback: feedback,
    missingWords: missingWords,
    authoringMetadata: authoringMetadata,
  ).exercise;

  /// A Before you start card (Build 257): a presentation whose note is a
  /// text element with role `intro`, shown before its Round starts, and an
  /// optional Open GuideBook button. The one shape the form, the Round
  /// Wizard and the v11 converter build.
  factory Exercise.beforeYouStart({
    required String id,
    PublicationState publicationState = PublicationState.published,
    DateTime? updatedAt,
    required String text,
    bool guidebookButton = false,
    ExerciseFeedback feedback = ExerciseFeedback.empty,
    Map<String, Object?>? authoringMetadata,
  }) => Exercise.canonical(
    id: id,
    publicationState: publicationState,
    updatedAt: updatedAt,
    primitive: ExercisePrimitive.presentation,
    options: PrimitiveOptions({
      if (guidebookButton)
        OptionKey.guidebookButton: const BoolOptionValue(true),
    }),
    promptElements: [PromptElement(role: 'intro', type: 'text', text: text)],
    canonicalEvaluation: CanonicalEvaluation.none,
    feedback: feedback,
    authoringMetadata: authoringMetadata,
  );

  factory Exercise.presentation({
    required String id,
    required String editorTemplate,
    required String term,
    required String meaning,
    PublicationState publicationState = PublicationState.published,
  }) => Exercise.canonical(
    id: id,
    publicationState: publicationState,
    primitive: ExercisePrimitive.presentation,
    options: PrimitiveOptions({
      OptionKey.completionMode: const EnumOptionValue(
        CompletionMode.understoodReview,
      ),
    }),
    promptElements: [
      if (term.isNotEmpty)
        PromptElement(role: 'term', type: 'text', text: term),
      if (meaning.isNotEmpty)
        PromptElement(role: 'meaning', type: 'text', text: meaning),
    ],
    canonicalEvaluation: CanonicalEvaluation.none,
    authoringMetadata: {
      'presetId': editorTemplate.isEmpty ? 'flashcard' : editorTemplate,
    },
  );

  /// Exposes the existing token/authored-order resolution used by the
  /// legacy whole-sentence Arrange builder so Editor authoring for the
  /// inline-gap Arrange mode can reuse the identical block-matching rules.
  static List<String> resolveOrderedItemIds(
    List<String> tokens,
    List<String> authoredOrder,
  ) => _resolveOrderedItemIds(tokens, authoredOrder);

  /// Exposes the existing legacy prompt-role mapping (clue/primary/passage/
  /// context) so Editor authoring for the inline-gap Arrange mode builds
  /// prompt elements identical to the whole-sentence Arrange builder.
  static List<PromptElement> legacyPromptElements(
    String type,
    String prompt,
    String question,
    String? tts,
    String imageAsset,
  ) => _legacyPrompt(type, prompt, question, tts, imageAsset);

  // ---------------------------------------------------------------------
  // Course Model v12 JSON
  // ---------------------------------------------------------------------

  static const _jsonKeys = {
    'updatedAt',
    'primitive',
    'options',
    'prompt',
    'items',
    'targets',
    'layout',
    'evaluation',
    'feedback',
    'hint',
  };

  Map<String, dynamic> toJson() => {
    'updatedAt': _timestampToJson(updatedAt),
    'primitive': primitive.serialized,
    if (options.isNotEmpty) 'options': options.toJson(),
    'prompt': promptElements.map((e) => e.toJson()).toList(),
    if (items.isNotEmpty) 'items': items.map((e) => e.toJson()).toList(),
    if (targets.isNotEmpty) 'targets': targets.map((e) => e.toJson()).toList(),
    if (layout.isNotEmpty) 'layout': layout.map((e) => e.toJson()).toList(),
    'evaluation': canonicalEvaluation.toJson(),
    if (!feedback.isEmpty) 'feedback': feedback.toJson(),
    if (hint.isNotEmpty) 'hint': hint,
  };

  factory Exercise.fromJson(
    Map<String, dynamic> j, {
    required String contentId,
    Map<String, Object?> authoringMetadata = const {},
    required PublicationState publicationState,
    String editorNotes = '',
  }) {
    for (final legacy in const ['interaction', 'editorTemplate']) {
      if (j.containsKey(legacy)) {
        throw FormatException(
          'Course Model formatVersion 12 exercises have a primitive, options and a canonical evaluation, not $legacy. Convert the Course with tools/convert_course_to_v12.dart.',
        );
      }
    }
    final unknown = j.keys.where((key) => !_jsonKeys.contains(key)).toList();
    if (unknown.isNotEmpty) {
      throw FormatException(
        'exercise contains unsupported fields: ${unknown.join(', ')}.',
      );
    }
    final primitive = ExercisePrimitive.parse(j['primitive']);
    final rawOptions = j['options'];
    if (j.containsKey('options') && rawOptions is! Map) {
      throw const FormatException('exercise.options must be an object.');
    }
    final parsedOptions = PrimitiveCapabilityRegistry.parseOptions(
      primitive,
      rawOptions is Map
          ? Map<String, Object?>.from(
              rawOptions.map((k, v) => MapEntry(k.toString(), v)),
            )
          : const {},
    );
    if (parsedOptions.violations.isNotEmpty) {
      throw FormatException(
        'exercise.options: ${parsedOptions.violations.map((v) => v.message).join(' ')}',
      );
    }
    final p = j['prompt'];
    final e = j['evaluation'];
    if (p is! List || e is! Map) {
      throw const FormatException(
        'Exercise requires prompt[] and an evaluation object.',
      );
    }
    final rawFeedback = j['feedback'];
    if (j.containsKey('feedback') && rawFeedback is! Map) {
      throw const FormatException('exercise.feedback must be an object.');
    }
    return Exercise.canonical(
      id: contentId,
      publicationState: publicationState,
      updatedAt: _requiredUtcTimestamp(j, 'updatedAt', 'exercise'),
      primitive: primitive,
      options: parsedOptions.options,
      promptElements: _mapList(j, 'prompt', 'exercise', PromptElement.fromJson),
      items: j['items'] == null
          ? const []
          : _mapList(j, 'items', 'exercise', ExerciseItem.fromJson),
      targets: j['targets'] == null
          ? const []
          : _mapList(j, 'targets', 'exercise', ExerciseTarget.fromJson),
      layout: j['layout'] == null
          ? const []
          : _mapList(j, 'layout', 'exercise', LayoutElement.fromJson),
      canonicalEvaluation: CanonicalEvaluation.fromJson(
        Map<String, dynamic>.from(e),
      ),
      feedback: rawFeedback is Map
          ? ExerciseFeedback.fromJson(Map<String, dynamic>.from(rawFeedback))
          : ExerciseFeedback.empty,
      hint: _optionalString(j, 'hint', ''),
      authoringMetadata: authoringMetadata,
      editorNotes: editorNotes,
    );
  }

  /// Alias of [toJson], kept for tests written against the v11 helper. The
  /// result is Course Model v12 JSON.
  Map<String, dynamic> toV2Json() => toJson();

  /// Alias of [fromJson], kept for tests written against the v11 helper. It
  /// reads Course Model v12 JSON; [editorTemplate] becomes the preset in the
  /// authoring metadata.
  factory Exercise.fromV2Json(
    Map<String, dynamic> j, {
    required String contentId,
    required String editorTemplate,
    required PublicationState publicationState,
  }) => Exercise.fromJson(
    j,
    contentId: contentId,
    authoringMetadata: editorTemplate.trim().isEmpty
        ? const {}
        : {'presetId': editorTemplate.trim()},
    publicationState: publicationState,
  );

  /// The same exercise with other authoring metadata (the canonical content
  /// is untouched).
  Exercise withAuthoringMetadata(Map<String, Object?> metadata) =>
      Exercise.canonical(
        id: id,
        publicationState: publicationState,
        updatedAt: updatedAt,
        primitive: primitive,
        options: options,
        promptElements: promptElements,
        items: items,
        targets: targets,
        layout: layout,
        canonicalEvaluation: canonicalEvaluation,
        feedback: feedback,
        hint: hint,
        authoringMetadata: metadata,
        editorNotes: editorNotes,
      );

  /// The same exercise with another publication state and, optionally,
  /// timestamp.
  Exercise withPublicationState(
    PublicationState state, {
    DateTime? updatedAt,
  }) => Exercise.canonical(
    id: id,
    publicationState: state,
    updatedAt: updatedAt ?? this.updatedAt,
    primitive: primitive,
    options: options,
    promptElements: promptElements,
    items: items,
    targets: targets,
    layout: layout,
    canonicalEvaluation: canonicalEvaluation,
    feedback: feedback,
    hint: hint,
    authoringMetadata: authoringMetadata,
    editorNotes: editorNotes,
  );

  /// A copy with some canonical fields replaced. Authoring code that changes
  /// one part of an exercise uses this instead of rebuilding the exercise
  /// through the v11 views, which cannot carry a v12 inline layout.
  Exercise copyWith({
    String? id,
    PublicationState? publicationState,
    DateTime? updatedAt,
    PrimitiveOptions? options,
    List<PromptElement>? promptElements,
    List<ExerciseItem>? items,
    List<ExerciseTarget>? targets,
    List<LayoutElement>? layout,
    CanonicalEvaluation? canonicalEvaluation,
    ExerciseFeedback? feedback,
    String? hint,
    Map<String, Object?>? authoringMetadata,
    String? editorNotes,
  }) => Exercise.canonical(
    id: id ?? this.id,
    publicationState: publicationState ?? this.publicationState,
    updatedAt: updatedAt ?? this.updatedAt,
    primitive: primitive,
    options: options ?? this.options,
    promptElements: promptElements ?? this.promptElements,
    items: items ?? this.items,
    targets: targets ?? this.targets,
    layout: layout ?? this.layout,
    canonicalEvaluation: canonicalEvaluation ?? this.canonicalEvaluation,
    feedback: feedback ?? this.feedback,
    hint: hint ?? this.hint,
    authoringMetadata: authoringMetadata ?? this.authoringMetadata,
    editorNotes: editorNotes ?? this.editorNotes,
  );

  /// The options with the registry's defaults filled in.
  PrimitiveOptions get effectiveOptions =>
      PrimitiveCapabilityRegistry.effectiveOptions(primitive, options);

  /// Whether this version of QQL can play the exercise, from the registry's
  /// runtime-support table (Build 256 Revision 6, plan A.2 and A.6):
  /// computed here, never stored in Course data. A legal configuration no
  /// entry covers is readable but not executable: kept, editable and
  /// exported unchanged; learners of this version skip it.
  ExerciseRuntimeSupport get runtimeSupport =>
      PrimitiveCapabilityRegistry.runtimeSupport(
        primitive: primitive,
        options: options,
        evaluationMode: canonicalEvaluation.mode,
      );

  bool get isExecutable => runtimeSupport.isExecutable;

  /// The canonical content in a form that ignores authoring metadata, the
  /// timestamp and the publication state, with every default option filled
  /// in: two exercises are semantically equal when this is equal. IDs and
  /// item order count.
  Map<String, dynamic> semanticJson() => {
    'id': id,
    ...toJson()..remove('updatedAt'),
    'options': effectiveOptions.toJson(),
  };

  bool semanticallyEquals(Exercise other) =>
      jsonEncode(_sortedJson(semanticJson())) ==
      jsonEncode(_sortedJson(other.semanticJson()));

  static Object? _sortedJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: _sortedJson(value[key])};
    }
    if (value is List) return value.map(_sortedJson).toList(growable: false);
    return value;
  }

  // ---------------------------------------------------------------------
  // v11 → v12 mapping (shared with the converter tool)
  // ---------------------------------------------------------------------

  /// Maps a v11-shaped exercise to Course Model v12. The preset (the v11
  /// `editorTemplate`) decides the behaviors v11 attached to it: automatic
  /// audio, text languages, typo tolerance, literal answers, the gap of Type
  /// the missing word, the gaps of Listen for missing words, the joiner of
  /// Image-prompt ordering. Without a known preset the interaction kind
  /// alone decides, with the registry defaults.
  static V11ExerciseConversion convertV11({
    required String id,
    PublicationState publicationState = PublicationState.published,
    DateTime? updatedAt,
    required String editorTemplate,
    required List<PromptElement> promptElements,
    required ExerciseInteraction interaction,
    required ExerciseEvaluation evaluation,
    String hint = '',
    ExerciseFeedback feedback = ExerciseFeedback.empty,
    List<String> missingWords = const [],
    Map<String, Object?> authoringMetadata = const {},
  }) {
    final notes = <String>[];
    final preset = editorTemplate.trim();
    final type = _legacyTypeFromTemplate(preset, interaction.kind);
    // A preset the Build 256 Revision 4 catalogue retired is recorded as its
    // successor; the v11 type above still decides the conversion. An Arrange
    // with inline gaps is Pick the words for the gaps; a Choose with inline
    // gaps, whose option may fill several gaps, has no preset since Build
    // 259 Revision 4.
    final hasGaps = interaction.layout.any((element) => element.type == 'gap');
    final presetId = hasGaps && preset == 'choice'
        ? ''
        : hasGaps && (preset == 'word_order' || preset == 'build_translation')
        ? 'gap_blocks'
        : presetSuccessorOf[preset] ?? preset;
    final metadata = <String, Object?>{
      ...authoringMetadata,
      if (presetId.isNotEmpty) 'presetId': presetId,
    };
    final gaps = interaction.layout
        .where((element) => element.type == 'gap')
        .map((element) => element.text)
        .toList(growable: false);
    List<LayoutElement> layoutOf() => [
      for (final element in interaction.layout)
        if (element.type == 'gap')
          LayoutElement.target(element.text)
        else
          LayoutElement.text(element.text),
    ];
    List<TargetAssignment> assignmentsOf() => [
      for (final gapId in gaps)
        if (evaluation.gapAssignments.containsKey(gapId))
          TargetAssignment(
            targetId: gapId,
            itemIds: [evaluation.gapAssignments[gapId]!],
          ),
    ];
    List<PromptElement> withAudio(
      List<PromptElement> elements,
      AudioPlayback playback,
    ) => [
      for (final element in elements)
        if (element.isAudio) element.copyWith(playback: playback) else element,
    ];
    List<PromptElement> withTextLanguage(
      List<PromptElement> elements,
      String role,
      TextLanguage language,
    ) => [
      // A language the element states wins over the one the preset implies.
      for (final element in elements)
        if (element.isText && element.role == role && element.language == null)
          element.copyWith(language: language)
        else
          element,
    ];
    List<ExerciseItem> withItemLanguage(TextLanguage language) => [
      for (final item in interaction.items)
        item.copyWith(
          content: [
            for (final element in item.content)
              if (element.isText &&
                  element.role == 'primary' &&
                  element.language == null)
                element.copyWith(language: language)
              else
                element,
          ],
        ),
    ];

    ExercisePrimitive primitive;
    var options = <OptionKey, OptionValue>{};
    var prompt = promptElements;
    var items = interaction.items;
    var targets = <ExerciseTarget>[];
    var layout = <LayoutElement>[];
    CanonicalEvaluation canonical;
    var canonicalFeedback = feedback;

    if (type == 'flashcard' || interaction.kind == 'presentation') {
      primitive = ExercisePrimitive.presentation;
      options[OptionKey.completionMode] = const EnumOptionValue(
        CompletionMode.understoodReview,
      );
      final usage = interaction.items.map((item) => item.value).toList();
      prompt = [
        for (final element in promptElements)
          if (element.isText && element.role != 'question')
            element.copyWith(role: 'term')
          else if (element.isText)
            element.copyWith(role: 'meaning')
          else if (element.isAudio)
            element.copyWith(role: 'audio')
          else
            element,
        if (usage.isNotEmpty)
          PromptElement(role: 'usage', type: 'text', text: usage.first),
        if (usage.length > 1)
          PromptElement(
            role: 'usage_translation',
            type: 'text',
            text: usage[1],
          ),
      ];
      items = const [];
      canonical = CanonicalEvaluation.none;
    } else {
      switch (interaction.kind) {
        case 'select':
          primitive = ExercisePrimitive.select;
          final multiple = interaction.maxSelections > 1;
          if (multiple) {
            options[OptionKey.selectionMode] = const EnumOptionValue(
              SelectionMode.multiple,
            );
            if (interaction.minSelections != 1) {
              options[OptionKey.minimumSelections] = IntOptionValue(
                interaction.minSelections < 1 ? 1 : interaction.minSelections,
              );
            }
            options[OptionKey.maximumSelections] = IntOptionValue(
              interaction.maxSelections,
            );
            options[OptionKey.evaluationTiming] = const EnumOptionValue(
              EvaluationTiming.explicit,
            );
          }
          if (gaps.isNotEmpty) {
            options[OptionKey.layout] = const EnumOptionValue(
              LayoutValue.inline,
            );
            options[OptionKey.itemReuse] = const EnumOptionValue(
              ItemReuse.unlimited,
            );
            options[OptionKey.evaluationTiming] = const EnumOptionValue(
              EvaluationTiming.explicit,
            );
            targets = [for (final gapId in gaps) ExerciseTarget(id: gapId)];
            layout = layoutOf();
            canonical = CanonicalEvaluation(
              mode: EvaluationMode.exactItem,
              assignments: assignmentsOf(),
            );
            if (evaluation.correctItemIds.isNotEmpty) {
              notes.add(
                '$id: correctItemIds are not used by an inline-gap Select and were dropped.',
              );
            }
          } else {
            canonical = CanonicalEvaluation(
              mode: multiple
                  ? EvaluationMode.exactSet
                  : EvaluationMode.exactItem,
              correctItemIds: evaluation.correctItemIds,
            );
          }
          if (const {
            'listening_choice',
            'listening_comprehension',
            'contextual_comprehension',
            // Listen and pick the image (Build 256 Revision 4).
            'icon_choice',
          }.contains(type)) {
            prompt = withAudio(prompt, AudioPlayback.automatic);
          }
          if (type == 'translation_choice_to_target' ||
              type == 'translation_choice_to_source') {
            // Pick the translation is solvable without audio: its spoken
            // text is optional and never makes it an audio exercise.
            prompt = [
              for (final element in prompt)
                if (element.isAudio)
                  element.copyWith(required: false)
                else
                  element,
            ];
          }
          if (type == 'translation_choice_to_target') {
            prompt = withTextLanguage(prompt, 'question', TextLanguage.source);
            items = withItemLanguage(TextLanguage.target);
          } else if (type == 'translation_choice_to_source') {
            prompt = withTextLanguage(prompt, 'question', TextLanguage.target);
            items = withItemLanguage(TextLanguage.source);
          } else if (type == 'dialogue_response') {
            // The text a Dialogue response answers is a situation, which the
            // v11 shape stored under the reading passage's role.
            prompt = [
              for (final element in prompt)
                if (element.isText && element.role == 'passage')
                  element.copyWith(role: 'situation')
                else
                  element,
            ];
          } else if (type == 'script_recognition') {
            // Recognize characters shows character specimens, not
            // illustrations: the runtime draws `character` images as
            // specimens and every other image as one illustration.
            prompt = [
              for (final element in prompt)
                if (element.isImage)
                  element.copyWith(role: 'character')
                else
                  element,
            ];
            items = [
              for (final item in items)
                item.copyWith(
                  content: [
                    for (final element in item.content)
                      if (element.isImage)
                        element.copyWith(role: 'character')
                      else
                        element,
                  ],
                ),
            ];
          }
        case 'input':
          primitive = ExercisePrimitive.input;
          final normalization = evaluation.normalization;
          if (normalization['case'] == 'preserve') {
            options[OptionKey.caseHandling] = const EnumOptionValue(
              CaseHandling.exact,
            );
          }
          if (normalization['punctuation'] == 'preserve') {
            options[OptionKey.punctuationHandling] = const EnumOptionValue(
              PunctuationHandling.exact,
            );
          }
          if (normalization['whitespace'] == 'preserve') {
            options[OptionKey.whitespaceHandling] = const EnumOptionValue(
              WhitespaceHandling.exact,
            );
          }
          if (normalization['accents'] == 'ignore') {
            options[OptionKey.accentHandling] = const EnumOptionValue(
              AccentHandling.ignore,
            );
          }
          final unknownRules = normalization.keys
              .where(
                (key) => !const {
                  'case',
                  'punctuation',
                  'whitespace',
                  'accents',
                }.contains(key),
              )
              .toList();
          if (unknownRules.isNotEmpty) {
            notes.add(
              '$id: normalization keys ${unknownRules.join(', ')} have no v12 form and were dropped.',
            );
          }
          if (type == 'type_translation' || type == 'type_missing_word') {
            options[OptionKey.typoTolerance] = const EnumOptionValue(
              TypoTolerance.conservative,
            );
          }
          final spoken = promptElements
              .where((element) => element.isAudio)
              .map((element) => element.text.trim())
              .firstOrNull;
          final literal = <String>[
            if (const {
                  'fill_blank',
                  'listening_spelling',
                  'type_translation',
                }.contains(type) &&
                spoken != null &&
                spoken.isNotEmpty &&
                !evaluation.accepted.contains(spoken))
              spoken,
          ];
          canonical = CanonicalEvaluation(
            mode: EvaluationMode.expression,
            answers: evaluation.accepted,
            literalAnswers: literal,
          );
          if (type == 'type_missing_word') {
            final sentence = _primaryText(prompt);
            final match = RegExp(r'_{3,}').firstMatch(sentence ?? '');
            if (sentence != null && match != null) {
              options[OptionKey.layout] = const EnumOptionValue(
                LayoutValue.inlineGaps,
              );
              targets = const [
                ExerciseTarget(id: 'gap_1', reveal: TargetReveal.firstGrapheme),
              ];
              layout = [
                if (match.start > 0)
                  LayoutElement.text(sentence.substring(0, match.start)),
                const LayoutElement.target('gap_1'),
                if (match.end < sentence.length)
                  LayoutElement.text(sentence.substring(match.end)),
              ];
              prompt = _withoutPrimaryText(prompt);
              canonical = CanonicalEvaluation(
                mode: EvaluationMode.expression,
                targetAnswers: [
                  TargetAnswers(
                    targetId: 'gap_1',
                    answers: evaluation.accepted,
                  ),
                ],
              );
            } else {
              notes.add(
                '$id: Type the missing word has no ___ gap in its sentence; kept as one field.',
              );
            }
          } else if (type == 'missing_word') {
            final transcript = _primaryText(prompt);
            final words = missingWords.isNotEmpty
                ? missingWords
                : evaluation.accepted;
            final built = transcript == null
                ? null
                : _missingWordLayout(transcript, words);
            if (built != null) {
              options[OptionKey.cardinality] = const EnumOptionValue(
                Cardinality.multiple,
              );
              options[OptionKey.layout] = const EnumOptionValue(
                LayoutValue.inlineGaps,
              );
              targets = [
                for (var i = 0; i < words.length; i++)
                  ExerciseTarget(id: 'gap_${i + 1}'),
              ];
              layout = built;
              prompt = withAudio(
                _withoutPrimaryText(prompt),
                AudioPlayback.automatic,
              );
              canonical = CanonicalEvaluation(
                mode: EvaluationMode.expression,
                targetAnswers: [
                  for (var i = 0; i < words.length; i++)
                    TargetAnswers(
                      targetId: 'gap_${i + 1}',
                      answers: [words[i]],
                    ),
                ],
              );
            } else {
              notes.add(
                '$id: Listen for missing words could not place every missing word in its transcript; kept as one field.',
              );
              prompt = withAudio(prompt, AudioPlayback.automatic);
            }
          } else if (type == 'listening_spelling') {
            prompt = withAudio(prompt, AudioPlayback.automatic);
          } else if (type == 'type_translation') {
            prompt = withTextLanguage(prompt, 'primary', TextLanguage.source);
            prompt = withTextLanguage(prompt, 'clue', TextLanguage.source);
            canonicalFeedback = ExerciseFeedback(
              correct: feedback.correct,
              incorrect: feedback.incorrect,
              showAlternatives: FeedbackAlternatives.ranked,
            );
          }
          if (missingWords.isNotEmpty && type != 'missing_word') {
            notes.add(
              '$id: missingWords apply to Listen for missing words only and were dropped.',
            );
          }
        case 'arrange':
          primitive = ExercisePrimitive.arrange;
          if (type == 'image_word') {
            // Spell what you hear speaks its word (Build 256 Revision 4).
            prompt = withAudio(prompt, AudioPlayback.automatic);
            options[OptionKey.joiner] = const EnumOptionValue(Joiner.none);
            options[OptionKey.unusedItems] = const EnumOptionValue(
              UnusedItems.forbidden,
            );
          }
          if (gaps.isNotEmpty) {
            options[OptionKey.placementMode] = const EnumOptionValue(
              PlacementMode.inlineGaps,
            );
            options[OptionKey.layout] = const EnumOptionValue(
              LayoutValue.inline,
            );
            targets = [for (final gapId in gaps) ExerciseTarget(id: gapId)];
            layout = layoutOf();
            canonical = CanonicalEvaluation(
              mode: EvaluationMode.gapAssignments,
              assignments: assignmentsOf(),
            );
            if (evaluation.correctOrders.isNotEmpty) {
              notes.add(
                '$id: correctOrders are not used by an inline-gap Arrange and were dropped.',
              );
            }
          } else {
            canonical = CanonicalEvaluation(
              mode: evaluation.correctOrders.length > 1
                  ? EvaluationMode.acceptedOrders
                  : EvaluationMode.exactOrder,
              correctOrders: evaluation.correctOrders,
            );
          }
          if (type == 'build_translation') {
            prompt = withTextLanguage(prompt, 'primary', TextLanguage.source);
            prompt = withTextLanguage(prompt, 'clue', TextLanguage.source);
            canonicalFeedback = ExerciseFeedback(
              correct: feedback.correct,
              incorrect: feedback.incorrect,
              showAlternatives: FeedbackAlternatives.all,
            );
          }
        case 'match':
          primitive = ExercisePrimitive.match;
          final left = <String>{};
          final right = <String>{};
          for (final pair in evaluation.pairs) {
            if (pair.length == 2) {
              left.add(pair[0]);
              right.add(pair[1]);
            }
          }
          items = [
            for (var i = 0; i < interaction.items.length; i++)
              interaction.items[i].copyWith(
                side: left.contains(interaction.items[i].id)
                    ? MatchSide.left
                    : right.contains(interaction.items[i].id)
                    ? MatchSide.right
                    : i.isEven
                    ? MatchSide.left
                    : MatchSide.right,
              ),
          ];
          canonical = CanonicalEvaluation(
            mode: EvaluationMode.exactRelations,
            relations: [
              for (final pair in evaluation.pairs)
                if (pair.length == 2) [pair[0], pair[1]],
            ],
          );
          // The v11 presets implied the languages of the two sides: Match
          // the words pairs target-language phrases with source-language
          // translations, Match related words the other way round; the
          // same-language presets state nothing.
          final sideLanguages = type == 'matching'
              ? (TextLanguage.target, TextLanguage.source)
              : type == 'word_match'
              ? (TextLanguage.source, TextLanguage.target)
              : null;
          if (sideLanguages != null) {
            items = [
              for (final item in items)
                item.copyWith(
                  content: [
                    for (final element in item.content)
                      if (element.isText &&
                          element.role == 'primary' &&
                          element.language == null)
                        element.copyWith(
                          language: item.side == MatchSide.left
                              ? sideLanguages.$1
                              : sideLanguages.$2,
                        )
                      else
                        element,
                  ],
                ),
            ];
          }
        default:
          throw FormatException(
            'Unknown interaction kind “${interaction.kind}” cannot be converted to a Course Model v12 primitive.',
          );
      }
    }
    // v11 let any evaluation carry every kind's fields; v12 keeps only the
    // primitive's own, so stale data is reported rather than lost quietly.
    final stale = <String>[
      if (primitive != ExercisePrimitive.select &&
          primitive != ExercisePrimitive.presentation &&
          evaluation.correctItemIds.isNotEmpty)
        'correctItemIds',
      if (primitive != ExercisePrimitive.input &&
          evaluation.accepted.isNotEmpty)
        'acceptedAnswers',
      if (primitive != ExercisePrimitive.arrange &&
          evaluation.correctOrders.isNotEmpty)
        'correctOrders',
      if (primitive != ExercisePrimitive.match && evaluation.pairs.isNotEmpty)
        'pairs',
      if (primitive != ExercisePrimitive.input &&
          evaluation.normalization.isNotEmpty)
        'normalization',
    ];
    if (stale.isNotEmpty) {
      notes.add(
        '$id: v11 evaluation fields ${stale.join(', ')} are not used by ${primitive.label} and were dropped.',
      );
    }
    return V11ExerciseConversion(
      exercise: Exercise.canonical(
        id: id,
        publicationState: publicationState,
        updatedAt: updatedAt,
        primitive: primitive,
        options: PrimitiveOptions(options),
        promptElements: prompt,
        items: items,
        targets: targets,
        layout: layout,
        canonicalEvaluation: canonical,
        feedback: canonicalFeedback,
        hint: hint,
        authoringMetadata: metadata,
      ),
      notes: notes,
    );
  }

  static String? _primaryText(List<PromptElement> elements) => elements
      .where((element) => element.isText && element.role == 'primary')
      .map((element) => element.text)
      .firstOrNull;

  static List<PromptElement> _withoutPrimaryText(List<PromptElement> elements) {
    var removed = false;
    return [
      for (final element in elements)
        if (!removed && element.isText && element.role == 'primary')
          ...(() {
            removed = true;
            return const <PromptElement>[];
          })()
        else
          element,
    ];
  }

  /// The inline layout of Listen for missing words: the transcript with the
  /// first case-insensitive occurrence of each missing word, in order,
  /// replaced by a target. Null when a word is not found.
  static List<LayoutElement>? _missingWordLayout(
    String transcript,
    List<String> words,
  ) {
    if (words.isEmpty) return null;
    final out = <LayoutElement>[];
    var cursor = 0;
    final lower = transcript.toLowerCase();
    for (var i = 0; i < words.length; i++) {
      final word = words[i].trim();
      if (word.isEmpty) return null;
      final index = lower.indexOf(word.toLowerCase(), cursor);
      if (index < 0) return null;
      if (index > cursor) {
        out.add(LayoutElement.text(transcript.substring(cursor, index)));
      }
      out.add(LayoutElement.target('gap_${i + 1}'));
      cursor = index + word.length;
    }
    if (cursor < transcript.length) {
      out.add(LayoutElement.text(transcript.substring(cursor)));
    }
    return out;
  }

  // ---------------------------------------------------------------------
  // v11 views (read-only, derived; removed in Sessions 3 and 4)
  // ---------------------------------------------------------------------

  /// The preset that authored this exercise, or an empty string.
  String get editorTemplate {
    final preset = authoringMetadata['presetId'];
    return preset is String ? preset.trim() : '';
  }

  late final ExerciseInteraction interaction = _buildInteraction();
  late final ExerciseEvaluation evaluation = _buildEvaluation();

  ExerciseInteraction _buildInteraction() {
    final legacyItems = primitive == ExercisePrimitive.presentation
        ? [
            for (var i = 0; i < answers.length; i++)
              ExerciseItem(
                id: 'item_$i',
                content: [PromptElement(type: 'text', text: answers[i])],
              ),
          ]
        : items;
    return ExerciseInteraction(
      kind: primitive == ExercisePrimitive.presentation
          ? 'select'
          : primitive.serialized,
      inputType: 'text',
      minSelections: isMultiSelect ? requiredSelectionCount : 1,
      maxSelections: isMultiSelect ? maxSelectionCount : 1,
      items: legacyItems,
      // v11 knew inline gaps on Select and Arrange only; an Input's inline
      // layout (Type the missing word, Listen for missing words) is new in
      // v12 and reaches v11 readers through the `prompt` view instead.
      layout: [
        if (primitive == ExercisePrimitive.select ||
            primitive == ExercisePrimitive.arrange)
          for (final element in layout)
            element.isTarget
                ? PromptElement(type: 'gap', text: element.targetId)
                : PromptElement(type: 'text', text: element.text),
      ],
    );
  }

  ExerciseEvaluation _buildEvaluation() {
    switch (primitive) {
      case ExercisePrimitive.select:
        return ExerciseEvaluation(
          kind: 'selected_items',
          correctItemIds: canonicalEvaluation.correctItemIds,
          gapAssignments: targetAssignments,
        );
      case ExercisePrimitive.input:
        final effective = effectiveOptions;
        String rule<T extends OptionEnumValue>(OptionKey key, T strict) =>
            effective.enumValue<T>(key) == strict ? 'preserve' : 'ignore';
        return ExerciseEvaluation(
          kind: 'text_match',
          accepted: accepted,
          normalization: {
            'case': rule(OptionKey.caseHandling, CaseHandling.exact),
            'punctuation': rule(
              OptionKey.punctuationHandling,
              PunctuationHandling.exact,
            ),
            'whitespace':
                effective.enumValue<WhitespaceHandling>(
                      OptionKey.whitespaceHandling,
                    ) ==
                    WhitespaceHandling.exact
                ? 'preserve'
                : 'normalize',
            'accents':
                effective.enumValue<AccentHandling>(OptionKey.accentHandling) ==
                    AccentHandling.ignore
                ? 'ignore'
                : 'preserve',
          },
        );
      case ExercisePrimitive.arrange:
        return ExerciseEvaluation(
          kind: 'ordered_items',
          correctOrders: canonicalEvaluation.correctOrders,
          gapAssignments: targetAssignments,
        );
      case ExercisePrimitive.match:
        return ExerciseEvaluation(
          kind: 'matched_items',
          pairs: canonicalEvaluation.relations,
        );
      case ExercisePrimitive.presentation:
        return const ExerciseEvaluation(kind: 'selected_items');
      case ExercisePrimitive.assign:
      case ExercisePrimitive.speak:
      case ExercisePrimitive.ink:
      case ExercisePrimitive.submit:
        return ExerciseEvaluation(kind: canonicalEvaluation.mode.serialized);
    }
  }

  // Author-friendly compatibility views. These are derived from primitives.
  String get type => primitive == ExercisePrimitive.presentation
      ? 'flashcard'
      : _legacyTypeFromTemplate(editorTemplate, primitive.serialized);
  String _promptRole(String role) =>
      promptElements
          .where((e) => e.role == role && e.type == 'text')
          .map((e) => e.text)
          .firstOrNull ??
      '';
  String get prompt {
    if (primitive == ExercisePrimitive.presentation) return _promptRole('term');
    if (primitive == ExercisePrimitive.input && layout.isNotEmpty) {
      return inlineSentence;
    }
    return _promptRole('context').isNotEmpty
        ? _promptRole('context')
        : _promptRole('passage').isNotEmpty
        ? _promptRole('passage')
        : _promptRole('situation').isNotEmpty
        ? _promptRole('situation')
        : _promptRole('primary').isNotEmpty
        ? _promptRole('primary')
        : _promptRole('clue');
  }

  /// The inline layout as one sentence: a target with a first-grapheme
  /// reveal reads `___`, any other target reads its first accepted answer.
  String get inlineSentence => [
    for (final element in layout)
      if (element.isText)
        element.text
      else if (_targetById(element.targetId)?.reveal != null)
        '___'
      else
        _firstAnswerOf(element.targetId),
  ].join();

  ExerciseTarget? _targetById(String id) =>
      targets.where((target) => target.id == id).firstOrNull;

  String _firstAnswerOf(String targetId) =>
      canonicalEvaluation.targetAnswers
          .where((answers) => answers.targetId == targetId)
          .expand((answers) => answers.answers)
          .firstOrNull ??
      '';

  String get question => primitive == ExercisePrimitive.presentation
      ? _promptRole('meaning')
      : _promptRole('question');
  String? get tts {
    final a = promptElements
        .where((e) => e.type == 'audio')
        .map((e) => e.text)
        .firstOrNull;
    return a == null || a.isEmpty ? null : a;
  }

  List<String> get answers {
    if (primitive == ExercisePrimitive.presentation) {
      final usage = _promptRole('usage');
      final translation = _promptRole('usage_translation');
      return [
        if (usage.isNotEmpty) usage,
        if (translation.isNotEmpty) translation,
      ];
    }
    if (primitive == ExercisePrimitive.match && type == 'audio_match') {
      return canonicalEvaluation.relations
          .map((p) {
            final it = items.where((x) => x.id == p[1]).firstOrNull;
            return it?.value ?? '';
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (primitive == ExercisePrimitive.match) return const [];
    return items.map((e) => e.value).where((e) => e.isNotEmpty).toList();
  }

  int? get correct {
    if (canonicalEvaluation.correctItemIds.isEmpty) return null;
    final id = canonicalEvaluation.correctItemIds.first;
    final i = items.indexWhere((e) => e.id == id);
    return i < 0 ? null : i;
  }

  /// Every accepted text of an Input: the single field's answers, or the
  /// answers of every inline gap in target order.
  List<String> get accepted => canonicalEvaluation.targetAnswers.isEmpty
      ? canonicalEvaluation.answers
      : [
          for (final target in targets)
            ...canonicalEvaluation.targetAnswers
                .where((answers) => answers.targetId == target.id)
                .expand((answers) => answers.answers),
        ];

  /// Listen for missing words: the first accepted answer of each gap, in
  /// order. Empty for every other exercise.
  List<String> get missingWords => primitive == ExercisePrimitive.input
      ? [
          for (final target in targets)
            if (target.reveal == null)
              for (final answers in canonicalEvaluation.targetAnswers)
                if (answers.targetId == target.id && answers.answers.isNotEmpty)
                  answers.answers.first,
        ]
      : const [];
  List<String> get tokens =>
      items.map((e) => e.value).where((e) => e.isNotEmpty).toList();

  /// Whether this exercise uses an inline layout with targets.
  bool get hasInlineTargets => layout.any((element) => element.isTarget);

  /// Target ID -> the one item it must hold (gap grading).
  Map<String, String> get targetAssignments => {
    for (final assignment in canonicalEvaluation.assignments)
      if (assignment.itemIds.isNotEmpty)
        assignment.targetId: assignment.itemIds.first,
  };

  /// Whether this Arrange exercise uses the inline-gap layout instead of the
  /// whole-sentence tile builder.
  bool get hasArrangeGaps =>
      primitive == ExercisePrimitive.arrange && hasInlineTargets;

  /// Whether this Select exercise allows choosing more than one option.
  bool get isMultiSelect =>
      primitive == ExercisePrimitive.select &&
      options.enumValue<SelectionMode>(OptionKey.selectionMode) ==
          SelectionMode.multiple;

  /// The minimum number of options a multi-select Select exercise requires
  /// before it can be submitted. Meaningless for single-select exercises.
  int get requiredSelectionCount {
    final minimum = options.intValue(OptionKey.minimumSelections) ?? 1;
    return minimum < 1 ? 1 : minimum;
  }

  /// The maximum number of options a multi-select Select exercise allows to
  /// be selected at once. 1 for every single-select exercise.
  int get maxSelectionCount {
    if (!isMultiSelect) return 1;
    final maximum = options.intValue(OptionKey.maximumSelections);
    return maximum == null || maximum < 1 ? items.length : maximum;
  }

  /// The full set of correct item IDs, used for set-based exact-match
  /// correctness on multi-select Select exercises.
  Set<String> get correctItemIdSet =>
      canonicalEvaluation.correctItemIds.toSet();

  /// Whether this Select exercise embeds inline gaps whose values are filled
  /// by selecting linked options.
  bool get hasSelectGaps =>
      primitive == ExercisePrimitive.select && hasInlineTargets;
  List<String> get orderAnswer =>
      canonicalEvaluation.correctOrders.firstOrNull?.itemIds
          .map((id) {
            final it = items.where((x) => x.id == id).firstOrNull;
            return it?.value ?? '';
          })
          .where((e) => e.isNotEmpty)
          .toList() ??
      const [];
  List<List<String>> get orderAnswers => canonicalEvaluation.correctOrders
      .map(
        (answer) => answer.itemIds
            .map((id) {
              final it = items.where((x) => x.id == id).firstOrNull;
              return it?.value ?? '';
            })
            .where((e) => e.isNotEmpty)
            .toList(growable: false),
      )
      .toList(growable: false);
  List<String> get correctTranslationTexts => canonicalEvaluation.correctOrders
      .map((answer) => answer.text)
      .toList(growable: false);
  List<List<String>> get pairs => canonicalEvaluation.relations
      .map((p) {
        if (p.length != 2) return <String>[];
        String val(String id) =>
            items.where((x) => x.id == id).map((x) => x.value).firstOrNull ??
            id;
        return [val(p[0]), val(p[1])];
      })
      .where((p) => p.length == 2)
      .toList();
  List<String> get icons => items
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
    'script_recognition',
    'gap_choice',
    'icon_choice',
    'listening_choice',
    'listening_comprehension',
    'reading_comprehension',
    'dialogue_response',
    'contextual_comprehension',
    'translation_choice_to_target',
    'translation_choice_to_source',
    'flashcard',
  }.contains(type)) {
    final items = <ExerciseItem>[];
    for (var i = 0; i < answers.length; i++) {
      items.add(
        ExerciseItem(
          id: 'item_$i',
          content: [
            PromptElement(type: 'text', text: answers[i]),
            if (i < icons.length && icons[i].isNotEmpty)
              _isImageReference(icons[i])
                  ? PromptElement(type: 'image', asset: icons[i])
                  : PromptElement(role: 'icon', type: 'text', text: icons[i]),
          ],
        ),
      );
    }
    return ExerciseInteraction(kind: 'select', items: items);
  }
  if (const {
    'fill_blank',
    'type_missing_word',
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
    'script_recognition',
    'gap_choice',
    'icon_choice',
    'listening_choice',
    'listening_comprehension',
    'reading_comprehension',
    'dialogue_response',
    'contextual_comprehension',
    'translation_choice_to_target',
    'translation_choice_to_source',
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
    'type_missing_word',
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

  List<int>? matchEntries(
    List<String> entries,
    String Function(String) comparable,
  ) {
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

  List<int>? split(String Function(String) comparable) {
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

    return visit(sentence, const <int>{});
  }

  // Exact capitals first; then capitals ignored (owner decision, 29
  // September 2026: a capital that differs is an Audit Warning,
  // ARRANGE_ANSWER_CASE_DIFFERS, never an answer without its blocks).
  String caseless(String value) => comparable(value).toLowerCase();
  final indexes =
      matchEntries(authoredOrder, comparable) ??
      split(comparable) ??
      matchEntries(authoredOrder, caseless) ??
      split(caseless);
  if (indexes == null || indexes.isEmpty) return const [];
  return indexes.map((index) => 'item_$index').toList(growable: false);
}

/// Whether an icon key names a picture the item carries as an image element
/// rather than a named icon or a bundled asset key: a Course medium or a
/// portable data URI (Build 256 Revision 4). Bundled `assets/` keys stay
/// icon keys, drawn as before.
bool _isImageReference(String value) =>
    value.startsWith('media:') || value.startsWith('data:');

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
  // A Build 256 Revision 4 catalogue preset reads as the recipe it is built
  // on (`presetRecipeBaseOf`); its own ID is not a v11 type.
  final base = presetRecipeBaseOf[template];
  if (base != null) return base;
  if (template.isNotEmpty) return template;
  return switch (interaction) {
    'select' => 'choice',
    'input' => 'fill_blank',
    'arrange' => 'word_order',
    'match' => 'matching',
    'presentation' => 'flashcard',
    _ => interaction,
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
