import 'profile_service.dart';

/// The protection of every destructive admin action (the resets of Advanced
/// (Admin), and since Build 266 Revision 2 the Inventory's Delete and
/// Forget): the actor must be an admin with a PIN, and [pin] must be it.
class AdminPinGate {
  AdminPinGate(this._profiles);

  final ProfileService _profiles;

  /// Why [actorProfileId] may not act with [pin], or null when they may.
  /// [what] names the action in the first refusal ("reset QQL").
  Future<String?> problem(
    String actorProfileId,
    String pin, {
    required String what,
  }) async {
    if (!await _profiles.isAdmin(actorProfileId)) {
      return 'Only an admin may $what.';
    }
    if (!await _profiles.hasAccessPin(actorProfileId)) {
      return 'Set a PIN before using reset options.';
    }
    if (!await _profiles.verifyAccessPin(actorProfileId, pin)) {
      return 'Incorrect PIN. Nothing was changed.';
    }
    return null;
  }
}
