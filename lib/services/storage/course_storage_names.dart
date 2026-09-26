import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../models/course_models.dart';

/// The names of QQL's per-Course files and folders, the same on every system
/// (Build 255 Revision 4): `QQL_` (or `QQL_bkp_` for a backup), the Course's
/// language pair, source then target (`EN_IT`), and its ID, or the ID's hash
/// for a media folder. Sorting by name groups a pair; there are no language
/// folder levels.
///
/// Plain Dart (no Flutter), so the one-off move tool uses the same rules.
class CourseStorageNames {
  const CourseStorageNames._();

  static const prefix = 'QQL';
  static const backupPrefix = 'QQL_bkp';

  /// What a language code falls back to when a Course names no language.
  static const unknownLanguage = 'UNKNOWN';

  /// A fallback code built from a name is cut to this length, so an unusual
  /// language name cannot make paths long.
  static const maxCodeLength = 16;

  /// Known language names, in lower case, by code. The tag of a Course wins
  /// over this table; a name missing here is used itself, in capitals.
  static const Map<String, String> codesByName = {
    'arabic': 'AR',
    'basque': 'EU',
    'euskara': 'EU',
    'breton': 'BR',
    'catalan': 'CA',
    'català': 'CA',
    'chinese': 'ZH',
    'czech': 'CS',
    'danish': 'DA',
    'dutch': 'NL',
    'nederlands': 'NL',
    'english': 'EN',
    'esperanto': 'EO',
    'finnish': 'FI',
    'suomi': 'FI',
    'french': 'FR',
    'français': 'FR',
    'francais': 'FR',
    'friulian': 'FUR',
    'friulano': 'FUR',
    'furlan': 'FUR',
    'galician': 'GL',
    'galego': 'GL',
    'german': 'DE',
    'deutsch': 'DE',
    'greek': 'EL',
    'hebrew': 'HE',
    'hindi': 'HI',
    'hungarian': 'HU',
    'irish': 'GA',
    'italian': 'IT',
    'italiano': 'IT',
    'japanese': 'JA',
    'korean': 'KO',
    'latin': 'LA',
    'ligurian': 'LIJ',
    'ligure': 'LIJ',
    'lombard': 'LMO',
    'lombardo': 'LMO',
    'mirandese': 'MWL',
    'mirandés': 'MWL',
    'neapolitan': 'NAP',
    'napoletano': 'NAP',
    'norwegian': 'NO',
    'piedmontais': 'PMS',
    'piedmontese': 'PMS',
    'piemontese': 'PMS',
    'piemontèis': 'PMS',
    'polish': 'PL',
    'portuguese': 'PT',
    'português': 'PT',
    'portugues': 'PT',
    'romanian': 'RO',
    'russian': 'RU',
    'sardinian': 'SC',
    'sardo': 'SC',
    'scottish gaelic': 'GD',
    'sicilian': 'SCN',
    'siciliano': 'SCN',
    'spanish': 'ES',
    'español': 'ES',
    'espanol': 'ES',
    'swedish': 'SV',
    'turkish': 'TR',
    'ukrainian': 'UK',
    'venetian': 'VEC',
    'veneto': 'VEC',
    'welsh': 'CY',
    'cymraeg': 'CY',
  };

  /// One language code: the primary subtag of [tag] in capitals when it has
  /// one (`it-IT` → `IT`, `nap-IT` → `NAP`), otherwise the code of [name] from
  /// [codesByName], otherwise [name] itself in capitals with letters and
  /// digits only, otherwise [unknownLanguage].
  static String languageCode({String? tag, String? name}) {
    final primary = (tag ?? '').trim().split(RegExp('[-_]')).first;
    if (RegExp(r'^[A-Za-z]{2,8}$').hasMatch(primary)) {
      return primary.toUpperCase();
    }
    final normalized = (name ?? '').trim().toLowerCase();
    final known = codesByName[normalized];
    if (known != null) return known;
    final letters = normalized.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (letters.isEmpty) return unknownLanguage;
    return letters.length > maxCodeLength
        ? letters.substring(0, maxCodeLength)
        : letters;
  }

  /// The pair `SOURCE_TARGET` for a Course's languages. The target comes from
  /// the target language tag when there is one, then the target language
  /// name, then the learning language.
  static String pair({
    required String sourceLanguage,
    required String targetLanguage,
    String targetLanguageTag = '',
    String learningLanguage = '',
  }) {
    final target = targetLanguage.trim().isNotEmpty
        ? targetLanguage
        : learningLanguage;
    return '${languageCode(name: sourceLanguage)}_'
        '${languageCode(tag: targetLanguageTag, name: target)}';
  }

  /// [pair] for a Course.
  static String pairOfCourse(Course course) => pair(
    sourceLanguage: course.sourceLanguage,
    targetLanguage: course.targetLanguage,
    targetLanguageTag: course.targetLanguageTag,
    learningLanguage: course.learningLanguage,
  );

