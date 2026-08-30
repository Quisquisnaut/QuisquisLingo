import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test('build 216 alpha expiry is inclusive through the expiry day', () {
    expect(AlphaLifecycleService.expiryIsoDate, '2026-09-28');
    expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 8, 29)), 30);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 9, 28, 12)), isFalse);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 9, 29)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 21)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 25)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 27)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 28)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 20)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 22)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 23)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 24)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 26)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 29)),
      null,
    ); // expired
  });
}
