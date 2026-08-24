import 'package:flutter/material.dart';
import '../services/alpha_lifecycle_service.dart';

/// Learner-facing gate for an expired alpha. Authoring remains available from
/// Settings/Course Editor and no local learner or course data is deleted.
class AlphaExpiredView extends StatelessWidget {
  final bool scaffold;
  const AlphaExpiredView({super.key, this.scaffold = true});

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.update, size: 44),
                  const SizedBox(height: 12),
                  Text('This alpha version has expired.', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text('Install a newer QuisquisLingo alpha to continue learning. Your learner progress, locally installed courses, course edits and settings have not been deleted. Course Editor remains available so authoring work can be recovered or exported.', textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text('Alpha expiry: ${AlphaLifecycleService.expiryIsoDate}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return scaffold ? Scaffold(appBar: AppBar(title: const Text('Alpha expired')), body: content) : content;
  }
}
