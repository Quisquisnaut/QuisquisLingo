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
  /// The role of a credit whose author chose none, and the role a person
  /// added to a form starts with.
  static const defaultRole = 'Contributor';

  /// The role of the row a form fills with the Course creator's own name.
  static const creatorRole = 'Author';

  /// The one license of QQL's list that gives the rights up: nobody holds
  /// them, so it asks for no Rights Holder (owner decision of 13 October
  /// 2026).
  static const rightsGivenUp = 'CC0 1.0';

  /// What the forms of a new Course say under the Rights Holder rows.
  static const rightsHolderDefaultNote =
      'Left empty, the Rights Holder is the Author named above (everyone '
      'with the role Author, else the first person named). CC0 1.0 needs '
      'none: it gives the rights up.';

  /// What the Course Wizard says instead for a Course that names no Rights
  /// Holder and whose license asks for one: a Course stored before a new
  /// Course named one, or one whose credits name nobody.
  static const rightsHolderMissingNote =
      'This Course names no Rights Holder yet. Add one below, or change the '
      'Author or the license: the Author is then named (not with CC0 1.0).';

  /// The line under the Wizard's empty Rights Holder rows for [stored].
  static String rightsHolderNoteFor(Course stored) =>
      stored.rightsHolders.isEmpty && needsRightsHolder(stored.license)
      ? rightsHolderMissingNote
      : rightsHolderDefaultNote;

  /// What a form says when Other / Custom license is chosen and no text is
  /// typed.
  static const customLicenseMissing =
      'Type the custom license, or choose a license from the list.';

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

  /// Whether a Course with [license] should name a Rights Holder: it states
  /// a license, and the license keeps rights. A license with nobody holding
  /// the rights does not say whom to ask (Build 272 Revision 14).
  static bool needsRightsHolder(String license) =>
      license.trim().isNotEmpty && license.trim() != rightsGivenUp;

  /// The Rights Holders a new Course names when its form names none: the
  /// people the form credits as [creatorRole] (Author), or the first person
  /// it names when none has that role. They are the AUTHOR of the form, not
  /// the app's own name of who is creating the Course (owner decision: an
  /// author may use another name in the app, or create a Course from
  /// someone else's material). None for a license that needs none.
  static List<CourseRightsHolder> defaultRightsHolders(
    List<CourseAuthor> authors,
    String license,
  ) {
    if (!needsRightsHolder(license)) return const [];
    // A person credited in two rows is one Rights Holder.
    final names = <String>{
      for (final author in mainAuthors(authors)) author.name.trim(),
    };
    return [
      for (final name in names)
        CourseRightsHolder(type: CourseRightsHolderType.person, name: name),
    ];
  }

  /// The people [authors] credit as [creatorRole] (Author), or the first
  /// person named when none has that role.
  static List<CourseAuthor> mainAuthors(List<CourseAuthor> authors) {
    final named = [
      for (final author in authors)
        if (author.name.trim().isNotEmpty) author,
    ];
    final main = [
      for (final author in named)
        if (author.roles.contains(creatorRole)) author,
    ];
    return main.isNotEmpty ? main : named.take(1).toList();
  }

  /// The Rights Holders New Course stores: the ones its form [named], else
  /// [defaultRightsHolders].
  static List<CourseRightsHolder> rightsHoldersOfNewCourse({
    required List<CourseRightsHolder> named,
    required List<CourseAuthor> authors,
    required String license,
  }) => named.isNotEmpty ? named : defaultRightsHolders(authors, license);

  /// The Rights Holders [course]'s author wrote by hand: none when the
  /// Course names exactly the default of its own authors and license. The
  /// Course Wizard creates the Course before its author has written the
  /// credits, so its form shows that default as rows left empty, as New
  /// Course's form does, and what it stores is what
  /// [rightsHoldersOfWizardCredits] makes of the fields on screen. (A form
  /// that showed the default as a row stored the earlier Author's name
  /// again after a save that stayed on the step.)
  static List<CourseRightsHolder> rightsHoldersByHand(Course course) =>
      sameRightsHolders(
        course.rightsHolders,
        defaultRightsHolders(course.authors, course.license),
      )
      ? const []
      : course.rightsHolders;

  /// The Rights Holders the Course Wizard's credits store in the Course
  /// [stored]: the ones its rows name ([named]), else the default of the
  /// form's [authors] and [license], with one exception. A Course stored
  /// without a Rights Holder (made before a new Course named one, or
  /// emptied in Course Info Editor) keeps none while the form leaves its
  /// authors and its license as they are: a stored Course is never changed
  /// by a step its author only opened (owner decision of 13 October 2026;
  /// found by the independent review: the step looked unsaved as soon as
  /// it was shown).
  static List<CourseRightsHolder> rightsHoldersOfWizardCredits({
    required List<CourseRightsHolder> named,
    required Course stored,
    required List<CourseAuthor> authors,
    required String license,
  }) {
    if (named.isNotEmpty) return named;
    // The stored authors as a form writes them: a form puts the roles in
    // its own order, which is no change of the credits (found by the
    // second review: roles stored in another order named the Author).
    if (stored.rightsHolders.isEmpty &&
        stored.license == license &&
        sameAuthors(authorsAsFormsWrite(stored.authors), authors)) {
      return const [];
    }
    return defaultRightsHolders(authors, license);
  }

  /// [authors] as a form that shows them stores them again untouched: the
  /// standard roles first, in their order, then the author's own.
  static List<CourseAuthor> authorsAsFormsWrite(List<CourseAuthor> authors) => [
    for (final stored in authors)
      if (author(
            name: stored.name,
            standardRoles: standardRolesIn(stored.roles),
            customRoles: customRolesIn(stored.roles),
          )
          case final written?)
        written,
  ];

  /// Whether two lists credit the same people with the same roles in the
  /// same order.
  static bool sameAuthors(List<CourseAuthor> a, List<CourseAuthor> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      final one = a[index];
      final other = b[index];
      if (one.name != other.name || one.roles.length != other.roles.length) {
        return false;
      }
      for (var role = 0; role < one.roles.length; role++) {
        if (one.roles[role] != other.roles[role]) return false;
      }
    }
    return true;
  }

  /// Whether two lists name the same Rights Holders in the same order.
  static bool sameRightsHolders(
    List<CourseRightsHolder> a,
    List<CourseRightsHolder> b,
  ) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index].type != b[index].type || a[index].name != b[index].name) {
        return false;
      }
    }
    return true;
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

  /// What the Custom license field starts with for a stored [license]:
  /// nothing for a licence of the list, the licence itself when it is the
  /// author's own.
  static String customLicenseTextFor(String license) =>
      CourseMetadataOptions.standardLicenses.contains(license) ? '' : license;

  /// The licence a Course stores for a [choice] of the list: the text typed
  /// in the Custom license field for Other / Custom license (empty when
  /// nothing was typed: the form then says [customLicenseMissing]), else the
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

  /// As [policyOf], for a form that edits a stored Course (Course Info and
  /// the Course Wizard): a licence of the list left as the Course stores it
  /// keeps the Course's policy, also one the licence does not state (a
  /// Course may be "All rights reserved" and still allow derivative works).
  /// A save never changes what the author did not touch.
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
