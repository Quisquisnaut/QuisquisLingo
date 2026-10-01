# Build 261 change summary

Owner requests 1–6 of 1 October 2026, discussed with questions the same
evening. Three revisions: 0 learner polish, 1 Study and Review from
Courses and the Course Editor's opening mode, 2 the Course preview from the
Course Editor.

## Revision 0 (2.0.61+261000, 2 October 2026): learner polish

**Round names on one line.** In the learner path a Round card showed
"Round 2" in bold on its own line and the title in bold below it. Now the
name is one line (`_RoundNode._title` in `lib/screens/home_screen.dart`,
key `unified-round-title-<id>`): "Round 2: " in normal weight before the
title in bold, in a slightly smaller type (15 instead of 16 points, line
height 1.4), wrapping up to three lines, so that with the status line it
still fits the card's 88 pixels. A Story shows "Story: " and its title the
same way, a sequence "Sequence: " (the label `LearningRound.displayTitle`
derives); a Round without a title of its own shows "Round 2" alone, in
bold. "Round", "Story" and "Sequence" stay English (owner decision: not
translated with the learner panel's buttons).

**Tooltips.** The Round name and the Lesson title (`identity.fullText`,
key `unified-guidebook-lesson-tooltip-<id>`) show their whole text as a
tooltip on hover or long press, for when three lines cut them. The
tooltips are left out of the semantics tree, which already reads the text.

**Confetti for the weekly goal.** When a Round's completion reaches the
Weekly XP Target, the "Weekly goal reached!" dialog now has a short burst
of confetti over it (`ConfettiBurst`, `lib/widgets/confetti_burst.dart`):
about two seconds, 90 pieces fired from the two lower corners, falling and
fading, drawn by its own painter (no new package), never taking a tap and
hidden from screen readers. It shows only when `ConfettiBurst.allowed`:
Animations on in Do Not Disturb (whose subtitle now names it) and no
reduced motion asked by the system. Only the weekly goal celebrates this
way (owner decision: not a first Laurel, a Duel or a Lesson). Help
EN/IT/ES say so in the progress paragraph.

Scoring, progression, Course files and learner data are unchanged.
