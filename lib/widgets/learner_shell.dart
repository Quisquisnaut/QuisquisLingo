import 'package:flutter/material.dart';

import '../controllers/learner_status_controller.dart';
import 'learner_navigation.dart';
import 'learner_status_bar.dart';

class LearnerShell extends StatefulWidget {
  static const double statusSlotHeight = learnerStatusSlotHeight;

  final Widget child;
  final LearnerStatusController? controller;

  const LearnerShell({super.key, required this.child, this.controller});

  static LearnerShellState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LearnerShellScope>()?.state;

  @override
  State<LearnerShell> createState() => LearnerShellState();
}

class LearnerShellState extends State<LearnerShell> {
  late final LearnerStatusController _controller;
  late final bool _ownsController;
  final ValueNotifier<(bool, LearnerStatusForeground, double)> _presentation =
      ValueNotifier((false, LearnerStatusForeground.dark, kToolbarHeight));
  final Map<ModalRoute<dynamic>, (LearnerStatusForeground, double)>
  _eligibleRoutes = {};
  bool _reconcileScheduled = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? LearnerStatusController();
  }

  void registerRoute(
    ModalRoute<dynamic> route,
    LearnerStatusForeground foreground,
    double statusBarTop,
  ) {
    _eligibleRoutes[route] = (foreground, statusBarTop);
    scheduleReconcile();
  }

  void unregisterRoute(ModalRoute<dynamic> route) {
    _eligibleRoutes.remove(route);
    scheduleReconcile();
  }

  void scheduleReconcile() {
    if (_reconcileScheduled) return;
    _reconcileScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcileScheduled = false;
      if (!mounted) return;
      MapEntry<ModalRoute<dynamic>, (LearnerStatusForeground, double)>? current;
      for (final entry in _eligibleRoutes.entries) {
        if (entry.key.isCurrent) current = entry;
      }
      final next = current == null
          ? (false, _presentation.value.$2, _presentation.value.$3)
          : (true, current.value.$1, current.value.$2);
      if (_presentation.value != next) _presentation.value = next;
    });
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    _presentation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LearnerShellScope(
      state: this,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          ValueListenableBuilder<(bool, LearnerStatusForeground, double)>(
            valueListenable: _presentation,
            builder: (context, presentation, _) {
              if (!presentation.$1) return const SizedBox.shrink();
              return Positioned(
                key: const Key('learner-status-position'),
                top: MediaQuery.paddingOf(context).top + presentation.$3,
                left: 0,
                right: 0,
                height: LearnerShell.statusSlotHeight,
                child: LearnerStatusBar(
                  controller: _controller,
                  foreground: presentation.$2,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LearnerShellScope extends InheritedWidget {
  final LearnerShellState state;

  const _LearnerShellScope({required this.state, required super.child});

  @override
  bool updateShouldNotify(_LearnerShellScope oldWidget) => false;
}

/// Declares that a route participates in the persistent learner status shell.
class LearnerStatusPage extends StatefulWidget {
  final Widget child;
  final LearnerStatusForeground foreground;
  final double statusBarTop;

  const LearnerStatusPage({
    super.key,
    required this.child,
    this.foreground = LearnerStatusForeground.dark,
    this.statusBarTop = kToolbarHeight,
  });

  @override
  State<LearnerStatusPage> createState() => _LearnerStatusPageState();
}

class _LearnerStatusPageState extends State<LearnerStatusPage> with RouteAware {
  ModalRoute<dynamic>? _route;
  LearnerShellState? _shell;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final shell = LearnerShell.maybeOf(context);
    if (_route == route && _shell == shell) return;
    if (_route != null) {
      learnerStatusRouteObserver.unsubscribe(this);
      _shell?.unregisterRoute(_route!);
    }
    _route = route;
    _shell = shell;
    if (route != null) {
      learnerStatusRouteObserver.subscribe(this, route);
      shell?.registerRoute(route, widget.foreground, widget.statusBarTop);
    }
  }

  @override
  void didUpdateWidget(LearnerStatusPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.foreground != widget.foreground ||
            oldWidget.statusBarTop != widget.statusBarTop) &&
        _route != null) {
      _shell?.registerRoute(_route!, widget.foreground, widget.statusBarTop);
    }
  }

  @override
  void didPush() => _shell?.scheduleReconcile();

  @override
  void didPopNext() => _shell?.scheduleReconcile();

  @override
  void didPushNext() => _shell?.scheduleReconcile();

  @override
  void didPop() => _shell?.scheduleReconcile();

  @override
  void dispose() {
    learnerStatusRouteObserver.unsubscribe(this);
    if (_route != null) _shell?.unregisterRoute(_route!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Reserves the transparent, fixed-height shell slot below a page's app bar.
class LearnerStatusAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final PreferredSizeWidget appBar;
  final Color? backgroundColor;

  const LearnerStatusAppBar({
    super.key,
    required this.appBar,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    appBar.preferredSize.height + LearnerShell.statusSlotHeight,
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: appBar,
            ),
          ),
          const SizedBox(height: LearnerShell.statusSlotHeight),
        ],
      ),
    );
  }
}
