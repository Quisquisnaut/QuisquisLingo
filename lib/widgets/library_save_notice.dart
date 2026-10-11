import 'package:flutter/material.dart';

/// The one line a Course's Audio Library and Image Library open with (Build
/// 271 Revision 2, owner decision of 10 October 2026): word for word the
/// same in both, so it is written once.
class LibrarySaveNotice extends StatelessWidget {
  const LibrarySaveNotice({super.key});

  static const text =
      'Changes are applied to the Course when you leave; Save now or Save '
      'course writes them.';

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
