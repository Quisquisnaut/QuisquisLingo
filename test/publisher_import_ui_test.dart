import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';
import 'support/pump_file_io.dart';

void main() {
  for (final valid in [true, false]) {
    testWidgets(
      '${valid ? 'signed' : 'unsigned'} publisher import through Course Manager',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'sound_effects_enabled': false,
        });
        final verifier = fixtureVerifier(
          TrustedPublishers.dummy.publisherId,
          TrustedPublishers.dummy.publisherName,
        );
        final editor = CourseEditorService(publisherVerification: verifier);
        late Course course;
        late Directory directory;
        await tester.runAsync(() async {
          directory = await Directory.systemTemp.createTemp(
            'qql-publisher-import-ui-',
          );
          final json = Map<String, dynamic>.from(
            jsonDecode(
              await File(
                'test/fixtures/publishers/dummy-signed-v1.json',
              ).readAsString(),
            ),
          );
          if (!valid) json.remove('publisherSignature');
          course = Course.fromJson(json);
          await File(
            '${directory.path}/import.json',
          ).writeAsString(jsonEncode(json));
        });
        addTearDown(() async {
          await directory.delete(recursive: true);
        });
        await tester.pumpWidget(
          MaterialApp(
            home: CourseProjectsScreen(
              currentCourse: course,
              editorService: editor,
              transferService: CustomCourseTransferService(
                importDirectory: () async => directory,
                publisherVerification: verifier,
              ),
            ),
          ),
        );
        await tester.pumpUntilFileIoState(
          () => find.byTooltip('Course Import').evaluate().isNotEmpty,
        );
        await tester.tap(find.byTooltip('Course Import'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.byKey(const Key('import-course-json-primary')));
        if (valid) {
          await tester.pumpUntilFileIoState(
            () => find
                .text('Install verified Publisher Course?')
                .evaluate()
                .isNotEmpty,
          );
          expect(
            find.textContaining('Verified publisher: Dummy Publisher'),
            findsOneWidget,
          );
          await tester.tap(
            find.widgetWithText(FilledButton, 'Install verified course'),
          );
          await tester.pumpUntilFileIoState(
            () => find
                .textContaining('Installed Publisher Course version')
                .evaluate()
                .isNotEmpty,
          );
          final stored = await tester.runAsync(editor.listUserCourses);
          expect(
            stored!.single.publisherVerificationStatus,
            PublisherVerificationStatus.verified,
          );
        } else {
          await tester.pumpUntilFileIoState(
            () => find
                .textContaining('Publisher signature missing')
                .evaluate()
                .isNotEmpty,
          );
          expect(
            find.textContaining(
              'This file cannot be imported as a Publisher Course.',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('as an official course'), findsNothing);
          expect(find.text('Install verified Publisher Course?'), findsNothing);
          expect(await tester.runAsync(editor.listUserCourses), isEmpty);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
