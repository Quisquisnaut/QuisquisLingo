import 'package:flutter/material.dart';
import '../widgets/file_dialog_feedback.dart';
import '../services/storage/qql_storage.dart';
import '../widgets/course_package_notes.dart';

/// Export counterpart of [CourseImportScreen]: the fixed-folder route and the
/// system dialog in one place, so the Course Studio menu offers one Export.
class CourseExportScreen extends StatelessWidget {
  final String courseTitle;
  final Future<void> Function() onExport;

  /// Null hides the button (no system dialog on this platform).
  final Future<void> Function()? onSaveTo;

  const CourseExportScreen({
    super.key,
    required this.courseTitle,
    required this.onExport,
    this.onSaveTo,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course Export')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          courseTitle,
          key: const Key('export-course-title'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('export-course-zip-primary'),
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Quick Export'),
        ),
        const SizedBox(height: 4),
        Text(
          'Writes a ZIP holding course.json and only the images and recordings this Course uses, into ${courseFolderLabel(QqlStorageRole.courseExports)}, without a dialog.',
        ),
        if (onSaveTo != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('save-course-zip-to'),
            onPressed: onSaveTo,
            icon: const Icon(Icons.save_alt_outlined),
            label: const Text('Save as…'),
          ),
          const SizedBox(height: 4),
          const Text(
            'The same package, saved wherever you choose with the system file dialog.',
          ),
          const SizedBox(height: 8),
          Text(
            cloudFolderHelpText(),
            key: const Key('cloud-folder-help'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Export notes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '1. The package always exports the Course as it is stored. Changes still open in the Course Editor are not included until they are confirmed.\n'
          '2. App-bundled QQL images are supplied by the application and are not packaged.\n'
          '3. A Course with blocking Audit errors can still be exported; the result names them so the recipient knows.\n'
          '4. Import the package on another device from Course Studio > Import Course.',
        ),
      ],
    ),
  );
}
