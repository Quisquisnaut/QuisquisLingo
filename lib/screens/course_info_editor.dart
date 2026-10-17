import 'package:flutter/material.dart';

import '../controllers/course_info_form.dart';
import '../models/authoring_team.dart';
import '../models/course_metadata_options.dart';
import '../models/course_models.dart';
import '../services/course_backup_retention.dart';
import '../services/course_credits.dart';
import '../services/course_governance_resolver.dart';
import '../services/course_governance_service.dart';
import '../services/course_info_update_service.dart';
import '../services/course_language_pair.dart';
import '../services/course_language_resolver.dart';
import '../services/editor_display_preferences.dart';
import '../services/language_catalog.dart';
import '../services/profile_service.dart';
import '../widgets/course_cover_field.dart';
import '../widgets/course_flag_picker.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../widgets/language_field.dart';
import '../widgets/reported_action.dart';
import 'course_info_screen.dart' show CourseForkProvenanceCard;

/// What Apply in the Course Info Editor returns: the change for the Course,
/// and the backups kept on this device (a device setting, not Course data).
typedef CourseInfoEditorResult = ({CourseInfoChange change, int? backupsKept});

/// Opens the Course Info Editor on [course], the Course Editor's working
/// copy. Null when the author cancels.
///
/// The dialog reads and writes nothing by itself: [otherCourses] gives the
/// stored Courses for the name warning, [onVersionHistory] opens the Version
/// history after the dialog has closed, and the caller stages the result.
Future<CourseInfoEditorResult?> showCourseInfoEditor(
  BuildContext context, {
  required Course course,
  required ResolvedCourseGovernance governance,
  required List<LearnerProfile> profiles,
  required List<AuthoringTeam> teams,
  required bool canGovern,
  required bool editMode,
  required int? backupsKept,
  required Future<List<Course>> Function() otherCourses,
  required VoidCallback onVersionHistory,
}) {
  // Measured once, when the dialog opens.
  final narrow = MediaQuery.sizeOf(context).width < 560;
  // The form is made before the dialog opens: a Course it cannot read
  // opens no dialog at all.
  final form = CourseInfoForm(course, backupsKept: backupsKept);
  return showDialog<CourseInfoEditorResult>(
    context: context,
    builder: (_) => CourseInfoEditor(
      form: form,
      governance: governance,
      profiles: profiles,
      teams: teams,
      canGovern: canGovern,
      editMode: editMode,
      narrow: narrow,
      otherCourses: otherCourses,
      onVersionHistory: onVersionHistory,
    ),
  );
}

/// The Course Info Editor dialog (Build 272 Revision 2: a widget of its own;
/// before, one method of the Course Editor screen). It draws a
/// [CourseInfoForm], which owns the fields and what Apply makes of them.
class CourseInfoEditor extends StatefulWidget {
  const CourseInfoEditor({
    super.key,
    required this.form,
    required this.governance,
    required this.profiles,
    required this.teams,
    required this.canGovern,
    required this.editMode,
    required this.narrow,
    required this.otherCourses,
    required this.onVersionHistory,
  });

  /// The form drawn. The dialog disposes it when it leaves the screen.
  final CourseInfoForm form;

  /// The names shown for the Course's people and Team.
  final ResolvedCourseGovernance governance;

  /// The learners of this device, for the Course Maintainer list.
  final List<LearnerProfile> profiles;

  /// The Teams of this device, for the Assigned Team list.
  final List<AuthoringTeam> teams;

  /// Whether the author may change the Course Maintainer and the Assigned
  /// Team: the current Maintainer, in Edit mode.
  final bool canGovern;

  /// Whether the Course Editor is in Edit mode.
  final bool editMode;

  /// Whether the window is too narrow for two fields side by side.
  final bool narrow;

  /// The stored custom Courses, for the "name already exists" warning.
  final Future<List<Course>> Function() otherCourses;

  /// Opens the Version history; the dialog closes first.
  final VoidCallback onVersionHistory;

  @override
  State<CourseInfoEditor> createState() => _CourseInfoEditorState();
}

class _CourseInfoEditorState extends State<CourseInfoEditor> {
  late final _learningLanguage = CourseLanguageResolver.learning(course);
  late final _baseLanguage = CourseLanguageResolver.base(course);
  final _assignedTeamFieldKey = GlobalKey<FormFieldState<String?>>();

