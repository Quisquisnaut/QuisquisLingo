import 'package:characters/characters.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Shared conservative validation for human-facing local names.
///
/// Visible spelling is retained. The comparison key is separate so identity
/// and authorization never depend on a presentation label.
class FormalNamePolicy {
  static const int minimumLength = 2;
  static const int maximumUserTextLength = 32;
  static const int maximumLabelLength = 120;

  static final RegExp _unicodeLetterMarkOrNumber = RegExp(
    r'^[\p{L}\p{M}\p{N}]$',
    unicode: true,
  );

  static String validateUserScreenName(String value) {
    _validateWhitespaceAndLength(
      value,
      minimumLength: minimumLength,
      maximumLength: maximumUserTextLength,
      parameterName: 'screenName',
    );
    var hasLetter = false;
    var previousWasLatin = false;
    for (final rune in value.runes) {
      if (_isLatinLetter(rune)) {
        hasLetter = true;
        previousWasLatin = true;
        continue;
      }
      if (_isCombiningMark(rune) && previousWasLatin) continue;
      previousWasLatin = false;
      if (rune == 0x20 || rune == 0x27 || rune == 0x2d || rune == 0x5f) {
        continue;
      }
      throw ArgumentError.value(
        value,
        'screenName',
        'Use Latin letters, single spaces, apostrophes, hyphens or underscores. Do not enter digits.',
      );
    }
    if (!hasLetter) {
      throw ArgumentError.value(
        value,
        'screenName',
        'Screen Name must contain letters.',
      );
    }
    return value;
  }

  static String validatePresentationLabel(
    String value, {
    String parameterName = 'name',
    int maximumLength = maximumLabelLength,
  }) {
    _validateWhitespaceAndLength(
      value,
      minimumLength: 1,
      maximumLength: maximumLength,
      parameterName: parameterName,
    );
    var hasLetterOrNumber = false;
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      if (_unicodeLetterMarkOrNumber.hasMatch(character)) {
        if (!RegExp(r'^[\p{M}]$', unicode: true).hasMatch(character)) {
          hasLetterOrNumber = true;
        }
        continue;
      }
      if (rune == 0x20 || rune == 0x27 || rune == 0x2d || rune == 0x5f) {
        continue;
      }
      throw ArgumentError.value(
        value,
        parameterName,
        'Use letters, numbers, single spaces, apostrophes, hyphens or underscores.',
      );
    }
    if (!hasLetterOrNumber) {
      throw ArgumentError.value(
        value,
        parameterName,
        'The name must contain a letter or number.',
      );
    }
    return value;
  }

  static String comparisonKey(String value) {
    // NFC is used only for comparison. Storage retains the spelling entered by
    // the user, including whether accents were entered in composed form.
    return unorm.nfc(value).toLowerCase();
  }

  static void _validateWhitespaceAndLength(
    String value, {
    required int minimumLength,
    required int maximumLength,
    required String parameterName,
  }) {
    if (value != value.trim() || value.contains('  ')) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Do not use leading, trailing or consecutive spaces.',
      );
    }
    final length = value.characters.length;
    if (length < minimumLength || length > maximumLength) {
      throw ArgumentError.value(
        value,
        parameterName,
        'The name must be $minimumLength to $maximumLength characters.',
      );
    }
  }

  static bool _isLatinLetter(int rune) =>
      (rune >= 0x41 && rune <= 0x5a) ||
      (rune >= 0x61 && rune <= 0x7a) ||
      (rune >= 0x00c0 && rune <= 0x00d6) ||
      (rune >= 0x00d8 && rune <= 0x00f6) ||
      (rune >= 0x00f8 && rune <= 0x024f) ||
      (rune >= 0x1e00 && rune <= 0x1eff) ||
      (rune >= 0xab30 && rune <= 0xab6f);

  static bool _isCombiningMark(int rune) =>
      (rune >= 0x0300 && rune <= 0x036f) ||
      (rune >= 0x1ab0 && rune <= 0x1aff) ||
      (rune >= 0x1dc0 && rune <= 0x1dff);
}
