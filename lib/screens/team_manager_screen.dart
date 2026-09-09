import 'package:flutter/material.dart';

import '../models/authoring_team.dart';
import '../services/profile_service.dart';
import '../services/team_service.dart';
import '../widgets/editor_app_bar_actions.dart';

class TeamManagerScreen extends StatefulWidget {
  const TeamManagerScreen({super.key, this.teamService, this.profileService});

  final TeamService? teamService;
  final ProfileService? profileService;

  @override
  State<TeamManagerScreen> createState() => _TeamManagerScreenState();
}

class _TeamManagerScreenState extends State<TeamManagerScreen> {
  late final ProfileService _profiles =
      widget.profileService ?? ProfileService();
  late final TeamService _teams =
      widget.teamService ?? TeamService(profileService: _profiles);
  LearnerProfile? _active;
  List<AuthoringTeam> _mine = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final active = await _profiles.getActiveProfileRecord();
    final teams = active == null
        ? const <AuthoringTeam>[]
        : await _teams.teamsForProfile(active.learnerProfileId);
    if (!mounted) return;
    setState(() {
      _active = active;
      _mine = teams;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final active = _active;
    if (active == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: TextField(
          key: const Key('team-name-field'),
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Team name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('create-team-confirm'),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await _teams.createTeam(
        creatorProfileId: active.learnerProfileId,
        displayName: name,
      );
      await _reload();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString().replaceFirst('StateError: ', ''))),
  );

  Future<void> _open(AuthoringTeam team) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TeamDetailScreen(
          teamId: team.teamId,
          teamService: _teams,
          profileService: _profiles,
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Team Manager'),
      actions: const [EditorAppBarActions()],
    ),
    floatingActionButton: _active == null
        ? null
        : FloatingActionButton.extended(
            key: const Key('create-team'),
            onPressed: _create,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Create Team'),
          ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _active == null
        ? const Center(child: Text('Select or create a learner profile first.'))
        : _mine.isEmpty
        ? const Center(child: Text('You do not belong to a Team yet.'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: _mine.length,
            itemBuilder: (context, index) {
              final team = _mine[index];
              return Card(
                child: ListTile(
                  key: ValueKey('team-${team.teamId}'),
                  leading: const Icon(Icons.groups_outlined),
                  title: Text(team.displayName),
                  subtitle: Text(
                    '${team.memberProfileIds.length} members · ${team.leadProfileIds.length} Team Lead${team.leadProfileIds.length == 1 ? '' : 's'}${team.hasLead(_active!.learnerProfileId) ? ' · You are a Lead' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(team),
                ),
              );
            },
          ),
  );
}

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamService,
    required this.profileService,
  });

