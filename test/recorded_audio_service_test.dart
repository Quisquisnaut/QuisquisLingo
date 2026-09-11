import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';

void main() {
  test('recorded audio storage is contained and Course-ID specific', () {
    final unsafe = RecordedAudioService.storageDirectoryForCourseId(
      r'..\..\outside',
    );
    final other = RecordedAudioService.storageDirectoryForCourseId('outside');

    expect(unsafe, matches(RegExp(r'^course_[0-9a-f]{64}$')));
    expect(unsafe, isNot(other));
    expect(unsafe, isNot(contains('..')));
    expect(unsafe, isNot(contains('/')));
    expect(unsafe, isNot(contains(r'\')));
    expect(
      () => RecordedAudioService.storageDirectoryForCourseId('  '),
      throwsArgumentError,
    );
  });

  test('recorded audio segmentation prefers longest expression', () {
    final service = RecordedAudioService();
    const clips = [
      CourseAudioClip(id: '1', text: 'buon', filePath: 'a.mp3'),
      CourseAudioClip(id: '2', text: 'buon giorno', filePath: 'b.mp3'),
      CourseAudioClip(id: '3', text: 'a tutti', filePath: 'c.mp3'),
    ];
    final result = service.segment('Buon giorno a tutti', clips);
    expect(result?.map((e) => e.id).toList(), ['2', '3']);
  });
  test('recorded audio segmentation fails when a word is uncovered', () {
    final service = RecordedAudioService();
    const clips = [
      CourseAudioClip(id: '1', text: 'buongiorno', filePath: 'a.mp3'),
    ];
    expect(service.segment('buongiorno a tutti', clips), isNull);
  });

  test('recorded audio segmentation preserves Korean letters', () {
    final service = RecordedAudioService();
    const clips = [
      CourseAudioClip(id: '1', text: '안녕하세요', filePath: 'hello.mp3'),
      CourseAudioClip(id: '2', text: '친구', filePath: 'friend.mp3'),
    ];

    expect(service.segment('“안녕하세요!” 친구.', clips)?.map((clip) => clip.id), [
      '1',
      '2',
    ]);
  });

  test('recorded audio segmentation preserves combining-mark scripts', () {
    final service = RecordedAudioService();
    const decomposedCafe = 'cafe\u0301';
    const clips = [
      CourseAudioClip(id: '1', text: decomposedCafe, filePath: 'cafe.mp3'),
      CourseAudioClip(id: '2', text: 'हेलो', filePath: 'hello-hi.mp3'),
    ];

    expect(service.segment('($decomposedCafe)', clips)?.single.id, '1');
    expect(service.segment('「हेलो」', clips)?.single.id, '2');
  });
}
