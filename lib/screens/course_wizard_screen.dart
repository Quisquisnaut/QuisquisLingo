import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/course_flag_selection.dart';
import '../models/course_metadata_options.dart';
import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../services/authoring_duplication_service.dart';
import '../services/course_access_policy.dart';
import '../services/course_authoring_session.dart';
import '../services/course_language_resolver.dart';
import '../services/course_library_operations.dart';
import '../services/course_service.dart';
import '../services/course_wizard.dart';
import '../services/duel_eligibility_service.dart';
import '../services/formal_name_policy.dart';
import '../services/guidebook_picture_match.dart';
import '../services/guidebook_round_links.dart';
import '../services/lesson_icon_catalog.dart';
import '../services/lesson_presentation_service.dart';
import '../services/round_type_presentation.dart';
import '../services/settings_service.dart';
import '../services/timed_round_rules.dart';
import '../widgets/course_cover_field.dart';
import '../widgets/course_flag_picker.dart';
import '../widgets/language_field.dart';
import '../widgets/lesson_fallback_icon.dart';
import '../widgets/reported_action.dart';
import 'course_editor_screen.dart' show GuidebookRoundGeneratorScreen;
import 'editor_help_screen.dart';
import 'flat_image_library_screen.dart';
import 'guidebook_editor_screen.dart';

/// The Course Wizard (Build 267, `docs/267_COURSE_WIZARD_PLAN.md`).
///
/// Without [course] it is New Course's first screen, Basics: the author then
/// continues with the Wizard, which saves the Course at once, or creates the
/// Course by hand with the New Course form. With [course] it continues a
/// paused Wizard on the stored Course, re-read by the caller, so changes made
/// by hand in the meantime are kept.
///
/// Every save is an ordinary confirmed Course save through one
/// [CourseAuthoringSession] (version + 1, a backup, Version History), with
/// version notes naming the step. The screen pops a [CourseWizardOutcome].
class CourseWizardScreen extends StatefulWidget {
  const CourseWizardScreen({
    super.key,
    this.course,
    this.access,
    this.pause,
    this.operations,
    this.titleTaken,
    this.clock,
  });

  /// The stored Course of a paused Wizard; null starts a new Course.
  final Course? course;

  /// What the active profile may do with [course].
  final CourseAccessCapabilities? access;

  /// Where the paused Wizard stopped.
  final CourseWizardPause? pause;
  final CourseLibraryOperations? operations;

  /// New Course's duplicate-name warning.
  final bool Function(String title)? titleTaken;
  final DateTime Function()? clock;

  @override
  State<CourseWizardScreen> createState() => _CourseWizardScreenState();
}

class _CreditRow {
  _CreditRow({String name = '', Set<String>? roles, String customRoles = ''})
    : name = TextEditingController(text: name),
      roles = roles ?? {'Author'},
      customRoles = TextEditingController(text: customRoles);

  factory _CreditRow.of(CourseAuthor author) => _CreditRow(
    name: author.name,
    roles: {
      for (final role in author.roles)
        if (CourseMetadataOptions.standardRoles.contains(role)) role,
    },
    customRoles: author.roles
        .where((role) => !CourseMetadataOptions.standardRoles.contains(role))
        .join(', '),
  );

  final TextEditingController name;
  final Set<String> roles;
  final TextEditingController customRoles;

  CourseAuthor? get value {
    final trimmed = name.text.trim();
    if (trimmed.isEmpty) return null;
    final list = <String>[
      ...CourseMetadataOptions.standardRoles.where(roles.contains),
    ];
    for (final part in customRoles.text.split(',')) {
      final role = part.trim();
      if (role.isNotEmpty && !list.contains(role)) list.add(role);
    }
    if (list.isEmpty) list.add('Contributor');
    return CourseAuthor(name: trimmed, roles: list);
  }

  void dispose() {
    name.dispose();
    customRoles.dispose();
  }
}

class _HolderRow {
  _HolderRow({this.type = CourseRightsHolderType.person, String name = ''})
    : name = TextEditingController(text: name);

  CourseRightsHolderType type;
  final TextEditingController name;

  void dispose() => name.dispose();
}

class _LessonRow {
  _LessonRow({
    this.lessonId,
    String title = '',
    this.iconAsset,
    String sectionName = '',
  }) : title = TextEditingController(text: title),
       section = TextEditingController(text: sectionName);

  factory _LessonRow.of(CourseWizardLessonDraft draft) => _LessonRow(
    lessonId: draft.lessonId,
    title: draft.title,
    iconAsset: draft.iconAsset,
    sectionName: draft.sectionName,
  );

  final String? lessonId;
  final TextEditingController title;
  final TextEditingController section;
  String? iconAsset;

  CourseWizardLessonDraft get draft => CourseWizardLessonDraft(
    lessonId: lessonId,
    title: title.text,
    iconAsset: iconAsset,
    sectionName: section.text,
  );

  void dispose() {
    title.dispose();
    section.dispose();
  }
}

class _CourseWizardScreenState extends State<CourseWizardScreen> {
  late final CourseLibraryOperations _ops =
      widget.operations ?? CourseLibraryOperations();
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  final _ids = TimestampAuthoringIdGenerator();

  CourseAuthoringSession? _session;
  CourseWizardStep _step = CourseWizardStep.basics;
  CourseWizardStep _furthest = CourseWizardStep.basics;
  bool _busy = false;
  bool _closing = false;
  String _authorName = '';

  /// Bumped whenever the fields are refilled, so keyed fields take the new
  /// values.
  int _generation = 0;

  // Step 1.
  final _title = TextEditingController();
  final _source = LanguageFieldController(name: 'English');
  final _target = LanguageFieldController();
  final _variant = TextEditingController();

  // Step 2.
  final _description = TextEditingController();
  final _startLevel = TextEditingController();
  final _targetLevel = TextEditingController();
  final _studyHours = TextEditingController();
  final _keywords = TextEditingController();
  String _cover = '';
  CourseMediaAttribution? _coverCredit;
  int? _minimumAge;
  CourseFlagSelection _flag = const CourseFlagSelection.automatic();

  // Step 3.
  final _creditRows = <_CreditRow>[];
  String _licenseChoice = CourseWizardCredits.defaultLicense;
  final _customLicense = TextEditingController();
  DerivativeWorksPolicy _derivative = DerivativeWorksPolicy.forbidden;
  final _holderRows = <_HolderRow>[];
  final _buyACoffee = TextEditingController();
  final _contactWebsite = TextEditingController();
  final _contactEmail = TextEditingController();

  // Step 4.
  CourseWizardOptions _options = CourseWizardOptions.defaults;
  final _customLessonLabel = TextEditingController();
  final _customRoundLabel = TextEditingController();

  // Step 5.
  final _lessonRows = <_LessonRow>[];

  // Steps 6 and 7: the Lesson shown, and the Lesson a paused Wizard stopped
  // at (read once).
  int _shownLesson = 0;
  late String? _pausedLessonId = widget.pause?.lessonId;

  static const _customLicenseChoice = 'Other / Custom license';