  final String teamId;
  final TeamService teamService;
  final ProfileService profileService;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  AuthoringTeam? _team;
  LearnerProfile? _active;
  Map<String, LearnerProfile> _profiles = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final team = await widget.teamService.teamById(widget.teamId);
    final active = await widget.profileService.getActiveProfileRecord();
    final profiles = await widget.profileService.getProfileRecords();
    if (!mounted) return;
    setState(() {
      _team = team;
      _active = active;
      _profiles = {
        for (final profile in profiles) profile.learnerProfileId: profile,
      };
      _loading = false;
    });
  }

  bool get _canManage =>
      _team != null &&
      _active != null &&
      _team!.hasLead(_active!.learnerProfileId);

  String _name(String id) =>
      _profiles[id]?.displayName ?? 'Unavailable local profile';

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('StateError: ', '')),
        ),
      );
    }
  }

  Future<void> _addMember() async {
    final team = _team;
    final active = _active;
    if (team == null || active == null || !_canManage) return;
    final available = _profiles.values
        .where((profile) => !team.hasMember(profile.learnerProfileId))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Every local profile is already a member.'),
        ),
      );
      return;
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Add existing local profile'),
        children: [
          for (final profile in available)
            SimpleDialogOption(
              key: ValueKey('add-member-${profile.learnerProfileId}'),
              onPressed: () => Navigator.pop(context, profile.learnerProfileId),
              child: Text(profile.displayName),
            ),
        ],
      ),
    );
    if (selected == null) return;
    await _run(() async {
      await widget.teamService.addMember(
        teamId: team.teamId,
        actorProfileId: active.learnerProfileId,
        memberProfileId: selected,
      );
    });
  }

  Future<void> _rename() async {
    final team = _team;
    final active = _active;
    if (team == null || active == null || !_canManage) return;
    final controller = TextEditingController(text: team.displayName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Team'),
        content: TextField(controller: controller, maxLength: 120),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    await _run(() async {
      await widget.teamService.renameTeam(
        teamId: team.teamId,
        actorProfileId: active.learnerProfileId,
        displayName: value,
      );
    });
  }

  Future<void> _memberAction(String action, String profileId) async {
    final team = _team!;
    final actor = _active!.learnerProfileId;
    await _run(() async {
      switch (action) {
        case 'promote':
          await widget.teamService.promoteToLead(
            teamId: team.teamId,
            actorProfileId: actor,
            memberProfileId: profileId,
          );
          return;
        case 'demote':
          await widget.teamService.demoteLead(
            teamId: team.teamId,
            actorProfileId: actor,
            leadProfileId: profileId,
          );
          return;
        case 'remove':
          await widget.teamService.removeMember(
            teamId: team.teamId,
            actorProfileId: actor,
            memberProfileId: profileId,
          );
          return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final team = _team;
    if (team == null) {
      return const Scaffold(
        body: Center(child: Text('This Team is unavailable.')),
      );
    }
    final leads = team.leadProfileIds;
    final members = team.memberProfileIds.where((id) => !team.hasLead(id));
    return Scaffold(
      appBar: AppBar(
        title: Text(team.displayName),
        actions: [
          if (_canManage)
            IconButton(
              tooltip: 'Rename Team',
              onPressed: _rename,
              icon: const Icon(Icons.edit_outlined),
            ),
          const EditorAppBarActions(),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              key: const Key('add-team-member'),
              onPressed: _addMember,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add member'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text(
            _canManage
                ? 'Team Leads administer membership. Every member can edit and duplicate Team-owned courses.'
                : 'Every Team member can edit and duplicate Team-owned courses. Only Team Leads administer membership.',
          ),
          const SizedBox(height: 16),
          Text('Team Leads', style: Theme.of(context).textTheme.titleMedium),
          for (final id in leads) _memberTile(team, id, isLead: true),
          const SizedBox(height: 12),
          Text('Members', style: Theme.of(context).textTheme.titleMedium),
          if (members.isEmpty)
            const ListTile(title: Text('No ordinary members')),
          for (final id in members) _memberTile(team, id, isLead: false),
        ],
      ),
    );
  }

  Widget _memberTile(
    AuthoringTeam team,
    String profileId, {
    required bool isLead,
  }) {
    final finalLead = isLead && team.leadProfileIds.length == 1;
    return ListTile(
      key: ValueKey('team-member-$profileId'),
      leading: Icon(
        isLead ? Icons.admin_panel_settings_outlined : Icons.person_outline,
      ),
      title: Text(_name(profileId)),
      subtitle: Text(
        finalLead
            ? 'Team Lead · The final Team Lead cannot be demoted or removed.'
            : isLead
            ? 'Team Lead'
            : 'Member',
      ),
      trailing: !_canManage
          ? null
          : PopupMenuButton<String>(
              tooltip: finalLead
                  ? 'The Team must retain at least one Team Lead'
                  : 'Manage member',
              onSelected: (value) => _memberAction(value, profileId),
              itemBuilder: (_) => [
                if (!isLead)
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('Promote to Team Lead'),
                  ),
                if (isLead)
                  PopupMenuItem(
                    value: 'demote',
                    enabled: !finalLead,
                    child: const Text('Demote to Member'),
                  ),
                PopupMenuItem(
                  value: 'remove',
                  enabled: !finalLead,
                  child: const Text('Remove member'),
                ),
              ],
            ),
    );
  }
}
