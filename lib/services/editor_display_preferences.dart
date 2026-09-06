import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local presentation preferences shared by the complete Editor.
abstract final class EditorDisplayPreferences {
  static const showInternalIdsKey = 'editor_show_internal_ids_v1';

  static final ValueNotifier<bool> showInternalIds = ValueNotifier(false);
  static SharedPreferences? _preferences;
  static Future<void>? _loading;

  static Future<void> load() => _loading ??= _load();

  static Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    showInternalIds.value = preferences.getBool(showInternalIdsKey) ?? false;
  }

  static Future<void> toggleInternalIds() async {
    await load();
    final next = !showInternalIds.value;
    showInternalIds.value = next;
    await _preferences!.setBool(showInternalIdsKey, next);
  }

  @visibleForTesting
  static void resetForTesting() {
    _preferences = null;
    _loading = null;
    showInternalIds.value = false;
  }
}
