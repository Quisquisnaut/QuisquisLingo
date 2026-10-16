import 'dart:convert';

import '../models/course_models.dart';
import 'course_editor_transaction.dart';
import 'lesson_presentation_service.dart';
import 'round_type_presentation.dart';

/// One area of a Course's unsaved changes: its name ("Course Info",
/// "Audio Library", "Lessons") and the changes in it, one line each.
class CourseChangeArea {
  const CourseChangeArea(this.title, this.details);

  final String title;
  final List<String> details;
}

/// What differs between the Course as last saved and the Course Editor's
/// working copy (Build 274 Revision 5, owner decisions of 16 October 2026:
/// the "Unsaved course changes" question names it, the areas first, each
/// opening to all its details; text only).
///
/// The comparison is the Course Editor's own
/// ([CourseEditorTransaction.semanticValue]: the JSON, every `updatedAt`
/// left out), so the summary is empty exactly when the Editor sees no
/// change: a field no area names is listed under "Other Course details",
/// a difference no line names is [unnamed]. No widgets: the Rounds are
/// named by [RoundTypePresentation].
abstract final class CourseChangeSummary {
  static const courseInfo = 'Course Info';
  static const versionHistory = 'Version history';
  static const courseState = 'Draft or Published';
  static const lessonOptions = 'Lesson Options';
  static const audioLibrary = 'Audio Library';
  static const imageLibrary = 'Image Library';
  static const storyCharacters = 'Story characters';
  static const lessons = 'Lessons';
  static const other = 'Other Course details';

  /// What [between] says, under the area it is found in (else under
  /// [other]), when the two Courses differ in a way no line names (two
  /// items sharing one ID, say).
  static const unnamed = 'A change this list cannot name';

  /// The areas in the order the question lists them.
  static const _areaOrder = [
    courseInfo,
    versionHistory,
    courseState,
    lessonOptions,
    audioLibrary,
    imageLibrary,
    storyCharacters,
    lessons,
    other,
  ];

  /// The Course's own fields by the area and the name the screens give
  /// them; Course Info's in the order the Course Info Editor shows them.
  static const _courseFields = <String, (String, String)>{
    'title': (courseInfo, 'Course name'),
    'maintainer': (courseInfo, 'Course Maintainer'),
    'assignedTeamId': (courseInfo, 'Assigned Team'),
    'learningLanguage': (courseInfo, 'Languages'),
    'interfaceLanguage': (courseInfo, 'Languages'),
    'sourceLanguage': (courseInfo, 'Languages'),
    'targetLanguage': (courseInfo, 'Languages'),
    'sourceLanguageTag': (courseInfo, 'Languages'),
    'targetLanguageTag': (courseInfo, 'Languages'),
    'ttsLanguage': (courseInfo, 'Languages'),
    'textDirection': (courseInfo, 'Languages'),
    'targetLanguageNameForLearners': (
      courseInfo,
      'Learning language name for learners',
    ),
    'flagCode': (courseInfo, 'Course flag'),
    'worldFlagId': (courseInfo, 'Course flag'),
    'flagImageBase64': (courseInfo, 'Course flag'),
    'coverImage': (courseInfo, 'Cover image'),
    'authors': (courseInfo, 'Authors'),
    'languageVariant': (courseInfo, 'Language variant'),
    'startLevel': (courseInfo, 'Starting level'),
    'targetLevel': (courseInfo, 'Target level'),
    'courseDescription': (courseInfo, 'Course description'),
    'buyACoffeeUrl': (courseInfo, 'Buy a Coffee URL'),
    'estimatedStudyHours': (courseInfo, 'Estimated study hours'),
    'minimumAge': (courseInfo, 'Minimum age'),
    'keywords': (courseInfo, 'Keywords'),
    'publisherContact': (courseInfo, 'Publisher contact'),
    'minimumAppBuild': (courseInfo, 'Minimum QuisquisLingo build'),
    'license': (courseInfo, 'Course content license'),
    'derivativeWorksPolicy': (courseInfo, 'Derivative works for other users'),
    'allowPageSharing': (
      courseInfo,
      'Learners may share, save and print pages',
    ),
    'temporarySample': (courseInfo, 'Private course'),
    'rightsHolders': (courseInfo, 'Rights Holders'),
    'mediaAttributions': (courseInfo, 'Media credits'),
    'lessonNumberingMode': (lessonOptions, 'Lesson label and numbering'),
    'customLessonLabel': (lessonOptions, 'Lesson label and numbering'),
    'roundNumberingMode': (lessonOptions, 'Round label and numbering'),
    'customRoundLabel': (lessonOptions, 'Round label and numbering'),
    'useGuidebook': (lessonOptions, 'Use GuideBook'),
    'wordLookup': (lessonOptions, 'Word Lookup'),
    'createDuels': (lessonOptions, 'Create Duels'),
    'defaultTimedLimitsSeconds': (lessonOptions, 'Default Timed limits'),
    'pictureAnswers': (lessonOptions, 'Picture answers'),
    'storyNarrator': (storyCharacters, 'Narrator'),
    'sectionNames': (lessons, 'Section names'),
    'defaultLessonIconStyle': (lessons, 'Lesson number icons'),
    'lessonIconAssets': (lessons, 'Custom Lesson icons'),
  };

