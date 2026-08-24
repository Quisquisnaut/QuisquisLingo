import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const files = [
    'italian_en.json','german_en.json','spanish_en.json','english_es.json',
    'portuguese_en.json','dutch_en.json','welsh_en.json','finnish_en.json',
  ];
  for (final file in files) {
    test('$file has exactly three temporary sample chapters', () async {
      final raw = await rootBundle.loadString('assets/courses/$file');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      expect(data['formatVersion'],3);
      final chapters = data['chapters'] as List<dynamic>;
      expect(chapters, hasLength(3));
      for (final chapter in chapters.cast<Map<String, dynamic>>()) {
        expect(chapter['temporarySample'], isTrue);
        expect(chapter.containsKey('guidebook'),isFalse);
        final learning=(chapter['topics'] as List).cast<Map<String,dynamic>>().where((t)=>t['role']!='assessment').toList();
        expect(learning,hasLength(3));
      }
    });

    test('$file gives every learning Topic its own Guidebook and non-exercise Round 1 intro', () async {
      final raw = await rootBundle.loadString('assets/courses/$file');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final chapters = (data['chapters'] as List).cast<Map<String,dynamic>>();
      for (final chapter in chapters) {
        for (final topic in (chapter['topics'] as List).cast<Map<String,dynamic>>().where((t) => t['role'] != 'assessment')) {
          final guidebook=Map<String,dynamic>.from(topic['guidebook'] as Map);
          final guideContent=(guidebook['content'] as List).cast<Map<String,dynamic>>();
          expect(guideContent,isNotEmpty);
          expect(guideContent.where((item)=>item['kind']=='vocabulary').length,greaterThanOrEqualTo(4));
          final rounds = (topic['rounds'] as List).cast<Map<String,dynamic>>();
          expect(rounds, isNotEmpty);
          final content = (rounds.first['content'] as List).cast<Map<String,dynamic>>();
          final first = content.first;
          expect(first['kind'], 'explanation');
          expect(first['role'], 'topic_intro');
          expect(first['required'], isFalse);
          expect(first.containsKey('exercise'), isFalse);
          expect((first['text'] as String).toLowerCase(), contains('guidebook'));
        }
      }
    });
  }
}
