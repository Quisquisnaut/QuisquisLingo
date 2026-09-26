/// Which way a user file travels through a QQL folder.
enum QqlTransferDirection { imports, exports }

/// What kind of user file a QQL folder holds. A category names the kind of
/// file, never a place: each platform's layout decides where it lives.
enum QqlFileCategory {
  courses,
  merges,
  learnerData,
  recoveryKeys,
  audio,
  images,
  lessonIcons,
  courseFlags,
  auditReports,
  diagnosticLogs,
}

/// One logical QQL user folder, such as "the Quick Import source for
/// Courses". Feature code asks for a role; the platform layout decides
/// whether it means a desktop path, an Android shared-storage folder or,
/// later, an iOS document location.
///
/// Only the combinations QQL uses exist, as the constants below. They are
/// canonical constants, so identity equality is enough.
final class QqlStorageRole {
  const QqlStorageRole._(this.direction, this.category, this.placeholder);

  final QqlTransferDirection direction;
  final QqlFileCategory category;

  /// Name of the Help text placeholder, `{folderCourseImports}` and so on,
  /// which QQL replaces with this folder's label for the current platform.
  final String placeholder;

  /// Quick Import source for Course packages and media-free Course JSON.
  static const courseImports = QqlStorageRole._(
    QqlTransferDirection.imports,
    QqlFileCategory.courses,
    'folderCourseImports',
  );

  /// Quick Export destination for Course packages.
  static const courseExports = QqlStorageRole._(
    QqlTransferDirection.exports,
    QqlFileCategory.courses,
    'folderCourseExports',
  );

  /// Where the second Course of a Course Merge is read from (ToBeMerged,
  /// beside Import rather than inside it).
  static const mergeImports = QqlStorageRole._(
    QqlTransferDirection.imports,
    QqlFileCategory.merges,
    'folderMergeImports',
  );

  /// Import my data reads `learner_import.json` here.
  static const learnerDataImports = QqlStorageRole._(
    QqlTransferDirection.imports,
    QqlFileCategory.learnerData,
    'folderLearnerDataImports',
  );

  /// Export my data writes the learner backup here.
  static const learnerDataExports = QqlStorageRole._(
    QqlTransferDirection.exports,
    QqlFileCategory.learnerData,
    'folderLearnerDataExports',
  );

  /// Import User Recovery Key searches here.
  static const recoveryKeyImports = QqlStorageRole._(
    QqlTransferDirection.imports,
    QqlFileCategory.recoveryKeys,
    'folderRecoveryKeyImports',
  );

  /// Export User Recovery Key writes here.
  static const recoveryKeyExports = QqlStorageRole._(
    QqlTransferDirection.exports,
    QqlFileCategory.recoveryKeys,
    'folderRecoveryKeyExports',
  );

  /// Import MP3 reads every MP3 here.
  static const audioImports = QqlStorageRole._(
    QqlTransferDirection.imports,
    QqlFileCategory.audio,
    'folderAudioImports',
  );

  /// Single images and Image Bank ZIPs are read here.
  static const imageImports = QqlStorageRole._(
    QqlTransferDirection.imports,
    QqlFileCategory.images,
    'folderImageImports',
  );

  /// Import custom icon reads the one Lesson icon image here.
  static const lessonIconImports = QqlStorageRole._(
    QqlTransferDirection.imports,
    QqlFileCategory.lessonIcons,
    'folderLessonIconImports',
  );

  /// Upload custom flag reads `flag.png`, `flag.jpg` or `flag.jpeg` here.
  static const courseFlagImports = QqlStorageRole._(
    QqlTransferDirection.imports,
    QqlFileCategory.courseFlags,
    'folderCourseFlagImports',
  );

  /// Export Audit report writes here.
  static const auditReportExports = QqlStorageRole._(
    QqlTransferDirection.exports,
    QqlFileCategory.auditReports,
    'folderAuditReportExports',
  );

  /// Export Diagnostic Log and the Crash Log's Quick Export write their
  /// copies here (Logs).
  static const diagnosticLogExports = QqlStorageRole._(
    QqlTransferDirection.exports,
    QqlFileCategory.diagnosticLogs,
    'folderDiagnosticLogExports',
  );

  static const values = <QqlStorageRole>[
    courseImports,
    courseExports,
    mergeImports,
    learnerDataImports,
    learnerDataExports,
    recoveryKeyImports,
    recoveryKeyExports,
    audioImports,
    imageImports,
    lessonIconImports,
    courseFlagImports,
    auditReportExports,
    diagnosticLogExports,
  ];

  @override
  String toString() => '${direction.name}.${category.name}';
}
