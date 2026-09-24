import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../localization/locale_service.dart';
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
import '../widgets/app_locale_selector.dart';

String _t(
  AppLocale locale,
  String key, [
  Map<String, String> values = const {},
]) => helpText.lookup(locale, 'courseInfo.$key', values: values);

String _value(AppLocale locale, String key, Object value) =>
    _t(locale, key, {'value': '$value'});

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

  Future<void> _buyCoffee(BuildContext context, AppLocale locale) async {
    final uri = Uri.tryParse(course.buyACoffeeUrl);
    if (uri == null || uri.scheme != 'https') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(locale, 'authorSupportMissing'))),
      );
      return;
    }
    final opened = launchExternal == null
        ? await launchUrl(uri, mode: LaunchMode.externalApplication)
        : await launchExternal!(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(locale, 'authorSupportOpenFailed'))),
      );
    }
  }

  String _credits(AppLocale locale) {
    final structured = course.authors;
    final authorNames = structured
        .map((author) => author.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final lines = <String>[
      _value(
        locale,
        'authorsContributors',
        authorNames.isEmpty
            ? _t(locale, 'notSpecified')
            : authorNames.join(', '),
      ),
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
        'Contributor' => _t(locale, 'contributors'),
        'Illustrator' => _t(locale, 'illustrators'),
        _ => role,
      };
      lines.add('$label: ${people.join(', ')}');
    }
    return lines.join('\n');
  }

  String _localDateTime(BuildContext context, String utc, AppLocale locale) {
    final parsed = DateTime.tryParse(utc)?.toLocal();
    if (parsed == null) return _t(locale, 'notRecorded');
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatFullDate(parsed)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
  }

  List<String> _originDetails(BuildContext context, AppLocale locale) {
    if (course.originType.isOfficial) {
      return [
        _value(
          locale,
          'origin.label',
          course.originType == CourseOriginType.bundledOfficial
              ? _t(locale, 'origin.bundledOfficial')
              : _t(locale, 'origin.publisherCourse'),
        ),
        _value(locale, 'publisher', course.publisherName),
        _value(
          locale,
          'originalCourseCreated',
          _localDateTime(context, course.originalCreatedAtUtc, locale),
        ),
        if (course.lastVersionEditorDisplayName.isNotEmpty)
          _value(
            locale,
            'lastVersionEditor',
            course.lastVersionEditorDisplayName,
          ),
        _value(
          locale,
          'modified',
          _localDateTime(context, course.modifiedAtUtc, locale),
        ),
        _value(locale, 'officialCourseVersion', course.officialCourseVersion),
        _value(
          locale,
          'officialRelease',
          _localDateTime(context, course.officialReleaseDateUtc, locale),
        ),
        _value(locale, 'distributionChannel', course.distributionChannel),
        _value(
          locale,
          'publisherVerification',
          course.publisherVerificationStatus.name,
        ),
        if (course.originType == CourseOriginType.externalOfficial &&
            course.publisherVerificationStatus !=
                PublisherVerificationStatus.verified)
          _t(locale, 'verificationRequired'),
        if (course.originType == CourseOriginType.externalOfficial &&
            course.publisherVerificationStatus ==
                PublisherVerificationStatus.verified)
          _t(locale, 'signatureScope'),
        _value(locale, 'officialChecksum', course.officialChecksum),
        _t(locale, 'officialReadOnly'),
      ];
    }
    return [
      _value(locale, 'origin.label', _t(locale, 'origin.customCourse')),
      _value(
        locale,
        'courseVersion',
        course.courseVersion.trim().isEmpty
            ? _t(locale, 'unconfirmed')
            : course.courseVersion,
      ),
      if (course.originalCreatedAtUtc.isNotEmpty)
        _value(
          locale,
          'originalCourseCreated',
          _localDateTime(context, course.originalCreatedAtUtc, locale),
        ),
      if (course.lastVersionEditorDisplayName.isNotEmpty)
        _value(
          locale,
          'lastVersionEditor',
          course.lastVersionEditorDisplayName,
        ),
      if (course.modifiedAtUtc.isNotEmpty)
        _value(
          locale,
          'modified',
          _localDateTime(context, course.modifiedAtUtc, locale),
        ),
      if (course.versionNotes.isNotEmpty)
        _value(locale, 'versionNotes', course.versionNotes),
    ];
  }

  Widget _build(
    BuildContext context, {
    required ResolvedCourseGovernance governance,
    required AppLocale locale,
  }) => Scaffold(
    appBar: AppBar(
      title: Text(_t(locale, 'title')),
      actions: [
        AppLocaleSelector(
          key: const Key('course-info-locale-selector'),
          locale: locale,
        ),
      ],
    ),
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
                  title: _t(locale, 'internalCourseData'),
                  body: _value(locale, 'courseModel', course.formatVersion),
                )
              : const SizedBox.shrink(),
        ),
        if (course.courseDescription.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(course.courseDescription.trim()),
        ],
        const SizedBox(height: 18),
        if (course.temporarySample)
          _InfoCard(
            title: _t(locale, 'temporarySample.title'),
            body: _t(locale, 'temporarySample.body'),
          ),
        _GovernanceInfoCard(
          course: course,
          governance: governance,
          locale: locale,
        ),
        _InfoCard(
          title: _t(locale, 'authorshipAndDescriptiveCredits'),
          body: _credits(locale),
          tooltip:
              course.authors.any(
                (author) => author.roles.contains('Team Leader'),
              )
              ? _t(locale, 'teamLeaderTooltip')
              : null,
        ),
        _InfoCard(
          title: _t(locale, 'languages'),
          body: [
            _value(
              locale,
              'learningLanguage',
              CourseLanguageResolver.learning(course).displayLabel,
            ),
            _value(
              locale,
              'baseLanguage',
              CourseLanguageResolver.base(course).displayLabel,
            ),
          ].join('\n'),
        ),
        if (course.forkProvenance != null)
          CourseForkProvenanceCard(
            provenance: course.forkProvenance!,
            locale: locale,
          ),
        _InfoCard(
          title: _t(locale, 'licenseRights'),
          body: [
            _value(
              locale,
              'license',
              course.license.trim().isEmpty
                  ? _t(locale, 'notSpecified')
                  : course.license,
            ),
            _value(
              locale,
              'rightsHolder',
              course.rightsHolders.isEmpty
                  ? _t(locale, 'notSpecified')
                  : course.rightsHolders
                        .map((holder) => '${holder.name} (${holder.type.name})')
                        .join(', '),
            ),
            _value(
              locale,
              'derivativeWorks',
              course.derivativeWorksPolicy.name,
            ),
            _t(locale, 'rightsHolderDisclaimer'),
          ].join('\n'),
        ),
        if (course.mediaAttributions.isNotEmpty)
          _InfoCard(
            key: const Key('course-info-media-credits'),
            title: _t(locale, 'mediaCredits'),
            body: [
              for (final credit in course.mediaAttributions)
                [
                  if (credit.title.isNotEmpty) '${credit.title} — ',
                  credit.author,
                  ', ',
                  credit.license,
                  if (credit.appliesTo.isNotEmpty) ' (${credit.appliesTo})',
                  if (credit.source.isNotEmpty)
                    '\n  ${_value(locale, 'source', credit.source)}',
                ].join(),
              _t(locale, 'mediaCreditsDisclaimer'),
            ].join('\n'),
          ),
        _InfoCard(
          title: _t(locale, 'courseDetails'),
          body: [
            ..._originDetails(context, locale),
            _value(locale, 'lessons', course.lessons.length),
            if (course.estimatedStudyHours != null)
              _t(locale, 'estimatedStudyTime', {
                'value': '${course.estimatedStudyHours}',
                'unit': _t(
                  locale,
                  course.estimatedStudyHours == 1 ? 'hour' : 'hours',
                ),
              }),
            if (course.minimumAge != null)
              _value(locale, 'minimumAge', course.minimumAge!),
            if (course.keywords.isNotEmpty)
              _value(locale, 'keywords', course.keywords.join(', ')),
            if (course.minimumAppBuild != null)
              _value(locale, 'requiresBuild', course.minimumAppBuild!),
          ].join('\n'),
        ),
        if (course.publisherContact != null)
          _InfoCard(
            key: const Key('course-info-publisher-contact'),
            title: _t(locale, 'publisherContact'),
            body: [
              if (course.publisherContact!.websiteUrl.isNotEmpty)
                _value(locale, 'website', course.publisherContact!.websiteUrl),
              if (course.publisherContact!.email.isNotEmpty)
                _value(locale, 'email', course.publisherContact!.email),
            ].join('\n'),
          ),
        if (course.buyACoffeeUrl.isNotEmpty) ...[
          const Divider(height: 24),
          ListTile(
            key: const Key('course-info-buy-coffee'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.coffee_outlined),
            title: Text(_t(locale, 'buyACoffee')),
            subtitle: Text(_t(locale, 'supportAuthors')),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _buyCoffee(context, locale),
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
    return LocaleBuilder(
      builder: (context, locale) => Localizations.override(
        context: context,
        locale: Locale(locale.id.toLowerCase()),
        delegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        child: Builder(
          builder: (localizedContext) => widget._build(
            localizedContext,
            governance: governance,
            locale: locale,
          ),
        ),
      ),
    );
  }
}

