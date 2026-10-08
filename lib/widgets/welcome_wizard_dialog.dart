import 'package:flutter/material.dart';

import '../localization/locale_service.dart';
import '../localization/welcome_text.dart';

/// Shows the Welcome Wizard in [locale], the language the learner chose in
/// Create Profile. Returns true when the learner finishes or skips it.
Future<bool?> showWelcomeWizard(
  BuildContext context, {
  AppLocale locale = AppLocale.english,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => WelcomeWizardDialog(locale: locale),
);

/// Five short steps, each with a QuisquisLingo mascot (Build 255 Revision 7):
/// what QQL is, Courses made by others, Lessons and Laurels, studying little
/// and often, and Course Studio.
class WelcomeWizardDialog extends StatefulWidget {
  const WelcomeWizardDialog({super.key, this.locale = AppLocale.english});

  final AppLocale locale;

  @override
  State<WelcomeWizardDialog> createState() => _WelcomeWizardDialogState();
}

class _WelcomeWizardDialogState extends State<WelcomeWizardDialog> {
  /// In order: the kid, the cat, the monkey, the robot and the dog.
  static const _steps = [
    (color: Color(0xFF1565C0), mascot: 'assets/mascots/kid_reading.webp'),
    (
      color: Color(0xFF6A1B9A),
      mascot: 'assets/mascots/cat-celebrating_tr.webp',
    ),
    (color: Color(0xFF00796B), mascot: 'assets/mascots/monkey-yawning_tr.webp'),
    (color: Color(0xFFEF6C00), mascot: 'assets/mascots/robot_running.webp'),
    (
      color: Color(0xFFAD1457),
      mascot: 'assets/mascots/dog-laughing-pencil_tr.webp',
    ),
  ];

  static const _mascotHeight = 132.0;

  var _step = 0;

  String _text(String key, [Map<String, String> values = const {}]) =>
      welcomeText.lookup(widget.locale, key, values: values);

  @override
  Widget build(BuildContext context) {
    final current = _steps[_step];
    final number = _step + 1;
    final finalStep = number == _steps.length;
    return AlertDialog(
      key: const Key('welcome-wizard'),
      title: Text(
        _text('step$number.title'),
        style: TextStyle(color: current.color, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  current.mascot,
                  key: ValueKey('welcome-wizard-mascot-$number'),
                  height: _mascotHeight,
                  // The mascots are large pictures: decode them at the size
                  // shown.
                  cacheHeight:
                      (_mascotHeight * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _text('step', {
                  'current': '$number',
                  'total': '${_steps.length}',
                }),
                style: TextStyle(
                  color: current.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: current.color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _text('step$number.body'),
                    key: const Key('welcome-wizard-body'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_step > 0)
          TextButton(
            key: const Key('welcome-wizard-back'),
            onPressed: () => setState(() => _step--),
            child: Text(_text('back')),
          ),
        TextButton(
          key: const Key('welcome-wizard-skip'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(_text('skip')),
        ),
        FilledButton(
          key: const Key('welcome-wizard-next'),
          onPressed: () {
            if (finalStep) {
              Navigator.pop(context, true);
            } else {
              setState(() => _step++);
            }
          },
          child: Text(_text(finalStep ? 'start' : 'next')),
        ),
      ],
    );
  }
}
