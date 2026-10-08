import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/beta_lifecycle_service.dart';

void main() {
  test(
    'QQL 267 Revision 0 expires on 7 November and includes the expiry day',
    () {
      expect(BetaLifecycleService.expiryIsoDate, '2026-11-07');
      expect(BetaLifecycleService.daysRemaining(DateTime(2026, 10, 8)), 30);
      expect(
        BetaLifecycleService.isExpired(DateTime(2026, 11, 7, 12)),
        isFalse,
      );
      expect(
        BetaLifecycleService.isExpired(DateTime(2026, 11, 7, 23, 59, 59)),
        isFalse,
      );
      expect(BetaLifecycleService.isExpired(DateTime(2026, 11, 8)), isTrue);
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

    BetaLifecycleService.clock = () => DateTime(2026, 11, 8);
    expect(BetaLifecycleService.isExpired(), isTrue);

    BetaLifecycleService.clock = () => DateTime(2026, 11, 6);
    expect(BetaLifecycleService.isExpired(), isFalse);
    expect(BetaLifecycleService.daysRemaining(), 1);
    expect(BetaLifecycleService.warningStage(), 1);
  });

  test('warning milestones are stable', () {
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 31)), 7);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 11, 4)), 3);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 11, 6)), 1);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 11, 7)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 30)),
      null,
    ); // 8 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 11, 1)),
      7,
    ); // 6 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 11, 2)),
      7,
    ); // 5 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 11, 3)),
      7,
    ); // 4 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 11, 5)),
      3,
    ); // 2 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 11, 8)),
      null,
    ); // expired
  });
}
