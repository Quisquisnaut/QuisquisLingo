import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test(
    'build 226.02 revision 4 keeps the existing expiry inclusive through the expiry day',
    () {
      expect(AlphaLifecycleService.expiryIsoDate, '2026-10-06');
      expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 9, 6)), 30);
      expect(
        AlphaLifecycleService.isExpired(DateTime(2026, 10, 6, 12)),
        isFalse,
      );
      expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 7)), isTrue);
    },
  );

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 29)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 3)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 5)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 6)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 28)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 30)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 1)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 2)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 4)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 7)),
      null,
    ); // expired
  });
}