  /// The order the Course's keys are read in: its own fields, then those
  /// said line by line (the audio source before the recordings). Any other
  /// key comes after them, in the order the Course's JSON writes it.
  static final _keyOrder = [
    ..._courseFields.keys,
    'publicationState',
    'restoredFromVersion',
    'audioMode',
    'audioLibrary',
    'imageLibrary',
    'storyCharacters',
    'lessons',
  ];

  /// What differs between [saved] and [working], area by area, in the
  /// question's order; empty exactly when nothing does.
  static List<CourseChangeArea> between(Course saved, Course working) {
    final before = saved.toJson();
    final after = working.toJson();
    final found = <String, List<String>>{};
    void add(String area, String detail, {bool unique = false}) {
      final details = found.putIfAbsent(area, () => []);
      if (!unique || !details.contains(detail)) details.add(detail);
    }

    // Every key has a rank of its own, so the order never depends on how
    // the sort treats equal keys.
    final all = {...before.keys, ...after.keys}.toList();
    int rank(String key) {
      final i = _keyOrder.indexOf(key);
      return i < 0 ? _keyOrder.length + all.indexOf(key) : i;
    }

    final keys = [...all]..sort((a, b) => rank(a).compareTo(rank(b)));
    for (final key in keys) {
      if (key == 'updatedAt' || same(before[key], after[key])) continue;
      switch (key) {
        case 'publicationState':
          add(
            courseState,
            working.publicationState.isPublished
                ? 'The Course is now Published'
                : 'The Course is now Draft',
          );
        case 'restoredFromVersion':
          final version = working.restoredFromVersion;
          add(
            versionHistory,
            version == null
                ? 'No longer a version loaded from Version history'
                : 'Version $version loaded from Version history',
          );
        case 'audioMode':
          add(
            audioLibrary,
            'Audio source: ${_audioModeName(saved.audioMode)} → '
            '${_audioModeName(working.audioMode)}',
          );
        case 'audioLibrary':
          for (final line in _itemChanges(
            before[key],
            after[key],
            idOf: (entry) => entry['id'],
            nameOf: (entry) {
              final text = '${entry['text'] ?? ''}'.trim();
              if (text.isNotEmpty) return 'Recording “$text”';
              final file = '${entry['originalFileName'] ?? ''}'.trim();
              return file.isEmpty
                  ? 'A recording without text'
                  : 'Recording $file';
            },
            many: 'recordings',
          )) {
            add(audioLibrary, line);
          }
        case 'imageLibrary':
          for (final line in _itemChanges(
            before[key],
            after[key],
            idOf: (entry) => entry['asset'],
            nameOf: (entry) {
              final source = entry['sharedImageSource'];
              final own = '${entry['label'] ?? ''}'.trim();
              final label = own.isNotEmpty
                  ? own
                  : source is Map
                  ? '${source['label'] ?? ''}'.trim()
                  : '';
              return label.isEmpty ? 'A picture' : 'Picture “$label”';
            },
            many: 'pictures',
          )) {
            add(imageLibrary, line);
          }
        case 'storyCharacters':
          for (final line in _itemChanges(
            before[key],
            after[key],
            idOf: (entry) => entry['id'],
            nameOf: (entry) {
              final name = '${entry['name'] ?? ''}'.trim();
              return name.isEmpty ? 'A character' : 'Character “$name”';
            },
            many: 'characters',
          )) {
            add(storyCharacters, line);
          }
        case 'lessons':
          final lines = _lessonChanges(saved, working);
          for (final line in lines) {
            add(lessons, line);
          }
          // Two Lessons sharing one ID, say.
          if (lines.isEmpty) add(lessons, unnamed);
        default:
          final field = _courseFields[key];
          if (field == null) {
            add(other, key, unique: true);
          } else {
            add(field.$1, field.$2, unique: true);
          }
      }
    }
    if (found.values.every((details) => details.isEmpty) &&
        !same(before, after)) {
      add(other, unnamed);
    }
    return [
      for (final area in _areaOrder)
        if (found[area] case final details? when details.isNotEmpty)
          CourseChangeArea(area, List.unmodifiable(details)),
    ];
  }

