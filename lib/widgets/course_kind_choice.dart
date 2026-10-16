import 'package:flutter/material.dart';

import '../screens/editor_help_screen.dart';
import '../services/course_language_pair.dart';

/// What kind of Course? The two cards of the Course Wizard's Basics step and
/// of New Course's form (Build 275 Revision 0, owner decisions of
/// 16 October 2026): Through another language, In the same language; neither
/// chosen at first. Under them, Which should I choose? opens the Editor
/// Help's answer.
///
/// Keys: `<keyPrefix>-kind-other`, `<keyPrefix>-kind-same`,
/// `<keyPrefix>-kind-help`.
class CourseKindChoice extends StatelessWidget {
  const CourseKindChoice({
    super.key,
    required this.kind,
    required this.onChanged,
    required this.keyPrefix,
  });

  final CourseKind? kind;
  final ValueChanged<CourseKind> onChanged;
  final String keyPrefix;

  /// The Editor Help question that helps to choose.
  static const helpQuestion = 'courseKind';

  static const otherTitle = 'Through another language';
  static const sameTitle = 'In the same language';
  static const otherBody =
      'For example Italian for English speakers. Learners read instructions '
      'and translations in the language they already speak.';
  static const sameBody =
      'For example English explained in English, for intermediate and '
      'advanced learners or native speakers. Everything is in the language '
      'being learned.';

  /// What the forms say while no kind is chosen.
  static const missing =
      'Choose what kind of Course it is: through another language, or in '
      'the same language.';

  /// What the forms say when Through another language names one language
  /// twice. Two variants of one language are a translation Course: each is
  /// typed by hand with its tag (the list holds languages, not variants).
  static String sameLanguageTwice(String language) =>
      'Both languages are $language: choose In the same language. For two '
      'variants of one language, type each by hand with its tag, such as '
      'English (UK) with en-GB and English (US) with en-US.';

  /// The kind as the Course shows it once it exists.
  static String shown(CourseKind kind, String source, String target) =>
      kind == CourseKind.sameLanguage
      ? '$sameTitle: $target'
      : '$otherTitle: $source → $target';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _card(
        context,
        CourseKind.otherLanguage,
        key: Key('$keyPrefix-kind-other'),
        title: otherTitle,
        body: otherBody,
      ),
      const SizedBox(height: 8),
      _card(
        context,
        CourseKind.sameLanguage,
        key: Key('$keyPrefix-kind-same'),
        title: sameTitle,
        body: sameBody,
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: Key('$keyPrefix-kind-help'),
          icon: const Icon(Icons.help_outline),
          label: const Text('Which should I choose?'),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const EditorHelpScreen(question: helpQuestion),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _card(
    BuildContext context,
    CourseKind value, {
    required Key key,
    required String title,
    required String body,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final chosen = kind == value;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: chosen,
      child: Material(
        key: key,
        color: chosen ? scheme.secondaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: chosen ? scheme.primary : scheme.outlineVariant,
            width: chosen ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  chosen
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: chosen ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(body),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
