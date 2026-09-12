import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/course_metadata_options.dart';
import '../models/course_models.dart';
import '../services/profile_service.dart';
import '../services/team_service.dart';
import '../services/course_language_resolver.dart';
import '../services/course_governance_resolver.dart';
import '../services/course_service.dart';
import '../services/editor_display_preferences.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../widgets/flag_art.dart';

class CourseInfoScreen extends StatefulWidget {
  final Course course;
  final Future<bool> Function(Uri uri)? launchExternal;
  final ProfileService? profileService;
  final TeamService? teamService;

  const CourseInfoScreen({
    super.key,
    required this.course,
    this.launchExternal,
    this.profileService,
    this.teamService,
  });

  @override
  State<CourseInfoScreen> createState() => _CourseInfoScreenState();

  Future<void> _buyCoffee(BuildContext context) async {
    final uri = Uri.tryParse(course.buyACoffeeUrl);
    if (uri == null || uri.scheme != 'https') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This course does not provide an author support link.'),
        ),
      );
      return;
    }
    final opened = launchExternal == null
        ? await launchUrl(uri, mode: LaunchMode.externalApplication)
        : await launchExternal!(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The author support link could not open.'),
        ),
      );
    }
  }

  String get _credits {
    final structured = course.authors;
    final authorNames = structured
        .map((author) => author.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final lines = <String>[
      'Authors / Contributors: ${authorNames.isEmpty ? 'Not specified' : authorNames.join(', ')}',
    ];
    final peopleByRole = <String, List<String>>{};
    for (final author in structured) {
      for (final role in author.roles) {
        final normalizedRole = role.trim();
        if (normalizedRole.isEmpty) continue;
        final people = peopleByRole.putIfAbsent(normalizedRole, () => []);
        if (!people.contains(author.name)) people.add(author.name);
      }
    }
    final orderedRoles = <String>[
      ...CourseMetadataOptions.standardRoles,
      ...peopleByRole.keys.where(
        (role) => !CourseMetadataOptions.standardRoles.contains(role),
      ),
    ];
    for (final role in orderedRoles) {
      final people = peopleByRole[role];
      if (people == null || people.isEmpty) continue;
      final label = switch (role) {
        'Contributor' => 'Contributors',
        'Illustrator' => 'Illustrators',
        _ => role,
      };
      lines.add('$label: ${people.join(', ')}');
    }
    return lines.join('\n');
  }

  String _localDateTime(BuildContext context, String utc) {
    final parsed = DateTime.tryParse(utc)?.toLocal();
    if (parsed == null) return 'Not recorded';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatFullDate(parsed)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
  }

  List<String> _originDetails(BuildContext context) {
    if (course.originType.isOfficial) {
      return [
        'Origin: ${course.originType == CourseOriginType.bundledOfficial ? 'Bundled official' : 'External official'}',
        'Publisher: ${course.publisherName}',
        'Original Course Created: ${_localDateTime(context, course.originalCreatedAtUtc)}',
        if (course.lastVersionEditorDisplayName.isNotEmpty)
          'Last Version Editor: ${course.lastVersionEditorDisplayName}',
        'Modified: ${_localDateTime(context, course.modifiedAtUtc)}',
        'Official course version: ${course.officialCourseVersion}',
        'Official release: ${_localDateTime(context, course.officialReleaseDateUtc)}',
        'Distribution channel: ${course.distributionChannel}',
        'Publisher verification: ${course.publisherVerificationStatus.name}',
        'Official checksum: ${course.officialChecksum}',
        'Official course - read only',
      ];
    }
    return [
      'Origin: Custom course',
      'Course version: ${course.courseVersion.trim().isEmpty ? 'Unconfirmed' : course.courseVersion}',
      if (course.originalCreatedAtUtc.isNotEmpty)
        'Original Course Created: ${_localDateTime(context, course.originalCreatedAtUtc)}',
      if (course.lastVersionEditorDisplayName.isNotEmpty)
        'Last Version Editor: ${course.lastVersionEditorDisplayName}',
      if (course.modifiedAtUtc.isNotEmpty)
        'Modified: ${_localDateTime(context, course.modifiedAtUtc)}',
      if (course.versionNotes.isNotEmpty)
        'Version notes:\n${course.versionNotes}',
    ];
  }

  Widget _build(
    BuildContext context, {
    required ResolvedCourseGovernance governance,
  }) => Scaffold(
    appBar: AppBar(title: const Text('Course Info')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        Text(
          course.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          '${CourseLanguageResolver.base(course).displayLabel} → '
          '${CourseLanguageResolver.learning(course).displayLabel}',
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: CourseFlagBadge(
            course: course,
            fallbackCode: CourseService.codeForCourse(course),
            width: 64,
            height: 44,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: EditorDisplayPreferences.showInternalIds,
          builder: (context, showInternalIds, _) => showInternalIds
              ? _InfoCard(
                  title: 'Internal course data',
                  body: 'Course Model: v${course.formatVersion}',
                )
              : const SizedBox.shrink(),
        ),
        if (course.courseDescription.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(course.courseDescription.trim()),
        ],
        const SizedBox(height: 18),
        if (course.temporarySample)
          const _InfoCard(
            title: 'Temporary Sample',
            body:
                'This course is marked TEMPORARY SAMPLE. The preloaded material is provided only to demonstrate and test the editor. Replace sample material with reviewed content before publishing or distributing the course.',
          ),
        _GovernanceInfoCard(course: course, governance: governance),
        _InfoCard(
          title: 'Authorship and descriptive credits',
          body: _credits,
          tooltip:
              course.authors.any(
                (author) => author.roles.contains('Team Leader'),
              )
              ? 'This is descriptive information only. To assign or change Team Leader roles in QQL, use Team Manager.'
              : null,
        ),
        _InfoCard(
          title: 'Languages',
          body: [
            'Learning language: ${CourseLanguageResolver.learning(course).displayLabel}',
            'Base language: ${CourseLanguageResolver.base(course).displayLabel}',
          ].join('\n'),
        ),
        if (course.forkProvenance != null)
          CourseForkProvenanceCard(provenance: course.forkProvenance!),
        _InfoCard(
          title: 'License / Rights',
          body: [
            'License: ${course.license.trim().isEmpty ? 'Not specified' : course.license}',
            'Rights Holder: ${course.rightsHolders.isEmpty ? 'Not specified' : course.rightsHolders.map((holder) => '${holder.name} (${holder.type.name})').join(', ')}',
            'Derivative works: ${course.derivativeWorksPolicy.name}',
            'Rights Holder is descriptive legal metadata and does not control QQL permissions.',
          ].join('\n'),
        ),
        _InfoCard(
          title: 'Course details',
          body: [
            ..._originDetails(context),
            'Lessons: ${course.lessons.length}',
          ].join('\n'),
        ),
        if (course.buyACoffeeUrl.isNotEmpty) ...[
          const Divider(height: 24),
          ListTile(
            key: const Key('course-info-buy-coffee'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.coffee_outlined),
            title: const Text('Buy a Coffee'),
            subtitle: const Text('Support this course\'s authors.'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _buyCoffee(context),
          ),
        ],
      ],
    ),
  );
}

class _CourseInfoScreenState extends State<CourseInfoScreen> {
  late final ProfileService _profiles =
      widget.profileService ?? ProfileService();
  late final TeamService _teams =
      widget.teamService ?? TeamService(profileService: _profiles);
  ResolvedCourseGovernance? _governance;

  @override
  void initState() {
    super.initState();
    EditorDisplayPreferences.load();
    _resolveIdentities();
  }

  Future<void> _resolveIdentities() async {
    final course = widget.course;
    final resolved = await CourseGovernanceResolver(
      profileService: _profiles,
      teamService: _teams,
    ).resolve(course);
    if (!mounted) return;
    setState(() => _governance = resolved);
  }

  @override
  Widget build(BuildContext context) {
    final governance = _governance;
    if (governance == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget._build(context, governance: governance);
  }
}

class _GovernanceInfoCard extends StatelessWidget {
  const _GovernanceInfoCard({required this.course, required this.governance});

  final Course course;
  final ResolvedCourseGovernance governance;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course responsibility, Team assignment and authorization',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (course.originType.isOfficial) ...[
            SelectableText('Official publisher: ${course.publisherName}'),
            const SizedBox(height: 8),
            SelectableText(
              'Original Course Creator: ${course.originalCourseCreator.displayName}',
            ),
          ] else ...[
            SelectableText('Course Maintainer: ${governance.maintainerLabel}'),
            if (governance.maintainerProfileId != null)
              EditorInternalIdText(
                label: 'User',
                id: governance.maintainerProfileId!,
              ),
            const SizedBox(height: 8),
            SelectableText(
              'Original Course Creator: ${governance.originalCreatorLabel}',
            ),
            if (governance.originalCreatorProfileId != null)
              EditorInternalIdText(
                label: 'User',
                id: governance.originalCreatorProfileId!,
              ),
            const SizedBox(height: 8),
            SelectableText(
              'Assigned Team: ${governance.assignedTeamLabel ?? 'None'}',
            ),
            if (governance.assignedTeamId != null)
              EditorInternalIdText(
                label: 'Team',
                id: governance.assignedTeamId!,
              ),
          ],
          if (!course.originType.isOfficial &&
              governance.assignedTeamId != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              'Team Leaders: ${governance.teamLeaders.isEmpty ? 'None available' : governance.teamLeaders.map((value) => value.label).join(', ')}',
            ),
            for (final leader in governance.teamLeaders)
              EditorInternalIdText(label: 'User', id: leader.profileId),
            const SizedBox(height: 8),
            SelectableText(
              'Team Members: ${governance.teamMembers.isEmpty ? 'None' : governance.teamMembers.map((value) => value.label).join(', ')}',
            ),
            for (final member in governance.teamMembers)
              EditorInternalIdText(label: 'User', id: member.profileId),
          ],
          const SelectableText(
            'Course maintenance and Team governance are separate. Provenance, attribution and rights metadata do not grant editing permission.',
          ),
        ],
      ),
    ),
  );
}

