import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/alpha_lifecycle_service.dart';

void main() {
  test(
    'build 227.03 preserves the 227 Alpha expiry and includes the expiry day',
    () {
      expect(AlphaLifecycleService.expiryIsoDate, '2026-10-07');
      expect(AlphaLifecycleService.daysRemaining(DateTime(2026, 9, 7)), 30);
      expect(
        AlphaLifecycleService.isExpired(DateTime(2026, 10, 7, 12)),
        isFalse,
      );
      expect(AlphaLifecycleService.isExpired(DateTime(2026, 10, 8)), isTrue);
    },
  );

  test('warning milestones are stable', () {
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 9, 30)), 7);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 4)), 3);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 6)), 1);
    expect(AlphaLifecycleService.warningStage(DateTime(2026, 10, 7)), 0);
  });

  test('warning stages use next stricter milestone after skipped days', () {
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 9, 29)),
      null,
    ); // 8 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 1)),
      7,
    ); // 6 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 2)),
      7,
    ); // 5 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 3)),
      7,
    ); // 4 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 5)),
      3,
    ); // 2 days
    expect(
      AlphaLifecycleService.warningStage(DateTime(2026, 10, 8)),
      null,
    ); // expired
  });
}
