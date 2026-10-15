# Build 273 change summary

Build 273 is the second half of the modularization plan
(`docs/272_MODULARIZATION_PLAN.md`): the owners the plan rated medium risk,
which the owner moved out of Build 272 on 12 October 2026. The rule is
Build 272's: no file is split unless the responsibility first gets an owner
of its own that can be tested without the screen; one owner per revision;
**nothing an author or a learner sees changes** unless the owner decides a
change, which is then a revision of its own.

## Revision 0 (2.0.73+273000): the Story cast owner

### Before

Who speaks in a Course's Stories (the narrator and the reusable characters)
is edited in two places: the Course Editor's **Story characters** section
and the **New Story** wizard. The rules about the cast lived inside the
Course Editor file:

- the line under a speaker's name ("Target language · voice female"),
  written once in each screen;
- how the narrator, the characters and an avatar's picture credit are
  written into the Course, a helper at the end of the file that both
  screens called;
- how many Dialogue lines still name a character, and the message that
  refuses to remove it (Course Editor only);
- the list of characters with one replaced or one removed, written inline
  (Course Editor only).

### Now

- `StoryCast` (`lib/services/story_cast.dart`, pure Dart, no screen and no
  storage) is the one owner:
  - `describe(speaker)`: the line under a speaker's name;
  - `summaryOf(course)`: the Story characters tile ("Narrator: Teller · 1
    character", "Unnamed narrator · 2 characters");
  - `linesSpokenBy(course, speakerId)`: the exercises of every Lesson and
    Round whose prompt names the speaker;
  - `stillSpeaksMessage(lines)`: why a character still speaking cannot be
    removed (no line is ever handed to the narrator silently);
  - `replacing(characters, speaker)` and `without(characters, speakerId)`;
  - `withSpeakers(course, narrator:, characters:, credits:)`: the narrator
    is stored only when the Course already has one or the new one differs
    from the Course's narrator, so saving the default narrator unchanged
    changes nothing (the rule the owner chose in Build 270); characters in
    their order, none leaves no entry; each credit once, after the
    Course's own; everything else of the Course kept.
- The Course Editor's Story characters, the Story Wizard and the Rounds
  page (which receives the Wizard's new Story) call it. The Course Editor
  file is at 7,848 lines (7,927).
- Left as they are, on purpose: `Course.narrator` and `Course.speakerOf`
  stay in the Course model (the Round screen and the Audit read them); the
  Story Wizard shows "Unknown character" for a line whose speaker it does
  not know while the Round screen lets the narrator say it. They are two
  presentations, not one rule, and nothing changes for learners.

### What does not change

The screens, their keys and their texts; Course files; scoring,
progression and learner data. No new key or folder.
