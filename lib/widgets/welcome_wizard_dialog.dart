import 'package:flutter/material.dart';

Future<bool?> showWelcomeWizard(BuildContext context) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const WelcomeWizardDialog(),
);

class WelcomeWizardDialog extends StatefulWidget {
  const WelcomeWizardDialog({super.key});

  @override
  State<WelcomeWizardDialog> createState() => _WelcomeWizardDialogState();
}

class _WelcomeWizardDialogState extends State<WelcomeWizardDialog> {
  static const _steps = [
    (
      color: Color(0xFF1565C0),
      icon: Icons.language_outlined,
      title: 'Welcome to QuisquisLingo',
      body:
          'Learn languages offline. Your Courses, profiles and progress stay on this device.',
    ),
    (
      color: Color(0xFF6A1B9A),
      icon: Icons.person_outline,
      title: 'Your learner profile',
      body:
          'Your profile and avatar keep your local learning progress together.',
    ),
    (
      color: Color(0xFF00796B),
      icon: Icons.menu_book_outlined,
      title: 'Choose a Course',
      body:
          'Use the Course selector to start learning. It also opens Course Manager.',
    ),
    (
      color: Color(0xFFEF6C00),
      icon: Icons.route_outlined,
      title: 'Learn through Lessons and Rounds',
      body:
          'Complete Lessons and Rounds to unlock more. Review reinforces learning; Duels are optional.',
    ),
    (
      color: Color(0xFFAD1457),
      icon: Icons.emoji_events_outlined,
      title: 'Track your learning',
      body:
          'Follow your streak, Laurels and Weekly XP. Settings keeps your preferences local.',
    ),
  ];

  var _step = 0;

  @override
  Widget build(BuildContext context) {
    final current = _steps[_step];
    final finalStep = _step == _steps.length - 1;
    return AlertDialog(
      key: const Key('welcome-wizard'),
      title: Row(
        children: [
          Icon(current.icon, color: current.color),
          const SizedBox(width: 10),
          Expanded(child: Text(current.title)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${_step + 1} of ${_steps.length}',
              style: TextStyle(
                color: current.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: current.color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(current.body),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_step > 0)
          TextButton(
            key: const Key('welcome-wizard-back'),
            onPressed: () => setState(() => _step--),
            child: const Text('Back'),
          ),
        TextButton(
          key: const Key('welcome-wizard-skip'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Skip'),
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
          child: Text(finalStep ? 'Start learning' : 'Next'),
        ),
      ],
    );
  }
}
