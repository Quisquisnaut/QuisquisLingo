import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/avatar_settings_screen.dart';
import 'package:quisquislingo_app/screens/new_learner_flow_screen.dart';
import 'package:quisquislingo_app/screens/profile_screen.dart';
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
      expect(
        find.text('Each level has its own T-shirt color.'),
        findsOneWidget,
      );
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
        numericSuffixGenerator: () => 12345,
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
      await tester.enterText(
        find.byKey(const Key('new-learner-access-pin')),
        '2468',
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
      expect(created.single.displayName, 'Stable learner 12345');
      expect(created.single.screenNameSuffix, '12345');
      expect(created.single.discordHandle, '@stable_handle');
      expect(await profiles.verifyAccessPin(_learnerId, '2468'), isTrue);
      expect(await profiles.verifyAccessPin(_learnerId, '1357'), isFalse);
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

  testWidgets(
    'Create Profile warns for invalid Discord usernames and can continue',
    (tester) async {
      final profiles = ProfileService(
        idGenerator: () => _learnerId,
        numericSuffixGenerator: () => 23456,
        randomIndex: (_) => 0,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: NewLearnerFlowScreen(
            profileService: profiles,
            canCancel: true,
            onComplete: (_) {},
          ),
        ),
      );

      expect(
        find.byTooltip(
          'Enter your Discord username, not your Discord display name.',
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('new-learner-screen-name')),
        'Warning Learner',
      );
      await tester.enterText(
        find.byKey(const Key('new-learner-discord')),
        'test..test',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('This does not appear to be a valid Discord username.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Edit username'));
      await tester.pumpAndSettle();
      expect(find.text('Create Profile'), findsWidgets);
      expect(await profiles.getProfileRecords(), isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue anyway'));
      await tester.pumpAndSettle();
      final created = (await profiles.getProfileRecords()).single;
      expect(created.displayName, 'Warning Learner 23456');
      expect(created.discordHandle, '@test..test');
      expect(find.text('Avatar Customization'), findsOneWidget);
    },
  );

  testWidgets('Create Profile visibly replaces a colliding generated suffix', (
    tester,
  ) async {
    var nextId = 0;
    final suffixes = [12345, 67890].iterator;
    final profiles = ProfileService(
      idGenerator: () => [_otherLearnerId, _learnerId][nextId++],
      numericSuffixGenerator: () {
        suffixes.moveNext();
        return suffixes.current;
      },
      randomIndex: (_) => 0,
    );
    await profiles.addProfile('Collision Learner 12345');
    await tester.pumpWidget(
      MaterialApp(
        home: NewLearnerFlowScreen(
          profileService: profiles,
          canCancel: true,
          onComplete: (_) {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('new-learner-screen-name')),
      'Collision Learner',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Create Profile'), findsWidgets);
    expect(
      find.textContaining('A new five-digit suffix was generated'),
      findsOneWidget,
    );
    expect(find.text(' 67890'), findsOneWidget);
    expect(await profiles.getProfileRecords(), hasLength(1));

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Avatar Customization'), findsOneWidget);
    expect(
      (await profiles.getProfileById(_learnerId))!.displayName,
      'Collision Learner 67890',
    );
  });

  testWidgets(
    'Edit Profile warns without blocking and retains its immutable suffix',
    (tester) async {
      final profiles = ProfileService(
        idGenerator: () => _learnerId,
        numericSuffixGenerator: () => 34567,
        randomIndex: (_) => 0,
      );
      await profiles.createProfile('Original Learner');
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            course: _course,
            profileService: profiles,
            onManageLearners: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('profile-identity-link')),
      );
      await tester.tap(find.byKey(const Key('profile-identity-link')));
      await tester.pumpAndSettle();

      expect(
        find.byTooltip(
          'Enter your Discord username, not your Discord display name.',
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('edit-profile-screen-name')),
        'Renamed Learner',
      );
      await tester.enterText(
        find.byKey(const Key('edit-profile-discord')),
        '@@invalid',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('This does not appear to be a valid Discord username.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue anyway'));
      await tester.pumpAndSettle();

      final renamed = await profiles.getProfileById(_learnerId);
      expect(renamed!.displayName, 'Renamed Learner 34567');
      expect(renamed.screenNameSuffix, '34567');
      expect(renamed.discordHandle, '@invalid');
    },
  );

  testWidgets('Edit Profile warns but permits a duplicate complete name', (
    tester,
  ) async {
    var nextSuffix = 45678;
    final profiles = ProfileService(
      idGenerator: () => (nextSuffix == 45678 ? _learnerId : _otherLearnerId),
      numericSuffixGenerator: () {
        final value = nextSuffix;
        nextSuffix += 11111;
        return value;
      },
      randomIndex: (_) => 0,
    );
    final first = await profiles.createProfile('Duplicate Learner');
    final second = await profiles.createProfile('Other Learner');
    await profiles.replaceProfileRecord(
      LearnerProfile(
        learnerProfileId: second.learnerProfileId,
        displayName: first.displayName,
        screenNameSuffix: first.screenNameSuffix,
      ),
    );
    await profiles.setActiveProfileById(first.learnerProfileId);

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          course: _course,
          profileService: profiles,
          onManageLearners: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-identity-link')));
    await tester.tap(find.byKey(const Key('profile-identity-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('A user with this Screen Name already exists.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Edit name'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-profile-screen-name')), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue anyway'));
    await tester.pumpAndSettle();
    expect(
      (await profiles.getProfileById(first.learnerProfileId))!.displayName,
      first.displayName,
    );
  });
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

const _otherLearnerId = '22222222-2222-4222-8222-222222222222';
