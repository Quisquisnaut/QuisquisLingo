import 'dart:convert';

import 'package:characters/characters.dart';

import '../models/course_models.dart';
import 'audit_code_registry.dart';
import 'course_audit_service.dart';
import 'lesson_presentation_service.dart';

/// What a Course file is about to be used for: the check and its pop-up
/// follow it.
enum CourseFileUse {
  import('importing', 'Import'),
  merge('merging', 'Continue');

  const CourseFileUse(this.doing, this.goOn);

  /// "before importing", "before merging".
  final String doing;

  /// The button that goes on; with anomalies it says "... anyway".
  final String goOn;
}

/// One thing a Course file leaves out or writes wrongly.
enum CourseImportAnomalyKind {
  noAuthor,
  noLicense,
  noRightsHolder,
  audioModeUnknown,
  audioLibraryNotAList,
  audioLibraryEntriesSkipped,
  recordingsFirstAndNone,
  noLessons,
  lessonsWithoutRounds,

  /// Only where the file is not refused for them: a Merge.
  auditErrors,
  auditWarnings,
  notExecutable,
}

class CourseImportAnomaly {
  const CourseImportAnomaly(this.kind, this.text);

  final CourseImportAnomalyKind kind;

  /// What was found and what QuisquisLingo does about it, in plain words.
  final String text;
}

/// What the pop-up tells about the Course in a file without anomalies
/// (owner's list of 13 October 2026): its authors, who maintains it, its
/// Team, its last edit, its license and its size.
class CourseImportFacts {
  const CourseImportFacts({
    required this.authors,
    required this.maintainerLabel,
    required this.maintainer,
    required this.team,
    required this.lastEdited,
    required this.lastEditor,
    required this.license,
    required this.content,
  });

  /// Names with their roles, or [noneNamed].
  final String authors;

  /// "Maintainer", or "Publisher" for a Publisher Course (it has none).
  final String maintainerLabel;
  final String maintainer;

  /// The assigned Team's name, [noTeam], [teamNotHere] or [teamNotRead];
  /// null for a Publisher Course, which has no Team.
  final String? team;

  /// When the Course was last changed, in local time. Null only when the
  /// date cannot be read, which the Course's reader refuses in a file.
  final DateTime? lastEdited;

  /// Who made that change, as the file records it; empty when it does not.
  final String lastEditor;

  /// The license with its Rights Holders, or [noneStated].
  final String license;

  /// "Lessons: 4 · Rounds: 12 · Exercises: 96", with the Course's own labels
  /// for its Lessons and Rounds when it has them ([lessonsLabel],
  /// [roundsLabel]). Exercises are counted as the Course Editor counts them.
  final String content;

  static const noneNamed = 'None named';
  static const noneStated = 'None stated';
  static const noTeam = 'None';
  static const teamNotHere = 'A Team that is not on this device';
  static const teamNotRead =
      'Not known: the Teams of this device could not be read';
  static const notALearnerHere = 'Not a learner on this device';

  /// How many authors and Rights Holders a line names before "and N more".
  static const shownNames = 6;

  /// [maintainerOnDevice] and [teamOnDevice] are the names this device has
  /// for the Course's Maintainer and assigned Team, null when it has none:
  /// a Course file holds only their IDs. [teamsRead] is false when the
  /// Teams of this device could not be read.
  static CourseImportFacts of(
    Course course, {
    String? maintainerOnDevice,
    String? teamOnDevice,
    bool teamsRead = true,
  }) {
    final official = course.originType.isOfficial;
    final rounds = [...course.lessons.expand((lesson) => lesson.rounds)];
    final exercises = rounds.fold<int>(
      0,
      (count, round) => count + round.exercises.length,
    );
    final holders = _names([
      for (final holder in course.rightsHolders) holder.name,
    ]);
    return CourseImportFacts(
      authors: course.authors.isEmpty
          ? noneNamed
          : _names([
              for (final author in course.authors)
                '${author.name} (${author.roles.join(', ')})',
            ]),
      maintainerLabel: official ? 'Publisher' : 'Maintainer',
      maintainer: CourseImportCheck.shown(
        official
            ? _or(
                course.publisherName,
                course.originalCourseCreator.displayName,
              )
            : maintainerOnDevice ?? _recordedMaintainer(course),
      ),
      team: official
          ? null
          : course.assignedTeamId == null
          ? noTeam
          : !teamsRead
          ? teamNotRead
          : CourseImportCheck.shown(teamOnDevice ?? teamNotHere),
      lastEdited: DateTime.tryParse(course.modifiedAtUtc.trim())?.toLocal(),
      lastEditor: CourseImportCheck.shown(course.lastVersionEditorDisplayName),
      license: course.license.isEmpty
          ? noneStated
          : '${CourseImportCheck.shown(course.license)} · Rights Holder: '
                '${holders.isEmpty ? 'none named' : holders}',
      content:
          '${lessonsLabel(course)}: ${course.lessons.length} · '
          '${roundsLabel(course)}: ${rounds.length} · Exercises: $exercises',
    );
  }

