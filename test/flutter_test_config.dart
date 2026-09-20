import 'dart:async';

import 'package:quisquislingo_app/services/beta_lifecycle_service.dart';

/// Runs once per test file, before its `main()`.
///
/// Learner screens ask [BetaLifecycleService] whether the Beta has expired
/// without passing a date, so Home, Round, Duel and Review would all render
/// `BetaExpiredView` once the real clock passed the expiry — turning the whole
/// suite red on a fixed calendar day. Pinning the clock relative to the expiry
/// keeps the suite deterministic and survives every expiry refresh, so this
/// file needs no maintenance when the Beta lifetime moves.
///
/// Fifteen days before expiry is deliberately outside every warning milestone
/// (7 / 3 / 1 / 0 days), so tests see the ordinary, unwarned learner state.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BetaLifecycleService.clock = () =>
      BetaLifecycleService.expiryDate.subtract(const Duration(days: 15));
  await testMain();
}
