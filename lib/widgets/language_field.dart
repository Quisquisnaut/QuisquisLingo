import 'package:flutter/material.dart';

import '../services/language_catalog.dart';

/// The language one side of a Course is in (Build 260 Revision 0): a
/// language of [LanguageCatalog], stored by its English name and tag, or one
/// entered by hand, with its name and an optional tag ('' when unknown).
class LanguageChoice {
  const LanguageChoice({required this.name, required this.tag});

  final String name;
  final String tag;
}

/// The text of a [LanguageField] and, for a language entered by hand, its
/// tag.
class LanguageFieldController {
  LanguageFieldController({String name = ''})
    : text = TextEditingController(text: name),
      tag = TextEditingController();

  final TextEditingController text;
  final TextEditingController tag;

  /// The listed language the text names (English name, other name or tag),
  /// or null for a language entered by hand.
  LanguageEntry? get entry => LanguageCatalog.resolve(text.text);

  bool get isEmpty => text.text.trim().isEmpty;
  bool get isHandEntered => !isEmpty && entry == null;

  /// Why the hand-entered tag cannot be used, or null.
  String? get tagError {
    final value = tag.text.trim();
    if (!isHandEntered || value.isEmpty || LanguageCatalog.isValidTag(value)) {
      return null;
    }
    return 'Not a language tag. Use letters such as nap, pt-BR or zh-Hant, or leave it empty.';
  }

  /// The language to store, or null while the field is empty or the tag is
  /// wrong.
  LanguageChoice? get choice {
    if (isEmpty || tagError != null) return null;
    final listed = entry;
    if (listed != null) {
      return LanguageChoice(name: listed.englishName, tag: listed.tag);
    }
    return LanguageChoice(name: text.text.trim(), tag: tag.text.trim());
  }

  void dispose() {
    text.dispose();
    tag.dispose();
  }
}

/// A Course language: type a language, or choose it from the list of
/// [LanguageCatalog] by its English name. A language the list does not hold
/// is kept as typed, with an optional tag.
class LanguageField extends StatefulWidget {
  const LanguageField({
    super.key,
    required this.controller,
    required this.label,
    required this.keyPrefix,
    this.onChanged,
  });

  final LanguageFieldController controller;
  final String label;

  /// Prefix of the field's keys: `<prefix>`, `<prefix>-list`, `<prefix>-tag`.
  final String keyPrefix;
  final VoidCallback? onChanged;

  @override
  State<LanguageField> createState() => _LanguageFieldState();
}

class _LanguageFieldState extends State<LanguageField> {
  void _changed() {
    setState(() {});
    widget.onChanged?.call();
  }

  Future<void> _pick() async {
    final entry = await showLanguagePicker(
      context,
      initialQuery: widget.controller.entry == null
          ? widget.controller.text.text
          : '',
    );
    if (entry == null) return;
    widget.controller.text.text = entry.englishName;
    widget.controller.tag.clear();
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final entry = controller.entry;
    final helper = controller.isEmpty
        ? 'Choose from the list, or type a language that is not in it.'
        : entry != null
        ? '${entry.englishName} · ${entry.tag}'
        : 'Not in the list: kept as typed.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: Key(widget.keyPrefix),
          controller: controller.text,
          maxLength: 80,
          onChanged: (_) => _changed(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.label,
            helperText: helper,
            helperMaxLines: 2,
            suffixIcon: IconButton(
              key: Key('${widget.keyPrefix}-list'),
              tooltip: 'Choose from the list',
              icon: const Icon(Icons.list_alt_outlined),
              onPressed: _pick,
            ),
          ),
        ),
        if (controller.isHandEntered) ...[
          const SizedBox(height: 8),
          TextField(
            key: Key('${widget.keyPrefix}-tag'),
            controller: controller.tag,
            maxLength: 35,
            onChanged: (_) => _changed(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Language tag (optional)',
              helperText:
                  'A tag such as nap, pt-BR or zh-Hant. Leave it empty if you do not know it.',
              helperMaxLines: 2,
              errorText: controller.tagError,
              errorMaxLines: 3,
            ),
          ),
        ],
      ],
    );
  }
}

/// The searchable list of [LanguageCatalog] languages by English name. Null
/// when closed without a choice.
Future<LanguageEntry?> showLanguagePicker(
  BuildContext context, {
  String initialQuery = '',
  String title = 'Choose a language',
}) => showDialog<LanguageEntry>(
  context: context,
  builder: (context) =>
      _LanguagePicker(initialQuery: initialQuery, title: title),
);

class _LanguagePicker extends StatefulWidget {
  const _LanguagePicker({required this.initialQuery, required this.title});

  final String initialQuery;
  final String title;

  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = LanguageCatalog.search(_query.text);
    return AlertDialog(
      key: const Key('language-picker'),
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              key: const Key('language-picker-search'),
              controller: _query,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search by name or tag',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        'Not in the list. Close this and type the language in the field.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final entry = results[index];
                        return ListTile(
                          key: Key('language-picker-${entry.tag}'),
                          dense: true,
                          title: Text(entry.englishName),
                          trailing: Text(entry.tag),
                          onTap: () => Navigator.pop(context, entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
