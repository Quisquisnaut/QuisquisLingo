import 'package:flutter/material.dart';

import '../models/course_models.dart';

/// The optional Editor Notes of an exercise (Build 267 Revision 8, owner
/// decisions of 9 October 2026): the author's own, never shown to learners.
/// The preset form gives a [controller]; the canonical editor an
/// [initialValue], as its other fields. [help] is the field's Help control
/// (the preset form's, as its other fields).
class EditorNotesField extends StatelessWidget {
  const EditorNotesField({
    super.key,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.onChanged,
    this.help,
  }) : assert(controller == null || initialValue == null);

  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Widget? help;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: initialValue,
    readOnly: readOnly,
    minLines: 2,
    maxLines: 6,
    maxLength: Exercise.maxEditorNotesLength,
    onChanged: onChanged,
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: 'Editor notes (optional)',
      helperText:
          'Only authors see them, here and as a note icon in the Round '
          'editor; learners never do. Export as Publisher Course leaves them '
          'out.',
      helperMaxLines: 3,
      prefixIcon: const Icon(Icons.sticky_note_2_outlined),
      suffixIcon: help,
    ),
  );
}