  /// [pair] for a Course's JSON, as stored or packaged.
  static String pairOfJson(Map<Object?, Object?> course) {
    String field(String key) {
      final value = course[key];
      return value is String ? value : '';
    }

    return pair(
      sourceLanguage: field('sourceLanguage'),
      targetLanguage: field('targetLanguage'),
      targetLanguageTag: field('targetLanguageTag'),
      learningLanguage: field('learningLanguage'),
    );
  }

  /// A Course ID in a form that is safe as part of a file name. Lossy: the
  /// stores check the ID inside a file and never replace another Course's.
  static String sanitizedId(String courseId) {
    final clean = courseId
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (clean.isEmpty || clean == '.' || clean == '..') {
      throw const FormatException('Course ID cannot form a safe backup path.');
    }
    return clean;
  }

  /// The ID as names show it: [sanitizedId] without the `course_` that
  /// QQL-made IDs start with, so it is not repeated after the prefix.
  static String idPart(String courseId) {
    final safe = sanitizedId(courseId);
    const own = 'course_';
    return safe.startsWith(own) && safe.length > own.length
        ? safe.substring(own.length)
        : safe;
  }

  /// The lowercase SHA-256 of the ID, which names a Course's media folder.
  static String hashOf(String courseId) {
    final value = courseId.trim();
    if (value.isEmpty) {
      throw ArgumentError.value(courseId, 'courseId', 'Course ID is required');
    }
    return sha256.convert(utf8.encode(value)).toString();
  }

  // ---- Stored Course files: QQL_<pair>_<id>.json

  static String courseFileName(String courseId, String pair) =>
      '${prefix}_${pair}_${idPart(courseId)}.json';

  static final RegExp _courseFile = RegExp(
    r'^QQL_[A-Z0-9]+_[A-Z0-9]+_(.+)\.json$',
  );

  /// The ID part of a stored Course file name, or null for another name.
  static String? idPartOfCourseFile(String fileName) =>
      _courseFile.firstMatch(fileName)?.group(1);

  // ---- Media folders: QQL_<pair>_<hash>, or QQL_<hash> before the first save

  /// The media folder of [courseId]; without [pair], the neutral name a new
  /// Course's folder has until its first confirmed save.
  static String mediaFolderName(String courseId, {String? pair}) =>
      mediaFolderNameOfHash(hashOf(courseId), pair: pair);

  /// [mediaFolderName] from the ID hash, for a folder known only by it.
  static String mediaFolderNameOfHash(String hash, {String? pair}) =>
      pair == null ? '${prefix}_$hash' : '${prefix}_${pair}_$hash';

  static final RegExp _mediaFolder = RegExp(
    r'^QQL_(?:[A-Z0-9]+_[A-Z0-9]+_)?([0-9a-f]{64})$',
  );

  /// The ID hash a media folder name ends with, or null for another name.
  static String? hashOfMediaFolder(String folderName) =>
      _mediaFolder.firstMatch(folderName)?.group(1);

  // ---- Backups: QQL_bkp_<pair>_<id>/ with QQL_bkp_<pair>_<id>_v<version>_<stamp>.json

  static String backupFolderName(String courseId, String pair) =>
      '${backupPrefix}_${pair}_${idPart(courseId)}';

  static final RegExp _backupFolder = RegExp(
    r'^QQL_bkp_[A-Z0-9]+_[A-Z0-9]+_(.+)$',
  );

  /// The ID part of a backup folder name, or null for another name.
  static String? idPartOfBackupFolder(String folderName) =>
      _backupFolder.firstMatch(folderName)?.group(1);

  /// The name, without `.json`, of one saved version in a backup folder. A
  /// Course without a version is saved as version 0.
  static String backupVersionName(
    String courseId,
    String pair, {
    required String version,
    required String stamp,
  }) {
    final safeVersion = _safe(version);
    return '${backupFolderName(courseId, pair)}'
        '_v${safeVersion.isEmpty ? '0' : safeVersion}_$stamp';
  }

  // ---- Exported packages: QQL_<pair>_<title>, QQL_bkp_<pair>_<title>_v<version>

  /// The base name of an exported Course package; an earlier version from
  /// Version History is marked as a backup and carries its version.
  static String exportBaseName({
    required String pair,
    required String title,
    String? historicalVersion,
  }) {
    final safeTitle = title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final name = safeTitle.isEmpty ? 'custom_course' : safeTitle;
    if (historicalVersion == null) return '${prefix}_${pair}_$name';
    final version = _safe(historicalVersion);
    return version.isEmpty
        ? '${backupPrefix}_${pair}_$name'
        : '${backupPrefix}_${pair}_${name}_v$version';
  }

  static String _safe(String value) => value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9.-]+'), '_')
      .replaceAll(RegExp(r'^[_.]+|[_.]+$'), '');
}
