import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/topic_unlock_service.dart';

Topic _topic(String id) => Topic(
  id: id,
  title: id,
  rounds: const [],
  duel: Duel(id: 'duel_$id', title: 'Duel $id'),
);

Course _course({List<Topic>? topics}) => Course(
  courseId: 'test',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Test',
  ttsLanguage: 'it-IT',
  version: '1',
  topics: topics ?? [_topic('t1'), _topic('t2'), _topic('t3')],
);

void main() {
  const service = TopicUnlockService();

  test('first Topic is unlocked when it exists', () {
    expect(
      service.isTopicUnlocked(
        topicIndex: 0,
        course: _course(),
        completedTopics: const {},
        wonDuels: const {},
      ),
      isTrue,
    );
  });

  test('later Topic stays locked without previous Topic progress', () {
    expect(
      service.isTopicUnlocked(
        topicIndex: 1,
        course: _course(),
        completedTopics: const {},
        wonDuels: const {},
      ),
      isFalse,
    );
  });

  test('later Topic unlocks after completing the previous Topic', () {
    expect(
      service.isTopicUnlocked(
        topicIndex: 1,
        course: _course(),
        completedTopics: const {'t1'},
        wonDuels: const {},
      ),
      isTrue,
    );
  });

  test('later Topic unlocks after winning the previous Topic Duel', () {
    expect(
      service.isTopicUnlocked(
        topicIndex: 1,
        course: _course(),
        completedTopics: const {},
        wonDuels: const {'duel_t1'},
      ),
      isTrue,
    );
  });

  test('only the immediately previous Topic can unlock a later Topic', () {
    expect(
      service.isTopicUnlocked(
        topicIndex: 2,
        course: _course(),
        completedTopics: const {'t1', 'unrelated'},
        wonDuels: const {'duel_t1'},
      ),
      isFalse,
    );
  });

  test('missing Topic indices are not unlocked', () {
    expect(
      service.isTopicUnlocked(
        topicIndex: -1,
        course: _course(),
        completedTopics: const {},
        wonDuels: const {},
      ),
      isFalse,
    );
    expect(
      service.isTopicUnlocked(
        topicIndex: 3,
        course: _course(),
        completedTopics: const {'t3'},
        wonDuels: const {'duel_t3'},
      ),
      isFalse,
    );
    expect(
      service.isTopicUnlocked(
        topicIndex: 0,
        course: _course(topics: const []),
        completedTopics: const {},
        wonDuels: const {},
      ),
      isFalse,
    );
  });
}
