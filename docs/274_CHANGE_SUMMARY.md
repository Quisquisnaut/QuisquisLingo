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

## Revision 2 (2.0.74+274002): playback on request

### Before

- Only Pick the translation let a learner hear a sentence on request: a
  speaker beside a target-language question, and "Listen to the answer"
  after answering when the answers are in the target language.
- Build the translation and Type the translation showed no speaker, in
  either direction.
- Select the image's words under named icons and the words of Match pictures
  to words could not be heard.

### Now

- Build the translation and Type the translation behave as Pick the
  translation:
  - into the source language: a speaker beside the target-language sentence
    to translate;
  - into the target language: "Listen to the answer" under the feedback once
    answered, speaking the first answer the exercise accepts (Type the
    translation: a verbatim answer first, else the first answer an answer
    expression accepts, optional words left out; Build the translation: its
    first correct order), even when the correct answer line shows another
    accepted answer, the one closest to what was typed.
  - With the learner's audio off the speaker is greyed, with Pick the
    translation's note.
  - An Instruction or context is never offered as the sentence to hear.
- Select the image: an option that shows a word (a named icon) has a small
  speaker on its corner; a picture option shows no word and has none.
- Match pictures to words: each word in a row's menu has a small speaker;
  the closed field shows the chosen word as before.
- Only the picture grid of a single-answer Select the image has speakers
  (several answers, or answers that fill gaps, are drawn otherwise), and a
  listening exercise never says its answers.
- The mascot beside a sentence keeps room for its speaker.
- A word that states no language counts as the target language (owner
  decision of 15 October 2026); a word marked as the source language has no
  speaker. The small speakers are shown only while the learner's audio is
  on, and a tap plays the word without answering.
- The Audio Library's Texts in this Course and Used in N exercises count
  every text a learner can now hear on request, so a recording session
  knows them.
- Help in English, Italian and Spanish (the six presets' Help, Which texts
  still need a recording?).

### Known and left

As for Pick the translation: in a Course with its own recordings, a speaker
whose text no recording covers (and, in a Course that mixes recordings and
the device's voice, with Text-to-speech off) says it cannot play. The Audio
Library's Texts in this Course now lists these texts, so the author can
record them.

### What does not change

Nothing plays by itself. Course files, what authors write, the Duel,
grading, scoring, progression and learner data.

## Revision 3 (2.0.74+274003): Listen and pick the missing word

### Before

- No Listening exercise asked the learner to choose among sounds.
- A sound was always found by its text, so a recording without a text could
  not be an answer.

### Now

- A new preset, **Listen and pick the missing word**: the whole sentence is
  spoken by itself and shown with one ___ gap; the answers are sounds; a
  tap plays an answer and chooses it, Check grades. Before answering an
  answer shows only its place ("Sound 2"); once answered, its text, with
  the right answer and a wrong choice marked.
- An answer is a word, spoken as any text, or (in a Course whose audio
  source is Recorded MP3 only or Hybrid) a recording of the Audio Library,
  which needs no text. Each answer may have its own text shown once
  answered; else it shows its word, else its recording's text.
- On-Device TTS plays no recordings, chosen ones included: such an answer
  has no sound, the Audit shows an Error and the exercise is skipped.
  Switching the audio source to On-Device TTS while answers play
  recordings asks first.
- Deleting a recording that answers play asks first, naming the exercises.
- The Audit has five new rules (four Errors, one Info), and checks the
  preset's spoken sentence and gap (Warnings).
- It fits a Listen Round; in a Test Round it marks nothing before the
  results page.
- A single-answer Select graded on Check is now playable; picture answers
  keep their grid (a tap chooses, Check grades).
- The form counts the answers as it numbers them, so a blank row never
  makes another the correct one.
- Help in English, Italian and Spanish; the learner's title and line in
  seven languages; a Laboratory example.

### Owner decisions (16 October 2026)

- An answer names its recording by its Audio Library id, not its file.
- Delete asks first; On-Device TTS plays no chosen recordings; the switch
  to it warns first (it lives in the Audio Library's audio source menu).

### What does not change

Every other exercise, Course file and learner data; scoring and
progression.

## Revision 4 (2.0.74+274004): Image Library search order and Strict search

### Before

- A search found every picture whose name, tag, Local word, ID or category
  contained the letters typed, in the order of the chosen sort: "man"
  mixed Man with Woman, Businesswoman and the rest.

### Now

- The best matches come first: the name is the term; then the term is a
  whole word of the name; then a whole word of a tag or a Local word, or
  the whole name of the picture's category or group; then it is only
  inside a longer word. The chosen sort orders
  each part. The pictures found are the same as before.
- Strict search, above Search all and off by default, keeps the whole
  words only: "man" no longer finds Woman.

### What does not change

The picture records, their categories and tags, Courses, Image Banks and
learner data.
