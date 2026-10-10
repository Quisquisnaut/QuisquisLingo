import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// What went wrong with the learner-data file, for the Crash Log and the
/// learner's notice.
enum LearnerDataProblemKind {
  /// The file could not be read; the last copy that loaded fine was used.
  restoredLastGood,

  /// The file could not be read and no usable copy existed: QQL started
  /// without learner data. The damaged file was kept.
  startedEmpty,

  /// A change could not be written to disk.
  writeFailed,
}

class LearnerDataProblem {
  const LearnerDataProblem(
    this.kind, {
    this.damagedCopy,
    this.lastGoodSavedAt,
    this.error,
  });

  final LearnerDataProblemKind kind;

  /// Where the unreadable file was kept, when it was.
  final String? damagedCopy;

  /// When the copy that was used had been saved.
  final DateTime? lastGoodSavedAt;
  final Object? error;
}

/// Learner data on Windows and Linux (Build 270 Revision 0).
///
/// The shared_preferences plugins for these systems keep every preference in
/// one `shared_preferences.json` that they rewrite in place: a crash, a power
/// cut or a full disk in the middle of a write leaves a file nobody can read,
/// and the app could not start again. This store keeps the same file, at the
/// same place and in the same JSON, so nothing is converted, but:
///
/// - every write goes to a temporary file that is flushed and then renamed
///   over the file, so the file is always either the old or the new version;
/// - writes run one at a time and always save the latest state, so a burst of
///   changes is one write;
/// - after each successful start-up the file is copied to [lastGoodFileName];
///   a file that cannot be read is kept as `QQL_learner_data_damaged_<time>`
///   and the last good copy is used instead;
/// - a write that fails is reported through [onProblem] instead of being lost
///   in silence (the plugin only printed it in debug builds).
class AtomicPreferencesStore extends SharedPreferencesStorePlatform {
  AtomicPreferencesStore({
    required Future<Directory> Function() directory,
    this.onProblem,
    @visibleForTesting
    this.renameRetryDelays = const [
      Duration(milliseconds: 50),
      Duration(milliseconds: 150),
      Duration(milliseconds: 400),
    ],
  }) : _directory = directory;

  /// The plugin's own file name, so the data stays where it always was.
  static const fileName = 'shared_preferences.json';
  static const temporaryFileName = 'shared_preferences.json.tmp';

  /// The copy of the file as it was at the last start-up that read it.
  static const lastGoodFileName = 'QQL_learner_data_last_good.json';
  static const damagedFilePrefix = 'QQL_learner_data_damaged_';

  static const _defaultPrefix = 'flutter.';

