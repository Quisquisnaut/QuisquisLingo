import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test('phase 233.3 refreshes Alpha expiry and includes the expiry day', () {
    expect(AlphaLifecycleService.expiryIsoDate, '2026-10-14');
    expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 9, 14)), 30);
    expect(
      AlphaLifecycleService.isExpired(DateTime(2026, 10, 14, 12)),
      isFalse,
    );
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 15)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 7)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 11)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 13)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 14)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 6)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 8)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 9)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 10)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 12)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 15)),
      null,
    ); // expired
  });
}
