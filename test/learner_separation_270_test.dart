import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _parent = '10000000-0000-4000-8000-000000000001';
const _child = '20000000-0000-4000-8000-000000000002';
const _newcomer = '30000000-0000-4000-8000-000000000003';

// Build 270 Revision 1 (audit item 2, owner threat model: a PIN that is set
// must not be bypassed with ordinary taps). Before, a parent who switched to
// a child stayed unlocked, and the child could restore a backup naming the
// parent ("Replace existing"): the parent's data was replaced and the child
// became the parent without the PIN.
void main() {
  late ProfileService profiles;
  late LearnerBackupService backup;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProfileService.beginAccessSession();
    final ids = [_parent, _child].iterator;
    profiles = ProfileService(
      idGenerator: () {
        ids.moveNext();
        return ids.current;
      },
    );
    await profiles.createProfile('Parent', accessPin: '4321');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '${ProfileService.prefixForProfileId(_parent)}xp_IT',
      500,
    );
    // The parent adds the child, who becomes the active learner.
    await profiles.createProfile('Child');
    backup = LearnerBackupService(profileService: profiles);
  });

  LearnerBackupDocument documentFor(String id, String name) =>
      LearnerBackupDocument(
        schemaVersion: LearnerBackupService.schemaVersion,
        learnerProfileId: id,
        displayName: name,
        data: const {'xp_IT': 1},
      );

  Future<int?> parentXp() async => (await SharedPreferences.getInstance())
      .getInt('${ProfileService.prefixForProfileId(_parent)}xp_IT');

  test('a learner left with a switch is locked again', () async {
    expect(await profiles.getActiveProfileId(), _child);
    // Whatever sets the active learner afterwards cannot bring the parent
    // back without the PIN.
    await (await SharedPreferences.getInstance()).setString(
      ProfileService.activeProfileIdKey,
      _parent,
    );
    expect(await profiles.getActiveProfileId(), isNull);
  });

  test('replacing another learner who has a PIN needs that PIN', () async {
    expect(await backup.replacingNeedsPin(_parent), isTrue);
    for (final pin in [null, '0000']) {
      await expectLater(
        backup.restorePreservingIdentity(
          documentFor(_parent, 'Parent'),
          replaceExisting: true,
          accessPin: pin,
        ),
        throwsA(isA<ProfilePinException>()),
      );
      expect(await parentXp(), 500, reason: 'nothing replaced');
      expect(await profiles.getActiveProfileId(), _child);
    }

    await backup.restorePreservingIdentity(
      documentFor(_parent, 'Parent'),
      replaceExisting: true,
      accessPin: '4321',
    );
    expect(await parentXp(), 1);
    expect(await profiles.getActiveProfileId(), _parent);
  });

  test('a learner replaces their own data without their PIN', () async {
    await profiles.setActiveProfileById(_parent, accessPin: '4321');
    expect(await backup.replacingNeedsPin(_parent), isFalse);
    await backup.restorePreservingIdentity(
      documentFor(_parent, 'Parent'),
      replaceExisting: true,
    );
    expect(await parentXp(), 1);
    expect(await profiles.getActiveProfileId(), _parent);
  });

  test(
    'a learner without a PIN, or one new to the device, needs none',
    () async {
      await profiles.setActiveProfileById(_parent, accessPin: '4321');
      expect(await backup.replacingNeedsPin(_child), isFalse);
      await backup.restorePreservingIdentity(
        documentFor(_child, 'Child'),
        replaceExisting: true,
      );
      expect(await profiles.getActiveProfileId(), _child);

      expect(await backup.replacingNeedsPin(_newcomer), isFalse);
      await backup.restorePreservingIdentity(
        documentFor(_newcomer, 'Newcomer'),
      );
      expect(await profiles.getActiveProfileId(), _newcomer);
    },
  );
}
