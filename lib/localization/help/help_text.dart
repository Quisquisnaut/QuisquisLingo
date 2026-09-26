import '../../services/storage/qql_storage_layout.dart';
import '../localized_text.dart';
import 'help_en.dart';
import 'help_es.dart';
import 'help_it.dart';

/// Shared keyed text for the first localization slice. Folder names such as
/// `{folderCourseImports}` resolve to the current platform's folders.
const helpText = LocalizedText(
  english: helpEn,
  italian: helpIt,
  spanish: helpEs,
  defaultValues: QqlStorageLayout.helpValues,
);
