import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_en.dart';
import 'package:quisquislingo_app/localization/help/help_es.dart';
import 'package:quisquislingo_app/localization/help/help_it.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';

void main() {
  test('EN IT ES have complete, nonempty key parity', () {
    expect(helpIt.keys.toSet(), helpEn.keys.toSet());
    expect(helpEs.keys.toSet(), helpEn.keys.toSet());
    for (final catalog in [helpEn, helpIt, helpEs]) {
      for (final entry in catalog.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('dynamic App Info and Course Info values survive translation', () {
    final placeholder = RegExp(r'\{[a-zA-Z][a-zA-Z0-9]*\}');
    Set<String> tokens(String value) =>
        placeholder.allMatches(value).map((match) => match.group(0)!).toSet();
    for (final entry in helpEn.entries.where(
      (entry) =>
          entry.key.startsWith('appInfo.') ||
          entry.key.startsWith('courseInfo.'),
    )) {
      final englishTokens = tokens(entry.value);
      for (final catalog in [helpIt, helpEs]) {
        expect(tokens(catalog[entry.key]!), englishTokens, reason: entry.key);
      }
    }
  });

  test(
    'ordered Help sections and Exercise field guides resolve in all three',
    () {
      final sectionGroups = <(String, List<String>)>[
        ('editorHelp', editorHelpSectionIds),
        ('editorHelp', courseStudioHelpSectionIds),
        ('appInfo', appInfoSectionIds),
        ('allCoursesHelp', allCoursesHelpSectionIds),
        ('technical.courseModel', courseModelHelpSectionIds),
        ('technical.exercisePrimitives', exercisePrimitivesHelpSectionIds),
        ('technical.jsonStructure', jsonStructureHelpSectionIds),
        ('debugHelp', debugHelpSectionIds),
        ('publisherSigningHelp', publisherSigningHelpSectionIds),
      ];
      for (final locale in AppLocale.values) {
        for (final (prefix, ids) in sectionGroups) {
          for (final id in ids) {
            expect(helpText.lookup(locale, '$prefix.$id.title'), isNotEmpty);
            if (prefix != 'appInfo' ||
                (id != 'versionAndBuild' && id != 'betaExpiry')) {
              expect(helpText.lookup(locale, '$prefix.$id.body'), isNotEmpty);
            }
          }
        }
        for (final preset in ExercisePresetRegistry.presets) {
          expect(
            helpText.lookup(locale, 'exerciseHelp.preset.${preset.id}.body'),
            isNotEmpty,
          );
          for (final field in ExerciseFieldHelpRegistry.editorFieldKeys(
            preset.id,
          )) {
            final key =
                exerciseHelpFieldKeyByPresetAndField['${preset.id}.$field'];
            expect(key, isNotNull, reason: '${preset.id}.$field');
            expect(helpText.lookup(locale, key!), isNotEmpty);
          }
        }
      }
    },
  );

  test('translated prose retains canonical English QQL commands', () {
    for (final locale in AppLocale.values) {
      final wizard = helpText.lookup(
        locale,
        'editorHelp.exerciseCreationWizard.body',
      );
      expect(wizard, contains('Exercise Wizard'));
      expect(wizard, contains('New exercise'));
      expect(wizard, isNot(contains('Creation Wizard')));
      final export = helpText.lookup(
        locale,
        'editorHelp.exportCustomCourse.body',
      );
      expect(export, contains('Export Course'));
      expect(export, isNot(contains('Export Course ZIP')));
    }
    final commandChecks = <String, List<String>>{
      'editorHelp.oneCourseEditorTransaction.body': [
        'View only',
        'Inspection mode',
        'Edit',
        'Save as draft',
      ],
      'editorHelp.confirmOrCancelCompleteCourse.body': [
        'Confirm course changes',
        'Cancel course changes',
      ],
      'courseStudioHelp.courseOperations.body': [
        'Copy as New Course',
        'Fork',
        'Merge',
        'Hide in Learner',
      ],
      'appInfo.audioSettings.body': [
        'Audio Settings',
        'Enable Audio Exercises',
        'Text-to-speech',
        'Test Voice',
      ],
      'courseInfo.title': ['Course Info'],
      'courseInfo.buyACoffee': ['Buy a Coffee'],
    };
    for (final locale in [AppLocale.italian, AppLocale.spanish]) {
      for (final category in ExerciseCategory.values) {
        expect(
          helpText.lookup(locale, 'exerciseHelp.category.${category.name}'),
          category.label,
          reason: '${locale.id}: ${category.name}',
        );
      }
      for (final entry in commandChecks.entries) {
        final translated = helpText.lookup(locale, entry.key);
        for (final command in entry.value) {
          expect(
            translated,
            contains(command),
            reason: '${locale.id}: ${entry.key}',
          );
        }
      }
      expect(
        helpText.lookup(locale, 'publisherSigningHelp.signAndDistribute.body'),
        contains('dart run tools/sign_course.dart prepare'),
      );
    }
  });

  test('QQL-Tools Device Administration Help explains its boundaries', () {
    expect(deviceAdminHelpSectionIds, contains('qqlTools'));
    expect(
      deviceAdminHelpSectionShape['qqlTools'],
      (paragraphs: 2, bullets: 0),
    );
    for (final locale in AppLocale.values) {
      expect(
        helpText.lookup(locale, 'deviceAdminHelp.qqlTools.title'),
        'QQL-Tools',
      );
      final help = [
        helpText.lookup(locale, 'deviceAdminHelp.qqlTools.paragraph1'),
        helpText.lookup(locale, 'deviceAdminHelp.qqlTools.paragraph2'),
      ].join(' ');
      for (final phrase in [
        'QQL-Tools',
        'Course Audit',
        'Browse...',
        'Test',
        'Clear',
        'Validate with QQL-Tools...',
        'Not available on mobile devices.',
      ]) {
        expect(help, contains(phrase), reason: locale.id);
      }
    }
  });
}
