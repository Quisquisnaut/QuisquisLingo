/// The one sanitizer for names that come from outside QQL: a picked file, a
/// document provider or an archive entry.
///
/// The result is for display, logs and provenance only. It never chooses a
/// storage path: QQL names stored files itself.
String safeDisplayName(String raw, {int maxLength = 120}) {
  // The last path segment only, whichever separator the source used.
  final segments = raw.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty);
  var name = segments.isEmpty ? '' : segments.last;
  // NUL and every C0/C1 control character.
  name = name.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');
  // Windows ignores trailing dots and spaces; leading/trailing blanks confuse.
  name = name.trim().replaceAll(RegExp(r'[. ]+$'), '');
  if (name.isEmpty || name == '.' || name == '..') return 'file';
  final dot = name.indexOf('.');
  final stem = (dot < 0 ? name : name.substring(0, dot)).toUpperCase();
  if (_reservedWindowsNames.contains(stem)) name = '_$name';
  if (name.length > maxLength) {
    final extension = name.lastIndexOf('.');
    final suffix = extension > 0 && name.length - extension <= 10
        ? name.substring(extension)
        : '';
    name = '${name.substring(0, maxLength - suffix.length)}$suffix';
  }
  return name;
}

const _reservedWindowsNames = {
  'CON',
  'PRN',
  'AUX',
  'NUL',
  'COM1',
  'COM2',
  'COM3',
  'COM4',
  'COM5',
  'COM6',
  'COM7',
  'COM8',
  'COM9',
  'LPT1',
  'LPT2',
  'LPT3',
  'LPT4',
  'LPT5',
  'LPT6',
  'LPT7',
  'LPT8',
  'LPT9',
};
