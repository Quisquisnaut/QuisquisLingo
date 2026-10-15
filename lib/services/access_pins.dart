import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A learner's Access PIN (Build 273 Revision 6; the rules of Build 233,
/// Build 270 Revisions 1 and 8): its stored verifier, the wait after too
/// many wrong PINs, and which learners are unlocked in this run of QQL.
///
/// The PIN prevents mistakes and casual access on a shared device; it is not
/// a security boundary between learners (owner's view). The verifier is a
/// salted SHA-256 of the four digits; the PIN itself is never stored.
///
/// `ProfileService` keeps its public PIN methods and delegates here; the
/// learner key namespace is its own, given as [prefixFor].
class AccessPins {
  AccessPins({
    required String Function(String learnerProfileId) prefixFor,
    required DateTime Function() now,
    required List<int> Function(int length) secureBytes,
  }) : _prefixFor = prefixFor,
       _now = now,
       _secureBytes = secureBytes;

  /// The learner key of the verifier (`v1:<salt>:<digest>`).
  static const verifierKeyBase = 'access_pin_verifier_v1';

  /// Build 270 Revision 8 (owner request of 10 October 2026): after this
  /// many wrong Access PINs in a row, a learner's PIN is not checked for
  /// [lockDuration], so trying every code by hand stops being easy. The
  /// count is kept per learner (under their prefix), so restarting QQL does
  /// not skip the wait; a right PIN clears it, and so does removing the PIN
  /// or setting one where there was none (Build 273 Revision 7, owner
  /// decision: a new PIN starts afresh). Like the PIN itself, it
  /// prevents casual access, not a determined person with the device's
  /// files.
  static const maxFailures = 10;
  static const lockDuration = Duration(minutes: 1);
  static const lockKeyBase = 'access_pin_lock_v1';

  static final Set<String> _unlocked = <String>{};

  final String Function(String learnerProfileId) _prefixFor;
  final DateTime Function() _now;
  final List<int> Function(int length) _secureBytes;

  // The session below is called by `ProfileService` only (and tests): it
  // unlocks a learner after their PIN was checked, or when no PIN applies.

  /// A new run of QQL (or a reset): nobody is unlocked.
  static void beginSession() => _unlocked.clear();

  /// Build 270 Revision 1: only the active learner is unlocked. A learner
  /// left with a switch must give their Access PIN again, so nothing that
  /// sets the active learner afterwards (a restore) can bring them back
  /// without it.
  static void unlockOnly(String learnerProfileId) => _unlocked
    ..clear()
    ..add(learnerProfileId);

  /// [learnerProfileId] gave their PIN (or set it) in this run.
  static void unlock(String learnerProfileId) =>
      _unlocked.add(learnerProfileId);

  /// [learnerProfileId] must give their PIN again.
  static void lock(String learnerProfileId) =>
      _unlocked.remove(learnerProfileId);

  /// [learnerProfileId] gave their PIN in this run.
  static bool isUnlocked(String learnerProfileId) =>
      _unlocked.contains(learnerProfileId);

  String _key(String learnerProfileId, String base) =>
      '${_prefixFor(learnerProfileId)}$base';

  /// Whether [learnerProfileId] has an Access PIN, read from [prefs].
  bool hasIn(SharedPreferences prefs, String learnerProfileId) =>
      prefs.containsKey(_key(learnerProfileId, verifierKeyBase));

  /// Whether [learnerProfileId] has an Access PIN.
  Future<bool> has(String learnerProfileId) async =>
      hasIn(await SharedPreferences.getInstance(), learnerProfileId);

