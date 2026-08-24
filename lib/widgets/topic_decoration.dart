import 'package:flutter/material.dart';

/// Lightweight decorative scenes for the bottom of Topic pages.
///
/// The variations are drawn from Material icons rather than remote assets, so
/// they add visual variety without downloads, licensing surprises or memory
/// spikes on low-spec desktop systems.
class TopicDecoration extends StatelessWidget {
  final int variant;
  const TopicDecoration({super.key, required this.variant});

  static const _scenes = <List<IconData>>[
    [Icons.park_outlined, Icons.eco_outlined, Icons.flutter_dash_outlined],
    [Icons.local_florist_outlined, Icons.nature_outlined, Icons.wb_sunny_outlined],
    [Icons.menu_book_outlined, Icons.park_outlined, Icons.auto_stories_outlined],
    [Icons.pedal_bike_outlined, Icons.park_outlined, Icons.alt_route_outlined],
    [Icons.coffee_outlined, Icons.local_florist_outlined, Icons.weekend_outlined],
    [Icons.public_outlined, Icons.eco_outlined, Icons.explore_outlined],
    [Icons.home_outlined, Icons.park_outlined, Icons.cloud_outlined],
    [Icons.train_outlined, Icons.nature_outlined, Icons.park_outlined],
    [Icons.restaurant_outlined, Icons.local_florist_outlined, Icons.eco_outlined],
    [Icons.music_note_outlined, Icons.park_outlined, Icons.flutter_dash_outlined],
    [Icons.account_balance_outlined, Icons.park_outlined, Icons.auto_awesome_outlined],
    [Icons.water_drop_outlined, Icons.local_florist_outlined, Icons.park_outlined],
    [Icons.map_outlined, Icons.alt_route_outlined, Icons.eco_outlined],
    [Icons.nightlight_outlined, Icons.park_outlined, Icons.star_outline],
    [Icons.wb_sunny_outlined, Icons.nature_outlined, Icons.local_florist_outlined],
    [Icons.bug_report_outlined, Icons.park_outlined, Icons.eco_outlined],
  ];

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[variant.abs() % _scenes.length];
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: .52);
    return Semantics(
      label: 'Decorative tree and plant illustration',
      child: SizedBox(
        height: 138,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 8,
              left: 18,
              child: Icon(scene[0], size: 92, color: color),
            ),
            Positioned(
              bottom: 16,
              right: 34,
              child: Icon(scene[1], size: 58, color: color.withValues(alpha: .82)),
            ),
            Positioned(
              top: 14,
              right: 82,
              child: Icon(scene[2], size: 32, color: color.withValues(alpha: .72)),
            ),
          ],
        ),
      ),
    );
  }
}
