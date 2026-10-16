import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/new_course_form.dart';
import '../models/course_metadata_options.dart';
import '../models/course_models.dart';
import '../services/course_credits.dart';
import '../services/course_language_pair.dart';
import '../services/course_language_resolver.dart';
import '../services/course_library_operations.dart';
import '../services/course_media_store.dart';
import '../services/course_wizard.dart';
import '../services/profile_service.dart';
import '../widgets/course_cover_field.dart';
import '../widgets/course_flag_picker.dart';
import '../widgets/course_kind_choice.dart';
import '../widgets/language_field.dart';

/// Opens New Course's form for [creator], the active learner. Returns the
/// unsaved Draft Course the Course Editor continues with, or null when the
/// author cancels.
///
/// [prefill] carries the title, languages and variant of the Course Wizard's
/// first screen (Build 267, Continue by hand). [maintainers] are the
/// learners of this device, [titleTaken] tells whether a Course already has
/// a name, and [operations] builds the Course.
Future<Course?> showNewCourseDialog(
  BuildContext context, {
  required LearnerProfile creator,
  required List<LearnerProfile> maintainers,
  required CourseLibraryOperations operations,
  required bool Function(String title) titleTaken,
  CourseWizardBasics? prefill,
}) async {
  final form = NewCourseForm(creator: creator, prefill: prefill);
  final course = await showDialog<Course>(
    context: context,
    builder: (_) => NewCourseDialog(
      form: form,
      maintainers: maintainers,
      operations: operations,
      titleTaken: titleTaken,
    ),
  );
  // Build 255 Revision 7: a cover chosen in the form is stored before the
  // Course exists; a cancelled form deletes it.
  if (course == null && form.coverStored) {
    unawaited(CourseMediaStore().deleteCourse(form.courseId));
  }
  return course;
}

/// New Course's form as a dialog (Build 272 Revision 3: a widget of its own;
/// before, one method of the Course Studio screen). It draws a
/// [NewCourseForm], which owns the fields and the Course they make.
class NewCourseDialog extends StatefulWidget {
  const NewCourseDialog({
    super.key,
    required this.form,
    required this.maintainers,
    required this.operations,
    required this.titleTaken,
  });

  /// The form drawn. The dialog disposes it when it leaves the screen.
  final NewCourseForm form;

  /// The learners of this device, for the Course Maintainer list.
  final List<LearnerProfile> maintainers;

  /// Builds the Course from the form's values.
  final CourseLibraryOperations operations;

  /// Whether a Course already has this name; the author may go on anyway.
  final bool Function(String title) titleTaken;

  @override
  State<NewCourseDialog> createState() => _NewCourseDialogState();
}

class _NewCourseDialogState extends State<NewCourseDialog> {
  NewCourseForm get _form => widget.form;

  @override
  void dispose() {
    // The dialog has left the screen: its fields are no longer drawn.
    _form.dispose();
    super.dispose();
  }

