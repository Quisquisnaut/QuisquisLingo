import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_catalogs.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_en.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/course_info_update_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/language_catalog.dart';
import 'package:quisquislingo_app/widgets/language_field.dart';

/// Build 260 Revision 0 (owner decisions of 1 October 2026): the Course
/// languages come from a list (English names and tags) or are typed by hand;
/// the learner panel's lines are in the base language when QQL has it
/// (English, Spanish, Italian, German, Portuguese, Dutch, French) and name
/// the languages in that language; Course Info may only add the tags of a
/// Course's own languages.

const _maintainer = '11111111-1111-4111-8111-111111111111';

Course _course({
  String source = 'English',
  String target = 'Italian',
  String sourceTag = '',
  String targetTag = '',
  String learnerName = '',
}) => Course(
  courseId: 'languages-260',
  originType: CourseOriginType.custom,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _maintainer,
    displayName: 'Author',
  ),
  maintainer: const CourseMaintainer(_maintainer),
  originalCreatedAtUtc: '2026-10-01T00:00:00.000Z',
  learningLanguage: target,
  interfaceLanguage: source,
  sourceLanguage: source,
  targetLanguage: target,
  sourceLanguageTag: sourceTag,
  targetLanguageTag: targetTag,
  targetLanguageNameForLearners: learnerName,
  title: 'Languages',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

/// A Type the translation exercise whose text is in [language].
Exercise _translation(TextLanguage language) => Exercise.canonical(
  id: 'translate',
  publicationState: PublicationState.published,
  primitive: ExercisePrimitive.input,
  promptElements: [
    PromptElement(
      type: 'text',
      text: 'ciao',
      role: 'primary',
      language: language,
    ),
  ],
  canonicalEvaluation: const CanonicalEvaluation(
    mode: EvaluationMode.expression,
    answers: ['hello'],
  ),
  updatedAt: DateTime.utc(2026, 10, 1),
);

String _line(Course course, TextLanguage promptLanguage) =>
    ExerciseCopyService.instructionForExercise(
      course,
      _translation(promptLanguage),
    );

