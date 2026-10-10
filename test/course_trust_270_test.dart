import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/admin_pin_gate.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/publisher_course_export.dart';
import 'package:quisquislingo_app/services/publisher_course_ids.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:quisquislingo_app/widgets/shared_device_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _friend = '33333333-3333-4333-8333-333333333333';

Course _course({
  String id = 'friend-course',
  String maintainer = _friend,
  String version = '1',
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: 'Author',
  ),
  maintainer: CourseMaintainer(maintainer),
  originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
  courseVersion: version,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Friend Course',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

// Build 270 Revision 8 (owner decisions of 10 October 2026): received
// Courses can be removed, published Courses get an ID of their own, a
// Publisher Course's ID stays reserved, and a shared device says what the
// Access PIN can do.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late CourseEditorService editor;
  final profiles = ProfileService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProfileService.beginAccessSession();
    root = await Directory.systemTemp.createTemp('qql_270_trust_');
    for (final (id, name) in [(_alice, 'Alice'), (_bob, 'Bob')]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    final media = CourseMediaStore(supportDirectory: () async => root);
    final verifier = fixtureVerifier(
      TrustedPublishers.dummy.publisherId,
      TrustedPublishers.dummy.publisherName,
    );
    editor = CourseEditorService(
      courseStore: CourseFileStore(supportDirectory: () async => root),
      mediaStore: media,
      backupService: CourseBackupService(
        backupsDirectoryProvider: () async => root,
        publisherVerification: verifier,
        mediaStore: media,
      ),
      publisherVerification: verifier,
      clock: () => DateTime.utc(2026, 10, 10, 9),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('received Courses', () {
    test(
      'any learner may delete one; an authored one keeps its rule',
      () async {
        // Bob, no admin and no author, received the friend's Course.
        await editor.installImportedCustomCourse(_course());
        expect(await editor.receivedCourses.mayRemove(_course()), isTrue);
        await editor.deleteUserCourse('friend-course');
        expect(await editor.listUserCourses(), isEmpty);

        // Alice's own Course is not received: only she may delete it.
        await profiles.setActiveProfileById(_alice);
        final own = _course(id: 'alice-course', maintainer: _alice);
        await editor.saveUserCourse(own);
        await profiles.setActiveProfileById(_bob);
        expect(await editor.receivedCourses.mayRemove(own), isFalse);
        await expectLater(
          editor.deleteUserCourse('alice-course'),
          throwsStateError,
        );
      },
    );

    test('Course Studio offers Delete for a received Course', () {
      final received = _course();
      CourseManagerEntry delete(CourseManagerLibrary library) => library
          .entriesFor(received)
          .singleWhere((entry) => entry.action == CourseManagerAction.delete);
      final library = CourseManagerLibrary(
        personalCourses: [received],
        activeProfileId: _bob,
      );
      expect(delete(library).available, isFalse);
      final removable = CourseManagerLibrary(
        personalCourses: [received],
        activeProfileId: _bob,
        removableReceivedIds: {received.courseId},
      );
      expect(delete(removable).available, isTrue);
    });
  });

  group('published Courses', () {
    test('a published Course has an ID of its own, the same at every '
        'export', () {
      const pattern =
          r'^course_[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';
      final id = PublisherCourseExport.publishedCourseId(
        'course_7c1d2b9e-4f3a-4b6c-8d2e-1a5f9e3c7b40',
        'org.example.publisher',
      );
      expect(id, matches(pattern));
      expect(id, isNot('course_7c1d2b9e-4f3a-4b6c-8d2e-1a5f9e3c7b40'));
      expect(
        PublisherCourseExport.publishedCourseId(
          ' course_7c1d2b9e-4f3a-4b6c-8d2e-1a5f9e3c7b40',
          'org.example.publisher ',
        ),
        id,
      );
      expect(
        PublisherCourseExport.publishedCourseId(
          'course_7c1d2b9e-4f3a-4b6c-8d2e-1a5f9e3c7b40',
          'org.other.publisher',
        ),
        isNot(id),
      );
    });

    test('an installed Publisher Course keeps its ID from custom Courses, '
        'even once removed', () async {
      final signed = Course.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
                File(
                  'test/fixtures/publishers/dummy-signed-v1.json',
                ).readAsStringSync(),
              )
              as Map,
        ),
      );
      // Alice, the admin, installs it and later removes it from the device.
      await profiles.setActiveProfileById(_alice);
      await editor.installExternalOfficialUpdate(signed);
      expect(await PublisherCourseIds().contains(signed.courseId), isTrue);
      await editor.removePublisherCourseFromDevice(signed);
      expect(await editor.listUserCourses(), isEmpty);
      await profiles.setActiveProfileById(_bob);
      await expectLater(
        editor.installImportedCustomCourse(_course(id: signed.courseId)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            CourseEditorService.publisherIdTakenMessage,
          ),
        ),
      );
    });
  });

  group('Access PIN wait', () {
    test('ten wrong PINs in a row make the PIN wait a minute', () async {
      var now = DateTime.utc(2026, 10, 10, 9);
      final pins = ProfileService(now: () => now);
      await pins.setOwnAccessPin(actorProfileId: _bob, pin: '1234');
      for (var i = 0; i < 9; i++) {
        expect(await pins.verifyAccessPin(_bob, '0000'), isFalse);
      }
      await expectLater(
        pins.verifyAccessPin(_bob, '0000'),
        throwsA(
          isA<ProfilePinException>().having(
            (error) => error.message,
            'message',
            contains('Wait 60 seconds'),
          ),
        ),
      );
      // Even the right PIN waits, and restarting QQL does not help.
      now = now.add(const Duration(seconds: 30));
      await expectLater(
        ProfileService(now: () => now).verifyAccessPin(_bob, '1234'),
        throwsA(
          isA<ProfilePinException>().having(
            (error) => error.message,
            'message',
            contains('Wait 30 seconds'),
          ),
        ),
      );
      now = now.add(const Duration(seconds: 31));
      expect(await pins.verifyAccessPin(_bob, '1234'), isTrue);

      // A right PIN starts the count again.
      for (var i = 0; i < 9; i++) {
        expect(await pins.verifyAccessPin(_bob, '0000'), isFalse);
      }
      expect(await pins.verifyAccessPin(_bob, '1234'), isTrue);
      for (var i = 0; i < 9; i++) {
        expect(await pins.verifyAccessPin(_bob, '0000'), isFalse);
      }
    });

    test('the admin PIN gate names the wait; backups never carry it', () async {
      final pins = ProfileService(now: () => DateTime.utc(2026, 10, 10, 9));
      await profiles.setActiveProfileById(_alice);
      await pins.setOwnAccessPin(actorProfileId: _alice, pin: '4321');
      for (var i = 0; i < 9; i++) {
        expect(
          await AdminPinGate(pins).problem(_alice, '0000', what: 'reset QQL'),
          'Incorrect PIN. Nothing was changed.',
        );
      }
      expect(
        await AdminPinGate(pins).problem(_alice, '0000', what: 'reset QQL'),
        contains('Too many wrong PINs'),
      );
      expect(
        ProfileService.isSensitiveCredentialPreferenceSuffix(
          ProfileService.accessPinLockKeyBase,
        ),
        isTrue,
      );
    });
  });

  group('a shared device', () {
    setUp(() => SharedDeviceNotice.enabled = true);
    tearDown(() => SharedDeviceNotice.enabled = false);

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => SharedDeviceNotice.showIfNeeded(context),
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
    }

    testWidgets('with two learners each learner is told once', (tester) async {
      Future<void> seesItOnce() async {
        await pump(tester);
        expect(find.byKey(const Key('shared-device-notice')), findsOneWidget);
        expect(find.textContaining('casual access'), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('shared-device-notice')), findsNothing);
      }

      // Bob, the active learner, then Alice.
      await seesItOnce();
      await tester.runAsync(() => profiles.setActiveProfileById(_alice));
      await seesItOnce();
    });

    testWidgets('one learner sees nothing', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await profiles.createProfile('Solo', generateScreenNameSuffix: false);
      await pump(tester);
      expect(find.byKey(const Key('shared-device-notice')), findsNothing);
    });
  });
}