/// Immediate source attribution is distinct from editable contributor data.
class CourseForkProvenanceCard extends StatelessWidget {
  const CourseForkProvenanceCard({super.key, required this.provenance});

  final CourseForkProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final sourceAuthors = provenance.sourceAuthors.isNotEmpty
        ? provenance.sourceAuthors
              .map(
                (author) => author.roles.isEmpty
                    ? author.name
                    : '${author.name} — ${author.roles.join(', ')}',
              )
              .join('\n')
        : 'Not specified';
    final created = DateTime.tryParse(provenance.forkCreatedAtUtc)?.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final createdLabel = created == null
        ? 'Not recorded'
        : '${localizations.formatFullDate(created)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(created))}';
    return _InfoCard(
      title: 'Fork provenance',
      body: [
        'Forked From Course ID: ${provenance.sourceCourseId}',
        'Source Course: ${provenance.sourceCourseTitle}',
        if (provenance.sourceCourseVersion.isNotEmpty)
          'Source Course version: ${provenance.sourceCourseVersion}',
        if (provenance.sourcePublisherName.isNotEmpty)
          'Source publisher: ${provenance.sourcePublisherName}',
        if (provenance.sourcePublisherId.isNotEmpty)
          'Source publisher ID: ${provenance.sourcePublisherId}',
        'Source Authors / Contributors:\n$sourceAuthors',
        if (provenance.sourceOfficialChecksum.isNotEmpty)
          'Source official checksum: ${provenance.sourceOfficialChecksum}',
        'Fork Created By: ${provenance.forkCreatedByDisplayName}',
        'Fork Created Date: $createdLabel',
        'Fork provenance is immutable. Rights Holder and attribution metadata remain separate from QQL permissions.',
      ].join('\n'),
      children: [
        EditorInternalIdText(
          label: 'Fork creator user',
          id: provenance.forkCreatedByProfileId,
          padding: const EdgeInsets.only(top: 6),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final List<Widget> children;
  final String? tooltip;

  const _InfoCard({
    required this.title,
    required this.body,
    this.children = const [],
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (tooltip == null)
            SelectableText(body)
          else
            Tooltip(message: tooltip!, child: SelectableText(body)),
          ...children,
        ],
      ),
    ),
  );
}
