import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';

void main(){
  test('recorded audio segmentation prefers longest expression',(){
    final service=RecordedAudioService();
    const clips=[CourseAudioClip(id:'1',text:'buon',filePath:'a.mp3'),CourseAudioClip(id:'2',text:'buon giorno',filePath:'b.mp3'),CourseAudioClip(id:'3',text:'a tutti',filePath:'c.mp3')];
    final result=service.segment('Buon giorno a tutti',clips);
    expect(result?.map((e)=>e.id).toList(),['2','3']);
  });
  test('recorded audio segmentation fails when a word is uncovered',(){
    final service=RecordedAudioService();
    const clips=[CourseAudioClip(id:'1',text:'buongiorno',filePath:'a.mp3')];
    expect(service.segment('buongiorno a tutti',clips),isNull);
  });
}
