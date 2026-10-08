#!/usr/bin/env python3
"""Course Model v11 Content builders shared by the bundled Course generators.

Build 262 Revision 0 moved these helpers, unchanged, out of the Piedmontese
demo's generator (which left the repository with its Courses) so that
`generate_english_from_italian_260.py` keeps producing the same file. They
build v11 Content; `qql_course_v12.convert_course_v11_to_v12` converts it.
Uses only stdlib.
"""
from __future__ import annotations

# The time stamp of a built exercise; a generator may replace it.
STAMP = "2026-09-25T00:00:00.000Z"
NORMALIZATION = {
    "case": "ignore", "punctuation": "ignore",
    "whitespace": "normalize", "accents": "preserve",
}


def text(value: str, role: str = "primary", language: str | None = None) -> dict:
    element = {"role": role, "type": "text", "text": value}
    if language:
        element["language"] = language
    return element


def audio(value: str, role: str = "primary", required: bool | None = None) -> dict:
    element = {"role": role, "type": "audio", "text": value}
    if required is not None:
        element["required"] = required
    return element


def turn(value: str, speaker: str, read_aloud: str | None = None) -> list[dict]:
    """A Read and answer dialogue line (target language) and, when read
    aloud, its optional audio right after it (Build 256 Revision 7 fourth
    follow-up)."""
    line = [{**text(value, "dialogue_turn"), "speaker": speaker}]
    if read_aloud:
        line.append({"role": "dialogue_turn", "type": "audio", "text": value,
                     "playback": read_aloud, "required": False})
    return line


def image(name: str, alternative: str, role: str = "clue") -> dict:
    return {
        "role": role, "type": "image", "text": alternative,
        "asset": f"assets/exercise_images/{name}.webp",
    }



def exercise(kind: str, prompt: list[dict], interaction: dict, evaluation: dict,
             **fields) -> dict:
    return {
        "publicationState": "published", "kind": "exercise", "required": True,
        "editorTemplate": kind,
        "exercise": {
            "updatedAt": STAMP, "prompt": prompt, "interaction": interaction,
            "evaluation": evaluation, **fields,
        },
    }


def choose(kind: str, prompt: list[dict], choices: list[str], correct: int = 0,
           pictures: list[str] | None = None, language: str | None = None) -> dict:
    return exercise(kind, prompt, {
        "kind": "select", "minSelections": 1, "maxSelections": 1,
        "items": [
            {"id": f"i{index}", "content": [text(value, language=language)] + (
                [text(f"assets/exercise_images/{pictures[index]}.webp", "icon")] if pictures else []
            )} for index, value in enumerate(choices)
        ],
    }, {"kind": "selected_items", "correctItemIds": [f"i{correct}"]})


def enter(kind: str, prompt: list[dict], accepted: list[str], **fields) -> dict:
    return exercise(kind, prompt, {"kind": "input", "inputType": "text"}, {
        "kind": "text_match", **({"acceptedAnswers": accepted} if accepted else {}),
        "normalization": NORMALIZATION.copy(),
    }, **fields)


def arrange(kind: str, prompt: list[dict], blocks: list[str],
            orders: list[list[int]], language: str | None = None, **fields) -> dict:
    separator = "" if kind in ("image_word", "spell_heard", "spell_word") else " "
    return exercise(kind, prompt, {
        "kind": "arrange",
        "items": [{"id": f"i{i}", "content": [text(block, language=language)]}
                  for i, block in enumerate(blocks)],
    }, {
        "kind": "ordered_items", "correctOrders": [
            {"text": separator.join(blocks[i] for i in order),
             "itemIds": [f"i{i}" for i in order]} for order in orders
        ],
    }, **fields)


def gaps(kind: str, instruction: str, parts: list, distractors: list[str]) -> dict:
    """An inline-gap Select (Pick the words for the gaps) or Arrange (Drag the
    blocks into the gaps): `parts` mixes fixed text and one-element tuples."""
    select = kind == "gap_choice_inline"
    options: list[str] = []
    layout, assignments = [], {}
    for part in parts:
        if isinstance(part, str):
            layout.append(text(part))
            continue
        value = part[0]
        gap_id = f"gap_{len(assignments) + 1}"
        if not select or value not in options:
            options.append(value)
            index = len(options) - 1
        else:
            index = options.index(value)
        assignments[gap_id] = f"i{index}"
        layout.append({"role": "primary", "type": "gap", "text": gap_id})
    options.extend(distractors)
    interaction = {"kind": "select" if select else "arrange",
                   "items": [{"id": f"i{i}", "content": [text(v)]} for i, v in enumerate(options)],
                   "layout": layout}
    if select:
        interaction.update(minSelections=1, maxSelections=1)
    return exercise(kind, [text(instruction, "primary" if select else "clue")], interaction,
                    {"kind": "selected_items" if select else "ordered_items", "gapAssignments": assignments})


def match(kind: str, instruction: str, pairs: list[tuple[str, str]]) -> dict:
    items = []
    for i, (left, right) in enumerate(pairs):
        items.append({"id": f"i{2 * i}", "content": [
            audio(left) if kind == "audio_match"
            else image(left, right, "primary") if kind == "picture_word_match"
            else text(left)
        ]})
        items.append({"id": f"i{2 * i + 1}", "content": [text(right)]})
    return exercise(kind, [text(instruction)], {"kind": "match", "items": items}, {
        "kind": "matched_items",
        "pairs": [[f"i{2 * i}", f"i{2 * i + 1}"] for i in range(len(pairs))],
    })


def flashcard(term: str, meaning: str, usage: str, translation: str) -> dict:
    """A Flashcard: the read-aloud speaks the term and is optional, never an
    audio exercise (Build 256 Revision 7 follow-up)."""
    return {
        "publicationState": "published", "kind": "presentation", "required": True,
        "editorTemplate": "flashcard", "presentation": {
            "content": [text(term, "term"), text(meaning, "meaning"),
                        text(usage, "usage"), text(translation, "usage_translation"),
                        audio(term, "audio", required=False)],
            "completion": {"actions": ["understood", "review_later"]},
        },
    }


def picture_card(term: str, meaning: str, picture: str, usage: str = "", translation: str = "") -> dict:
    """A Picture flashcard: the picture is required, the pronunciation optional."""
    content = [text(term, "term"), text(meaning, "meaning")]
    if usage:
        content.append(text(usage, "usage"))
    if translation:
        content.append(text(translation, "usage_translation"))
    content += [image(picture, meaning, "picture"), audio(term, "audio", required=False)]
    return {
        "publicationState": "published", "kind": "presentation", "required": True,
        "editorTemplate": "picture_flashcard", "presentation": {
            "content": content, "completion": {"actions": ["understood", "review_later"]},
        },
    }


def note(title: str, body: str) -> dict:
    return {
        "publicationState": "published", "kind": "presentation", "required": True,
        "editorTemplate": "note_card", "presentation": {
            "content": [text(title, "term"), text(body, "meaning")],
            "completion": {"actions": ["continue"]},
        },
    }
