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

  AuthoringTeam({
    required this.teamId,
    required this.displayName,
    required this.creatorProfileId,
    required this.createdAtUtc,
    required Iterable<String> memberProfileIds,
    required Iterable<String> leadProfileIds,
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
        !this.leadProfileIds.every(this.memberProfileIds.contains)) {
      throw const FormatException(
        'Authoring Team data are incomplete or invalid.',
      );
    }
  }

  bool hasMember(String profileId) => memberProfileIds.contains(profileId);
  bool hasLead(String profileId) => leadProfileIds.contains(profileId);

  AuthoringTeam copyWith({
    String? displayName,
    Iterable<String>? memberProfileIds,
    Iterable<String>? leadProfileIds,
  }) => AuthoringTeam(
    teamId: teamId,
    displayName: displayName ?? this.displayName,
    creatorProfileId: creatorProfileId,
    createdAtUtc: createdAtUtc,
    memberProfileIds: memberProfileIds ?? this.memberProfileIds,
    leadProfileIds: leadProfileIds ?? this.leadProfileIds,
  );

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'displayName': displayName,
    'creatorProfileId': creatorProfileId,
    'createdAtUtc': createdAtUtc,
    'memberProfileIds': memberProfileIds,
    'leadProfileIds': leadProfileIds,
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

    return AuthoringTeam(
      teamId: requiredString('teamId'),
      displayName: requiredString('displayName').trim(),
      creatorProfileId: requiredString('creatorProfileId'),
      createdAtUtc: requiredString('createdAtUtc'),
      memberProfileIds: ids('memberProfileIds'),
      leadProfileIds: ids('leadProfileIds'),
    );
  }
}
