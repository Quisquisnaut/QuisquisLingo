import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test('build 214 alpha expiry is inclusive through the expiry day', () {
    expect(AlphaLifecycleService.expiryIsoDate, '2026-09-27');
    expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 8, 28)), 30);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 9, 27, 12)), isFalse);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 9, 28)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 20)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 24)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 26)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 27)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 19)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 21)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 22)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 23)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 25)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 28)),
      null,
    ); // expired
  });
}
