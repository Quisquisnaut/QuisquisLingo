# Build 274 change summary

Small improvements to the Course Editor, the Audit, playback on request, one
new Listening preset and the Image Library, from the owner's nine points of
13 October 2026 (`docs/274_PLAN.md`). The plan's Revision 1 (two
recommendations that stop being Warnings) was delivered early, as Build 272
Revision 16.

## Revision 0 (2.0.74+274000): the Course Editor's top bar and breadcrumbs

### Before

- The Rounds page's top bar named the Lesson in full ("Rounds · Lesson 2:
  Greetings", "Lesson 2" small and grey), right above the breadcrumb that
  named it again.
- In the breadcrumbs only one crumb was a link: the one just above the page
  (the Exercise editor's Round; the Round editor's Lesson, which went back
  to the Rounds list). The exercise's crumb read "Exercise".

### Now

- The Rounds page's top bar names the Lesson once, in the title's type:
  "Rounds · Lesson 2"; a custom label as written ("Rounds · Unit 2"); with
  Lesson numbering Off or Number only, the Lesson's title ("Rounds ·
  Greetings"). The breadcrumb below still names it whole.
- The breadcrumbs (owner decision of 15 October 2026) have a Rounds crumb
  between the Lesson and the Round, also on the Rounds page itself as its
  last crumb: "Course > Lesson 2: Greetings > Rounds > Round 3 > Exercise 4".
- The exercise's crumb is "Exercise 4": its place in its Round, the number
  the Round editor's list shows; "New Exercise" before it is added.
- Every crumb whose page is open above is a link: Course opens the Course
  Editor's main page, Lesson the Lesson's page, Rounds the Rounds list,
  Round the Round editor.
- A jump goes back one page at a time, each through its own Back: an
  exercise with unsaved changes asks first, Keep editing stays where you are
  and ends the jump, Discard changes or Apply go on. Nothing is applied or
  discarded differently from pressing Back that many times.
- A page opened outside the chain (a search result, the Audit, a wizard)
  links only to the pages it really came through, as before: an exercise
  opened from a Round editor that itself came from the Audit links to that
  Round only. The canonical editor opened from a new exercise's form has the
  same links, and a jump from it goes on through the form. The Lessons list
  keeps its one crumb (Course) as plain text.
- The canonical editor goes back once: its Back did not check that the page
  was already leaving, so a crumb tapped while Apply closes the page, or
  Back pressed twice, could close a second page (found by the independent
  review).
- Help in English, Italian and Spanish (How do I move between exercises?).

### What does not change

Back, the working copy and when it is saved, Course files, learner data,
scoring and progression.
