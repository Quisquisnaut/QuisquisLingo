import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/bounded_log_writer.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bounded string logging keeps the newest diagnostics', () {
    final result = BoundedLogWriter.appendString(
      current: 'oldest\n${List.filled(80, 'x').join()}',
      entry: 'newest-entry\n',
      maximumCharacters: 64,
    );

    expect(result.length, lessThanOrEqualTo(64));
    expect(result, startsWith(BoundedLogWriter.truncationMarker));
    expect(result, contains('newest-entry'));
    expect(result, isNot(contains('oldest')));
  });

  test('bounded string logging does not split a Unicode surrogate pair', () {
    final result = BoundedLogWriter.appendString(
      current: List.filled(20, '🙂').join(),
      entry: 'ok',
      maximumCharacters: 49,
    );
    final retained = result.substring(BoundedLogWriter.truncationMarker.length);

    expect(result.length, lessThanOrEqualTo(49));
    expect(retained.codeUnitAt(0), isNot(inInclusiveRange(0xdc00, 0xdfff)));
    expect(result, endsWith('ok'));
  });

  test(
    'bounded file logging rotates old bytes and preserves new entries',
    () async {
      final directory = await Directory.systemTemp.createTemp('qql_230_logs_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File(
        '${directory.path}${Platform.pathSeparator}bounded.log',
      );

      await BoundedLogWriter.appendFile(
        file,
        'oldest-entry\n${List.filled(80, 'a').join()}\n',
        maximumBytes: 96,
      );
      await BoundedLogWriter.appendFile(
        file,
        'newest-entry\n',
        maximumBytes: 96,
      );

      expect(await file.length(), lessThanOrEqualTo(96));
      final contents = await file.readAsString();
      expect(contents, startsWith(BoundedLogWriter.truncationMarker));
      expect(contents, contains('newest-entry'));
      expect(contents, isNot(contains('oldest-entry')));
    },
  );

  test('bounded file logging preserves valid UTF-8 after rotation', () async {
    final directory = await Directory.systemTemp.createTemp('qql_230_logs_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}unicode.log');

    await BoundedLogWriter.appendFile(
      file,
      '${List.filled(20, '🙂').join()}newest-🚀\n',
      maximumBytes: 65,
    );

    expect(await file.length(), lessThanOrEqualTo(65));
    final contents = await file.readAsString();
    expect(contents, startsWith(BoundedLogWriter.truncationMarker));
    expect(contents, endsWith('newest-🚀\n'));
  });

  test(
    'concurrent file appends are serialized without losing entries',
    () async {
      final directory = await Directory.systemTemp.createTemp('qql_230_logs_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}${Platform.pathSeparator}queued.log');

      await Future.wait([
        for (var index = 0; index < 20; index++)
          BoundedLogWriter.appendFile(
            file,
            'entry-$index\n',
            maximumBytes: 4096,
          ),
      ]);

      final contents = await file.readAsString();
      for (var index = 0; index < 20; index++) {
        expect(contents, contains('entry-$index\n'));
      }
    },
  );

  test('concurrent diagnostic entries do not overwrite one another', () async {
    SharedPreferences.setMockInitialValues({});
    final log = DiagnosticLogService();

    await Future.wait([
      for (var index = 0; index < 20; index++) log.logInfo('event-$index'),
    ]);

    final preferences = await SharedPreferences.getInstance();
    final contents =
        preferences.getString('quisquislingo_diagnostic_log') ?? '';
    for (var index = 0; index < 20; index++) {
      expect(contents, contains('event-$index'));
    }
  });
}