  /// What the Course calls its Lessons where they are counted (owner
  /// decision of 13 October 2026: a Course's own label is used): "Lessons",
  /// one of QQL's earlier labels in the plural ("Units"), or the label the
  /// author chose, as written (QQL cannot know its plural).
  static String lessonsLabel(Course course) {
    if (course.lessonNumberingMode == LessonNumberingMode.other) {
      final own = CourseImportCheck.shown(course.customLessonLabel, 40);
      return own.isEmpty ? 'Lessons' : own;
    }
    final first = LessonPresentationService.prefixFor(
      course.lessonNumberingMode,
      1,
    );
    return first != null && first.endsWith(' 1')
        ? '${first.substring(0, first.length - 2)}s'
        : 'Lessons';
  }

  /// What the Course calls its Rounds where they are counted: "Rounds", or
  /// the label the author chose, as written.
  static String roundsLabel(Course course) {
    final own = CourseImportCheck.shown(course.customRoundLabel, 40);
    return course.roundNumberingMode == RoundNumberingMode.customAndNumber &&
            own.isNotEmpty
        ? own
        : 'Rounds';
  }

  /// A Maintainer who is no learner of this device, by the name the file
  /// records for that person as its creator or its last editor.
  static String _recordedMaintainer(Course course) {
    final id = course.maintainer?.profileId;
    if (id == null) return notALearnerHere;
    final creator = course.originalCourseCreator;
    final name =
        creator.type == CourseProvenanceIdentityType.qqlUser && creator.id == id
        ? creator.displayName.trim()
        : course.lastVersionEditorProfileId == id
        ? course.lastVersionEditorDisplayName.trim()
        : '';
    return name.isEmpty
        ? notALearnerHere
        : '${CourseImportCheck.shown(name)} (not a learner on this device)';
  }

  static String _names(List<String> names) => [
    for (final name in names.take(shownNames)) CourseImportCheck.shown(name),
    if (names.length > shownNames) 'and ${names.length - shownNames} more',
  ].join(', ');

  static String _or(String first, String second) =>
      first.trim().isEmpty ? second.trim() : first.trim();
}

/// What the import of a Course file, or a Merge that reads one, shows
/// before anything is stored (Build 272 Revision 13, owner decisions of 13
/// October 2026): the file's [anomalies] to confirm, or, when it has none,
/// that it was checked, with the Course's [facts].
///
/// **Rule: an anomaly never refuses a file.** The pop-up lists and waits;
/// going on uses the Course exactly as without the pop-up. A file QQL
/// refuses is refused by its reader or, at import, by the Course Audit's
/// errors before the pop-up, never here: so what the Audit refuses (a Round
/// with nothing in it, a Course that plays only its recordings and has
/// none) has no line of its own.
///
/// An anomaly of an import is one of: something a Course should not leave
/// empty (an author, a license, a Rights Holder for a license that keeps
/// rights), something written wrongly with what QQL does about it (the
/// audio mode, the Audio Library), a Course set to play its recordings
/// first that has none, Lessons that are missing or empty, the Audit's
/// other warnings, exercises this version cannot play. An empty optional
/// field is normal and is never listed: Section names, keywords, custom
/// Lesson icons, a description, recordings in a Course read by the device's
/// voice.
///
/// A Merge takes its Lessons from the file and everything else from the
/// stored Course, which the file must match. For [CourseFileUse.merge] the
/// author and license anomalies are listed all the same (owner decision:
/// they may be relevant when merging), with what concerns the Lessons and
/// the Audit's errors (a Merge does not refuse the file for them when it is
/// loaded); the audio anomalies and the audio reminders are left out.
class CourseImportCheck {
  const CourseImportCheck({
    required this.facts,
    this.anomalies = const [],
    this.reminders = const [],
  });

