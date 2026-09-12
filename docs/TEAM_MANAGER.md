# Team Manager

Updated for QuisquisLingo 2.0.33, Build 233.1 (technical build 233030).

Team Manager is an offline authoring feature. Open Course Manager and select **Team Manager** to open its separate page. It creates no account, invitation, network, server, email, or online collaboration state.

## Team identity and membership

A Team has a generated stable Team ID, a changeable display name, the stable local profile ID of its creator, a creation timestamp, members, and one or more Team Leaders. Membership and leadership records always use opaque local profile IDs; Screen Names and optional Discord handles are resolved only for presentation. Renaming a Team therefore does not alter any Course assignment.

The profile that creates a Team becomes its first member and Team Leader. The creator identity remains provenance only and gives no permanent administrative privilege. Any Team Leader may add an existing local profile, remove a member, promote a member to Team Leader, or demote a Team Leader to Member. A Team can have multiple Team Leaders. The last remaining Team Leader cannot be removed or demoted; the contextual control tooltip explains why, attempted invalid actions retain appropriate feedback, and the service rejects the same operation independently. An ordinary member cannot administer membership or leadership state.

The active ordinary member has a three-dot menu on their own member row with **Leave Team**. The action requires confirmation; Cancel changes nothing. Confirm removes only that active opaque profile ID from membership and returns to the Team list. It does not delete or rewrite the Team, assigned Courses, learner progress or other members. Team-derived Course Edit/Copy as New Course access disappears automatically because the authorization policy reads current Team membership. Team Leaders do not receive this self-service action; they remain on the promote/demote administration path so a Team can never lose its final Team Leader.

The shared **Internal IDs** preference keeps Team names and learner display names primary. When enabled, Team Manager shows every Team ID plus every Lead/member User ID in the established selectable monospaced, non-clickable style. When disabled, it hides only those IDs and leaves names, roles, permissions and actions unchanged.

Deleting a local profile preserves both authoring invariants. A profile that is the sole Team Leader of any Team must first promote another member. A profile that maintains a custom Course must first transfer its maintenance role or delete that Course. Otherwise its membership is removed from each Team while the historical Team creator identity remains unchanged.

## Course maintenance and Team assignment

A custom Course always has one individual Course Maintainer. On New Course, the Original Course Creator may remain Maintainer or select another local individual. Only the current Maintainer may transfer maintenance to another individual in Course Editor Edit mode. Original Course Creator/Created provenance never changes through a maintenance transfer, and a Team is never a Maintainer choice.

The current Course Maintainer may assign a Team to manage the Course and may later revoke that assignment. Assignment requires an explicit warning and confirmation. It changes neither Original Course Creator nor Course Maintainer. Every current Team member may manage assigned Course content under QQL permissions; Team Leader status is not required for that course-management access. Removing a member or an ordinary member leaving immediately removes those Team-derived rights. A Team cannot self-assign, and a Team Leader cannot assign the Team without the Maintainer's action.

Authorization follows one rule throughout Course Manager, Course Editor, Course Info, Copy as New Course, Fork, import and persistence:

`Individual Maintainer -> maintenance transfer, Team assignment and full authoring rights`

`Assigned Team member -> course-content management rights`

`License -> derivative/use rights granted to users outside that operational boundary`

Author, Contributor, Illustrator, Team Leader and any custom credit role are descriptive attribution only. Original Course Creator and Fork Created By are provenance only. Rights Holder and License are legal/distribution metadata. None grants Edit, Copy as New Course, Fork, membership, maintenance or Team-administration rights by being named. Course maintenance grants no Team-governance power, and Team leadership grants no Course-maintenance power unless the same user separately holds both roles.

## Copy as New Course and Fork

Copy as New Course is available only inside the Course-management boundary. It receives fresh Course/content IDs and starts an independent lineage: the active user becomes Original Course Creator, Maintainer and Last Version Editor; Original Course Created/Modified initialize for the new Course; Assigned Team and fork metadata are absent. It copies content, structured attribution, Rights Holder and applicable License without treating the operation as a transfer of legal rights.

Fork creates a derivative from a Course outside the current profile's management boundary. It is available only when derivative works are explicitly allowed, leaves the source untouched, receives fresh identities and the active user as Maintainer, inherits Original Course Creator/Created, structured attribution, Rights Holder and applicable License, and records its immediate source plus Fork Created By/Date. Copy as New Course is never used to bypass a no-derivatives License.

## Persistence

Teams use the verified local SharedPreferences registry `quisquislingo_authoring_teams_v1_2291`. Team state is user-management data and is not Course JSON. Course Model v9 stores immutable `originalCourseCreator`/`originalCreatedAtUtc`, the individual `maintainer`, optional separate `assignedTeamId`, and fork provenance only where applicable. Active v9 Course persistence does not read or migrate v8 data; v8 namespaces remain physically untouched.

## Experimental collaboration model

Teams are an experimental QQL collaboration model. A Team is independent of any particular Course and may manage multiple Courses with different Original Course Creators and Maintainers. Team Leaders govern the Team under the rules above; Course Maintainers govern maintenance transfer and Team assignment for their Courses. QQL permissions determine behavior inside QQL only. They do not by themselves determine copyright ownership, contractual rights or authority in an external organization.
