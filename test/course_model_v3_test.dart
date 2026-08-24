import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  const samples=['italian_en.json','german_en.json','spanish_en.json','english_es.json','portuguese_en.json','dutch_en.json','welsh_en.json','finnish_en.json'];

  for(final file in samples){
    test('$file is native Course Model v3 with Topic Guidebooks and assessment Topics',()async{
      final raw=await rootBundle.loadString('assets/courses/$file');
      final json=jsonDecode(raw) as Map<String,dynamic>;
      expect(json['formatVersion'],3);
      final course=Course.fromJson(json);
      expect(course.formatVersion,3);
      expect(course.chapters,hasLength(3));
      for(final chapter in course.chapters){
        expect(chapter.learningTopics,hasLength(3));
        expect(chapter.toJson().containsKey('guidebook'),isFalse);
        expect(chapter.learningTopics.every((t)=>t.title.trim().isNotEmpty&&t.imageAsset.trim().isNotEmpty),isTrue);
        final assessments=chapter.topics.where((t)=>t.role=='assessment').toList();
        expect(assessments,hasLength(1));
        expect(assessments.single.assessment?.purpose,'skip_test');
        expect(assessments.single.assessment?.selectionCount,25);
        for(final topic in chapter.learningTopics){
          expect(topic.guidebook.content,isNotEmpty);
          expect(topic.rounds,isNotEmpty);
          expect(topic.rounds.every((r)=>r.content.isNotEmpty),isTrue);
          expect(topic.rounds.first.content.first.role,'topic_intro');
        }
      }
    });
  }

  test('Course Model v2 Chapter Guidebook migrates deterministically into Topic Guidebooks',(){
    final json=<String,dynamic>{
      'formatVersion':2,'courseId':'legacy','learningLanguage':'Italian','interfaceLanguage':'English',
      'sourceLanguage':'English','targetLanguage':'Italian','title':'Legacy','ttsLanguage':'it-IT','version':'1',
      'chapters':[{
        'id':'c1','title':'One','requiredTopics':1,
        'guidebook':{'content':[{'id':'old_g1','kind':'vocabulary','required':false,'role':'vocabulary','text':'ciao = hello'}]},
        'topics':[
          {'id':'t1','title':'Topic 1','role':'learning','rounds':[{'id':'r1','title':'Round 1','content':[{'id':'intro','kind':'explanation','required':false,'role':'topic_intro','text':'Intro','sourceRefs':['old_g1']}]}]},
          {'id':'t2','title':'Topic 2','role':'learning','rounds':[]},
          {'id':'duel','title':'Language Duel','role':'assessment','assessment':{'purpose':'skip_test','selection':{'count':25}},'rounds':[]},
        ],
      }],
    };
    final course=Course.fromJson(json);
    expect(course.formatVersion,3);
    expect(course.chapters.single.learningTopics.every((t)=>t.guidebook.vocabulary.single=='ciao = hello'),isTrue);
    final ids=course.chapters.single.learningTopics.expand((t)=>t.guidebook.content.map((c)=>c.id)).toList();
    expect(ids.toSet().length,ids.length);
    expect(ids.every((id)=>id.contains('_legacy_guide_')),isTrue);
    expect(course.chapters.single.learningTopics.first.rounds.first.content.first.sourceRefs.single,course.chapters.single.learningTopics.first.guidebook.content.first.id);
    final exported=course.toJson();
    expect(exported['formatVersion'],3);
    expect((exported['chapters'] as List).first.containsKey('guidebook'),isFalse);
  });

  test('text_match reads acceptedAnswers and legacy accepted, then writes acceptedAnswers',(){
    ExerciseEvaluation read(Map<String,dynamic> json)=>ExerciseEvaluation.fromJson(json);
    expect(read({'kind':'text_match','acceptedAnswers':['ecco']}).accepted,['ecco']);
    expect(read({'kind':'text_match','accepted':['ciao']}).accepted,['ciao']);
    final encoded=read({'kind':'text_match','acceptedAnswers':['ecco']}).toJson();
    expect(encoded['acceptedAnswers'],['ecco']);
    expect(encoded.containsKey('accepted'),isFalse);
  });

  test('optional course flag metadata round-trips in Course Model v3',(){
    final course=Course(
      courseId:'user_flag_test',learningLanguage:'German',interfaceLanguage:'English',
      sourceLanguage:'English',targetLanguage:'German',title:'German',ttsLanguage:'de-DE',version:'1',
      flagCode:'DE',flagImageBase64:'aGVsbG8=',chapters:const [],
    );
    final decoded=Course.fromJson(course.toJson());
    expect(decoded.flagCode,'DE');
    expect(decoded.flagImageBase64,'aGVsbG8=');
  });

  test('choice correctness is stored by stable Item ID',(){
    final ex=Exercise(id:'x',type:'choice',prompt:'',question:'Q',answers:const ['a','b'],correct:1,tts:null,accepted:const [],tokens:const [],orderAnswer:const [],pairs:const [],hint:'',icons:const []);
    expect(ex.interaction.kind,'select');
    expect(ex.evaluation.kind,'selected_items');
    expect(ex.evaluation.correctItemIds,[ex.interaction.items[1].id]);
  });

  test('topic intro Content is not exposed as a runnable exercise',(){
    final round=LearningRound(id:'r',title:'Round',content:[
      const LearningContent(id:'intro',kind:'explanation',required:false,role:'topic_intro',text:'Read the Topic Guidebook for more.'),
      LearningContent.fromExercise(Exercise(id:'x',type:'choice',prompt:'',question:'Q',answers:const ['a','b'],correct:0,tts:null,accepted:const [],tokens:const [],orderAnswer:const [],pairs:const [],hint:'',icons:const [])),
    ]);
    expect(round.content,hasLength(2));
    expect(round.exercises,hasLength(1));
    expect(round.exercises.single.id,'x');
  });

  test('flashcard serializes as Presentation Content',(){
    final ex=Exercise(id:'f',type:'flashcard',prompt:'ciao',question:'hello',answers:const [],correct:null,tts:'ciao',accepted:const [],tokens:const [],orderAnswer:const [],pairs:const [],hint:'',icons:const []);
    final content=LearningContent.fromExercise(ex);
    expect(content.kind,'presentation');
    expect(content.presentation?.actions,containsAll(['understood','review_later']));
  });
}
