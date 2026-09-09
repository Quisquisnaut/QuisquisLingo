import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test('build 229 refreshes the Alpha expiry and includes the expiry day', () {
    expect(AlphaLifecycleService.expiryIsoDate, '2026-10-09');
    expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 9, 9)), 30);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 9, 12)), isFalse);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 10)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 2)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 6)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 8)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 9)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 1)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 3)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 4)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 5)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 7)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 10)),
      null,
    ); // expired
  });
}
