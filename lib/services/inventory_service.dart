import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/authoring_team.dart';
import '../models/course_models.dart';
import 'course_editor_service.dart';
import 'course_file_store.dart';
import 'profile_service.dart';
import 'course_media_store.dart';
import 'course_favorite_service.dart';
import 'course_received_service.dart';
import 'publisher_export_memory.dart';
import 'course_wizard.dart';
import 'course_wizard_memory.dart';
import 'diagnostic_log_service.dart';
import 'storage/atomic_preferences_store.dart';
import 'exercise_image_service.dart';
import 'image_bank_service.dart';
import 'team_service.dart';
import 'import/import_stager.dart';
import 'storage/course_storage_names.dart';
import 'storage/qql_earlier_private_folders.dart';
import 'storage/qql_storage.dart';

/// What Delete or Forget does to an Inventory item (Build 266 Revision 2,
/// owner decisions of 8 October 2026). `InventoryActionService` runs it,
/// after the admin's PIN, through the rules the rest of QQL applies.
enum InventoryActionKind {
  /// A learner profile (ProfileService's rules: never the only admin, never
  /// a learner who maintains a Course).
  deleteLearner,

  /// One record in QQL's settings: a Favorite, a Received flag, a
  /// remembered publisher.
  forget,

  /// A stored custom Course (its Maintainer or Team; a Course this version
  /// cannot open also by an admin), with its Course media.
  deleteCourse,

  /// An installed Publisher Course.
  deletePublisherCourse,

  /// A file no stored Course or library record depends on.
  deleteFile,

  /// A Shared Image Library image an Admin added: its record and its file.
  deleteDeviceImage,

  /// An imported Image Bank with its images.
  removeImageBank,
}

class InventoryAction {
  const InventoryAction(
    this.kind,
    this.target, {
    required this.label,
    required this.explanation,
  });

  final InventoryActionKind kind;

  /// A learner ID, a settings key, a Course ID, a file path or a bank ID.
  final String target;

  /// The button: Delete, Forget or Remove bank.
  final String label;

  /// What it removes and what stays, for the confirmation.
  final String explanation;
}

/// One thing QQL stores because of user activity: a file, a folder, or a
/// record kept inside QQL's own settings (which has no file of its own).
class InventoryItem {
  final String name;

  /// Null for records that live inside QQL's settings.
  final String? path;
  final int? sizeBytes;
  final DateTime? modified;

  /// The learner or person this belongs to, when it can be determined.
  final String? owner;
  final String? note;

  /// Delete or Forget, where it applies (Build 266 Revision 2).
  final InventoryAction? action;

  /// The folder Open folder shows, where there is one.
  final String? folder;

  const InventoryItem({
    required this.name,
    this.path,
    this.sizeBytes,
    this.modified,
    this.owner,
    this.note,
    this.action,
    this.folder,
  });
}

class InventorySection {
  final String title;
  final String description;

  /// Where the section lives, or null when it is not a folder.
  final String? location;
  final List<InventoryItem> items;

  /// Items counted but not listed because the section was very large.
  final int hiddenCount;
  final int totalBytes;

  const InventorySection({
    required this.title,
    required this.description,
    required this.items,
    this.location,
    this.hiddenCount = 0,
    this.totalBytes = 0,
  });

  int get count => items.length + hiddenCount;
}

/// Lists what QQL has stored on this device because of what people did:
/// created inside the app, or added to QQL's folders from outside it.
class InventoryService {
  static const maxListedPerSection = 500;
  static const _maxJsonBytesForOwner = 5 * 1024 * 1024;

  final ProfileService _profiles;
  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _support;
  final Future<List<Course>> Function()? _courses;
  final CourseEditorService? _courseService;
  final Future<List<AuthoringTeam>> Function() _teams;
  final QqlStorage _storage;

  InventoryService({
    ProfileService? profiles,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? supportDirectory,
    Future<List<Course>> Function()? courses,
    Future<List<AuthoringTeam>> Function()? teams,
    QqlStorage? storage,
  }) : _profiles = profiles ?? ProfileService(),
       _storage = storage ?? QqlStorage(),
       _documents = documentsDirectory ?? getApplicationDocumentsDirectory,
       _support = supportDirectory ?? getApplicationSupportDirectory,
       _courseService = courses == null
           ? CourseEditorService(
               courseStore: CourseFileStore(supportDirectory: supportDirectory),
             )
           : null,
       _courses = courses,
       _teams = teams ?? (() => TeamService().listTeams());

