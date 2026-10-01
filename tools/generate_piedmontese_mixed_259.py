#!/usr/bin/env python3
"""Generate QQL Demo: Piedmontese (Build 259 Revision 6, owner request of
1 October 2026): the exercises of the Piedmontese demo, no longer grouped by
exercise type but mixed at random.

The source is the Piedmontese demo as tools/generate_piedmontais_demo_254.py
builds it. Its Lessons 1-40 (one exercise type each, three examples) give 120
exercises; a fixed seed mixes them into one Lesson of 20 Rounds of six, the
first opening with a Before you start card (each Round had one until Build
260 Revision 3, owner decision). The Story (the market dialogue,
whose lines stay in order) is the second Lesson. Exercises keep their
content and time stamps; their IDs take this Course's prefix. Build 259
Revision 7 (owner request) gives both Lessons a GuideBook: an overview,
notes and the vocabulary the exercises use, gathered from the source
GuideBooks; every card offers Open GuideBook. Build 260 Revision 7 (owner decisions) orders the mix along a
difficulty curve: each exercise's level (LEVEL, as ExerciseDifficulty
computes it) plus a random offset (fixed seed) sets its place, so later
Rounds hold a larger share of the harder types; no type repeats within a
Round, the exercises that need audio are spread evenly (at most two in a
Round), and the cards come one to a Round in the first Rounds. Run --check
to verify without writing.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_piedmontais_demo_254 as source_demo  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/courses/piedmontese_mixed_en.json"
# Allocated once (UUIDv4) in Build 259 Revision 6.
COURSE_ID = "course_69ff369e-bb4f-46a3-85f0-57ff9d51b453"
PREFIX = "pmsmix_69ff369e_"
SOURCE_PREFIX = source_demo.PREFIX + "_"
STAMP = "2026-10-01T00:00:00.000Z"
SEED = 259006
ROUNDS = 20
PER_ROUND = 6
SOURCE_PRACTICE_LESSONS = 40
# The difficulty level of each preset's exercises here, as ExerciseDifficulty
# computes it from canonical data (checked by the Dart test).
LEVEL = {
    "flashcard": 0, "picture_flashcard": 0, "note_card": 0,
    "choice_source": 1, "true_false": 1, "icon_choice": 1, "script_recognition": 2,
    "listening_choose_source": 1, "listening_answer_source": 1, "translation_choice_to_source": 1,
    "word_match": 1, "picture_word_match": 1, "audio_match": 1, "listening_image_choice": 1,
    "choice_target": 2, "gap_choice": 2, "one_word_fills_all": 2, "listening_choose_target": 2,
    "listening_answer_target": 2, "reading_answer_target": 2, "translation_choice_to_target": 2,
    "super_match": 2, "picture_choice": 2,
    "build_translation_to_target": 3, "build_translation_to_source": 3, "word_order": 3, "gap_blocks": 3,
    "sentence_order": 3, "image_word": 3, "spell_word": 3, "spell_heard": 3, "picture_blocks": 3,
    "type_translation_to_target": 4, "type_translation_to_source": 4, "complete_text": 4,
    "missing_letters": 4, "type_missing_word": 4, "listening_spelling": 4, "missing_word": 4,
    "picture_name": 4,
}
# How far a random offset may move an exercise along the curve, in levels.
SPREAD = 1.0
MAX_AUDIO_PER_ROUND = 2

# Build 259 Revision 7: the GuideBooks. The vocabulary (English = Piedmontese)
# is what the source Lessons' GuideBooks taught, without repetitions.
PRACTICE_OVERVIEW = (
    "Mixed practice: the exercises of the Piedmontese demo, every type mixed, six to a Round, from "
    "the easier ones (recognize the meaning) to the harder ones (build and write). The notes explain "
    "three things that come back often; the words are the ones the exercises use.")
PRACTICE_NOTES = [
    "Subject pronouns. Piedmontese puts a short subject pronoun before the verb: i son content = "
    "I am happy. Written Piedmontese does not leave it out, as Italian leaves out io. The full "
    "pronoun mi adds emphasis and is optional: mi i son content.",
    "Articles. ël goes before a masculine noun (ël can, ël pan), la before a feminine one (la ca), "
    "l' before a vowel (l'eva). un means a or one.",
    "Spelling. o sounds like the oo in food and ò like the o in hot; ë is a short, neutral vowel, "
    "as in ël; eu and u sound like the French eu and u.",
]
PRACTICE_VOCABULARY = [
    "hello, bye = ciàu",
    "good morning = bondì, bon-a matin",
    "good night = bon-aneuit",
    "how are you? = come ch'a va?",
    "well, thank you = bin, grassie",
    "thank you = grassie, mersì",
    "you are welcome = prego",
    "I am = i son",
    "I am happy = i son content",
    "I have = i l'hai",
    "the house = la ca",
    "at home = a ca",
    "big (feminine) = granda",
    "the book = ël lìber",
    "bread = pan",
    "the bread = ël pan",
    "water = eva",
    "bread and water = pan e eva",
    "water is for drinking = l'eva a l'é da bèive",
    "apple, apples = pom",
    "the apple = ël pom",
    "cat = gat",
    "the cat = ël gat",
    "dog = can",
    "the dog = ël can",
    "horse = caval",
    "the cat and the dog = ël gat e ël can",
    "the cat is an animal = ël gat a l'é n'animal",
    "a, one = un",
    "two = doi",
    "three = tre",
    "red = ross",
]
STORY_OVERVIEW = (
    "A Story at the market: the narrator speaks English, Gioanin and Catlin-a speak Piedmontese. "
    "Read or listen to each line, then continue; the scrolling log keeps the dialogue.")
STORY_VOCABULARY = [
    "good morning = bondì",
    "a loaf of bread = un pan",
    "please = për piasì",
    "thank you = grassie",
    "have a good day = bon-a giornà",
]


def guidebook(lesson_id: str, overview: str, notes: list[str], vocabulary: list[str]) -> dict:
    def entry(number: int, kind: str, role: str, text: str) -> dict:
        return {"id": f"{lesson_id}_g{number:02d}", "publicationState": "published", "kind": kind,
                "required": False, "role": role, "text": text}
    content = [entry(1, "explanation", "overview", overview)]
    for note in notes:
        content.append(entry(len(content) + 1, "explanation", "grammar", note))
    for word in vocabulary:
        # The Review reads "prompt = answer"; its other separators stay out.
        assert word.count(" = ") == 1 and ":" not in word and " - " not in word and " → " not in word, word
        content.append(entry(len(content) + 1, "vocabulary", "vocabulary", word))
    return {"content": content}


def renamed(value, old: str, new: str):
    """The value with every ID that starts with `old` starting with `new`."""
    text = json.dumps(value, ensure_ascii=False)
    return json.loads(text.replace(f'"{old}', f'"{new}'))


def card(round_number: int) -> dict:
    return {
        "id": f"{PREFIX}l01_r{round_number:02d}_intro",
        "publicationState": "published",
        "kind": "exercise",
        "required": False,
        "authoringMetadata": {"presetId": "before_you_start"},
        "exercise": {
            "updatedAt": STAMP,
            "primitive": "presentation",
            "options": {"guidebookButton": True},
            "prompt": [{"role": "intro", "type": "text",
                        "text": f"Mixed practice: {ROUNDS} Rounds of {PER_ROUND} exercises of different "
                                "types, from easier to harder. Open the GuideBook for the notes and the "
                                "words."}],
            "evaluation": {"mode": "none"},
        },
    }


def needs_audio(content: dict) -> bool:
    """Whether the exercise cannot be solved without its audio (an audio
    element that is not optional), as ExerciseFeatures.requiresAudio says."""
    exercise = content["exercise"]
    elements = list(exercise.get("prompt", []))
    for item in exercise.get("items", []):
        elements.extend(item.get("content", []))
    return any(e.get("type") == "audio" and e.get("required", True) is not False for e in elements)


def curve(exercises: list[dict]) -> list[list[dict]]:
    """The exercises in Rounds along the difficulty curve. Every exercise's
    key is its level plus a random offset. The cards (level 0) introduce the
    words: one in each of the first Rounds. The exercises that need audio
    are spread next, in key order, evenly over the Rounds (at most
    MAX_AUDIO_PER_ROUND each, never two of a type). Then each Round in turn
    takes, from the others in key order, the first one of a type it does not
    have yet."""
    generator = random.Random(SEED)

    def preset(content: dict) -> str:
        return content["authoringMetadata"]["presetId"]

    def types(members: list[dict]) -> set[str]:
        return {preset(x) for x in members}

    keyed = sorted(((LEVEL[preset(c)] + generator.uniform(-SPREAD, SPREAD), c) for c in exercises),
                   key=lambda kc: kc[0])
    cards = [c for _, c in keyed if LEVEL[preset(c)] == 0]
    heard = [c for _, c in keyed if LEVEL[preset(c)] > 0 and needs_audio(c)]
    queue = [c for _, c in keyed if LEVEL[preset(c)] > 0 and not needs_audio(c)]
    assert len(heard) <= ROUNDS * MAX_AUDIO_PER_ROUND
    generator.shuffle(cards)
    rounds = [[card] for card in cards] + [[] for _ in range(ROUNDS - len(cards))]
    for index, content in enumerate(heard):
        home = index * ROUNDS // len(heard)
        nearby = sorted(range(ROUNDS), key=lambda r: (abs(r - home), r < home))
        target = next(r for r in nearby
                      if sum(needs_audio(x) for x in rounds[r]) < MAX_AUDIO_PER_ROUND
                      and preset(content) not in types(rounds[r]))
        rounds[target].append(content)
    for members in rounds:
        while len(members) < PER_ROUND:
            pick = next((c for c in queue if preset(c) not in types(members)), queue[0])
            queue.remove(pick)
            members.append(pick)
    assert not queue
    # A type left twice in a Round (the last ones take what remains) swaps
    # with an exercise of the nearest earlier Round that clashes with
    # neither Round, and has the same need for audio.
    for index, members in enumerate(rounds):
        for twin in [c for c in members if [preset(x) for x in members].count(preset(c)) > 1][1:]:
            for earlier in reversed(rounds[:index]):
                swap = next((c for c in earlier
                             if LEVEL[preset(c)] > 0 and needs_audio(c) == needs_audio(twin)
                             and preset(c) not in types(members)
                             and preset(twin) not in types(earlier)), None)
                if swap is not None:
                    earlier[earlier.index(swap)] = twin
                    members[members.index(twin)] = swap
                    break
    for members in rounds:
        generator.shuffle(members)
    return rounds


def mixed_lesson(source_lessons: list[dict]) -> dict:
    exercises = []
    for lesson in source_lessons:
        for round_data in lesson["rounds"]:
            # The first Content of each source Round is its Before you start
            # card, which names one exercise type.
            exercises.extend(round_data["content"][1:])
    assert len(exercises) == ROUNDS * PER_ROUND, len(exercises)
    rounds = []
    for number, members in enumerate(curve(exercises), 1):
        # Only the Lesson's first Round opens with a card (Build 260
        # Revision 3).
        content = [card(number)] if number == 1 else []
        for position, exercise in enumerate(members, 1):
            new_id = f"{PREFIX}l01_r{number:02d}_e{position:02d}"
            content.append(renamed(exercise, exercise["id"], new_id))
        # Every Round keeps at least one exercise that is scored.
        assert any(item["exercise"]["evaluation"]["mode"] != "none" for item in content), number
        rounds.append({
            "id": f"{PREFIX}l01_r{number:02d}",
            "publicationState": "published",
            "updatedAt": STAMP,
            "visualType": "generic",
            "title": f"Mixed practice {number}",
            "content": content,
        })
    return {
        "lessonId": f"{PREFIX}l01",
        "publicationState": "published",
        "updatedAt": STAMP,
        "section": False,
        "title": "Mixed practice",
        "themeIconAsset": "assets/lesson_icons/school.png",
        "guidebook": guidebook(f"{PREFIX}l01", PRACTICE_OVERVIEW, PRACTICE_NOTES, PRACTICE_VOCABULARY),
        "rounds": rounds,
        "duel": {"id": f"{PREFIX}l01_duel", "title": "Duel"},
    }


def story_lesson(source: dict) -> dict:
    lesson = copy.deepcopy(source)
    # The GuideBook IDs take the source Lesson's ID, renamed below.
    lesson["guidebook"] = guidebook(source["lessonId"], STORY_OVERVIEW, [], STORY_VOCABULARY)
    # The source titles name the exercise type; here the Lesson is the Story.
    lesson["title"] = "At the market"
    for round_data in lesson["rounds"]:
        round_data["title"] = "At the market"
        for content in round_data["content"]:
            if content.get("authoringMetadata", {}).get("presetId") == "before_you_start":
                # The card keeps its Open GuideBook button.
                content["exercise"]["prompt"][0]["text"] = "A Story at the market: three lines of dialogue."
    return renamed(lesson, source["lessonId"], f"{PREFIX}l02")


def build_course() -> dict:
    source = source_demo.build_course()
    lessons = source["lessons"]
    assert len(lessons) == SOURCE_PRACTICE_LESSONS + 1
    assert all(round_data.get("flow") is None
               for lesson in lessons[:SOURCE_PRACTICE_LESSONS] for round_data in lesson["rounds"])
    assert lessons[-1]["rounds"][0]["visualType"] == "story"
    replaced = {
        "courseId": COURSE_ID,
        "officialCourseVersion": "1.0.0",
        "officialReleaseDateUtc": STAMP,
        "officialReleaseNotes": "QQL Build 259 Revisions 6 and 7 and Build 260 Revision 7: the exercises of "
                                "the Piedmontese demo mixed in one Lesson of 20 Rounds from easier to harder, "
                                "then its Story; each Lesson has a GuideBook.",
        "originalCreatedAtUtc": STAMP,
        "modifiedAtUtc": STAMP,
        "title": "QQL Demo: Piedmontese",
        "courseDescription": (
            "TEMPORARY UNREVIEWED AI-GENERATED SAMPLE. English to Piedmontese: the 120 exercises of the "
            "Piedmontese demo, mixed in 20 Rounds of six from easier to harder instead of one Lesson per "
            "exercise type, "
            "followed by its Story at the market. The content is for testing and requires native-speaker "
            "review before language-teaching use. Audio uses On-Device TTS with pms-IT; listening examples "
            "require a suitable device voice."),
        "lessons": [mixed_lesson(lessons[:SOURCE_PRACTICE_LESSONS]), story_lesson(lessons[-1])],
    }
    # Use GuideBook stays on: the Course stores no useGuidebook key.
    course = {key: replaced.get(key, value) for key, value in source.items() if key != "officialChecksum"}
    assert "useGuidebook" not in course
    course["storyCharacters"] = renamed(course["storyCharacters"], f"{SOURCE_PREFIX}character_",
                                        f"{PREFIX}character_")
    course = renamed(course, f"{SOURCE_PREFIX}character_", f"{PREFIX}character_")
    text = json.dumps(course, ensure_ascii=False)
    assert SOURCE_PREFIX not in text, "an ID of the source Course is left"
    canonical = {key: value for key, value in course.items()
                 if key not in {"officialChecksum", "publisherVerificationStatus", "publisherSignature"}}
    course["officialChecksum"] = hashlib.sha256(json.dumps(
        canonical, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")).hexdigest()
    return course


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Verify reproducibility without writing.")
    args = parser.parse_args()
    rendered = json.dumps(build_course(), ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != rendered:
            print(f"FAIL: {OUTPUT.relative_to(ROOT)} differs from the authored generator")
            return 1
        print(f"PASS: {OUTPUT.relative_to(ROOT)} is reproducible; 2 Lessons, "
              f"{ROUNDS} mixed Rounds of {PER_ROUND} and the Story")
        return 0
    OUTPUT.write_text(rendered, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
