import 'package:flutter/material.dart';

import '../services/status_service.dart';
import 'learner_avatar.dart';

class AvatarCustomizationContent extends StatelessWidget {
  final int currentLevel;
  final String skinTone;
  final String hairTone;
  final ValueChanged<String> onSkinChanged;
  final ValueChanged<String> onHairChanged;

  const AvatarCustomizationContent({
    super.key,
    required this.currentLevel,
    required this.skinTone,
    required this.hairTone,
    required this.onSkinChanged,
    required this.onHairChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeLevel = currentLevel.clamp(0, StatusService.names.length - 1);
    final levelName = StatusService.names[safeLevel];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Status: $levelName',
          key: const Key('avatar-current-status'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('Skin and hair are your avatar choices.'),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 112,
            height: 128,
            child: LearnerAvatar(
              key: const Key('avatar-live-preview'),
              level: safeLevel,
              skinTone: skinTone,
              hairTone: hairTone,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Avatar skin color'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in const [
              ('light', 'Light'),
              ('medium', 'Medium'),
              ('dark', 'Dark'),
            ])
              ChoiceChip(
                key: Key('avatar-skin-${item.$1}'),
                label: Text(item.$2),
                selected: skinTone == item.$1,
                onSelected: (_) => onSkinChanged(item.$1),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Avatar hair color'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in const [('light', 'Light'), ('dark', 'Dark')])
              ChoiceChip(
                key: Key('avatar-hair-${item.$1}'),
                label: Text(item.$2),
                selected: hairTone == item.$1,
                onSelected: (_) => onHairChanged(item.$1),
              ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Text(
              'Status levels',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              key: const Key('status-level-help'),
              tooltip: 'How Status works',
              onPressed: () => _showStatusHelp(context),
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
        const Text('Each level has its own T-shirt color.'),
        const SizedBox(height: 8),
        for (var index = 0; index < StatusService.names.length; index++)
          _StatusLevelRow(index: index, isCurrent: index == safeLevel),
      ],
    );
  }

  Future<void> _showStatusHelp(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How Status works'),
      content: const SingleChildScrollView(
        child: Text(StatusService.progressionExplanation),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _StatusLevelRow extends StatelessWidget {
  final int index;
  final bool isCurrent;

  const _StatusLevelRow({required this.index, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final color = Color(StatusService.colorValues[index]);
    final threshold = StatusService.thresholds[index];
    return Card(
      key: isCurrent ? Key('status-level-current-$index') : null,
      color: isCurrent ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Container(
          key: Key('status-level-color-$index'),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        title: Text(StatusService.names[index]),
        subtitle: Text(
          threshold == 0
              ? 'Starts at 0 Status points'
              : 'Starts at ${_formatNumber(threshold)} Status points',
        ),
        trailing: isCurrent
            ? const Chip(
                avatar: Icon(Icons.check_circle, size: 18),
                label: Text('Current'),
              )
            : null,
      ),
    );
  }
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    if (index > 0 && (text.length - index) % 3 == 0) buffer.write(',');
    buffer.write(text[index]);
  }
  return buffer.toString();
}
