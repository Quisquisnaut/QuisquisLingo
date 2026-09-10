# Team Manager

Updated for QuisquisLingo 2.0.29, Build 229 revision 3 (technical build 2293).

Team Manager is an offline authoring feature. Open Course Manager and select **Team Manager** to open its separate page. It creates no account, invitation, network, server, email, or online collaboration state.

## Team identity and membership

A Team has a generated stable Team ID, a changeable display name, the stable local profile ID of its creator, a creation timestamp, members, and one or more Team Leads. Membership and Lead records always use opaque local profile IDs; display names are resolved only for presentation. Renaming a Team therefore does not alter any Team-owned Course.

The profile that creates a Team becomes its first member and Team Lead. The creator identity remains provenance only and gives no permanent administrative privilege. A Team Lead may add an existing local profile, remove a member, promote a member to Team Lead, or demote a Lead to Member. A Team can have multiple Leads. The last remaining Lead cannot be removed or demoted; the contextual control tooltip explains why, attempted invalid actions retain appropriate feedback, and the service rejects the same operation independently. The interface does not repeat this as permanent explanatory text. An ordinary member cannot administer membership or Lead state.

The active ordinary member has a three-dot menu on their own member row with **Leave Team**. The action requires confirmation; Cancel changes nothing. Confirm removes only that active opaque profile ID from membership and returns to the Team list. It does not delete or rewrite the Team, Team-owned courses, learner progress or other members. Team-derived Course edit/Duplicate access disappears automatically because the existing authorization policy reads current Team membership. Team Leads do not receive this self-service action; they remain on the promote/demote administration path so a Team can never lose its final Lead.

The shared **Internal IDs** preference keeps Team names and learner display names primary. When enabled, Team Manager shows every Team ID plus every Lead/member User ID in the established selectable monospaced, non-clickable style. When disabled, it hides only those IDs and leaves names, roles, permissions and actions unchanged.

Deleting a local profile also preserves the last-Lead invariant. A profile that is the sole Lead of any Team must first promote another member. Otherwise its membership is removed from each Team while the historical Team creator identity remains unchanged.

## Course ownership

A custom course is owned either by one local profile or by one Team. New Course displays an Owner choice only when the active profile belongs to at least one Team: **Me** plus those eligible Teams. The choice stores the stable Owner ID, never the display name. Course Info resolves the current Team name from the Team registry, so a Team rename changes presentation without changing Course JSON or ownership. There is no automatic transfer of an existing individually owned course.

Every member of an owning Team may edit and Duplicate its course. Team Lead status is not required for ordinary course authoring. Removing a member or an ordinary member leaving immediately removes these Team-derived rights. The course remains Team-owned if its original Creator later leaves the Team, loses Lead status, or changes display name.

Authorization follows one rule throughout Course Manager, Course Editor, Course Info, Duplicate, Fork, import, and persistence:

`Owner / owning Team -> full authoring rights`

`License -> derivative/use rights granted to users outside that ownership boundary`

Author, Contributor, Illustrator, Team Leader, and any custom credit role are descriptive attribution only. They never grant edit, Duplicate, Fork, membership, or Team administration rights.

## Duplicate and Fork

Duplicate is available only inside the ownership boundary. An individual Owner's Duplicate remains individually owned by that profile; a Team member's Duplicate of a Team-owned course remains owned by the same Team. It receives fresh Course and course-owned content IDs while preserving credits, license, and appropriate lineage.

Fork creates a derivative from a course outside the current profile's ownership boundary. It is available only when derivative works are explicitly allowed, leaves the source untouched, receives fresh identities and local individual ownership, and retains the existing source/author/version/provenance record. Duplicate is never used to bypass a no-derivatives license.

## Persistence

Teams use the verified local SharedPreferences registry `quisquislingo_authoring_teams_v1_2291`. Team state is user-management data and is not Course JSON. Course Model v7 stores only the custom course's stable `creatorProfileId` and `ownership` reference so ownership survives restart, export, import, Duplicate, and Fork. QQL does not infer or migrate ownership for older custom courses.
