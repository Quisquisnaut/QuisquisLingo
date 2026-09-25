#!/usr/bin/env python3
"""Reproduce the approved Build 254 English -> Piedmontais sample only.

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
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/courses/piedmontais_en.json"
COURSE_ID = "course_e5f5585a-7762-43a0-a6b2-62754e02d17b"
STAMP = "2026-09-25T00:00:00.000Z"
PREFIX = "pms_e5f5585a"
NORMALIZATION = {
    "case": "ignore", "punctuation": "ignore",
    "whitespace": "normalize", "accents": "preserve",
}
AUDIO_NOTE = (
    "Audio uses On-Device TTS with pms-IT. This demo contains no recorded "
    "Piedmontais voice. Listening examples require a suitable device voice; "
    "availability and pronunciation depend on the device."
)


def text(value: str, role: str = "primary") -> dict:
    return {"role": role, "type": "text", "text": value}


def audio(value: str, role: str = "primary") -> dict:
    return {"role": role, "type": "audio", "text": value}


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
           pictures: list[str] | None = None) -> dict:
    return exercise(kind, prompt, {
        "kind": "select", "minSelections": 1, "maxSelections": 1,
        "items": [
            {"id": f"i{index}", "content": [text(value)] + (
                [image(pictures[index], value, "primary")] if pictures else []
            )} for index, value in enumerate(choices)
        ],
    }, {"kind": "selected_items", "correctItemIds": [f"i{correct}"]})


def enter(kind: str, prompt: list[dict], accepted: list[str], **fields) -> dict:
    return exercise(kind, prompt, {"kind": "input", "inputType": "text"}, {
        "kind": "text_match", **({"acceptedAnswers": accepted} if accepted else {}),
        "normalization": NORMALIZATION.copy(),
    }, **fields)


def arrange(kind: str, prompt: list[dict], blocks: list[str],
            orders: list[list[int]]) -> dict:
    separator = "" if kind == "image_word" else " "
    return exercise(kind, prompt, {
        "kind": "arrange",
        "items": [{"id": f"i{i}", "content": [text(block)]}
                  for i, block in enumerate(blocks)],
    }, {
        "kind": "ordered_items", "correctOrders": [
            {"text": separator.join(blocks[i] for i in order),
             "itemIds": [f"i{i}" for i in order]} for order in orders
        ],
    })


def match(kind: str, instruction: str, pairs: list[tuple[str, str]]) -> dict:
    items = []
    for i, (left, right) in enumerate(pairs):
        items.append({"id": f"i{2 * i}", "content": [
            audio(left) if kind == "audio_match" else text(left)
        ]})
        items.append({"id": f"i{2 * i + 1}", "content": [text(right)]})
    return exercise(kind, [text(instruction)], {"kind": "match", "items": items}, {
        "kind": "matched_items",
        "pairs": [[f"i{2 * i}", f"i{2 * i + 1}"] for i in range(len(pairs))],
    })


def flashcard(term: str, meaning: str, usage: str, translation: str) -> dict:
    return {
        "publicationState": "published", "kind": "presentation", "required": True,
        "editorTemplate": "flashcard", "presentation": {
            "content": [text(term, "term"), text(meaning, "meaning"),
                        text(usage, "usage"), text(translation, "usage_translation"),
                        audio(term, "audio")],
            "completion": {"actions": ["understood", "review_later"]},
        },
    }


def lesson_specs() -> list[tuple[str, str, str, list[dict]]]:
    """Preset ID, teaching topic, GuideBook, authored examples."""
    specs = []

    def add(kind, topic, guide, examples):
        specs.append((kind, topic, guide, examples))

    add("choice", "First words", "pan = bread; gat = cat; eva = water. Choose the Piedmontais word.", [
        choose("choice", [text("How do you say bread in Piedmontais?")], ["pan", "gat", "eva"]),
        choose("choice", [text("How do you say cat in Piedmontais?")], ["can", "gat", "pan"], 1),
        choose("choice", [text("How do you say water in Piedmontais?")], ["pom", "pan", "eva"], 2),
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
    add("listening_choice", "Hear a greeting", "bondì = good morning; mersì = thank you; ciàu = hello or bye. Choose the exact written word you hear. " + AUDIO_NOTE, [
        choose("listening_choice", [text(instruction), audio(heard)], choices, correct)
        for heard, choices, correct, instruction in [
            ("bondì", ["bondì", "mersì", "ciàu"], 0, "Listen to the first greeting."),
            ("mersì", ["ciàu", "mersì", "bondì"], 1, "Listen to the next expression."),
            ("ciàu", ["mersì", "bondì", "ciàu"], 2, "Listen to the final greeting."),
        ]
    ])
    add("listening_comprehension", "Listen for meaning", "I l'hai = I have; i son = I am; a ca = at home; lìber = book; un = one; doi = two; tre = three. Listen to each short passage and answer its English question. " + AUDIO_NOTE, [
        choose("listening_comprehension", [audio("Mi i son a ca. I l'hai un lìber.", "passage"), text("What does the speaker have?", "question")], ["a book", "a dog", "an apple"]),
        choose("listening_comprehension", [audio("I l'hai un gat e un can.", "passage"), text("Which two animals are mentioned?", "question")], ["a cat and a horse", "a cat and a dog", "a dog and a horse"], 1),
        choose("listening_comprehension", [audio("La lista: pan, eva e tre pom.", "passage"), text("How many apples are on the list?", "question")], ["one", "two", "three"], 2),
    ])
    add("reading_comprehension", "Read a short note", "la lista = the list; pan = bread; eva = water; pom = apple; gat = cat; can = dog; lìber = book; a ca = at home.", [
        choose("reading_comprehension", [text("La lista: pan, eva e tre pom.", "passage"), text("Which drink is on the list?", "question")], ["water", "coffee", "milk"]),
        choose("reading_comprehension", [text("I l'hai un gat e un can.", "passage"), text("How many kinds of animal does the speaker have?", "question")], ["one", "two", "three"], 1),
        choose("reading_comprehension", [text("Mi i son a ca. I l'hai un lìber.", "passage"), text("Where is the speaker?", "question")], ["at school", "at the station", "at home"], 2),
    ])
    add("dialogue_response", "Reply politely", "bondì = good morning; grassie = thank you; prego = you are welcome; bon-aneuit = good night. The situation determines the reply.", [
        choose("dialogue_response", [text("Anna: Bondì!", "passage"), text("It is morning. Return Anna's greeting.", "question")], ["Bondì!", "Bon-aneuit!"]),
        choose("dialogue_response", [text("Anna: Grassie!", "passage"), text("Anna thanks you. Choose you are welcome.", "question")], ["Bon-aneuit!", "Prego!"], 1),
        choose("dialogue_response", [text("Anna: Bon-aneuit!", "passage"), text("You are going to bed. Return the good-night wish.", "question")], ["Bon-aneuit!", "Bondì!"]),
    ])
    context_examples = []
    for first, second, question, choices, correct in [
        ("I l'hai un gat.", "I l'hai un can.", "Who has a dog?", ["Anna", "Tòni"], 1),
        ("I l'hai un lìber.", "I l'hai un pom.", "Who has a book?", ["Anna", "Tòni"], 0),
        ("Grassie!", "Prego!", "What is Tòni doing?", ["Saying good night", "Replying to thanks"], 1),
    ]:
        turns = [dict(text(first, "dialogue_turn"), speaker="Anna"),
                 dict(text(second, "dialogue_turn"), speaker="Tòni")]
        context_examples.append(choose("contextual_comprehension", turns + [text(question, "question")], choices, correct))
    add("contextual_comprehension", "Who said it", "Read the two speakers' words. I l'hai means I have. Keep track of who owns the object or responds to the other speaker.", context_examples)
    add("type_translation", "Write in Piedmontais", "Translate English into Piedmontais. Thank you accepts grassie or mersì. The happy speaker is masculine: i son content; mi is optional. The house is la ca.", [
        enter("type_translation", [text("thank you")], ["grassie", "mersì"]),
        enter("type_translation", [text("I am happy. (masculine speaker)")], ["{mi} i son content"]),
        enter("type_translation", [text("the house")], ["la ca"]),
    ])
    add("build_translation", "Translate with blocks", "Build an English phrase in Piedmontais. ël lìber = the book; i son content = I am happy (masculine); pan e eva = bread and water. For I am happy, both mi i son content and i son content are accepted.", [
        arrange("build_translation", [text("the book")], ["lìber", "la", "ël"], [[2, 0]]),
        arrange("build_translation", [text("I am happy. (masculine speaker)")], ["content", "mi", "son", "i"], [[1, 3, 2, 0], [3, 2, 0]]),
        arrange("build_translation", [text("bread and water")], ["eva", "pan", "e"], [[1, 2, 0]]),
    ])
    add("translation_choice_to_target", "English to Piedmontais", "Read the English source and pick its Piedmontais translation. ël can = the dog; ross = red; tre = three.", [
        choose("translation_choice_to_target", [text("the dog", "question")], ["ël can", "ël gat", "ël pan"]),
        choose("translation_choice_to_target", [text("red", "question")], ["nèir", "ross", "bianch"], 1),
        choose("translation_choice_to_target", [text("three", "question")], ["un", "doi", "tre"], 2),
    ])
    add("translation_choice_to_source", "Piedmontais to English", "Read the Piedmontais source and pick its English meaning. bon-aneuit = good night; ël pan = the bread; mi i son content = I am happy.", [
        choose("translation_choice_to_source", [text("bon-aneuit", "question")], ["good night", "good morning", "thank you"]),
        choose("translation_choice_to_source", [text("ël pan", "question")], ["the dog", "the bread", "the house"], 1),
        choose("translation_choice_to_source", [text("mi i son content", "question")], ["I have a book", "I am at home", "I am happy"], 2),
    ])
    add("fill_blank", "Complete a phrase", "Type only the missing word. ël lìber = the book; la ca = the house; pan e eva = bread and water. Preserve the accent in lìber.", [
        enter("fill_blank", [text("ël ___")], ["lìber"], hint="Complete the book."),
        enter("fill_blank", [text("la ___")], ["ca"], hint="Complete the house."),
        enter("fill_blank", [text("pan e ___")], ["eva"], hint="Complete bread and water."),
    ])
    add("type_missing_word", "First-letter help", "Complete each missing word after its first letter is shown. Enter the whole word: gat (cat), ca (house), or lìber (book), including the first letter.", [
        enter("type_missing_word", [text("I l'hai un ___.")], ["gat"], hint="The animal that meows."),
        enter("type_missing_word", [text("la ___")], ["ca"], hint="The place where you live."),
        enter("type_missing_word", [text("ël ___")], ["lìber"], hint="An object with pages to read."),
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
    add("matching", "Everyday pairs", "Match each English meaning with its Piedmontais phrase. Pair relationships stay the same when the display is shuffled.", [
        match("matching", "Match each greeting with its English meaning.", [("bondì", "good morning"), ("bon-aneuit", "good night"), ("grassie", "thank you")]),
        match("matching", "Match each Piedmontais phrase with its English meaning.", [("ël lìber", "the book"), ("la ca", "the house"), ("ël can", "the dog")]),
        match("matching", "Match each Piedmontais colour with its English meaning.", [("ross", "red"), ("nèir", "black"), ("bianch", "white")]),
    ])
    add("word_match", "Three translations", "Match English words with Piedmontais words. Food: pan, eva, pom. Animals: gat, can, caval. At home: tàula, cadrega, pòrta.", [
        match("word_match", f"Match English {topic} words to Piedmontais.", pairs)
        for topic, pairs in [
            ("food and drink", [("bread", "pan"), ("water", "eva"), ("apple", "pom")]),
            ("animal", [("cat", "gat"), ("dog", "can"), ("horse", "caval")]),
            ("household", [("table", "tàula"), ("chair", "cadrega"), ("door", "pòrta")]),
        ]
    ])
    add("super_match", "Related Piedmontais words", "Follow the relationship named in each exercise. Opposites: càud/frèid (hot/cold), nèir/bianch (black/white), grand/cit (big/small). Plurals: ël lìber/ij lìber, la ca/le ca, la cadrega/le cadreghe. Articles: ël gat, la ca, ël lìber.", [
        match("super_match", "Match the Piedmontais opposites.", [("càud", "frèid"), ("nèir", "bianch"), ("grand", "cit")]),
        match("super_match", "Match each singular phrase to its plural.", [("ël lìber", "ij lìber"), ("la ca", "le ca"), ("la cadrega", "le cadreghe")]),
        match("super_match", "Match each noun to the same noun with its definite article.", [("gat", "ël gat"), ("ca", "la ca"), ("lìber", "ël lìber")]),
    ])
    add("audio_match", "Match what you hear", "Play each Piedmontais item and match it to the English meaning. Each exercise has three unique audio/text pairs and no distractors. " + AUDIO_NOTE, [
        match("audio_match", f"Match each spoken Piedmontais {topic} word to its English meaning.", pairs)
        for topic, pairs in [
            ("food or drink", [("pan", "bread"), ("eva", "water"), ("pom", "apple")]),
            ("animal", [("gat", "cat"), ("can", "dog"), ("caval", "horse")]),
            ("colour", [("ross", "red"), ("nèir", "black"), ("bianch", "white")]),
        ]
    ])
    add("word_order", "Put words in order", "Restore the Piedmontais phrase. Keep i before son. A repeated ël needs its own block each time. These are ordering exercises; no English sentence is being translated.", [
        arrange("word_order", [text("Put the speaker, verb and description in order.", "clue")], ["content", "son", "mi", "i"], [[2, 3, 1, 0]]),
        arrange("word_order", [text("Put the food first, then the link, then the drink.", "clue")], ["eva", "e", "pan"], [[2, 1, 0]]),
        arrange("word_order", [text("Put the cat first and the dog second, with an article before each.", "clue")], ["can", "ël", "e", "gat", "ël"], [[1, 3, 2, 4, 0]]),
    ])
    add("image_word", "Build pictured words", "Use every letter to spell the Piedmontais word in the picture: pan (bread), gat (cat), caval (horse). The two a letters in caval are separate blocks.", [
        arrange("image_word", [text(instruction, "clue"), image(asset, alternative)], blocks, [order])
        for asset, alternative, blocks, order, instruction in [
            ("bread", "Bread", ["n", "p", "a"], [1, 2, 0], "Spell the pictured food in Piedmontais."),
            ("cat", "A cat", ["t", "g", "a"], [1, 2, 0], "Spell the pictured pet in Piedmontais."),
            ("horse", "A horse", ["a", "l", "c", "a", "v"], [2, 0, 4, 3, 1], "Spell the pictured farm animal in Piedmontais."),
        ]
    ])
    add("flashcard", "Remember useful words", "Read each term, meaning and example. Choose Got it or Review again. Flashcards do not award ordinary correct-answer XP. Pronunciation is optional and depends on the device. " + AUDIO_NOTE, [
        flashcard("lìber", "book", "I l'hai un lìber.", "I have a book."),
        flashcard("grassie", "thank you", "Grassie, Anna!", "Thank you, Anna!"),
        flashcard("eva", "water", "pan e eva", "bread and water"),
    ])
    return specs


def build_course() -> dict:
    registry = (ROOT / "lib/models/exercise_authoring.dart").read_text(encoding="utf-8")
    registry_pairs = re.findall(r"id: '([^']+)',\s+name: '([^']+)'", registry)
    specs = lesson_specs()
    assert [spec[0] for spec in specs] == [pair[0] for pair in registry_pairs], (
        "Preset registry changed: review the demo's authored Lesson coverage."
    )
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
        "officialCourseVersion": "1.0.0", "officialReleaseDateUtc": STAMP,
        "officialReleaseNotes": "QQL Build 254: English-to-Piedmontais AI-Slop Demo with one Lesson per current named exercise type.",
        "distributionChannel": "bundled", "publisherVerificationStatus": "verified",
        "originalCourseCreator": {"type": "publisher", "id": "org.quisquislingo", "displayName": "QuisquisLingo"},
        "originalCreatedAtUtc": STAMP, "modifiedAtUtc": STAMP,
        "learningLanguage": "Piedmontais", "interfaceLanguage": "English",
        "sourceLanguage": "English", "targetLanguage": "Piedmontais",
        "title": "AI-Slop Demo: Piedmontais", "ttsLanguage": "pms-IT", "audioMode": "tts",
        "authors": [{"name": "OpenAI Codex (AI-generated sample; not linguistically reviewed)", "roles": ["Author"]}],
        "license": "All rights reserved",
        "derivativeWorksPolicy": "allowed",
        "mediaAttributions": [{
            "author": "OpenAI Codex",
            "license": "Original code-rendered letter diagrams for this temporary sample",
            "title": "Accented Piedmontais letters",
            "source": "tools/generate_piedmontais_demo_254.py glyph_png",
            "appliesTo": "The three embedded character-recognition PNGs: ë, é and ò",
        }],
        "languageVariant": "Piedmontese literary spelling; introductory AI-authored examples awaiting native-speaker review",
        "startLevel": "Beginner", "targetLevel": "Beginner",
        "courseDescription": "TEMPORARY UNREVIEWED AI-GENERATED SAMPLE. English to Piedmontais (Piedmontese), with 24 Lessons demonstrating the 24 current named Exercise types. The content is for testing and requires native-speaker review before language-teaching use. Basic spellings were checked against Claudio Panero's English-Piedmontese dictionary; examples and letter diagrams are newly authored. " + AUDIO_NOTE,
        "sourceLanguageTag": "en-GB", "targetLanguageTag": "pms-IT",
        "textDirection": "ltr", "worldFlagId": "piedmontese", "temporarySample": True,
        "lessons": lessons,
    }
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
        print("PASS: Piedmontais course is reproducible; 24 named types, 24 Lessons, 72 examples")
        return 0
    OUTPUT.write_text(rendered, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}: 24 Lessons, 24 Rounds, 69 Exercises and 3 Flashcards")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
