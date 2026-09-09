# Team Manager

Updated for QuisquisLingo 2.0.29, Phase 229 revision 1 (technical build 2291).

Team Manager is an offline authoring feature. Open Course Manager and select **Team Manager** to open its separate page. It creates no account, invitation, network, server, email, or online collaboration state.

## Team identity and membership

A Team has a generated stable Team ID, a changeable display name, the stable local profile ID of its creator, a creation timestamp, members, and one or more Team Leads. Membership and Lead records always use opaque local profile IDs; display names are resolved only for presentation. Renaming a Team therefore does not alter any Team-owned Course.

The profile that creates a Team becomes its first member and Team Lead. The creator identity remains provenance only and gives no permanent administrative privilege. A Team Lead may add an existing local profile, remove a member, promote a member to Team Lead, or demote a Lead to Member. A Team can have multiple Leads. The last remaining Lead cannot be removed or demoted; the UI disables that action with an explanation and the service rejects the same operation independently. An ordinary member cannot administer membership or Lead state.

Deleting a local profile also preserves the last-Lead invariant. A profile that is the sole Lead of any Team must first promote another member. Otherwise its membership is removed from each Team while the historical Team creator identity remains unchanged.

## Course ownership

A custom course is owned either by one local profile or by one Team. New Course displays an Owner choice only when the active profile belongs to at least one Team: **Me** plus those eligible Teams. The choice stores the stable Owner ID, never the display name. There is no automatic transfer of an existing individually owned course.

Every member of an owning Team may edit and Duplicate its course. Team Lead status is not required for ordinary course authoring. Removing a member immediately removes these Team-derived rights. The course remains Team-owned if its original Creator later leaves the Team, loses Lead status, or changes display name.

Authorization follows one rule throughout Course Manager, Course Editor, Course Info, Duplicate, Fork, import, and persistence:

`Owner / owning Team -> full authoring rights`

`License -> derivative/use rights granted to users outside that ownership boundary`

Author, Contributor, Illustrator, Team Leader, and any custom credit role are descriptive attribution only. They never grant edit, Duplicate, Fork, membership, or Team administration rights.

## Duplicate and Fork

Duplicate is available only inside the ownership boundary. An individual Owner's Duplicate remains individually owned by that profile; a Team member's Duplicate of a Team-owned course remains owned by the same Team. It receives fresh Course and course-owned content IDs while preserving credits, license, and appropriate lineage.

Fork creates a derivative from a course outside the current profile's ownership boundary. It is available only when derivative works are explicitly allowed, leaves the source untouched, receives fresh identities and local individual ownership, and retains the existing source/author/version/provenance record. Duplicate is never used to bypass a no-derivatives license.

## Persistence

Teams use the verified local SharedPreferences registry `quisquislingo_authoring_teams_v1_2291`. Team state is user-management data and is not Course JSON. Course Model v7 stores only the custom course's stable `creatorProfileId` and `ownership` reference so ownership survives restart, export, import, Duplicate, and Fork. QQL does not infer or migrate ownership for older custom courses.
