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
    'korean_en.json',
  ];
  for (final file in files) {
    test('$file has nine direct temporary-sample Lessons', () async {
      final raw = await rootBundle.loadString('assets/courses/$file');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      expect(data['formatVersion'], 6);
      expect(data['temporarySample'], isTrue);
      expect(data.containsKey('chapters'), isFalse);
      final lessons = (data['lessons'] as List).cast<Map<String, dynamic>>();
      expect(lessons, hasLength(9));
      for (final lesson in lessons) {
        expect(lesson['guidebook'], isA<Map>());
        expect(lesson['lessonId'], isA<String>());
        expect(lesson.containsKey('id'), isFalse);
        expect(lesson.containsKey('imageAsset'), isFalse);
        expect(lesson['section'], isA<bool>());
        if (lesson['section'] == true) {
          expect(lesson['sectionName'], isA<String>());
        }
        expect(lesson['themeIconAsset'], isA<String>());
        expect(lesson['updatedAt'], endsWith('Z'));
        expect(lesson['duel'], {
          'id': '${lesson['lessonId']}_duel',
          'title': 'Duel',
        });
      }
    });

    test(
      '$file gives every learning Lesson its own Guidebook and non-exercise Round 1 intro',
      () async {
        final raw = await rootBundle.loadString('assets/courses/$file');
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final lessons = (data['lessons'] as List).cast<Map<String, dynamic>>();
        for (final lesson in lessons) {
          final guidebook = Map<String, dynamic>.from(
            lesson['guidebook'] as Map,
          );
          final guideContent = (guidebook['content'] as List)
              .cast<Map<String, dynamic>>();
          expect(guideContent, isNotEmpty);
          expect(
            guideContent.where((item) => item['kind'] == 'vocabulary').length,
            greaterThanOrEqualTo(4),
          );
          final rounds = (lesson['rounds'] as List)
              .cast<Map<String, dynamic>>();
          expect(rounds, hasLength(4));
          final content = (rounds.first['content'] as List)
              .cast<Map<String, dynamic>>();
          final first = content.first;
          expect(first['kind'], 'text');
          expect(first['role'], 'lesson_intro');
          expect(first['required'], isFalse);
          expect(first.containsKey('exercise'), isFalse);
          expect((first['text'] as String).trim(), isNotEmpty);
        }
      },
    );
  }

  test(
    'sample Lessons cover complete Sections, icons and Round title layouts',
    () async {
      final raw = await rootBundle.loadString('assets/courses/italian_en.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final lessons = (data['lessons'] as List).cast<Map<String, dynamic>>();

      expect(
        lessons.where((lesson) => lesson['section'] == true),
        hasLength(9),
      );
      expect(
        lessons.every((lesson) => lesson['themeIconAsset'] != null),
        isTrue,
      );
      expect(
        lessons.any((lesson) => (lesson['title'] as String).length > 50),
        isTrue,
      );
      expect(lessons[0]['sectionName'], lessons[1]['sectionName']);
      expect(lessons[1]['sectionName'], lessons[2]['sectionName']);
      expect(lessons[3]['sectionName'], isNot(lessons[0]['sectionName']));
      expect(lessons[3]['sectionName'], lessons[5]['sectionName']);
      expect(lessons[6]['sectionName'], lessons[8]['sectionName']);

      final rounds = lessons
          .expand((lesson) => (lesson['rounds'] as List).cast<Map>())
          .toList();
      expect(rounds.any((round) => round['title'] == 'First steps'), isTrue);
      expect(rounds.any((round) => round['title'] == 'Comprehension'), isTrue);
      expect(rounds.any((round) => !round.containsKey('title')), isTrue);
    },
  );
}
