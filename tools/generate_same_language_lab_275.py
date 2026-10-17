#!/usr/bin/env python3
"""Generate QQL Test: En-En Exercise Lab, a Course in the same language.

Build 275 Revision 5 (docs/SAME_LANGUAGE_COURSES_PLAN.md): English explained
in English, one exercise for each preset a Course in the same language
offers (the three "to source" twins of Choose the answer, Listen and choose
and Listen and answer are not offered there), one Lesson for each group of
presets, a GuideBook module of words and their meanings in every Lesson.

It is a custom Course to import, like the En-It Exercise Lab, written to
test_courses/exercise_lab_en_en.json; no Course comes with the app. The
examples are authored with the Exercise Laboratory's builder (its v11
shapes pass through tools/qql_course_v12.py), so they are shaped exactly as
the presets' forms shape them. Written by AI and not reviewed, as App Info
says of the test Courses. --check verifies the committed file.
"""
from __future__ import annotations

import argparse
import copy
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_exercise_laboratory_254 import (  # noqa: E402
    Laboratory, audio, glyph_asset, image, lab_guidebook, text, turn)
from qql_course_v12 import convert_course_v11_to_v12  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "test_courses/exercise_lab_en_en.json"
# Allocated once (UUIDv4); regeneration keeps the identity.
COURSE_ID = "course_007bf835-bda7-404a-848e-2753875953dd"
# The made-up QQL-user Maintainer of the other test Courses.
MAINTAINER = "afb065f8-701c-48d2-85f7-c80d44abecb9"
PREFIX = "qql_enen275_"
STAMP = "2026-10-17T00:00:00.000Z"
TITLE = "QQL Test: En-En Exercise Lab"
# Build 275 Revision 2: the stored kind needs this build.
MINIMUM_APP_BUILD = 275002

# Every Lesson's GuideBook module: a word, then its meaning, in English.
VOCABULARY: dict[str, list[str]] = {
    "Vocabulary": [
        "espresso = a small, strong coffee",
        "thirsty = wanting something to drink",
        "a mug = a big cup with a handle",
        "glad = happy",
        "quick = fast",
        "the counter = the long, flat surface where you order and pay",
    ],
    "Grammar": [
        "to sleep = to rest with your eyes closed",
        "a kitten = a young cat",
        "to order = to ask for food or a drink",
        "to pay = to give money for something",
        "a sofa = a long, soft seat for two or more people",
    ],
    "Listening": [
        "good morning = hello, said before midday",
        "the market = a place where people buy food from stalls",
        "a loaf = bread baked in one piece",
        "the bill = the paper that says what you must pay",
        "a cat = a small pet that says meow",
    ],
    "Reading": [
        "a neighbour = a person who lives next to you",
        "a cake = something sweet that is baked",
        "without = not having",
        "bitter = with a strong taste, not sweet",
    ],
    "Pictures": [
        "an apple = a round fruit, red or green",
        "bread = a food made from flour and baked",
        "a dog = a pet that barks",
        "a house = a building where people live",
    ],
    "Cards": [
        "a café = a place where you buy coffee and small meals",
        "a barista = a person who makes coffee in a café",
        "a sip = a very small mouthful of a drink",
        "a tip = money you give for good service",
    ],
}

MODULE_TITLES = {
    "Vocabulary": "Words and meanings",
    "Grammar": "Words for the sentences",
    "Listening": "What you hear",
    "Reading": "Situations and dialogues",
    "Pictures": "Pictures and letters",
    "Cards": "At the café",
}