  /// Each of these alone makes the pop-up ask "... anyway?".
  final List<CourseImportAnomaly> anomalies;

  /// Lines shown under the anomalies or the facts; they are no anomalies.
  final List<String> reminders;

  final CourseImportFacts facts;

  bool get hasAnomalies => anomalies.isNotEmpty;

  /// The one wording for a ZIP whose files sit in a folder of its name.
  static const matchingZipFolderText =
      'Accepted a matching ZIP folder. Course package files normally belong '
      'at the ZIP root.';

  /// The one license of QQL's list that gives the rights up: nobody holds
  /// them, so no Rights Holder is asked for (owner decision).
  static const rightsGivenUp = 'CC0 1.0';

  static const _audioModes = {'tts', 'recorded', 'hybrid'};

  /// The Audit warnings the pop-up says in its own words.
  static final _saidInWords = {
    AuditCode.courseLessonsEmpty.code,
    AuditCode.lessonRoundsEmpty.code,
  };

  /// The one wording for exercises this version cannot play.
  static String notExecutableText(int count) =>
      '$count exercise${count == 1 ? '' : 's'} cannot be played by this '
      'version of QuisquisLingo and ${count == 1 ? 'is' : 'are'} kept '
      'unchanged.';

  /// A text of the file as the pop-up shows it: one line, at most [max]
  /// characters. A file may hold a megabyte in any of its texts. The cut
  /// never falls inside a character (half an emoji would make Flutter draw
  /// the whole line as a replacement mark).
  static String shown(String value, [int max = 80]) {
    final line = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (line.length <= max) return line;
    final characters = line.characters;
    return characters.length <= max ? line : '${characters.take(max)}…';
  }

  /// The Course file as written, or null when it is not a JSON object (the
  /// reader has refused such a file before this is asked).
  static Map<String, dynamic>? fileJsonOf(List<int> courseJsonBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(courseJsonBytes));
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  /// The check of [course] as read from [fileJson] (the file as written;
  /// without it only what the read Course shows is listed), for [use].
  /// [warnings] are the Course Audit's; [auditErrors] its number of errors,
  /// counted only for a Merge (an import is refused for them first).
  static CourseImportCheck of(
    Course course, {
    CourseFileUse use = CourseFileUse.import,
    Map<String, dynamic>? fileJson,
    List<CourseAuditIssue> warnings = const [],
    int auditErrors = 0,
    int notExecutable = 0,
    String? maintainerOnDevice,
    String? teamOnDevice,
    bool teamsRead = true,
    bool matchingZipFolder = false,
  }) {
    final importing = use == CourseFileUse.import;
    final found = <CourseImportAnomaly>[];
    void add(CourseImportAnomalyKind kind, String text) =>
        found.add(CourseImportAnomaly(kind, text));

    _credits(course, fileJson, add);
    // The audio of a Merge is the stored Course's.
    if (importing) _audio(course, fileJson, add);

    // Lessons, in words, with the Course's own labels.
    final lessonsLabel = CourseImportFacts.lessonsLabel(course);
    final roundsLabel = CourseImportFacts.roundsLabel(course);
    if (course.lessons.isEmpty) {
      add(
        CourseImportAnomalyKind.noLessons,
        'The Course has no $lessonsLabel.',
      );
    }
    final emptyLessons = course.lessons
        .where((lesson) => lesson.rounds.isEmpty)
        .length;
    if (emptyLessons > 0) {
      add(
        CourseImportAnomalyKind.lessonsWithoutRounds,
        '$lessonsLabel without $roundsLabel: $emptyLessons.',
      );
    }

    // What the Course Audit says. The warnings said above are not counted
    // again.
    if (!importing && auditErrors > 0) {
      add(
        CourseImportAnomalyKind.auditErrors,
        'The Course Audit has $auditErrors '
        'error${auditErrors == 1 ? '' : 's'} in this Course: a Merge whose '
        'result has Audit errors is refused.',
      );
    }
    final others = warnings
        .where((issue) => !_saidInWords.contains(issue.code))
        .length;
    if (others > 0) {
      final count =
          '$others ${others == warnings.length ? '' : 'other '}'
          'warning${others == 1 ? '' : 's'}';
      add(
        CourseImportAnomalyKind.auditWarnings,
        importing
            ? 'The Course Audit has $count: the Course’s Audit lists '
                  '${others == 1 ? 'it' : 'them'} after the import.'
            : 'The Course Audit has $count in this Course.',
      );
    }
    if (notExecutable > 0) {
      add(
        CourseImportAnomalyKind.notExecutable,
        notExecutableText(notExecutable),
      );
    }

    final recordings = course.audioLibrary.length;
    final checkVoice =
        'Please check that Text-to-speech is set up correctly for '
        '${_studied(course)} (Settings › Audio Settings).';
    return CourseImportCheck(
      facts: CourseImportFacts.of(
        course,
        maintainerOnDevice: maintainerOnDevice,
        teamOnDevice: teamOnDevice,
        teamsRead: teamsRead,
      ),
      anomalies: List.unmodifiable(found),
      reminders: List.unmodifiable([
        if (matchingZipFolder) matchingZipFolderText,
        if (importing && recordings == 0 && course.audioMode != 'recorded')
          'The Course has no recordings: QuisquisLingo will use the '
              'device’s voice. $checkVoice'
        else if (importing && recordings > 0 && course.audioMode == 'tts')
          'The Course has $recordings recording${recordings == 1 ? '' : 's'} '
              'but its audio mode is On-Device TTS: '
              '${recordings == 1 ? 'it is' : 'they are'} not played, and the '
              'device’s voice reads every text. $checkVoice',
      ]),
    );
  }

