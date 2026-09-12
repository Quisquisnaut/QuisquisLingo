# Team Manager

Updated for QuisquisLingo 2.0.33, Build 233.1 (technical build 233030).

Team Manager is an offline authoring feature. Open Course Manager and select **Team Manager** to open its separate page. It creates no account, invitation, network, server, email, or online collaboration state.

## Team identity and membership

A Team has a generated stable Team ID, a changeable display name, the stable local profile ID of its creator, a creation timestamp, members, and one or more Team Leaders. Membership and leadership records always use opaque local profile IDs; Screen Names and optional Discord handles are resolved only for presentation. Renaming a Team therefore does not alter any Course assignment.

The profile that creates a Team becomes its first member and Team Leader. The creator identity remains provenance only and gives no permanent administrative privilege. Any Team Leader may add an existing local profile, remove a member, promote a member to Team Leader, or demote a Team Leader to Member. A Team can have multiple Team Leaders. The last remaining Team Leader cannot be removed or demoted; the contextual control tooltip explains why, attempted invalid actions retain appropriate feedback, and the service rejects the same operation independently. An ordinary member cannot administer membership or leadership state.

The active ordinary member has a three-dot menu on their own member row with **Leave Team**. The action requires confirmation; Cancel changes nothing. Confirm removes only that active opaque profile ID from membership and returns to the Team list. It does not delete or rewrite the Team, assigned Courses, learner progress or other members. Team-derived Course edit/Duplicate access disappears automatically because the authorization policy reads current Team membership. Team Leaders do not receive this self-service action; they remain on the promote/demote administration path so a Team can never lose its final Team Leader.

The shared **Internal IDs** preference keeps Team names and learner display names primary. When enabled, Team Manager shows every Team ID plus every Lead/member User ID in the established selectable monospaced, non-clickable style. When disabled, it hides only those IDs and leaves names, roles, permissions and actions unchanged.

Deleting a local profile preserves both authoring invariants. A profile that is the sole Team Leader of any Team must first promote another member. A profile that individually owns a custom Course must first transfer its Course or delete that Course. Otherwise its membership is removed from each Team while the historical Team creator identity remains unchanged.

## Course ownership and Team assignment

A custom Course is always owned by one local individual profile. Its Creator may keep ownership when creating it or select another local individual. Only the current Course Owner may transfer ownership to another individual in Course Editor Edit mode. Creator provenance never changes, and a Team is never an Owner choice.

The current Course Owner may assign a Team to manage the Course and may later revoke that assignment. Assignment requires an explicit warning and confirmation. It changes neither Creator nor Owner. Every current Team member may manage assigned Course content under QQL permissions; Team Leader status is not required for that course-management access. Removing a member or an ordinary member leaving immediately removes those Team-derived rights. A Team cannot self-assign, and a Team Leader cannot assign the Team without the Course Owner's action.

Authorization follows one rule throughout Course Manager, Course Editor, Course Info, Duplicate, Fork, import, and persistence:

`Individual Owner -> ownership transfer, Team assignment and full authoring rights`

`Assigned Team member -> course-content management rights`

`License -> derivative/use rights granted to users outside that ownership boundary`

Author, Contributor, Illustrator, Team Leader, and any custom credit role are descriptive attribution only. They never grant edit, Duplicate, Fork, membership, ownership or Team administration rights. Course ownership grants no Team-governance power, and Team leadership grants no Course-ownership power unless the same user separately holds both roles.

## Duplicate and Fork

Duplicate is available only inside the course-management boundary. A Duplicate preserves the source's individual Owner and optional assigned Team while receiving fresh Course and course-owned content IDs and preserving credits, license and appropriate lineage.

Fork creates a derivative from a course outside the current profile's ownership boundary. It is available only when derivative works are explicitly allowed, leaves the source untouched, receives fresh identities and local individual ownership, and retains the existing source/author/version/provenance record. Duplicate is never used to bypass a no-derivatives license.

## Persistence

Teams use the verified local SharedPreferences registry `quisquislingo_authoring_teams_v1_2291`. Team state is user-management data and is not Course JSON. Course Model v8 stores the custom Course's stable `creatorProfileId`, individual `ownership` reference and optional separate `assignedTeamId`, so both roles survive restart, export, import, Duplicate and Fork. QQL does not infer or migrate ownership or Team assignment for older custom courses.

## Experimental collaboration model

Teams are an experimental QQL collaboration model. A Team is independent of any particular Course and may manage multiple Courses created or owned by different individuals. Team Leaders govern the Team under the rules above; Course Owners govern ownership and Team assignment for their own Courses. QQL permissions determine behavior inside QQL only. They do not by themselves determine copyright ownership, contractual rights or authority in an external organization.
