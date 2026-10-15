import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/access_pins.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 273 Revision 6: the Access PIN has an owner. `ProfileService`
/// keeps its public PIN methods and delegates; its own cases
/// (`qql_233_revision_profile_security_test`, `course_trust_270_test`,
/// `learner_separation_270_test`) pass before and after. These pin each
/// rule on the owner.
const _anna = '12345678-1234-4234-9234-123456789abc';
const _bob = '22345678-1234-4234-9234-123456789abc';

void main() {
  late DateTime now;
  late AccessPins pins;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 15, 12);
    pins = AccessPins(
      prefixFor: ProfileService.prefixForProfileId,
      now: () => now,
      secureBytes: (length) => List<int>.filled(length, 7),
    );
    AccessPins.beginSession();
  });

  tearDown(AccessPins.beginSession);

  Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  test('a PIN is four digits; only a verifier is stored', () async {
    for (final bad in ['123', '12345', 'abcd', '12 4']) {
      expect(
        () async => pins.write(await prefs(), _anna, bad),
        throwsArgumentError,
      );
    }
    expect(await pins.has(_anna), isFalse);
    await pins.write(await prefs(), _anna, '2468');
    expect(await pins.has(_anna), isTrue);
    expect(pins.hasIn(await prefs(), _anna), isTrue);
    final stored = (await prefs()).getString(
      '${ProfileService.prefixForProfileId(_anna)}${AccessPins.verifierKeyBase}',
    );
    // v1:<salt>:<digest>, the salt being the 16 bytes given (all 7 here).
    final salt = List<int>.filled(16, 7);
    expect(
      stored,
      'v1:${base64Url.encode(salt)}:'
      '${sha256.convert([...salt, ...utf8.encode('2468')])}',
    );
    expect(stored, isNot(contains('2468')));
    expect(await pins.has(_bob), isFalse);
  });

  test('a learner without a PIN is let in with anything', () async {
    expect(await pins.verify(_anna, ''), isTrue);
  });

  test('the right PIN, a wrong one', () async {
    await pins.write(await prefs(), _anna, '2468');
    expect(await pins.verify(_anna, '2468'), isTrue);
    expect(await pins.verify(_anna, '1357'), isFalse);
    expect(await pins.verify(_bob, '1357'), isTrue);
  });

  test('ten wrong PINs in a row lock it for a minute', () async {
    await pins.write(await prefs(), _anna, '2468');
    for (var i = 1; i < AccessPins.maxFailures; i++) {
      expect(await pins.verify(_anna, '0000'), isFalse);
    }
    await expectLater(
      pins.verify(_anna, '0000'),
      throwsA(
        isA<ProfilePinException>().having(
          (e) => e.message,
          'message',
          'Too many wrong PINs. Wait 60 seconds, then try again.',
        ),
      ),
    );
    // Even the right PIN waits.
    now = now.add(const Duration(seconds: 59, milliseconds: 500));
    await expectLater(
      pins.verify(_anna, '2468'),
      throwsA(
        isA<ProfilePinException>().having(
          (e) => e.message,
          'message',
          'Too many wrong PINs. Wait 1 second, then try again.',
        ),
      ),
    );
    // After the wait the count starts again.
    now = now.add(const Duration(seconds: 1));
    for (var i = 1; i < AccessPins.maxFailures; i++) {
      expect(await pins.verify(_anna, '0000'), isFalse);
    }
    expect(await pins.verify(_anna, '2468'), isTrue);
  });

  test('a right PIN clears the count', () async {
    await pins.write(await prefs(), _anna, '2468');
    for (var i = 1; i < AccessPins.maxFailures; i++) {
      expect(await pins.verify(_anna, '0000'), isFalse);
    }
    expect(await pins.verify(_anna, '2468'), isTrue);
    expect(
      (await prefs()).containsKey(
        '${ProfileService.prefixForProfileId(_anna)}${AccessPins.lockKeyBase}',
      ),
      isFalse,
    );
    for (var i = 1; i < AccessPins.maxFailures; i++) {
      expect(await pins.verify(_anna, '0000'), isFalse);
    }
  });

  test('a removed PIN is no PIN', () async {
    await pins.write(await prefs(), _anna, '2468');
    await pins.remove(_anna);
    expect(await pins.has(_anna), isFalse);
    expect(await pins.verify(_anna, ''), isTrue);
  });

  test('the session: only the learner unlocked last, or added', () {
    expect(AccessPins.isUnlocked(_anna), isFalse);
    AccessPins.unlockOnly(_anna);
    expect(AccessPins.isUnlocked(_anna), isTrue);
    AccessPins.unlock(_bob);
    expect(AccessPins.isUnlocked(_bob), isTrue);
    AccessPins.unlockOnly(_bob);
    expect(AccessPins.isUnlocked(_anna), isFalse);
    AccessPins.lock(_bob);
    expect(AccessPins.isUnlocked(_bob), isFalse);
    AccessPins.unlock(_anna);
    ProfileService.beginAccessSession();
    expect(AccessPins.isUnlocked(_anna), isFalse);
  });

  test('ProfileService keeps its names for the wait and the keys', () {
    expect(ProfileService.maxAccessPinFailures, 10);
    expect(ProfileService.accessPinLockDuration, const Duration(minutes: 1));
    expect(ProfileService.accessPinLockKeyBase, 'access_pin_lock_v1');
    expect(ProfileService.sensitiveCredentialPreferenceSuffixes, [
      'access_pin_verifier_v1',
      ProfileService.recoveryCredentialKeyBase,
      'access_pin_lock_v1',
    ]);
  });
}
