import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled course registry includes Spanish', () {
    expect(CourseService.hasCourse('ES'), isTrue);
    expect(CourseService.hasCourse('es'), isTrue);
    expect(CourseService.courseAssets['ES'], 'assets/courses/spanish_en.json');
  });

  test('bundled course registry includes English from Spanish', () {
    expect(CourseService.hasCourse('EN'), isTrue);
    expect(CourseService.courseAssets['EN'], 'assets/courses/english_es.json');
  });

  test('empty authoring course shells are registered explicitly', () {
    expect(CourseService.hasCourse('NL'), isTrue);
    expect(CourseService.hasCourse('CY'), isTrue);
    expect(CourseService.hasCourse('PT'), isTrue);
    expect(CourseService.hasCourse('FI'), isTrue);
    expect(CourseService.courseAssets['FI'], 'assets/courses/finnish_en.json');
  });

  test('unknown language is not silently mapped to Italian', () {
    expect(CourseService.hasCourse('ZZ'), isFalse);
  });
}