void main() {
  group('the language list', () {
    test('holds the ISO 639-1 languages and the curated regional ones', () {
      final tags = LanguageCatalog.entries.map((entry) => entry.tag).toList();
      expect(tags.length, greaterThan(220));
      expect(tags.toSet(), hasLength(tags.length));
      for (final tag in ['it', 'en', 'zh', 'nap', 'pms', 'vec', 'scn', 'fur']) {
        expect(LanguageCatalog.byTag(tag), isNotNull, reason: tag);
      }
      expect(LanguageCatalog.byTag('nap')!.englishName, 'Neapolitan');
    });

    test('recognizes tags, English names and other names', () {
      expect(LanguageCatalog.resolve('Italiano')?.tag, 'it');
      expect(LanguageCatalog.resolve('ITALIAN')?.tag, 'it');
      expect(LanguageCatalog.resolve('Español')?.tag, 'es');
      expect(LanguageCatalog.resolve('espanol')?.tag, 'es');
      expect(LanguageCatalog.resolve('Piemontèis')?.tag, 'pms');
      expect(LanguageCatalog.resolve('napoletano')?.tag, 'nap');
      expect(LanguageCatalog.resolve('tedesco')?.tag, 'de');
      expect(LanguageCatalog.resolve('nap')?.tag, 'nap');
      // An English name wins a clash: Ladino is Judeo-Spanish.
      expect(LanguageCatalog.resolve('Ladino')?.tag, 'lad');
      expect(LanguageCatalog.resolve('Klingon'), isNull);
      expect(LanguageCatalog.byTag('pt-BR')?.tag, 'pt');
      expect(LanguageCatalog.isValidTag('zh-Hant'), isTrue);
      expect(LanguageCatalog.isValidTag('it_IT!'), isFalse);
      expect(LanguageCatalog.search('neapo').map((e) => e.tag), ['nap']);
    });

    test('names common languages in the seven instruction languages', () {
      expect(LanguageCatalog.nameIn('it', 'de'), 'tedesco');
      expect(LanguageCatalog.nameIn('es', 'it'), 'italiano');
      expect(LanguageCatalog.nameIn('de', 'pms'), 'Piemontesisch');
      expect(LanguageCatalog.nameIn('fr', 'nb'), 'norvégien');
      expect(LanguageCatalog.nameIn('it', 'tpi'), isNull);
      expect(LanguageCatalog.nameIn('fi', 'it'), isNull);
    });
  });

  group('the learner lines', () {
    test('every instruction catalog has every English key', () {
      expect(exerciseCopyCatalogs.keys.toSet(), {
        'en',
        'es',
        'it',
        'de',
        'pt',
        'nl',
        'fr',
      });
      for (final MapEntry(key: language, value: catalog)
          in exerciseCopyCatalogs.entries) {
        expect(
          exerciseCopyEn.keys.where((key) => !catalog.containsKey(key)),
          isEmpty,
          reason: '$language lacks these keys',
        );
      }
    });

    test('follow the base language, recognized by tag or by name', () {
      String select(Course course) =>
          ExerciseCopyService.instruction(course, LearnerExerciseKind.select);
      expect(select(_course()), 'Find the correct answer.');
      expect(
        select(_course(source: 'Español')),
        'Encuentra la respuesta correcta.',
      );
      expect(
        select(_course(source: 'French', sourceTag: 'fr')),
        'Trouve la bonne réponse.',
      );
      // Finnish and Welsh left the instruction languages: English lines.
      expect(select(_course(source: 'Finnish')), 'Find the correct answer.');
      expect(
        select(_course(source: 'Welsh', sourceTag: 'cy')),
        'Find the correct answer.',
      );
    });

    test('name the language of the answer in the base language', () {
      final spanish = _course(source: 'Español', target: 'Italian');
      expect(_line(spanish, TextLanguage.source), 'Traduce al italiano.');
      expect(_line(spanish, TextLanguage.target), 'Traduce al español.');
      expect(
        _line(
          _course(source: 'Italian', target: 'Neapolitan', targetTag: 'nap'),
          TextLanguage.source,
        ),
        'Traduci in napoletano.',
      );
      expect(
        _line(_course(source: 'French', target: 'German'), TextLanguage.source),
        'Traduis en allemand.',
      );
      // A language QQL does not name in Italian keeps its English name.
      expect(
        _line(
          _course(source: 'Italian', target: 'Tok Pisin', targetTag: 'tpi'),
          TextLanguage.source,
        ),
        'Traduci in Tok Pisin.',
      );
      // A language typed by hand keeps the name the Course writes.
      expect(
        _line(_course(target: 'Klingon'), TextLanguage.source),
        'Translate into Klingon.',
      );
      // The Course's own name for learners wins.
      expect(
        _line(
          _course(
            source: 'Spanish',
            target: 'Neapolitan',
            targetTag: 'nap',
            learnerName: 'napulitano',
          ),
          TextLanguage.source,
        ),
        'Traduce al napulitano.',
      );
    });
  });

  group('Course Info only adds the tags of the Course languages', () {
    CourseInfoChange change(
      Course course, {
      String? sourceTag,
      String? targetTag,
      String learnerName = '',
    }) => (
      title: course.title,
      authors: course.authors,
      rightsHolders: course.rightsHolders,
      mediaAttributions: course.mediaAttributions,
      license: course.license,
      derivativePolicy: course.derivativeWorksPolicy,
      allowPageSharing: course.allowPageSharing,
      privateCourse: course.temporarySample,
      sourceLanguageTag: sourceTag ?? course.sourceLanguageTag,
      targetLanguageTag: targetTag ?? course.targetLanguageTag,
      targetLanguageNameForLearners: learnerName,
      variant: course.languageVariant,
      startLevel: course.startLevel,
      targetLevel: course.targetLevel,
      description: course.courseDescription,
      buyACoffeeUrl: course.buyACoffeeUrl,
      estimatedStudyHours: course.estimatedStudyHours,
      minimumAge: course.minimumAge,
      keywords: course.keywords,
      publisherContact: course.publisherContact,
      minimumAppBuild: course.minimumAppBuild,
      flagCode: course.flagCode,
      flagImageBase64: course.flagImageBase64,
      worldFlagId: course.worldFlagId,
      coverImage: course.coverImage,
      maintainerProfileId: course.maintainer!.profileId,
      assignedTeamId: course.assignedTeamId,
    );

    test('adds the matching tags and the learners\' name', () async {
      final earlier = _course(source: 'Español', target: 'Italiano');
      final updated = (await CourseInfoUpdateService().apply(
        earlier,
        change(
          earlier,
          sourceTag: 'es',
          targetTag: 'it',
          learnerName: 'italiano',
        ),
        _maintainer,
      )).course;
      expect(updated.sourceLanguageTag, 'es');
      expect(updated.targetLanguageTag, 'it');
      expect(updated.targetLanguage, 'Italiano');
      expect(updated.targetLanguageNameForLearners, 'italiano');
      expect(updated.toJson()['targetLanguageNameForLearners'], 'italiano');
    });

    test('refuses another language, a changed tag or a moved code', () async {
      final service = CourseInfoUpdateService();
      final english = _course();
      await expectLater(
        service.apply(english, change(english, sourceTag: 'fr'), _maintainer),
        throwsArgumentError,
      );
      final tagged = _course(targetTag: 'it');
      await expectLater(
        service.apply(tagged, change(tagged, targetTag: 'de'), _maintainer),
        throwsArgumentError,
      );
      // A name QQL does not know may gain a tag only if XP keeps its code
      // (here IT, from the voice it-IT).
      final unknown = _course(target: 'Kiliwa');
      await expectLater(
        service.apply(unknown, change(unknown, targetTag: 'de'), _maintainer),
        throwsArgumentError,
      );
    });
  });

  group('the language field', () {
    testWidgets('recognizes a listed language and keeps a typed one', (
      tester,
    ) async {
      final controller = LanguageFieldController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageField(
              controller: controller,
              label: 'Target language *',
              keyPrefix: 'target',
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('target')), 'Italiano');
      await tester.pump();
      expect(find.text('Italian · it'), findsOneWidget);
      expect(controller.choice?.name, 'Italian');
      expect(controller.choice?.tag, 'it');
      expect(find.byKey(const Key('target-tag')), findsNothing);

      await tester.enterText(find.byKey(const Key('target')), 'Klingon');
      await tester.pump();
      expect(find.byKey(const Key('target-tag')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('target-tag')), 'tlh!');
      await tester.pump();
      expect(controller.choice, isNull);
      await tester.enterText(find.byKey(const Key('target-tag')), 'tlh');
      await tester.pump();
      expect(controller.choice?.name, 'Klingon');
      expect(controller.choice?.tag, 'tlh');

      await tester.tap(find.byKey(const Key('target-list')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('language-picker-search')),
        'neapo',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('language-picker-nap')));
      await tester.pumpAndSettle();
      expect(controller.choice?.name, 'Neapolitan');
      expect(controller.choice?.tag, 'nap');
    });
  });
}
