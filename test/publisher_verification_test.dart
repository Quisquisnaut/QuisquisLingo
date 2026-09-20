import 'package:cryptography/cryptography.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_file_dialog_backend.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:quisquislingo_app/services/publisher_verification_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';
import 'support/publisher_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final verifier = fixtureVerifier(
    TrustedPublishers.dummy.publisherId,
    TrustedPublishers.dummy.publisherName,
  );
  Course fixture() => Course.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(
        File(
          'test/fixtures/publishers/dummy-signed-v1.json',
        ).readAsStringSync(),
      ),
    ),
  );
  Course mutate(Course course, Map<String, Object?> changes) =>
      Course.fromJson({...course.toJson(), ...changes});

  test(
    'OpenSSL fixture verifies, declared status is ignored, JSON order is irrelevant',
    () async {
      final original = fixture();
      final verified = await verifier.requireVerified(original);
      expect(
        verified.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      final reversed = Map<String, dynamic>.fromEntries(
        original.toJson().entries.toList().reversed,
      );
      expect(
        (await verifier.requireVerified(
          Course.fromJson(reversed),
        )).publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      expect(
        (await PublisherVerificationService().assessStored(
          verified,
        )).publisherVerificationStatus,
        TrustedPublishers.dummyEnabled
            ? PublisherVerificationStatus.verified
            : PublisherVerificationStatus.unverified,
      );
    },
  );

  test(
    'normal registry excludes Dummy unless explicitly configured as a test build',
    () {
      expect(
        TrustedPublishers.application().find(
              TrustedPublishers.dummy.publisherId,
              'dummy-1',
            ) !=
            null,
        TrustedPublishers.dummyEnabled,
      );
      expect(
        TrustedPublishers(
          [],
        ).find(TrustedPublishers.dummy.publisherId, 'dummy-1'),
        isNull,
      );
    },
  );

  test(
    'tampering still fails after an attacker recalculates the checksum',
    () async {
      final changed = mutate(fixture(), {'title': 'Tampered title'});
      final recalculated = mutate(changed, {
        'officialChecksum': CourseBackupService.officialContentChecksum(
          changed,
        ),
      });
      await expectLater(
        verifier.requireVerified(recalculated),
        throwsFormatException,
      );
    },
  );

  test(
    'missing, malformed, unknown and revoked signatures fail closed',
    () async {
      final source = fixture();
      for (final signature in [
        '',
        'bad',
        'qql-ed25519-v2:dummy-1:AA==',
        'qql-ed25519-v1:dummy-1:%%%',
        'qql-ed25519-v1:dummy-1:AA==',
        source.publisherSignature.replaceFirst('dummy-1', 'unknown'),
        '${source.publisherSignature}:extra',
      ]) {
        await expectLater(
          verifier.requireVerified(
            mutate(source, {
              'publisherSignature': signature,
              'publisherVerificationStatus': 'verified',
            }),
          ),
          throwsFormatException,
        );
      }
      await expectLater(
        fixtureVerifier(
          source.publisherId,
          source.publisherName,
          revoked: true,
        ).requireVerified(source),
        throwsFormatException,
      );
      await expectLater(
        PublisherVerificationService(
          publishers: TrustedPublishers([]),
        ).requireVerified(source),
        throwsFormatException,
      );
      await expectLater(
        verifier.requireVerified(
          await signFixture(
            mutate(source, {'publisherName': 'Impersonated name'}),
          ),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'transfer validator checks signatures and blocks imported bundled origins',
    () async {
      final transfer = CustomCourseTransferService(
        publisherVerification: verifier,
      );
      final source = fixture();
      Uint8List bytes(Course value) =>
          Uint8List.fromList(utf8.encode(jsonEncode(value.toJson())));
      final valid = await transfer.courseFromBytes(
        bytes(source),
        'signed.json',
      );
      expect(
        valid.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      await expectLater(
        transfer.courseFromBytes(
          bytes(mutate(source, {'publisherSignature': ''})),
          'unsigned.json',
        ),
        throwsFormatException,
      );
      await expectLater(
        transfer.courseFromBytes(
          bytes(await CourseService().loadBundledCourse('IT')),
          'bundled.json',
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'folder and native dialog imports share signature checks and preserve input',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'qql-signature-transfer-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final backend = FakeFileDialogBackend();
      final transfer = CustomCourseTransferService(
        importDirectory: () async => directory,
        fileDialogs: FileDialogService(backend: backend),
        publisherVerification: verifier,
      );
      for (final valid in [true, false]) {
        final source = valid
            ? fixture()
            : mutate(fixture(), {'publisherSignature': ''});
        final bytes = Uint8List.fromList(
          utf8.encode(jsonEncode(source.toJson())),
        );
        final file = File('${directory.path}/import.json');
        await file.writeAsBytes(bytes);
        backend.onOpen = () async =>
            FileDialogResult.opened('import.json', bytes);
        if (valid) {
          expect(
            (await transfer.importCourseFromDialog()).course!.toJson(),
            (await transfer.importCourse()).toJson(),
          );
        } else {
          await expectLater(transfer.importCourse(), throwsFormatException);
          await expectLater(
            transfer.importCourseFromDialog(),
            throwsFormatException,
          );
        }
        expect(await file.readAsBytes(), bytes);
      }
    },
  );

  test(
    'signed updates persist, archive and reject downgrade without changing files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'qql-signatures-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final backups = CourseBackupService(
        documentsDirectoryProvider: () async => directory,
        publisherVerification: verifier,
      );
      final service = CourseEditorService(
        publisherVerification: verifier,
        backupService: backups,
      );
      final first = await service.installExternalOfficialUpdate(fixture());
      final second = await signFixture(
        mutate(fixture(), {
          'officialCourseVersion': '2',
          'title': 'Dummy version two',
        }),
      );
      final installed = await service.installExternalOfficialUpdate(second);
      expect(installed.backupPath, isNotNull);
      expect(
        (await backups.listOfficialBackups(
          second.courseId,
        )).single.course.toJson(),
        first.officialCourse.toJson(),
      );
      final snapshot = jsonEncode(
        await CourseFileStore().readAll(CourseStoreKind.externalOfficial),
      );
      await expectLater(
        service.installExternalOfficialUpdate(fixture()),
        throwsFormatException,
      );
      final impostor = await signFixture(
        mutate(second, {
          'officialCourseVersion': '3',
          'publisherId': 'other.publisher',
          'originalCourseCreator': {
            'type': 'publisher',
            'id': 'other.publisher',
            'displayName': second.publisherName,
          },
        }),
      );
      final otherVerifier = fixtureVerifier(
        'other.publisher',
        second.publisherName,
      );
      await expectLater(
        CourseEditorService(
          publisherVerification: otherVerifier,
          backupService: backups,
        ).installExternalOfficialUpdate(
          impostor,
          confirmUnverifiedAssociation: true,
        ),
        throwsFormatException,
      );
      expect(
        jsonEncode(
          await CourseFileStore().readAll(CourseStoreKind.externalOfficial),
        ),
        snapshot,
      );
    },
  );

  test(
    'explicit key rotation accepts the new key and revoked old keys fail',
    () async {
      final source = fixture();
      final pair = await Ed25519().newKeyPairFromSeed(List.filled(32, 42));
      final publicKey = await pair.extractPublicKey();
      final newKey = TrustedPublisherKey(
        publisherId: source.publisherId,
        publisherName: source.publisherName,
        keyId: 'rotated-2',
        publicKeyBase64: base64Encode(publicKey.bytes),
      );
      final draft = mutate(source, {'officialCourseVersion': '2'});
      final normalized = mutate(draft, {
        'officialChecksum': CourseBackupService.officialContentChecksum(draft),
      });
      final signature = await Ed25519().sign(
        PublisherVerificationService.signingBytes(normalized, 'rotated-2'),
        keyPair: pair,
      );
      final rotated = mutate(normalized, {
        'publisherSignature':
            'qql-ed25519-v1:rotated-2:${base64Encode(signature.bytes)}',
      });
      final rotationVerifier = PublisherVerificationService(
        publishers: TrustedPublishers([TrustedPublishers.dummy, newKey]),
      );
      final directory = await Directory.systemTemp.createTemp(
        'qql-key-rotation-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final editor = CourseEditorService(
        publisherVerification: rotationVerifier,
        backupService: CourseBackupService(
          documentsDirectoryProvider: () async => directory,
          publisherVerification: rotationVerifier,
        ),
      );
      await editor.installExternalOfficialUpdate(source);
      expect(
        (await editor.installExternalOfficialUpdate(
          rotated,
        )).officialCourse.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      final afterRevocation = PublisherVerificationService(
        publishers: TrustedPublishers([
          TrustedPublisherKey(
            publisherId: source.publisherId,
            publisherName: source.publisherName,
            keyId: 'dummy-1',
            publicKeyBase64: TrustedPublishers.dummy.publicKeyBase64,
            revoked: true,
          ),
          newKey,
        ]),
      );
      await expectLater(
        afterRevocation.requireVerified(source),
        throwsFormatException,
      );
      expect(
        (await afterRevocation.requireVerified(
          rotated,
        )).publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
    },
  );

  test(
    'legacy courses are preserved and explicit association reactivates them',
    () async {
      final source = fixture();
      SharedPreferences.setMockInitialValues({
        'v4_completed_rounds': ['existing-round'],
        'weekly_xp': 120,
      });
      final legacy = mutate(source, {
        'publisherSignature': '',
        'publisherVerificationStatus': 'verified',
      });
      final store = CourseFileStore();
      await store.write(CourseStoreKind.externalOfficial, source.courseId, {
        'source': legacy.toJson(),
      });
      final before = jsonEncode(
        await store.readAll(CourseStoreKind.externalOfficial),
      );
      final directory = await Directory.systemTemp.createTemp(
        'qql-legacy-signature-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final service = CourseEditorService(
        publisherVerification: verifier,
        backupService: CourseBackupService(
          documentsDirectoryProvider: () async => directory,
          publisherVerification: verifier,
        ),
      );
      final read = (await service.listUserCourses()).single;
      expect(
        read.publisherVerificationStatus,
        PublisherVerificationStatus.unverified,
      );
      expect(const PublicationService().learnerCourse(read), isNull);
      expect(
        jsonEncode(await store.readAll(CourseStoreKind.externalOfficial)),
        before,
      );
      final next = await signFixture(
        mutate(source, {'officialCourseVersion': '2'}),
      );
      await expectLater(
        service.installExternalOfficialUpdate(next),
        throwsFormatException,
      );
      expect(
        jsonEncode(await store.readAll(CourseStoreKind.externalOfficial)),
        before,
      );
      await service.installExternalOfficialUpdate(
        next,
        confirmUnverifiedAssociation: true,
      );
      expect(
        const PublicationService().learnerCourse(
          (await service.listUserCourses()).single,
        ),
        isNotNull,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('v4_completed_rounds'), ['existing-round']);
      expect(prefs.getInt('weekly_xp'), 120);
      final revoked = CourseEditorService(
        publisherVerification: fixtureVerifier(
          source.publisherId,
          source.publisherName,
          revoked: true,
        ),
      );
      expect(
        (await revoked.listUserCourses()).single.publisherVerificationStatus,
        PublisherVerificationStatus.unverified,
      );
    },
  );

  test(
    'unsigned external official cannot be installed even if it claims verified',
    () async {
      final source = await CourseService().loadBundledCourse('IT');
      final candidate = Course.fromJson({
        ...source.toJson(),
        'courseId': 'publisher_signature_unsigned',
        'originType': 'externalOfficial',
        'publisherVerificationStatus': 'verified',
        'publisherSignature': '',
      });
      final course = Course.fromJson({
        ...candidate.toJson(),
        'officialChecksum': CourseBackupService.officialContentChecksum(
          candidate,
        ),
      });
      await expectLater(
        CourseEditorService().installExternalOfficialUpdate(course),
        throwsA(isA<FormatException>()),
      );
    },
  );
}