def lab() -> Laboratory:
    lab = Laboratory(prefix=PREFIX, stamp=STAMP, vocabulary=VOCABULARY)

    lab.start_lesson("Vocabulary", "Words and their meanings, in English. In a Course in the same language there are no translations: Pick the word gives a meaning and asks for the word, Pick the meaning does the opposite; Type and Build work the same way.")
    lab.start_round("vocabulary_words", "Words and meanings", "Each exercise gives a word or its meaning; pick, type or build the other side. QQL writes the instruction line.")
    lab.choose("pick_word", "translation_choice_to_target", [text("a small, strong coffee", "question")], ["espresso", "cappuccino", "tea"], 0, "Pick the word; a meaning and three words")
    lab.choose("pick_meaning", "translation_choice_to_source", [text("thirsty", "question")], ["wanting something to drink", "wanting something to eat", "wanting to sleep"], 0, "Pick the meaning; a word and three meanings")
    lab.enter("type_word", "type_translation", [text("a big cup with a handle")], ["mug", "a mug"], "Type the word; a meaning and two accepted answers")
    lab.enter("type_meaning", "type_translation_to_source", [text("quick", language="target")], ["fast", "rapid", "speedy", "swift"], "Type the meaning; a word and four accepted synonyms")
    lab.arrange("build_sentence", "build_translation", [text("I want a small, strong coffee, please.")], ["I", "would", "like", "an", "espresso", "a"], [[0, 1, 2, 3, 4]], "Build the sentence; a meaning, word blocks and one extra block")
    lab.arrange("build_meaning", "build_translation_to_source", [text("I am thirsty.", language="target")], ["I", "want", "something", "to", "drink", "eat"], [[0, 1, 2, 3, 4]], "Build the meaning; a sentence, meaning blocks and one extra block", language="source")
    lab.match("match_words", "word_match", "Match each meaning with its word.", [("a small, strong coffee", "espresso"), ("wanting something to drink", "thirsty"), ("a big cup with a handle", "mug")], "Match words and meanings; three meaning = word pairs")
    lab.match("match_synonyms", "super_match", "Match each word with a word that means the same.", [("glad", "happy"), ("quick", "fast"), ("big", "large")], "Match by meaning; three pairs of synonyms")
    lab.start_round("vocabulary_cards", "Flashcards", "Read each card, turn it over, then choose Got it or Review again.")
    lab.card("card_word", "the counter", "the long, flat surface where you order and pay", "Flashcard; word, meaning, a usage sentence and its read-aloud", usage="Pay at the counter.", spoken="the counter")
    lab.card("card_picture", "an apple", "a round fruit, red or green", "Picture flashcard; picture, word and meaning", preset="picture_flashcard", picture="apple")

    lab.start_lesson("Grammar", "Sentences and their parts: choose, complete, put in order and sort. The answers are in English, like the questions.")
    lab.start_round("grammar_choose", "Choose and complete", "Choose the answer, or the word that completes the sentence. One word fills all puts one word in every gap.")
    lab.choose("choose_answer", "choice_target", [text("Which sentence is correct?", "question")], ["She drinks coffee.", "She drink coffee.", "She drinking coffee."], 0, "Choose the answer; a grammar question")
    lab.choose("pick_missing", "gap_choice", [text("The cat ___ on the sofa.", "question")], ["sleeps", "sleep", "sleeping"], 0, "Pick the missing word; one ___ gap and a hint", hint="The subject is one animal.")
    lab.enter("type_missing", "type_missing_word", [text("The ___ says meow.")], ["cat"], "Type the missing word; the first letter is shown", hint="A small pet.")
    lab.choose("one_word_all", "one_word_fills_all", [text("___ cat sleeps. ___ dog eats.", "question")], ["The", "An", "Two"], 0, "One word fills all; one article for two gaps")
    lab.choose("true_false", "true_false", [text("An espresso is a large cup of tea.", "question")], ["True", "False"], 1, "True or false; a false statement", language="source")
    lab.start_round("grammar_order", "Words and lines in order", "Build the sentence from its blocks, fill the gaps, or put the lines of a short story in order.")
    lab.arrange("word_order", "word_order", [text("Put the words in order.", "clue")], ["The", "cat", "is", "asleep.", "are"], [[0, 1, 2, 3]], "Word order; one extra block")
    lab.gaps("gap_blocks", "gap_blocks", "Complete the sentence.", ["Anna", ("drinks",), ("coffee",), "every morning."], ["eats"], "Pick the words for the gaps; two gaps and one extra word")
    lab.arrange("sentence_order", "sentence_order", [text("Anna stops at a café for a coffee.", "clue")], ["Anna walks into the café.", "She orders an espresso.", "She pays and says goodbye."], [[0, 1, 2]], "Put the sentences in order; three lines under an instruction that sets the scene")
    lab.start_round("grammar_typed", "Typed gaps", "Type the missing words of the text, or the missing letters inside the words.")
    lab.enter("complete_text", "complete_text", [text("Anna's morning before work.", "clue"), text("Anna drinks a coffee at the café. Then she takes the train.")], [], "Complete the text; two typed gaps, an instruction and a hint", hint="What an espresso is; then a way to travel by rail between towns.", missing=["coffee", "train"], answer="coffee / train")
    lab.enter("missing_letters", "missing_letters", [text("The kitten sleeps on the sofa.")], [], "Missing letters; letters inside two words", missing=["tt", "of"], answer="tt / of")
    lab.start_round("grammar_assign", "Groups and slots", "Tap a word, then the group or the slot that takes it; Check grades every destination at once.")
    lab.assign("sort_groups", "sort_into_groups", "categories", "Sort the words: drinks or food?",
               [("coffee", "coffee"), ("tea", "tea"), ("bread", "bread"), ("apple", "apple")],
               [("drinks", "Drinks"), ("food", "Food")],
               {"drinks": ["coffee", "tea"], "food": ["bread", "apple"]},
               "Sort into groups; two groups of two words", "Drinks: coffee, tea; Food: bread, apple",
               capacity="unlimited")
    lab.assign("fill_slots", "fill_the_slots", "slots", "Which article goes with each noun?",
               [("a", "a"), ("an", "an")], [("s1", "… cat"), ("s2", "… apple")],
               {"s1": ["a"], "s2": ["an"]},
               "Fill the slots; one word for each slot", "… cat: a; … apple: an")

    lab.start_lesson("Listening", "Listen, then choose, type, match or spell. Enable Audio Exercises and Text-to-speech in Audio Settings to practise these exercises; the Preview plays them anyway.")
    lab.start_round("listening_choose", "Listen and choose", "Play the sound as often as you like, then answer.", "listening")
    lab.choose("listen_choose", "listening_choose_target", [audio("Good morning."), text("Choose the greeting you hear.")], ["Good morning.", "Good evening.", "Good night."], 0, "Listen and choose; an instruction and written answers")
    lab.choose("listen_answer", "listening_comprehension", [audio("Maria buys two apples and a loaf of bread at the market.", "passage"), text("Where does Maria do her shopping?", "question")], ["At the market.", "At school.", "At the station."], 0, "Listen and answer; a passage and a question")
    lab.choose("listen_image", "listening_image_choice", [audio("the cat")], ["the cat", "the dog", "the horse"], 0, "Listen and pick the image; picture answers", images=["cat", "dog", "horse"])
    lab.pick_missing_word("listen_pick_word", "listen_image", "The cat sleeps on the sofa.", "The cat ___ on the sofa.", [{"word": "sleeps"}, {"word": "sleep", "after_answer": "sleep (they sleep)"}, {"word": "sleeping"}], 0, "Listen and pick the missing word; three spoken answers, one with its own text", "sleeps")
    lab.start_round("listening_type", "Type, match and spell", "Type what you hear, fill the gaps, match the sounds to their meanings, or spell the word you hear.", "listening")
    lab.enter("listen_type", "listening_spelling", [audio("Thank you very much.")], [], "Type what you hear; the spoken text is the answer", answer="Thank you very much.")
    lab.enter("listen_gaps", "missing_word", [text("Anna eats an apple."), audio("Anna eats an apple.")], ["apple"], "Listen and fill the gaps; one gap", missing=["apple"])
    lab.match("listen_match", "audio_match", "Listen and match each word with its meaning.", [("espresso", "a small, strong coffee"), ("mug", "a big cup with a handle"), ("bill", "the paper that says what you must pay")], "Listen and match; three sounds and their meanings")
    lab.arrange("listen_spell", "spell_heard", [audio("bread")], ["b", "r", "e", "a", "d"], [[0, 1, 2, 3, 4]], "Spell what you hear; letter tiles")

    lab.start_lesson("Reading", "Read a situation and a short dialogue, then answer a question about its meaning. The right answer never copies the text.")
    lab.start_round("reading_answer", "Read and answer", "Read the situation and the dialogue, then answer. One dialogue is read aloud line by line.", "story")
    lab.choose("read_situation", "reading_answer_target", [text("You meet your neighbour after dinner, at about eight.", "context", "source"), text("What do you say?", "question")], ["Good evening!", "Good morning!", "Good night!"], 0, "Read and answer; a situation, no dialogue")
    lab.choose("read_dialogue", "reading_answer_target", [text("Anna and Luca are at a café.", "context", "source"), *turn("Would you like a cake?", "Anna"), *turn("No, thanks. Just a coffee.", "Luca"), text("What does Luca want?", "question")], ["Only something to drink.", "Something sweet to eat.", "Nothing at all."], 0, "Read and answer; a situation and two dialogue lines")
    lab.choose("read_dialogue_aloud", "reading_answer_target", [text("Anna and Luca talk after lunch.", "context", "source"), *turn("Do you want a coffee?", "Anna", "automatic"), *turn("Yes, without sugar.", "Luca", "automatic"), text("Is Luca's coffee sweet?", "question")], ["No, it is bitter.", "Yes, it is very sweet.", "Yes, with honey."], 0, "Read and answer; the dialogue read aloud automatically")

    lab.start_lesson("Pictures", "Pictures and written letters: select, name, spell and match.")
    lab.start_round("pictures_select", "Select and name", "Choose the picture or the word, type or build the name of what you see.")
    lab.choose("select_image", "icon_choice", [text("Select ‘cat’.", "question")], ["cat", "dog", "bird"], 0, "Select the image; picture answers", icons=[f"assets/exercise_images/{name}.webp" for name in ("cat", "dog", "bird")])
    lab.choose("script_letter", "script_recognition", [text("Select the letter shown."), {"role": "clue", "type": "image", "asset": glyph_asset("A"), "text": "Printed letter specimen"}], ["A", "E", "H"], 0, "Recognize characters; a printed letter to text")
    lab.choose("picture_choice", "picture_choice", [text("What is this?"), image("apple", "An apple", "picture")], ["an apple", "a pear", "some bread"], 0, "What is in the picture; text answers")
    lab.enter("picture_name", "picture_name", [text("What is this?"), image("bread", "Bread", "picture")], ["bread", "some bread", "{a} loaf {of bread}"], "Type what you see; accepted answers, one an expression")
    lab.arrange("picture_blocks", "picture_blocks", [text("What is this?"), image("apple", "An apple", "picture")], ["an", "apple", "a"], [[0, 1]], "Name what you see; word blocks and one extra block", hint="Include the article.")
    lab.start_round("pictures_spell", "Spell and match", "Spell the word from its letters, then match each picture with its word.")
    lab.arrange("image_word", "image_word", [text("Spell the word for this fruit.", "clue"), image("apple", "An apple")], ["a", "p", "p", "l", "e"], [[0, 1, 2, 3, 4]], "Spell the word in the picture; letter tiles")
    lab.arrange("spell_word", "spell_word", [text("a small pet that says meow", "clue", "source")], ["c", "a", "t"], [[0, 1, 2]], "Spell the word; a meaning as the clue")
    lab.match("picture_match", "picture_word_match", "Match each picture with its word.", [("cat", "the cat"), ("dog", "the dog"), ("house", "the house")], "Match pictures to words; three pictures", left_images=True)

    anna, luca = PREFIX + "character_anna", PREFIX + "character_luca"
    lab.start_lesson("Cards", "Cards and notes: a note card, a Page and a short Story. Every Round of this Course opens with a Before you start card.")
    lab.start_round("cards_notes", "Notes and a Page", "Read the note and the Page, then press Continue.")
    lab.card("note_card", "A or an?", "Use an before a vowel sound (an apple, an hour) and a before a consonant sound (a cat, a university).", "Note card; a grammar note", preset="note_card")
    lab.page("page_cafe", [
        {"type": "text", "text": "Coffee in a café", "textStyle": "heading1", "align": "center"},
        {"type": "text", "text": "An **espresso** is a small, strong coffee. Many people drink it *standing* at the counter, in a few sips.", "align": "justify"},
        {"type": "text", "text": "An espresso, please.", "language": "target", "textStyle": "quote", "align": "center", "readAloud": True},
        {"type": "text", "text": "Coffee words", "textStyle": "heading2"},
        {"type": "text", "text": "**espresso**: a small, strong coffee\n**cappuccino**: coffee with foamed milk\n**mug**: a big cup with a handle", "textStyle": "bulleted"},
        {"type": "image", "text": "A cup of coffee", "asset": "assets/exercise_images/coffee.webp", "size": "medium"},
        {"type": "text", "text": "Remember: say *please* and *thank you* to the barista.", "align": "end", "color": "accent"},
    ], "Page; headings, bold and italic, a quote read aloud, a list, a picture and an accent colour")
    lab.start_story("cards_story", "A Story", "Read or listen to the Story and answer the question between the lines.", "At the café")
    lab.cover("story_cover", "coffee", "A cup of coffee", "A morning at the café", "Story cover; a picture and a title line")
    lab.line("story_narrator", "Anna walks into a café and says hello to the barista.", "Dialogue line; the narrator")
    lab.line("story_anna", "Good morning! An espresso, please.", "Dialogue line; a character", speaker=anna)
    lab.line("story_luca", "Of course. Would you like a cake too?", "Dialogue line; another character", speaker=luca)
    lab.choose("story_choice", "choice_target", [text("What does Anna order?", "question")], ["A small, strong coffee", "A cup of tea", "A cake"], 0, "Choose the answer between the lines of a Story")
    lab.line("story_anna_no", "No, thank you. Just the coffee.", "Dialogue line; a character declines", speaker=anna)
    lab.finish_story()
    return lab


