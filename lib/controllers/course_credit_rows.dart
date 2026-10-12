import 'package:flutter/widgets.dart';

import '../models/course_models.dart';
import '../services/course_credits.dart';

/// One credit row of a Course form: a name, the standard roles chosen and
/// the author's other roles as text.
class CourseCreditRow {
  CourseCreditRow({
    String name = '',
    Set<String>? roles,
    String customRoles = '',
  }) : name = TextEditingController(text: name),
       roles = roles ?? {CourseCredits.defaultRole},
       customRoles = TextEditingController(text: customRoles);

  /// The row that shows a stored credit.
  factory CourseCreditRow.of(CourseAuthor author) => CourseCreditRow(
    name: author.name,
    roles: CourseCredits.standardRolesIn(author.roles),
    customRoles: CourseCredits.customRolesIn(author.roles),
  );

  final TextEditingController name;
  final Set<String> roles;
  final TextEditingController customRoles;

  /// The credit to store, or null while the row has no name.
  CourseAuthor? get value => CourseCredits.author(
    name: name.text,
    standardRoles: roles,
    customRoles: customRoles.text,
  );

  void dispose() {
    name.dispose();
    customRoles.dispose();
  }
}

/// One Rights Holder row of a Course form.
class CourseRightsHolderRow {
  CourseRightsHolderRow({
    this.type = CourseRightsHolderType.person,
    String name = '',
  }) : name = TextEditingController(text: name);

  factory CourseRightsHolderRow.of(CourseRightsHolder holder) =>
      CourseRightsHolderRow(type: holder.type, name: holder.name);

  CourseRightsHolderType type;
  final TextEditingController name;

  /// The Rights Holder to store, or null while the row has no name.
  CourseRightsHolder? get value => CourseCredits.rightsHolder(type, name.text);

  void dispose() => name.dispose();
}
