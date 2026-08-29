import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const files = [
    'italian_en.json',
    'german_en.json',
    'spanish_en.json',
    'english_es.json',
    'portuguese_en.json',
    'dutch_en.json',
    'welsh_en.json',
    'finnish_en.json',
  ];
  for (final file in files) {
    test('$file has nine direct temporary-sample Topics', () async {
      final raw = await rootBundle.loadString('assets/courses/$file');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      expect(data['formatVersion'], 4);
      expect(data['temporarySample'], isTrue);
      expect(data.containsKey('chapters'), isFalse);
      final topics = (data['topics'] as List).cast<Map<String, dynamic>>();
      expect(topics, hasLength(9));
      for (final topic in topics) {
        expect(topic['guidebook'], isA<Map>());
        expect(topic['duel'], {'id': '${topic['id']}_duel', 'title': 'Duel'});
      }
    });

    test(
      '$file gives every learning Topic its own Guidebook and non-exercise Round 1 intro',
      () async {
        final raw = await rootBundle.loadString('assets/courses/$file');
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final topics = (data['topics'] as List).cast<Map<String, dynamic>>();
        for (final topic in topics) {
          final guidebook = Map<String, dynamic>.from(
            topic['guidebook'] as Map,
          );
          final guideContent = (guidebook['content'] as List)
              .cast<Map<String, dynamic>>();
          expect(guideContent, isNotEmpty);
          expect(
            guideContent.where((item) => item['kind'] == 'vocabulary').length,
            greaterThanOrEqualTo(4),
          );
          final rounds = (topic['rounds'] as List).cast<Map<String, dynamic>>();
          expect(rounds, isNotEmpty);
          final content = (rounds.first['content'] as List)
              .cast<Map<String, dynamic>>();
          final first = content.first;
          expect(first['kind'], 'explanation');
          expect(first['role'], 'topic_intro');
          expect(first['required'], isFalse);
          expect(first.containsKey('exercise'), isFalse);
          expect(
            (first['text'] as String).toLowerCase(),
            contains('guidebook'),
          );
        }
      },
    );
  }
}