  /// Whether [a] and [b] are the same as the Course Editor compares them.
  static bool same(Object? a, Object? b) =>
      jsonEncode(CourseEditorTransaction.semanticValue(a)) ==
      jsonEncode(CourseEditorTransaction.semanticValue(b));

  static String _audioModeName(String mode) => switch (mode) {
    'recorded' => 'Recorded MP3 only',
    'hybrid' => 'Hybrid: MP3 + TTS fallback',
    _ => 'On-Device TTS',
  };

  /// A list of records by their key, each named: added, changed, removed,
  /// and the order when it alone changed.
  static List<String> _itemChanges(
    Object? before,
    Object? after, {
    required Object? Function(Map entry) idOf,
    required String Function(Map entry) nameOf,
    required String many,
  }) {
    final old = _byId(before, idOf);
    final now = _byId(after, idOf);
    final lines = [
      for (final entry in now.entries)
        if (!old.containsKey(entry.key))
          '${nameOf(entry.value)}: added'
        else if (!same(old[entry.key], entry.value))
          '${nameOf(entry.value)}: changed',
      for (final entry in old.entries)
        if (!now.containsKey(entry.key)) '${nameOf(entry.value)}: removed',
    ];
    if (lines.isEmpty && !same(before, after)) {
      final keptOld = [
        for (final id in old.keys)
          if (now.containsKey(id)) id,
      ];
      final keptNew = [
        for (final id in now.keys)
          if (old.containsKey(id)) id,
      ];
      lines.add(
        _sameOrder(keptOld, keptNew) ? unnamed : 'The order of the $many',
      );
    }
    return lines;
  }

  static Map<Object?, Map> _byId(
    Object? list,
    Object? Function(Map entry) idOf,
  ) => {
    if (list is List)
      for (final entry in list)
        if (entry is Map) idOf(entry): entry,
  };

