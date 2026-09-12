import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/avatar_settings_screen.dart';
import 'package:quisquislingo_app/screens/new_learner_flow_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/learner_status_level_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/status_service.dart';
import 'package:quisquislingo_app/widgets/learner_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _learnerId = '00000000-0000-4000-8000-000000000233';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('authoritative Status levels retain their vivid shirt colors', () {
    expect(StatusService.names, const [
      'Apprentice',
      'Wanderer',
      'Squire',
      'Wordsmith',
      'Knight',
      'Lorekeeper',
      'Language Wizard',
      'Grand Master',
      'Sage',
      'Guru',
    ]);
    expect(StatusService.colorValues, const [
      0xFF2EAD5B,
      0xFF7AC943,
      0xFFF2C230,
      0xFFF28C28,
      0xFFE85D4A,
      0xFFD83A56,
      0xFFC044A4,
      0xFF8E5AC8,
      0xFF5964D8,
      0xFF2878D0,
    ]);
    expect(
      LearnerAvatarPainter(9, 'medium', 'dark').shirtColor,
      const Color(0xFF2878D0),
    );
  });

  test(
    'Status changes automatically produce the corresponding shirt color',
    () async {
      final profiles = ProfileService(
        idGenerator: () => _learnerId,
        randomIndex: (_) => 0,
      );
      await profiles.createProfile('Progress learner');
      final progress = ProgressService(now: () => DateTime(2026, 9, 12));
      final levels = LearnerStatusLevelService(progressService: progress);

      await progress.addXp(6499, courseCode: 'IT', courseId: 'course-a');
      final apprentice = await levels.rankForActiveLearner(
        courseId: 'course-a',
        courseCode: 'IT',
      );
      await profiles.setSkinTone('dark');
      await profiles.setHairTone('light');
      await progress.addXp(1, courseCode: 'IT', courseId: 'course-a');
      final wanderer = await levels.rankForActiveLearner(
        courseId: 'course-a',
        courseCode: 'IT',
      );

      expect(apprentice.name, 'Apprentice');
      expect(wanderer.name, 'Wanderer');
      expect(
        LearnerAvatarPainter(apprentice.index, 'dark', 'light').shirtColor,
        const Color(0xFF2EAD5B),
      );
      expect(
        LearnerAvatarPainter(wanderer.index, 'dark', 'light').shirtColor,
        const Color(0xFF7AC943),
      );
      expect(await progress.getXp(courseCode: 'IT'), 6500);
    },
  );

  testWidgets(
    'Avatar Customization presents current Status help and no shirt control',
    (tester) async {
      final profiles = ProfileService(
        idGenerator: () => _learnerId,
        randomIndex: (_) => 0,
      );
      await profiles.createProfile('Existing learner');
      final progress = ProgressService(now: () => DateTime(2026, 9, 12));
      await progress.addXp(6500, courseCode: 'IT', courseId: 'course-a');

      await tester.pumpWidget(
        MaterialApp(
          home: AvatarSettingsScreen(
            course: _course,
            profileService: profiles,
            statusLevelService: LearnerStatusLevelService(
              progressService: progress,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current Status: Wanderer'), findsOneWidget);
      expect(find.byKey(const Key('status-level-current-1')), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(5));
      expect(find.text('T-shirt color'), findsNothing);
      final preview = tester.widget<LearnerAvatar>(
        find.byKey(const Key('avatar-live-preview')),
      );
      expect(preview.level, 1);

      await tester.tap(find.byKey(const Key('status-level-help')));
      await tester.pumpAndSettle();
      expect(find.text('How Status works'), findsWidgets);
      expect(find.text(StatusService.progressionExplanation), findsOneWidget);
    },
  );

  testWidgets(
    'new learner creation has two steps and customizes one stable identity',
    (tester) async {
      final randomValues = [2, 0].iterator;
      final profiles = ProfileService(
        idGenerator: () => _learnerId,
        randomIndex: (_) {
          randomValues.moveNext();
          return randomValues.current;
        },
      );
      LearnerProfile? completed;

      await tester.pumpWidget(
        MaterialApp(
          home: NewLearnerFlowScreen(
            profileService: profiles,
            canCancel: true,
            onComplete: (profile) => completed = profile,
          ),
        ),
      );

      expect(find.text('Create Profile'), findsWidgets);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('new-learner-screen-name')),
        'Stable learner',
      );
      await tester.enterText(
        find.byKey(const Key('new-learner-discord')),
        'stable_handle',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Avatar Customization'), findsOneWidget);
      expect(find.text('Step 2 of 2'), findsOneWidget);
      expect(find.text('Current Status: Apprentice'), findsOneWidget);
      expect(find.byKey(const Key('status-level-current-0')), findsOneWidget);
      for (var index = 0; index < StatusService.names.length; index++) {
        expect(find.text(StatusService.names[index]), findsOneWidget);
        expect(find.byKey(Key('status-level-color-$index')), findsOneWidget);
      }
      final created = await profiles.getProfileRecords();
      expect(created, hasLength(1));
      expect(created.single.learnerProfileId, _learnerId);
      expect(created.single.displayName, 'Stable learner');
      expect(created.single.discordHandle, '@stable_handle');
      expect(
        await profiles.getAvatarAppearanceForProfile(_learnerId),
        isA<ProfileAvatarAppearance>()
            .having((value) => value.skinTone, 'initial skin', 'dark')
            .having((value) => value.hairTone, 'initial hair', 'light'),
      );

      await tester.tap(find.byKey(const Key('avatar-skin-light')));
      await tester.tap(find.byKey(const Key('avatar-hair-dark')));
      await tester.scrollUntilVisible(
        find.text('Done'),
        500,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      expect(completed?.learnerProfileId, _learnerId);
      expect(await profiles.getProfileRecords(), hasLength(1));
      expect(
        await profiles.getAvatarAppearanceForProfile(_learnerId),
        isA<ProfileAvatarAppearance>()
            .having((value) => value.skinTone, 'chosen skin', 'light')
            .having((value) => value.hairTone, 'chosen hair', 'dark'),
      );
    },
  );
}

final _course = Course(
  courseId: 'course-a',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'QQL 233 Status Course',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  lessons: const [],
);
