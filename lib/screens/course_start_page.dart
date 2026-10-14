import 'package:flutter/material.dart';

import '../localization/locale_builder.dart';
import '../localization/start_page_text.dart';

/// The learner's page while no Course can be studied (Build 272 Revision
/// 17, owner decisions of 13 October 2026): no Course comes with the app, so
/// a new learner starts here. It offers Import a Course and New Course and
/// says, in the learner's Help Language, where Courses come from, how to
/// import one and how to turn on Course Studio and the Course Editor.
///
/// The page never names a Course. It only draws: Home decides what each
/// button does.
class CourseStartPage extends StatelessWidget {
  const CourseStartPage({
    super.key,
    required this.editorUnlocked,
    required this.waitingCourses,
    required this.addableCourses,
    required this.onImport,
    required this.onNewCourse,
    required this.onAllCourses,
    required this.onCourseStudio,
    required this.onSettings,
  });

  /// Whether Course Studio is unlocked for the active learner.
  final bool editorUnlocked;

  /// How many Courses the learner has that cannot be studied yet (not
  /// Published, or waiting for Publisher verification).
  final int waitingCourses;

  /// How many Courses already on this device the learner could add in All
  /// Courses and study. With some, the page says so first: importing a file
  /// the device already has ends at the Matching Course ID dialog, which
  /// cannot simply add the Course to the learner's courses.
  final int addableCourses;

  final VoidCallback onImport;
  final VoidCallback onNewCourse;
  final VoidCallback onAllCourses;
  final VoidCallback onCourseStudio;
  final VoidCallback onSettings;

  /// The pictures are QQL's own: a mascot and pictures of the image library.
  static const mascot = 'assets/mascots/cat_reading.webp';
  static const friendPicture = 'assets/exercise_images/friends.webp';
  static const teacherPicture = 'assets/exercise_images/headteacher_woman.webp';
  static const publisherPicture = 'assets/exercise_images/bookshop.webp';
  static const filePicture = 'assets/exercise_images/folder.webp';
  static const devicePicture = 'assets/exercise_images/smartphone.webp';
  static const writePicture = 'assets/exercise_images/pencil.webp';

  static const _maxWidth = 560.0;

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) {
      String t(String key, [Map<String, String> values = const {}]) =>
          startPageText.lookup(locale, key, values: values);
      final theme = Theme.of(context);
      // With Courses on this device that the learner could add, the card
      // comes first and says how many; without, it closes the page.
      final device = _Section(
        key: const Key('course-start-device'),
        title: t('device.title'),
        children: [
          Text(
            addableCourses == 0
                ? t('device.none')
                : addableCourses == 1
                ? t('device.some.one')
                : t('device.some.many', {'count': '$addableCourses'}),
            key: const Key('course-start-device-text'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              addableCourses == 0
                  ? OutlinedButton.icon(
                      key: const Key('start-all-courses'),
                      onPressed: onAllCourses,
                      icon: const Icon(Icons.library_add_outlined),
                      label: const Text('All Courses'),
                    )
                  : FilledButton.icon(
                      key: const Key('start-all-courses'),
                      onPressed: onAllCourses,
                      icon: const Icon(Icons.library_add_outlined),
                      label: const Text('All Courses'),
                    ),
              if (editorUnlocked)
                OutlinedButton.icon(
                  key: const Key('empty-library-course-manager'),
                  onPressed: onCourseStudio,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Course Studio'),
                ),
            ],
          ),
        ],
      );
      return Scaffold(
        key: const Key('course-start-page'),
        appBar: AppBar(
          title: const Text('QuisquisLingo'),
          actions: [
            IconButton(
              key: const Key('empty-library-settings'),
              tooltip: 'Settings',
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              // Not a lazy list: the page is short, and every button stays
              // in the tree for a screen reader and for the tests.
              child: SingleChildScrollView(
                key: const Key('course-start-list'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _picture(mascot, 120),
                    const SizedBox(height: 8),
                    Text(
                      t('title'),
                      key: const Key('course-start-title'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('intro'),
                      key: const Key('course-start-intro'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (waitingCourses > 0) ...[
                      const SizedBox(height: 12),
                      _Notice(
                        key: const Key('course-start-waiting'),
                        text: waitingCourses == 1
                            ? t('waiting.one')
                            : t('waiting.many', {'count': '$waitingCourses'}),
                      ),
                    ],
                    if (addableCourses > 0) ...[
                      const SizedBox(height: 16),
                      device,
                    ],
                    const SizedBox(height: 16),
                    _Section(
                      key: const Key('course-start-where'),
                      title: t('where.title'),
                      children: [
                        Text(t('where.body')),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Captioned(friendPicture, t('where.friend')),
                            _Captioned(teacherPicture, t('where.teacher')),
                            _Captioned(publisherPicture, t('where.publisher')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      key: const Key('course-start-import'),
                      title: t('import.title'),
                      children: [
                        // A file goes into QuisquisLingo.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _picture(filePicture, 56),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.arrow_forward, size: 28),
                            ),
                            _picture(devicePicture, 56),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (var step = 1; step <= 4; step++)
                          _Step(number: step, text: t('import.step$step')),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          key: const Key('start-import-course'),
                          onPressed: onImport,
                          icon: const Icon(Icons.file_open_outlined),
                          label: const Text('Import a Course'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      key: const Key('course-start-create'),
                      title: t('create.title'),
                      children: [
                        Text(t('create.body')),
                        const SizedBox(height: 10),
                        // Settings' Version and Build row, tapped ten times.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _picture(writePicture, 56),
                            const SizedBox(width: 12),
                            const Flexible(child: _TenTaps()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (var step = 1; step <= 5; step++)
                          _Step(number: step, text: t('create.step$step')),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              editorUnlocked
                                  ? Icons.lock_open_outlined
                                  : Icons.lock_outline,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                t(editorUnlocked ? 'create.on' : 'create.off'),
                                key: const Key('course-start-studio-state'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          key: const Key('start-new-course'),
                          onPressed: onNewCourse,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('New Course'),
                        ),
                      ],
                    ),
                    if (addableCourses == 0) ...[
                      const SizedBox(height: 12),
                      device,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  static Widget _picture(String asset, double size) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    // A picture that cannot be drawn leaves its place empty: the words
    // carry the page.
    errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
  );
}

/// One titled block of the page.
class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A numbered line of a how-to.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: ExcludeSemantics(
              child: Text(
                '$number',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(label: '$number.', child: Text(text)),
          ),
        ],
      ),
    );
  }
}

/// A picture with its caption, a third of the row.
class _Captioned extends StatelessWidget {
  const _Captioned(this.asset, this.caption);

  final String asset;
  final String caption;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        CourseStartPage._picture(asset, 64),
        const SizedBox(height: 4),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

/// The amber note about Courses that cannot be studied yet.
class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// A drawing of Settings' Version and Build row being tapped ten times.
class _TenTaps extends StatelessWidget {
  const _TenTaps();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ExcludeSemantics(
      child: Container(
        key: const Key('course-start-ten-taps'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Version and Build',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.touch_app_outlined, size: 22, color: scheme.primary),
            const SizedBox(width: 2),
            Text(
              '× 10',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
