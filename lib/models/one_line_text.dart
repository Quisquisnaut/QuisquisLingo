import 'package:characters/characters.dart';

/// A text of a Course as a message shows it: one line, at most [max]
/// characters. A Course file may hold a megabyte in any of its texts, and a
/// custom license may be several lines long. The cut never falls inside a
/// character (half an emoji would make Flutter draw the whole line as a
/// replacement mark).
String oneLineText(String value, [int max = 80]) {
  final line = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (line.length <= max) return line;
  final characters = line.characters;
  return characters.length <= max ? line : '${characters.take(max)}…';
}
