import '../models/course_models.dart';

class TopicUnlockService {
  const TopicUnlockService();

  bool isTopicUnlocked({
    required int topicIndex,
    required Course course,
    required Set<String> completedTopics,
    required Set<String> wonDuels,
  }) {
    if (topicIndex < 0 || topicIndex >= course.topics.length) return false;
    if (topicIndex == 0) return true;

    final previousTopic = course.topics[topicIndex - 1];
    return completedTopics.contains(previousTopic.id) ||
        wonDuels.contains(previousTopic.duel.id);
  }
}