  /// Whether [pin] is [learnerProfileId]'s Access PIN (true for a learner
  /// without one). Throws a [ProfilePinException] while too many wrong
  /// PINs keep it locked ([maxFailures]), and when the wrong PIN that locks
  /// it is given.
  Future<bool> verify(String learnerProfileId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key(learnerProfileId, verifierKeyBase));
    if (value == null) return true;
    final lockKey = _key(learnerProfileId, lockKeyBase);
    final lock = _AccessPinLock.decode(prefs.getString(lockKey));
    final now = _now().toUtc();
    final lockedUntil = lock.lockedUntil;
    if (lockedUntil != null && now.isBefore(lockedUntil)) {
      throw ProfilePinException(lockedMessage(lockedUntil.difference(now)));
    }
    final parts = value.split(':');
    final right =
        parts.length == 3 &&
        parts.first == 'v1' &&
        sha256.convert([
              ...base64Url.decode(base64Url.normalize(parts[1])),
              ...utf8.encode(pin),
            ]).toString() ==
            parts[2];
    if (right) {
      if (prefs.containsKey(lockKey)) await prefs.remove(lockKey);
      return true;
    }
    // A wait that has passed starts the count again.
    final failures = (lockedUntil == null ? lock.failures : 0) + 1;
    if (failures >= maxFailures) {
      await prefs.setString(
        lockKey,
        _AccessPinLock(
          failures: 0,
          lockedUntil: now.add(lockDuration),
        ).encode(),
      );
      throw ProfilePinException(lockedMessage(lockDuration));
    }
    await prefs.setString(lockKey, _AccessPinLock(failures: failures).encode());
    return false;
  }

  /// What a learner reads while their PIN is locked for [wait] ("1 second"
  /// in its last second: Build 273 Revision 7, owner decision).
  static String lockedMessage(Duration wait) {
    final seconds = (wait.inMicroseconds / Duration.microsecondsPerSecond)
        .ceil();
    return 'Too many wrong PINs. Wait $seconds second${seconds == 1 ? '' : 's'}, '
        'then try again.';
  }

  /// Stores [pin] (exactly four digits) as [learnerProfileId]'s Access PIN.
  /// A learner who had no PIN starts afresh: a count of wrong PINs left by a
  /// PIN removed before Build 273 Revision 7 is cleared. A PIN changed for
  /// another keeps the count.
  Future<void> write(
    SharedPreferences prefs,
    String learnerProfileId,
    String pin,
  ) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError.value(
        pin,
        'pin',
        'Access PIN must contain exactly 4 digits.',
      );
    }
    final salt = _secureBytes(16);
    final encodedSalt = base64Url.encode(salt);
    final digest = sha256.convert([...salt, ...utf8.encode(pin)]).toString();
    if (!hasIn(prefs, learnerProfileId)) {
      await prefs.remove(_key(learnerProfileId, lockKeyBase));
    }
    await prefs.setString(
      _key(learnerProfileId, verifierKeyBase),
      'v1:$encodedSalt:$digest',
    );
  }

  /// [learnerProfileId] no longer has an Access PIN; its count of wrong
  /// PINs and any wait go with it, so a new PIN starts afresh (Build 273
  /// Revision 7, owner decision: an admin's reset and the learner's own
  /// removal alike).
  Future<void> remove(String learnerProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    // The count first: stopped in between, no count is left without a PIN.
    await prefs.remove(_key(learnerProfileId, lockKeyBase));
    await prefs.remove(_key(learnerProfileId, verifierKeyBase));
  }
}

/// A learner's Access PIN was refused: wrong, or locked after too many
/// wrong ones (the message says how long to wait).
class ProfilePinException implements Exception {
  final String message;

  const ProfilePinException(this.message);

  @override
  String toString() => message;
}

/// The wrong Access PINs given in a row, and the end of the wait they
/// started (Build 270 Revision 8).
class _AccessPinLock {
  const _AccessPinLock({this.failures = 0, this.lockedUntil});

  final int failures;
  final DateTime? lockedUntil;

  static _AccessPinLock decode(String? raw) {
    if (raw == null) return const _AccessPinLock();
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return const _AccessPinLock();
      final failures = json['failures'];
      final until = json['lockedUntil'];
      return _AccessPinLock(
        failures: failures is int && failures > 0 ? failures : 0,
        lockedUntil: until is String ? DateTime.tryParse(until)?.toUtc() : null,
      );
    } catch (_) {
      return const _AccessPinLock();
    }
  }

  String encode() => jsonEncode({
    'failures': failures,
    if (lockedUntil != null) 'lockedUntil': lockedUntil!.toIso8601String(),
  });
}
