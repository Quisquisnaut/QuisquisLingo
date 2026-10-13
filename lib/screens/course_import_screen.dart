import 'package:flutter/material.dart';
import '../widgets/file_dialog_feedback.dart';
import '../services/storage/qql_storage.dart';
import '../widgets/course_package_notes.dart';

class CourseImportScreen extends StatelessWidget {
  final Future<void> Function() onImport;

  /// Null hides the button (no system dialog on this platform).
  final Future<void> Function()? onOpenFrom;

  const CourseImportScreen({
    super.key,
    required this.onImport,
    this.onOpenFrom,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course Import')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          key: const Key('import-course-json-primary'),
          onPressed: onImport,
          icon: const Icon(Icons.file_open_outlined),
          label: const Text('Quick Import'),
        ),
        const SizedBox(height: 4),
        Text(
          'Reads import.zip or import.json from '
          '${courseFolderLabel(QqlStorageRole.courseImports)} without a dialog.',
        ),
        if (onOpenFrom != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('open-course-json-from'),
            onPressed: onOpenFrom,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Open from…'),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a Course package ZIP or a media-free JSON file with the system file dialog. '
            'It is checked exactly like an ordinary import.',
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
          'Import instructions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '1. Copy a Course package to ${courseFileLabel(QqlStorageRole.courseImports, 'import.zip')}, or a media-free JSON to import.json. Keep only one.\n'
          '2. A ZIP may have its files at the root or inside one folder named import. QQL accepts the matching folder with a warning. Select Quick Import; QQL validates the complete file before changing local storage.\n'
          '3. If the Course ID already exists, choose Replace/update, Copy as New Course, Fork or Cancel, as available.\n'
          '4. A successful import is added to your courses. Only published courses are available for study. The source file remains in ${courseFolderLabel(QqlStorageRole.courseImports)}.',
        ),
      ],
    ),
  );
}
