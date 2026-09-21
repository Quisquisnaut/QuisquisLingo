import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/beta_lifecycle_service.dart';

void main() {
  test(
    'QQL 244 Revision 5 recalculates the Beta expiry and includes the expiry day',
    () {
      expect(BetaLifecycleService.expiryIsoDate, '2026-10-22');
      expect(BetaLifecycleService.daysRemaining(DateTime(2026, 9, 22)), 30);
      expect(
        BetaLifecycleService.isExpired(DateTime(2026, 10, 22, 12)),
        isFalse,
      );
      expect(
        BetaLifecycleService.isExpired(DateTime(2026, 10, 22, 23, 59, 59)),
        isFalse,
      );
      expect(BetaLifecycleService.isExpired(DateTime(2026, 10, 23)), isTrue);
    },
  );

  test('no-argument lifecycle checks follow the injectable clock', () {
    final pinned = BetaLifecycleService.clock;
    addTearDown(() => BetaLifecycleService.clock = pinned);

    // The suite-wide pin in test/flutter_test_config.dart must always leave the
    // Beta unexpired and unwarned, otherwise learner screens across the suite
    // would render BetaExpiredView instead of the screen under test.
    expect(BetaLifecycleService.isExpired(), isFalse);
    expect(BetaLifecycleService.warningStage(), isNull);
    expect(BetaLifecycleService.daysRemaining(), 15);

    BetaLifecycleService.clock = () => DateTime(2026, 10, 23);
    expect(BetaLifecycleService.isExpired(), isTrue);

    BetaLifecycleService.clock = () => DateTime(2026, 10, 21);
    expect(BetaLifecycleService.isExpired(), isFalse);
    expect(BetaLifecycleService.daysRemaining(), 1);
    expect(BetaLifecycleService.warningStage(), 1);
  });

  test('warning milestones are stable', () {
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 15)), 7);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 19)), 3);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 21)), 1);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 22)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 14)),
      null,
    ); // 8 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 16)),
      7,
    ); // 6 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 17)),
      7,
    ); // 5 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 18)),
      7,
    ); // 4 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 20)),
      3,
    ); // 2 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 23)),
      null,
    ); // expired
  });
}