  CourseInfoForm get _form => widget.form;

  /// The Course Editor's working copy the form opened on.
  Course get course => _form.course;

  @override
  void dispose() {
    // The dialog has left the screen: its fields are no longer drawn.
    _form.dispose();
    super.dispose();
  }

  static String _tagHelper(String tag) =>
      tag.isEmpty ? 'Read-only · no language tag' : 'Read-only · tag $tag';

  static String _localCourseDateTime(BuildContext context, String utc) {
    final parsed = DateTime.tryParse(utc)?.toLocal();
    if (parsed == null) return 'Not recorded';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatFullDate(parsed)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
  }

  Widget _readOnlyField(
    String label,
    String value, {
    String helperText = 'Read-only',
  }) => InputDecorator(
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: label,
      helper: Text(helperText),
    ),
    child: Text(value.trim().isEmpty ? 'Not specified' : value),
  );

  /// The tags of the Course's own languages (Build 260 Revision 0, owner
  /// decision: a Course's languages never change). A written name QQL
  /// recognizes gives its tag; otherwise the author picks the language from
  /// the list, and a learning language tag is kept only when it leaves the
  /// language code of XP and streaks as it is.
  Future<void> _addLanguageTags() async {
    Future<String> tagFor(String written) async {
      final known = LanguageCatalog.resolve(written);
      if (known != null) return known.tag;
      if (!mounted) return '';
      final picked = await showLanguagePicker(
        context,
        initialQuery: written,
        title: 'Which language is “$written”?',
      );
      return picked?.tag ?? '';
    }

    var source = _form.sourceTag;
    var target = _form.targetTag;
    if (source.isEmpty) source = await tagFor(course.sourceLanguage);
    if (target.isEmpty) {
      final candidate = await tagFor(course.targetLanguage);
      if (candidate.isNotEmpty) {
        if (_form.keepsLearningLanguage(candidate)) {
          target = candidate;
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '“${LanguageCatalog.byTag(candidate)?.englishName ?? candidate}” is not “${course.targetLanguage}”: the learning language of a Course cannot change.',
              ),
            ),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _form.sourceTag = source;
      _form.targetTag = target;
    });
  }

  /// Apply: the name first (with the warning for a name another Course
  /// has), then the form says whether the fields can be stored.
  Future<void> _apply() async {
    final String title;
    try {
      title = _form.validTitle();
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message?.toString() ?? 'Check the Course name.'),
        ),
      );
      return;
    }
    final duplicate = _form.titleTakenBy(
      title,
      await runReported(
            context,
            'Checking the Course name',
            widget.otherCourses,
          ) ??
          const <Course>[],
    );
    if (duplicate) {
      if (!mounted) return;
      final continueAnyway = await showDialog<bool>(
        context: context,
        builder: (warningContext) => AlertDialog(
          title: const Text('Course name already exists'),
          content: const Text('A Course with this name already exists.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(warningContext, false),
              child: const Text('Edit name'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(warningContext, true),
              child: const Text('Continue anyway'),
            ),
          ],
        ),
      );
      if (continueAnyway != true) return;
    }
    if (!mounted) return;
    switch (_form.submit(title)) {
      case CourseInfoAccepted(:final change):
        Navigator.pop<CourseInfoEditorResult>(context, (
          change: change,
          backupsKept: _form.backupsKept,
        ));
      case CourseInfoRefused(:final message):
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        } else {
          // The form shows the reason under the Media credits.
          setState(() {});
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Course Info Editor'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Course identity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('course-info-title'),
                controller: _form.title,
                maxLength: 120,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Course name',
                  helper: Text('Renaming keeps the same Course ID.'),
                ),
              ),
              // Build 271 Revision 2: the switch for the IDs of this
              // dialog (Course, User, Team) and of every Editor page.
              ValueListenableBuilder<bool>(
                valueListenable: EditorDisplayPreferences.showInternalIds,
                builder: (context, showInternalIds, _) => SwitchListTile(
                  key: const Key('course-info-internal-ids'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Show internal IDs'),
                  subtitle: const Text(
                    'The Course ID here, the User and Team IDs below, and '
                    'the IDs on the other Editor pages.',
                  ),
                  value: showInternalIds,
                  onChanged: (_) =>
                      EditorDisplayPreferences.toggleInternalIds(),
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<bool>(
                valueListenable: EditorDisplayPreferences.showInternalIds,
                builder: (context, showInternalIds, _) => showInternalIds
                    ? Column(
                        children: [
                          _readOnlyField('Course ID', course.courseId),
                          const SizedBox(height: 8),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              _readOnlyField('Course origin', course.originType.name),
              const SizedBox(height: 8),
              _readOnlyField(
                'Original Course Creator',
                widget.governance.originalCreatorLabel,
                helperText:
                    'The person who originally created this Course. This does not change when maintainership changes or the Course is forked.',
              ),
              EditorInternalIdText(
                label: 'User',
                id: course.originalCourseCreator.id,
                padding: const EdgeInsets.only(top: 6),
              ),
              const SizedBox(height: 8),
              if (widget.canGovern)
                DropdownButtonFormField<String>(
                  key: const Key('course-info-owner'),
                  initialValue: _form.maintainerProfileId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Course Maintainer',
                    helper: Text(
                      'The person currently responsible for maintaining this Course.',
                    ),
                  ),
                  items: [
                    for (final profile in widget.profiles)
                      DropdownMenuItem(
                        value: profile.learnerProfileId,
                        child: Tooltip(
                          message: profile.presentationName,
                          child: Text(
                            profile.presentationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(
                    () => _form.maintainerProfileId =
                        value ?? _form.maintainerProfileId,
                  ),
                )
              else
                _readOnlyField(
                  'Course Maintainer',
                  widget.governance.maintainerLabel,
                  helperText: widget.editMode
                      ? 'Only the current Course Maintainer may change this field.'
                      : 'Read-only outside Edit mode',
                ),
              EditorInternalIdText(
                label: 'User',
                id: _form.maintainerProfileId,
                padding: const EdgeInsets.only(top: 6),
              ),
              const SizedBox(height: 8),
              if (widget.canGovern)
                KeyedSubtree(
                  key: const Key('course-info-assigned-team'),
                  child: DropdownButtonFormField<String?>(
                    key: _assignedTeamFieldKey,
                    initialValue: _form.assignedTeamId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Assigned Team',
                      helper: Text(
                        'Grants Team management access; the Course Maintainer and Original Course Creator stay unchanged.',
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No assigned Team'),
                      ),
                      for (final team in widget.teams)
                        DropdownMenuItem<String?>(
                          value: team.teamId,
                          child: Tooltip(
                            message: team.displayName,
                            child: Text(
                              team.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (value) async {
                      if (value == _form.assignedTeamId) return;
                      if (value != null) {
                        final confirmed =
                            await showDialog<bool>(
                              context: context,
                              builder: (warningContext) => AlertDialog(
                                key: const Key('team-assignment-warning'),
                                title: const Text('Assign Course to Team?'),
                                content: const Text(
                                  CourseGovernanceService.teamAssignmentWarning,
                                ),
                                actions: [
                                  TextButton(
                                    key: const Key('team-assignment-cancel'),
                                    onPressed: () =>
                                        Navigator.pop(warningContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    key: const Key('team-assignment-confirm'),
                                    onPressed: () =>
                                        Navigator.pop(warningContext, true),
                                    child: const Text('Confirm assignment'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!confirmed) {
                          _assignedTeamFieldKey.currentState?.didChange(
                            _form.assignedTeamId,
                          );
                          return;
                        }
                      }
                      setState(() => _form.assignedTeamId = value);
                    },
                  ),
                )
              else ...[
                _readOnlyField(
                  'Assigned Team',
                  widget.governance.assignedTeamLabel ?? 'None',
                  helperText:
                      'Only the current Course Maintainer may assign or revoke a Team.',
                ),
              ],
              if (_form.assignedTeamId != null)
                EditorInternalIdText(
                  label: 'Team',
                  id: _form.assignedTeamId!,
                  padding: const EdgeInsets.only(top: 6),
                ),
              ValueListenableBuilder<bool>(
                valueListenable: EditorDisplayPreferences.showInternalIds,
                builder: (context, showInternalIds, _) => showInternalIds
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SelectableText(
                          'Course Model: v${course.formatVersion}',
                          key: const Key('course-info-model-version'),
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (course.forkProvenance != null)
                CourseForkProvenanceCard(provenance: course.forkProvenance!),
              ...[
                const SizedBox(height: 8),
                _readOnlyField(
                  'Original Course Created',
                  _localCourseDateTime(context, course.originalCreatedAtUtc),
                ),
                const SizedBox(height: 8),
                _readOnlyField(
                  'Last Version Editor',
                  course.lastVersionEditorDisplayName,
                ),
                const SizedBox(height: 8),
                _readOnlyField(
                  'Modified',
                  _localCourseDateTime(context, course.modifiedAtUtc),
                ),
                if (course.versionNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _readOnlyField('Version notes', course.versionNotes),
                ],
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onVersionHistory();
                  },
                  icon: const Icon(Icons.history_outlined),
                  label: const Text('Version history'),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Languages',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (widget.narrow) ...[
                _readOnlyField(
                  'Base language',
                  _baseLanguage.displayLabel,
                  helperText: _tagHelper(_form.sourceTag),
                ),
                const SizedBox(height: 8),
                _readOnlyField(
                  'Learning language',
                  _learningLanguage.displayLabel,
                  helperText: _tagHelper(_form.targetTag),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _readOnlyField(
                        'Base language',
                        _baseLanguage.displayLabel,
                        helperText: _tagHelper(_form.sourceTag),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _readOnlyField(
                        'Learning language',
                        _learningLanguage.displayLabel,
                        helperText: _tagHelper(_form.targetTag),
                      ),
                    ),
                  ],
                ),
              // Build 275: the kind the creator chose, which never changes.
              if (CourseLanguagePair.isSameLanguage(course))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Same-language Course: everything is in the language '
                    'being learned.',
                    key: const Key('course-info-editor-same-language'),
                  ),
                ),
              if (_form.sourceTag.isEmpty || _form.targetTag.isEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('course-info-language-tags'),
                    icon: const Icon(Icons.sell_outlined),
                    label: const Text('Add the language tags from the list'),
                    onPressed: _addLanguageTags,
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('course-info-learner-language-name'),
                controller: _form.learnerLanguageName,
                maxLength: 60,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Learning language name for learners',
                  hintText: _form.defaultLearnerLanguageName,
                  helper: Text(
                    'How this Course’s learners call the language they learn, in lines such as “Translate into …”. Leave it empty for “${_form.defaultLearnerLanguageName}”.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Course flag',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CourseFlagSelector(
                key: const Key('course-info-flag-selector'),
                selection: _form.flag,
                languageName: _learningLanguage.displayLabel,
                languageTag: _learningLanguage.code,
                onChanged: (selection) =>
                    setState(() => _form.flag = selection),
              ),
              const SizedBox(height: 14),
              CourseCoverField(
                key: const Key('course-info-cover'),
                courseId: course.courseId,
                course: course,
                cover: _form.coverImage,
                onChanged: (choice) =>
                    setState(() => _form.setCover(choice.cover, choice.credit)),
              ),
              const SizedBox(height: 14),
              const Text(
                'Authors',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Roles describe what each person did; they are not a hierarchy. More than one role may be selected.',
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _form.authors.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _form.authors[i].name,
                                  maxLength: 120,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Name',
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove author',
                                onPressed: _form.authors.length == 1
                                    ? null
                                    : () =>
                                          setState(() => _form.removeAuthor(i)),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final role
                                  in CourseMetadataOptions.standardRoles)
                                Tooltip(
                                  message: role == 'Team Leader'
                                      ? 'This is descriptive information only. To assign or change Team Leader roles in QQL, use Team Manager.'
                                      : CourseMetadataOptions
                                                .roleDescriptions[role] ??
                                            role,
                                  child: FilterChip(
                                    label: Text(role),
                                    selected: _form.authors[i].roles.contains(
                                      role,
                                    ),
                                    onSelected: (on) => setState(() {
                                      if (on) {
                                        _form.authors[i].roles.add(role);
                                      } else {
                                        _form.authors[i].roles.remove(role);
                                      }
                                    }),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          for (final role
                              in CourseMetadataOptions.standardRoles.where(
                                (r) => _form.authors[i].roles.contains(r),
                              ))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '$role: ${CourseMetadataOptions.roleDescriptions[role]}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _form.authors[i].customRoles,
                            maxLength: 240,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Custom role(s)',
                              helper: Text(
                                'Optional; separate roles with commas.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(_form.addAuthor),
                  icon: const Icon(Icons.add),
                  label: const Text('Add author'),
                ),
              ),
              const Divider(),
              TextField(
                controller: _form.variant,
                maxLength: 120,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Language variant',
                ),
              ),
              const SizedBox(height: 8),
              if (widget.narrow) ...[
                TextField(
                  controller: _form.startLevel,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Starting level',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _form.targetLevel,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Target level',
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _form.startLevel,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Starting level',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _form.targetLevel,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Target level',
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              _readOnlyField(
                'Course version',
                course.courseVersion.isEmpty
                    ? 'Not confirmed yet'
                    : course.courseVersion,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _form.description,
                minLines: 2,
                maxLines: 5,
                maxLength: 5000,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Course description / information',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _form.buyACoffeeUrl,
                maxLength: 2000,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Buy a Coffee URL (optional)',
                  helper: Text('HTTPS only; shown in Course Info.'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('course-info-estimated-hours'),
                      controller: _form.estimatedHours,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Estimated study hours (optional)',
                        helper: Text('Whole number, 1–1000.'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      key: const Key('course-info-minimum-age'),
                      initialValue: _form.minimumAge,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Minimum age',
                        helper: Text('App Store age classes.'),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Not specified'),
                        ),
                        for (final age in Course.minimumAgeClasses)
                          DropdownMenuItem<int?>(
                            value: age,
                            child: Text('$age+'),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _form.minimumAge = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('course-info-keywords'),
                controller: _form.keywords,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Keywords (optional)',
                  helper: Text(
                    'Separate with commas. Up to 20 keywords of up to 32 characters each.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('course-info-contact-website'),
                controller: _form.contactWebsite,
                maxLength: 500,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Publisher website (optional)',
                  helper: Text(
                    'HTTPS only; shown as plain text in Course Info.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('course-info-contact-email'),
                controller: _form.contactEmail,
                maxLength: 254,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Publisher email (optional)',
                  helper: Text('Shown as plain text in Course Info.'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('course-info-minimum-app-build'),
                controller: _form.minimumAppBuild,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Minimum QuisquisLingo build (optional)',
                  helper: Text(
                    'Older builds refuse this Course. Leave empty unless it needs a recent feature. This is build ${Course.appBuildNumber}.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'License / Rights',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _form.licenseChoice,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Course content license',
                ),
                items: [
                  for (final v in CourseMetadataOptions.standardLicenses)
                    DropdownMenuItem(
                      value: v,
                      child: Text(v, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(
                  () => _form.chooseLicense(v ?? _form.licenseChoice),
                ),
              ),
              if (CourseCredits.isCustomLicenseChoice(_form.licenseChoice)) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _form.customLicense,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Custom license',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<DerivativeWorksPolicy>(
                  initialValue: _form.derivativePolicy,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Derivative works for other users',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: DerivativeWorksPolicy.allowed,
                      child: Text('Allowed', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: DerivativeWorksPolicy.forbidden,
                      child: Text('Forbidden', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: DerivativeWorksPolicy.unspecified,
                      child: Text(
                        'Not specified',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(
                    () => _form.derivativePolicy =
                        value ?? _form.derivativePolicy,
                  ),
                ),
              ],
              // Build 258 Revision 4 (owner decision): on by default.
              SwitchListTile(
                key: const Key('course-info-page-sharing'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Learners may share, save and print pages'),
                subtitle: const Text(
                  'Shows Share, Save PDF and Print under every Page; the PDF credits this Course, its rights holder and licence. A courtesy, not protection: a screenshot is always possible.',
                ),
                value: _form.allowPageSharing,
                onChanged: (value) =>
                    setState(() => _form.allowPageSharing = value),
              ),
              // Build 259 Revision 8 (owner decisions): the flag stored as
              // temporarySample, shown as Private course.
              SwitchListTile(
                key: const Key('course-info-private'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Private course'),
                subtitle: const Text(
                  'Visible in QQL only to the Course Maintainer and the members of its assigned Team; nobody else on this device sees it, admins included. An exported file stays private; Fork and Copy as New Course start non-private.',
                ),
                value: _form.privateCourse,
                onChanged: (value) =>
                    setState(() => _form.privateCourse = value),
              ),
              // Build 270 Revision 9 (owner decisions of 10 October
              // 2026): kept on this device, never in the Course file.
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                key: const Key('course-info-backups-kept'),
                initialValue: _form.backupsKept,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Backups kept on this device',
                  helperText:
                      'After a save that leaves more backups, QQL asks before deleting the older ones; nothing is deleted without your yes. A setting of this device, not of the Course file.',
                  helperMaxLines: 4,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'All (never ask)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final keep in CourseBackupRetention.choices)
                    DropdownMenuItem<int?>(
                      value: keep,
                      child: Text(
                        'The newest $keep',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _form.backupsKept = value),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rights Holder records rights ownership information. It does not control QQL permissions.',
              ),
              const SizedBox(height: 8),
              for (
                var rightsIndex = 0;
                rightsIndex < _form.rightsHolders.length;
                rightsIndex++
              )
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Rights Holder ${rightsIndex + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove Rights Holder',
                              onPressed: _form.rightsHolders.length == 1
                                  ? null
                                  : () => setState(
                                      () =>
                                          _form.removeRightsHolder(rightsIndex),
                                    ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                        DropdownButtonFormField<CourseRightsHolderType>(
                          key: ValueKey(
                            'course-info-rights-holder-type-$rightsIndex',
                          ),
                          initialValue: _form.rightsHolders[rightsIndex].type,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Rights Holder type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: CourseRightsHolderType.person,
                              child: Text('Person'),
                            ),
                            DropdownMenuItem(
                              value: CourseRightsHolderType.organization,
                              child: Text('Organization'),
                            ),
                          ],
                          onChanged: (value) => setState(() {
                            _form.rightsHolders[rightsIndex].type =
                                value ?? _form.rightsHolders[rightsIndex].type;
                          }),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: ValueKey(
                            'course-info-rights-holder-name-$rightsIndex',
                          ),
                          controller: _form.rightsHolders[rightsIndex].name,
                          maxLength: 240,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Rights Holder',
                            helper: Text(
                              'A person or organization; descriptive only.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('course-info-add-rights-holder'),
                  onPressed: () => setState(_form.addRightsHolder),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Rights Holder'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Media credits',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Credit images and recordings made by someone else: an imported picture, a recording another person performed, a custom Lesson icon or course flag. Media that came with QuisquisLingo is already credited in App Info and needs no entry here. These credits travel inside the Course file even when the media files themselves do not. They are descriptive only and do not control QQL permissions.',
              ),
              const SizedBox(height: 8),
              for (
                var creditIndex = 0;
                creditIndex < _form.mediaCredits.length;
                creditIndex++
              )
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Media credit ${creditIndex + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove media credit',
                              onPressed: _form.mediaCredits.length == 1
                                  ? null
                                  : () => setState(
                                      () =>
                                          _form.removeMediaCredit(creditIndex),
                                    ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                        TextField(
                          key: ValueKey(
                            'course-info-media-author-$creditIndex',
                          ),
                          controller: _form.mediaCredits[creditIndex].author,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Author',
                            helper: Text('Who must be credited.'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: ValueKey(
                            'course-info-media-license-$creditIndex',
                          ),
                          controller: _form.mediaCredits[creditIndex].license,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Licence',
                            helper: Text(
                              'As the creator states it, for example CC BY-SA 4.0.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: ValueKey('course-info-media-title-$creditIndex'),
                          controller: _form.mediaCredits[creditIndex].title,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Title (optional)',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: ValueKey(
                            'course-info-media-source-$creditIndex',
                          ),
                          controller: _form.mediaCredits[creditIndex].source,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Source (optional)',
                            helper: Text(
                              'A page reference or address. Shown as plain text, never opened.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: ValueKey(
                            'course-info-media-applies-to-$creditIndex',
                          ),
                          controller: _form.mediaCredits[creditIndex].appliesTo,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Applies to (optional)',
                            helper: Text(
                              'Which media in this course it covers.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_form.mediaCreditError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    _form.mediaCreditError!,
                    key: const Key('course-info-media-credit-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('course-info-add-media-credit'),
                  onPressed: () => setState(_form.addMediaCredit),
                  icon: const Icon(Icons.add),
                  label: const Text('Add media credit'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('course-info-save'),
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