  static bool _sameOrder(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------- Lessons

  /// A Lesson as the breadcrumbs name it: "Lesson 2: Greetings".
  static String _lessonName(Course course, int index) {
    final name = const LessonPresentationService()
        .identity(course, index)
        .fullText
        .trim();
    return name.isEmpty ? 'Lesson ${index + 1}' : name;
  }

  /// A Round as the Rounds page labels it ("Round 3 · Practice", or the
  /// type alone while the numbering is off), then its title.
  static String _roundName(Course course, LearningRound round, int index) {
    final label = RoundTypePresentation.prefix(
      round.roundType,
      index + 1,
      course.roundNumberingMode,
      customPrefix: course.customRoundLabel,
    );
    final title = RoundTypePresentation.authoredTitle(round);
    return title.isEmpty ? label : '$label: $title';
  }

  /// [names] (the working list's) with the place added to every name
  /// another item also has, in this list or in the saved one, [others]
  /// ("Practice (3rd in the list)"): untitled Rounds of one type read alike
  /// while the numbering is off.
  static List<String> _told(List<String> names, List<String> others) => [
    for (final (i, name) in names.indexed)
      _count(names, name) > 1 || _count(others, name) > 1
          ? '$name (${_ordinal(i + 1)} in the list)'
          : name,
  ];

  /// [names] (the saved list's, for the items removed) with the place they
  /// had added to every name that reads like another, saved or still there
  /// ([others]): "Practice (was 1st in the list)", so a removed Round never
  /// reads like one that moved into its place.
  static List<String> _toldRemoved(List<String> names, List<String> others) => [
    for (final (i, name) in names.indexed)
      _count(names, name) > 1 || others.contains(name)
          ? '$name (was ${_ordinal(i + 1)} in the list)'
          : name,
  ];

  static int _count(List<String> list, String name) =>
      list.where((other) => other == name).length;

  static String _ordinal(int n) {
    final suffix = n % 100 >= 11 && n % 100 <= 13
        ? 'th'
        : switch (n % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$n$suffix';
  }

  static String _state(Object? state) =>
      state == PublicationState.published.name ? 'now Published' : 'now Draft';

  /// The lines of the Lessons area: each Lesson, GuideBook, Round and
  /// exercise added, removed, put in another order or changed, named as the
  /// breadcrumbs name them (removed ones as they were named when saved). An
  /// item moved to another Lesson or Round is removed there and added here.
  static List<String> _lessonChanges(Course saved, Course working) {
    final lines = <String>[];
    final oldIndex = {
      for (final (i, lesson) in saved.lessons.indexed) lesson.lessonId: i,
    };
    final newIndex = {
      for (final (i, lesson) in working.lessons.indexed) lesson.lessonId: i,
    };
    final keptOld = [
      for (final lesson in saved.lessons)
        if (newIndex.containsKey(lesson.lessonId)) lesson.lessonId,
    ];
    final keptNew = [
      for (final lesson in working.lessons)
        if (oldIndex.containsKey(lesson.lessonId)) lesson.lessonId,
    ];
    if (!_sameOrder(keptOld, keptNew)) lines.add('The order of the Lessons');
    final plainOld = [
      for (final (i, _) in saved.lessons.indexed) _lessonName(saved, i),
    ];
    final plainNew = [
      for (final (i, _) in working.lessons.indexed) _lessonName(working, i),
    ];
    final oldNames = _toldRemoved(plainOld, plainNew);
    final newNames = _told(plainNew, plainOld);
    for (final (i, lesson) in working.lessons.indexed) {
      final name = newNames[i];
      final before = oldIndex[lesson.lessonId];
      if (before == null) {
        lines.add('$name: added');
        continue;
      }
      lines.addAll(
        _oneLesson(saved, saved.lessons[before], working, lesson, name),
      );
    }
    for (final (i, lesson) in saved.lessons.indexed) {
      if (!newIndex.containsKey(lesson.lessonId)) {
        lines.add('${oldNames[i]}: removed');
      }
    }
    return lines;
  }

  static List<String> _oneLesson(
    Course savedCourse,
    Lesson saved,
    Course workingCourse,
    Lesson working,
    String name,
  ) {
    final before = saved.toJson();
    final after = working.toJson();
    if (same(before, after)) return const [];
    final lines = <String>[];
    final own = <String>[];
    for (final key in {...before.keys, ...after.keys}) {
      if (key == 'rounds' || key == 'guidebook' || key == 'updatedAt') {
        continue;
      }
      if (same(before[key], after[key])) continue;
      final what = switch (key) {
        'title' => 'its title',
        'section' || 'sectionName' => 'its section',
        'themeIconAsset' => 'its icon',
        'publicationState' => _state(after[key]),
        'provisionalDraft' => null,
        'duel' => 'its Duel',
        _ => 'its details',
      };
      if (what != null && !own.contains(what)) own.add(what);
    }
    if (own.isNotEmpty) lines.add('$name: ${own.join(', ')}');
    if (!same(before['guidebook'], after['guidebook'])) {
      final was = (before['guidebook'] as Map?)?['publicationState'];
      final now = (after['guidebook'] as Map?)?['publicationState'];
      lines.add('$name › GuideBook${was != now ? ' (${_state(now)})' : ''}');
    }
    if (!same(before['rounds'], after['rounds'])) {
      lines.addAll(_rounds(savedCourse, saved, workingCourse, working, name));
    }
    if (lines.isEmpty) lines.add('$name: changed');
    return lines;
  }

  static List<String> _rounds(
    Course savedCourse,
    Lesson saved,
    Course workingCourse,
    Lesson working,
    String name,
  ) {
    final lines = <String>[];
    final oldIndex = {
      for (final (i, round) in saved.rounds.indexed) round.id: i,
    };
    final newIndex = {
      for (final (i, round) in working.rounds.indexed) round.id: i,
    };
    final keptOld = [
      for (final round in saved.rounds)
        if (newIndex.containsKey(round.id)) round.id,
    ];
    final keptNew = [
      for (final round in working.rounds)
        if (oldIndex.containsKey(round.id)) round.id,
    ];
    if (!_sameOrder(keptOld, keptNew)) {
      lines.add('$name: the order of the Rounds');
    }
    final plainOld = [
      for (final (i, round) in saved.rounds.indexed)
        _roundName(savedCourse, round, i),
    ];
    final plainNew = [
      for (final (i, round) in working.rounds.indexed)
        _roundName(workingCourse, round, i),
    ];
    final oldNames = _toldRemoved(plainOld, plainNew);
    final newNames = _told(plainNew, plainOld);
    for (final (i, round) in working.rounds.indexed) {
      final roundName = '$name › ${newNames[i]}';
      final was = oldIndex[round.id];
      if (was == null) {
        lines.add('$roundName: added');
        continue;
      }
      lines.addAll(_oneRound(saved.rounds[was], round, roundName));
    }
    for (final (i, round) in saved.rounds.indexed) {
      if (!newIndex.containsKey(round.id)) {
        lines.add('$name › ${oldNames[i]}: removed');
      }
    }
    if (lines.isEmpty) lines.add('$name: its Rounds changed');
    return lines;
  }

  /// A flow's own options: what a Story or a sequence lets the author
  /// choose, without its steps (written again from the content whenever a
  /// step is added, removed or moved) and its title (said apart). Needs the
  /// Story's audio counts only on the steps of [kept], those both Rounds
  /// hold: a step added or removed is said as added or removed.
  static Object? _flowOptions(Object? flow, Set<String> kept) {
    if (flow is! Map) return flow;
    final options = Map<String, Object?>.from(flow)
      ..remove('start')
      ..remove('nodes')
      ..remove('title');
    options['requiresAudio'] = [
      for (final node in (flow['nodes'] as List?) ?? const [])
        if (node is Map &&
            node['requiresAudio'] == true &&
            kept.contains('${node['contentId']}'))
          '${node['contentId']}',
    ]..sort();
    return options;
  }

  static List<String> _oneRound(
    LearningRound saved,
    LearningRound working,
    String name,
  ) {
    final before = saved.toJson();
    final after = working.toJson();
    if (same(before, after)) return const [];
    final lines = <String>[];
    final own = <String>[];
    void say(String what) {
      if (!own.contains(what)) own.add(what);
    }

    final oldContent = _contentOf(saved);
    final newContent = _contentOf(working);
    final contentSame = _sameContent(oldContent, newContent);
    final newIds = {for (final entry in newContent) entry.id};
    final kept = {
      for (final entry in oldContent)
        if (newIds.contains(entry.id)) entry.id,
    };
    for (final key in {...before.keys, ...after.keys}) {
      if (key == 'content' || key == 'updatedAt') continue;
      if (same(before[key], after[key])) continue;
      switch (key) {
        case 'title':
          say('its title');
        case 'roundType' || 'visualType':
          say('its type');
        case 'publicationState':
          say(_state(after[key]));
        case 'provisionalDraft':
          break;
        case 'flow':
          final oldFlow = before[key];
          final newFlow = after[key];
          final oldTitle = oldFlow is Map ? oldFlow['title'] : null;
          final newTitle = newFlow is Map ? newFlow['title'] : null;
          var explained = false;
          if (oldTitle != newTitle) {
            say('its title');
            explained = true;
          }
          if (!same(_flowOptions(oldFlow, kept), _flowOptions(newFlow, kept))) {
            say(
              oldFlow == null || newFlow == null
                  ? 'played in order: ${newFlow == null ? 'no' : 'yes'}'
                  : 'its sequence or Story options',
            );
            explained = true;
          }
          // Steps written again for content that changed say nothing more.
          if (!explained && contentSame) say('its steps');
        case 'testFixedOrder' || 'testPassingPercent':
          say('its Test options');
        case 'timedLimitsSeconds':
          say('its Timed limits');
        case 'focusModuleId' || 'supportingModuleIds':
          say('its GuideBook modules');
        default:
          say('its details');
      }
    }
    if (own.isNotEmpty) lines.add('$name: ${own.join(', ')}');
    if (!contentSame) {
      lines.addAll(_contentChanges(oldContent, newContent, name));
    }
    if (lines.isEmpty) lines.add('$name: changed');
    return lines;
  }

  static List<String> _contentChanges(
    List<_Entry> oldContent,
    List<_Entry> newContent,
    String name,
  ) {
    final lines = <String>[];
    final oldIds = {for (final entry in oldContent) entry.id: entry};
    final newIds = {for (final entry in newContent) entry.id: entry};
    final keptOld = [
      for (final entry in oldContent)
        if (newIds.containsKey(entry.id)) entry.id,
    ];
    final keptNew = [
      for (final entry in newContent)
        if (oldIds.containsKey(entry.id)) entry.id,
    ];
    if (!_sameOrder(keptOld, keptNew)) {
      lines.add('$name: the order of the exercises');
    }
    for (final entry in newContent) {
      final was = oldIds[entry.id];
      if (was == null) {
        lines.add('$name › ${entry.label}: added');
      } else if (!same(was.json, entry.json)) {
        final changes = <String>[];
        void say(String what) {
          if (!changes.contains(what)) changes.add(what);
        }

        for (final key in {...was.json.keys, ...entry.json.keys}) {
          if (same(was.json[key], entry.json[key])) continue;
          switch (key) {
            case 'publicationState':
              say(_state(entry.json[key]));
            case 'editorNotes':
              say('its Editor notes');
            default:
              say('changed');
          }
        }
        // "changed" covers the rest; it comes first when there is any.
        changes.sort(
          (a, b) => (a == 'changed' ? 0 : 1).compareTo(b == 'changed' ? 0 : 1),
        );
        lines.add('$name › ${entry.label}: ${changes.join(', ')}');
      }
    }
    for (final entry in oldContent) {
      if (!newIds.containsKey(entry.id)) {
        lines.add('$name › ${entry.label}: removed');
      }
    }
    if (lines.isEmpty) lines.add('$name: its exercises changed');
    return lines;
  }

  static bool _sameContent(List<_Entry> a, List<_Entry> b) => same(
    [for (final entry in a) entry.json],
    [for (final entry in b) entry.json],
  );

  /// The Round's content, each named by its place as the Round editor's
  /// list numbers it ("Exercise 4": [LearningRound.exercises]); what is not
  /// one of them is a text.
  static List<_Entry> _contentOf(LearningRound round) {
    final entries = <_Entry>[];
    var place = 0;
    for (final content in round.content) {
      final isExercise =
          content.role != 'lesson_intro' &&
          content.asRunnableExercise() != null;
      if (isExercise) place++;
      entries.add(
        _Entry(
          content.id,
          isExercise ? 'Exercise $place' : 'A text',
          content.toJson(),
        ),
      );
    }
    return entries;
  }
}

class _Entry {
  _Entry(this.id, this.label, this.json);

  final String id;
  final String label;
  final Map<String, dynamic> json;
}
