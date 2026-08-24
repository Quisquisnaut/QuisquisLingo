import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Topic cards stay fractionally constrained without outer Row overflow', () {
    final source = File('lib/screens/chapter_screen.dart').readAsStringSync();
    final start = source.indexOf('class _TopicTree extends StatelessWidget');
    final end = source.indexOf('class _DuelGate extends StatelessWidget', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final topicTree = source.substring(start, end);
    expect(topicTree.contains('FractionallySizedBox('), isTrue);
    expect(topicTree.contains('widthFactor: 0.72'), isTrue);
    expect(topicTree.contains('mainAxisAlignment:'), isFalse);
    expect(topicTree.contains('MediaQuery.of(context).size.width'), isFalse);
    expect(topicTree.contains('maxLines: 2'), isTrue);
    expect(topicTree.contains('overflow: TextOverflow.ellipsis'), isTrue);
  });
}
