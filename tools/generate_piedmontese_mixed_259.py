#!/usr/bin/env python3
"""Generate QQL Demo: Piedmontese (Build 259 Revision 6, owner request of
1 October 2026): the exercises of the Piedmontese demo, no longer grouped by
exercise type but mixed at random.

The source is the Piedmontese demo as tools/generate_piedmontais_demo_254.py
builds it. Its Lessons 1-40 (one exercise type each, three examples) give 120
exercises; a fixed seed mixes them into one Lesson of 20 Rounds of six, each
Round opening with a Before you start card. The Story (the market dialogue,
whose lines stay in order) is the second Lesson. The Course has no GuideBook
(owner decision: the cards only). Exercises keep their content and time
stamps; their IDs take this Course's prefix. Run --check to verify without
writing.
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
            "prompt": [{"role": "intro", "type": "text",
                        "text": f"Mixed practice: {PER_ROUND} exercises of different types."}],
            "evaluation": {"mode": "none"},
        },
    }


def mixed_lesson(source_lessons: list[dict]) -> dict:
    exercises = []
    for lesson in source_lessons:
        for round_data in lesson["rounds"]:
            # The first Content of each source Round is its Before you start
            # card, which names one exercise type.
            exercises.extend(round_data["content"][1:])
    assert len(exercises) == ROUNDS * PER_ROUND, len(exercises)
    random.Random(SEED).shuffle(exercises)
    rounds = []
    for number in range(1, ROUNDS + 1):
        content = [card(number)]
        for position, exercise in enumerate(
                exercises[(number - 1) * PER_ROUND:number * PER_ROUND], 1):
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
        "guidebook": {"content": []},
        "rounds": rounds,
        "duel": {"id": f"{PREFIX}l01_duel", "title": "Duel"},
    }


def story_lesson(source: dict) -> dict:
    lesson = copy.deepcopy(source)
    lesson["guidebook"] = {"content": []}
    # The source titles name the exercise type; here the Lesson is the Story.
    lesson["title"] = "At the market"
    for round_data in lesson["rounds"]:
        round_data["title"] = "At the market"
        for content in round_data["content"]:
            if content.get("authoringMetadata", {}).get("presetId") == "before_you_start":
                # No GuideBook, so no Open GuideBook button on the card.
                content["exercise"].pop("options", None)
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
        "officialReleaseNotes": "QQL Build 259 Revision 6: the exercises of the Piedmontese demo mixed at "
                                "random in one Lesson of 20 Rounds, then its Story.",
        "originalCreatedAtUtc": STAMP,
        "modifiedAtUtc": STAMP,
        "title": "QQL Demo: Piedmontese",
        "courseDescription": (
            "TEMPORARY UNREVIEWED AI-GENERATED SAMPLE. English to Piedmontese: the 120 exercises of the "
            "Piedmontese demo, mixed at random in 20 Rounds of six instead of one Lesson per exercise type, "
            "followed by its Story at the market. The content is for testing and requires native-speaker "
            "review before language-teaching use. Audio uses On-Device TTS with pms-IT; listening examples "
            "require a suitable device voice."),
        "lessons": [mixed_lesson(lessons[:SOURCE_PRACTICE_LESSONS]), story_lesson(lessons[-1])],
    }
    course = {}
    for key, value in source.items():
        if key == "officialChecksum":
            continue
        course[key] = replaced.get(key, value)
        if key == "createDuels":
            # Course.toJson order: useGuidebook follows createDuels.
            course["useGuidebook"] = False
    assert course["useGuidebook"] is False
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