def course(lab: Laboratory) -> dict:
    """The Course to import: custom, the test Courses' made-up Maintainer,
    In the same language (Build 275 Revision 2: the stored kind)."""
    creator = {"type": "qqlUser", "id": MAINTAINER, "displayName": "QuisquisLingo"}
    lessons = copy.deepcopy(lab.lessons)
    for after, content in lab.canonical_extras:
        placed = False
        for lesson in lessons:
            for round_ in lesson["rounds"]:
                ids = [item["id"] for item in round_["content"]]
                if after in ids:
                    round_["content"].insert(ids.index(after) + 1, content)
                    placed = True
        assert placed, after
    v11 = {
        "formatVersion": 11,
        "courseId": COURSE_ID,
        "originType": "custom",
        "originalCourseCreator": creator,
        "maintainer": {"profileId": MAINTAINER},
        "originalCreatedAtUtc": STAMP,
        "courseVersion": "1",
        "lastVersionEditorProfileId": MAINTAINER,
        "lastVersionEditorDisplayName": "QuisquisLingo",
        "publicationState": "published", "lessonNumberingMode": "lesson",
        "defaultLessonIconStyle": "monochrome", "modifiedAtUtc": STAMP,
        "learningLanguage": "English", "interfaceLanguage": "English",
        "sourceLanguage": "English", "sourceLanguageTag": "en-GB",
        "targetLanguage": "English", "targetLanguageTag": "en-GB",
        "title": TITLE, "ttsLanguage": "en-GB", "audioMode": "tts",
        "authors": [{"name": "QuisquisLingo", "roles": ["Author"]}],
        "license": "All rights reserved", "derivativeWorksPolicy": "allowed",
        "courseDescription": "A Course in the same language, English explained in English, for trying every exercise type such a Course offers: words and their meanings instead of translations. Six Lessons group the presets: Vocabulary, Grammar, Listening, Reading, Pictures and Cards. Every Lesson has a GuideBook module of words and meanings, which Word Lookup reads. Enable Audio Exercises and Text-to-speech to include the listening examples. Written by AI and not reviewed.",
        "textDirection": "ltr", "temporarySample": False, "flagCode": "EN",
        "createDuels": False,
        "mediaAttributions": [{
            "author": "QuisquisLingo", "license": "All rights reserved",
            "title": "Exercise Lab printed-character specimens",
            "source": "Original deterministic block lettering generated by tools/generate_exercise_laboratory_254.py; no external font or image source.",
            "appliesTo": "The embedded A PNG in the Recognize characters example.",
        }],
        "keywords": ["exercise laboratory", "same language", "English", "test course"],
        "lessons": lessons,
    }
    value = convert_course_v11_to_v12(v11)
    for lesson, source in zip(value["lessons"], v11["lessons"]):
        lesson["guidebook"] = lab_guidebook(source, MODULE_TITLES)
    value["roundNumberingMode"] = "off"
    for lesson in value["lessons"]:
        for round_data in lesson["rounds"]:
            round_data["roundType"] = "story" if round_data.get("flow") else "practice"
    value["storyNarrator"] = {"name": "Narrator", "language": "source"}
    value["storyCharacters"] = [
        {"id": PREFIX + "character_anna", "name": "Anna", "avatar": "assets/avatars/cat.png",
         "language": "target", "voice": "female"},
        {"id": PREFIX + "character_luca", "name": "Luca", "avatar": "assets/avatars/dog.png",
         "language": "target", "voice": "male"},
    ]
    value["minimumAppBuild"] = MINIMUM_APP_BUILD
    value["sameLanguage"] = True
    return value


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    built = lab()
    expected = json.dumps(course(built), ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != expected:
            raise SystemExit(f"Generated output differs: {OUTPUT.relative_to(ROOT)}")
    else:
        OUTPUT.write_text(expected, encoding="utf-8", newline="\n")
    presets = {
        (content.get("authoringMetadata") or {}).get("presetId")
        for lesson in json.loads(expected)["lessons"]
        for round_ in lesson["rounds"] for content in round_["content"]
    }
    print(f"En-En Exercise Lab {'verified' if args.check else 'generated'}: "
          f"{len(built.lessons)} Lessons, {sum(len(l['rounds']) for l in built.lessons)} Rounds, "
          f"{len(built.cases)} examples, {len(presets)} presets.")


if __name__ == "__main__":
    main()
