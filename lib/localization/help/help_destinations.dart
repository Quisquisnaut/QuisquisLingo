import 'package:flutter/widgets.dart';

import '../../screens/audit_codes_screen.dart';
import '../../screens/available_courses_screen.dart';
import '../../screens/debug_screen.dart';
import '../../screens/device_administration_help_screen.dart';
import '../../screens/editor_help_screen.dart';
import '../../screens/publisher_signing_help_screen.dart';
import '../locale_service.dart';
import 'help_text.dart';

/// One entry per standalone Help route. Titles come from the same catalog as
/// each page's AppBar, so Guide labels follow later translations and renames.
class QqlGuideHelpDestination {
  const QqlGuideHelpDestination({
    required this.id,
    required this.build,
    this.titleKey,
    this.fixedTitle,
    this.englishOnly = false,
  }) : assert(titleKey != null || fixedTitle != null);

  final String id;
  final WidgetBuilder build;
  final String? titleKey;
  final String? fixedTitle;
  final bool englishOnly;

  String titleFor(AppLocale locale) =>
      titleKey == null ? fixedTitle! : helpText.lookup(locale, titleKey!);
}

/// Add a new standalone Help page here. Existing title changes and additional
/// catalog languages need no separate Guide list.
abstract final class QqlGuideHelpDestinations {
  static final List<QqlGuideHelpDestination> all = List.unmodifiable([
    QqlGuideHelpDestination(
      id: 'all-courses',
      titleKey: 'allCoursesHelp.allCoursesPageTitle',
      build: (_) => const CourseLibraryHelpScreen(
        source: CourseLibraryHelpSource.allCourses,
      ),
    ),
    QqlGuideHelpDestination(
      id: 'audit-codes',
      fixedTitle: auditCodesPageTitle,
      englishOnly: true,
      build: (_) => const AuditCodesScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'course-library',
      titleKey: 'allCoursesHelp.courseLibraryPageTitle',
      build: (_) => const CourseLibraryHelpScreen(
        source: CourseLibraryHelpSource.courseLibrary,
      ),
    ),
    QqlGuideHelpDestination(
      id: 'course-studio',
      titleKey: 'courseStudioHelp.title',
      build: (_) => const CourseManagerHelpScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'debug',
      titleKey: 'debugHelp.title',
      build: (_) => const DebugHelpScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'device-administration',
      titleKey: 'deviceAdminHelp.title',
      build: (_) => const DeviceAdministrationHelpScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'editor',
      titleKey: 'editorHelp.title',
      build: (_) => const EditorHelpScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'exercise',
      titleKey: 'exerciseHelp.title',
      build: (_) => const ExerciseHelpScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'exercise-primitives',
      titleKey: 'technical.exercisePrimitives.title',
      build: (_) => const ExercisePrimitivesHelpScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'json-structure',
      titleKey: 'technical.jsonStructure.title',
      build: (_) => const JsonV4HelpScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'publisher-signing',
      titleKey: 'publisherSigningHelp.title',
      build: (_) => const PublisherSigningHelpScreen(),
    ),
    QqlGuideHelpDestination(
      id: 'course-model',
      titleKey: 'technical.courseModel.title',
      build: (_) => const CourseModelV4HelpScreen(),
    ),
  ]);

  static List<QqlGuideHelpDestination> sortedFor(AppLocale locale) {
    final sorted = List<QqlGuideHelpDestination>.of(all);
    sorted.sort((left, right) {
      final byTitle = left
          .titleFor(locale)
          .toLowerCase()
          .compareTo(right.titleFor(locale).toLowerCase());
      return byTitle != 0 ? byTitle : left.id.compareTo(right.id);
    });
    return List.unmodifiable(sorted);
  }
}
