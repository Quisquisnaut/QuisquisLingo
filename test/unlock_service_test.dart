import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/unlock_service.dart';

Topic _topic(String id)=>Topic(id:id,title:id,rounds:const []);

Chapter _chapter({
  required String id,
  required int requiredTopics,
  required List<Topic> topics,
})=>Chapter(
  id:id,
  title:id,
  requiredTopics:requiredTopics,
  topics:[...topics, Topic(id:'duel_$id',title:'Duel $id',role:'assessment',assessment:const TopicAssessment(),rounds:const [])],
);

Course _course()=>Course(
  courseId:'test',
  learningLanguage:'Italian',
  interfaceLanguage:'English',
  sourceLanguage:'English',
  targetLanguage:'Italian',
  title:'Test',
  ttsLanguage:'it-IT',
  version:'1',
  chapters:[
    _chapter(id:'c1',requiredTopics:2,topics:[_topic('t1'),_topic('t2'),_topic('t3')]),
    _chapter(id:'c2',requiredTopics:1,topics:[_topic('t4')]),
    _chapter(id:'c3',requiredTopics:0,topics:const []),
  ],
);

void main(){
  final service=UnlockService();

  test('first chapter is always unlocked',(){
    expect(service.isChapterUnlocked(
      chapterIndex:0,
      course:_course(),
      completedTopics:const {},
      wonDuels:const {},
    ),isTrue);
  });

  test('later chapter stays locked with insufficient previous progress',(){
    expect(service.isChapterUnlocked(
      chapterIndex:1,
      course:_course(),
      completedTopics:const {'t1'},
      wonDuels:const {},
    ),isFalse);
  });

  test('later chapter unlocks after enough topics in previous chapter',(){
    expect(service.isChapterUnlocked(
      chapterIndex:1,
      course:_course(),
      completedTopics:const {'t1','t2'},
      wonDuels:const {},
    ),isTrue);
  });

  test('later chapter unlocks after winning previous duel',(){
    expect(service.isChapterUnlocked(
      chapterIndex:1,
      course:_course(),
      completedTopics:const {},
      wonDuels:const {'duel_c1'},
    ),isTrue);
  });

  test('topics completed in another chapter do not unlock the next chapter',(){
    expect(service.isChapterUnlocked(
      chapterIndex:1,
      course:_course(),
      completedTopics:const {'t4','unrelated'},
      wonDuels:const {},
    ),isFalse);
  });

  test('requiredTopics zero unlocks the following chapter',(){
    expect(service.isChapterUnlocked(
      chapterIndex:3,
      course:Course(
        courseId:'test2',
        learningLanguage:'Italian',
        interfaceLanguage:'English',
        sourceLanguage:'English',
        targetLanguage:'Italian',
        title:'Test 2',
        ttsLanguage:'it-IT',
        version:'1',
        chapters:[
          _chapter(id:'a',requiredTopics:1,topics:[_topic('a1')]),
          _chapter(id:'b',requiredTopics:1,topics:[_topic('b1')]),
          _chapter(id:'c',requiredTopics:0,topics:const []),
          _chapter(id:'d',requiredTopics:0,topics:const []),
        ],
      ),
      completedTopics:const {},
      wonDuels:const {},
    ),isTrue);
  });
}