  /// Uses this store on the systems whose plugin rewrites the file in place.
  /// Call before anything reads a preference.
  static AtomicPreferencesStore? installIfNeeded({
    required Future<Directory> Function() directory,
    void Function(LearnerDataProblem problem)? onProblem,
  }) {
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux)) return null;
    final store = AtomicPreferencesStore(
      directory: directory,
      onProblem: onProblem,
    );
    SharedPreferencesStorePlatform.instance = store;
    return store;
  }

  /// The safety copies this store makes in [directory] (the last good copy
  /// and the damaged files kept), for the Inventory and Wipe everything.
  static Future<List<File>> safetyCopiesIn(Directory directory) async {
    final copies = <File>[];
    if (!await directory.exists()) return copies;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name == lastGoodFileName ||
          (name.startsWith(damagedFilePrefix) && name.endsWith('.json'))) {
        copies.add(entity);
      }
    }
    copies.sort((a, b) => a.path.compareTo(b.path));
    return copies;
  }

  final Future<Directory> Function() _directory;
  final void Function(LearnerDataProblem problem)? onProblem;
  final List<Duration> renameRetryDelays;

  Map<String, Object>? _cache;
  Future<Map<String, Object>>? _loading;
  LearnerDataProblem? _recovery;

  /// What happened when the file was read at start-up, when it could not be
  /// read as it was.
  LearnerDataProblem? get recovery => _recovery;

  // Each change takes a number; a write saves every change made before it
  // started, so the changes queued behind it are already on disk.
  int _changes = 0;
  int _savedChanges = 0;
  Future<void> _writes = Future<void>.value();

  // Build 270 Revision 5: while [hold] runs, changes stay in memory and are
  // written together when it ends, so a crash leaves all of them or none.
  int _holds = 0;

  /// Runs [body] with this store's writes held, then writes once. Every
  /// change made meanwhile (by [body] or anything else) reaches the disk in
  /// the same write; a change made while held reports success at once, and
  /// a failure of that write is reported through [onProblem].
  Future<T> hold<T>(Future<T> Function() body) async {
    _holds++;
    try {
      return await body();
    } finally {
      _holds--;
      if (_holds == 0 && _changes > _savedChanges) await _persist();
    }
  }

  /// Runs [body] as one group of learner-data changes: on Windows and Linux,
  /// where [AtomicPreferencesStore] is installed, written together; on other
  /// systems (and in tests) simply run.
  static Future<T> group<T>(Future<T> Function() body) {
    final store = SharedPreferencesStorePlatform.instance;
    return store is AtomicPreferencesStore ? store.hold(body) : body();
  }

  Future<Map<String, Object>> _preferences() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load().then(
      (value) => _cache = value,
      onError: (Object error, StackTrace stackTrace) {
        // Let the next read try again (the start-up screen offers Retry).
        _loading = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  Future<Map<String, Object>> _load() async {
    final directory = await _directory();
    final main = _file(directory, fileName);
    final lastGood = _file(directory, lastGoodFileName);
    await _deleteQuietly(_file(directory, temporaryFileName));

    final current = await _read(main);
    if (current case _Readable(:final values)) {
      await _saveLastGood(directory, values);
      return values;
    }
    if (current is _Missing) {
      // First start, or a file lost outside QQL: a copy may still exist.
      final copy = await _read(lastGood);
      if (copy case _Readable(:final values)) {
        _report(
          LearnerDataProblem(
            LearnerDataProblemKind.restoredLastGood,
            lastGoodSavedAt: await _modified(lastGood),
          ),
          startUp: true,
        );
        await _writeFile(directory, values);
        return values;
      }
      return <String, Object>{};
    }

    // The file is there but cannot be read: keep it for a rescue, never
    // overwrite it.
    final damaged = await _keepDamaged(directory, main);
    final copy = await _read(lastGood);
    if (copy case _Readable(:final values)) {
      _report(
        LearnerDataProblem(
          LearnerDataProblemKind.restoredLastGood,
          damagedCopy: damaged,
          lastGoodSavedAt: await _modified(lastGood),
          error: (current as _Unreadable).error,
        ),
        startUp: true,
      );
      await _writeFile(directory, values);
      return values;
    }
    _report(
      LearnerDataProblem(
        LearnerDataProblemKind.startedEmpty,
        damagedCopy: damaged,
        error: (current as _Unreadable).error,
      ),
      startUp: true,
    );
    return <String, Object>{};
  }

  Future<_FileState> _read(File file) async {
    try {
      if (!await file.exists()) return const _Missing();
      final text = await file.readAsString();
      // An empty file is what an interrupted in-place write leaves behind.
      if (text.trim().isEmpty) {
        return const _Unreadable('The learner-data file is empty.');
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        return const _Unreadable('The learner-data file is not a JSON object.');
      }
      final values = <String, Object>{};
      for (final MapEntry(:key, :value) in decoded.entries) {
        if (key is String && value != null) values[key] = value as Object;
      }
      return _Readable(values);
    } catch (error) {
      return _Unreadable(error);
    }
  }

  Future<String?> _keepDamaged(Directory directory, File main) async {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
    var target = _file(directory, '$damagedFilePrefix$stamp.json');
    for (var n = 2; await target.exists(); n++) {
      target = _file(directory, '$damagedFilePrefix${stamp}_$n.json');
    }
    try {
      await main.rename(target.path);
      return target.path;
    } catch (_) {
      try {
        await main.copy(target.path);
        return target.path;
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _saveLastGood(
    Directory directory,
    Map<String, Object> values,
  ) async {
    try {
      final temporary = _file(directory, '$lastGoodFileName.tmp');
      await temporary.writeAsString(jsonEncode(values), flush: true);
      await _rename(temporary, _file(directory, lastGoodFileName));
    } catch (_) {
      // The copy is a safety net: the learner's data is still in the file.
    }
  }

  Future<bool> _persist() {
    if (_holds > 0) {
      _changes++;
      return Future.value(true);
    }
    final change = ++_changes;
    final done = Completer<bool>();
    _writes = _writes.then((_) async {
      // Saved by a later write, or held: the end of the hold writes it.
      if (_savedChanges >= change || _holds > 0) {
        done.complete(true);
        return;
      }
      final covers = _changes;
      // The state to save is taken now, before any wait, so a hold that
      // starts while the file is written never has half its changes in it.
      final text = jsonEncode(_cache!);
      var ok = false;
      try {
        ok = await _writeText(await _directory(), text);
      } catch (error) {
        _report(
          LearnerDataProblem(LearnerDataProblemKind.writeFailed, error: error),
        );
      }
      if (ok) _savedChanges = covers;
      done.complete(ok);
    });
    return done.future;
  }

  Future<bool> _writeFile(Directory directory, Map<String, Object> values) =>
      _writeText(directory, jsonEncode(values));

  Future<bool> _writeText(Directory directory, String text) async {
    try {
      await directory.create(recursive: true);
      final temporary = _file(directory, temporaryFileName);
      await temporary.writeAsString(text, flush: true);
      await _rename(temporary, _file(directory, fileName));
      return true;
    } catch (error) {
      _report(
        LearnerDataProblem(LearnerDataProblemKind.writeFailed, error: error),
      );
      return false;
    }
  }

  /// A virus scanner or a sync client may hold the file for a moment.
  Future<void> _rename(File from, File to) async {
    for (var attempt = 0; ; attempt++) {
      try {
        await from.rename(to.path);
        return;
      } on FileSystemException {
        if (attempt >= renameRetryDelays.length) rethrow;
        await Future<void>.delayed(renameRetryDelays[attempt]);
      }
    }
  }

  void _report(LearnerDataProblem problem, {bool startUp = false}) {
    if (startUp) _recovery = problem;
    try {
      onProblem?.call(problem);
    } catch (_) {
      // Reporting must never stop a read or a write.
    }
  }

  static File _file(Directory directory, String name) =>
      File('${directory.path}${Platform.pathSeparator}$name');

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<DateTime?> _modified(File file) async {
    try {
      return await file.lastModified();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> clear() => clearWithParameters(
    ClearParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
  );

  @override
  Future<bool> clearWithPrefix(String prefix) => clearWithParameters(
    ClearParameters(filter: PreferencesFilter(prefix: prefix)),
  );

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async {
    final filter = parameters.filter;
    final preferences = await _preferences();
    preferences.removeWhere(
      (key, _) =>
          key.startsWith(filter.prefix) &&
          (filter.allowList == null || filter.allowList!.contains(key)),
    );
    return _persist();
  }

  @override
  Future<Map<String, Object>> getAll() => getAllWithParameters(
    GetAllParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
  );

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) =>
      getAllWithParameters(
        GetAllParameters(filter: PreferencesFilter(prefix: prefix)),
      );

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    final filter = parameters.filter;
    final preferences = Map<String, Object>.from(await _preferences());
    preferences.removeWhere(
      (key, _) =>
          !(key.startsWith(filter.prefix) &&
              (filter.allowList?.contains(key) ?? true)),
    );
    return preferences;
  }

  @override
  Future<bool> remove(String key) async {
    final preferences = await _preferences();
    preferences.remove(key);
    return _persist();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final preferences = await _preferences();
    preferences[key] = value;
    return _persist();
  }
}

sealed class _FileState {
  const _FileState();
}

class _Missing extends _FileState {
  const _Missing();
}

class _Readable extends _FileState {
  const _Readable(this.values);
  final Map<String, Object> values;
}

class _Unreadable extends _FileState {
  const _Unreadable(this.error);
  final Object error;
}
