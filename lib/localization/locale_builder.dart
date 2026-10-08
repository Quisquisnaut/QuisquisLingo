import 'dart:async';

import 'package:flutter/material.dart';

import '../services/learner_status_events.dart';
import 'locale_service.dart';

/// Rebuilds localized surfaces after a Locale change or learner switch.
///
/// The persisted preference remains authoritative; this widget never writes.
class LocaleBuilder extends StatefulWidget {
  const LocaleBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, AppLocale locale) builder;

  @override
  State<LocaleBuilder> createState() => _LocaleBuilderState();
}

class _LocaleBuilderState extends State<LocaleBuilder> {
  final _service = LocaleService();
  late final StreamSubscription<LearnerStatusInvalidation> _subscription;
  AppLocale _locale = AppLocale.english;
  int _readSequence = 0;

  @override
  void initState() {
    super.initState();
    _subscription = LearnerStatusEvents.stream.listen((event) {
      if (event == LearnerStatusInvalidation.locale ||
          event == LearnerStatusInvalidation.activeProfile) {
        unawaited(_reload());
      }
    });
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final sequence = ++_readSequence;
    AppLocale locale;
    try {
      locale = await _service.read();
    } catch (_) {
      locale = AppLocale.english;
    }
    if (!mounted || sequence != _readSequence) return;
    if (locale != _locale) setState(() => _locale = locale);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _locale);
}
