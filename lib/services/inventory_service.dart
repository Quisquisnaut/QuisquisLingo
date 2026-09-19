import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/authoring_team.dart';
import '../models/course_models.dart';
import 'course_editor_service.dart';
import 'profile_service.dart';
import 'recorded_audio_service.dart';
import 'team_service.dart';

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

  const InventoryItem({
    required this.name,
    this.path,
    this.sizeBytes,
    this.modified,
    this.owner,
    this.note,
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
  final Future<List<Course>> Function() _courses;
  final Future<List<AuthoringTeam>> Function() _teams;

  InventoryService({
    ProfileService? profiles,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? supportDirectory,
    Future<List<Course>> Function()? courses,
    Future<List<AuthoringTeam>> Function()? teams,
  }) : _profiles = profiles ?? ProfileService(),
       _documents = documentsDirectory ?? getApplicationDocumentsDirectory,
       _support = supportDirectory ?? getApplicationSupportDirectory,
       _courses = courses ?? (() => CourseEditorService().listUserCourses()),
       _teams = teams ?? (() => TeamService().listTeams());

  static const _knownTopLevel = <String>{
    'exports',
    'imports',
    'logs',
    'merges',
  };

  Future<List<InventorySection>> load() async {
    final learners = await _profiles.getProfileRecords();
    final admins = await _profiles.getAdminProfileIds();
    final names = {for (final l in learners) l.learnerProfileId: l.displayName};

    List<Course> courses = const [];
    String? courseProblem;
    try {
      courses = await _courses();
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
            'Learner profiles and their progress and settings. These are stored inside QQL’s own settings storage, so they have no file of their own.',
        items: [
          for (final learner in learners)
            InventoryItem(
              name: learner.displayName,
              owner: admins.contains(learner.learnerProfileId)
                  ? '${learner.displayName} (admin)'
                  : learner.displayName,
              note: 'Stored inside QQL settings (no file).',
            ),
        ],
      ),
    );

    sections.add(
      InventorySection(
        title: 'Custom and installed courses',
        description:
            'Courses created or installed on this device. They are stored inside QQL’s own settings storage, so they have no file of their own. Export a course from Course Manager to get a file.',
        items: [
          if (courseProblem != null)
            InventoryItem(name: 'Stored courses', note: courseProblem),
          for (final course in courses)
            InventoryItem(
              name: course.title.isEmpty ? course.courseId : course.title,
              owner: ownerOf(course),
              modified: DateTime.tryParse(course.modifiedAtUtc)?.toLocal(),
              note:
                  '${course.originType == CourseOriginType.custom ? 'Custom course' : 'Installed external course'} · ID ${course.courseId} · stored inside QQL settings (no file).',
            ),
        ],
      ),
    );

    // ---- Folders under Documents/QuisquisLingo
    Future<InventorySection> folder({
      required String title,
      required String description,
      required Directory directory,
      required Future<InventoryItem> Function(File file, Directory root)
      describe,
    }) async {
      final files = await _files(directory);
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

    Future<InventoryItem> plain(
      File file,
      Directory root, {
      String? note,
      String? owner,
    }) async {
      final stat = await file.stat();
      return InventoryItem(
        name: _relative(file, root),
        path: file.path,
        sizeBytes: stat.size,
        modified: stat.modified,
        owner: owner,
        note: note,
      );
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

    sections.add(
      await folder(
        title: 'Exports and backups',
        description:
            'Learner backups, User Recovery Keys, course exports and the course backups the Course Editor makes automatically before saving changes (in "Course Backups v9").',
        directory: Directory('${documentsRoot.path}${sep}Exports'),
        describe: (file, root) async {
          final rel = _relative(file, root);
          final lower = rel.toLowerCase();
          String kind;
          String? reason;
          if (lower.contains('course backups v9')) {
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
            if (reason != null &&
                reason.toLowerCase().startsWith('pre-change')) {
              kind = 'Automatic course backup (made before a change)';
            }
          } else if (lower.endsWith('.user-recovery-key.json')) {
            kind = 'User Recovery Key';
          } else if (lower.contains('_backup') && lower.endsWith('.json')) {
            kind = 'Learner backup';
          } else {
            kind = 'Export';
          }
          return plain(
            file,
            root,
            note: kind,
            owner: await ownerFromJson(file),
          );
        },
      ),
    );

    sections.add(
      await folder(
        title: 'Imports',
        description:
            'Files copied into the Imports folder from outside QQL: images, audio (MP3) files, lesson icons and course files waiting to be imported. QQL only reads them; importing makes separate copies.',
        directory: Directory('${documentsRoot.path}${sep}Imports'),
        describe: (file, root) =>
            plain(file, root, note: 'Added from outside QQL.'),
      ),
    );
    sections.add(
      await folder(
        title: 'Merges',
        description:
            'Course files placed in the Merges folder for a Course Merge.',
        directory: Directory('${documentsRoot.path}${sep}Merges'),
        describe: (file, root) =>
            plain(file, root, note: 'Added from outside QQL.'),
      ),
    );
    sections.add(
      await folder(
        title: 'Logs',
        description:
            'The crash log, the diagnostic log export and the session marker QQL uses to detect an abnormal shutdown.',
        directory: Directory('${documentsRoot.path}${sep}Logs'),
        describe: (file, root) => plain(file, root, note: 'Written by QQL.'),
      ),
    );

    // ---- Imported media copies in QQL's own storage
    final audioOwners = <String, String>{};
    for (final course in courses) {
      audioOwners[RecordedAudioService.storageDirectoryForCourseId(
            course.courseId,
          )] =
          '${course.title.isEmpty ? course.courseId : course.title} · ${ownerOf(course)}';
    }
    sections.add(
      await folder(
        title: 'Imported images',
        description:
            'Copies QQL made in its own storage when you imported images or image banks.',
        directory: Directory('$supportRoot${sep}exercise_images'),
        describe: (file, root) =>
            plain(file, root, note: 'Imported exercise image.'),
      ),
    );
    sections.add(
      await folder(
        title: 'Image banks',
        description:
            'Imported image banks (each with its manifest and images).',
        directory: Directory('$supportRoot${sep}image_banks'),
        describe: (file, root) =>
            plain(file, root, note: 'Part of an imported image bank.'),
      ),
    );
    sections.add(
      await folder(
        title: 'Imported audio files',
        description:
            'Recorded MP3 copies QQL made in its own storage when you imported them, one folder per course.',
        directory: Directory('$supportRoot${sep}quisquislingo_audio'),
        describe: (file, root) async {
          final rel = _relative(file, root);
          final courseFolder = rel.split(RegExp(r'[\\/]')).first;
          return plain(
            file,
            root,
            note: 'Imported MP3 recording.',
            owner:
                audioOwners[courseFolder] ??
                'A course no longer on this device',
          );
        },
      ),
    );

    // ---- Anything else in the QQL documents folder
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
