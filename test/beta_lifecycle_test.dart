import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/beta_lifecycle_service.dart';

void main() {
  test('QQL 236 refreshes Beta expiry and includes the expiry day', () {
    expect(BetaLifecycleService.expiryIsoDate, '2026-10-16');
    expect(BetaLifecycleService.daysRemaining(DateTime(2026, 9, 16)), 30);
    expect(BetaLifecycleService.isExpired(DateTime(2026, 10, 16, 12)), isFalse);
    expect(
      BetaLifecycleService.isExpired(DateTime(2026, 10, 16, 23, 59, 59)),
      isFalse,
    );
    expect(BetaLifecycleService.isExpired(DateTime(2026, 10, 17)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 9)), 7);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 13)), 3);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 15)), 1);
    expect(BetaLifecycleService.warningStage(DateTime(2026, 10, 16)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 8)),
      null,
    ); // 8 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 10)),
      7,
    ); // 6 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 11)),
      7,
    ); // 5 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 12)),
      7,
    ); // 4 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 14)),
      3,
    ); // 2 days
    expect(
      BetaLifecycleService.warningStage(DateTime(2026, 10, 17)),
      null,
    ); // expired
  });
}
