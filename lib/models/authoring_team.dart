import 'team_shared_folder_link.dart';

class AuthoringTeam {
  static const storageKey = 'quisquislingo_authoring_teams_v1_2291';

  static final RegExp uuidV4Pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final String teamId;
  final String displayName;
  final String creatorProfileId;
  final String createdAtUtc;
  final List<String> memberProfileIds;
  final List<String> leadProfileIds;

  /// The Team's shared Google Drive folder, in its stored form, or '' for
  /// none (Build 255 Revision 6). Registries written before simply lack it.
  final String sharedFolderUrl;

  AuthoringTeam({
    required this.teamId,
    required this.displayName,
    required this.creatorProfileId,
    required this.createdAtUtc,
    required Iterable<String> memberProfileIds,
    required Iterable<String> leadProfileIds,
    this.sharedFolderUrl = '',
  }) : memberProfileIds = List.unmodifiable(memberProfileIds.toSet()),
       leadProfileIds = List.unmodifiable(leadProfileIds.toSet()) {
    if (!uuidV4Pattern.hasMatch(teamId) ||
        !uuidV4Pattern.hasMatch(creatorProfileId) ||
        displayName.trim().isEmpty ||
        displayName.length > 120 ||
        !createdAtUtc.endsWith('Z') ||
        DateTime.tryParse(createdAtUtc)?.isUtc != true ||
        this.memberProfileIds.any((id) => !uuidV4Pattern.hasMatch(id)) ||
        this.leadProfileIds.any((id) => !uuidV4Pattern.hasMatch(id)) ||
        this.leadProfileIds.isEmpty ||
        !this.leadProfileIds.every(this.memberProfileIds.contains) ||
        (sharedFolderUrl.isNotEmpty &&
            !TeamSharedFolderLink.isStored(sharedFolderUrl))) {
      throw const FormatException(
        'Authoring Team data are incomplete or invalid.',
      );
    }
  }

  bool hasMember(String profileId) => memberProfileIds.contains(profileId);
  bool hasLead(String profileId) => leadProfileIds.contains(profileId);

  /// Whether [profileId] is the Team's only Team Leader.
  bool isLastLead(String profileId) =>
      hasLead(profileId) && leadProfileIds.length == 1;

  /// Who leads the Team once [profileId], its last Team Leader, is gone: the
  /// member who was added first (Build 271 Revision 2 second follow-up,
  /// owner decision of 11 October 2026). Null when [profileId] is not its
  /// last Team Leader, or when no other member is left.
  String? successorOf(String profileId) => isLastLead(profileId)
      ? memberProfileIds.where((id) => id != profileId).firstOrNull
      : null;

  /// The Team without [profileId]. A Team always has a Team Leader, so when
  /// its last one goes [successorOf] takes over. Null when nobody is left:
  /// the Team goes too.
  AuthoringTeam? without(String profileId) {
    final members = memberProfileIds.where((id) => id != profileId).toList();
    if (members.isEmpty) return null;
    final leads = leadProfileIds.where((id) => id != profileId).toList();
    return copyWith(
      memberProfileIds: members,
      leadProfileIds: leads.isEmpty ? [members.first] : leads,
    );
  }

  AuthoringTeam copyWith({
    String? displayName,
    Iterable<String>? memberProfileIds,
    Iterable<String>? leadProfileIds,
    String? sharedFolderUrl,
  }) => AuthoringTeam(
    teamId: teamId,
    displayName: displayName ?? this.displayName,
    creatorProfileId: creatorProfileId,
    createdAtUtc: createdAtUtc,
    memberProfileIds: memberProfileIds ?? this.memberProfileIds,
    leadProfileIds: leadProfileIds ?? this.leadProfileIds,
    sharedFolderUrl: sharedFolderUrl ?? this.sharedFolderUrl,
  );

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'displayName': displayName,
    'creatorProfileId': creatorProfileId,
    'createdAtUtc': createdAtUtc,
    'memberProfileIds': memberProfileIds,
    'leadProfileIds': leadProfileIds,
    if (sharedFolderUrl.isNotEmpty) 'sharedFolderUrl': sharedFolderUrl,
  };

  factory AuthoringTeam.fromJson(Map<String, dynamic> json) {
    List<String> ids(String key) {
      final value = json[key];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('team.$key must be a list of profile IDs.');
      }
      return value.cast<String>();
    }

    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('team.$key is required.');
      }
      return value;
    }

    final sharedFolderUrl = json['sharedFolderUrl'];
    if (sharedFolderUrl != null && sharedFolderUrl is! String) {
      throw const FormatException('team.sharedFolderUrl must be a string.');
    }
    return AuthoringTeam(
      teamId: requiredString('teamId'),
      displayName: requiredString('displayName').trim(),
      creatorProfileId: requiredString('creatorProfileId'),
      createdAtUtc: requiredString('createdAtUtc'),
      memberProfileIds: ids('memberProfileIds'),
      leadProfileIds: ids('leadProfileIds'),
      sharedFolderUrl: (sharedFolderUrl as String?) ?? '',
    );
  }
}
