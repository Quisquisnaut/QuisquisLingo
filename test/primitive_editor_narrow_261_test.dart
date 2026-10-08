import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/canonical_exercise_samples.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 261 Revision 6 follow-up (owner request of 2 October 2026): the
/// canonical editor fits a phone. At 360 pixels its option and evaluation
/// menus overflowed to the right; every primitive's form, blank and filled
/// with its example, and every exercise of the Exercise Laboratory (long
/// IDs and real content) now lays out without an overflow.
final _stamp = DateTime.utc(2026, 10, 2, 12);

Future<void> _pump(WidgetTester tester, Exercise exercise, bool isNew) async {
  tester.view.physicalSize = const Size(360, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: PrimitiveEditorScreen(
        key: UniqueKey(),
        exercise: exercise,
        title: isNew ? 'New Exercise' : 'Exercise',
        isNew: isNew,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final primitive in ExercisePrimitive.values) {
    testWidgets('${primitive.serialized} fits 360 pixels', (tester) async {
      await _pump(
        tester,
        CanonicalExerciseDraft.blankExercise(
          primitive,
          id: 'blank',
          updatedAt: _stamp,
        ),
        true,
      );
      expect(tester.takeException(), isNull, reason: 'blank');
      await _pump(
        tester,
        CanonicalExerciseSamples.forPrimitive(
          primitive,
          id: 'sample',
          updatedAt: _stamp,
        ),
        false,
      );
      expect(tester.takeException(), isNull, reason: 'example');
    });
  }

  testWidgets('every Laboratory exercise fits 360 pixels', (tester) async {
    final course = Course.fromJson(
      jsonDecode(
            File(
              'assets/courses/exercise_laboratory_en_it.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    var count = 0;
    for (final lesson in course.lessons) {
      for (final round in lesson.rounds) {
        for (final content in round.content) {
          final exercise = content.exercise;
          if (exercise == null) continue;
          await _pump(tester, exercise, false);
          expect(tester.takeException(), isNull, reason: exercise.id);
          count++;
        }
      }
    }
    expect(count, greaterThan(100));
  });
}
