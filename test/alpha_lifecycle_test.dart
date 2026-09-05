import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test('build 226.01 alpha expiry is inclusive through the expiry day', () {
    expect(AlphaLifecycleService.expiryIsoDate, '2026-10-05');
    expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 9, 5)), 30);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 5, 12)), isFalse);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 6)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 28)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 2)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 4)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 5)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 27)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 29)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 30)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 1)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 3)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 6)),
      null,
    ); // expired
  });
}