class _GovernanceInfoCard extends StatelessWidget {
  const _GovernanceInfoCard({
    required this.course,
    required this.governance,
    required this.locale,
  });

  final Course course;
  final ResolvedCourseGovernance governance;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(locale, 'governance.title'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (course.originType.isOfficial) ...[
            SelectableText(
              _value(
                locale,
                'governance.officialPublisher',
                course.publisherName,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _value(
                locale,
                'governance.originalCreator',
                course.originalCourseCreator.displayName,
              ),
            ),
          ] else ...[
            SelectableText(
              _value(
                locale,
                'governance.maintainer',
                governance.maintainerLabel,
              ),
            ),
            if (governance.maintainerProfileId != null)
              EditorInternalIdText(
                label: 'User',
                id: governance.maintainerProfileId!,
              ),
            const SizedBox(height: 8),
            SelectableText(
              _value(
                locale,
                'governance.originalCreator',
                governance.originalCreatorLabel,
              ),
            ),
            if (governance.originalCreatorProfileId != null)
              EditorInternalIdText(
                label: 'User',
                id: governance.originalCreatorProfileId!,
              ),
            const SizedBox(height: 8),
            SelectableText(
              _value(
                locale,
                'governance.assignedTeam',
                governance.assignedTeamLabel ?? _t(locale, 'governance.none'),
              ),
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
              _value(
                locale,
                'governance.teamLeaders',
                governance.teamLeaders.isEmpty
                    ? _t(locale, 'governance.noneAvailable')
                    : governance.teamLeaders
                          .map((value) => value.label)
                          .join(', '),
              ),
            ),
            for (final leader in governance.teamLeaders)
              EditorInternalIdText(label: 'User', id: leader.profileId),
            const SizedBox(height: 8),
            SelectableText(
              _value(
                locale,
                'governance.teamMembers',
                governance.teamMembers.isEmpty
                    ? _t(locale, 'governance.none')
                    : governance.teamMembers
                          .map((value) => value.label)
                          .join(', '),
              ),
            ),
            for (final member in governance.teamMembers)
              EditorInternalIdText(label: 'User', id: member.profileId),
          ],
          SelectableText(_t(locale, 'governance.disclaimer')),
        ],
      ),
    ),
  );
}