  /// The QuisquisLingo folder's own folders, current and earlier, in lower
  /// case.
  static final _knownTopLevel = <String>{
    for (final folder in QqlTopFolder.values) folder.folderName.toLowerCase(),
    for (final name in QqlTopFolder.earlierFolders.keys) name.toLowerCase(),
  };

  Future<List<InventorySection>> load() async {
    final learners = await _profiles.getProfileRecords();
    final admins = await _profiles.getAdminProfileIds();
    final names = {for (final l in learners) l.learnerProfileId: l.displayName};

    List<Course> courses = const [];
    String? courseProblem;
    try {
      courses = await (_courses ?? _courseService!.listUserCourses)();
      // Unreadable files no longer hide the others; name them here.
      final unreadable = _courseService?.unreadableCourseFiles ?? const [];
      if (unreadable.isNotEmpty) {
        courseProblem =
            'These stored course files could not be read and were kept '
            'unchanged: ${unreadable.map((file) => file.fileName).join(', ')}.';
      }
    } catch (error) {
      courseProblem = 'The stored courses could not be read: $error';
    }
    var teams = <AuthoringTeam>[];
    try {
      teams = await _teams();
    } catch (_) {
      // Team names are only decoration on the course rows.
    }
    final teamNames = {for (final t in teams) t.teamId: t.displayName};

    String? ownerOf(Course course) {
      final maintainer = course.maintainer?.profileId;
      final parts = <String>[];
      if (maintainer != null) {
        parts.add(
          'Maintainer: ${names[maintainer] ?? 'a learner no longer on this device'}',
        );
      } else {
        parts.add('Creator: ${course.originalCourseCreator.displayName}');
      }
      final team = course.assignedTeamId;
      if (team != null && team.isNotEmpty) {
        parts.add('Team: ${teamNames[team] ?? 'unknown Team'}');
      }
      return parts.join(' · ');
    }

    // On Android the user folders are public (Download/QuisquisLingo): the
    // app's own documents folder then holds only earlier versions' files.
    final public = _storage.publicFolders;
    final documentsRoot = Directory(
      '${(await _documents()).path}${Platform.pathSeparator}QuisquisLingo',
    );
    final supportRoot = (await _support()).path;
    final sep = Platform.pathSeparator;

    final sections = <InventorySection>[];

    // ---- Records kept inside QQL's settings
    sections.add(
      InventorySection(
        title: 'Learners',
        description:
            'Learner profiles, personal course membership, progress and settings. These are stored inside QQL’s own settings storage, so they have no file of their own.',
        items: [
          for (final learner in learners)
            InventoryItem(
              name: learner.displayName,
              owner: admins.contains(learner.learnerProfileId)
                  ? '${learner.displayName} (admin)'
                  : learner.displayName,
              note: 'Stored inside QQL settings (no file).',
              action: InventoryAction(
                InventoryActionKind.deleteLearner,
                learner.learnerProfileId,
                label: 'Delete',
                explanation:
                    'Delete the learner ${learner.displayName} with their '
                    'progress and settings. The usual rules apply: the only '
                    'admin cannot be deleted, nor a learner who maintains a '
                    'Course.',
              ),
            ),
        ],
      ),
    );

    final preferences = await SharedPreferences.getInstance();
    final favoriteFlags = <({String courseId, String profileId, String key})>[];
    const learnerPrefix = 'learner_';
    const favoriteMarker = '_${CourseFavoriteService.keyPrefix}';
    for (final key in preferences.getKeys()) {
      if (!key.startsWith(learnerPrefix)) continue;
      final markerAt = key.indexOf(favoriteMarker, learnerPrefix.length);
      if (markerAt < 0) continue;
      final profileId = key.substring(learnerPrefix.length, markerAt);
      if (!ProfileService.isValidLearnerProfileId(profileId) ||
          preferences.getBool(key) != true) {
        continue;
      }
      final encodedCourseId = key.substring(markerAt + favoriteMarker.length);
      if (encodedCourseId.isEmpty) continue;
      String courseId;
      try {
        courseId = Uri.decodeComponent(encodedCourseId);
      } on FormatException {
        courseId = encodedCourseId;
      }
      favoriteFlags.add((courseId: courseId, profileId: profileId, key: key));
    }
    favoriteFlags.sort((a, b) {
      final byCourse = a.courseId.compareTo(b.courseId);
      return byCourse != 0 ? byCourse : a.profileId.compareTo(b.profileId);
    });
    sections.add(
      InventorySection(
        title: 'Course Favorites',
        description:
            'Per-learner Course Favorite flags stored inside QQL settings. They do not change Personal Library membership or Course files.',
        items: [
          for (final favorite in favoriteFlags.take(maxListedPerSection))
            InventoryItem(
              name: favorite.courseId,
              owner:
                  names[favorite.profileId] ??
                  'a learner no longer on this device',
              note: 'Course Favorite flag in QQL settings (no file).',
              action: InventoryAction(
                InventoryActionKind.forget,
                favorite.key,
                label: 'Forget',
                explanation:
                    'Forget that this Course is a Favorite of '
                    '${names[favorite.profileId] ?? 'this learner'}. The '
                    'Course, its membership and its progress stay.',
              ),
            ),
        ],
        hiddenCount: favoriteFlags.length > maxListedPerSection
            ? favoriteFlags.length - maxListedPerSection
            : 0,
      ),
    );

    final receivedKeys =
        preferences
            .getKeys()
            .where(
              (key) =>
                  key.startsWith(CourseReceivedService.keyPrefix) &&
                  preferences.getBool(key) == true,
            )
            .toList()
          ..sort();
    String receivedCourseId(String key) {
      final encoded = key.substring(CourseReceivedService.keyPrefix.length);
      try {
        return Uri.decodeComponent(encoded);
      } on FormatException {
        return encoded;
      }
    }

    sections.add(
      InventorySection(
        title: 'Received Custom Courses',
        description:
            'Device-level flags for imported Custom Courses whose Maintainer and assigned Team were not on this device when installed. They are stored inside QQL settings.',
        items: [
          for (final key in receivedKeys.take(maxListedPerSection))
            InventoryItem(
              name: receivedCourseId(key),
              note: 'Received Custom Course flag in QQL settings (no file).',
              action: InventoryAction(
                InventoryActionKind.forget,
                key,
                label: 'Forget',
                explanation:
                    'Forget that this Custom Course was received. The Course '
                    'stays; a newer version from its Maintainer is then '
                    'offered only as a copy.',
              ),
            ),
        ],
        hiddenCount: receivedKeys.length > maxListedPerSection
            ? receivedKeys.length - maxListedPerSection
            : 0,
      ),
    );

    // The publisher each Course was last exported for (Export as Publisher
    // Course, owner request of 4 October 2026).
    final memory = PublisherExportMemory();
    final publisherKeys =
        preferences
            .getKeys()
            .where((key) => key.startsWith(PublisherExportMemory.keyPrefix))
            .toList()
          ..sort();
    final publisherItems = <InventoryItem>[];
    for (final key in publisherKeys.take(maxListedPerSection)) {
      final encoded = key.substring(PublisherExportMemory.keyPrefix.length);
      String courseId;
      try {
        courseId = Uri.decodeComponent(encoded);
      } on FormatException {
        courseId = encoded;
      }
      final publisher = await memory.recall(courseId);
      publisherItems.add(
        InventoryItem(
          name: courseId,
          action: InventoryAction(
            InventoryActionKind.forget,
            key,
            label: 'Forget',
            explanation:
                'Forget the publisher this Course was last exported for. The '
                'next Export as Publisher Course starts with empty fields.',
          ),
          note: publisher == null
              ? 'Unreadable remembered publisher in QQL settings (no file).'
              : 'Last exported as a Publisher Course of '
                    '${publisher.publisherName} (${publisher.publisherId}); '
                    'in QQL settings (no file).',
        ),
      );
    }
    sections.add(
      InventorySection(
        title: 'Remembered publishers',
        description:
            'The publisher ID and name each Course was last exported for with Export as Publisher Course, filled in at the next export. They are stored inside QQL settings.',
        items: publisherItems,
        hiddenCount: publisherKeys.length > maxListedPerSection
            ? publisherKeys.length - maxListedPerSection
            : 0,
      ),
    );

    // Where each paused Course Wizard stands (Build 267).
    final wizardKeys =
        preferences
            .getKeys()
            .where((key) => key.startsWith(CourseWizardMemory.keyPrefix))
            .toList()
          ..sort();
    sections.add(
      InventorySection(
        title: 'Paused Course Wizards',
        description:
            'The step where the Course Wizard of each Course stopped, so it can be continued from Course Studio. They are stored inside QQL settings.',
        items: [
          for (final key in wizardKeys.take(maxListedPerSection))
            InventoryItem(
              name: CourseWizardMemory.courseIdOfKey(key),
              note: switch (preferences.get(key)) {
                final String raw when CourseWizardPause.decode(raw) != null =>
                  '${CourseWizardPause.decode(raw)!.description}; in QQL settings (no file).',
                _ =>
                  'Unreadable paused Course Wizard in QQL settings (no file).',
              },
              action: InventoryAction(
                InventoryActionKind.forget,
                key,
                label: 'Forget',
                explanation:
                    'Forget where the Course Wizard stopped. The Course '
                    'stays as it is saved and is continued by hand in the '
                    'Course Editor.',
              ),
            ),
        ],
        hiddenCount: wizardKeys.length > maxListedPerSection
            ? wizardKeys.length - maxListedPerSection
            : 0,
      ),
    );

    // ---- Folders; [only] lists just those subfolders of [directory]
    Future<InventorySection> folder({
      required String title,
      required String description,
      required Directory directory,
      List<String>? only,
      required Future<InventoryItem> Function(File file, Directory root)
      describe,
    }) async {
      final files = only == null
          ? await _files(directory)
          : [
              for (final name in only)
                ...await _files(Directory('${directory.path}$sep$name')),
            ];
      final items = <InventoryItem>[];
      var total = 0;
      for (final file in files) {
        final stat = await file.stat();
        total += stat.size;
        if (items.length < maxListedPerSection) {
          items.add(await describe(file, directory));
        }
      }
      items.sort(
        (a, b) =>
            (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)),
      );
      return InventorySection(
        title: title,
        description: description,
        location: directory.path,
        items: items,
        hiddenCount: files.length - items.length,
        totalBytes: total,
      );
    }