  Course get _working => _session!.workingCourse;
  bool get _starting => _session == null;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    if (course == null) return;
    _session = CourseAuthoringSession(
      course: course,
      access:
          widget.access ??
          CourseAccessPolicy.evaluate(
            course,
            profileId: course.maintainer?.profileId,
          ),
      editorService: _ops.editor,
      clock: _clock,
    )..setEditorMode(CourseEditorMode.edit);
    final step = widget.pause?.step ?? CourseWizardStep.about;
    _step = step;
    _furthest = step;
    _load(step);
    unawaited(_loadAuthorName());
  }

  Future<void> _loadAuthorName() async {
    final profile = await _ops.profiles.getActiveProfileRecord();
    if (profile != null && mounted) {
      setState(() => _authorName = profile.presentationName);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _variant,
      _description,
      _startLevel,
      _targetLevel,
      _studyHours,
      _keywords,
      _customLicense,
      _buyACoffee,
      _contactWebsite,
      _contactEmail,
      _customLessonLabel,
      _customRoundLabel,
    ]) {
      controller.dispose();
    }
    _source.dispose();
    _target.dispose();
    for (final row in _creditRows) {
      row.dispose();
    }
    for (final row in _holderRows) {
      row.dispose();
    }
    for (final row in _lessonRows) {
      row.dispose();
    }
    super.dispose();
  }

  // ---- Values in and out of the fields

  /// Fills [step]'s fields from the working copy.
  void _load(CourseWizardStep step) {
    final course = _working;
    switch (step) {
      case CourseWizardStep.basics:
        _setBasics(
          CourseWizardBasics(
            title: course.title,
            sourceLanguage: course.sourceLanguage,
            targetLanguage: course.targetLanguage,
            variant: course.languageVariant,
          ),
        );
      case CourseWizardStep.about:
        _setAbout(CourseWizardAbout.of(course));
      case CourseWizardStep.credits:
        _setCredits(CourseWizardCredits.of(course));
      case CourseWizardStep.options:
        _setOptions(CourseWizardOptions.of(course));
      case CourseWizardStep.lessons:
        _setLessons(CourseWizardLessons.of(course));
      case CourseWizardStep.guidebook || CourseWizardStep.rounds:
        final paused = _pausedLessonId;
        _pausedLessonId = null;
        final index = paused == null
            ? -1
            : course.lessons.indexWhere((lesson) => lesson.lessonId == paused);
        _shownLesson = index >= 0
            ? index
            : (step == CourseWizardStep.guidebook
                          ? CourseWizardGuidebook.firstProblem(course)
                          : CourseWizardRounds.firstProblem(course))
                      ?.index ??
                  0;
        _generation++;
    }
  }

  void _setBasics(CourseWizardBasics basics) {
    _title.text = basics.title;
    _variant.text = basics.variant;
    if (_starting) {
      _source.text.text = basics.sourceLanguage;
      _source.tag.clear();
      _target.text.text = basics.targetLanguage;
      _target.tag.clear();
    }
    _generation++;
  }

  void _setAbout(CourseWizardAbout about) {
    _description.text = about.description;
    _startLevel.text = about.startLevel;
    _targetLevel.text = about.targetLevel;
    _studyHours.text = about.studyHours?.toString() ?? '';
    _keywords.text = about.keywords.join(', ');
    _cover = about.coverImage;
    _coverCredit = about.coverCredit;
    _minimumAge = about.minimumAge;
    _flag = about.flag;
    _generation++;
  }

  /// Replaced rows are disposed after the frame that stops showing them.
  void _disposeLater(List<Object> rows) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in rows) {
        switch (row) {
          case _CreditRow():
            row.dispose();
          case _HolderRow():
            row.dispose();
          case _LessonRow():
            row.dispose();
        }
      }
    });
  }

  void _setCredits(CourseWizardCredits credits) {
    _disposeLater([..._creditRows, ..._holderRows]);
    _creditRows
      ..clear()
      ..addAll(credits.authors.map(_CreditRow.of));
    _holderRows
      ..clear()
      ..addAll(
        credits.rightsHolders.map(
          (holder) => _HolderRow(type: holder.type, name: holder.name),
        ),
      );
    final standard = CourseMetadataOptions.standardLicenses.contains(
      credits.license,
    );
    _licenseChoice = standard ? credits.license : _customLicenseChoice;
    _customLicense.text = standard ? '' : credits.license;
    _derivative = credits.derivativePolicy;
    _buyACoffee.text = credits.buyACoffeeUrl;
    _contactWebsite.text = credits.publisherContact?.websiteUrl ?? '';
    _contactEmail.text = credits.publisherContact?.email ?? '';
    _generation++;
  }

  void _setOptions(CourseWizardOptions options) {
    _options = options;
    _customLessonLabel.text = options.customLessonLabel;
    _customRoundLabel.text = options.customRoundLabel;
    _generation++;
  }

  void _setLessons(List<CourseWizardLessonDraft> drafts) {
    _disposeLater([..._lessonRows]);
    _lessonRows
      ..clear()
      ..addAll(drafts.map(_LessonRow.of));
    _generation++;
  }

  CourseWizardBasics get _basicsValue => CourseWizardBasics(
    title: _title.text,
    sourceLanguage: _source.text.text,
    targetLanguage: _target.text.text,
    variant: _variant.text,
  );

  CourseWizardAbout get _aboutValue => CourseWizardAbout(
    description: _description.text,
    startLevel: _startLevel.text,
    targetLevel: _targetLevel.text,
    coverImage: _cover,
    coverCredit: _coverCredit,
    studyHours: int.tryParse(_studyHours.text.trim()),
    minimumAge: _minimumAge,
    keywords: CourseWizardAbout.keywordsFrom(_keywords.text),
    flag: _flag,
  );

  /// Throws a [FormatException] for an address that cannot be stored.
  CourseWizardCredits get _creditsValue => CourseWizardCredits(
    authors: [
      for (final row in _creditRows)
        if (row.value case final author?) author,
    ],
    license: _licenseChoice == _customLicenseChoice
        ? _customLicense.text.trim()
        : _licenseChoice,
    derivativePolicy: _licenseChoice == _customLicenseChoice
        ? _derivative
        : CourseMetadataOptions.derivativePolicyForLicense(_licenseChoice),
    rightsHolders: [
      for (final row in _holderRows)
        if (row.name.text.trim().isNotEmpty)
          CourseRightsHolder(type: row.type, name: row.name.text.trim()),
    ],
    buyACoffeeUrl: Course.normalizeBuyACoffeeUrl(_buyACoffee.text),
    publisherContact: CoursePublisherContact.fromFields(
      _contactWebsite.text,
      _contactEmail.text,
    ),
  );

  CourseWizardOptions get _optionsValue => _options.copyWith(
    customLessonLabel: _customLessonLabel.text,
    customRoundLabel: _customRoundLabel.text,
  );

  List<CourseWizardLessonDraft> get _lessonDrafts => [
    for (final row in _lessonRows) row.draft,
  ];

  /// Why the current step's values cannot be stored, or null.
  String? get _problem {
    switch (_step) {
      case CourseWizardStep.basics:
        final title = _title.text.trim();
        if (title.isEmpty) return 'Give the Course a title.';
        try {
          FormalNamePolicy.validatePresentationLabel(
            title,
            parameterName: 'courseName',
          );
        } on ArgumentError catch (error) {
          return error.message?.toString() ?? 'Check the Course title.';
        }
        if (_starting) {
          if (_source.isEmpty) return 'Choose the source language.';
          if (_target.isEmpty) return 'Choose the target language.';
          if (_source.tagError != null) return _source.tagError;
          if (_target.tagError != null) return _target.tagError;
        }
        return null;
      case CourseWizardStep.about:
        return CourseWizardAbout.studyHoursProblem(_studyHours.text) ??
            CourseWizardAbout.keywordsProblem(_keywords.text);
      case CourseWizardStep.credits:
        if (_licenseChoice == _customLicenseChoice &&
            _customLicense.text.trim().isEmpty) {
          return 'Type the custom license, or choose a license from the list.';
        }
        try {
          _creditsValue;
        } on FormatException catch (error) {
          return error.message;
        }
        return null;
      case CourseWizardStep.options:
        return _optionsValue.problem;
      case CourseWizardStep.lessons:
        return CourseWizardLessons.problem(_lessonDrafts);
      case CourseWizardStep.guidebook || CourseWizardStep.rounds:
        // Their changes go into the working copy as they are made.
        return null;
    }
  }

  /// The working copy with the current step's values.
  Course _candidate() => switch (_step) {
    CourseWizardStep.basics => _basicsValue.applyTo(_working),
    CourseWizardStep.about => _aboutValue.applyTo(_working),
    CourseWizardStep.credits => _creditsValue.applyTo(_working),
    CourseWizardStep.options => _optionsValue.applyTo(_working),
    CourseWizardStep.lessons => CourseWizardLessons.applyTo(
      _working,
      _lessonDrafts,
      now: _clock(),
      ids: _ids,
    ),
    CourseWizardStep.guidebook || CourseWizardStep.rounds => _working,
  };

  /// Whether the current step holds something Fill or Clear all would
  /// replace.
  bool get _stepHoldsSomething => switch (_step) {
    CourseWizardStep.basics =>
      _title.text.trim().isNotEmpty ||
          _variant.text.trim().isNotEmpty ||
          (_starting && !_target.isEmpty),
    CourseWizardStep.about =>
      [
            _description,
            _startLevel,
            _targetLevel,
            _studyHours,
            _keywords,
          ].any((controller) => controller.text.trim().isNotEmpty) ||
          _cover.isNotEmpty ||
          _minimumAge != null ||
          _flag != const CourseFlagSelection.automatic(),
    CourseWizardStep.credits =>
      _creditRows.isNotEmpty ||
          _holderRows.isNotEmpty ||
          _licenseChoice != CourseWizardCredits.defaultLicense ||
          [
            _buyACoffee,
            _contactWebsite,
            _contactEmail,
          ].any((controller) => controller.text.trim().isNotEmpty),
    CourseWizardStep.options => !_optionsValue.isDefault,
    CourseWizardStep.lessons => _lessonRows.isNotEmpty,
    CourseWizardStep.guidebook =>
      _currentLesson?.guidebook.modules.isNotEmpty ?? false,
    CourseWizardStep.rounds => _currentLesson?.rounds.isNotEmpty ?? false,
  };

  /// Whether leaving now would lose something: a change not yet saved.
  bool get _unsaved {
    final session = _session;
    if (session == null) return false;
    if (session.hasChanges) return true;
    if (_problem != null) return true;
    try {
      return jsonEncode(_candidate().toJson()) != jsonEncode(_working.toJson());
    } catch (_) {
      return true;
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Moving and saving

  /// Puts the current step's values into the working copy, without saving.
  /// False, with the reason shown, when they cannot be stored.
  bool _stage() {
    final problem = _problem;
    if (problem != null) {
      _tell(problem);
      return false;
    }
    final Course candidate;
    try {
      candidate = _candidate();
    } catch (error) {
      _tell('$error'.replaceFirst(RegExp(r'^\w+(Error|Exception): '), ''));
      return false;
    }
    if (jsonEncode(candidate.toJson()) != jsonEncode(_working.toJson())) {
      _session!.stageCourse(candidate);
    }
    return true;
  }

  /// Stages the current step and saves the Course when it changed: an
  /// ordinary confirmed save, its version notes naming the step.
  Future<bool> _save() async {
    if (!_stage()) return false;
    final session = _session!;
    if (!session.hasChanges) return true;
    final result = await runReported(
      context,
      'Saving the Course',
      () => session.confirm(
        languageCode: CourseService.codeForCourse(session.workingCourse),
        versionNotes: 'Course Wizard: ${_step.title}',
      ),
    );
    return result != null;
  }

  Future<void> _remember(CourseWizardStep step) async {
    final session = _session;
    if (session == null) return;
    final course = session.workingCourse;
    final lesson =
        step == CourseWizardStep.guidebook || step == CourseWizardStep.rounds
        ? _currentLesson
        : null;
    try {
      await _ops.wizardMemory.remember(
        course.courseId,
        CourseWizardPause(
          step: step,
          savedAtUtc: _clock().toUtc(),
          lessonId: lesson?.lessonId,
        ),
      );
    } catch (_) {
      // The Course is saved either way; Course Studio then shows no pause.
    }
  }

  Future<void> _goTo(CourseWizardStep step) async {
    setState(() {
      _step = step;
      if (step.index > _furthest.index) _furthest = step;
      _load(step);
    });
    await _remember(step);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Continue with the Course Wizard: the Course is created and saved now,
  /// as a Draft with no Lessons.
  Future<void> _begin() => _run(() async {
    final problem = _problem;
    if (problem != null) {
      _tell(problem);
      return;
    }
    final title = _title.text.trim();
    if (widget.titleTaken?.call(title) == true &&
        !await _confirm(
          key: const Key('course-wizard-title-taken-confirm'),
          title: 'Course name already exists',
          message: 'A Course with this name already exists.',
          action: 'Continue anyway',
          cancel: 'Edit name',
        )) {
      return;
    }
    if (!mounted) return;
    final profile = await _ops.profiles.getActiveProfileRecord();
    if (!mounted) return;
    if (profile == null) {
      _tell('Select or create a learner profile first.');
      return;
    }
    final source = _source.choice!;
    final target = _target.choice!;
    final course = _ops.newWizardCourse(
      creator: profile,
      title: title,
      sourceLanguage: source.name,
      targetLanguage: target.name,
      sourceLanguageTag: source.tag,
      targetLanguageTag: target.tag,
      languageVariant: _variant.text.trim(),
    );
    final session = CourseAuthoringSession(
      course: course,
      access: CourseAccessPolicy.evaluate(
        course,
        profileId: profile.learnerProfileId,
      ).copyForUnconfirmedCreator(),
      editorService: _ops.editor,
      isNewCourse: true,
      clock: _clock,
    )..setEditorMode(CourseEditorMode.edit);
    final saved = await runReported(
      context,
      'Creating the Course',
      () => session.confirm(
        languageCode: CourseService.codeForCourse(course),
        versionNotes: 'Course Wizard: ${CourseWizardStep.basics.title}',
      ),
    );
    if (saved == null) {
      await session.discardUnconfirmedMedia();
      return;
    }
    if (!mounted) return;
    _authorName = profile.presentationName;
    _session = session;
    await _goTo(CourseWizardStep.about);
  });

  /// Create it myself: New Course's form with what this screen holds.
  void _createManually() {
    final source = _source.choice;
    final target = _target.choice;
    Navigator.of(context).pop(
      CourseWizardCreateManually(
        CourseWizardBasics(
          title: _title.text.trim(),
          sourceLanguage: source?.name ?? _source.text.text.trim(),
          sourceLanguageTag: source?.tag ?? '',
          targetLanguage: target?.name ?? _target.text.text.trim(),
          targetLanguageTag: target?.tag ?? '',
          variant: _variant.text.trim(),
        ),
      ),
    );
  }

  Future<void> _next() => _run(() async {
    if (_step == CourseWizardStep.lessons && _lessonRows.isEmpty) {
      _tell('Add at least one Lesson.');
      return;
    }
    if (_step == CourseWizardStep.guidebook ||
        _step == CourseWizardStep.rounds) {
      final problem = _step == CourseWizardStep.guidebook
          ? CourseWizardGuidebook.firstProblem(_working)
          : CourseWizardRounds.firstProblem(_working);
      if (problem != null) {
        setState(() => _shownLesson = problem.index);
        _tell(problem.problem);
        return;
      }
    }
    if (!await _save()) return;
    final next = _step.next;
    if (next == null) {
      await _close(finish: true);
      return;
    }
    await _goTo(next);
  });

  Future<void> _back() async {
    final previous = _step.previous;
    if (previous == null || _busy || !_stage()) return;
    await _goTo(previous);
  }

  Future<void> _jumpTo(CourseWizardStep step) async {
    if (step == _step || _busy || !_stage()) return;
    await _goTo(step);
  }

  Future<void> _saveForNow() => _run(() async {
    if (!await _save()) return;
    await _close(finish: false, saved: true);
  });

  /// Continue by hand: saves, forgets the Wizard and opens the Course Editor.
  Future<void> _byHand() => _run(() async {
    if (!await _save()) return;
    await _close(finish: true);
  });

  /// Ends the Wizard. [finish] forgets it and opens the Course Editor;
  /// otherwise it stays paused at this step, and the SnackBar says where to
  /// continue ([saved]: after Save for now).
  Future<void> _close({required bool finish, bool saved = false}) async {
    final session = _session!;
    final course = session.originalCourse;
    try {
      if (finish) {
        await _ops.wizardMemory.forget(course.courseId);
      } else {
        await _remember(_step);
      }
    } catch (_) {}
    await session.discardUnconfirmedMedia();
    if (!mounted) return;
    _closing = true;
    if (!finish) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('course-wizard-saved-for-now'),
          content: Text(
            '${saved ? 'Saved.' : 'Course Wizard paused.'} Continue it from '
            'the Course\'s ⋮ menu in Course Studio.',
          ),
        ),
      );
    }
    Navigator.of(
      context,
    ).pop(finish ? CourseWizardOpenEditor(course) : CourseWizardPaused(course));
  }

  /// The back button: on the first screen nothing is created; later the
  /// Wizard stays paused, and an unsaved change is saved or left first.
  Future<void> _leave() async {
    if (_busy) return;
    if (_starting) {
      _closing = true;
      Navigator.of(context).pop();
      return;
    }
    if (!_unsaved) {
      await _run(() => _close(finish: false));
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('course-wizard-leave'),
        title: const Text('Leave the Course Wizard?'),
        content: const Text(
          'This step has changes that are not saved yet. Save for now keeps '
          'them; you can continue the Wizard later from the Course\'s ⋮ menu '
          'in Course Studio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep working'),
          ),
          TextButton(
            key: const Key('course-wizard-leave-discard'),
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: const Text('Leave without saving'),
          ),
          FilledButton(
            key: const Key('course-wizard-leave-save'),
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Save for now'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'save') {
      await _saveForNow();
      return;
    }
    _session!.cancel();
    await _run(() => _close(finish: false));
  }

  Future<bool> _confirm({
    required Key key,
    required String title,
    required String message,
    required String action,
    String cancel = 'Cancel',
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(cancel),
            ),
            FilledButton(
              key: key,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  /// Fill with an example: the built-in sample Course's values for this
  /// step, asking first when the step holds something.
  Future<void> _fillExample() async {
    // The Rounds step's example is the Round Wizard with its recommended
    // settings, which it starts with; its plan comes before anything.
    if (_step == CourseWizardStep.rounds) {
      await _makeRounds();
      return;
    }
    if (_stepHoldsSomething &&
        !await _confirm(
          key: const Key('course-wizard-fill-example-confirm'),
          title: 'Fill with an example?',
          message: switch (_step) {
            CourseWizardStep.lessons => _lessonReplaceMessage(
              'The example replaces the Lessons of this step.',
            ),
            CourseWizardStep.guidebook => _moduleReplaceMessage(
              'The example replaces this Lesson\'s modules.',
              'Replacing',
            ),
            _ => 'The example replaces what this step holds.',
          },
          action: 'Fill',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      switch (_step) {
        case CourseWizardStep.basics:
          _setBasics(CourseWizardSample.basics);
        case CourseWizardStep.about:
          // The cover stays: the example has no picture of its own.
          final cover = _cover;
          final credit = _coverCredit;
          _setAbout(CourseWizardSample.about);
          _cover = cover;
          _coverCredit = credit;
        case CourseWizardStep.credits:
          _setCredits(CourseWizardSample.credits(_authorName));
        case CourseWizardStep.options:
          _setOptions(CourseWizardSample.options);
        case CourseWizardStep.lessons:
          _setLessons(CourseWizardSample.lessons);
        case CourseWizardStep.guidebook:
          _setModules(CourseWizardSample.guidebook(_ids));
        case CourseWizardStep.rounds:
          break;
      }
    });
  }

  /// Clear all: empties this step only, asking first unless it is empty.
  Future<void> _clearAll() async {
    if (_stepHoldsSomething &&
        !await _confirm(
          key: const Key('course-wizard-clear-all-confirm'),
          title: 'Clear this step?',
          message: switch (_step) {
            CourseWizardStep.lessons => _lessonReplaceMessage(
              'Clear all removes every Lesson.',
            ),
            CourseWizardStep.guidebook => _moduleReplaceMessage(
              'Clear all removes this Lesson\'s modules.',
              'Clearing',
            ),
            CourseWizardStep.rounds =>
              'Clear all removes the ${_currentLesson?.rounds.length ?? 0} '
                  'Rounds of Lesson ${_shownLesson + 1}, with their '
                  'exercises. Nothing is saved until you press Next or Save '
                  'for now; Version History can bring back any earlier save.',
            _ =>
              'Clear all empties this step. Steps you have already saved '
                  'stay as they are; Version History can bring back any '
                  'earlier save.',
          },
          action: 'Clear all',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      switch (_step) {
        case CourseWizardStep.basics:
          _setBasics(const CourseWizardBasics());
        case CourseWizardStep.about:
          _setAbout(const CourseWizardAbout());
        case CourseWizardStep.credits:
          _setCredits(const CourseWizardCredits());
        case CourseWizardStep.options:
          _setOptions(CourseWizardOptions.defaults);
        case CourseWizardStep.lessons:
          _setLessons(const []);
        case CourseWizardStep.guidebook:
          _setModules(const []);
        case CourseWizardStep.rounds:
          final lesson = _currentLesson;
          if (lesson != null) {
            _session!.stageCourse(
              CourseWizardRounds.withRounds(
                _working,
                lesson.lessonId,
                const [],
                now: _clock(),
                replace: true,
              ),
            );
            _generation++;
          }
      }
    });
  }

  /// What replacing every Lesson takes with it, named Lesson by Lesson.
  String _lessonReplaceMessage(String lead) {
    final removed = _session == null
        ? const <String>[]
        : CourseWizardLessons.removedContent(_working, const []);
    return [
      lead,
      ...removed,
      'Nothing is saved until you press Next or Save for now; Version '
          'History can bring back any earlier save.',
    ].join('\n\n');
  }

  /// What replacing the shown Lesson's modules does, for Fill and Clear all.
  String _moduleReplaceMessage(String lead, String doing) {
    final lesson = _currentLesson;
    final note = lesson == null
        ? null
        : CourseWizardGuidebook.roundsNote(lesson, _shownLesson, doing);
    return [
      lead,
      ?note,
      'Nothing is saved until you press Next, This Lesson\'s GuideBook is '
          'ready or Save for now; Version History can bring back any earlier '
          'save.',
    ].join('\n\n');
  }

  // ---- GuideBook (step 6)

  Lesson? get _currentLesson {
    final lessons = _working.lessons;
    if (lessons.isEmpty) return null;
    return lessons[_shownLesson.clamp(0, lessons.length - 1)];
  }

  /// The shown Lesson's modules, in the working copy. A GuideBook being
  /// written is a Draft until it is approved with "This Lesson's GuideBook
  /// is ready".
  void _setModules(
    List<GuidebookModule> modules, {
    PublicationState state = PublicationState.draft,
  }) {
    final lesson = _currentLesson;
    if (lesson == null) return;
    _session!.stageCourse(
      CourseWizardGuidebook.withModules(
        _working,
        lesson.lessonId,
        modules,
        state: state,
        now: _clock(),
      ),
    );
    _generation++;
  }

  Future<GuidebookModule?> _editModule(GuidebookModule module) =>
      Navigator.of(context).push<GuidebookModule>(
        MaterialPageRoute(
          builder: (_) => GuidebookModuleEditorScreen(
            module: module,
            course: _working,
            ids: _ids,
          ),
        ),
      );

  Future<void> _addModule() async {
    final added = await _editModule(
      GuidebookModule(id: _ids.next('module'), title: ''),
    );
    final lesson = _currentLesson;
    if (added == null || lesson == null || !mounted) return;
    setState(() => _setModules([...lesson.guidebook.modules, added]));
  }

  Future<void> _openModule(int index) async {
    final lesson = _currentLesson;
    if (lesson == null) return;
    final edited = await _editModule(lesson.guidebook.modules[index]);
    final current = _currentLesson;
    if (edited == null || current == null || !mounted) return;
    final modules = [...current.guidebook.modules];
    if (index >= modules.length) return;
    // A module returned unchanged leaves the GuideBook as it is.
    if (jsonEncode(modules[index].toJson()) == jsonEncode(edited.toJson())) {
      return;
    }
    modules[index] = edited;
    setState(() => _setModules(modules));
  }

  Future<void> _removeModule(int index) async {
    final lesson = _currentLesson;
    if (lesson == null) return;
    final module = lesson.guidebook.modules[index];
    final focusing = GuidebookRoundLinks.focusCount(lesson.rounds, module.id);
    final title = module.title.trim().isEmpty
        ? 'Untitled module'
        : module.title.trim();
    if (!await _confirm(
      key: const Key('course-wizard-module-remove-confirm'),
      title: 'Remove this module?',
      message: [
        'Remove “$title” with its Sentences and Words & Expressions?',
        if (focusing > 0)
          '$focusing ${focusing == 1 ? 'Round focuses' : 'Rounds focus'} on '
              'this module; ${focusing == 1 ? 'it keeps its' : 'they keep '
                        'their'} exercises and '
              '${focusing == 1 ? 'loses' : 'lose'} the link.',
      ].join('\n\n'),
      action: 'Remove',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _setModules([...lesson.guidebook.modules]..removeAt(index)));
  }

  void _moveModule(int index, int offset) {
    final lesson = _currentLesson;
    if (lesson == null) return;
    final modules = [...lesson.guidebook.modules];
    modules.insert(index + offset, modules.removeAt(index));
    setState(() => _setModules(modules));
  }

  void _chooseLesson(int index) {
    if (index == _shownLesson) return;
    setState(() {
      _shownLesson = index;
      _generation++;
    });
    unawaited(_remember(_step));
  }

  /// This Lesson's GuideBook is ready: saves it as Published, then shows
  /// the next Lesson still to do.
  Future<void> _guidebookReady() => _run(() async {
    final lesson = _currentLesson;
    if (lesson == null) return;
    if (!CourseWizardGuidebook.hasUsableModule(lesson)) {
      _tell(
        'This Lesson needs a module with at least '
        '${CourseWizardGuidebook.minimumWords} Words & Expressions: the '
        'Round Wizard makes its Rounds from them.',
      );
      return;
    }
    final number = _shownLesson + 1;
    setState(
      () => _setModules(
        lesson.guidebook.modules,
        state: PublicationState.published,
      ),
    );
    final session = _session!;
    final saved = await runReported(
      context,
      'Saving the Course',
      () => session.confirm(
        languageCode: CourseService.codeForCourse(session.workingCourse),
        versionNotes: 'Course Wizard: GuideBook, Lesson $number',
      ),
    );
    if (saved == null || !mounted) return;
    final next = CourseWizardGuidebook.firstProblem(_working);
    setState(() {
      if (next != null) _shownLesson = next.index;
      _generation++;
    });
    await _remember(_step);
    _tell(
      next == null
          ? 'Lesson $number\'s GuideBook is ready, and so is every Lesson\'s. '
                'Next goes on to the Rounds.'
          : 'Lesson $number\'s GuideBook is ready. Now Lesson '
                '${next.index + 1}.',
    );
  });

  // ---- Rounds (step 7)

  /// Make Rounds: the Round Wizard on the shown Lesson, its plan before
  /// anything; the Rounds it makes are added and saved.
  Future<void> _makeRounds() => _run(() async {
    final lesson = _currentLesson;
    if (lesson == null) return;
    if (!CourseWizardGuidebook.hasUsableModule(lesson)) {
      _tell(
        'Lesson ${_shownLesson + 1}\'s GuideBook needs a module with at '
        'least ${CourseWizardGuidebook.minimumWords} Words & Expressions '
        '(step 6).',
      );
      return;
    }
    final generated = await Navigator.of(context).push<List<LearningRound>>(
      MaterialPageRoute(
        builder: (_) => GuidebookRoundGeneratorScreen(
          course: _working,
          lesson: lesson,
          clock: _clock,
        ),
      ),
    );
    if (generated == null || generated.isEmpty || !mounted) return;
    final number = _shownLesson + 1;
    setState(() {
      _session!.stageCourse(
        CourseWizardRounds.withRounds(
          _working,
          lesson.lessonId,
          generated,
          now: _clock(),
        ),
      );
      _generation++;
    });
    final session = _session!;
    final saved = await runReported(
      context,
      'Saving the Course',
      () => session.confirm(
        languageCode: CourseService.codeForCourse(session.workingCourse),
        versionNotes: 'Course Wizard: Rounds, Lesson $number',
      ),
    );
    if (saved == null || !mounted) return;
    final next = CourseWizardRounds.firstProblem(_working);
    setState(() {
      if (next != null) _shownLesson = next.index;
      _generation++;
    });
    await _remember(_step);
    _tell(
      '${generated.length} Round${generated.length == 1 ? '' : 's'} added to '
      'Lesson $number. '
      '${next == null ? 'Every Lesson has Rounds: Finish saves the Course and opens the Course Editor.' : 'Now Lesson ${next.index + 1}.'}',
    );
  });

  // ---- Lessons

  void _addLesson() => setState(() {
    _lessonRows.add(
      _LessonRow(
        sectionName: _lessonRows.isEmpty ? '' : _lessonRows.last.section.text,
      ),
    );
    _generation++;
  });

  Future<void> _removeLesson(int index) async {
    final row = _lessonRows[index];
    final stored = row.lessonId == null
        ? null
        : _working.lessons
              .where((lesson) => lesson.lessonId == row.lessonId)
              .firstOrNull;
    final content = stored == null
        ? null
        : CourseWizardLessons.contentOf(stored);
    if (content != null &&
        !await _confirm(
          key: const Key('course-wizard-lesson-remove-confirm'),
          title: 'Remove this Lesson?',
          message:
              'Removing Lesson ${index + 1} removes $content. Version History '
              'can bring back any earlier save.',
          action: 'Remove',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _disposeLater([_lessonRows.removeAt(index)]);
      _generation++;
    });
  }

  void _moveLesson(int index, int offset) => setState(() {
    final row = _lessonRows.removeAt(index);
    _lessonRows.insert(index + offset, row);
    _generation++;
  });

  Future<void> _chooseIcon(int index) async {
    const numbers = '__numbers__';
    const library = '__library__';
    final row = _lessonRows[index];
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lesson icon',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Learners see it beside the Lesson. Numbers shows the '
                  'Lesson\'s number in its colour. Your own icon can be '
                  'imported later, on the Lesson\'s page in the Course Editor.',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('course-wizard-icon-from-library'),
                    onPressed: () => Navigator.pop(sheetContext, library),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose from the image library'),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _iconOption(
                      sheetContext,
                      key: 'none',
                      label: 'Numbers',
                      value: numbers,
                      selected: row.iconAsset == null,
                      icon: LessonFallbackIcon(number: index + 1, size: 48),
                    ),
                    for (final option in LessonIconCatalog.options)
                      _iconOption(
                        sheetContext,
                        key: option.id,
                        label: option.label,
                        value: option.assetPath,
                        selected: row.iconAsset == option.assetPath,
                        icon: Image.asset(
                          option.assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == library) {
      final picked = await Navigator.of(context).push<ExerciseImageMetadata>(
        MaterialPageRoute(
          builder: (_) => const FlatImageLibraryScreen(readOnly: true),
        ),
      );
      if (picked == null || !mounted) return;
      if (!LessonIconCatalog.isLibraryPicture(picked.assetPath) &&
          !LessonIconCatalog.isApproved(picked.assetPath)) {
        _tell(
          'A Lesson icon from the library must be one of QQL\'s own pictures, '
          'not a flag. A picture of your own can be imported as a custom '
          'icon on the Lesson\'s page in the Course Editor.',
        );
        return;
      }
      setState(() => row.iconAsset = picked.assetPath);
      return;
    }
    setState(() => row.iconAsset = selected == numbers ? null : selected);
  }

  Widget _iconOption(
    BuildContext sheetContext, {
    required String key,
    required String label,
    required String value,
    required bool selected,
    required Widget icon,
  }) => SizedBox(
    width: 96,
    child: Card(
      key: ValueKey('course-wizard-icon-option-$key'),
      color: selected
          ? Theme.of(sheetContext).colorScheme.secondaryContainer
          : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pop(sheetContext, value),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              SizedBox(width: 52, height: 52, child: icon),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _lessonIcon(String? asset, int number, {double size = 44}) {
    if (asset == null) return LessonFallbackIcon(number: number, size: size);
    if (CourseLessonIconAsset.isManagedReference(asset)) {
      final managed = _working.lessonIconAssets
          .where((icon) => icon.reference == asset)
          .firstOrNull;
      if (managed != null) {
        return Image.memory(
          base64Decode(managed.base64Png),
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      }
      return LessonFallbackIcon(number: number, size: size);
    }
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }

  // ---- Building blocks

  /// A small "Can wait" label whose tooltip says where it can be done later.
  Widget _canWait(String id, String where) => Tooltip(
    message: 'Can wait: $where',
    child: Container(
      key: ValueKey('course-wizard-can-wait-$id'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text('Can wait', style: Theme.of(context).textTheme.labelSmall),
    ),
  );

  /// A field's heading, with its tooltip and, when it can wait, the label.
  Widget _heading(
    String text, {
    String? tooltip,
    String? canWaitId,
    String? where,
  }) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: tooltip ?? text,
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (canWaitId != null) _canWait(canWaitId, where!),
      ],
    ),
  );

  static const _courseInfo = 'Course Info in the Course Editor';
  static const _lessonOptions = 'Lesson Options in the Course Editor';
  static const _lessonPage = 'the Lesson\'s page in the Course Editor';

  Widget _explanation(List<String> paragraphs) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('course-wizard-explanation'),
      color: scheme.secondaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, paragraph) in paragraphs.indexed)
                    Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                      child: Text(
                        paragraph,
                        style: TextStyle(color: scheme.onSecondaryContainer),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _explanationText => switch (_step) {
    CourseWizardStep.basics when _starting => const [
      'Every Course starts with a title and two languages.',
      'Title: what learners see in the list of Courses, for example '
          '“Italian at the bar”. Source language: the language your learners '
          'already speak; QQL writes its instructions and translations in it. '
          'Target language: the language they learn. For example English → '
          'Italian.',
      'Language variant: which form of the target language, for example '
          '“Italian of Italy” or “Brazilian Portuguese”.',
      'Needed now: the title and both languages. The languages never change '
          'later; the title can, in Course Info. The variant can wait.',
      'Then choose how to go on. The Course Wizard takes you through every '
          'step and explains it: QQL saves the Course now, as a Draft with no '
          'Lessons, and you can stop at any step and continue later. Creating '
          'it yourself opens the New Course form and then the Course Editor '
          'at once: quicker if you know QQL.',
    ],
    CourseWizardStep.basics => const [
      'The Course\'s title and its language variant. Learners see the title '
          'in the list of Courses, for example “Italian at the bar”.',
      'The languages cannot change: learners\' XP and streaks belong to the '
          'language they learn.',
      'Needed now: the title. The variant can wait (Course Info in the '
          'Course Editor).',
    ],
    CourseWizardStep.about => const [
      'Tell learners what the Course is about. They read it in Course Info '
          'and in the list of Courses before they start.',
      'Description: two or three sentences, for example “Order a coffee and '
          'a pastry in an Italian bar and ask for the bill.” Levels: where '
          'learners start and where they arrive, for example A1 → A2.',
      'Cover: a square picture that stands for the Course in lists, in place '
          'of the flag. Flag: Automatic takes the flag of the language '
          'learners learn.',
      'Study hours, minimum age and keywords help learners choose: “about 4 '
          'hours”, “for ages 9 and up”, “bar, food and drink, travel”.',
      'Everything here can wait: Course Info, in the Course Editor, changes '
          'it at any time.',
    ],
    CourseWizardStep.credits => const [
      'Say who made the Course and what other people may do with it.',
      'Credits name the people who worked on it, with their roles: Author, '
          'Illustrator, Native Speaker… Learners see them in Course Info. A '
          'credit never gives anyone the right to edit: you are this '
          'Course\'s Maintainer, and you can assign a Team later in Course '
          'Info.',
      'The license tells others what they may do with your content. '
          'Allowing derivative works lets other people Fork your Course: they '
          'get their own copy to change, with your name kept as the original '
          'creator.',
      'Rights Holders record who owns the rights: a person or an '
          'organization. Buy a Coffee and the publisher\'s website and email '
          'let learners thank you or reach you.',
      'Everything here can wait (Course Info in the Course Editor). Until '
          'you change it, the Course is “All rights reserved” and nobody may '
          'Fork it.',
    ],
    CourseWizardStep.options => const [
      'Choose how the Course looks and works for learners. Each option shows '
          'what learners see.',
      'Use GuideBook stays on: the Course Wizard builds your Rounds from the '
          'GuideBook, so it stays on. You can turn it off later in Lesson '
          'Options, but it is recommended.',
      'Everything here can wait: Lesson Options, on the Course Editor page.',
    ],
    CourseWizardStep.lessons => const [
      'A Lesson is one topic, like “At the market”. Learners open Lessons in '
          'order: the next one opens when they finish this one or win its '
          'Duel. A Duel needs 25 questions, so a Lesson usually has about six '
          'Rounds.',
      'Give each Lesson its title and, if you like, an icon and a section. A '
          'section groups neighbouring Lessons under one heading, for example '
          '“At the bar” over the first two Lessons.',
      'Needed now: at least one Lesson, and every Lesson\'s title. Icons and '
          'sections can wait (the Lesson\'s page in the Course Editor), and '
          'Lessons can be added, moved and removed there later too.',
      'Next saves the Lessons; then you write each Lesson\'s GuideBook.',
    ],
    CourseWizardStep.guidebook => [
      'The GuideBook is each Lesson\'s reference: learners read it, and the '
          'Round Wizard makes the Lesson\'s Rounds from it. It is made of '
          'modules, one short topic each, like “Al bar: ordering and paying”.',
      'A module has a title, Sentences (example sentences with their '
          'translation), Words & Expressions (single words and fixed '
          'expressions with their translation, an optional Context such as '
          '“restaurant”, and an optional picture) and a short Overview. '
          'Learners see the pictures in the GuideBook, on Review cards and in '
          'Word Lookup.',
      if (GuidebookPictureIndex.sideFor(_working) != null)
        'In a Course to or from English, typing a word suggests its picture '
            'from QQL\'s library when a picture has that name; you can change '
            'or remove it.',
      'Choose a Lesson and write its modules. Fill with an example fills the '
          'Lesson with a sample module, in Italian and English whatever the '
          'Course\'s languages.',
      'Needed now: in every Lesson, a module with at least '
          '${CourseWizardGuidebook.minimumWords} Words & Expressions, which the '
          'Round Wizard needs. When a Lesson\'s GuideBook is ready, press '
          '“This Lesson\'s GuideBook is ready”: it saves the GuideBook as '
          'Published, so learners can read it. Changing it afterwards asks for '
          'that again.',
      'Next saves the GuideBooks; then the Round Wizard makes each Lesson\'s '
          'Rounds from them.',
    ],
    CourseWizardStep.rounds => [
      'The Round Wizard makes each Lesson\'s Rounds from its GuideBook: '
          'Rounds that practise each module in turn, from recognizing its '
          'words to using them, with about a third of each Round reviewing '
          'the earlier modules.',
      'Choose a Lesson and press Make Rounds. The Round Wizard starts with '
          'its recommended settings (All modules with 3 Rounds each, or 6 '
          'Rounds for a Lesson with one module; 8 exercises per Round) and '
          'shows its plan, the Rounds with their focus module and words, '
          'before it makes anything. The Rounds it makes are Drafts: you can '
          'edit them in the Course Editor.',
      'Round titles: on, each Round is titled like “Practice: Al bar”; off, '
          'learners see only the Round type and number.',
      if (_working.createDuels)
        'Duel: the plan counts the Duel questions the Lesson will have. A '
            'Duel needs 25; if there are fewer, raise Rounds per module or '
            'exercises per Round.',
      'Needed now: every Lesson needs Rounds. Fill with an example opens the '
          'Round Wizard with its recommended settings.',
      'Finish saves the Course and opens the Course Editor.',
    ],
  };

  // ---- Steps

  List<Widget> _basicsFields() => [
    _heading('Title', tooltip: 'What learners see in the list of Courses.'),
    TextField(
      key: ValueKey('course-wizard-title-$_generation'),
      controller: _title,
      maxLength: 120,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Course title *',
        helperText: 'For example “Italian at the bar”.',
      ),
    ),
    _heading(
      'Languages',
      tooltip: 'The language learners speak, then the one they learn.',
    ),
    if (_starting) ...[
      LanguageField(
        key: ValueKey('course-wizard-source-$_generation'),
        controller: _source,
        label: 'Source language *',
        keyPrefix: 'course-wizard-source-language',
        onChanged: () => setState(() {}),
      ),
      const SizedBox(height: 8),
      LanguageField(
        key: ValueKey('course-wizard-target-$_generation'),
        controller: _target,
        label: 'Target language *',
        keyPrefix: 'course-wizard-target-language',
        onChanged: () => setState(() {}),
      ),
    ] else
      Text(
        key: const Key('course-wizard-languages'),
        '${_working.sourceLanguage} → ${_working.targetLanguage}',
      ),
    _heading(
      'Language variant',
      tooltip: 'Which form of the target language.',
      canWaitId: 'variant',
      where: _courseInfo,
    ),
    TextField(
      key: ValueKey('course-wizard-variant-$_generation'),
      controller: _variant,
      maxLength: 120,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Language variant',
        helperText: 'For example “Italian of Italy”.',
      ),
    ),
  ];

  List<Widget> _aboutFields() {
    final course = _working;
    return [
      _heading(
        'Description',
        tooltip: 'What learners read in Course Info.',
        canWaitId: 'description',
        where: _courseInfo,
      ),
      TextField(
        key: ValueKey('course-wizard-description-$_generation'),
        controller: _description,
        minLines: 2,
        maxLines: 6,
        maxLength: 5000,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Course description',
          helperText:
              'For example “Order a coffee and a pastry in an Italian bar '
              'and ask for the bill.”',
          helperMaxLines: 3,
        ),
      ),
      _heading(
        'Levels',
        tooltip: 'Where learners start and where they arrive.',
        canWaitId: 'levels',
        where: _courseInfo,
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: ValueKey('course-wizard-start-level-$_generation'),
              controller: _startLevel,
              maxLength: 40,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Starting level',
                helperText: 'For example A1.',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: ValueKey('course-wizard-target-level-$_generation'),
              controller: _targetLevel,
              maxLength: 40,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Target level',
                helperText: 'For example A2.',
              ),
            ),
          ),
        ],
      ),
      _heading(
        'Picture',
        tooltip: 'The cover and the flag that stand for the Course.',
        canWaitId: 'cover',
        where: _courseInfo,
      ),
      CourseCoverField(
        key: ValueKey('course-wizard-cover-$_generation'),
        courseId: course.courseId,
        course: course,
        cover: _cover,
        onChanged: (choice) => setState(() {
          _cover = choice.cover;
          _coverCredit = choice.credit;
        }),
      ),
      const SizedBox(height: 12),
      CourseFlagSelector(
        key: ValueKey('course-wizard-flag-$_generation'),
        selection: _flag,
        languageName: course.targetLanguage,
        languageTag: course.targetLanguageTag.isNotEmpty
            ? course.targetLanguageTag
            : CourseLanguageResolver.codeFromMetadata([course.targetLanguage]),
        onChanged: (selection) => setState(() => _flag = selection),
      ),
      _heading(
        'Study hours, age and keywords',
        tooltip: 'They help learners choose a Course.',
        canWaitId: 'details',
        where: _courseInfo,
      ),
      TextField(
        key: ValueKey('course-wizard-study-hours-$_generation'),
        controller: _studyHours,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Estimated study hours',
          helperText: 'A whole number, for example 4.',
          errorText: CourseWizardAbout.studyHoursProblem(_studyHours.text),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(
        key: ValueKey('course-wizard-minimum-age-$_generation'),
        initialValue: _minimumAge,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Minimum age',
          helperText: 'The app stores\' age classes.',
        ),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Not specified'),
          ),
          for (final age in Course.minimumAgeClasses)
            DropdownMenuItem<int?>(value: age, child: Text('$age+')),
        ],
        onChanged: (value) => setState(() => _minimumAge = value),
      ),
      const SizedBox(height: 12),
      TextField(
        key: ValueKey('course-wizard-keywords-$_generation'),
        controller: _keywords,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Keywords',
          helperText:
              'Separate them with commas, for example “bar, food and drink, '
              'travel”. Up to 20, of up to 32 characters each.',
          helperMaxLines: 3,
          errorText: CourseWizardAbout.keywordsProblem(_keywords.text),
        ),
      ),
    ];
  }

  List<Widget> _creditsFields() => [
    _heading(
      'Credits',
      tooltip: 'The people who made the Course and their roles.',
      canWaitId: 'credits',
      where: _courseInfo,
    ),
    const Text(
      'Credits are shown to learners and never give anyone the right to edit.',
    ),
    for (final (index, row) in _creditRows.indexed)
      Card(
        key: ValueKey('course-wizard-credit-$index'),
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
                        'course-wizard-credit-name-$index-$_generation',
                      ),
                      controller: row.name,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('course-wizard-credit-remove-$index'),
                    tooltip: 'Remove credit',
                    onPressed: () => setState(() {
                      _disposeLater([_creditRows.removeAt(index)]);
                      _generation++;
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final role in CourseMetadataOptions.standardRoles)
                    Tooltip(
                      message:
                          CourseMetadataOptions.roleDescriptions[role] ?? role,
                      child: FilterChip(
                        label: Text(role),
                        selected: row.roles.contains(role),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            row.roles.add(role);
                          } else {
                            row.roles.remove(role);
                          }
                        }),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey(
                  'course-wizard-credit-custom-$index-$_generation',
                ),
                controller: row.customRoles,
                maxLength: 240,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Other roles',
                  helperText: 'Optional; separate them with commas.',
                ),
              ),
            ],
          ),
        ),
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('course-wizard-add-credit'),
        onPressed: () => setState(() {
          _creditRows.add(
            _CreditRow(name: _creditRows.isEmpty ? _authorName : ''),
          );
          _generation++;
        }),
        icon: const Icon(Icons.add),
        label: const Text('Add a person'),
      ),
    ),
    _heading(
      'License',
      tooltip: 'What others may do with your content.',
      canWaitId: 'license',
      where: _courseInfo,
    ),
    DropdownButtonFormField<String>(
      key: ValueKey('course-wizard-license-$_generation'),
      initialValue: _licenseChoice,
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
      onChanged: (value) => setState(() {
        _licenseChoice = value ?? _licenseChoice;
        final inferred = CourseMetadataOptions.derivativePolicyForLicense(
          _licenseChoice,
        );
        if (inferred != DerivativeWorksPolicy.unspecified) {
          _derivative = inferred;
        }
      }),
    ),
    const SizedBox(height: 6),
    Text(
      key: const Key('course-wizard-derivative-note'),
      (_licenseChoice == _customLicenseChoice
                  ? _derivative
                  : CourseMetadataOptions.derivativePolicyForLicense(
                      _licenseChoice,
                    )) ==
              DerivativeWorksPolicy.allowed
          ? 'Derivative works are allowed: other people may Fork your Course '
                'and change their own copy; your name stays as the original '
                'creator.'
          : 'Derivative works are not allowed: nobody may Fork your Course.',
    ),
    if (_licenseChoice == _customLicenseChoice) ...[
      const SizedBox(height: 8),
      TextField(
        key: ValueKey('course-wizard-custom-license-$_generation'),
        controller: _customLicense,
        minLines: 2,
        maxLines: 5,
        maxLength: 2000,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Custom license',
        ),
      ),
      DropdownButtonFormField<DerivativeWorksPolicy>(
        key: ValueKey('course-wizard-derivative-$_generation'),
        initialValue: _derivative,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Derivative works for other users',
        ),
        items: const [
          DropdownMenuItem(
            value: DerivativeWorksPolicy.allowed,
            child: Text('Allowed'),
          ),
          DropdownMenuItem(
            value: DerivativeWorksPolicy.forbidden,
            child: Text('Forbidden'),
          ),
          DropdownMenuItem(
            value: DerivativeWorksPolicy.unspecified,
            child: Text('Not specified'),
          ),
        ],
        onChanged: (value) =>
            setState(() => _derivative = value ?? _derivative),
      ),
    ],
    _heading(
      'Rights Holders',
      tooltip: 'Who owns the rights: a person or an organization.',
      canWaitId: 'rights-holders',
      where: _courseInfo,
    ),
    for (final (index, row) in _holderRows.indexed)
      Card(
        key: ValueKey('course-wizard-rights-holder-$index'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CourseRightsHolderType>(
                      key: ValueKey(
                        'course-wizard-rights-holder-type-$index-$_generation',
                      ),
                      initialValue: row.type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Type',
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
                      onChanged: (value) =>
                          setState(() => row.type = value ?? row.type),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('course-wizard-rights-holder-remove-$index'),
                    tooltip: 'Remove Rights Holder',
                    onPressed: () => setState(() {
                      _disposeLater([_holderRows.removeAt(index)]);
                      _generation++;
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey(
                  'course-wizard-rights-holder-name-$index-$_generation',
                ),
                controller: row.name,
                maxLength: 240,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Rights Holder',
                ),
              ),
            ],
          ),
        ),
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('course-wizard-add-rights-holder'),
        onPressed: () => setState(() {
          _holderRows.add(
            _HolderRow(name: _holderRows.isEmpty ? _authorName : ''),
          );
          _generation++;
        }),
        icon: const Icon(Icons.add),
        label: const Text('Add a Rights Holder'),
      ),
    ),
    _heading(
      'Thanks and contact',
      tooltip: 'How learners can thank you or reach you.',
      canWaitId: 'contact',
      where: _courseInfo,
    ),
    TextField(
      key: ValueKey('course-wizard-buy-a-coffee-$_generation'),
      controller: _buyACoffee,
      maxLength: 2000,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Buy a Coffee address',
        helperText: 'HTTPS only; shown in Course Info.',
      ),
    ),
    const SizedBox(height: 8),
    TextField(
      key: ValueKey('course-wizard-contact-website-$_generation'),
      controller: _contactWebsite,
      maxLength: 500,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Publisher website',
        helperText: 'HTTPS only; shown as plain text in Course Info.',
      ),
    ),
    const SizedBox(height: 8),
    TextField(
      key: ValueKey('course-wizard-contact-email-$_generation'),
      controller: _contactEmail,
      maxLength: 254,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Publisher email',
        helperText: 'Shown as plain text in Course Info.',
      ),
    ),
  ];

  String get _lessonExample {
    final title = _lessonRows.isEmpty || _lessonRows.first.title.text.isEmpty
        ? 'At the market'
        : _lessonRows.first.title.text.trim();
    final prefix = LessonPresentationService.prefixFor(
      _options.lessonNumbering,
      1,
      customLabel: _customLessonLabel.text.trim(),
    );
    return prefix == null ? title : '$prefix: $title';
  }

  List<Widget> _optionsFields() {
    final legacy = !const [
      LessonNumberingMode.none,
      LessonNumberingMode.lesson,
      LessonNumberingMode.numberOnly,
      LessonNumberingMode.other,
    ].contains(_options.lessonNumbering);
    final style = _options.pictureAnswers;
    return [
      _heading(
        'Lesson label and numbering',
        tooltip: 'What learners see before a Lesson\'s title.',
        canWaitId: 'lesson-numbering',
        where: _lessonOptions,
      ),
      DropdownButtonFormField<LessonNumberingMode>(
        key: ValueKey('course-wizard-lesson-numbering-$_generation'),
        initialValue: _options.lessonNumbering,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Lesson label and numbering',
        ),
        items: [
          const DropdownMenuItem(
            value: LessonNumberingMode.none,
            child: Text('Off'),
          ),
          const DropdownMenuItem(
            value: LessonNumberingMode.lesson,
            child: Text('Lesson + number'),
          ),
          const DropdownMenuItem(
            value: LessonNumberingMode.numberOnly,
            child: Text('Number only'),
          ),
          const DropdownMenuItem(
            value: LessonNumberingMode.other,
            child: Text('Custom + number'),
          ),
          if (legacy)
            DropdownMenuItem(
              value: _options.lessonNumbering,
              child: Text('${_options.lessonNumbering.name} (existing)'),
            ),
        ],
        onChanged: (value) => setState(
          () => _options = _options.copyWith(lessonNumbering: value),
        ),
      ),
      if (_options.lessonNumbering == LessonNumberingMode.other) ...[
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('course-wizard-custom-lesson-label-$_generation'),
          controller: _customLessonLabel,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Custom Lesson label',
            helperText: 'For example “Unit” or “Episode”.',
          ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          key: const Key('course-wizard-lesson-example'),
          'Learners see: $_lessonExample',
        ),
      ),
      _heading(
        'Round label and numbering',
        tooltip: 'What learners see on each Round of the path.',
        canWaitId: 'round-numbering',
        where: _lessonOptions,
      ),
      DropdownButtonFormField<RoundNumberingMode>(
        key: ValueKey('course-wizard-round-numbering-$_generation'),
        initialValue: _options.roundNumbering,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Round label and numbering',
        ),
        items: const [
          DropdownMenuItem(value: RoundNumberingMode.off, child: Text('Off')),
          DropdownMenuItem(
            value: RoundNumberingMode.roundAndNumber,
            child: Text('Round + number'),
          ),
          DropdownMenuItem(
            value: RoundNumberingMode.numberOnly,
            child: Text('Number only'),
          ),
          DropdownMenuItem(
            value: RoundNumberingMode.customAndNumber,
            child: Text('Custom + number'),
          ),
        ],
        onChanged: (value) =>
            setState(() => _options = _options.copyWith(roundNumbering: value)),
      ),
      if (_options.roundNumbering == RoundNumberingMode.customAndNumber) ...[
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('course-wizard-custom-round-label-$_generation'),
          controller: _customRoundLabel,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Custom Round label',
            helperText: 'For example “Step”.',
          ),
        ),
      ],
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          key: const Key('course-wizard-round-example'),
          'Learners see the second Round of a Lesson as: '
          '${RoundTypePresentation.prefix(RoundType.practice, 2, _options.roundNumbering, customPrefix: _customRoundLabel.text)}',
        ),
      ),
      _heading(
        'Word Lookup and Duels',
        tooltip: 'Help while learning, and a game at the end of a Lesson.',
        canWaitId: 'switches',
        where: _lessonOptions,
      ),
      SwitchListTile(
        key: const Key('course-wizard-word-lookup'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Word Lookup'),
        subtitle: const Text(
          'Learners tap a word of the language they learn to see its '
          'translation from the GuideBook, for example “il conto” → “the '
          'bill”. Never in Test Rounds or Duels.',
        ),
        value: _options.wordLookup,
        onChanged: (value) =>
            setState(() => _options = _options.copyWith(wordLookup: value)),
      ),
      SwitchListTile(
        key: const Key('course-wizard-create-duels'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Create Duels'),
        subtitle: const Text(
          'At the end of a Lesson learners can play a Duel of quick '
          'questions; winning it opens the next Lesson even before every '
          'Round is done. A Duel needs 25 suitable questions in the Lesson.',
        ),
        value: _options.createDuels,
        onChanged: (value) =>
            setState(() => _options = _options.copyWith(createDuels: value)),
      ),
      _heading(
        'Picture answers',
        tooltip: 'How exercises with pictures as answers show them.',
        canWaitId: 'picture-answers',
        where: _lessonOptions,
      ),
      const Text(
        'When learners choose a picture as their answer, as in “Select the '
        'image”: large squares, two per row, unless you choose otherwise. An '
        'exercise can still choose its own look.',
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<PictureSize>(
        key: ValueKey('course-wizard-picture-size-$_generation'),
        initialValue: style.size,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Picture size',
        ),
        items: const [
          DropdownMenuItem(value: PictureSize.large, child: Text('Large')),
          DropdownMenuItem(value: PictureSize.normal, child: Text('Normal')),
        ],
        onChanged: (value) => setState(
          () => _options = _options.copyWith(
            pictureAnswers: PictureAnswerStyle(
              size: value ?? style.size,
              shape: style.shape,
              perRow: style.perRow,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<PictureShape>(
        key: ValueKey('course-wizard-picture-shape-$_generation'),
        initialValue: style.shape,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Picture shape',
        ),
        items: const [
          DropdownMenuItem(
            value: PictureShape.square,
            child: Text('Square, cropped'),
          ),
          DropdownMenuItem(value: PictureShape.round, child: Text('Round')),
        ],
        onChanged: (value) => setState(
          () => _options = _options.copyWith(
            pictureAnswers: PictureAnswerStyle(
              size: style.size,
              shape: value ?? style.shape,
              perRow: style.perRow,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<PicturesPerRow>(
        key: ValueKey('course-wizard-pictures-per-row-$_generation'),
        initialValue: style.perRow,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Pictures per row',
        ),
        items: const [
          DropdownMenuItem(value: PicturesPerRow.one, child: Text('1')),
          DropdownMenuItem(value: PicturesPerRow.two, child: Text('2')),
          DropdownMenuItem(value: PicturesPerRow.three, child: Text('3')),
          DropdownMenuItem(
            value: PicturesPerRow.automatic,
            child: Text('As many as fit'),
          ),
        ],
        onChanged: (value) => setState(
          () => _options = _options.copyWith(
            pictureAnswers: PictureAnswerStyle(
              size: style.size,
              shape: style.shape,
              perRow: value ?? style.perRow,
            ),
          ),
        ),
      ),
      _heading(
        'Default Timed limits',
        tooltip: 'The time limits a new Timed Round starts with.',
        canWaitId: 'timed',
        where: _lessonOptions,
      ),
      const Text(
        'A Timed Round asks learners to finish before a countdown ends; each '
        'limit they beat earns an On Time bonus. New Timed Rounds take these '
        'limits, shortest last. The Course Wizard makes no Timed Rounds: you '
        'can add them in the Course Editor.',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final seconds in {
            ...TimedRoundRules.presetSeconds,
            ..._options.defaultTimedLimits,
          })
            FilterChip(
              key: ValueKey('course-wizard-timed-$seconds'),
              label: Text(TimedRoundRules.label(seconds)),
              selected: _options.defaultTimedLimits.contains(seconds),
              onSelected: (selected) => setState(() {
                final limits = {..._options.defaultTimedLimits};
                if (selected) {
                  limits.add(seconds);
                } else {
                  limits.remove(seconds);
                }
                _options = _options.copyWith(
                  defaultTimedLimits: limits.toList()
                    ..sort((a, b) => b.compareTo(a)),
                );
              }),
            ),
        ],
      ),
    ];
  }

  List<Widget> _lessonFields() => [
    _heading(
      'Lessons',
      tooltip: 'One topic each, opened by learners in this order.',
    ),
    if (_lessonRows.isEmpty)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No Lessons yet. Add the first one, for example “At the market”.',
        ),
      ),
    for (final (index, row) in _lessonRows.indexed)
      Card(
        key: ValueKey('course-wizard-lesson-$index'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Tooltip(
                    message: 'Choose the Lesson icon',
                    child: InkWell(
                      key: ValueKey('course-wizard-lesson-icon-$index'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _chooseIcon(index),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _lessonIcon(row.iconAsset, index + 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lesson ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('course-wizard-lesson-up-$index'),
                    tooltip: 'Move up',
                    onPressed: index == 0 ? null : () => _moveLesson(index, -1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    key: ValueKey('course-wizard-lesson-down-$index'),
                    tooltip: 'Move down',
                    onPressed: index == _lessonRows.length - 1
                        ? null
                        : () => _moveLesson(index, 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    key: ValueKey('course-wizard-lesson-remove-$index'),
                    tooltip: 'Remove this Lesson',
                    onPressed: () => _removeLesson(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                key: ValueKey('course-wizard-lesson-title-$index-$_generation'),
                controller: row.title,
                maxLength: CourseWizardLessons.maxTitleLength,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Lesson title *',
                  helperText: 'For example “At the market”.',
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Icon and section'),
                  _canWait('lesson-$index', _lessonPage),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                key: ValueKey(
                  'course-wizard-lesson-section-$index-$_generation',
                ),
                controller: row.section,
                maxLength: CourseWizardLessons.maxSectionNameLength,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Section',
                  helperText:
                      'Neighbouring Lessons with the same section are grouped '
                      'under it, for example “At the bar”. Empty: no section.',
                  helperMaxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: const Key('course-wizard-add-lesson'),
        onPressed: _addLesson,
        icon: const Icon(Icons.add),
        label: const Text('Add a Lesson'),
      ),
    ),
  ];

  List<Widget> _guidebookFields() {
    final lessons = _working.lessons;
    if (lessons.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No Lessons yet: go back to Lessons and add one.'),
        ),
      ];
    }
    final lesson = _currentLesson!;
    final modules = lesson.guidebook.modules;
    final scheme = Theme.of(context).colorScheme;
    final ready = CourseWizardGuidebook.isReady(lesson);
    final status = ready
        ? 'Ready: approved, with ${modules.length} '
              'module${modules.length == 1 ? '' : 's'}.'
        : CourseWizardGuidebook.hasUsableModule(lesson)
        ? 'Not approved yet: press “This Lesson\'s GuideBook is ready” when '
              'it is.'
        : 'Needs a module with at least ${CourseWizardGuidebook.minimumWords} '
              'Words & Expressions.';
    return [
      _heading('Lesson', tooltip: 'Write the GuideBook Lesson by Lesson.'),
      _lessonChips('guidebook', CourseWizardGuidebook.isReady),
      const SizedBox(height: 8),
      Text(
        key: const Key('course-wizard-guidebook-status'),
        status,
        style: TextStyle(
          color: ready ? scheme.primary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      _heading(
        'Modules of Lesson ${_shownLesson + 1}',
        tooltip: 'One short topic each, in the order learners read them.',
      ),
      if (modules.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No modules yet. Add the first one, for example “Al bar: '
            'ordering and paying”, or press Fill with an example.',
          ),
        ),
      for (final (index, module) in modules.indexed)
        Card(
          key: ValueKey('course-wizard-module-$index'),
          child: ListTile(
            title: Text(
              module.title.trim().isEmpty
                  ? 'Untitled module'
                  : module.title.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${module.sentences.length} '
              'sentence${module.sentences.length == 1 ? '' : 's'} · '
              '${module.words.length} '
              'word${module.words.length == 1 ? '' : 's'}',
            ),
            onTap: () => _openModule(index),
            trailing: Wrap(
              children: [
                IconButton(
                  key: ValueKey('course-wizard-module-up-$index'),
                  tooltip: 'Move up',
                  visualDensity: VisualDensity.compact,
                  onPressed: index == 0 ? null : () => _moveModule(index, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  key: ValueKey('course-wizard-module-down-$index'),
                  tooltip: 'Move down',
                  visualDensity: VisualDensity.compact,
                  onPressed: index == modules.length - 1
                      ? null
                      : () => _moveModule(index, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  key: ValueKey('course-wizard-module-remove-$index'),
                  tooltip: 'Remove this module',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeModule(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('course-wizard-add-module'),
            onPressed: _busy ? null : _addModule,
            icon: const Icon(Icons.add),
            label: const Text('Add a module'),
          ),
          Tooltip(
            message:
                'Save this Lesson\'s GuideBook as Published, then go on to '
                'the next Lesson.',
            child: FilledButton.tonalIcon(
              key: const Key('course-wizard-guidebook-ready'),
              onPressed: _busy ? null : _guidebookReady,
              icon: const Icon(Icons.task_alt),
              label: const Text('This Lesson\'s GuideBook is ready'),
            ),
          ),
        ],
      ),
    ];
  }

  /// One chip per Lesson, ticked when [done]; keys
  /// `course-wizard-<step>-lesson-<i>`.
  Widget _lessonChips(String step, bool Function(Lesson lesson) done) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (index, each) in _working.lessons.indexed)
          ChoiceChip(
            key: ValueKey('course-wizard-$step-lesson-$index'),
            avatar: done(each)
                ? Icon(Icons.check_circle, color: scheme.primary)
                : null,
            label: Text(
              '${index + 1}. ${each.title}',
              overflow: TextOverflow.ellipsis,
            ),
            selected: index == _shownLesson,
            onSelected: (_) => _chooseLesson(index),
          ),
      ],
    );
  }

  List<Widget> _roundsFields() {
    final course = _working;
    final lessons = course.lessons;
    if (lessons.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No Lessons yet: go back to Lessons and add one.'),
        ),
      ];
    }
    final lesson = _currentLesson!;
    final scheme = Theme.of(context).colorScheme;
    final rounds = lesson.rounds;
    final duel = CourseWizardRounds.duelCount(lesson);
    const needed = DuelEligibilityService.requiredQuestionCount;
    final usable = CourseWizardGuidebook.hasUsableModule(lesson);
    return [
      _heading('Lesson', tooltip: 'Make the Rounds Lesson by Lesson.'),
      _lessonChips('rounds', (each) => each.rounds.isNotEmpty),
      const SizedBox(height: 8),
      Text(
        key: const Key('course-wizard-rounds-status'),
        rounds.isEmpty
            ? 'No Rounds yet.'
            : '${rounds.length} Round${rounds.length == 1 ? '' : 's'}, '
                  '${rounds.fold<int>(0, (sum, round) => sum + round.exercises.length)} '
                  'exercises.',
        style: TextStyle(
          color: rounds.isEmpty ? scheme.onSurfaceVariant : scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (course.createDuels)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            key: const Key('course-wizard-rounds-duel'),
            [
              'Duel: ${duel.questions} question${duel.questions == 1 ? '' : 's'} '
                  '($needed needed)',
              if (duel.audio > 0)
                '${duel.audio} more need${duel.audio == 1 ? 's' : ''} audio',
            ].join(' · '),
          ),
        ),
      _heading(
        'Rounds of Lesson ${_shownLesson + 1}',
        tooltip: 'In the order learners play them.',
      ),
      for (final (index, round) in rounds.indexed)
        Padding(
          key: ValueKey('course-wizard-round-$index'),
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '${RoundTypePresentation.title(round, index + 1, course.roundNumberingMode, customPrefix: course.customRoundLabel)}'
            ' · ${round.exercises.length} exercises'
            '${round.publicationState.isPublished ? '' : ' · Draft'}',
          ),
        ),
      if (!usable)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'This Lesson\'s GuideBook needs a module with at least '
            '${CourseWizardGuidebook.minimumWords} Words & Expressions first '
            '(step 6).',
            style: TextStyle(color: scheme.error),
          ),
        ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message:
              'Open the Round Wizard on this Lesson: its plan comes before '
              'anything is made.',
          child: FilledButton.tonalIcon(
            key: const Key('course-wizard-make-rounds'),
            onPressed: _busy || !usable ? null : _makeRounds,
            icon: const Icon(Icons.auto_awesome_motion_outlined),
            label: Text(rounds.isEmpty ? 'Make Rounds' : 'Make more Rounds'),
          ),
        ),
      ),
    ];
  }

  List<Widget> _fields() => switch (_step) {
    CourseWizardStep.basics => _basicsFields(),
    CourseWizardStep.about => _aboutFields(),
    CourseWizardStep.credits => _creditsFields(),
    CourseWizardStep.options => _optionsFields(),
    CourseWizardStep.lessons => _lessonFields(),
    CourseWizardStep.guidebook => _guidebookFields(),
    CourseWizardStep.rounds => _roundsFields(),
  };

  /// Done: the step was passed and what it needs now is there.
  bool _done(CourseWizardStep step) {
    if (_starting || step.index >= _furthest.index) return false;
    return switch (step) {
      CourseWizardStep.lessons => _working.lessons.isNotEmpty,
      CourseWizardStep.guidebook =>
        _working.lessons.isNotEmpty &&
            CourseWizardGuidebook.firstProblem(_working) == null,
      CourseWizardStep.rounds =>
        _working.lessons.isNotEmpty &&
            CourseWizardRounds.firstProblem(_working) == null,
      _ => true,
    };
  }

  Widget _stepBar() {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: const Key('course-wizard-steps'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (final step in CourseWizardStep.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(
                message: step.index <= _furthest.index || _starting
                    ? step.title
                    : '${step.title}: reached with Next',
                child: InkWell(
                  key: ValueKey('course-wizard-step-${step.number}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap:
                      !_starting &&
                          step != _step &&
                          step.index <= _furthest.index
                      ? () => _jumpTo(step)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: step == _step ? scheme.primaryContainer : null,
                      border: Border.all(
                        color: step == _step ? scheme.primary : scheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_done(step))
                          Icon(
                            Icons.check_circle,
                            key: ValueKey(
                              'course-wizard-step-done-${step.number}',
                            ),
                            size: 16,
                            color: scheme.primary,
                          )
                        else
                          Text(
                            '${step.number}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(width: 6),
                        Text(step.title),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buttons() {
    if (_starting) {
      return [
        TextButton(
          key: const Key('course-wizard-cancel'),
          onPressed: _busy ? null : _leave,
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          key: const Key('course-wizard-manual'),
          onPressed: _busy ? null : _createManually,
          child: const Text('Create it myself'),
        ),
        FilledButton(
          key: const Key('course-wizard-continue'),
          onPressed: _busy ? null : _begin,
          child: const Text('Continue with the Course Wizard'),
        ),
      ];
    }
    return [
      Tooltip(
        message: 'Save and close; continue later from Course Studio.',
        child: TextButton(
          key: const Key('course-wizard-save-for-now'),
          onPressed: _busy ? null : _saveForNow,
          child: const Text('Save for now'),
        ),
      ),
      Tooltip(
        message: 'Save, end the Course Wizard and open the Course Editor.',
        child: TextButton(
          key: const Key('course-wizard-by-hand'),
          onPressed: _busy ? null : _byHand,
          child: const Text('Continue by hand'),
        ),
      ),
      OutlinedButton(
        key: const Key('course-wizard-back'),
        onPressed: _busy || _step.previous == null ? null : _back,
        child: const Text('Back'),
      ),
      FilledButton(
        key: const Key('course-wizard-next'),
        onPressed: _busy ? null : _next,
        child: Text(_step.isLast ? 'Finish' : 'Next'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session != null && !session.canModify) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Wizard')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            key: Key('course-wizard-not-allowed'),
            'Only the Course Maintainer or a member of its assigned Team can '
            'continue this Course Wizard.',
          ),
        ),
      );
    }
    return PopScope(
      canPop: _closing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Course Wizard'),
              Text(
                _starting ? 'New Course' : _working.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            IconButton(
              key: const Key('course-wizard-help'),
              tooltip: 'Help: the Course Wizard',
              icon: const Icon(Icons.help_outline),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      const EditorHelpScreen(question: 'courseWizard'),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _stepBar(),
              const Divider(height: 1),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      key: const Key('course-wizard-page'),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        Text(
                          key: const Key('course-wizard-step-title'),
                          'Step ${_step.number} of '
                          '${CourseWizardStep.values.length}: ${_step.title}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        _explanation(_explanationText),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Tooltip(
                              message:
                                  'Fill this step from a built-in example '
                                  'Course, “Italian at the bar”.',
                              child: TextButton.icon(
                                key: const Key('course-wizard-fill-example'),
                                onPressed: _busy ? null : _fillExample,
                                icon: const Icon(Icons.auto_awesome_outlined),
                                label: const Text('Fill with an example'),
                              ),
                            ),
                            Tooltip(
                              message: 'Empty this step only.',
                              child: TextButton.icon(
                                key: const Key('course-wizard-clear-all'),
                                onPressed: _busy ? null : _clearAll,
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear all'),
                              ),
                            ),
                          ],
                        ),
                        ..._fields(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: _buttons(),
            ),
          ),
        ),
      ),
    );
  }
}
