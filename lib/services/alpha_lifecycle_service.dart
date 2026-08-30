/// Lifecycle policy for time-limited pre-release builds.
///
/// This is intentionally a transparent alpha-expiry mechanism rather than DRM.
/// It trusts the device clock, never deletes local data, and can be disabled in
/// a future stable build by setting [isAlphaBuild] to false.
class AlphaLifecycleService {
  static const bool isAlphaBuild = true;
  // Thirty days from the 2026-08-29 build 216 release date.
  static final DateTime expiryDate = DateTime(2026, 9, 28, 23, 59, 59);

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isExpired([DateTime? now]) {
    if (!isAlphaBuild) return false;
    final value = now ?? DateTime.now();
    return value.isAfter(expiryDate);
  }

  static int daysRemaining([DateTime? now]) {
    if (!isAlphaBuild) return 1 << 20;
    final value = _day(now ?? DateTime.now());
    final expiry = _day(expiryDate);
    return expiry.difference(value).inDays;
  }

  /// Warning stages are one-time UI milestones. If the app was not opened on
  /// the exact milestone day, the next stricter stage is used instead.
  static int? warningStage([DateTime? now]) {
    if (!isAlphaBuild || isExpired(now)) return null;
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
