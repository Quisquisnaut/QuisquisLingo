import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test('build 224 alpha expiry is inclusive through the expiry day', () {
    expect(AlphaLifecycleService.expiryIsoDate, '2026-10-03');
    expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 9, 3)), 30);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 3, 12)), isFalse);
    expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 4)), isTrue);
  });

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 26)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 30)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 2)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 3)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 25)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 27)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 28)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 29)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 1)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 4)),
      null,
    ); // expired
  });
}
