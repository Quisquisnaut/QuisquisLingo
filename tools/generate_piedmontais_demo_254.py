#!/usr/bin/env python3
"""Reproduce the approved Build 254 English -> Piedmontese sample only.

This is authored demo data, not a language-course generation framework.
The Course ID was allocated once with Course.newCourseId(); regeneration
preserves that identity and the stable descendant IDs. Uses only stdlib.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import re
import struct
import zlib
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qql_course_v12 import convert_course_v11_to_v12, story_cover, story_flow, story_line  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/courses/piedmontais_en.json"
COURSE_ID = "course_e5f5585a-7762-43a0-a6b2-62754e02d17b"
STAMP = "2026-09-25T00:00:00.000Z"
# Build 255 Revision 6 released version 1.1.0: the Course was renamed from
# Piedmontais to Piedmontese, the name of its target language, and its
# derivative-works policy became forbidden (All rights reserved).
# Build 256 Revision 4 released version 1.2.0 (one Lesson per catalogue
# preset); Revision 5 releases 1.3.0 with the two Story presets' Lessons.
RELEASE_STAMP = "2026-09-28T00:00:00.000Z"
PREFIX = "pms_e5f5585a"
NORMALIZATION = {
    "case": "ignore", "punctuation": "ignore",
    "whitespace": "normalize", "accents": "preserve",
}
AUDIO_NOTE = (
    "Audio uses On-Device TTS with pms-IT. This demo contains no recorded "
    "Piedmontese voice. Listening examples require a suitable device voice; "
    "availability and pronunciation depend on the device."
)


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


def image(name: str, alternative: str, role: str = "clue") -> dict:
    return {
        "role": role, "type": "image", "text": alternative,
        "asset": f"assets/exercise_images/{name}.webp",
    }


def glyph_png(letter: str) -> str:
    """Original high-contrast 5-column glyph diagrams; no font dependency."""
    accents = {
        "ë": ["01010", "00000"],
        "é": ["00010", "00100"],
        "ò": ["01000", "00100"],
    }
    shapes = {
        "e": ["00000", "01110", "10001", "11111", "10000", "01110", "00000"],
        "o": ["00000", "01110", "10001", "10001", "10001", "01110", "00000"],
    }
    rows = accents[letter] + shapes["o" if letter == "ò" else "e"]
    scale, pad = 14, 20
    width, height = 5 * scale + 2 * pad, len(rows) * scale + 2 * pad
    pixels = bytearray()
    for y in range(height):
        pixels.append(0)  # PNG scanline filter: none
        for x in range(width):
            gx, gy = (x - pad) // scale, (y - pad) // scale
            ink = 0 <= gx < 5 and 0 <= gy < len(rows) and rows[gy][gx] == "1"
            pixels.append(24 if ink else 255)

    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(
            ">I", zlib.crc32(kind + data) & 0xFFFFFFFF
        )

    png = b"\x89PNG\r\n\x1a\n" + chunk(
        b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 0, 0, 0, 0)
    ) + chunk(b"IDAT", zlib.compress(bytes(pixels), 9)) + chunk(b"IEND", b"")
    return "data:image/png;base64," + base64.b64encode(png).decode("ascii")


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
            orders: list[list[int]], language: str | None = None) -> dict:
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
    })


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


def lesson_specs() -> list[tuple[str, str, str, list[dict]]]:
    """Preset ID, teaching topic, GuideBook, authored examples."""
    specs = []

    def add(kind, topic, guide, examples):
        specs.append((kind, topic, guide, examples))

    add("choice_target", "First words", "pan = bread; gat = cat; eva = water. Choose the Piedmontese word.", [
        choose("choice_target", [text("How do you say bread in Piedmontese?")], ["pan", "gat", "eva"]),
        choose("choice_target", [text("How do you say cat in Piedmontese?")], ["can", "gat", "pan"], 1),
        choose("choice_target", [text("How do you say water in Piedmontese?")], ["pom", "pan", "eva"], 2),
    ])
    add("choice_source", "What does it mean?", "grassie and mersì = thank you; ciàu = hello or bye; bondì = good morning. The questions and the answers are in English.", [
        choose("choice_source", [text("What does “grassie” mean?", "question", "source")], ["thank you", "good morning", "goodbye"], language="source"),
        choose("choice_source", [text("When do people say “bondì”?", "question", "source")], ["At night", "In the morning", "At the table"], 1, language="source"),
        choose("choice_source", [text("Which word is a greeting?", "question", "source")], ["pan", "eva", "ciàu"], 2, language="source"),
    ])
    add("true_false", "True or false?", "Ël gat a l'é n'animal = the cat is an animal; ël pan a l'é n'animal = the bread is an animal (false); l'eva a l'é da bèive = water is for drinking. Answer True or False.", [
        choose("true_false", [text("Ël gat a l'é n'animal.", "question")], ["True", "False"], 0, language="source"),
        choose("true_false", [text("Ël pan a l'é n'animal.", "question"), audio("Ël pan a l'é n'animal.")], ["True", "False"], 1, language="source"),
        choose("true_false", [text("L'eva a l'é da bèive.", "question")], ["True", "False"], 0, language="source"),
    ])
    add("gap_choice", "Small phrases", "ël can = the dog; la ca = the house; bon-a matin = good morning.", [
        choose("gap_choice", [text("Complete the phrase meaning the dog."), text("ël ___", "question")], ["pan", "can", "pom"], 1),
        choose("gap_choice", [text("Complete the phrase meaning the house."), text("la ___", "question")], ["ca", "cadrega", "tàula"]),
        choose("gap_choice", [text("Complete the greeting meaning good morning."), text("bon-a ___", "question")], ["ca", "eva", "matin"], 2),
    ])
    add("icon_choice", "Words in pictures", "Look at the pictures: gat = cat; pan = bread; eva = water.", [
        choose("icon_choice", [text("Select the image for gat.")], ["gat", "can", "caval"], pictures=["cat", "dog", "horse"]),
        choose("icon_choice", [text("Select the image for pan.")], ["pom", "pan", "eva"], 1, ["apple", "bread", "water"]),
        choose("icon_choice", [text("Select the image for eva.")], ["pan", "pom", "eva"], 2, ["bread", "apple", "water"]),
    ])
    add("script_recognition", "Accented letters", "These letter diagrams distinguish ë (e with diaeresis), é (e with acute accent), and ò (o with grave accent). Identify the printed character, not its sound.", [
        choose("script_recognition", [text(instruction), {
            "role": "clue", "type": "image", "text": "A printed accented letter",
            "asset": glyph_png(letter),
        }], choices, correct)
        for letter, choices, correct, instruction in [
            ("ë", ["ë", "é", "e"], 0, "Identify this printed e-family character."),
            ("é", ["è", "é", "ë"], 1, "Which accented e is printed here?"),
            ("ò", ["o", "ó", "ò"], 2, "Which o-family character is shown?"),
        ]
    ])
    add("listening_answer_target", "Hear a greeting", "bondì = good morning; mersì = thank you; ciàu = hello or bye. Choose the exact written word you hear. " + AUDIO_NOTE, [
        choose("listening_answer_target", [text(instruction), audio(heard)], choices, correct)
        for heard, choices, correct, instruction in [
            ("bondì", ["bondì", "mersì", "ciàu"], 0, "Listen to the first greeting."),
            ("mersì", ["ciàu", "mersì", "bondì"], 1, "Listen to the next expression."),
            ("ciàu", ["mersì", "bondì", "ciàu"], 2, "Listen to the final greeting."),
        ]
    ])
    add("listening_answer_source", "Listen for meaning", "I l'hai = I have; i son = I am; a ca = at home; lìber = book; un = one; doi = two; tre = three. Listen to each short passage and answer its English question. " + AUDIO_NOTE, [
        choose("listening_answer_source", [audio("Mi i son a ca. I l'hai un lìber.", "passage"), text("What does the speaker have?", "question", "source")], ["a book", "a dog", "an apple"]),
        choose("listening_answer_source", [audio("I l'hai un gat e un can.", "passage"), text("Which two animals are mentioned?", "question", "source")], ["a cat and a horse", "a cat and a dog", "a dog and a horse"], 1),
        choose("listening_answer_source", [audio("La lista: pan, eva e tre pom.", "passage"), text("How many apples are on the list?", "question", "source")], ["one", "two", "three"], 2),
    ])
    add("reading_answer_target", "Read a short note", "la lista = the list; pan = bread; eva = water; pom = apple; gat = cat; can = dog; lìber = book; a ca = at home.", [
        choose("reading_answer_target", [text("La lista: pan, eva e tre pom.", "passage"), text("Which drink is on the list?", "question")], ["water", "coffee", "milk"]),
        choose("reading_answer_target", [text("I l'hai un gat e un can.", "passage"), text("How many kinds of animal does the speaker have?", "question")], ["one", "two", "three"], 1),
        choose("reading_answer_target", [text("Mi i son a ca. I l'hai un lìber.", "passage"), text("Where is the speaker?", "question")], ["at school", "at the station", "at home"], 2),
    ])
    add("reading_answer_source", "Understand the situation", "bondì = good morning; grassie = thank you; prego = you are welcome; bon-aneuit = good night. Read the situation and answer in English.", [
        choose("reading_answer_source", [text("Anna: Bondì, Gioann! Gioann: Bondì, Anna!", "passage"), text("What time of day is it?", "question", "source")], ["Morning", "Night", "Noon"], language="source"),
        choose("reading_answer_source", [text("Anna: Grassie, Gioann! Gioann: Prego, Anna.", "passage"), text("What is Anna doing?", "question", "source")], ["Saying good night", "Thanking you", "Asking for bread"], 1, language="source"),
        choose("reading_answer_source", [text("Anna: Bon-aneuit, Gioann! Gioann: Bon-aneuit, Anna.", "passage"), text("What is Anna about to do?", "question", "source")], ["Have lunch", "Leave for work", "Go to bed"], 2, language="source"),
    ])
    add("type_translation_to_target", "Write in Piedmontese", "Translate English into Piedmontese. Thank you accepts grassie or mersì. The happy speaker is masculine: i son content; mi is optional. The house is la ca.", [
        enter("type_translation_to_target", [text("thank you")], ["grassie", "mersì"]),
        enter("type_translation_to_target", [text("I am happy. (masculine speaker)")], ["{mi} i son content"]),
        enter("type_translation_to_target", [text("the house")], ["la ca"]),
    ])
    add("type_translation_to_source", "Translate into English", "grassie = thank you; la ca = the house; i son content = I am happy. Type the English meaning.", [
        enter("type_translation_to_source", [text("grassie", language="target")], ["thank you", "thanks"]),
        enter("type_translation_to_source", [text("la ca", language="target")], ["the house"]),
        enter("type_translation_to_source", [text("mi i son content", language="target")], ["I am happy", "I'm happy"]),
    ])
    add("build_translation_to_target", "Translate with blocks", "Build an English phrase in Piedmontese. ël lìber = the book; i son content = I am happy (masculine); pan e eva = bread and water. For I am happy, both mi i son content and i son content are accepted.", [
        arrange("build_translation_to_target", [text("the book")], ["lìber", "la", "ël"], [[2, 0]]),
        arrange("build_translation_to_target", [text("I am happy. (masculine speaker)")], ["content", "mi", "son", "i"], [[1, 3, 2, 0], [3, 2, 0]]),
        arrange("build_translation_to_target", [text("bread and water")], ["eva", "pan", "e"], [[1, 2, 0]]),
    ])
    add("build_translation_to_source", "Translate into English with blocks", "ël lìber = the book; pan e eva = bread and water; ël can = the dog. Build the English phrase from the blocks.", [
        arrange("build_translation_to_source", [text("ël lìber", language="target")], ["the", "book", "dog"], [[0, 1]], language="source"),
        arrange("build_translation_to_source", [text("pan e eva", language="target")], ["water", "bread", "and"], [[1, 2, 0]], language="source"),
        arrange("build_translation_to_source", [text("ël can", language="target")], ["cat", "the", "dog"], [[1, 2]], language="source"),
    ])
    add("translation_choice_to_target", "English to Piedmontese", "Read the English source and pick its Piedmontese translation. ël can = the dog; ross = red; tre = three.", [
        choose("translation_choice_to_target", [text("the dog", "question")], ["ël can", "ël gat", "ël pan"]),
        choose("translation_choice_to_target", [text("red", "question")], ["nèir", "ross", "bianch"], 1),
        choose("translation_choice_to_target", [text("three", "question")], ["un", "doi", "tre"], 2),
    ])
    add("translation_choice_to_source", "Piedmontese to English", "Read the Piedmontese source and pick its English meaning. bon-aneuit = good night; ël pan = the bread; mi i son content = I am happy.", [
        choose("translation_choice_to_source", [text("bon-aneuit", "question")], ["good night", "good morning", "thank you"]),
        choose("translation_choice_to_source", [text("ël pan", "question")], ["the dog", "the bread", "the house"], 1),
        choose("translation_choice_to_source", [text("mi i son content", "question")], ["I have a book", "I am at home", "I am happy"], 2),
    ])
    add("complete_text", "Complete the text", "Type the words missing from each short text: gat = cat; can = dog; pan = bread; eva = water; lìber = book. No audio.", [
        enter("complete_text", [text("I l'hai un gat e un can.")], [], missingWords=["gat", "can"]),
        enter("complete_text", [text("La lista: pan, eva e tre pom.")], [], missingWords=["pan", "eva"]),
        enter("complete_text", [text("Mi i son a ca. I l'hai un lìber.")], [], missingWords=["lìber"]),
    ])
    add("missing_letters", "Missing letters", "Type the letters missing inside the words: gat = cat; granda = big; eva = water.", [
        enter("missing_letters", [text("I l'hai un gat.")], [], missingWords=["at"]),
        enter("missing_letters", [text("La ca a l'é granda.")], [], missingWords=["and"]),
        enter("missing_letters", [text("Pan e eva."), audio("Pan e eva.")], [], missingWords=["va"]),
    ])
    add("type_missing_word", "First-letter help", "Complete each missing word after its first letter is shown. Enter the whole word: gat (cat), ca (house), or lìber (book), including the first letter.", [
        enter("type_missing_word", [text("I l'hai un ___.")], ["gat"], hint="The animal that meows."),
        enter("type_missing_word", [text("la ___")], ["ca"], hint="The place where you live."),
        enter("type_missing_word", [text("ël ___")], ["lìber"], hint="An object with pages to read."),
    ])
    add("gap_choice_inline", "Pick the words for the gaps", "Tap the options to fill the gaps of a fixed sentence: mi i son content = I am happy; pan e eva = bread and water; ël gat e ël can = the cat and the dog.", [
        gaps("gap_choice_inline", "Complete the sentence about being happy.", ["Mi", ("i",), ("son",), "content."], ["a"]),
        gaps("gap_choice_inline", "Complete the phrase meaning bread and water.", [("pan",), "e", ("eva",)], ["pom"]),
        gaps("gap_choice_inline", "Complete the phrase; the same article fills both gaps.", [("ël",), "gat e", ("ël",), "can"], ["la"]),
    ])
    add("listening_spelling", "Hear and spell", "Listen and type the whole word. The vocabulary is pan (bread), eva (water), and pom (apple). " + AUDIO_NOTE, [
        enter("listening_spelling", [text(instruction), audio(word)], [word])
        for word, instruction in [
            ("pan", "Transcribe the first food word."),
            ("eva", "Type the drink you hear."),
            ("pom", "Transcribe the final food word."),
        ]
    ])
    add("missing_word", "Listen for gaps", "The transcript supplies the sentence around each missing word. Fill the missing words in order: pan = bread; eva = water; gat = cat; can = dog; lìber = book. " + AUDIO_NOTE, [
        enter("missing_word", [text(transcript), audio(transcript)], [], missingWords=missing)
        for transcript, missing in [
            ("pan e eva", ["pan", "eva"]),
            ("I l'hai un gat e un can.", ["gat", "can"]),
            ("I l'hai un lìber.", ["lìber"]),
        ]
    ])
    add("word_match", "Three translations", "Match English words with Piedmontese words. Food: pan, eva, pom. Animals: gat, can, caval. At home: tàula, cadrega, pòrta.", [
        match("word_match", f"Match English {topic} words to Piedmontese.", pairs)
        for topic, pairs in [
            ("food and drink", [("bread", "pan"), ("water", "eva"), ("apple", "pom")]),
            ("animal", [("cat", "gat"), ("dog", "can"), ("horse", "caval")]),
            ("household", [("table", "tàula"), ("chair", "cadrega"), ("door", "pòrta")]),
        ]
    ])
    add("super_match", "Related Piedmontese words", "Follow the relationship named in each exercise. Opposites: càud/frèid (hot/cold), nèir/bianch (black/white), grand/cit (big/small). Plurals: ël lìber/ij lìber, la ca/le ca, la cadrega/le cadreghe. Articles: ël gat, la ca, ël lìber.", [
        match("super_match", "Match the Piedmontese opposites.", [("càud", "frèid"), ("nèir", "bianch"), ("grand", "cit")]),
        match("super_match", "Match each singular phrase to its plural.", [("ël lìber", "ij lìber"), ("la ca", "le ca"), ("la cadrega", "le cadreghe")]),
        match("super_match", "Match each noun to the same noun with its definite article.", [("gat", "ël gat"), ("ca", "la ca"), ("lìber", "ël lìber")]),
    ])
    add("picture_word_match", "Pictures and words", "Match each picture with its Piedmontese word: gat = cat; can = dog; caval = horse; pan = bread; eva = water; pom = apple.", [
        match("picture_word_match", "Match each animal picture with its word.", [("cat", "gat"), ("dog", "can"), ("horse", "caval")]),
        match("picture_word_match", "Match each food picture with its word.", [("bread", "pan"), ("water", "eva"), ("apple", "pom")]),
        match("picture_word_match", "Match each picture at home with its word.", [("house", "ca"), ("book", "lìber"), ("chair", "cadrega")]),
    ])
    add("audio_match", "Match what you hear", "Play each Piedmontese item and match it to the English meaning. Each exercise has three unique audio/text pairs and no distractors. " + AUDIO_NOTE, [
        match("audio_match", f"Match each spoken Piedmontese {topic} word to its English meaning.", pairs)
        for topic, pairs in [
            ("food or drink", [("pan", "bread"), ("eva", "water"), ("pom", "apple")]),
            ("animal", [("gat", "cat"), ("can", "dog"), ("caval", "horse")]),
            ("colour", [("ross", "red"), ("nèir", "black"), ("bianch", "white")]),
        ]
    ])
    add("word_order", "Put words in order", "Restore the Piedmontese phrase. Keep i before son. A repeated ël needs its own block each time. These are ordering exercises; no English sentence is being translated.", [
        arrange("word_order", [text("Put the speaker, verb and description in order.", "clue")], ["content", "son", "mi", "i"], [[2, 3, 1, 0]]),
        arrange("word_order", [text("Put the food first, then the link, then the drink.", "clue")], ["eva", "e", "pan"], [[2, 1, 0]]),
        arrange("word_order", [text("Put the cat first and the dog second, with an article before each.", "clue")], ["can", "ël", "e", "gat", "ël"], [[1, 3, 2, 4, 0]]),
    ])
    add("gap_blocks", "Drag the blocks into the gaps", "Drag each block into its gap; every block is used once: mi i son content; pan e eva; ël gat e ël can.", [
        gaps("gap_blocks", "Complete the sentence about being happy.", ["Mi", ("i",), ("son",), "content."], ["a"]),
        gaps("gap_blocks", "Complete the phrase meaning bread and water.", [("pan",), "e", ("eva",)], ["pom"]),
        gaps("gap_blocks", "Complete the phrase; the article is a separate block each time.", [("ël",), "gat e", ("ël",), "can"], []),
    ])
    add("sentence_order", "Put the sentences in order", "Put the lines of each short exchange in order. bondì = good morning; come ch'a va? = how are you?; bin, grassie = well, thank you.", [
        arrange("sentence_order", [text("Put the greeting exchange in order.", "clue")], ["Bondì, Anna!", "Bondì, Tòni! Come ch'a va?", "Bin, grassie."], [[0, 1, 2]]),
        arrange("sentence_order", [text("Put the shopping story in order.", "clue")], ["Anna va al mercà.", "A compra pan e eva.", "A torna a ca."], [[0, 1, 2]]),
        arrange("sentence_order", [text("Put the evening in order.", "clue")], ["I mangio.", "I leso un lìber.", "Bon-aneuit!"], [[0, 1, 2]]),
    ])
    add("image_word", "Build pictured words", "Use every letter to spell the Piedmontese word in the picture: pan (bread), gat (cat), caval (horse). The two a letters in caval are separate blocks.", [
        arrange("image_word", [text(instruction, "clue"), image(asset, alternative)], blocks, [order])
        for asset, alternative, blocks, order, instruction in [
            ("bread", "Bread", ["n", "p", "a"], [1, 2, 0], "Spell the pictured food in Piedmontese."),
            ("cat", "A cat", ["t", "g", "a"], [1, 2, 0], "Spell the pictured pet in Piedmontese."),
            ("horse", "A horse", ["a", "l", "c", "a", "v"], [2, 0, 4, 3, 1], "Spell the pictured farm animal in Piedmontese."),
        ]
    ])
    add("spell_word", "Spell the word", "Spell the Piedmontese word from its English clue with letter or syllable tiles: gat = cat; pan = bread; eva = water.", [
        arrange("spell_word", [text("cat (the animal)", "clue", "source")], ["g", "a", "t"], [[0, 1, 2]]),
        arrange("spell_word", [text("bread", "clue", "source")], ["p", "a", "n"], [[0, 1, 2]]),
        arrange("spell_word", [text("water (you drink it)", "clue", "source")], ["e", "va"], [[0, 1]]),
    ])
    add("spell_heard", "Spell what you hear", "Listen and spell the word with the tiles: gat = cat; pan = bread; caval = horse. " + AUDIO_NOTE, [
        arrange("spell_heard", [audio("gat")], ["g", "a", "t"], [[0, 1, 2]]),
        arrange("spell_heard", [audio("pan")], ["p", "a", "n"], [[0, 1, 2]]),
        arrange("spell_heard", [audio("caval")], ["ca", "val"], [[0, 1]]),
    ])
    add("listening_image_choice", "Hear and pick the picture", "Listen to the Piedmontese word and pick its picture: gat = cat; can = dog; caval = horse; pan = bread; eva = water; pom = apple. " + AUDIO_NOTE, [
        choose("listening_image_choice", [audio("gat")], ["gat", "can", "caval"], pictures=["cat", "dog", "horse"]),
        choose("listening_image_choice", [audio("pan")], ["pom", "pan", "eva"], 1, ["apple", "bread", "water"]),
        choose("listening_image_choice", [audio("eva")], ["pan", "pom", "eva"], 2, ["bread", "apple", "water"]),
    ])
    add("picture_choice", "What is in the picture?", "Look at the picture and pick its Piedmontese word: gat = cat; pan = bread; eva = water.", [
        choose("picture_choice", [text("What is this?", "question"), image("cat", "A cat", "picture")], ["gat", "can", "caval"]),
        choose("picture_choice", [text("What is this?", "question"), image("bread", "Bread", "picture")], ["pom", "pan", "eva"], 1),
        choose("picture_choice", [text("What is this?", "question"), image("water", "Water", "picture")], ["pan", "pom", "eva"], 2),
    ])
    add("picture_name", "Name what you see", "Type the Piedmontese word for the picture: gat = cat; pan = bread; eva = water. The article is optional.", [
        enter("picture_name", [text("What is this?", "question"), image("cat", "A cat", "picture")], ["{ël} gat"]),
        enter("picture_name", [text("What is this?", "question"), image("bread", "Bread", "picture")], ["{ël} pan"]),
        enter("picture_name", [text("What is this?", "question"), image("water", "Water", "picture")], ["{l'} eva", "eva"]),
    ])
    add("picture_flashcard", "Picture cards", "Look at the picture, read the word and its meaning; the pronunciation is optional. gat = cat; pan = bread; eva = water.", [
        picture_card("gat", "cat", "cat", "I l'hai un gat.", "I have a cat."),
        picture_card("pan", "bread", "bread", "Pan e eva.", "Bread and water."),
        picture_card("eva", "water", "water"),
    ])
    add("note_card", "Good to know", "Three notes about Piedmontese: the articles, the pronouns and the greetings.", [
        note("Ël, la, l'", "Piedmontese has ël for masculine and la for feminine nouns; l' comes before a vowel: l'eva."),
        note("Mi i son", "The subject pronoun is often doubled: mi i son means I am, literally me I am."),
        note("Bondì e bon-aneuit", "Bondì is good morning, bon-aneuit good night; ciàu works for hello and bye."),
    ])
    add("flashcard", "Remember useful words", "Read each term, meaning and example. Choose Got it or Review again. Flashcards do not award ordinary correct-answer XP. Pronunciation is optional and depends on the device. " + AUDIO_NOTE, [
        flashcard("lìber", "book", "I l'hai un lìber.", "I have a book."),
        flashcard("grassie", "thank you", "Grassie, Anna!", "Thank you, Anna!"),
        flashcard("eva", "water", "pan e eva", "bread and water"),
    ])
    return specs


def build_course_v11() -> dict:
    """The Course before conversion: the v11 original the converter tests read."""
    registry = (ROOT / "lib/models/exercise_authoring.dart").read_text(encoding="utf-8")
    registry_pairs = re.findall(r"id: '([^']+)',\s+name: '([^']+)'", registry)
    # The registry pairs include the Coming later presets, which have no
    # Lesson; the Lessons follow the registry's order of the active presets.
    by_kind = {spec[0]: spec for spec in lesson_specs()}
    active = [pair[0] for pair in registry_pairs if pair[0] in by_kind]
    assert set(by_kind) == set(active) and len(active) == len(by_kind), (
        "Preset registry changed: review the demo's authored Lesson coverage."
    )
    specs = [by_kind[kind] for kind in active]
    names = dict(registry_pairs)
    lessons = []
    for number, (kind, topic, guide, examples) in enumerate(specs, 1):
        lid = f"{PREFIX}_l{number:02d}"
        rid = f"{lid}_r01"
        for index, content in enumerate(examples, 1):
            eid = f"{rid}_e{index:02d}"
            content["id"] = eid
            if content["kind"] == "exercise":
                payload = content["exercise"]
                ids = {item["id"]: f"{eid}_{item['id']}"
                       for item in payload["interaction"].get("items", [])}
                for item in payload["interaction"].get("items", []):
                    item["id"] = ids[item["id"]]
                evaluation = payload["evaluation"]
                if "correctItemIds" in evaluation:
                    evaluation["correctItemIds"] = [ids[i] for i in evaluation["correctItemIds"]]
                for order in evaluation.get("correctOrders", []):
                    order["itemIds"] = [ids[i] for i in order["itemIds"]]
                if "pairs" in evaluation:
                    evaluation["pairs"] = [[ids[i] for i in pair] for pair in evaluation["pairs"]]
                if "gapAssignments" in evaluation:
                    evaluation["gapAssignments"] = {gap: ids[i] for gap, i in evaluation["gapAssignments"].items()}
        introduction = {
            "id": f"{rid}_intro", "publicationState": "published", "kind": "text",
            "required": False, "role": "lesson_intro",
            "text": f"{names[kind]}: {topic}. Three short examples use this exercise type.",
        }
        lessons.append({
            "lessonId": lid, "publicationState": "published", "updatedAt": STAMP,
            "section": False,
            "title": f"{names[kind]} — {topic}",
            "themeIconAsset": "assets/lesson_icons/speech_bubbles.png",
            "guidebook": {"content": [{
                "id": f"{lid}_g01", "publicationState": "published", "kind": "explanation",
                "required": False, "role": "overview", "text": guide,
            }]},
            "rounds": [{
                "id": rid, "publicationState": "published", "updatedAt": STAMP,
                "visualType": "generic", "title": f"{names[kind]} practice",
                "content": [introduction, *examples],
            }],
            "duel": {"id": f"{lid}_duel", "title": "Duel"},
        })
    course = {
        "formatVersion": 11, "publicationState": "published",
        "lessonNumberingMode": "lesson", "defaultLessonIconStyle": "monochrome",
        "createDuels": False, "courseId": COURSE_ID, "originType": "bundledOfficial",
        "publisherId": "org.quisquislingo", "publisherName": "QuisquisLingo",
        "officialCourseVersion": "1.3.0", "officialReleaseDateUtc": RELEASE_STAMP,
        "officialReleaseNotes": "QQL Build 256 Revision 5: a Dialogue line Lesson played as a Story joins the one Lesson per preset; the Story cover preset has no Lesson of its own.",
        "distributionChannel": "bundled", "publisherVerificationStatus": "verified",
        "originalCourseCreator": {"type": "publisher", "id": "org.quisquislingo", "displayName": "QuisquisLingo"},
        "originalCreatedAtUtc": STAMP, "modifiedAtUtc": RELEASE_STAMP,
        "learningLanguage": "Piedmontese", "interfaceLanguage": "English",
        "sourceLanguage": "English", "targetLanguage": "Piedmontese",
        "title": "Temporary Demo: Piedmontese", "ttsLanguage": "pms-IT", "audioMode": "tts",
        "authors": [{"name": "OpenAI Codex (AI-generated sample; not linguistically reviewed)", "roles": ["Author"]}],
        "license": "All rights reserved",
        "derivativeWorksPolicy": "forbidden",
        "mediaAttributions": [{
            "author": "OpenAI Codex",
            "license": "Original code-rendered letter diagrams for this temporary sample",
            "title": "Accented Piedmontese letters",
            "source": "tools/generate_piedmontais_demo_254.py glyph_png",
            "appliesTo": "The three embedded character-recognition PNGs: ë, é and ò",
        }],
        "languageVariant": "Piedmontese literary spelling; introductory AI-authored examples awaiting native-speaker review",
        "startLevel": "Beginner", "targetLevel": "Beginner",
        "courseDescription": "TEMPORARY UNREVIEWED AI-GENERATED SAMPLE. English to Piedmontese, with one Lesson per current named Exercise type. The content is for testing and requires native-speaker review before language-teaching use. Basic spellings were checked against Claudio Panero's English-Piedmontese dictionary; examples and letter diagrams are newly authored. " + AUDIO_NOTE,
        "sourceLanguageTag": "en-GB", "targetLanguageTag": "pms-IT",
        "textDirection": "ltr", "worldFlagId": "piedmontese", "temporarySample": True,
        "lessons": lessons,
    }
    return course


def story_lessons() -> list[dict]:
    """Build 256 Revision 5: the Dialogue line preset has no v11 recipe and
    gets its Lesson here, a Story of three lines; it joins after conversion,
    so the converter fixture (build_course_v11) omits it. The Story cover
    preset has no Lesson of its own: a Story of covers alone belongs to the
    Edge Case demo (owner decision, 28 September 2026). The two Assign
    presets have none either: the Laboratory's Assign Lesson shows them
    (Revision 7 follow-up, 29 September 2026)."""
    narrator, gioanin, catlina = "", f"{PREFIX}_character_gioanin", f"{PREFIX}_character_catlina"

    def entry(rid: str, index: int, preset: str, exercise: dict) -> dict:
        return {"id": f"{rid}_e{index:02d}", "publicationState": "published", "kind": "exercise",
                "required": True, "editorTemplate": preset, "exercise": exercise}

    def intro(rid: str, name: str, topic: str) -> dict:
        return {"id": f"{rid}_intro", "publicationState": "published", "kind": "text",
                "required": False, "role": "lesson_intro",
                "text": f"{name}: {topic}. Three short examples use this exercise type."}

    def lesson(number: int, name: str, topic: str, guide: str, round_: dict) -> dict:
        lid = f"{PREFIX}_l{number:02d}"
        return {
            "lessonId": lid, "publicationState": "published", "updatedAt": STAMP,
            "section": False, "title": f"{name} — {topic}",
            "themeIconAsset": "assets/lesson_icons/speech_bubbles.png",
            "guidebook": {"content": [{
                "id": f"{lid}_g01", "publicationState": "published", "kind": "explanation",
                "required": False, "role": "overview", "text": guide,
            }]},
            "rounds": [round_],
            "duel": {"id": f"{lid}_duel", "title": "Duel"},
        }

    rid = f"{PREFIX}_l39_r01"
    lines = [
        intro(rid, "Dialogue line", "At the market"),
        entry(rid, 1, "dialogue_line", story_line(
            "Gioanin goes to the market to buy bread.", updated_at=STAMP, speaker_id=narrator)),
        entry(rid, 2, "dialogue_line", story_line(
            "Bondì! Un pan, për piasì.", updated_at=STAMP, speaker_id=gioanin)),
        entry(rid, 3, "dialogue_line", story_line(
            "Grassie! Bon-a giornà, Gioanin.", updated_at=STAMP, speaker_id=catlina)),
    ]
    story = {
        "id": rid, "publicationState": "published", "updatedAt": STAMP,
        "visualType": "story", "title": "Dialogue line practice", "content": lines,
        "flow": story_flow([(c["id"], "exercise" in c) for c in lines], title="Al mercà"),
    }
    return [
        lesson(39, "Dialogue line", "At the market",
               "A Story: the narrator speaks English, Gioanin and Catlin-a speak Piedmontese. Read or listen to each line and continue; the scroll log keeps the dialogue. bondì = good morning; un pan = a loaf of bread; për piasì = please; grassie = thank you.",
               story),
    ]


def build_course() -> dict:
    v11 = build_course_v11()
    v11["lessons"] = [*v11["lessons"], *story_lessons()]
    course = convert_course_v11_to_v12(v11)
    course["storyNarrator"] = {"name": "Narrator", "language": "source"}
    course["storyCharacters"] = [
        {"id": f"{PREFIX}_character_gioanin", "name": "Gioanin", "avatar": "assets/avatars/kid.png",
         "language": "target", "voice": "male"},
        {"id": f"{PREFIX}_character_catlina", "name": "Catlin-a", "avatar": "assets/avatars/cat.png",
         "language": "target", "voice": "female"},
    ]
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
        print("PASS: Piedmontese course is reproducible; 42 catalogue presets, 39 Lessons (Story cover, Sort into groups and Fill the slots have none), 117 examples")
        return 0
    OUTPUT.write_text(rendered, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}: one Lesson per catalogue preset")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
