import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active Dart architecture contains no legacy Lesson field names', () {
    final legacy = RegExp(
      r'topicId|topic_id|["\x27]topics["\x27]',
      caseSensitive: false,
    );
    final allowedNegativeValidation = RegExp(
      r'legacy topics field|containsKey\(["\x27]topics|containsKey\(["\x27]topicId',
      caseSensitive: false,
    );
    final violations = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.toLowerCase().contains('topic')) {
        violations.add('${entity.path}: legacy architecture filename');
      }
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (!legacy.hasMatch(line)) continue;
        final isModelRejection =
            entity.path.endsWith('course_models.dart') &&
            allowedNegativeValidation.hasMatch(line);
        if (!isModelRejection) {
          violations.add('${entity.path}:${index + 1}: ${line.trim()}');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