  static void _credits(
    Course course,
    Map<String, dynamic>? fileJson,
    void Function(CourseImportAnomalyKind kind, String text) add,
  ) {
    if (course.authors.isEmpty) {
      add(CourseImportAnomalyKind.noAuthor, 'The file names no author.');
    }
    final writtenLicense = fileJson == null
        ? course.license
        : fileJson['license'];
    if (writtenLicense is! String || writtenLicense.trim().isEmpty) {
      add(
        CourseImportAnomalyKind.noLicense,
        course.license.isEmpty
            ? 'The file states no license.'
            : 'The file states no license: QuisquisLingo reads it as '
                  '“${shown(course.license)}”.',
      );
    } else if (course.rightsHolders.isEmpty &&
        course.license != rightsGivenUp) {
      add(
        CourseImportAnomalyKind.noRightsHolder,
        'A license is stated (${shown(course.license)}) but no Rights Holder '
        'is named.',
      );
    }
  }

  /// What is written wrongly, then what the Course will do.
  static void _audio(
    Course course,
    Map<String, dynamic>? fileJson,
    void Function(CourseImportAnomalyKind kind, String text) add,
  ) {
    final writtenMode = fileJson?['audioMode'];
    if (writtenMode != null && !_audioModes.contains(writtenMode)) {
      add(
        CourseImportAnomalyKind.audioModeUnknown,
        writtenMode is String && writtenMode.trim().isNotEmpty
            ? 'The audio mode “${shown(writtenMode, 40)}” is not one '
                  'QuisquisLingo knows: the Course is read as On-Device TTS.'
            : 'The audio mode is not written as QuisquisLingo expects: the '
                  'Course is read as On-Device TTS.',
      );
    }
    final writtenLibrary = fileJson?['audioLibrary'];
    final libraryNotAList = writtenLibrary != null && writtenLibrary is! List;
    if (libraryNotAList) {
      add(
        CourseImportAnomalyKind.audioLibraryNotAList,
        'The Audio Library is not written as a list: the Course will be '
        'imported without recordings.',
      );
    } else if (writtenLibrary is List) {
      final skipped = writtenLibrary.where((entry) => entry is! Map).length;
      if (skipped > 0) {
        add(
          CourseImportAnomalyKind.audioLibraryEntriesSkipped,
          skipped == 1
              ? '1 entry of the Audio Library is not a recording and will be '
                    'skipped.'
              : '$skipped entries of the Audio Library are not recordings '
                    'and will be skipped.',
        );
      }
    }
    if (course.audioLibrary.isEmpty &&
        course.audioMode == 'hybrid' &&
        !libraryNotAList) {
      add(
        CourseImportAnomalyKind.recordingsFirstAndNone,
        'The Course is set to play its recordings first (Hybrid) and has '
        'none.',
      );
    }
  }

  static String _studied(Course course) {
    final name = shown(course.targetLanguage, 40);
    return name.isEmpty ? 'the language studied' : name;
  }
}
