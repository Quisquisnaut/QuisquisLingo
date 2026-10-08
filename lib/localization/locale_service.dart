import 'package:shared_preferences/shared_preferences.dart';

import '../services/learner_status_events.dart';
import '../services/profile_service.dart';

/// The learner's selected language for localized QQL text.
enum AppLocale {
  english('EN'),
  italian('IT'),
  spanish('ES');

  const AppLocale(this.id);

  final String id;

  static AppLocale fromStored(String? value) => AppLocale.values.firstWhere(
    (locale) => locale.id == value,
    orElse: () => AppLocale.english,
  );
}

/// Reads and changes the one profile-scoped Locale preference.
///
/// Reads and translation fallback never repair storage. A selected value is
/// stored only when the user changes a Locale selector.
class LocaleService {
  static const preferenceBase = 'locale';

  Future<AppLocale> read() async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return AppLocale.english;
    final raw = (await SharedPreferences.getInstance()).getString(
      profiles.keyForProfileId(activeId, preferenceBase),
    );
    return AppLocale.fromStored(raw);
  }

  Future<void> write(AppLocale locale) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      profiles.keyForProfileId(activeId, preferenceBase),
      locale.id,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.locale);
  }
}
