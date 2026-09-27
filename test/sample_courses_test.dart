import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Build 255 Revision 6 removed the other 225 samples; Korean remains.
  const files = ['korean_en.json'];
  for (final file in files) {
    test('$file has nine direct temporary-sample Lessons', () async {
      final raw = await rootBundle.loadString('assets/courses/$file');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      expect(data['formatVersion'], 12);
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
}
