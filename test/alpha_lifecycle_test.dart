import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test('QQL 234.2 refreshes Alpha expiry and includes the expiry day', () {
    expect(AlphaLifecycleService.expiryIsoDate, '2026-10-15');
    expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 9, 15)), 30);
    expect(
      AlphaLifecycleService.isExpired(DateTime(2026, 10, 15, 12)),
      isFalse,
    );
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 16)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 8)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 12)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 14)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 15)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 7)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 9)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 10)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 11)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 13)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 16)),
      null,
    ); // expired
  });
}