  void _tell(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// Continue to Editor: the name first (with the warning for a name
  /// another Course has), then the form says whether it makes a Course.
  Future<void> _continue() async {
    final String title;
    try {
      title = _form.validTitle();
    } on ArgumentError catch (error) {
      _tell(error.message?.toString() ?? 'Check the Course name.');
      return;
    }
    // Build 275 Revision 0: the kind is told; the language fields show
    // what is missing.
    final kindProblem = _form.kindProblem;
    if (kindProblem != null) {
      _tell(kindProblem);
      return;
    }
    if (!_form.languagesChosen) return;
    if (widget.titleTaken(title)) {
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
      if (continueAnyway != true || !mounted) return;
    }
    switch (_form.submit(title, widget.operations)) {
      case NewCourseAccepted(:final course):
        Navigator.pop(context, course);
      case NewCourseRefused(:final message):
        if (message != null) _tell(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create new course'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Continue to Editor to prepare this course. It is saved only when you confirm the course changes in the editor.',
              ),
              const SizedBox(height: 12),
              CourseKindChoice(
                kind: _form.kind,
                keyPrefix: 'new-course',
                onChanged: (kind) => setState(() => _form.kind = kind),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _form.title,
                maxLength: 120,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Course title *',
                ),
              ),
              if (_form.kind == CourseKind.sameLanguage) ...[
                const SizedBox(height: 8),
                LanguageField(
                  key: const ValueKey('new-course-language-field'),
                  controller: _form.target,
                  label: 'Language *',
                  keyPrefix: 'new-course-language',
                  onChanged: () => setState(() {}),
                ),
              ] else if (_form.kind == CourseKind.otherLanguage) ...[
                const SizedBox(height: 8),
                LanguageField(
                  controller: _form.source,
                  label: 'Source language *',
                  keyPrefix: 'new-course-source-language',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 8),
                LanguageField(
                  controller: _form.target,
                  label: 'Target language *',
                  keyPrefix: 'new-course-target-language',
                  onChanged: () => setState(() {}),
                ),
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('new-course-owner'),
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
                  for (final profile in widget.maintainers)
                    DropdownMenuItem(
                      value: profile.learnerProfileId,
                      child: Tooltip(
                        message:
                            profile.learnerProfileId ==
                                _form.creator.learnerProfileId
                            ? '${profile.presentationName} (Original Course Creator)'
                            : profile.presentationName,
                        child: Text(
                          profile.learnerProfileId ==
                                  _form.creator.learnerProfileId
                              ? '${profile.presentationName} (Original Course Creator)'
                              : profile.presentationName,
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
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Authors and credits',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Credits are descriptive only and never grant editing permission.',
                ),
              ),
              const SizedBox(height: 8),
              for (
                var authorIndex = 0;
                authorIndex < _form.authors.length;
                authorIndex++
              )
                Card(
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
                                key: ValueKey(
                                  'new-course-credit-name-$authorIndex',
                                ),
                                controller: _form.authors[authorIndex].name,
                                maxLength: 120,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Name',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove credit',
                              onPressed: _form.authors.length == 1
                                  ? null
                                  : () => setState(
                                      () => _form.removeAuthor(authorIndex),
                                    ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final role
                                in CourseMetadataOptions.standardRoles)
                              FilterChip(
                                label: Text(role),
                                selected: _form.authors[authorIndex].roles
                                    .contains(role),
                                onSelected: (selected) => setState(() {
                                  if (selected) {
                                    _form.authors[authorIndex].roles.add(role);
                                  } else {
                                    _form.authors[authorIndex].roles.remove(
                                      role,
                                    );
                                  }
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _form.authors[authorIndex].customRoles,
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
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('new-course-add-credit'),
                  onPressed: () => setState(_form.addAuthor),
                  icon: const Icon(Icons.add),
                  label: const Text('Add author or contributor'),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'License / Rights',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('new-course-license'),
                initialValue: _form.licenseChoice,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Course content license',
                ),
                items: [
                  for (final license in CourseMetadataOptions.standardLicenses)
                    DropdownMenuItem(
                      value: license,
                      child: Text(license, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(
                  () => _form.chooseLicense(value ?? _form.licenseChoice),
                ),
              ),
              if (CourseCredits.isCustomLicenseChoice(_form.licenseChoice)) ...[
                const SizedBox(height: 8),
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
                  key: const Key('new-course-derivative-policy'),
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
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rights Holder records rights ownership information. It does not control QQL permissions.',
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  CourseCredits.rightsHolderDefaultNote,
                  key: const Key('new-course-rights-holder-note'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
                            'new-course-rights-holder-type-$rightsIndex',
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
                            'new-course-rights-holder-name-$rightsIndex',
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
                  key: const Key('new-course-add-rights-holder'),
                  onPressed: () => setState(_form.addRightsHolder),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Rights Holder'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _form.variant,
                maxLength: 120,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Language variant',
                ),
              ),
              const SizedBox(height: 8),
              Row(
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
                  helper: Text('HTTPS only.'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('new-course-lesson-count'),
                controller: _form.lessonCount,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Number of Lessons',
                  helper: const Text('1–100. Default: 3.'),
                  errorText: _form.lessonCountProblem,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('new-course-round-count'),
                controller: _form.roundsPerLesson,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Rounds per Lesson',
                  helper: const Text('1–20. Default: 1.'),
                  errorText: _form.roundCountProblem,
                ),
              ),
              const SizedBox(height: 8),
              const Text('You can add or delete Lessons and Rounds later.'),
              const Text('Each Round starts with a sample exercise.'),
              const SizedBox(height: 12),
              CourseFlagSelector(
                selection: _form.flag,
                languageName: _form.target.text.text,
                languageTag: _form.target.choice?.tag.isNotEmpty == true
                    ? _form.target.choice!.tag
                    : CourseLanguageResolver.codeFromMetadata([
                        _form.target.text.text,
                      ]),
                onChanged: (selection) =>
                    setState(() => _form.flag = selection),
              ),
              const SizedBox(height: 12),
              CourseCoverField(
                key: const Key('new-course-cover'),
                courseId: _form.courseId,
                cover: _form.coverImage,
                onChanged: (choice) =>
                    setState(() => _form.setCover(choice.cover, choice.credit)),
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
          onPressed: _form.countsValid ? _continue : null,
          child: const Text('Continue to Editor'),
        ),
      ],
    );
  }
}
