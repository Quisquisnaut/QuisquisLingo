import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';

void main(){
  test('course author reads legacy role and writes multi-role metadata',(){
    final legacy=CourseAuthor.fromJson({'name':'A','role':'Course Creator'});
    expect(legacy.roles,['Course Creator']);
    final author=CourseAuthor(name:'A',roles:const ['Course Creator','Team Leader','Custom role']);
    final json=author.toJson();
    expect(json['roles'],['Course Creator','Team Leader','Custom role']);
    expect(json['role'],'Course Creator, Team Leader, Custom role');
  });

  test('chapter editor notes and Topic Guidebook round-trip independently',(){
    final chapter=Chapter.fromJson({
      'id':'c1','title':'One','requiredTopics':1,
      'topics':[
        {'id':'t1','title':'Topic','role':'learning','guidebook':{'content':[{'id':'g1','kind':'explanation','required':false,'role':'overview','text':'Learner text'}]},'rounds':[]},
        {'id':'d1','title':'Language Duel','role':'assessment','assessment':{'purpose':'skip_test'},'rounds':[]},
      ],
      'editorNotes':'Internal note',
    });
    expect(chapter.editorNotes,'Internal note');
    expect(chapter.learningTopics.single.guidebook.overview,'Learner text');
    expect(chapter.toJson()['editorNotes'],'Internal note');
    expect(chapter.toJson().containsKey('guidebook'),isFalse);
  });
}
