import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _beforeTime = DateTime.utc(2026, 9, 4, 9);
final _transferTime = DateTime.utc(2026, 9, 5, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'transfer-ui-learner-sentinel': 42,
    });
  });

  for (final copy in [false, true]) {
    for (final sameLesson in [false, true]) {
      for (final id in ['exercise-a', 'text-note', 'presentation']) {
        testWidgets(
          '${copy ? 'Copy' : 'Move'} $id through explicit destination ${sameLesson ? 'within' : 'across'} Lesson preserves v6 content',
          (tester) async {
            _viewport(tester);
            final original = _course();
            final before = jsonEncode(original.toJson());
            final changes = <Course>[];
            LearningRound? returned;
            await _openRound(
              tester,
              original,
              changes.add,
              (round) => returned = round,
            );
            await _openTransfer(tester, 'exercise', id, copy: copy);
            final destinationLesson = sameLesson ? 'lesson-one' : 'lesson-two';
            final destinationRound = sameLesson
                ? 'same-lesson-round'
                : 'other-lesson-round';
            await _chooseDestination(
              tester,
              original,
              destinationLesson,
              roundId: destinationRound,
            );
            await tester.tap(
              find.byKey(const Key('confirm-authoring-transfer')),
            );
            await _settle(tester);

            expect(tester.takeException(), isNull);
            expect(changes, hasLength(1));
            final staged = changes.single;
            final sourceContent = _round(original, 'source-round').content;
            final originalItem = sourceContent.singleWhere((c) => c.id == id);
            final remaining = _round(staged, 'source-round').content;
            expect(remaining.map((c) => c.toJson()), [
              for (final content in sourceContent)
                if (copy || content.id != id) content.toJson(),
            ]);
            final destination = _round(staged, destinationRound);
            expect(
              destination.content.first.toJson(),
              _round(original, destinationRound).content.first.toJson(),
            );
            expect(destination.content, hasLength(2));
            final transferred = destination.content.last;
            if (copy) {
              expect(transferred.id, isNot(id));
              expect(transferred.publicationState, PublicationState.draft);
              expect(transferred.kind, originalItem.kind);
              expect(transferred.role, originalItem.role);
              expect(transferred.required, originalItem.required);
              expect(transferred.text, originalItem.text);
              expect(
                transferred.presentation?.toJson(),
                originalItem.presentation?.toJson(),
              );
              expect(transferred.sourceRefs, originalItem.sourceRefs);
              if (transferred.exercise case final exercise?) {
                expect(
                  exercise.interaction.items
                      .map((i) => i.id)
                      .toSet()
                      .intersection(
                        originalItem.exercise!.interaction.items
                            .map((i) => i.id)
                            .toSet(),
                      ),
                  isEmpty,
                );
                expect(
                  exercise.evaluation.correctItemIds.single,
                  exercise.interaction.items.first.id,
                );
              }
            } else {
              expect(transferred.toJson(), originalItem.toJson());
            }
            expect(
              staged.toJson()..remove('lessons'),
              original.toJson()..remove('lessons'),
            );
            expect(jsonEncode(original.toJson()), before);
            expect((await SharedPreferences.getInstance()).getKeys(), {
              'transfer-ui-learner-sentinel',
            });

            await _back(tester);
            expect(returned, isNotNull);
            expect(
              returned!.updatedAt,
              _round(staged, 'source-round').updatedAt,
            );
            expect(
              returned!.content.map((c) => c.toJson()),
              remaining.map((c) => c.toJson()),
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'Exercise destination Cancel leaves mixed content and publication unchanged',
    (tester) async {
      _viewport(tester);
      final original = _course();
      final changes = <Course>[];
      LearningRound? returned;
      await _openRound(
        tester,
        original,
        changes.add,
        (round) => returned = round,
      );
      await _openTransfer(tester, 'exercise', 'exercise-a', copy: false);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('confirm-authoring-transfer')),
            )
            .onPressed,
        isNull,
      );
      await _chooseDestination(
        tester,
        original,
        'lesson-two',
        roundId: 'other-lesson-round',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await _settle(tester);
      expect(changes, isEmpty);
      expect(
        find.byKey(const ValueKey('exercise-actions-exercise-a')),
        findsOneWidget,
      );
      await _back(tester);
      expect(returned!.toJson(), _round(original, 'source-round').toJson());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing destination Lesson clears the previous Round selection',
    (tester) async {
      _viewport(tester);
      final original = _course();
      final changes = <Course>[];
      await _openRound(tester, original, changes.add, (_) {});
      await _openTransfer(tester, 'exercise', 'exercise-a', copy: true);
      await _chooseDestination(
        tester,
        original,
        'lesson-one',
        roundId: 'same-lesson-round',
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('confirm-authoring-transfer')),
            )
            .onPressed,
        isNotNull,
      );
      await _chooseLesson(tester, original, 'lesson-two');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('confirm-authoring-transfer')),
            )
            .onPressed,
        isNull,
      );
      final roundField = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('transfer-destination-round-lesson-two')),
      );
      expect(roundField.initialValue, isNull);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await _settle(tester);
      expect(changes, isEmpty);
    },
  );

  for (final copy in [false, true]) {
    final destinations = copy ? ['lesson-one', 'lesson-two'] : ['lesson-two'];
    for (final destination in destinations) {
      testWidgets(
        '${copy ? 'Copy' : 'Move'} Round to $destination survives every parent return',
        (tester) async {
          _viewport(tester);
          final original = _course();
          Course? returned;
          await _openManagement(
            tester,
            original,
            (course) => returned = course,
          );
          await _enterRounds(tester, 'lesson-one');
          await _openTransfer(tester, 'round', 'source-round', copy: copy);
          await _chooseDestination(tester, original, destination);
          await tester.tap(find.byKey(const Key('confirm-authoring-transfer')));
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey('round-actions-source-round')),
            copy ? findsOneWidget : findsNothing,
          );

          await _back(tester);
          expect(find.byType(LessonEditorScreen), findsOneWidget);
          await _back(tester);
          expect(find.byType(LessonManagementScreen), findsOneWidget);
          await _back(tester);
          expect(returned, isNotNull);
          final source = _round(original, 'source-round');
          final target = returned!.lessons
              .singleWhere((l) => l.lessonId == destination)
              .rounds
              .last;
          if (copy) {
            expect(target.id, isNot(source.id));
            expect(target.publicationState, PublicationState.draft);
            expect(target.content, hasLength(source.content.length));
            expect(
              target.content.map((c) => c.kind),
              source.content.map((c) => c.kind),
            );
            expect(
              target.content.map((c) => c.role),
              source.content.map((c) => c.role),
            );
            expect(target.content[1].text, source.content[1].text);
            expect(
              target.content[3].presentation!.toJson(),
              source.content[3].presentation!.toJson(),
            );
            final originalIds = {
              source.id,
              for (final c in source.content) c.id,
            };
            expect(
              {
                target.id,
                for (final c in target.content) c.id,
              }.intersection(originalIds),
              isEmpty,
            );
            expect(_round(returned!, 'source-round').toJson(), source.toJson());
          } else {
            expect(target.toJson(), source.toJson());
            expect(returned!.lessons.first.rounds.map((r) => r.id), [
              'same-lesson-round',
            ]);
          }
          expect(returned!.courseId, original.courseId);
          expect(returned!.courseVersion, original.courseVersion);
          expect(
            returned!.lessons.first.guidebook.toJson(),
            original.lessons.first.guidebook.toJson(),
          );
          expect((await SharedPreferences.getInstance()).getKeys(), {
            'transfer-ui-learner-sentinel',
          });
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Round destination Cancel returns an unchanged Course working copy',
    (tester) async {
      _viewport(tester);
      final original = _course();
      Course? returned;
      await _openManagement(tester, original, (course) => returned = course);
      await _enterRounds(tester, 'lesson-one');
      await _openTransfer(tester, 'round', 'source-round', copy: false);
      final lessons = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: find.byKey(const Key('transfer-destination-lesson')),
          matching: find.byWidgetPredicate(
            (widget) => widget is DropdownButton<String>,
          ),
        ),
      );
      expect(
        lessons.items!.map((item) => item.value),
        isNot(contains('lesson-one')),
      );
      await _chooseDestination(tester, original, 'lesson-two');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await _settle(tester);
      await _back(tester);
      await _back(tester);
      await _back(tester);
      expect(returned!.toJson(), original.toJson());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nested Exercise copies and moves propagate to both Lesson destinations',
    (tester) async {
      _viewport(tester);
      final original = _course();
      Course? returned;
      await _openManagement(tester, original, (course) => returned = course);
      await _enterRounds(tester, 'lesson-one');
      await tester.tap(
        find.byKey(const ValueKey('round-actions-source-round')),
      );
      await _settle(tester);
      await tester.tap(find.text('Edit').last);
      await _settle(tester);
      await _openTransfer(tester, 'exercise', 'exercise-a', copy: true);
      await _chooseDestination(
        tester,
        original,
        'lesson-one',
        roundId: 'same-lesson-round',
      );
      await tester.tap(find.byKey(const Key('confirm-authoring-transfer')));
      await _settle(tester);
      await _openTransfer(tester, 'exercise', 'exercise-b', copy: false);
      await _chooseDestination(
        tester,
        original,
        'lesson-two',
        roundId: 'other-lesson-round',
      );
      await tester.tap(find.byKey(const Key('confirm-authoring-transfer')));
      await _settle(tester);
      for (var i = 0; i < 4; i++) {
        await _back(tester);
      }
      expect(returned, isNotNull);
      expect(_round(returned!, 'same-lesson-round').content, hasLength(2));
      expect(
        _round(returned!, 'same-lesson-round').content.last.publicationState,
        PublicationState.draft,
      );
      expect(
        _round(returned!, 'other-lesson-round').content.last.toJson(),
        _round(original, 'source-round').content.last.toJson(),
      );
      expect(_round(returned!, 'source-round').content.map((c) => c.id), [
        'exercise-a',
        'hidden-intro',
        'text-note',
        'presentation',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Draft count and orange plus pink outlines update after a working-copy copy',
    (tester) async {
      _viewport(tester);
      final course = _course(invalidAnswer: true);
      final changes = <Course>[];
      await tester.pumpWidget(
        MaterialApp(
          home: LessonRoundsScreen(
            course: course,
            lesson: course.lessons.first,
            onCourseChanged: changes.add,
            clock: () => _transferTime,
          ),
        ),
      );
      await _settle(tester);
      final sourceIndicator = find.byKey(
        const ValueKey('round-draft-indicator-source-round'),
      );
      final sourceDecoration =
          tester.widget<Container>(sourceIndicator).decoration!
              as BoxDecoration;
      expect((sourceDecoration.border! as Border).top.color, Colors.orange);
      final sourceCard = tester.widget<Card>(
        find.descendant(of: sourceIndicator, matching: find.byType(Card)),
      );
      expect(
        (sourceCard.shape! as RoundedRectangleBorder).side.color,
        Colors.pinkAccent,
      );
      expect(
        find.text(
          '1 Draft Exercise · Orange: Draft Exercises · Pink: Audit Errors',
        ),
        findsOneWidget,
      );
      final destinationDecoration =
          tester
                  .widget<Container>(
                    find.byKey(
                      const ValueKey('round-draft-indicator-same-lesson-round'),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(destinationDecoration.border, isNull);

      await _openTransfer(tester, 'round', 'source-round', copy: true);
      await _chooseDestination(tester, course, 'lesson-one');
      await tester.tap(find.byKey(const Key('confirm-authoring-transfer')));
      await _settle(tester);
      expect(changes, hasLength(1));
      final copy = changes.single.lessons.first.rounds.last;
      expect(copy.exercises, hasLength(4));
      expect(
        find.text(
          '5 Draft Exercises · Orange: Draft Exercises · Pink: Audit Errors',
        ),
        findsOneWidget,
      );
      final copiedIndicator = find.byKey(
        ValueKey('round-draft-indicator-${copy.id}'),
      );
      await tester.ensureVisible(copiedIndicator);
      final copiedDecoration =
          tester.widget<Container>(copiedIndicator).decoration!
              as BoxDecoration;
      expect((copiedDecoration.border! as Border).top.color, Colors.orange);
      expect(tester.takeException(), isNull);
    },
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await _settle(tester);
}

Future<void> _openRound(
  WidgetTester tester,
  Course course,
  ValueChanged<Course> onChanged,
  ValueChanged<LearningRound?> onClosed,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              onClosed(
                await Navigator.of(context).push<LearningRound>(
                  MaterialPageRoute(
                    builder: (_) => RoundEditorScreen(
                      course: course,
                      lesson: course.lessons.first,
                      round: course.lessons.first.rounds.first,
                      roundIndex: 0,
                      onCourseChanged: onChanged,
                      clock: () => _transferTime,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open Round'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Round'));
  await _settle(tester);
}

Future<void> _openManagement(
  WidgetTester tester,
  Course course,
  ValueChanged<Course?> onClosed,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              onClosed(
                await Navigator.of(context).push<Course>(
                  MaterialPageRoute(
                    builder: (_) => LessonManagementScreen(
                      course: course,
                      initiallyLocked: false,
                      clock: () => _transferTime,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open Lessons'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Lessons'));
  await _settle(tester);
}

Future<void> _enterRounds(WidgetTester tester, String lessonId) async {
  final lesson = find.byKey(ValueKey(lessonId));
  await tester.ensureVisible(lesson);
  await tester.tap(
    find.descendant(of: lesson, matching: find.byType(ListTile)),
  );
  await _settle(tester);
  await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
  await _settle(tester);
}

Future<void> _openTransfer(
  WidgetTester tester,
  String kind,
  String id, {
  required bool copy,
}) async {
  final menu = find.byKey(ValueKey('$kind-actions-$id'));
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await _settle(tester);
  await tester.tap(find.text(copy ? 'Copy to…' : 'Move to…').last);
  await _settle(tester);
  expect(find.byKey(const Key('confirm-authoring-transfer')), findsOneWidget);
}

Future<void> _chooseLesson(
  WidgetTester tester,
  Course course,
  String lessonId,
) async {
  final index = course.lessons.indexWhere(
    (lesson) => lesson.lessonId == lessonId,
  );
  await tester.tap(find.byKey(const Key('transfer-destination-lesson')));
  await _settle(tester);
  await tester.tap(
    find.text('Lesson ${index + 1}: ${course.lessons[index].title}').last,
  );
  await _settle(tester);
}

Future<void> _chooseDestination(
  WidgetTester tester,
  Course course,
  String lessonId, {
  String? roundId,
}) async {
  await _chooseLesson(tester, course, lessonId);
  if (roundId == null) return;
  final lesson = course.lessons.singleWhere((l) => l.lessonId == lessonId);
  final index = lesson.rounds.indexWhere((round) => round.id == roundId);
  await tester.tap(
    find.byKey(ValueKey('transfer-destination-round-$lessonId')),
  );
  await _settle(tester);
  await tester.tap(find.text(lesson.rounds[index].displayTitle(index)).last);
  await _settle(tester);
}

LearningRound _round(Course course, String id) => course.lessons
    .expand((lesson) => lesson.rounds)
    .singleWhere((round) => round.id == id);

Course _course({bool invalidAnswer = false}) => Course(
  courseId: 'transfer-ui-course',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Transfer UI fixture',
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: '4',
  courseDescription: 'Preserved course metadata',
  lessons: [
    Lesson(
      lessonId: 'lesson-one',
      updatedAt: _beforeTime,
      title: 'First',
      guidebook: Guidebook(
        content: const [
          LearningContent(
            id: 'guide',
            kind: 'text',
            text: 'Original GuideBook',
          ),
        ],
      ),
      rounds: [
        LearningRound(
          id: 'source-round',
          updatedAt: _beforeTime,
          title: 'Source',
          visualType: 'story',
          content: [
            _exerciseContent('exercise-a', invalid: invalidAnswer),
            const LearningContent(
              id: 'hidden-intro',
              kind: 'text',
              role: 'lesson_intro',
              required: false,
              text: 'Hidden metadata must stay here',
              sourceRefs: ['guide'],
            ),
            const LearningContent(
              id: 'text-note',
              kind: 'text',
              role: 'round_note',
              required: false,
              editorTemplate: 'text',
              text: 'Interleaved text must stay here',
              sourceRefs: ['guide'],
            ),
            const LearningContent(
              id: 'presentation',
              kind: 'presentation',
              role: 'round_note',
              required: false,
              editorTemplate: 'flashcard',
              text: 'Extra wrapper metadata',
              sourceRefs: ['guide'],
              presentation: Presentation(
                content: [
                  PromptElement(role: 'term', type: 'text', text: 'Casa'),
                  PromptElement(role: 'meaning', type: 'text', text: 'House'),
                  PromptElement(
                    role: 'image',
                    type: 'image',
                    asset: 'assets/exercise_images/fixture.png',
                  ),
                  PromptElement(
                    role: 'audio',
                    type: 'audio',
                    asset: 'assets/audio/fixture.mp3',
                    text: 'casa',
                    speaker: 'Fixture speaker',
                  ),
                ],
                actions: ['understood'],
              ),
            ),
            _exerciseContent('exercise-b', draft: true),
          ],
        ),
        LearningRound(
          id: 'same-lesson-round',
          updatedAt: _beforeTime,
          title: 'Same Lesson destination',
          content: [_exerciseContent('same-existing')],
        ),
      ],
    ),
    Lesson(
      lessonId: 'lesson-two',
      updatedAt: _beforeTime,
      title: 'Second',
      rounds: [
        LearningRound(
          id: 'other-lesson-round',
          updatedAt: _beforeTime,
          title: 'Other Lesson destination',
          content: [_exerciseContent('other-existing')],
        ),
      ],
    ),
  ],
);

LearningContent _exerciseContent(
  String id, {
  bool draft = false,
  bool invalid = false,
}) => LearningContent(
  id: id,
  kind: 'exercise',
  publicationState: draft ? PublicationState.draft : PublicationState.published,
  required: false,
  editorTemplate: 'choice',
  role: 'round_note',
  text: 'Wrapper for $id',
  sourceRefs: const ['guide'],
  exercise: Exercise.v2(
    id: id,
    publicationState: draft
        ? PublicationState.draft
        : PublicationState.published,
    updatedAt: _beforeTime,
    editorTemplate: 'choice',
    promptElements: [PromptElement(type: 'text', text: 'Question $id')],
    interaction: ExerciseInteraction(
      kind: 'select',
      items: [
        ExerciseItem(
          id: '${id}_a',
          content: const [PromptElement(type: 'text', text: 'Casa')],
        ),
        ExerciseItem(
          id: '${id}_b',
          content: const [PromptElement(type: 'text', text: 'Cane')],
        ),
      ],
    ),
    evaluation: ExerciseEvaluation(
      kind: 'selected_items',
      correctItemIds: [invalid ? 'missing-item' : '${id}_a'],
    ),
    hint: 'A clue',
    feedback: const {'correct': 'Authored feedback'},
  ),
);
