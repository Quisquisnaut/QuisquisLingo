import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test('build 209 alpha expiry is inclusive through the expiry day', () {
    expect(AlphaLifecycleService.expiryIsoDate, '2026-09-25');
    expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 8, 26)), 30);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 9, 25, 12)), isFalse);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 9, 26)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 18)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 22)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 24)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 25)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 17)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 19)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 20)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 21)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 23)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 26)),
      null,
    ); // expired
  });
}
