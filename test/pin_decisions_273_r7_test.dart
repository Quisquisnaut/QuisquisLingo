import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/access_pins.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 273 Revision 7: the owner's decisions of 15 October 2026 on the two
/// findings of Revision 6.
/// 1. Removing an Access PIN, by an admin's reset or by the learner, also
///    clears its count of wrong PINs and a wait in progress.
/// 2. The wait message says "1 second" in its last second.
const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

void main() {
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProfileService.beginAccessSession();
    now = DateTime.utc(2026, 10, 15, 18);
    final profiles = ProfileService();
    // Alice is created first and so is the admin.
    for (final (id, name) in [(_alice, 'Alice'), (_bob, 'Bob')]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
  });

  tearDown(ProfileService.beginAccessSession);

  test('the wait says one second, or several', () {
    expect(
      AccessPins.lockedMessage(const Duration(milliseconds: 300)),
      'Too many wrong PINs. Wait 1 second, then try again.',
    );
    expect(
      AccessPins.lockedMessage(const Duration(seconds: 1)),
      'Too many wrong PINs. Wait 1 second, then try again.',
    );
    expect(
      AccessPins.lockedMessage(const Duration(milliseconds: 1001)),
      'Too many wrong PINs. Wait 2 seconds, then try again.',
    );
    expect(
      AccessPins.lockedMessage(const Duration(minutes: 1)),
      'Too many wrong PINs. Wait 60 seconds, then try again.',
    );
    // Less than a millisecond left is still a second to wait, not zero.
    expect(
      AccessPins.lockedMessage(const Duration(microseconds: 400)),
      'Too many wrong PINs. Wait 1 second, then try again.',
    );
  });

  Future<void> nineWrong(ProfileService pins) async {
    for (var i = 1; i < ProfileService.maxAccessPinFailures; i++) {
      expect(await pins.verifyAccessPin(_bob, '0000'), isFalse);
    }
  }

  test('an admin\'s reset clears the count: a new PIN starts afresh', () async {
    final pins = ProfileService(now: () => now);
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '1234');
    await nineWrong(pins);
    await pins.resetAccessPinAsAdmin(
      actorProfileId: _alice,
      targetProfileId: _bob,
    );
    expect(await pins.hasAccessPin(_bob), isFalse);
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '5678');
    // Nine more wrong PINs are still allowed before the wait.
    await nineWrong(pins);
    await expectLater(
      pins.verifyAccessPin(_bob, '0000'),
      throwsA(isA<ProfilePinException>()),
    );
  });

  test('an admin\'s reset ends a wait in progress', () async {
    final pins = ProfileService(now: () => now);
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '1234');
    await nineWrong(pins);
    await expectLater(
      pins.verifyAccessPin(_bob, '0000'),
      throwsA(isA<ProfilePinException>()),
    );
    await pins.resetAccessPinAsAdmin(
      actorProfileId: _alice,
      targetProfileId: _bob,
    );
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '5678');
    // Within the minute the old wait would have refused even this.
    now = now.add(const Duration(seconds: 10));
    expect(await pins.verifyAccessPin(_bob, '5678'), isTrue);
  });

  test('the learner removing their own PIN clears it too', () async {
    final pins = ProfileService(now: () => now);
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '1234');
    await nineWrong(pins);
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: null);
    expect(await pins.hasAccessPin(_bob), isFalse);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        '${ProfileService.prefixForProfileId(_bob)}'
        '${ProfileService.accessPinLockKeyBase}',
      ),
      isFalse,
    );
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '5678');
    await nineWrong(pins);
    expect(await pins.verifyAccessPin(_bob, '5678'), isTrue);
  });

  test('a count left by a PIN removed before Revision 7 does not reach a new '
      'PIN', () async {
    final prefs = await SharedPreferences.getInstance();
    final lockKey =
        '${ProfileService.prefixForProfileId(_bob)}'
        '${ProfileService.accessPinLockKeyBase}';
    // What an earlier version left: no PIN, a wait still running.
    await prefs.setString(
      lockKey,
      '{"failures":0,"lockedUntil":"${now.add(const Duration(seconds: 40)).toIso8601String()}"}',
    );
    final pins = ProfileService(now: () => now);
    expect(await pins.hasAccessPin(_bob), isFalse);
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '5678');
    expect(prefs.containsKey(lockKey), isFalse);
    expect(await pins.verifyAccessPin(_bob, '5678'), isTrue);
  });

  test('changing a PIN for another keeps the count, as before', () async {
    final pins = ProfileService(now: () => now);
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '1234');
    await nineWrong(pins);
    await pins.setOwnAccessPin(actorProfileId: _bob, pin: '5678');
    await expectLater(
      pins.verifyAccessPin(_bob, '0000'),
      throwsA(isA<ProfilePinException>()),
    );
  });
}
