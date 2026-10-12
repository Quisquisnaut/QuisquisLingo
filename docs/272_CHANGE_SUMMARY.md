# Build 272 change summary

Build 272 is the modularization build (plan
`docs/272_MODULARIZATION_PLAN.md`, the read-only audit of 10 October 2026).
Owner rule: no file is split unless the responsibility first gets an owner
of its own that can be tested without the screen. One owner per revision.
**Nothing an author or a learner sees changes**: every revision first
writes tests on the code as it is, and they must still pass afterwards.

## Revision 0 (2.0.72+272000): the credits and licence owner

### Before

Three screens let an author enter who made a Course and what others may do
with it: the Course Info Editor, New Course's form and the Course Wizard.
Each had its own copy of the same rules:

- which roles a credit gets (three copies);
- how stored roles are shown again as chips and a text field (two copies);
- which entry of the licence list shows a stored licence (two copies);
- which licence and which derivative-works policy are stored for a choice
  (three copies);
- which Rights Holder rows are stored (three copies).

The text "Other / Custom license" was written in nine places and compared
letter by letter.

### Now

- `CourseCredits` (`lib/services/course_credits.dart`, pure Dart, no screen
  and no storage) is the one owner:
  - `rolesOf(standard, custom)`: the standard roles in their standard
    order, then the author's own roles from the text field (separated by
    commas, each once, as typed), `Contributor` when there is none;
  - `standardRolesIn(roles)` and `customRolesIn(roles)`: a stored credit
    split into the chips shown selected and the text of the other roles;
  - `author(...)` and `rightsHolder(...)`: one row of a form, or nothing for
    a row without a name; names are trimmed;
  - `licenseChoiceFor(license)`: the entry of the list for a stored
    licence;
  - `licenseOf(choice, customText)`: the licence stored for a choice;
  - `policyOf(choice, chosen)`: the policy stored with a choice (the
    author's own for a custom licence, the licence's otherwise);
  - `policyKeepingStored(...)`: the same for a form that edits a stored
    Course (see difference 2 below);
  - `policyAfterChoosing(choice, current)`: the policy a form shows after a
    choice.
- `CourseMetadataOptions.customLicense` is the one place of the text
  "Other / Custom license".
- The Course Info Editor, New Course's form, `CourseLibraryOperations`
  (which builds New Course's Course) and the Course Wizard call the owner.
  `CourseLibraryOperations._rolesOf` and the Wizard's own constant are gone.

### Differences between the three screens, kept as they are

(Kept in Revision 0 only. The owner decided the same day that they must
become the same: Revision 1, below.)

While reading the three copies four differences came out. This revision
keeps each of them (a test pins each one), because changing them is the
owner's decision, not a side effect of tidying:

1. **Choosing Other / Custom license.** New Course then shows "Derivative
   works: Not specified". Course Info and the Course Wizard keep the policy
   shown before the choice (for example "Forbidden" after "All rights
   reserved").
2. **A licence left unchanged.** Course Info keeps the policy the Course
   stores, also one the licence does not state: a Course that is "All
   rights reserved" and allows derivative works (as QQL Demo: Italian
   Exercise Lab, and any Fork of it) stays so. The Course Wizard always stores the licence's own
   policy. In practice a Course made by the Wizard never has such a pair, so
   nobody should have met this.
3. **The Custom license field.** Course Info fills it with the stored
   licence also when that is one of the list (so switching to Other / Custom
   license starts from "CC BY 4.0"); the Course Wizard leaves it empty then.
4. **A credit row that is added.** It starts as Contributor in Course Info
   and in New Course, and as Author in the Course Wizard.

A fifth point, the same in all three: a role of the author's own that
contains a comma is split into two roles the next time the credit is saved,
because the text field separates roles with commas.

### Tests

`test/course_credits_272_test.dart`: 5 cases for the owner and 6 cases that
drive the three screens (Course Info 3, New Course 2, Course Wizard 1). The
6 screen cases were written and run on the code **before** the change and
passed there.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 1 (2.0.72+272001): the three screens follow the same rules

Owner decision of 12 October 2026 on the differences Revision 0 found:
"They must become the same", then "Agree on all five, own revision".

| # | The rule, now the same in Course Info, New Course and the Course Wizard | What changed |
|---|---|---|
| 1 | Choosing Other / Custom license keeps the derivative-works policy shown before the choice | New Course: it showed "Not specified" |
| 2 | A licence left unchanged keeps the policy the Course stores | Course Wizard: it stored the licence's own policy on every save of its step |
| 3 | The Custom license field starts empty for a licence of the list, and with the stored text when the licence is the author's own | Course Info: it started from the stored licence, for example "CC BY 4.0" |
| 4 | The creator's own credit row is Author; a person added afterwards starts as Contributor | Course Wizard: every added person was an Author |
| 5 | Other / Custom license without a text says "Type the custom license, or choose a license from the list." | Course Info and New Course: the button did nothing, without a word |

### What an author may notice

- **New Course**: after "CC BY-SA 4.0", choosing Other / Custom license
  shows "Allowed" (before: "Not specified"). Starting from the default "All
  rights reserved" it shows "Forbidden". The author can still choose any of
  the three.
- **Course Wizard**: a person added with **Add a person** is credited as
  Contributor unless another role is chosen under Advanced. The first row,
  which the Wizard fills with the creator's name, is still Author.
- **Course Wizard**: saving the About step no longer changes the policy of
  a Course whose licence was not touched.
- **Course Info**: switching to Other / Custom license starts from an empty
  field. A licence the author wrote earlier is still shown there.
- **Course Info and New Course**: with Other / Custom license and no text,
  Apply and Continue to Editor say what is missing.

Stored Courses are not converted: credits and policies already stored stay
as they are. No screen layout changes.

### How

- `CourseCredits` gains `customLicenseTextFor(license)`,
  `customLicenseMissing` (the one text of the refusal) and `creatorRole`.
- New Course's licence list calls `policyAfterChoosing`.
- The Course Wizard stores `policyKeepingStored` against its working copy
  (`_derivativeValue`); the line under the licence list ("Derivative works
  are allowed…") reads the same value. `_CreditRow` starts as
  `CourseCredits.defaultRole`; Add a person gives the creator's row
  `creatorRole`.
- Course Info's Custom license field starts from `customLicenseTextFor`;
  its Apply and New Course's Continue to Editor show
  `customLicenseMissing`.

### Tests

`test/course_credits_272_test.dart`, 12 cases: the screen cases that pinned
a difference in Revision 0 now pin the one rule (points 1 to 5), and one
more owner case covers the new owner members.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.
