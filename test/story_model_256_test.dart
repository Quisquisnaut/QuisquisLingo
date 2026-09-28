import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_image_usage.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';

/// Build 256 Revision 5, Stage 1: the Story model. A flow carries the
/// Story's title, scroll log and read-aloud default and marks the exercises
/// that need the Story's audio; a Course names its narrator and characters;
/// a prompt element names its speaker; a presentation may reveal its text
/// after its audio; avatars are images the Course uses.
Map<String, dynamic> _demoJson() =>
    jsonDecode(
          File(
            'demo_courses/italian_demo_2_pick_the_translation.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

FlowNode _content(String id) =>
    FlowNode(id: id, kind: FlowNodeKind.content, contentId: id);

FlowNode _exercise(String id, {bool requiresAudio = false}) => FlowNode(
  id: id,
  kind: FlowNodeKind.exercise,
  contentId: id,
  requiresAudio: requiresAudio,
);

LearningContent _presentation(String id, String text) =>
    LearningContent.fromExercise(
      Exercise.canonical(
        id: id,
        primitive: ExercisePrimitive.presentation,
        promptElements: [PromptElement(role: 'line', type: 'text', text: text)],
        canonicalEvaluation: CanonicalEvaluation.none,
        updatedAt: DateTime.utc(2026, 9, 28),
      ),
    );

LearningContent _select(String id) => LearningContent.fromExercise(
  Exercise.canonical(
    id: id,
    primitive: ExercisePrimitive.select,
    promptElements: const [PromptElement(type: 'text', text: 'Vero?')],
    items: [
      ExerciseItem(
        id: '${id}_a',
        content: const [PromptElement(type: 'text', text: 'sì')],
      ),
      ExerciseItem(
        id: '${id}_b',
        content: const [PromptElement(type: 'text', text: 'no')],
      ),
    ],
    canonicalEvaluation: CanonicalEvaluation(
      mode: EvaluationMode.exactItem,
      correctItemIds: ['${id}_a'],
    ),
    updatedAt: DateTime.utc(2026, 9, 28),
  ),
);

const _media =
    'media:'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png';

void main() {
  group('flow Story options', () {
    test('title, log, read-aloud and audio dependence round-trip', () {
      final flow = ContentFlow.linear(
        [
          _content('cover'),
          _content('line1'),
          _exercise('q1', requiresAudio: true),
          _exercise('q2'),
        ],
        presentation: FlowPresentation.scroll,
        title: 'Al bar',
        log: FlowLog.dialogue,
        readAloud: FlowReadAloud.manual,
      );
      final json = flow.toJson();
      expect(json['title'], 'Al bar');
      expect(json['log'], 'dialogue');
      expect(json['readAloud'], 'manual');
      expect(json['presentation'], 'scroll');
      final nodes = json['nodes'] as List;
      expect((nodes[2] as Map)['requiresAudio'], isTrue);
      expect((nodes[3] as Map).containsKey('requiresAudio'), isFalse);
      final back = ContentFlow.fromJson(jsonDecode(jsonEncode(json)));
      expect(back.title, 'Al bar');
      expect(back.log, FlowLog.dialogue);
      expect(back.readAloud, FlowReadAloud.manual);
      expect(back.audioDependentContentIds, {'q1'});
      expect(back.isLinear, isTrue);
      expect(back.toJson(), json);
    });

    test('defaults are omitted from JSON and read back', () {
      final flow = ContentFlow.linear([_content('a'), _exercise('b')]);
      final json = flow.toJson();
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('log'), isFalse);
      expect(json.containsKey('readAloud'), isFalse);
      final back = ContentFlow.fromJson(json);
      expect(back.title, '');
      expect(back.log, FlowLog.all);
      expect(back.readAloud, FlowReadAloud.automatic);
      expect(back.audioDependentContentIds, isEmpty);
    });

    test('bad Story values are refused, never coerced', () {
      final base = ContentFlow.linear([_content('a'), _exercise('b')]).toJson();
      expect(
        () => ContentFlow.fromJson({...base, 'log': 'exercises'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ContentFlow.fromJson({...base, 'readAloud': true}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ContentFlow.fromJson({...base, 'title': 7}),
        throwsA(isA<FormatException>()),
      );
      final nodes = List<Map<String, dynamic>>.from(
        (base['nodes'] as List).map((n) => Map<String, dynamic>.from(n as Map)),
      );
      expect(
        () => ContentFlow.fromJson({
          ...base,
          'nodes': [
            {...nodes[0], 'requiresAudio': true},
            nodes[1],
          ],
        }),
        throwsA(isA<FormatException>()),
        reason: 'a content node cannot depend on audio',
      );
      expect(
        () => ContentFlow.fromJson({
          ...base,
          'nodes': [
            nodes[0],
            {...nodes[1], 'requiresAudio': 'yes'},
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('copyWith changes one option and keeps the rest', () {
      final flow = ContentFlow.linear(
        [_content('a')],
        title: 'T',
        log: FlowLog.dialogue,
      );
      final changed = flow.copyWith(readAloud: FlowReadAloud.manual);
      expect(changed.title, 'T');
      expect(changed.log, FlowLog.dialogue);
      expect(changed.readAloud, FlowReadAloud.manual);
      expect(changed.nodes.map((n) => n.id), ['a']);
    });
  });

  group('RoundFlowAuthoring carries the Story options', () {
    final content = [
      _presentation('cover', 'Al bar'),
      _presentation('l1', 'Buongiorno!'),
      _select('q1'),
      _select('q2'),
    ];

    test('linearFor writes them and marks the audio-dependent exercises', () {
      final flow = RoundFlowAuthoring.linearFor(
        content,
        presentation: FlowPresentation.scroll,
        title: 'Al bar',
        log: FlowLog.dialogue,
        readAloud: FlowReadAloud.manual,
        requiresAudio: {'q2', 'l1'},
      );
      expect(flow.title, 'Al bar');
      expect(flow.log, FlowLog.dialogue);
      expect(flow.readAloud, FlowReadAloud.manual);
      expect(flow.audioDependentContentIds, {'q2'});
      expect(flow.nodeById('l1')!.requiresAudio, isFalse);
    });

    test('forContent keeps them across a reorder by content ID', () {
      final flow = RoundFlowAuthoring.linearFor(
        content,
        presentation: FlowPresentation.scroll,
        title: 'Al bar',
        log: FlowLog.dialogue,
        readAloud: FlowReadAloud.manual,
        requiresAudio: {'q2'},
      );
      final reordered = RoundFlowAuthoring.forContent(flow, [
        content[0],
        content[3],
        content[1],
        content[2],
      ]);
      expect(reordered!.linearNodeIds(), ['cover', 'q2', 'l1', 'q1']);
      expect(reordered.title, 'Al bar');
      expect(reordered.log, FlowLog.dialogue);
      expect(reordered.readAloud, FlowReadAloud.manual);
      expect(reordered.audioDependentContentIds, {'q2'});
    });

    test('withPresentation, withStoryOptions and withAudioDependence', () {
      final flow = RoundFlowAuthoring.linearFor(content, title: 'Al bar');
      final scrolling = RoundFlowAuthoring.withPresentation(
        flow,
        FlowPresentation.scroll,
      );
      expect(scrolling.title, 'Al bar');
      final options = RoundFlowAuthoring.withStoryOptions(
        scrolling,
        log: FlowLog.dialogue,
        readAloud: FlowReadAloud.manual,
      );
      expect(options.presentation, FlowPresentation.scroll);
      expect(options.log, FlowLog.dialogue);
      expect(options.readAloud, FlowReadAloud.manual);
      final dependent = RoundFlowAuthoring.withAudioDependence(
        options,
        content[2],
        requiresAudio: true,
      );
      expect(dependent.audioDependentContentIds, {'q1'});
      final ignored = RoundFlowAuthoring.withAudioDependence(
        dependent,
        content[1],
        requiresAudio: true,
      );
      expect(ignored.audioDependentContentIds, {
        'q1',
      }, reason: 'a dialogue line is never skipped');
      expect(
        RoundFlowAuthoring.withAudioDependence(
          dependent,
          content[2],
          requiresAudio: false,
        ).audioDependentContentIds,
        isEmpty,
      );
    });

    test('remapped keeps them over the renamed content', () {
      final flow = RoundFlowAuthoring.linearFor(
        content,
        title: 'Al bar',
        log: FlowLog.dialogue,
        requiresAudio: {'q1'},
      );
      final copy = RoundFlowAuthoring.remapped(flow, {
        'cover': 'c2',
        'l1': 'l2',
        'q1': 'x1',
        'q2': 'x2',
      });
      expect(copy!.linearNodeIds(), ['c2', 'l2', 'x1', 'x2']);
      expect(copy.title, 'Al bar');
      expect(copy.log, FlowLog.dialogue);
      expect(copy.audioDependentContentIds, {'x1'});
    });
  });

  group('Course narrator and characters', () {
    test('round-trip, defaults and lookup', () {
      final json = _demoJson();
      json['storyNarrator'] = {'name': 'Narrator', 'language': 'source'};
      json['storyCharacters'] = [
        {
          'id': 'character_anna',
          'name': 'Anna',
          'avatar': 'assets/avatars/cat.png',
          'language': 'target',
          'voice': 'female',
        },
        {'id': 'character_marco', 'avatar': _media, 'language': 'target'},
      ];
      final course = Course.fromJson(json);
      expect(course.narrator.name, 'Narrator');
      expect(course.narrator.isNarrator, isTrue);
      expect(course.storyCharacters, hasLength(2));
      expect(course.speakerOf('')!.isNarrator, isTrue);
      expect(course.speakerOf('character_anna')!.voice, StoryVoice.female);
      expect(course.speakerOf('character_marco')!.voice, StoryVoice.any);
      expect(course.speakerOf('character_marco')!.name, '');
      expect(course.speakerOf('nobody'), isNull);
      final back = Course.fromJson(jsonDecode(jsonEncode(course.toJson())));
      expect(back.toJson()['storyNarrator'], {
        'name': 'Narrator',
        'language': 'source',
      });
      expect(back.toJson()['storyCharacters'], [
        {
          'id': 'character_anna',
          'name': 'Anna',
          'avatar': 'assets/avatars/cat.png',
          'language': 'target',
          'voice': 'female',
        },
        {'id': 'character_marco', 'avatar': _media, 'language': 'target'},
      ]);
    });

    test(
      'a Course without Story data has the default narrator and no keys',
      () {
        final course = Course.fromJson(_demoJson());
        expect(course.storyNarrator, isNull);
        expect(course.storyCharacters, isEmpty);
        expect(course.narrator.language, TextLanguage.source);
        expect(course.narrator.voice, StoryVoice.any);
        expect(course.toJson().containsKey('storyNarrator'), isFalse);
        expect(course.toJson().containsKey('storyCharacters'), isFalse);
      },
    );

    test('speakers parse strictly', () {
      Course parse(Map<String, dynamic> extra) =>
          Course.fromJson({..._demoJson(), ...extra});
      void refused(Map<String, dynamic> extra, String reason) => expect(
        () => parse(extra),
        throwsA(isA<FormatException>()),
        reason: reason,
      );
      refused({
        'storyCharacters': [
          {'name': 'Anna', 'language': 'target'},
        ],
      }, 'a character needs an id');
      refused({
        'storyNarrator': {'id': 'x', 'language': 'source'},
      }, 'the narrator has no id');
      refused({
        'storyNarrator': {
          'language': 'source',
          'avatar': 'assets/mascots/cat.png',
        },
      }, 'an avatar must be a bundled avatar or a Course medium');
      refused({
        'storyNarrator': {'language': 'source', 'voice': 'child'},
      }, 'unknown voice');
      refused({
        'storyNarrator': {'language': 'klingon'},
      }, 'language must be source or target');
      refused({
        'storyNarrator': {'language': 'source', 'colour': 'red'},
      }, 'unknown fields are refused');
      refused({
        'storyCharacters': [
          {'id': 'c', 'language': 'target'},
          {'id': 'c', 'language': 'target'},
        ],
      }, 'ids are unique');
      refused({'storyCharacters': 'Anna'}, 'the list must be a list');
      refused({'storyNarrator': 'Narrator'}, 'the narrator must be an object');
    });
  });

  test('a prompt element names its speaker and omits an empty one', () {
    const element = PromptElement(
      role: 'line',
      type: 'text',
      text: 'Ciao!',
      speakerId: 'character_anna',
    );
    expect(element.toJson()['speakerId'], 'character_anna');
    expect(
      PromptElement.fromJson(element.toJson()).speakerId,
      'character_anna',
    );
    expect(
      const PromptElement(
        type: 'text',
        text: 'x',
      ).toJson().containsKey('speakerId'),
      isFalse,
    );
    expect(element.copyWith(speakerId: '').speakerId, '');
  });

  test('textReveal is a presentation option with the immediate default', () {
    expect(OptionKey.tryParse('textReveal'), OptionKey.textReveal);
    expect(
      OptionValue.parse(OptionKey.textReveal, 'afterAudio'),
      const EnumOptionValue(TextReveal.afterAudio),
    );
    expect(OptionValue.parse(OptionKey.textReveal, 'later'), isNull);
    final effective = PrimitiveCapabilityRegistry.effectiveOptions(
      ExercisePrimitive.presentation,
      PrimitiveOptions.empty,
    );
    expect(
      effective.enumValue<TextReveal>(OptionKey.textReveal),
      TextReveal.immediate,
    );
    final support = PrimitiveCapabilityRegistry.runtimeSupport(
      primitive: ExercisePrimitive.presentation,
      options: PrimitiveOptions({
        OptionKey.textReveal: const EnumOptionValue(TextReveal.afterAudio),
      }),
      evaluationMode: EvaluationMode.none,
    );
    expect(support.state, ExerciseSupportState.executable);
    expect(
      PrimitiveCapabilityRegistry.validate(
        primitive: ExercisePrimitive.select,
        options: PrimitiveOptions({
          OptionKey.textReveal: const EnumOptionValue(TextReveal.afterAudio),
        }),
        evaluationMode: EvaluationMode.exactItem,
      ),
      isNotEmpty,
      reason: 'textReveal belongs to the presentation primitive only',
    );
  });

  test('avatars are images the Course uses', () {
    final json = _demoJson();
    json['storyNarrator'] = {
      'language': 'source',
      'avatar': 'assets/avatars/robot.png',
    };
    json['storyCharacters'] = [
      {
        'id': 'character_anna',
        'name': 'Anna',
        'avatar': _media,
        'language': 'target',
      },
      {'id': 'character_mute', 'language': 'target'},
    ];
    final course = Course.fromJson(json);
    final uses = CourseImageUsage.uses(course);
    expect(
      uses
          .where((use) => use.asset == 'assets/avatars/robot.png')
          .single
          .location,
      'Story narrator avatar',
    );
    expect(
      uses.where((use) => use.asset == _media).single.location,
      'Story character “Anna” avatar',
    );
    expect(
      CourseImageUsage.usedAssets(course),
      containsAll([_media, 'assets/avatars/robot.png']),
    );
    expect(uses.where((use) => use.location.contains('mute')), isEmpty);
  });

  test('the five bundled avatars exist and match the avatar pattern', () {
    for (final name in ['cat', 'dog', 'kid', 'monkey', 'robot']) {
      final asset = 'assets/avatars/$name.png';
      expect(File(asset).existsSync(), isTrue, reason: asset);
      expect(StorySpeaker.avatarPattern.hasMatch(asset), isTrue, reason: asset);
    }
    expect(
      StorySpeaker.avatarPattern.hasMatch('assets/mascots/cat_reading.png'),
      isFalse,
    );
    expect(StorySpeaker.avatarPattern.hasMatch(_media), isTrue);
  });
}