/// Immediate source attribution is distinct from editable contributor data.
class CourseForkProvenanceCard extends StatelessWidget {
  const CourseForkProvenanceCard({
    super.key,
    required this.provenance,
    this.locale = AppLocale.english,
  });

  final CourseForkProvenance provenance;
  final AppLocale locale;

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
        : _t(locale, 'notSpecified');
    final created = DateTime.tryParse(provenance.forkCreatedAtUtc)?.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final createdLabel = created == null
        ? _t(locale, 'fork.notRecorded')
        : '${localizations.formatFullDate(created)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(created))}';
    return _InfoCard(
      title: _t(locale, 'fork.title'),
      body: [
        _value(locale, 'fork.fromCourseId', provenance.sourceCourseId),
        _value(locale, 'fork.sourceCourse', provenance.sourceCourseTitle),
        if (provenance.sourceCourseVersion.isNotEmpty)
          _value(
            locale,
            'fork.sourceCourseVersion',
            provenance.sourceCourseVersion,
          ),
        if (provenance.sourcePublisherName.isNotEmpty)
          _value(
            locale,
            'fork.sourcePublisher',
            provenance.sourcePublisherName,
          ),
        if (provenance.sourcePublisherId.isNotEmpty)
          _value(
            locale,
            'fork.sourcePublisherId',
            provenance.sourcePublisherId,
          ),
        _value(locale, 'fork.sourceAuthors', sourceAuthors),
        if (provenance.sourceOfficialChecksum.isNotEmpty)
          _value(
            locale,
            'fork.sourceOfficialChecksum',
            provenance.sourceOfficialChecksum,
          ),
        _value(locale, 'fork.createdBy', provenance.forkCreatedByDisplayName),
        _value(locale, 'fork.createdDate', createdLabel),
        _t(locale, 'fork.disclaimer'),
      ].join('\n'),
      children: [
        EditorInternalIdText(
          label: _t(locale, 'fork.creatorUser'),
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
    super.key,
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
