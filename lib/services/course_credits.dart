import '../models/course_metadata_options.dart';
import '../models/course_models.dart';

/// The rules that turn what an author enters about a Course's credits and
/// rights into what the Course stores: a credit's roles, the licence chosen
/// from the list and the derivative-works policy that goes with it, and the
/// Rights Holder rows.
///
/// Course Info, New Course and the Course Wizard share them (Build 272
/// Revision 0; each screen had its own copy before). Pure Dart: no screen,
/// no storage. The vocabulary (the standard roles and licences) stays in
/// [CourseMetadataOptions].
abstract final class CourseCredits {
  /// The role of a credit whose author chose none.
  static const defaultRole = 'Contributor';

  /// A credit's roles as a Course stores them: the [standard] ones in their
  /// standard order, then the author's own from [custom] (separated by
  /// commas, each once, as typed), and [defaultRole] when there is none.
  static List<String> rolesOf(Iterable<String> standard, String custom) {
    final chosen = standard.toSet();
    final roles = <String>[
      ...CourseMetadataOptions.standardRoles.where(chosen.contains),
    ];
    for (final part in custom.split(',')) {
      final role = part.trim();
      if (role.isNotEmpty && !roles.contains(role)) roles.add(role);
    }
    if (roles.isEmpty) roles.add(defaultRole);
    return roles;
  }

  /// The standard roles among a stored credit's [roles]: the chips a form
  /// shows selected.
  static Set<String> standardRolesIn(Iterable<String> roles) => {
    ...roles.where(CourseMetadataOptions.standardRoles.contains),
  };

  /// A stored credit's other [roles], as the form's text field shows them.
  static String customRolesIn(Iterable<String> roles) => roles
      .where((role) => !CourseMetadataOptions.standardRoles.contains(role))
      .join(', ');

  /// The credit of one row of a form, or null for a row without a name.
  static CourseAuthor? author({
    required String name,
    required Iterable<String> standardRoles,
    required String customRoles,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return CourseAuthor(
      name: trimmed,
      roles: rolesOf(standardRoles, customRoles),
    );
  }

  /// The Rights Holder of one row of a form, or null for a row without a
  /// name.
  static CourseRightsHolder? rightsHolder(
    CourseRightsHolderType type,
    String name,
  ) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return CourseRightsHolder(type: type, name: trimmed);
  }

  /// Whether [choice] is the entry of the licence list that opens the
  /// Custom license field.
  static bool isCustomLicenseChoice(String choice) =>
      choice == CourseMetadataOptions.customLicense;

  /// The entry of the licence list that shows a stored [license]: the
  /// licence itself when the list has it, else Other / Custom license.
  static String licenseChoiceFor(String license) =>
      CourseMetadataOptions.standardLicenses.contains(license)
      ? license
      : CourseMetadataOptions.customLicense;

  /// The licence a Course stores for a [choice] of the list: the text typed
  /// in the Custom license field for Other / Custom license (empty when
  /// nothing was typed: each form refuses that in its own way), else the
  /// choice.
  static String licenseOf(String choice, String customText) =>
      isCustomLicenseChoice(choice) ? customText.trim() : choice;

  /// The derivative-works policy stored with a [choice] of the list: the
  /// author's own ([chosen]) for Other / Custom license, else the policy the
  /// licence states.
  static DerivativeWorksPolicy policyOf(
    String choice,
    DerivativeWorksPolicy chosen,
  ) => isCustomLicenseChoice(choice)
      ? chosen
      : CourseMetadataOptions.derivativePolicyForLicense(choice);

  /// As [policyOf], for a form that edits a stored Course: a licence of the
  /// list left as the Course stores it keeps the Course's policy, also one
  /// the licence does not state (a Course may be "All rights reserved" and
  /// still allow derivative works). Course Info uses this; the Course Wizard
  /// uses [policyOf].
  static DerivativeWorksPolicy policyKeepingStored(
    String choice,
    DerivativeWorksPolicy chosen, {
    required String storedLicense,
    required DerivativeWorksPolicy storedPolicy,
  }) => !isCustomLicenseChoice(choice) && choice == storedLicense
      ? storedPolicy
      : policyOf(choice, chosen);

  /// The policy a form shows after its author picked [choice]: the one the
  /// licence states, or [current] when it states none (Other / Custom
  /// license), so the author's earlier answer is not lost.
  static DerivativeWorksPolicy policyAfterChoosing(
    String choice,
    DerivativeWorksPolicy current,
  ) {
    final stated = CourseMetadataOptions.derivativePolicyForLicense(choice);
    return stated == DerivativeWorksPolicy.unspecified ? current : stated;
  }
}
