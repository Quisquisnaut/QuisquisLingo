import 'package:flutter/foundation.dart';

/// Lifecycle policy for time-limited beta builds.
///
/// This is intentionally a transparent beta-expiry mechanism rather than DRM.
/// It trusts the device clock, never deletes local data, and can be disabled in
/// a future stable build by setting [isBetaBuild] to false.
class BetaLifecycleService {
  static const bool isBetaBuild = true;
  // Build 255 Revision 1: 30 local calendar days from the 25 September 2026
  // release date, ending on 25 October 2026 at 23:59:59 local time.
  static final DateTime expiryDate = DateTime(2026, 10, 25, 23, 59, 59);

  /// The clock the no-argument lifecycle checks read.
  ///
  /// Learner screens call [isExpired] and [daysRemaining] without an argument,
  /// so without this seam every widget test would silently start failing once
  /// the real date passed [expiryDate]. `test/flutter_test_config.dart` pins it
  /// relative to [expiryDate] for the whole suite; production keeps the local
  /// device clock.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isExpired([DateTime? now]) {
    if (!isBetaBuild) return false;
    final value = now ?? clock();
    return value.isAfter(expiryDate);
  }

  static int daysRemaining([DateTime? now]) {
    if (!isBetaBuild) return 1 << 20;
    final value = _day(now ?? clock());
    final expiry = _day(expiryDate);
    return expiry.difference(value).inDays;
  }

  /// Warning stages are one-time UI milestones. If the app was not opened on
  /// the exact milestone day, the next stricter stage is used instead.
  static int? warningStage([DateTime? now]) {
    if (!isBetaBuild || isExpired(now)) return null;
    final days = daysRemaining(now);
    if (days <= 0) return 0;
    if (days <= 1) return 1;
    if (days <= 3) return 3;
    if (days <= 7) return 7;
    return null;
  }

  static String get expiryIsoDate =>
      '${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
}
