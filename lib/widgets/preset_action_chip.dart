import 'package:flutter/material.dart';

/// The action word of a preset tile (Choose, Type, Arrange, Match, Card, …).
class PresetActionChip extends StatelessWidget {
  const PresetActionChip(this.action, {super.key});

  final String action;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(action),
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: EdgeInsets.zero,
  );
}
