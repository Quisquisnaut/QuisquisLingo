import 'course_models.dart';

/// Historical QQL course-credit and content-license vocabulary.
abstract final class CourseMetadataOptions {
  static const standardRoles = <String>[
    'Author',
    'Team Leader',
    'Contributor',
    'Editor',
    'Reviewer',
    'Native Speaker',
    'Audio Contributor',
    'Illustrator',
  ];

  static const roleDescriptions = <String, String>{
    'Author': 'Authored or designed a substantial part of the Course content.',
    'Editor':
        'Maintains or substantially revises existing course content over time.',
    'Contributor':
        'Provided a specific or limited contribution without creating or maintaining the course as a whole.',
    'Team Leader':
        'Coordinates the credited course team. This credit does not grant Team administration or authoring access.',
    'Reviewer':
        'Checks content and reports corrections or improvements without normally maintaining the course.',
    'Native Speaker':
        'Contributes specifically to naturalness and language-quality review.',
    'Audio Contributor': 'Provides voice recordings or other course audio.',
    'Illustrator': 'Creates or supplies visual artwork for the course.',
  };

  static const standardLicenses = <String>[
    'All rights reserved',
    'CC0 1.0',
    'CC BY 4.0',
    'CC BY-SA 4.0',
    'CC BY-NC 4.0',
    'CC BY-NC-SA 4.0',
    'Other / Custom license',
  ];

  static DerivativeWorksPolicy derivativePolicyForLicense(String license) =>
      switch (license) {
        'All rights reserved' => DerivativeWorksPolicy.forbidden,
        'CC0 1.0' ||
        'CC BY 4.0' ||
        'CC BY-SA 4.0' ||
        'CC BY-NC 4.0' ||
        'CC BY-NC-SA 4.0' => DerivativeWorksPolicy.allowed,
        _ => DerivativeWorksPolicy.unspecified,
      };
}
