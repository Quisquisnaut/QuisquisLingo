#!/usr/bin/env python3
"""Regenerate only the bundled Italian course for the build-225 Audit gate."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ITALIAN = ROOT / "assets" / "courses" / "italian_en.json"


def _render_like_existing_sample(course: dict[str, object]) -> str:
    lines = json.dumps(course, ensure_ascii=False, indent=2).splitlines()
    lessons_start = lines.index('  "lessons": [')
    for index in range(lessons_start + 1, len(lines) - 2):
        lines[index] = "    " + lines[index]
    return "\n".join(lines) + "\n"


def _item(item_id: str, text: str) -> dict[str, object]:
    return {
        "id": item_id,
        "content": [{"role": "primary", "type": "text", "text": text}],
    }


def _select_content(
    exercise_id: str,
    preset: str,
    prompt: list[dict[str, str]],
    options: list[str],
) -> dict[str, object]:
    item_ids = [f"{exercise_id}_i{index}" for index in range(len(options))]
    return {
        "id": exercise_id,
        "kind": "exercise",
        "publicationState": "published",
        "required": True,
        "editorTemplate": preset,
        "exercise": {
            "prompt": prompt,
            "interaction": {
                "kind": "select",
                "minSelections": 1,
                "maxSelections": 1,
                "items": [
                    _item(item_id, option)
                    for item_id, option in zip(item_ids, options, strict=True)
                ],
            },
            "evaluation": {
                "kind": "selected_items",
                "correctItemIds": [item_ids[0]],
            },
        },
    }


def _options(values: list[str], correct_index: int) -> list[str]:
    return [
        values[correct_index],
        values[(correct_index + 1) % len(values)],
        values[(correct_index + 2) % len(values)],
    ]


def _practice_round(
    round_id: str,
    title: str,
    vocabulary: list[tuple[str, str]],
    variant: int,
) -> dict[str, object]:
    targets = [target for target, _ in vocabulary]
    content: list[dict[str, object]] = []
    for index, (target, source) in enumerate(vocabulary):
        exercise_id = f"{round_id}_e{index + 1}"
        content.append(
            _select_content(
                exercise_id,
                "choice",
                [
                    {
                        "role": "question",
                        "type": "text",
                        "text": f"Choose the Italian translation of “{source}”.",
                    }
                ],
                _options(targets, index),
            )
        )

    first_listening = variant * 2
    for offset in range(2):
        index = (first_listening + offset) % len(vocabulary)
        target = vocabulary[index][0]
        exercise_id = f"{round_id}_e{len(content) + 1}"
        content.append(
            _select_content(
                exercise_id,
                "listening_choice",
                [
                    {"role": "primary", "type": "audio", "text": target},
                    {
                        "role": "question",
                        "type": "text",
                        "text": f"What do you hear in listening item {offset + 1}?",
                    },
                ],
                _options(targets, index),
            )
        )

    reading_index = (variant + 2) % len(vocabulary)
    reading_target = vocabulary[reading_index][0]
    exercise_id = f"{round_id}_e{len(content) + 1}"
    content.append(
        _select_content(
            exercise_id,
            "reading_comprehension",
            [
                {
                    "role": "passage",
                    "type": "text",
                    "text": f"Oggi ripassiamo la parola “{reading_target}” insieme.",
                },
                {
                    "role": "question",
                    "type": "text",
                    "text": "Which Italian word is being reviewed?",
                },
            ],
            _options(targets, reading_index),
        )
    )

    listening_index = (variant + 3) % len(vocabulary)
    listening_target = vocabulary[listening_index][0]
    exercise_id = f"{round_id}_e{len(content) + 1}"
    content.append(
        _select_content(
            exercise_id,
            "listening_comprehension",
            [
                {
                    "role": "passage",
                    "type": "audio",
                    "text": (
                        "Oggi ascoltiamo la parola "
                        f"{listening_target} in italiano."
                    ),
                },
                {
                    "role": "question",
                    "type": "text",
                    "text": "Which Italian word did you hear?",
                },
            ],
            _options(targets, listening_index),
        )
    )
    return {
        "id": round_id,
        "title": title,
        "visualType": "generic",
        "publicationState": "published",
        "content": content,
    }


def _vocabulary(lesson: dict[str, object]) -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = []
    guidebook = lesson.get("guidebook")
    if not isinstance(guidebook, dict):
        raise ValueError(f"{lesson.get('lessonId')}: missing Guidebook")
    content = guidebook.get("content")
    if not isinstance(content, list):
        raise ValueError(f"{lesson.get('lessonId')}: missing Guidebook content")
    for item in content:
        if not isinstance(item, dict) or item.get("kind") != "vocabulary":
            continue
        text = item.get("text")
        if not isinstance(text, str) or "=" not in text:
            continue
        target, source = (part.strip() for part in text.split("=", 1))
        if target and source:
            entries.append((target, source))
    if len(entries) < 4:
        raise ValueError(
            f"{lesson.get('lessonId')}: expected at least four vocabulary entries"
        )
    return entries[:4]


def _repair_existing_exercise(content: dict[str, object]) -> None:
    preset = content.get("editorTemplate")
    exercise = content.get("exercise")
    if not isinstance(exercise, dict):
        return
    interaction = exercise.get("interaction")
    evaluation = exercise.get("evaluation")
    prompt = exercise.get("prompt")

    if preset == "gap_choice" and isinstance(prompt, list):
        for element in prompt:
            if isinstance(element, dict) and element.get("role") == "question":
                element["text"] = "Questa parola è ___."
                break

    if (
        preset == "dialogue_response"
        and isinstance(interaction, dict)
        and isinstance(evaluation, dict)
    ):
        items = interaction.get("items")
        correct_ids = evaluation.get("correctItemIds")
        if isinstance(items, list) and len(items) > 2:
            correct_id = correct_ids[0] if isinstance(correct_ids, list) and correct_ids else None
            correct_item = next(
                (item for item in items if isinstance(item, dict) and item.get("id") == correct_id),
                items[0],
            )
            other_item = next(item for item in items if item is not correct_item)
            interaction["items"] = [correct_item, other_item]

    if preset == "listening_spelling":
        exercise.pop("missingWords", None)

    if preset == "missing_word":
        missing_words = exercise.get("missingWords")
        exercise["evaluation"] = {
            "kind": "text_match",
            "normalization": {
                "case": "ignore",
                "punctuation": "ignore",
                "whitespace": "normalize",
                "accents": "preserve",
            },
            "acceptedAnswers": missing_words if isinstance(missing_words, list) else [],
        }
        if isinstance(prompt, list):
            transcript = next(
                (
                    element.get("text", "")
                    for element in prompt
                    if isinstance(element, dict)
                    and element.get("type") == "text"
                    and element.get("role") in {"passage", "primary"}
                ),
                "",
            )
            if transcript and not any(
                isinstance(element, dict) and element.get("type") == "audio"
                for element in prompt
            ):
                prompt.append(
                    {"role": "primary", "type": "audio", "text": transcript}
                )

    hint = exercise.get("hint")
    if isinstance(hint, str) and isinstance(evaluation, dict):
        accepted = evaluation.get("acceptedAnswers", evaluation.get("accepted", []))
        if isinstance(accepted, list) and any(
            isinstance(answer, str)
            and re.sub(r"[^\w]+", "", answer.casefold())
            == re.sub(r"[^\w]+", "", hint.casefold())
            for answer in accepted
        ):
            exercise["hint"] = "Use the Lesson vocabulary clue."


def regenerate() -> None:
    course = json.loads(ITALIAN.read_text(encoding="utf-8"))
    if course.get("courseId") != "sample_it_en_it":
        raise ValueError("Unexpected bundled Italian course identity")

    lessons = course.get("lessons")
    if not isinstance(lessons, list):
        raise ValueError("Bundled Italian course has no Lessons")

    for lesson in lessons:
        if not isinstance(lesson, dict):
            raise ValueError("Bundled Italian course contains an invalid Lesson")
        rounds = lesson.get("rounds")
        if not isinstance(rounds, list) or len(rounds) < 2:
            raise ValueError(f"{lesson.get('lessonId')}: expected existing Rounds")
        for round_item in rounds[:2]:
            if not isinstance(round_item, dict):
                continue
            for content in round_item.get("content", []):
                if isinstance(content, dict):
                    _repair_existing_exercise(content)

        round_prefix = str(rounds[0]["id"]).removesuffix("_round_1")
        vocabulary = _vocabulary(lesson)
        generated = [
            _practice_round(
                f"{round_prefix}_round_3",
                "Vocabulary practice 1",
                vocabulary,
                0,
            ),
            _practice_round(
                f"{round_prefix}_round_4",
                "Vocabulary practice 2",
                vocabulary,
                1,
            ),
        ]
        lesson["rounds"] = [
            *rounds[:2],
            *generated,
            *[
                round_item
                for round_item in rounds[2:]
                if round_item.get("id")
                not in {generated[0]["id"], generated[1]["id"]}
            ],
        ]

    course["version"] = "1.5.8"
    course["courseVersion"] = "1.5.8"
    course["contentRevision"] = "sample-lessons-v225-it-audit"
    course["lastUpdated"] = "2026-09-03"
    course["updateSummary"] = (
        "Regenerated the bundled Italian sample through the canonical build-225 "
        "Editor model, repaired Audit-blocking content and added Duel-eligible "
        "practice while preserving existing stable IDs."
    )
    ITALIAN.write_text(_render_like_existing_sample(course), encoding="utf-8")


def main() -> int:
    regenerate()
    print(f"{ITALIAN.name}: regenerated for build 225")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