    /// A file, its folder to open and, unless [deletable] is false or
    /// [action] says otherwise, Delete.
    Future<InventoryItem> plain(
      File file,
      Directory root, {
      String? note,
      String? owner,
      bool deletable = true,
      InventoryAction? action,
    }) async {
      final stat = await file.stat();
      final name = _relative(file, root);
      return InventoryItem(
        name: name,
        path: file.path,
        sizeBytes: stat.size,
        modified: stat.modified,
        owner: owner,
        note: note,
        folder: file.parent.path,
        action:
            action ??
            (deletable
                ? InventoryAction(
                    InventoryActionKind.deleteFile,
                    file.path,
                    label: 'Delete',
                    explanation:
                        'Delete the file $name from this device. QQL does '
                        'not need it to run.',
                  )
                : null),
      );
    }

    Future<String?> rawCourseIdOf(File file) async {
      try {
        final decoded = jsonDecode(await file.readAsString());
        final id = decoded is Map ? decoded['courseId'] : null;
        return id is String && id.trim().isNotEmpty ? id : null;
      } catch (_) {
        return null;
      }
    }

    Future<String?> ownerFromJson(File file) async {
      try {
        if (!file.path.toLowerCase().endsWith('.json')) return null;
        if (await file.length() > _maxJsonBytesForOwner) return null;
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is! Map) return null;
        final id = decoded['learnerProfileId'];
        if (id is String) {
          final shown = names[id];
          if (shown != null) return shown;
          final stored = decoded['displayName'];
          return '${stored is String ? stored : 'a learner'} (no longer on this device)';
        }
        final course = decoded['course'] is Map
            ? decoded['course'] as Map
            : decoded;
        final maintainer = course['maintainer'];
        if (maintainer is Map && maintainer['profileId'] is String) {
          final pid = maintainer['profileId'] as String;
          return 'Maintainer: ${names[pid] ?? 'a learner no longer on this device'}';
        }
        final creator = course['originalCourseCreator'];
        if (creator is Map && creator['displayName'] is String) {
          return 'Creator: ${creator['displayName']}';
        }
      } catch (_) {
        // Unreadable or foreign JSON simply has no known owner.
      }
      return null;
    }

    // A stored file is `QQL_<pair>_<ID>.json`: it is matched by the ID part,
    // which stays when the Course's languages change.
    final courseByFile = <String, Course>{
      for (final course in courses)
        '${course.originType == CourseOriginType.custom ? CourseStoreKind.custom.directoryName : CourseStoreKind.externalOfficial.directoryName}$sep${CourseStorageNames.idPart(course.courseId)}':
            course,
    };
    Course? storedCourse(String relative) {
      final parts = relative.split(RegExp(r'[\\/]'));
      if (parts.length != 2) return null;
      final idPart = CourseStorageNames.idPartOfCourseFile(parts.last);
      return idPart == null ? null : courseByFile['${parts.first}$sep$idPart'];
    }

    sections.add(
      await folder(
        title: 'Custom and installed courses',
        description:
            'Courses created or installed on this device, stored as one file per course. Export a course from Course Studio to share it.'
            '${courseProblem == null ? '' : ' $courseProblem'}',
        directory: Directory(
          '$supportRoot$sep${CourseFileStore.rootDirectoryName}',
        ),
        describe: (file, root) async {
          final relative = _relative(file, root);
          final course = storedCourse(relative);
          final stat = await file.stat();
          final inCustom = relative.startsWith(
            CourseStoreKind.custom.directoryName,
          );
          // A Course this version cannot open is deleted through the Course
          // rules by its ID when its JSON names one; any other file is
          // deleted as a file (Build 266 Revision 2).
          final rawId = course == null && inCustom
              ? await rawCourseIdOf(file)
              : null;
          final title = course == null
              ? relative
              : (course.title.isEmpty ? course.courseId : course.title);
          return InventoryItem(
            name: title,
            path: file.path,
            sizeBytes: stat.size,
            modified: stat.modified,
            owner: course == null ? await ownerFromJson(file) : ownerOf(course),
            note: course == null
                ? (rawId == null
                      ? 'Stored course file; course metadata unavailable.'
                      : 'Stored custom Course (ID $rawId) that this version '
                            'cannot open.')
                : '${course.originType == CourseOriginType.custom ? 'Custom course' : 'Installed external course'} · ID ${course.courseId}',
            folder: file.parent.path,
            action: course != null
                ? InventoryAction(
                    course.originType == CourseOriginType.custom
                        ? InventoryActionKind.deleteCourse
                        : InventoryActionKind.deletePublisherCourse,
                    course.courseId,
                    label: 'Delete',
                    explanation: course.originType == CourseOriginType.custom
                        ? 'Delete the Course “$title” and its Course media '
                              'from this device. Only its Maintainer or a '
                              'member of its Team may. Its backups stay.'
                        : 'Remove the Publisher Course “$title” from this '
                              'device. Its progress and media stay for a '
                              'reinstallation.',
                  )
                : rawId != null
                ? InventoryAction(
                    InventoryActionKind.deleteCourse,
                    rawId,
                    label: 'Delete',
                    explanation:
                        'Delete this stored Course, which this version cannot '
                        'open, and its Course media from this device. Its '
                        'Maintainer, a member of its Team or an admin may.',
                  )
                : InventoryAction(
                    InventoryActionKind.deleteFile,
                    file.path,
                    label: 'Delete',
                    explanation:
                        'Delete the file $relative, which QQL cannot read, '
                        'from this device.',
                  ),
          );
        },
      ),
    );

    // Course backups and exports are told apart by name and, for backups,
    // by the reason in their manifest.
    Future<InventoryItem> describeBackupOrExport(
      File file,
      Directory root,
    ) async {
      final rel = _relative(file, root);
      final lower = rel.toLowerCase();
      String kind;
      String? reason;
      final isBackup =
          RegExp(r'course backups v\d+').hasMatch(lower) ||
          root.path.endsWith('$sep${QqlTopFolder.backups.folderName}');
      if (isBackup) {
        kind = 'Course backup';
        try {
          if (lower.endsWith('.json') &&
              await file.length() <= _maxJsonBytesForOwner) {
            final decoded = jsonDecode(await file.readAsString());
            if (decoded is Map && decoded['reason'] is String) {
              reason = decoded['reason'] as String;
            }
          }
        } catch (_) {}
        if (reason != null && reason.toLowerCase().startsWith('pre-change')) {
          kind = 'Automatic course backup (made before a change)';
        }
      } else if (lower.endsWith('.user-recovery-key.json')) {
        kind = 'User Recovery Key';
      } else if (lower.contains('_backup') && lower.endsWith('.json')) {
        kind = 'Learner backup';
      } else {
        kind = 'Export';
      }
      return plain(file, root, note: kind, owner: await ownerFromJson(file));
    }

    // ---- QQL's private copies, the same on every system
    sections.add(
      await folder(
        title: 'Crash Log',
        description:
            'The live Crash Log, the Diagnostic Log and the session marker QQL uses to detect an abnormal shutdown. They are private to QQL; Settings › Debug saves copies in the Logs folder.',
        directory: Directory(
          '$supportRoot$sep${DiagnosticLogService.logsDirectoryName}',
        ),
        // The live Crash Log and session marker stay: Settings › Debug saves
        // copies (Save&Open).
        describe: (file, root) =>
            plain(file, root, note: 'Written by QQL.', deletable: false),
      ),
    );

    // ---- Learner-data safety copies (Build 270 Revision 0)
    final supportDirectory = Directory(supportRoot);
    final safetyCopies = await AtomicPreferencesStore.safetyCopiesIn(
      supportDirectory,
    );
    if (safetyCopies.isNotEmpty) {
      final items = <InventoryItem>[];
      var total = 0;
      for (final file in safetyCopies) {
        total += (await file.stat()).size;
        final name = file.uri.pathSegments.last;
        items.add(
          await plain(
            file,
            supportDirectory,
            note: name == AtomicPreferencesStore.lastGoodFileName
                ? 'The learner data as it was at the last start-up.'
                : 'A learner-data file QQL could not read, kept for a rescue.',
            deletable: false,
          ),
        );
      }
      sections.add(
        InventorySection(
          title: 'Learner-data safety copies',
          description:
              'QQL keeps its learner data (profiles, progress, settings) in '
              'one file. It also keeps the copy that loaded fine at the last '
              'start-up, used if that file is ever damaged, and any damaged '
              'file it found. Wipe everything removes them.',
          location: supportRoot,
          items: items,
          hiddenCount: 0,
          totalBytes: total,
        ),
      );
    }

    // ---- The QuisquisLingo folder: Export, Import, ToBeMerged, Logs and
    // Backups
    const topFolders = <(QqlTopFolder, String, String)>[
      (
        QqlTopFolder.export,
        'Export folder',
        'Files QQL saved with Quick Export: Course packages, learner backups, '
            'User Recovery Keys and Audit reports.',
      ),
      (
        QqlTopFolder.import,
        'Import folder',
        'Files copied into the Import folder from outside QQL: Courses, '
            'images, audio (MP3) files, lesson icons, flags, learner data and '
            'User Recovery Keys waiting to be imported. QQL only reads them; '
            'importing makes separate copies.',
      ),
      (
        QqlTopFolder.toBeMerged,
        'ToBeMerged folder',
        'Course files placed there for a Course Merge. QQL only reads them.',
      ),
      (
        QqlTopFolder.logs,
        'Logs folder',
        'Copies of the Crash Log and the Diagnostic Log saved with Quick '
            'Export in Settings › Debug.',
      ),
      (
        QqlTopFolder.backups,
        'Backups folder',
        'The Course Backups the Course Editor makes automatically before '
            'saving a change, one folder per Course in Courses, which Version '
            'History lists.',
      ),
    ];
    for (final (top, title, description) in topFolders) {
      final writtenByQql =
          top == QqlTopFolder.export ||
          top == QqlTopFolder.logs ||
          top == QqlTopFolder.backups;
      final note = writtenByQql ? 'Written by QQL.' : 'Added from outside QQL.';
      if (public == null) {
        sections.add(
          await folder(
            title: title,
            description: description,
            directory: Directory('${documentsRoot.path}$sep${top.folderName}'),
            describe: top == QqlTopFolder.export || top == QqlTopFolder.backups
                ? describeBackupOrExport
                : (file, root) => plain(file, root, note: note),
          ),
        );
        continue;
      }
      // Android: the public Download/QuisquisLingo folder.
      List<QqlPublicFile> files;
      try {
        files = await public.list(top);
      } catch (_) {
        files = const [];
      }
      files = [...files]
        ..sort(
          (a, b) =>
              (b.modified ?? DateTime(0)).compareTo(a.modified ?? DateTime(0)),
        );
      sections.add(
        InventorySection(
          title: title,
          description: writtenByQql
              ? '$description Only the files QQL wrote itself are listed.'
              : '$description They are listed only while QQL has permission '
                    'to read the QuisquisLingo folder.',
          location: public.label(top),
          items: [
            for (final file in files.take(maxListedPerSection))
              InventoryItem(
                name: file.name,
                sizeBytes: file.size,
                modified: file.modified,
                note: note,
              ),
          ],
          hiddenCount: files.length > maxListedPerSection
              ? files.length - maxListedPerSection
              : 0,
          totalBytes: files.fold(0, (sum, file) => sum + (file.size ?? 0)),
        ),
      );
    }

    // ---- Folders earlier versions used: never read, listed so nothing
    // stays hidden. On Android the app's own documents folder held only
    // those (Crash Log and Course Backups).
    sections.add(
      await folder(
        title: 'Folders from earlier versions',
        description: public == null
            ? 'Imports, Exports and Merges from versions before Build 255 '
                  'Revision 3, including Course Backups made before then. QQL '
                  'no longer reads them; Wipe everything treats them like '
                  'Import, Export and ToBeMerged.'
            : 'Files earlier versions kept in QQL\'s own documents folder, '
                  'such as an older Crash Log and Course Backups. QQL no '
                  'longer uses them.',
        directory: documentsRoot,
        only: public == null ? QqlTopFolder.earlierFolders.keys.toList() : null,
        describe: describeBackupOrExport,
      ),
    );
    const earlierPrivateNotes = <String, String>{
      QqlEarlierPrivateFolders.courses:
          'Stored course from an earlier version.',
      QqlEarlierPrivateFolders.coursesV11:
          'Stored Course Model v11 course from Build 255; convert it with '
          'tools/convert_stored_courses_256.dart.',
      QqlEarlierPrivateFolders.courseMedia:
          'Course media from an earlier version.',
      QqlEarlierPrivateFolders.courseBackups:
          'Course backup from an earlier version.',
      QqlEarlierPrivateFolders.privateCourseBackups:
          'Course backup from an earlier version.',
      QqlEarlierPrivateFolders.importStaging:
          'Import copy left by an earlier version.',
      QqlEarlierPrivateFolders.logs: 'Crash Log from an earlier version.',
    };
    sections.add(
      await folder(
        title: 'Private folders from earlier versions',
        description:
            'Courses, course media, Course Backups, import copies and the '
            'Crash Log where QQL kept them before Build 255 Revision 4 gave '
            'its own folders QQL_ names, and the private Course Backups of '
            'Revision 4. QQL no longer reads them; a one-off tool moves '
            'earlier Courses, their media and backups to where QQL keeps them '
            'now. Wipe everything removes them, the earlier Crash Log with the '
            'Logs choice and the earlier backups with the Backups choice.',
        directory: Directory(supportRoot),
        only: await QqlEarlierPrivateFolders.presentIn(
          Directory(supportRoot),
          earlierPrivateNotes.keys,
          current: const [DiagnosticLogService.logsDirectoryName],
        ),
        describe: (file, root) => plain(
          file,
          root,
          note:
              earlierPrivateNotes[_relative(
                file,
                root,
              ).split(RegExp(r'[\\/]')).first] ??
              'From an earlier version.',
        ),
      ),
    );

    // ---- Imported media copies in QQL's own storage
    // Keyed by the ID hash a Course media folder's name ends with, whatever
    // its language pair.
    final mediaOwners = <String, String>{};
    for (final course in courses) {
      mediaOwners[CourseStorageNames.hashOf(course.courseId)] =
          '${course.title.isEmpty ? course.courseId : course.title} · ${ownerOf(course)}';
    }
    // The media of a Course this version cannot open stays with it: it goes
    // when that Course is deleted.
    final unopenableMedia = <String>{};
    for (final file in _courseService?.unreadableCourseFiles ?? const []) {
      final id = file.courseId;
      if (id == null) continue;
      final hash = CourseStorageNames.hashOf(id);
      final mediaRoot = Directory(
        '$supportRoot$sep${CourseMediaStore.rootDirectoryName}',
      );
      if (!await mediaRoot.exists()) continue;
      await for (final entity in mediaRoot.list(followLinks: false)) {
        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        if (CourseStorageNames.hashOfMediaFolder(name) == hash) {
          unopenableMedia.add(name);
        }
      }
    }
    sections.add(
      await folder(
        title: 'Imported images',
        description:
            'Copies QQL made in its own storage when you imported images or image banks. '
            'Images added before Build 255 Revision 4 stay in the earlier '
            '${QqlEarlierPrivateFolders.sharedImages} folder, where they keep working.',
        directory: Directory(supportRoot),
        only: const [
          ExerciseImageService.sharedImagesDirectoryName,
          QqlEarlierPrivateFolders.sharedImages,
        ],
        describe: (file, root) => plain(
          file,
          root,
          note: 'Imported exercise image.',
          action: InventoryAction(
            InventoryActionKind.deleteDeviceImage,
            file.path,
            label: 'Delete',
            explanation:
                'Delete this image from the Shared Image Library: its record '
                'and its file. Courses keep their own copies.',
          ),
        ),
      ),
    );
    sections.add(
      await folder(
        title: 'Import staging',
        description:
            'Files being checked during an import. Normally empty; leftovers from an interrupted import are removed at the next start.',
        directory: Directory(
          '$supportRoot$sep${ImportStager.stagingDirectoryName}',
        ),
        describe: (file, root) =>
            plain(file, root, note: 'Temporary import copy.'),
      ),
    );
    sections.add(
      await folder(
        title: 'Image banks',
        description:
            'Imported image banks (each with its manifest and images). Banks '
            'imported before Build 255 Revision 4 stay in the earlier '
            '${QqlEarlierPrivateFolders.imageBanks} folder, where they keep working.',
        directory: Directory(supportRoot),
        only: const [
          ImageBankService.banksDirectoryName,
          QqlEarlierPrivateFolders.imageBanks,
        ],
        describe: (file, root) {
          final parts = _relative(file, root).split(RegExp(r'[\\/]'));
          final bankId = parts.length > 2 ? parts[1] : null;
          return plain(
            file,
            root,
            note: 'Part of an imported image bank.',
            deletable: false,
            action: bankId == null
                ? null
                : InventoryAction(
                    InventoryActionKind.removeImageBank,
                    bankId,
                    label: 'Remove bank',
                    explanation:
                        'Remove the whole Image Bank $bankId and its images '
                        'from the Shared Image Library. Courses keep their '
                        'own copies.',
                  ),
          );
        },
      ),
    );
    sections.add(
      await folder(
        title: 'Course media',
        description:
            'Images and recorded MP3s that courses use, copied into QQL\'s own storage and named by content, one folder per course.',
        directory: Directory(
          '$supportRoot$sep${CourseMediaStore.rootDirectoryName}',
        ),
        describe: (file, root) async {
          final rel = _relative(file, root);
          final courseFolder = rel.split(RegExp(r'[\\/]')).first;
          final owner =
              mediaOwners[CourseStorageNames.hashOfMediaFolder(courseFolder)];
          // Media a stored Course uses has no Delete (Build 266 Revision 2):
          // only the folders no Course on this device uses can go.
          return plain(
            file,
            root,
            note: file.path.toLowerCase().endsWith('.mp3')
                ? 'Course recording (MP3).'
                : 'Course image.',
            owner: owner ?? 'A course no longer on this device',
            deletable: owner == null && !unopenableMedia.contains(courseFolder),
          );
        },
      ),
    );

    // ---- Anything else in the QQL folder. On Android the app's documents
    // folder is listed whole above, as earlier versions' files.
    if (public != null) return sections;
    final other = <InventoryItem>[];
    var otherTotal = 0;
    var otherCount = 0;
    if (await documentsRoot.exists()) {
      await for (final entity in documentsRoot.list(followLinks: false)) {
        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        if (_knownTopLevel.contains(name.toLowerCase())) continue;
        final files = entity is File
            ? [entity]
            : await _files(Directory(entity.path));
        for (final file in files) {
          final stat = await file.stat();
          otherTotal += stat.size;
          otherCount++;
          if (other.length < maxListedPerSection) {
            other.add(
              InventoryItem(
                name: _relative(file, documentsRoot),
                path: file.path,
                sizeBytes: stat.size,
                modified: stat.modified,
                note:
                    'Not created by QQL: added to the QQL folder from outside.',
                folder: file.parent.path,
                action: InventoryAction(
                  InventoryActionKind.deleteFile,
                  file.path,
                  label: 'Delete',
                  explanation:
                      'Delete the file ${_relative(file, documentsRoot)}, '
                      'which someone added to the QQL folder, from this '
                      'device.',
                ),
              ),
            );
          }
        }
      }
    }
    sections.add(
      InventorySection(
        title: 'Other files in the QQL folder',
        description:
            'Files or folders that someone added directly to the QuisquisLingo folder using the operating system. QQL did not create them and does not use them.',
        location: documentsRoot.path,
        items: other,
        hiddenCount: otherCount - other.length,
        totalBytes: otherTotal,
      ),
    );

    return sections;
  }

  Future<List<File>> _files(Directory directory) async {
    if (!await directory.exists()) return const [];
    return directory
        .list(recursive: true, followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();
  }

  String _relative(File file, Directory root) {
    final full = file.path;
    if (full.startsWith(root.path)) {
      var rest = full.substring(root.path.length);
      while (rest.startsWith('/') || rest.startsWith(r'\')) {
        rest = rest.substring(1);
      }
      return rest.isEmpty ? full : rest;
    }
    return full;
  }
}
