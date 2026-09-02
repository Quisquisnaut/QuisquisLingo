import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/world_flag_entity.dart';
import 'package:quisquislingo_app/services/flag_game_score_service.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('higher score then faster time replaces a learner best', () async {
    final profiles = ProfileService(idGenerator: () => _id(1));
    await profiles.createProfile('Player');
    final service = FlagGameScoreService(
      profileService: profiles,
      now: () => DateTime(2026, 9, 2, 12),
    );

    expect(
      await service.recordResult(
        mode: FlagGameMode.iso,
        score: 8,
        elapsedTime: const Duration(seconds: 20),
      ),
      isTrue,
    );
    expect(
      await service.recordResult(
        mode: FlagGameMode.iso,
        score: 7,
        elapsedTime: const Duration(seconds: 10),
      ),
      isFalse,
    );
    expect(
      await service.recordResult(
        mode: FlagGameMode.iso,
        score: 8,
        elapsedTime: const Duration(seconds: 21),
      ),
      isFalse,
    );
    expect(
      await service.recordResult(
        mode: FlagGameMode.iso,
        score: 8,
        elapsedTime: const Duration(seconds: 19),
      ),
      isTrue,
    );
    final best = await service.getBestForActive(FlagGameMode.iso);
    expect(best?.score, 8);
    expect(best?.elapsedTime, const Duration(seconds: 19));
  });

  test('same score and time keeps the earlier record', () async {
    final profiles = ProfileService(idGenerator: () => _id(1));
    await profiles.createProfile('Player');
    final service = FlagGameScoreService(profileService: profiles);
    final earlier = DateTime(2026, 9, 2, 12);
    final later = earlier.add(const Duration(minutes: 1));

    await service.recordResult(
      mode: FlagGameMode.unMembers,
      score: 10,
      elapsedTime: const Duration(seconds: 15),
      achievedAt: earlier,
    );
    expect(
      await service.recordResult(
        mode: FlagGameMode.unMembers,
        score: 10,
        elapsedTime: const Duration(seconds: 15),
        achievedAt: later,
      ),
      isFalse,
    );
    expect(
      (await service.getBestForActive(FlagGameMode.unMembers))?.achievedAt,
      earlier,
    );
  });

  test('existing stable-mode best records remain readable', () async {
    final profiles = ProfileService(idGenerator: () => _id(1));
    final profile = await profiles.createProfile('Existing');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      profiles.keyForProfileId(
        profile.learnerProfileId,
        '${FlagGameScoreService.keyPrefix}isoPlusShortlist',
      ),
      jsonEncode({
        'learnerProfileId': profile.learnerProfileId,
        'mode': 'isoPlusShortlist',
        'score': 9,
        'elapsedMilliseconds': 38400,
        'achievedAt': '2026-09-02T12:00:00.000',
      }),
    );

    final best = await FlagGameScoreService(
      profileService: profiles,
    ).getBestForActive(FlagGameMode.isoPlusShortlist);
    expect(best?.score, 9);
    expect(best?.elapsedTime, const Duration(milliseconds: 38400));
    expect(best?.achievedAt, DateTime(2026, 9, 2, 12));
  });

  test(
    'ranking uses score, time, achievedAt and limits each mode to five',
    () async {
      final profiles = ProfileService();
      final service = FlagGameScoreService(profileService: profiles);
      final base = DateTime(2026, 9, 2, 12);
      final inputs = [
        ('A', 11, 18, 0),
        ('B', 12, 30, 0),
        ('C', 11, 15, 2),
        ('D', 11, 15, 1),
        ('E', 9, 10, 0),
        ('F', 8, 9, 0),
      ];
      for (var index = 0; index < inputs.length; index++) {
        final input = inputs[index];
        final profile = await profiles.createProfile(
          input.$1,
          learnerProfileId: _id(index + 1),
        );
        await profiles.setActiveProfileById(profile.learnerProfileId);
        await service.recordResult(
          mode: FlagGameMode.allFlags,
          score: input.$2,
          elapsedTime: Duration(seconds: input.$3),
          achievedAt: base.add(Duration(minutes: input.$4)),
        );
      }

      final top = await service.getTopPlayers(FlagGameMode.allFlags);
      expect(top, hasLength(5));
      expect(top.map((entry) => entry.displayName), ['B', 'D', 'C', 'A', 'E']);
    },
  );

  test('duplicate display names remain separate by learnerProfileId', () async {
    final profiles = ProfileService();
    final service = FlagGameScoreService(profileService: profiles);
    for (var index = 1; index <= 2; index++) {
      final profile = await profiles.createProfile(
        'Marco',
        learnerProfileId: _id(index),
      );
      await profiles.setActiveProfileById(profile.learnerProfileId);
      await service.recordResult(
        mode: FlagGameMode.isoPlusShortlist,
        score: 8 + index,
        elapsedTime: Duration(seconds: 20 - index),
        achievedAt: DateTime(2026, 9, 2, 12, index),
      );
    }

    final top = await service.getTopPlayers(FlagGameMode.isoPlusShortlist);
    expect(top, hasLength(2));
    expect(top.map((entry) => entry.displayName), everyElement('Marco'));
    expect(top.map((entry) => entry.learnerProfileId).toSet(), hasLength(2));
  });

  test('the four gameplay modes maintain independent records', () async {
    final profiles = ProfileService(idGenerator: () => _id(1));
    await profiles.createProfile('Modes');
    final service = FlagGameScoreService(profileService: profiles);
    for (var index = 0; index < FlagGameMode.values.length; index++) {
      await service.recordResult(
        mode: FlagGameMode.values[index],
        score: index + 1,
        elapsedTime: Duration(seconds: 20 + index),
        achievedAt: DateTime(2026, 9, 2, 12, index),
      );
    }

    final scorecard = await service.getScorecard();
    expect(scorecard.keys.toSet(), FlagGameMode.values.toSet());
    for (var index = 0; index < FlagGameMode.values.length; index++) {
      expect(scorecard[FlagGameMode.values[index]]!.single.score, index + 1);
    }
  });

  test(
    'separate-copy backup rewrites only Flag Game learner identity',
    () async {
      final ids = [_id(1), _id(2)].iterator;
      final profiles = ProfileService(
        idGenerator: () {
          ids.moveNext();
          return ids.current;
        },
      );
      final original = await profiles.createProfile('Original');
      final scores = FlagGameScoreService(profileService: profiles);
      await scores.recordResult(
        mode: FlagGameMode.iso,
        score: 10,
        elapsedTime: const Duration(seconds: 12),
        achievedAt: DateTime(2026, 9, 2, 12),
      );
      final backup = LearnerBackupService(profileService: profiles);
      final exported = await backup.exportActiveProfile();
      final document = backup.decodeDocument(utf8.encode(jsonEncode(exported)));

      final copy = await backup.importAsSeparateCopy(
        document,
        displayName: 'Original',
      );
      expect(copy.learnerProfileId, isNot(original.learnerProfileId));
      final copiedBest = await scores.getBestForActive(FlagGameMode.iso);
      expect(copiedBest?.learnerProfileId, copy.learnerProfileId);
      expect(copiedBest?.score, 10);
      expect(
        (await scores.getTopPlayers(
          FlagGameMode.iso,
        )).map((entry) => entry.learnerProfileId).toSet(),
        {original.learnerProfileId, copy.learnerProfileId},
      );
    },
  );

  test(
    'invalid scores and no-active writes create no synthetic data',
    () async {
      final service = FlagGameScoreService();
      expect(
        () => service.recordResult(
          mode: FlagGameMode.iso,
          score: 13,
          elapsedTime: Duration.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.recordResult(
          mode: FlagGameMode.iso,
          score: 1,
          elapsedTime: Duration.zero,
        ),
        throwsStateError,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((key) => key.contains('flag_game_best_')),
        isEmpty,
      );
    },
  );
}

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
