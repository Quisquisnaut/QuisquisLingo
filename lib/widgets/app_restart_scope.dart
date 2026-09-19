import 'package:flutter/widgets.dart';

/// Rebuilds everything below it from scratch, as after a fresh launch.
///
/// Used after a full QQL reset so the app returns to its first-run flow with
/// no state kept in memory from before the reset.
class AppRestartScope extends StatefulWidget {
  final Widget child;

  const AppRestartScope({super.key, required this.child});

  static void restart(BuildContext context) =>
      context.findAncestorStateOfType<_AppRestartScopeState>()?.restart();

  @override
  State<AppRestartScope> createState() => _AppRestartScopeState();
}

class _AppRestartScopeState extends State<AppRestartScope> {
  Key _key = UniqueKey();

  void restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
