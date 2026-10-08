import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build 266 (GuideBook Modules): drives the GuideBook page from a test.
/// Before Build 266 the GuideBook was one page of text fields (Overview,
/// Usage examples, Vocabulary, Grammar); it is now a list of modules, each
/// edited on its own page.
///
/// Adds a module on the open GuideBook page: Add module, the module's
/// [title], its [sentences] and [words] (target, source) and [overview],
/// then Done, back on the GuideBook page (not yet saved).
Future<void> addGuidebookModule(
  WidgetTester tester, {
  String title = 'Greetings',
  String overview = '',
  List<(String, String)> sentences = const [],
  List<(String, String)> words = const [],
  Future<void> Function()? settle,
}) async {
  Future<void> pump() => settle?.call() ?? tester.pumpAndSettle();
  Future<void> tapKey(Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await pump();
  }

  Future<void> type(Key key, String text) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.enterText(find.byKey(key), text);
    await pump();
  }

  await tapKey(const Key('guidebook-add-module'));
  await type(const Key('guidebook-module-title'), title);
  for (var i = 0; i < sentences.length; i++) {
    await tapKey(const ValueKey('guidebook-module-add-sentence'));
    await type(ValueKey('guidebook-module-sentence-$i-target'), sentences[i].$1);
    await type(ValueKey('guidebook-module-sentence-$i-source'), sentences[i].$2);
  }
  for (var i = 0; i < words.length; i++) {
    await tapKey(const ValueKey('guidebook-module-add-word'));
    await type(ValueKey('guidebook-module-word-$i-target'), words[i].$1);
    await type(ValueKey('guidebook-module-word-$i-source'), words[i].$2);
  }
  if (overview.isNotEmpty) {
    await type(const Key('guidebook-module-overview'), overview);
  }
  await tester.tap(find.byKey(const Key('guidebook-module-done')));
  await pump();
}
