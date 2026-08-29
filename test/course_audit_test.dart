import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/status_service.dart';

Exercise sampleChoice({int? correct = 0, List<String> answers = const ['a', 'b']}) => Exercise(
  id: 'ex1', type: 'choice', prompt: 'p', question: 'q', answers: answers,
  correct: correct, tts: null, accepted: const [], tokens: const [],
  orderAnswer: const [], pairs: const [], hint: '', icons: const [],
);

Course sampleCourse(Topic topic) => Course(
  courseId: 'course-audit', learningLanguage: 'Italian', interfaceLanguage: 'English',
  sourceLanguage: 'English', targetLanguage: 'Italian', title: 'Audit course',
  ttsLanguage: 'it-IT', version: '1', topics: [topic],
);

void main() {
  test('audit issues expose a stable code field', () {
    final issues = CourseAuditService().auditExercise(sampleChoice(correct: 4));
    expect(issues.every((i) => i.code.isNotEmpty), isTrue);
  });

  test('exercise audit catches an invalid correct answer', () {
    final issues = CourseAuditService().auditExercise(sampleChoice(correct: 4));
    expect(issues.any((i) => i.severity == AuditSeverity.error), isTrue);
  });

  test('short Topic and insufficient Duel pool are non-blocking guidance', () {
    final topic=Topic(
      id:'topic-1',title:'Short Topic',duel:Duel(id:'topic-1-duel',title:'Duel'),
      rounds:[LearningRound(id:'round-1',title:'Round 1',exercises:[sampleChoice()])],
    );
    final issues=CourseAuditService().auditCourse(sampleCourse(topic)).issues;
    expect(issues.where((i)=>i.code=='TOPIC_ROUND_GUIDANCE').single.severity,AuditSeverity.suggestion);
    expect(issues.where((i)=>i.code=='DUEL_UNAVAILABLE').single.severity,AuditSeverity.suggestion);
    expect(issues.any((i)=>i.code=='DUEL_UNAVAILABLE'&&i.severity==AuditSeverity.error),isFalse);
  });

  test('exercise audit rejects a fill hint that reveals the answer', () {
    final ex = Exercise(
      id: 'f1', type: 'fill_blank', prompt: '', question: 'piazz_', answers: const [],
      correct: null, tts: null, accepted: const ['piazza'], tokens: const [],
      orderAnswer: const [], pairs: const [], hint: 'The word is piazza', icons: const [],
    );
    final issues = CourseAuditService().auditExercise(ex);
    expect(issues.any((i) => i.severity == AuditSeverity.error && i.code == 'HINT_REVEALS_ANSWER'), isTrue);
  });

  test('Status is monotonic with additional learning activity', () {
    final s = StatusService();
    final low = s.score(xp: 10, streak: 1, daysStudied: 1, roundsCompleted: 1);
    final high = s.score(xp: 20, streak: 2, daysStudied: 2, roundsCompleted: 2);
    expect(high, greaterThan(low));
  });
  // Audio Match duplicates are errors because a single exercise must not ask
  // the learner to match the same spoken item/word more than once.
  test('audio match audit rejects duplicate sounds and choices', () {
    final ex = Exercise(
      id: 'am1', type: 'audio_match', prompt: '', question: 'Match the sounds',
      answers: const ['hello', 'hello', 'thanks', 'water', 'coffee'], correct: null,
      tts: null, accepted: const [], tokens: const [], orderAnswer: const [],
      pairs: const [['Hallo', 'hello'], ['Hallo', 'hello'], ['Danke', 'thanks']],
      hint: '', icons: const [],
    );
    final issues = CourseAuditService().auditExercise(ex);
    expect(issues.where((i) => i.severity == AuditSeverity.error).length, greaterThanOrEqualTo(3));
    expect(issues.any((i) => i.message.contains('same target audio')), isTrue);
    expect(issues.any((i) => i.message.contains('same matching text')), isTrue);
    expect(issues.any((i) => i.message.contains('visible choices contain duplicates')), isTrue);
  });

  test('word block audit accepts zero distractors', () {
    final ex = Exercise(
      id: 'wo1', type: 'word_order', prompt: 'Translate', question: '',
      answers: const [], correct: null, tts: null, accepted: const [],
      tokens: const ['I', 'want', 'coffee'], orderAnswer: const ['I', 'want', 'coffee'],
      pairs: const [], hint: '', icons: const [],
    );
    final issues = CourseAuditService().auditExercise(ex);
    expect(issues.where((i) => i.severity == AuditSeverity.error), isEmpty);
  });

  test('word block audit accepts one extra distractor', () {
    final ex = Exercise(
      id: 'wo2', type: 'word_order', prompt: 'Translate', question: '',
      answers: const [], correct: null, tts: null, accepted: const [],
      tokens: const ['I', 'want', 'coffee', 'tea'], orderAnswer: const ['I', 'want', 'coffee'],
      pairs: const [], hint: '', icons: const [],
    );
    final issues = CourseAuditService().auditExercise(ex);
    expect(issues.where((i) => i.severity == AuditSeverity.error), isEmpty);
  });


  test('word block audit accepts two extra distractors', () {
    final ex = Exercise(
      id: 'wo2b', type: 'word_order', prompt: 'Translate', question: '',
      answers: const [], correct: null, tts: null, accepted: const [],
      tokens: const ['I', 'want', 'coffee', 'tea', 'water'], orderAnswer: const ['I', 'want', 'coffee'],
      pairs: const [], hint: '', icons: const [],
    );
    final issues = CourseAuditService().auditExercise(ex);
    expect(issues.where((i) => i.severity == AuditSeverity.error), isEmpty);
  });

  test('word block audit rejects more than two distractors', () {
    final ex = Exercise(
      id: 'wo2c', type: 'word_order', prompt: 'Translate', question: '',
      answers: const [], correct: null, tts: null, accepted: const [],
      tokens: const ['I', 'want', 'coffee', 'tea', 'water', 'book'], orderAnswer: const ['I', 'want', 'coffee'],
      pairs: const [], hint: '', icons: const [],
    );
    final issues = CourseAuditService().auditExercise(ex);
    expect(issues.any((i) => i.severity == AuditSeverity.error && i.message.contains('0, 1 or 2')), isTrue);
  });

  test('word block audit rejects a high-confidence cross-language distractor', () {
    final ex = Exercise(
      id: 'wo3', type: 'word_order', prompt: 'Translate', question: '',
      answers: const [], correct: null, tts: null, accepted: const [],
      tokens: const ['Grazie', 'Good'], orderAnswer: const ['Grazie'],
      pairs: const [], hint: '', icons: const [],
    );
    final issues = CourseAuditService().auditExercise(ex);
    expect(issues.any((i) => i.severity == AuditSeverity.error && i.message.contains('different language')), isTrue);
  });

  test('image word requires an image and rejects distractors', () {
    final valid = Exercise(
      id: 'iw1', type: 'image_word', prompt: 'Build the word', question: '',
      answers: const [], correct: null, tts: null, accepted: const [],
      tokens: const ['c', 'a', 's', 'a'], orderAnswer: const ['c', 'a', 's', 'a'],
      pairs: const [], hint: '', icons: const [], imageAsset: 'assets/exercise_images/house.webp',
    );
    expect(CourseAuditService().auditExercise(valid).where((i) => i.severity == AuditSeverity.error), isEmpty);
    final withDistractor = Exercise(
      id: 'iw2', type: 'image_word', prompt: 'Build the word', question: '',
      answers: const [], correct: null, tts: null, accepted: const [],
      tokens: const ['c', 'a', 's', 'a', 'x'], orderAnswer: const ['c', 'a', 's', 'a'],
      pairs: const [], hint: '', icons: const [], imageAsset: 'assets/exercise_images/house.webp',
    );
    expect(CourseAuditService().auditExercise(withDistractor).any((i) => i.message.contains('only the blocks needed')), isTrue);
    final missingImage = Exercise(
      id: 'iw3', type: 'image_word', prompt: 'Build the word', question: '',
      answers: const [], correct: null, tts: null, accepted: const [],
      tokens: const ['c', 'a', 's', 'a'], orderAnswer: const ['c', 'a', 's', 'a'],
      pairs: const [], hint: '', icons: const [],
    );
    expect(CourseAuditService().auditExercise(missingImage).any((i) => i.message.contains('requires an image')), isTrue);
  });

  test('gap choice requires one marked gap and a valid answer', () {
    final valid = Exercise(
      id: 'gap1', type: 'gap_choice', prompt: '', question: 'Maria ___ italiana.',
      answers: const ['è', 'sono', 'sei'], correct: 0, tts: null,
      accepted: const [], tokens: const [], orderAnswer: const [], pairs: const [], hint: '', icons: const [],
    );
    expect(CourseAuditService().auditExercise(valid).where((i) => i.severity == AuditSeverity.error), isEmpty);
    final invalid = Exercise(
      id: 'gap2', type: 'gap_choice', prompt: '', question: 'Maria è italiana.',
      answers: const ['è', 'sono'], correct: 0, tts: null,
      accepted: const [], tokens: const [], orderAnswer: const [], pairs: const [], hint: '', icons: const [],
    );
    expect(CourseAuditService().auditExercise(invalid).any((i) => i.message.contains('___')), isTrue);
  });

  test('Status starts at Apprentice and exposes ten long-term ranks', () {
    final rank = StatusService().rank(xp:0,streak:0,daysStudied:0,roundsCompleted:0);
    expect(rank.name, 'Apprentice');
    expect(rank.index, 0);
    expect(StatusService.names.length, 10);
    expect(StatusService.thresholds.length, 10);
  });

  test('removing Learner does not shift later Status thresholds', () {
    final s=StatusService();
    expect(s.rank(xp:6499,streak:0,daysStudied:0,roundsCompleted:0).name,'Apprentice');
    expect(s.rank(xp:6500,streak:0,daysStudied:0,roundsCompleted:0).name,'Wanderer');
    expect(StatusService.thresholds.last,140000);
  });

  test('listening spelling requires an accepted text answer', () {
    final ex = Exercise(
      id:'ls1',type:'listening_spelling',prompt:'',question:'Type what you hear.',answers:const [],correct:null,tts:'ecco',
      accepted:const [],tokens:const [],orderAnswer:const [],pairs:const [],hint:'',icons:const [],
    );
    final issues=CourseAuditService().auditExercise(ex);
    expect(issues.any((i)=>i.code=='LISTENING_SPELLING_NO_ANSWER'&&i.severity==AuditSeverity.error),isTrue);
  });

  test('audit flags unresolved selected Item IDs', () {
    final ex=Exercise.v2(
      id:'bad_select',editorTemplate:'choice',
      promptElements:const [PromptElement(role:'question',type:'text',text:'Choose.')],
      interaction:const ExerciseInteraction(kind:'select',items:[
        ExerciseItem(id:'i1',content:[PromptElement(type:'text',text:'one')]),
        ExerciseItem(id:'i2',content:[PromptElement(type:'text',text:'two')]),
      ]),
      evaluation:const ExerciseEvaluation(kind:'selected_items',correctItemIds:['missing']),
    );
    final issues=CourseAuditService().auditExercise(ex);
    expect(issues.any((i)=>i.code=='CORRECT_ITEM_UNRESOLVED'),isTrue);
  });

  test('audit flags the known generated Reading vocabulary mismatch pattern', () {
    final ex=Exercise(
      id:'read_bad',type:'reading_comprehension',prompt:'Magari viene più tardi.',
      question:'Read: “Magari viene più tardi.” Which option best fits the Topic vocabulary?',
      answers:const ['comunque','succede','pare'],correct:0,tts:null,accepted:const [],tokens:const [],orderAnswer:const [],pairs:const [],hint:'',icons:const [],
    );
    final issues=CourseAuditService().auditExercise(ex);
    expect(issues.any((i)=>i.code=='READING_OPTION_NOT_IN_PASSAGE'&&i.severity==AuditSeverity.warning),isTrue);
  });

}
