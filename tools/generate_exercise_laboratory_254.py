#!/usr/bin/env python3
"""Generate the original, deterministic Exercise Laboratory Course (Model v12).

The examples are authored in the v11 shape the presets describe and pass
through tools/qql_course_v12.py, the Python mirror of the Dart mapping, so
the committed file is Course Model v12 (Build 256 Revision 1).

Only this course and its coverage document are written. Existing courses and
media are inputs, never rewritten. --check verifies the committed outputs.
"""
from __future__ import annotations

import argparse
import base64
import copy
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qql_course_v12 import _ordered_evaluation, _ordered_options, assign_exercise, becomes_exercise, before_you_start, complete_text_exercise, page_exercise, convert_course_v11_to_v12, story_cover, story_flow, story_line  # noqa: E402
from qql_course_v12 import guidebook, guidebook_entry, guidebook_module, vocabulary_pair  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/courses/exercise_laboratory_en_it.json"
COVERAGE = ROOT / "docs/254_LABORATORY_COVERAGE.md"
# The test-only fixture of what this version cannot play (Build 256
# Revision 7, plan A.12): the same generator, a Course that is never bundled.
FIXTURE = ROOT / "test/fixtures/v12/laboratory_future_en_it.json"
FUTURE_ID = "course_9b1f6c2e-8d4a-4c3b-9e7f-2a5d6c8b1f04"
# Allocated once with Course.newCourseId(); regeneration retains the identity.
COURSE_ID = "course_50d68435-d2c2-4b63-9a0b-b23161357f1d"
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


def glyph_asset(letter: str, blue: bool = False) -> str:
    """Original 5 x 7 block lettering: a deterministic portable PNG, no fonts.

    This is a small technical character specimen, not an image-bank addition.
    It uses only standard-library PNG encoding and has no external provenance.
    """
    glyphs = {
        "A": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
        "E": ("11111", "10000", "10000", "11110", "10000", "10000", "11111"),
        "È": ("01000", "00100", "00000", "11111", "10000", "10000", "11110", "10000", "10000", "11111"),
    }
    rows = glyphs[letter]
    size, block = 160, 11
    x0, y0 = (size - 5 * block) // 2, (size - len(rows) * block) // 2
    foreground = bytes((25, 75, 150) if blue else (28, 28, 28))
    pixels = bytearray()
    for y in range(size):
        pixels.append(0)  # PNG scanline filter: None.
        for x in range(size):
            gx, gy = (x - x0) // block, (y - y0) // block
            ink = 0 <= gy < len(rows) and 0 <= gx < 5 and rows[gy][gx] == "1"
            pixels.extend(foreground if ink else b"\xff\xff\xff")

    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(pixels), 9))
    png += chunk(b"IEND", b"")
    assert len(png) <= 51_200
    return "data:image/png;base64," + base64.b64encode(png).decode("ascii")


# Build 265 Revision 2 (owner approval of 6 October 2026): each Lesson's
# GuideBook vocabulary, written target = source and taken from the Italian
# the learner can look up in that Lesson (Word Lookup). Mass nouns are
# translated without "the" (bread, milk, water, rice, coffee, espresso).
VOCABULARY: dict[str, list[str]] = {
    "Select": [
        "grazie = thank you",
        "la mela = the apple",
        "rossa = red",
        "il gatto = the cat",
        "dorme = sleeps",
        "il divano = the sofa",
        "il cane = the dog",
        "il caffè = coffee",
        "senza zucchero = without sugar",
        "dolce = sweet",
        "dov'è = where is",
        "la stazione = the station",
        "vicino al parco = near the park",
        "la capitale = the capital",
        "Italia = Italy",
    ],
    "Input": [
        "grazie = thank you",
        "buongiorno = good morning",
        "buonasera = good evening",
        "la mela = the apple",
        "il bambino = the child",
        "felice = happy",
        "domani = tomorrow",
        "a casa = at home",
        "il pane = bread",
        "il latte = milk",
        "l'acqua = water",
        "fredda = cold",
        "vorrei = I would like",
        "un caffè = a coffee",
        "il treno = the train",
    ],
    "Arrange": [
        "bevo = I drink",
        "l'acqua = water",
        "vado = I go",
        "a scuola = to school",
        "il treno = the train",
        "parte = leaves",
        "oggi = today",
        "beve = drinks",
        "mangia = eats",
        "il riso = rice",
        "il pane = bread",
        "legge = reads",
        "il libro = the book",
        "beviamo = we drink",
    ],
    "Match": [
        "ciao = hello",
        "a domani = see you tomorrow",
        "per favore = please",
        "buon viaggio = have a good trip",
        "a presto = see you soon",
        "felice = happy",
        "contento = glad",
        "veloce = fast",
        "rapido = quick",
        "caldo = hot",
        "freddo = cold",
        "aperto = open",
    ],
    "Presentation": [
        "ciao = hello",
        "grazie = thank you",
        "il pane = bread",
        "compro = I buy",
        "buongiorno = good morning",
        "il libro = the book",
        "leggo = I read",
        "il bicchiere = the glass",
        "la mela = the apple",
        "mangio = I eat",
    ],
    "Story": [
        "buongiorno = good morning",
        "un caffè = a coffee",
        "per favore = please",
        "subito = right away",
        "vuole = would you like",
        "anche = also",
        "il cornetto = the croissant",
        "solo = only",
        "ecco = here is",
        "il suo caffè = your coffee",
        "che cosa = what",
        "ordina = orders",
    ],
    "Assign": [
        "il gatto = the cat",
        "il cane = the dog",
        "la rosa = the rose",
        "il pino = the pine",
        "il tavolo = the table",
        "la sedia = the chair",
        "la casa = the house",
        "il libro = the book",
        "l'animale = the animal",
        "la pianta = the plant",
    ],
    "Page": [
        "un caffè = an espresso",
        "il caffè = espresso",
        "il cappuccino = coffee with foamed milk",
        "il macchiato = espresso with a drop of milk",
        "in piedi = standing",
        "al bar = at the bar",
        "il banco = the counter",
        "la cassa = the till",
        "buongiorno = good morning",
        "grazie = thank you",
    ],
}


# Build 266 (GuideBook Modules): each Lesson's GuideBook is one module for
# now, its vocabulary as Words & Expressions and its description as the
# Overview; the module's own name, never the Lesson title.
MODULE_TITLES: dict[str, str] = {
    "Select": "Everyday words",
    "Input": "Greetings and food",
    "Arrange": "Daily actions",
    "Match": "Greetings and opposites",
    "Presentation": "Words on the flashcards",
    "Story": "At the café",
    "Assign": "Animals, plants and things",
    "Page": "At the bar",
}


def lab_guidebook(lesson: dict) -> dict:
    """The Lesson's v12 GuideBook: one module from its v11 content."""
    prefix = lesson["lessonId"]
    content = lesson["guidebook"]["content"]
    overview = next(item["text"] for item in content if item["kind"] == "explanation")
    words = []
    for item in content:
        if item["kind"] != "vocabulary":
            continue
        target, source = vocabulary_pair(item["text"])
        words.append(guidebook_entry(item["id"], target, source))
    return guidebook([guidebook_module(f"{prefix}_module", MODULE_TITLES[lesson["title"]],
                                       words=words, overview=overview)])


class Laboratory:
    def __init__(self) -> None:
        self.lessons: list[dict] = []
        # The Story Lesson (Build 256 Revision 5) stands beside the five
        # primitive Lessons: its Round mixes a cover, lines and exercises of
        # several primitives, and its lines and covers have no v11 shape, so
        # the converter fixture (course_v11) omits it.
        self.story_lessons: list[dict] = []
        # Canonical examples that join a v11 Round in course(), after the
        # content they follow (Build 259 Revision 3); the v11 fixture omits
        # them.
        self.canonical_extras: list[tuple[str, dict]] = []
        self.cases: list[dict] = []
        self.lesson: dict = {}
        self.round: dict = {}

    def start_lesson(self, title: str, description: str) -> None:
        prefix = f"qql_lab254_{title.lower()}"
        self.lesson = {
            "lessonId": prefix, "publicationState": "published", "updatedAt": STAMP,
            "title": title, "section": False,
            "guidebook": {"content": [{
                "id": prefix + "_guide", "publicationState": "published",
                "kind": "explanation", "required": False, "role": "overview",
                "text": description,
            }, *[{
                "id": f"{prefix}_vocab_{number:02d}", "publicationState": "published",
                "kind": "vocabulary", "required": False, "role": "vocabulary", "text": word,
            } for number, word in enumerate(VOCABULARY[title], 1)]]},
            "rounds": [], "duel": {"id": prefix + "_duel", "title": title + " Duel"},
        }
        self.lessons.append(self.lesson)

    def start_round(self, key: str, title: str, intro: str, visual: str = "generic") -> None:
        self.round = {
            "id": "qql_lab254_round_" + key,
            "publicationState": "published", "updatedAt": STAMP,
            "title": title, "visualType": visual,
            "content": [{
                "id": "qql_lab254_intro_" + key, "publicationState": "published",
                "kind": "text", "required": False, "role": "lesson_intro", "text": intro,
            }],
        }
        self.lesson["rounds"].append(self.round)

    def add(self, key: str, preset: str, prompts: list[dict], interaction: dict,
            evaluation: dict, capability: str, answer: str, *, hint: str = "",
            missing: list[str] | None = None) -> dict:
        identity = "qql_lab254_" + key
        # IDs are global in bundled validation, even though runtime Item IDs
        # need only be unique within one exercise.
        remap = {item["id"]: identity + "_" + item["id"] for item in interaction.get("items", [])}
        for item in interaction.get("items", []):
            item["id"] = remap[item["id"]]
        for field in ("correctItemIds",):
            if field in evaluation:
                evaluation[field] = [remap[i] for i in evaluation[field]]
        for order in evaluation.get("correctOrders", []):
            order["itemIds"] = [remap[i] for i in order["itemIds"]]
        if "pairs" in evaluation:
            evaluation["pairs"] = [[remap[i] for i in pair] for pair in evaluation["pairs"]]
        if "gapAssignments" in evaluation:
            evaluation["gapAssignments"] = {gap: remap[i] for gap, i in evaluation["gapAssignments"].items()}
        exercise = {"updatedAt": STAMP, "prompt": prompts,
                    "interaction": interaction, "evaluation": evaluation}
        if hint:
            exercise["hint"] = hint
        if missing:
            exercise["missingWords"] = missing
        content = {"id": identity, "publicationState": "published", "kind": "exercise",
                   "required": True, "editorTemplate": preset, "exercise": exercise}
        self.round["content"].append(content)
        self.cases.append({"id": identity, "lesson": self.lesson["title"],
                           "round": self.round["title"], "preset": preset,
                           "capability": capability, "answer": answer})
        return content

    def choose(self, key: str, preset: str, prompts: list[dict], answers: list[str],
               correct: int, capability: str, *, icons: list[str] | None = None,
               hint: str = "", language: str | None = None,
               images: list[str] | None = None) -> None:
        items = [{"id": f"item_{i}", "content": [text(value, language=language)]}
                 for i, value in enumerate(answers)]
        if icons:
            for item, icon in zip(items, icons, strict=True):
                item["content"].append(text(icon, "icon"))
        if images:
            # Listen and pick the image: a bundled picture per answer, kept as
            # an icon key like Select the image's (the picker writes the same).
            for item, name in zip(items, images, strict=True):
                item["content"].append(text(f"assets/exercise_images/{name}.webp", "icon"))
        self.add(key, preset, prompts,
                 {"kind": "select", "minSelections": 1, "maxSelections": 1, "items": items},
                 {"kind": "selected_items", "correctItemIds": [f"item_{correct}"]},
                 capability, answers[correct], hint=hint)

    def multi(self, key: str, prompt: str, answers: list[str], correct: list[int],
              minimum: int, capability: str) -> None:
        self.add(key, "choice", [text(prompt, "question")],
                 {"kind": "select", "minSelections": minimum, "maxSelections": len(answers),
                  "items": [{"id": f"item_{i}", "content": [text(v)]} for i, v in enumerate(answers)]},
                 {"kind": "selected_items", "correctItemIds": [f"item_{i}" for i in correct]},
                 capability, " + ".join(answers[i] for i in correct))

    def gaps(self, key: str, preset: str, instruction: str, parts: list[str | tuple[str]],
             distractors: list[str], capability: str, *, spoken: str = "") -> None:
        select = preset in ("choice", "gap_choice_inline")
        options: list[str] = []
        layout, assignments, answers = [], {}, []
        for part in parts:
            if isinstance(part, str):
                layout.append(text(part))
            else:
                value = part[0]
                gap_id = f"gap_{len(assignments) + 1}"
                # Select options are reusable; Arrange requires distinct tile
                # occurrences even for the same visible word.
                if not select or value not in options:
                    options.append(value)
                    index = len(options) - 1
                else:
                    index = options.index(value)
                assignments[gap_id] = f"item_{index}"
                answers.append(value)
                layout.append({"role": "primary", "type": "gap", "text": gap_id})
        options.extend(distractors)
        prompts = [text(instruction, "primary" if select or preset == "build_translation" else "clue")]
        if spoken:
            prompts.append(audio(spoken))
        interaction = {"kind": "select" if select else "arrange",
                       "items": [{"id": f"item_{i}", "content": [text(v)]} for i, v in enumerate(options)],
                       "layout": layout}
        if select:
            interaction.update(minSelections=1, maxSelections=1)
        self.add(key, preset, prompts, interaction,
                 {"kind": "selected_items" if select else "ordered_items", "gapAssignments": assignments},
                 capability, " / ".join(answers))

    def enter(self, key: str, preset: str, prompts: list[dict], accepted: list[str],
              capability: str, *, hint: str = "", missing: list[str] | None = None,
              answer: str = "") -> None:
        self.add(key, preset, prompts, {"kind": "input", "inputType": "text"},
                 {"kind": "text_match", "acceptedAnswers": accepted, "normalization": dict(NORMALIZATION)},
                 capability, answer or " / ".join(accepted), hint=hint, missing=missing)

    def arrange(self, key: str, preset: str, prompts: list[dict], tokens: list[str],
                orders: list[list[int]], capability: str, *,
                language: str | None = None, hint: str = "") -> None:
        separator = "" if preset in ("image_word", "spell_heard", "spell_word") else " "
        correct_orders = [{"text": separator.join(tokens[i] for i in order),
                           "itemIds": [f"item_{i}" for i in order]} for order in orders]
        self.add(key, preset, prompts,
                 {"kind": "arrange", "items": [{"id": f"item_{i}", "content": [text(v, language=language)]}
                                               for i, v in enumerate(tokens)]},
                 {"kind": "ordered_items", "correctOrders": correct_orders},
                 capability, " / ".join(order["text"] for order in correct_orders), hint=hint)

    def match(self, key: str, preset: str, instruction: str, pairs: list[tuple[str, str]], capability: str, *,
              left_images: bool = False) -> None:
        items = []
        for index, (left, right) in enumerate(pairs):
            left_content = (
                audio(left) if preset == "audio_match"
                else image(left, right, "primary") if left_images
                else text(left)
            )
            items.extend([
                {"id": f"item_{index * 2}", "content": [left_content]},
                {"id": f"item_{index * 2 + 1}", "content": [text(right)]},
            ])
        self.add(key, preset, [text(instruction)], {"kind": "match", "items": items},
                 {"kind": "matched_items", "pairs": [[f"item_{i * 2}", f"item_{i * 2 + 1}"] for i in range(len(pairs))]},
                 capability, "; ".join(f"{left} = {right}" for left, right in pairs))

    def card(self, key: str, term: str, meaning: str, capability: str, *,
             usage: str = "", translation: str = "", spoken: str = "",
             preset: str = "flashcard", picture: str = "") -> None:
        elements = [text(term, "term"), text(meaning, "meaning")]
        if spoken:
            # A Flashcard's read-aloud is optional: never an audio exercise
            # (Build 256 Revision 7 follow-up: the plain Flashcard too).
            elements.append(audio(spoken, "audio", required=False))
        if usage:
            elements.append(text(usage, "usage"))
        if translation:
            assert usage
            elements.append(text(translation, "usage_translation"))
        if picture:
            elements.append(image(picture, term, "picture"))
        identity = "qql_lab254_" + key
        self.round["content"].append({
            "id": identity, "publicationState": "published", "kind": "presentation",
            "required": True, "editorTemplate": preset,
            "presentation": {"content": elements, "completion": {
                # A Note card is read and left with Continue.
                "actions": ["continue"] if preset == "note_card" else ["understood", "review_later"]}},
        })
        self.cases.append({"id": identity, "lesson": self.lesson["title"], "round": self.round["title"],
                           "preset": preset, "capability": capability,
                           "answer": "Got it; or Review again, then Got it on the repeated card"})

    def complete_text_canonical(self, key: str, after: str, text: str, answers: list[str],
                                capability: str, answer: str, *, instruction: str = "",
                                hint: str = "") -> None:
        """Complete the text with an answer expression per gap (Build 259
        Revision 3): the v11 shape cannot express alternatives, so the example
        joins its Round in the canonical shape, after `after`."""
        identity = "qql_lab254_" + key
        self.canonical_extras.append(("qql_lab254_" + after, {
            "id": identity, "publicationState": "published", "kind": "exercise",
            "required": True, "editorTemplate": "complete_text",
            "exercise": complete_text_exercise(text, answers, updated_at=STAMP,
                                               instruction=instruction, hint=hint),
        }))
        self.cases.append({"id": identity, "lesson": self.lesson["title"], "round": self.round["title"],
                           "preset": "complete_text", "capability": capability, "answer": answer})

    def start_story_lesson(self, title: str, description: str) -> None:
        self.start_lesson(title, description)
        self.story_lessons.append(self.lessons.pop())

    def start_canonical_lesson(self, title: str, description: str) -> None:
        """A Lesson whose exercises exist only in the canonical shape (no v11
        recipe): it joins the Course after the v11 conversion, as the Story
        Lesson does (Build 256 Revision 7: Assign)."""
        self.start_story_lesson(title, description)

    def assign(self, key: str, preset: str, mode: str, question: str, items: list[tuple[str, str]],
               targets: list[tuple[str, str]], assignments: dict[str, list[str]],
               capability: str, answer: str, *, capacity: str = "single",
               reuse: str = "forbidden", sentence: list | None = None) -> None:
        """An Assign example (Build 256 Revision 7), authored in the canonical
        shape with global item and target IDs; since the Revision 7
        follow-up it carries its preset (Sort into groups, Fill the slots),
        whose recipe represents it."""
        identity = "qql_lab254_" + key
        item_ids = {item_id: f"{identity}_{item_id}" for item_id, _ in items}
        target_ids = {target_id: f"{identity}_{target_id}" for target_id, _ in targets}
        exercise = assign_exercise(
            updated_at=STAMP, mode=mode, instruction=question,
            items=[(item_ids[i], text) for i, text in items],
            targets=[(target_ids[t], label) for t, label in targets],
            assignments={target_ids[t]: [item_ids[i] for i in ids] for t, ids in assignments.items()},
            capacity=capacity, reuse=reuse,
            sentence=None if sentence is None else [
                (target_ids[part[0]],) if isinstance(part, tuple) else part for part in sentence],
        )
        self.round["content"].append({
            "id": identity, "publicationState": "published", "kind": "exercise",
            "required": True, "editorTemplate": preset, "exercise": exercise,
        })
        self.cases.append({"id": identity, "lesson": self.lesson["title"], "round": self.round["title"],
                           "preset": preset, "capability": capability, "answer": answer})

    def page(self, key: str, blocks: list[dict], capability: str) -> None:
        """A Page example (Build 258 Revision 3): canonical content carrying
        the Page preset, whose recipe represents it."""
        identity = "qql_lab254_" + key
        self.round["content"].append({
            "id": identity, "publicationState": "published", "kind": "exercise",
            "required": True, "editorTemplate": "page",
            "exercise": page_exercise(blocks, updated_at=STAMP),
        })
        self.cases.append({"id": identity, "lesson": self.lesson["title"], "round": self.round["title"],
                           "preset": "page", "capability": capability, "answer": "Continue"})

    def start_story(self, key: str, title: str, intro: str, story_title: str, *,
                    read_aloud: str = "automatic") -> None:
        """A Story Round: scrolling, dialogue-only log; finish_story writes
        the flow once every step is added."""
        self.start_round(key, title, intro, "story")
        self.round["story"] = {"title": story_title, "readAloud": read_aloud, "requiresAudio": []}

    def _story_entry(self, key: str, preset: str, exercise: dict, capability: str) -> None:
        identity = "qql_lab254_" + key
        self.round["content"].append({
            "id": identity, "publicationState": "published", "kind": "exercise",
            "required": True, "editorTemplate": preset, "exercise": exercise,
        })
        self.cases.append({"id": identity, "lesson": self.lesson["title"], "round": self.round["title"],
                           "preset": preset, "capability": capability, "answer": "Continue"})

    def cover(self, key: str, picture: str, alternative: str, title_line: str, capability: str) -> None:
        self._story_entry(key, "story_cover", story_cover(
            updated_at=STAMP, picture=f"assets/exercise_images/{picture}.webp",
            alternative=alternative, title_line=title_line), capability)

    def line(self, key: str, line: str, capability: str, *, speaker: str = "",
             language: str | None = None, mode: str = "both", read_aloud: str = "story",
             text_reveal: str = "immediate") -> None:
        self._story_entry(key, "dialogue_line", story_line(
            line, updated_at=STAMP, speaker_id=speaker, language=language, mode=mode,
            read_aloud=read_aloud, text_reveal=text_reveal), capability)

    def needs_audio(self, key: str) -> None:
        self.round["story"]["requiresAudio"].append("qql_lab254_" + key)

    def finish_story(self) -> None:
        story = self.round.pop("story")
        self.round["flow"] = story_flow(
            [(content["id"], becomes_exercise(content)) for content in self.round["content"]],
            title=story["title"], read_aloud=story["readAloud"],
            requires_audio=set(story["requiresAudio"]))


def laboratory() -> Laboratory:
    lab = Laboratory()
    lab.start_lesson("Select", "Choose an answer, select a complete set, or fill fixed gaps with reusable options. The Rounds also demonstrate images, characters, reading, dialogue, listening and both translation directions. Listening needs Enable Audio Exercises and Text-to-speech in Audio Settings; Preview ignores those learner switches.")
    lab.start_round("select_basics", "Single and multiple answers", "Read the instruction carefully. Single-answer questions check immediately. Multiple-answer questions wait for Check; select every correct option and no distractor.")
    lab.choose("select_single", "choice", [text("How do you say ‘thank you’ in Italian?", "question")], ["grazie", "prego"], 0, "Single selection; two text options; immediate feedback")
    lab.choose("select_image_prompt", "choice", [text("How do you say ‘the apple’ in Italian?", "question"), image("apple", "An apple")], ["la mela", "il pane", "il latte"], 0, "Single selection with a supplementary prompt image")
    lab.multi("select_multiple", "Which words are Italian colours? Select all correct answers.", ["rosso", "blu", "pane", "libro"], [0, 1], 2, "Multiple selection; exact correct set; minimum equals two correct answers")
    lab.multi("select_minimum", "Which words name an animal? Select all correct answers.", ["gatto", "cane", "casa", "sole"], [0, 1], 1, "Multiple selection; minimum one permits partial submission but only the exact two-answer set is correct")
    lab.multi("select_one_in_multi", "Which word means ‘yes’? Select the correct answer, then press Check.", ["sì", "no", "mai"], [0], 1, "Multiple-selection presentation with one correct answer and an explicit Check")

    lab.start_round("select_gaps", "One missing word, one word for all gaps", "In Pick the missing word, choose the one missing expression. In One word fills all, one word fits every gap: choose it once and it appears in each gap.")
    lab.choose("select_gap_preset", "gap_choice", [text("Il gatto ___ sul divano.", "question")], ["dorme", "dormono", "dormire"], 0, "Fill in the blank preset; one ___ gap and non-revealing hint", hint="The subject is one animal.")
    # One word fills all (Build 259 Revision 4) replaces the reusable-option
    # gaps, which joined Pick the words for the gaps (gap_blocks).
    lab.choose("select_gap_all_article", "one_word_fills_all", [text("___ gatto dorme. ___ cane mangia.", "question")], ["Il", "La", "Lo"], 0, "One word fills all; one article for two gaps")
    lab.choose("select_gap_all_verb", "one_word_fills_all", [text("Anna ___ un caffè. Luca ___ un tè.", "question")], ["beve", "bevo", "bevono"], 0, "One word fills all; one verb form for two gaps and a hint", hint="Both subjects are one person.")

    lab.start_round("select_visual", "Images and written characters", "Match words to pictures, then inspect the printed characters. Character images are original portable PNG specimens. Image choices check immediately.")
    lab.choose("select_named_icons", "icon_choice", [text("Select ‘sole’.", "question")], ["sole", "luna", "albero"], 0, "Select the image; existing named icon vocabulary", icons=["sun", "moon", "tree"])
    lab.choose("select_asset_options", "icon_choice", [text("Select ‘gatto’.", "question")], ["gatto", "cane", "uccello"], 0, "Select the image; actual bundled image options", icons=[f"assets/exercise_images/{name}.webp" for name in ("cat", "dog", "bird")])
    for key, glyphs, options, capability in [
        ("script_image_text", [("A", False)], ["A", "E", "È"], "Recognize characters; one portable image to text"),
        ("script_multiple_images", [("E", False), ("E", True)], ["E", "A", "È"], "Recognize characters; two visual specimens of the same character to text"),
    ]:
        prompts = [text("Select the character shown." if len(glyphs) == 1 else "Select the character shown in both specimens.")]
        prompts += [{"role": "clue", "type": "image", "asset": glyph_asset(letter, blue), "text": "Printed character specimen"} for letter, blue in glyphs]
        lab.choose(key, "script_recognition", prompts, options, 0, capability)
    lab.add("script_text_image", "script_recognition", [text("Select the image of È (E with a grave accent).", "question")],
            {"kind": "select", "minSelections": 1, "maxSelections": 1,
             "items": [{"id": f"item_{i}", "content": [{"role": "primary", "type": "image", "asset": glyph_asset(letter)}]} for i, letter in enumerate(("E", "È", "A"))]},
            {"kind": "selected_items", "correctItemIds": ["item_1"]},
            "Recognize characters; text to image-only options; Italian accented character", "Image È")

    lab.start_round("select_context", "Read and answer", "Read the situation, written in English, and the Italian dialogue, then answer in Italian. Some dialogues are read aloud line by line, automatically or with Play dialogue.", "story")
    lab.choose("reading_situation", "reading_answer_target", [text("You meet your neighbour Anna in the evening.", "context", "source"), text("Che cosa dici?", "question")], ["Buonasera!", "Buongiorno!", "Buonanotte!"], 0, "Read and answer; a situation in the source language, no dialogue")
    lab.choose("reading_dialogue", "reading_answer_target", [text("Anna and Luca are in the kitchen.", "context", "source"), image("apple", "An apple", "context"), *turn("Vuoi una mela?", "Anna"), *turn("Sì, grazie.", "Luca"), text("Che cosa accetta Luca?", "question")], ["Un frutto.", "Un libro.", "Un caffè."], 0, "Read and answer; situation, dialogue lines and an image, no read-aloud")
    lab.choose("reading_dialogue_automatic", "reading_answer_target", [text("Anna and Luca talk after lunch.", "context", "source"), *turn("Vuoi un caffè?", "Anna", "automatic"), *turn("Sì, senza zucchero.", "Luca", "automatic"), text("Il caffè di Luca è dolce?", "question")], ["No, è amaro.", "Sì, è molto dolce.", "Sì, con il miele."], 0, "Read and answer; the dialogue read aloud automatically, line by line")
    lab.choose("reading_dialogue_manual", "reading_answer_target", [*turn("Dov'è la stazione?", "Anna", "manual"), *turn("È vicino al parco.", "Luca", "manual"), text("La stazione è lontana?", "question")], ["No, non è lontana.", "Sì, è molto lontana.", "È in un'altra città."], 0, "Read and answer; dialogue lines only, read aloud on request")

    lab.start_round("select_listening", "Listening", "Enable Audio Exercises and Text-to-speech to practise every item here. Use the replay control as needed. Listen for meaning as well as for individual words.", "listening")
    lab.choose("select_listening_word", "listening_choose_target", [audio("Buongiorno."), text("Choose the greeting you hear.")], ["Buongiorno.", "Buonasera.", "Buonanotte."], 0, "Listen and choose (to target); audio prompt, an instruction and written answers")
    lab.choose("select_listening_passage", "listening_comprehension", [audio("Maria compra due mele e un chilo di pane al mercato.", "passage"), text("Dove fa la spesa Maria?", "question")], ["Al mercato.", "A scuola.", "In stazione."], 0, "Listen and choose; passage audio and separate question")

    lab.start_round("select_translation", "Two translation directions", "Read the language named in the instruction. QQL supplies the instruction for each direction. Pronunciation is optional; these questions remain available with Audio Exercises off.")
    lab.choose("translation_target_two", "translation_choice_to_target", [text("Good morning.", "question")], ["Buongiorno.", "Buonanotte."], 0, "Pick translation to target; minimum two answers; no image")
    lab.choose("translation_target_five", "translation_choice_to_target", [text("The cat is sleeping.", "question"), image("cat", "A cat")], ["Il gatto dorme.", "Il cane dorme.", "Il gatto mangia.", "Il gatto corre.", "Il gatto beve."], 0, "Pick translation to target; maximum five answers; optional image")
    lab.choose("translation_source_two", "translation_choice_to_source", [text("Grazie.", "question")], ["Thank you.", "Goodbye."], 0, "Pick translation to source; minimum two answers; no image")
    lab.choose("translation_source_five", "translation_choice_to_source", [text("La mela è rossa.", "question"), image("apple", "An apple")], ["The apple is red.", "The apple is green.", "The pear is red.", "The apple is small.", "The apple is yellow."], 0, "Pick translation to source; maximum five answers; optional image")

    lab.start_round("select_source", "Source-language answers, pictures and true or false", "These Select exercises answer in the source language or with pictures: Choose the answer (to source), True or false, Listen and choose (to source), Listen and answer (to source), What is in the picture and Listen and pick the image.")
    lab.choose("choice_source_meaning", "choice_source", [text("What does “grazie” mean?", "question", "source")], ["thank you", "please", "sorry"], 0, "Choose the answer (to source); question and answers in the source language", language="source")
    lab.choose("choice_source_culture", "choice_source", [text("When do Italians say “buonasera”?", "question", "source")], ["From the afternoon on", "Only at night", "Only in the morning"], 0, "Choose the answer (to source); a culture question", language="source")
    lab.choose("true_false_true", "true_false", [text("Roma è la capitale d’Italia.", "question")], ["True", "False"], 0, "True or false; a true statement, answers in the source language", language="source")
    lab.choose("true_false_spoken", "true_false", [text("Il gatto è un frutto.", "question"), audio("Il gatto è un frutto.")], ["True", "False"], 1, "True or false; a spoken false statement", language="source")
    lab.choose("listening_source", "listening_choose_source", [audio("Grazie mille!"), text("What did you hear?")], ["Thank you very much", "Good night", "See you soon"], 0, "Listen and choose (to source); an instruction, answers in the source language", language="source")
    lab.choose("listening_source_question", "listening_answer_source", [audio("Il treno per Roma parte alle nove.", "passage"), text("When does the train leave?", "question", "source")], ["At nine", "At ten", "At noon"], 0, "Listen and answer (to source); a source-language question about a passage", language="source")
    lab.choose("picture_choice", "picture_choice", [text("What is this?"), image("apple", "An apple", "picture")], ["la mela", "la pera", "il pane"], 0, "What is in the picture; picture prompt, text answers")
    lab.choose("listening_image", "listening_image_choice", [audio("il gatto")], ["il gatto", "il cane", "il cavallo"], 0, "Listen and pick the image; captioned picture answers", images=["cat", "dog", "horse"])

    lab.start_lesson("Input", "Type a translation, a missing fragment, a complete word, or a transcription. Accepted answers can include optional wording and alternatives. Accents are preserved; ordinary capitalization, punctuation and spacing are normalized. Only Type the translation and Type the missing word tolerate one omitted or duplicated repeated letter.")
    lab.start_round("input_answers", "Translations and accepted variants", "Type a natural Italian translation. These examples demonstrate several ways an author can record equivalent answers; the answer notation is never shown as the learner prompt.")
    lab.enter("input_literal", "type_translation", [text("Thank you.")], ["grazie"], "One literal accepted translation")
    lab.enter("input_explicit", "type_translation", [text("Hello.")], ["ciao", "salve", "buongiorno"], "Multiple explicit accepted translations and ranked feedback")
    lab.enter("input_optional", "type_translation", [text("I eat an apple.")], ["{io} mangio una mela"], "Optional subject with {...}", answer="mangio una mela / io mangio una mela")
    lab.enter("input_alternatives", "type_translation", [text("The child is happy.")], ["il [bambino|bimbo] è [felice|contento]"], "Independent [a|b] groups; four grammatical variants", answer="il bambino è felice; il bimbo è contento; both other noun/adjective combinations")
    lab.enter("input_linked", "type_translation", [text("The teacher is tired. (The teacher may be a man or a woman.)")], ["[*:il maestro|la maestra] è [*:stanco|stanca]"], "Linked [*:a|b] groups preserve grammatical agreement", answer="il maestro è stanco / la maestra è stanca")
    lab.start_round("input_ordered_variants", "Flexible wording and written detail", "Translate the complete sentence. Several natural word orders may be accepted. Keep accents and apostrophes, and check repeated letters when you type.")
    lab.enter("input_reorder", "type_translation", [text("I am going to Rome tomorrow.")], ["domani <> vado a Roma"], "Whole-answer reorder with <>; proper name retained", answer="domani vado a Roma / vado a Roma domani")
    lab.enter("input_scoped", "type_translation", [text("I study at home in the evening.")], ["studio (a casa <> la sera)"], "Scoped reorder inside fixed text", answer="studio a casa la sera / studio la sera a casa")
    lab.enter("input_combined", "type_translation", [text("Today I buy bread and milk.")], ["{io} [compro|acquisto] pane e latte oggi", "oggi <> compro pane e latte"], "Optional wording plus independent alternative; separate reordered expression", answer="compro pane e latte oggi / io acquisto pane e latte oggi / oggi compro pane e latte")
    lab.enter("input_accents", "type_translation", [text("The water is cold.")], ["l'acqua è fredda."], "Apostrophe, Italian accent and final punctuation; non-revealing hint", hint="Use the contracted definite article before acqua.")
    lab.enter("input_repeat_letter", "type_translation", [text("The cat is small.")], ["il gatto è piccolo"], "Repeated-letter tolerance applies only to the established Input presets", answer="il gatto è piccolo; one omitted/duplicated repeated letter is tolerated by existing evaluation")

    lab.start_round("input_gaps", "Fragments and first letters", "Type the missing text. Type the missing word gives the first letter as a hint and still expects the complete word. A phrase with pronunciation audio also accepts its complete spoken form.")
    lab.enter("input_fragment", "fill_blank", [text("Buona____", "question")], ["sera"], "Type a missing word; fragment answer without audio", hint="An evening greeting.")
    lab.enter("input_fragment_audio", "fill_blank", [text("Buon____", "question"), audio("Buongiorno")], ["giorno"], "Type a missing word; audio supplements the clue and accepts a literal full phrase", answer="giorno / buongiorno")
    lab.enter("input_gap_variants", "fill_blank", [text("Il bambino è ___.", "question")], ["[felice|contento]"], "Type a missing word; accepted-answer expression", hint="Choose an adjective meaning happy.", answer="felice / contento")
    lab.enter("input_first_letter", "type_missing_word", [text("Il ___ miagola.")], ["gatto"], "Type the missing word; one ___ gap and full accepted word", hint="Think of a common household animal.")
    lab.enter("input_first_alternatives", "type_missing_word", [text("In fattoria vive un ___.")], ["cane", "cavallo"], "Type the missing word; multiple complete words sharing the first grapheme", hint="One barks; you can ride the other.")
    # Build 259 Revision 8 (owner review): an Italian proper name; the
    # French names were not about Italian.
    lab.enter("input_first_unicode", "type_missing_word", [text("Il David di Michelangelo è a ___.")], ["Firenze"], "Type the missing word; a proper name with its capital first letter", hint="The capital of Tuscany.")

    lab.start_round("input_listening", "Transcriptions and missing words", "Enable Audio Exercises and Text-to-speech. For a transcription, type the whole utterance. For missing words, complete the numbered fields in transcript order.", "listening")
    # Build 259 Revision 3: the Audio text is always accepted; other
    # spellings are listed only when there is one.
    lab.enter("input_listen_word", "listening_spelling", [audio("Grazie.")], [], "Type what you hear; one word, the Audio text is the answer", answer="Grazie.")
    lab.enter("input_listen_sentence", "listening_spelling", [text("Type the sentence about the train."), audio("Il treno parte alle nove.")], [], "Type what you hear; complete sentence and normal punctuation handling", answer="Il treno parte alle nove.")
    lab.enter("input_listen_variants", "listening_spelling", [text("Anna tells you when she arrives."), audio("Arrivo alle otto.")], ["arrivo alle 8"], "Type what you hear; another accepted spelling (the hour in digits)", answer="Arrivo alle otto. / arrivo alle 8")
    lab.enter("input_missing_one", "missing_word", [text("Anna mangia una mela."), audio("Anna mangia una mela.")], ["mela"], "Listen for missing words; one transcript gap", missing=["mela"])
    lab.enter("input_missing_many", "missing_word", [text("Luca legge un libro in giardino."), audio("Luca legge un libro in giardino.")], ["legge", "libro", "giardino"], "Listen for missing words; three distinct gaps in transcript order", missing=["legge", "libro", "giardino"], answer="1 legge; 2 libro; 3 giardino")

    lab.start_round("input_source_and_pictures", "Source answers, texts and pictures", "Type the translation (to source) takes a source-language translation. Complete the text and Missing letters are typed gaps without and with letters inside words. Name what you see names a picture.")
    lab.enter("type_source_literal", "type_translation_to_source", [text("Grazie.", language="target")], ["thank you", "thanks"], "Type the translation (to source); target text, source answers")
    lab.enter("type_source_variants", "type_translation_to_source", [text("Vorrei un caffè.", language="target")], ["I would like a coffee", "I'd like a coffee"], "Type the translation (to source); two accepted answers")
    lab.enter("complete_text", "complete_text", [text("Anna's morning before work.", "clue"), text("Anna beve un caffè al bar. Poi prende il treno.")], [], "Complete the text; two typed gaps, an instruction and a hint, no audio", hint="What Italians call an espresso; then a way to travel by rail between towns.", missing=["caffè", "treno"], answer="caffè / treno")
    lab.complete_text_canonical("complete_text_alternatives", "complete_text", "Luca prende ___ alle otto.", ["[il|un] treno"], "Complete the text; one gap with two accepted answers, [il|un] treno", "il treno / un treno", instruction="Luca goes to work.", hint="A way to travel by rail between towns, with its article.")
    lab.enter("missing_letters", "missing_letters", [text("Il gatto dorme sul divano.")], [], "Missing letters; letters inside two words", missing=["tt", "van"], answer="tt / van")
    lab.enter("missing_letters_audio", "missing_letters", [text("Il treno parte alle nove."), audio("Il treno parte alle nove.")], [], "Missing letters; spoken text and two gaps", missing=["ren", "ove"], answer="ren / ove")
    lab.enter("picture_name", "picture_name", [text("What is this?"), image("bread", "Bread", "picture")], ["il pane", "pane"], "Type what you see; picture prompt, typed answers")

    lab.start_lesson("Arrange", "Build an Italian answer from words, phrases, letters or syllables. Ordinary Arrange consumes each block once; repeated words need repeated blocks. Inline Arrange fills fixed gaps with distinct blocks. Word order and Build the translation allow zero, one or two distractors; Image-prompt ordering allows none.")
    lab.start_round("arrange_words", "Word and phrase blocks", "Tap blocks to build the answer. You can remove a chosen block before checking. Repeated words are separate occurrences.")
    lab.arrange("arrange_zero", "word_order", [text("Put the Italian sentence in order: The cat sleeps.", "clue")], ["Il", "gatto", "dorme"], [[0, 1, 2]], "Word order; zero distractors")
    lab.arrange("arrange_one", "word_order", [text("Put the Italian sentence in order: Anna drinks water.", "clue")], ["Anna", "beve", "acqua", "pane"], [[0, 1, 2]], "Word order; one distractor")
    lab.arrange("arrange_two", "word_order", [text("Put the Italian sentence in order: The train leaves today.", "clue")], ["Il", "treno", "parte", "oggi", "ieri", "dorme"], [[0, 1, 2, 3]], "Word order; two distinct target-language distractors")
    lab.arrange("arrange_repeat", "word_order", [text("Build: Anna eats bread and Luca eats rice.", "clue")], ["Anna", "mangia", "pane", "e", "Luca", "mangia", "riso"], [[0, 1, 2, 3, 4, 5, 6]], "Word order; repeated visible words use separate block occurrences")
    lab.arrange("arrange_phrases", "word_order", [text("Build: I go to school by bus.", "clue")], ["Vado", "a scuola", "in autobus"], [[0, 1, 2]], "Word order; multiword phrase blocks")
    lab.arrange("picture_blocks", "picture_blocks", [text("What is this?"), image("bread", "Bread", "picture")], ["il", "pane", "la"], [[0, 1]], "Name what you see; picture prompt, word blocks, one extra block and a hint", hint="Include the article.")

    lab.start_round("arrange_gaps", "Pick the words for the gaps", "Tap a word for each gap: each word fills one gap and leaves the bank. A word needed twice is offered twice. Gap contents can be removed, moved or swapped.")
    # Build 259 Revision 8 (owner review): at least two blocks to choose
    # from; the plural form does not agree with il gatto.
    lab.gaps("arrange_gap_one", "gap_blocks", "Complete the sentence.", ["Il gatto", ("dorme",), "."], ["dormono"], "Inline Arrange; one gap; one distractor")
    lab.gaps("arrange_gap_many", "gap_blocks", "Complete the sentence about Anna's drink.", ["Anna", ("beve",), ("acqua",), "."], ["mangia"], "Inline Arrange; two gaps; one distractor")
    lab.gaps("arrange_gap_repeat", "gap_blocks", "Complete the sentences using separate blocks.", ["Luca", ("è",), "italiano. Anna", ("è",), "italiana."], ["sono", "siamo"], "Inline Arrange; repeated text requires distinct tile IDs; two distractors")
    lab.gaps("arrange_gap_audio", "gap_blocks", "Listen and complete the sentence.", ["Io vado", ("a scuola",), ("in autobus",), "."], [], "Inline Arrange; phrase blocks and spoken prompt", spoken="Io vado a scuola in autobus.")

    lab.start_round("arrange_translations", "Build translations", "Translate the English prompt using the available literal blocks. Some questions accept more than one complete translation. Answer-expression notation and typo tolerance do not apply to this exercise type.")
    lab.arrange("build_single", "build_translation", [text("I drink water.")], ["Bevo", "acqua"], [[0, 1]], "Build translation; one literal answer and no distractors")
    lab.arrange("build_multiple", "build_translation", [text("I eat bread.")], ["Io", "mangio", "pane", "acqua"], [[1, 2], [0, 1, 2]], "Build translation; multiple valid orders with optional subject; one block unused by every answer")
    lab.arrange("build_phrase", "build_translation", [text("I go to school by train.")], ["Vado", "a scuola", "in treno", "in autobus", "a casa"], [[0, 1, 2]], "Build translation; phrase blocks and two distractors")
    lab.arrange("build_repeat", "build_translation", [text("Anna drinks water and Luca drinks milk.")], ["Anna", "beve", "acqua", "e", "Luca", "beve", "latte"], [[0, 1, 2, 3, 4, 5, 6]], "Build translation; repeated word occurrences")
    lab.gaps("build_gap", "gap_blocks", "Anna reads a book.", ["Anna", ("legge",), "un", ("libro",), "."], ["caffè"], "Build translation; inline gaps with one distractor")
    lab.gaps("build_gap_audio", "gap_blocks", "We drink water.", ["Noi", ("beviamo",), ("acqua",), "."], [], "Build translation; inline gaps and spoken prompt", spoken="Noi beviamo acqua.")

    lab.start_round("arrange_images", "Letters and syllables", "Use every available block to write the Italian word for the picture. There are no distractors. Each repeated letter is a separate block.")
    lab.arrange("image_letters", "image_word", [text("Build the Italian word for this fruit.", "clue"), image("apple", "An apple")], ["m", "e", "l", "a"], [[0, 1, 2, 3]], "Image-prompt ordering; individual letter blocks")
    lab.arrange("image_syllables", "image_word", [text("Build the Italian word for this animal.", "clue"), image("cat", "A cat")], ["gat", "to"], [[0, 1]], "Image-prompt ordering; syllable blocks")
    lab.arrange("image_repeated_letters", "image_word", [text("Build the Italian word for this fruit. Use the singular word.", "clue"), image("bananas", "Bananas")], ["b", "a", "n", "a", "n", "a"], [[0, 1, 2, 3, 4, 5]], "Image-prompt ordering; repeated individual letters",)

    lab.start_round("arrange_source_and_lines", "Source blocks, sentences and spelling", "Build the translation (to source) uses source-language blocks. Put the sentences in order orders lines. Spell what you hear and Spell the word spell a word from tiles without a picture.")
    lab.arrange("build_source_single", "build_translation_to_source", [text("Bevo acqua.", language="target")], ["I", "drink", "water"], [[0, 1, 2]], "Build the translation (to source); target text, source blocks", language="source")
    lab.arrange("build_source_distractor", "build_translation_to_source", [text("Vado a scuola in treno.", language="target")], ["I", "go", "to", "school", "by", "train", "bus"], [[0, 1, 2, 3, 4, 5]], "Build the translation (to source); one unused block", language="source")
    lab.arrange("sentence_order_story", "sentence_order", [text("Anna stops at the bar for a coffee.", "clue")], ["Anna entra nel bar.", "Ordina un caffè.", "Paga e saluta."], [[0, 1, 2]], "Put the sentences in order; three lines of a story under an instruction that sets the scene")
    lab.arrange("sentence_order_dialogue", "sentence_order", [text("At the bar: a customer orders a coffee.", "clue")], ["Buongiorno, un caffè per favore.", "Subito. Zucchero?", "No, grazie.", "Ecco a lei.", "Il treno parte alle nove."], [[0, 1, 2, 3]], "Put the sentences in order; four turns of a dialogue, one extra line and a hint", hint="The barista offers sugar before serving.")
    lab.arrange("spell_heard_letters", "spell_heard", [audio("pane")], ["p", "a", "n", "e"], [[0, 1, 2, 3]], "Spell what you hear; letter tiles, no picture")
    lab.arrange("spell_heard_syllables", "spell_heard", [audio("gatto")], ["gat", "to"], [[0, 1]], "Spell what you hear; syllable tiles")
    lab.arrange("spell_word_clue", "spell_word", [text("cat (the animal)", "clue", "source")], ["g", "a", "t", "t", "o"], [[0, 1, 2, 3, 4]], "Spell the word; a source-language clue and letter tiles")
    lab.arrange("spell_word_definition", "spell_word", [text("You drink it when you are thirsty.", "clue", "source")], ["ac", "qua"], [[0, 1]], "Spell the word; a definition and syllable tiles")

    lab.start_lesson("Match", "Match each item on the left to its partner. The shuffled columns preserve stable pair identities. Match the pairs can use a variable number of text pairs; Match the words, Match related words and Listen and match use exactly three pairs. Listen and match needs audio enabled.")
    lab.start_round("match_text", "Words, meanings and relationships", "Match every row before Check. For related words, read whether the task asks for synonyms or opposites.")
    lab.match("match_single", "matching", "Match the Italian greeting with its English meaning.", [("ciao", "hello")], "Match the pairs; smallest supported one-pair form")
    lab.match("match_four", "matching", "Match each Italian phrase with its English meaning.", [("a domani", "see you tomorrow"), ("per favore", "please"), ("buon viaggio", "have a good trip"), ("a presto", "see you soon")], "Match the pairs; variable four-pair form with phrases")
    lab.match("match_words", "word_match", "Match the English words with their Italian translations.", [("water", "acqua"), ("bread", "pane"), ("book", "libro")], "Match the words; exactly three source-to-target pairs")
    lab.match("match_synonyms", "super_match", "Match each word with its synonym.", [("felice", "contento"), ("veloce", "rapido"), ("grande", "ampio")], "Match related words; exactly three target-language synonym pairs")
    lab.start_round("match_pictures", "Pictures and words", "Match each picture on the left with its Italian word.")
    lab.match("picture_word_match", "picture_word_match", "Match each picture with its word.", [("cat", "il gatto"), ("dog", "il cane"), ("house", "la casa")], "Match pictures to words; picture left items", left_images=True)
    lab.start_round("match_audio", "Listen and match", "Enable Audio Exercises and Text-to-speech. Play each sound and match it to the English meaning. Three sounds have three distinct partners and no distractors.", "listening")
    lab.match("match_sounds", "audio_match", "Listen and match each Italian word with its English meaning.", [("acqua", "water"), ("pane", "bread"), ("libro", "book")], "Listen and match; three audio-to-text pairs with distinct sound and answer labels")
    lab.start_round("match_opposites", "Opposites", "Match these familiar Italian words to their opposites.")
    lab.match("match_opposites", "super_match", "Match each word with its opposite.", [("caldo", "freddo"), ("alto", "basso"), ("aperto", "chiuso")], "Match related words; exactly three target-language opposite pairs")

    lab.start_lesson("Presentation", "Flashcards present material without a scored answer. Got it completes a card; Review again schedules it again later in this Round. These six cards cover all meaningful combinations of optional pronunciation, usage and usage translation. A usage translation only appears with a usage sentence. Cards with pronunciation audio follow learner Audio Settings.")
    lab.start_round("presentation_text", "Cards without pronunciation", "Read each card. Try Review again once, then Got it when the card returns. These cards can be studied without audio and do not earn correct-answer base XP.")
    lab.card("card_minimal", "ciao", "hello", "Term and meaning only; no usage or pronunciation")
    lab.card("card_usage", "grazie", "thank you", "Term, meaning and usage; no translation or pronunciation", usage="Grazie per il libro.")
    lab.card("card_usage_translation", "pane", "bread", "Term, meaning, usage and usage translation; no pronunciation", usage="Compro il pane.", translation="I buy the bread.")
    lab.start_round("presentation_audio", "Cards with pronunciation", "Enable Audio Exercises and Text-to-speech to include these cards. Play the word or the usage sentence, then choose Got it or Review again.", "listening")
    lab.card("card_audio", "buongiorno", "good morning", "Term and meaning with pronunciation; no usage", spoken="buongiorno")
    lab.card("card_audio_usage", "libro", "book", "Term, meaning, pronunciation and usage; no usage translation", usage="Leggo un libro.", spoken="libro")
    lab.card("card_complete", "acqua", "water", "Term, meaning, pronunciation, usage and usage translation", usage="Bevo un bicchiere d'acqua.", translation="I drink a glass of water.", spoken="acqua")
    lab.start_round("presentation_pictures_notes", "Picture flashcards and note cards", "Picture flashcards show a picture with the word; their audio is optional and never makes them audio exercises. Note cards carry a tip or a grammar note.")
    lab.card("picture_card", "la mela", "apple", "Picture flashcard; picture, usage, translation and optional pronunciation", usage="Mangio una mela.", translation="I eat an apple.", spoken="la mela", preset="picture_flashcard", picture="apple")
    lab.card("picture_card_plain", "il pane", "bread", "Picture flashcard; picture, term and meaning only", preset="picture_flashcard", picture="bread")
    lab.card("note_card_tip", "Tu o Lei?", "Use Lei with people you do not know well; tu is for friends, family and children.", "Note card; a usage tip", preset="note_card")
    lab.card("note_card_grammar", "Gli articoli", "il, lo, la, i, gli, le: the article agrees with the noun in gender and number.", "Note card; a grammar note", preset="note_card")

    anna, luca = "qql_lab254_character_anna", "qql_lab254_character_luca"
    lab.start_story_lesson("Story", "A Story is a Round played in order: a cover, dialogue lines said by the narrator or by a character, and exercises about them (Build 256 Revision 5). Lines are never skipped: without audio the learner reads them. An exercise marked as needing the Story's audio is skipped, like the listening exercises, when Audio Exercises is off. Only the exercises score. The first Story alternates lines and questions; the second shows the line options one by one and has nothing to score.")
    lab.start_story("story_cafe", "A morning in Turin", "Read or listen to the story and answer the questions between the lines. Continue moves on; the scroll log keeps the dialogue.", "Al bar")
    lab.cover("story_cover", "coffee", "A cup of coffee on a bar counter", "A morning in Turin", "Story cover; a bundled picture and a title line under the Story title")
    lab.line("story_narrator", "Anna walks into a café in Turin and greets the barista.", "Dialogue line; the narrator in the source language, text and audio")
    lab.line("story_anna_order", "Buongiorno! Un caffè, per favore.", "Dialogue line; a character in the target language, text and audio", speaker=anna)
    lab.line("story_luca_offer", "Subito! Vuole anche un cornetto?", "Dialogue line; a character, text and audio", speaker=luca)
    lab.choose("story_choice", "choice_target", [text("Che cosa ordina Anna?", "question")], ["Un caffè", "Un tè", "Un cornetto"], 0, "Choose the answer between the lines of a Story")
    lab.line("story_anna_no", "No, grazie. Solo il caffè.", "Dialogue line; a character declines", speaker=anna)
    lab.line("story_luca_serves", "Ecco il suo caffè.", "Dialogue line; a character serves", speaker=luca)
    lab.choose("story_true_false", "true_false", [text("Anna ordina un cornetto.", "question")], ["True", "False"], 1, "True or false between the lines of a Story; needs the Story's audio, so Audio Exercises off skips it", language="source")
    lab.needs_audio("story_true_false")
    lab.arrange("story_order", "word_order", [text("Put Anna's order in order: A coffee, please.", "clue")], ["Un", "caffè,", "per", "favore."], [[0, 1, 2, 3]], "Word order closing a Story")
    lab.finish_story()

    lab.start_story("story_options", "The same morning, line by line", "Each line of this Story shows one option: text after listening, text only, audio only read on request, and audio read aloud although the Story reads on request. Nothing is scored.", "Le opzioni", read_aloud="manual")
    lab.cover("options_cover", "coffee", "A cup of coffee on a bar counter", "The same morning, line by line", "Story cover of a Story without exercises")
    lab.line("options_narrator", "Anna orders again; every line shows a different option.", "Dialogue line; the narrator, text and audio, read on request as the Story says")
    lab.line("options_after_audio", "Buongiorno! Un caffè, per favore.", "Dialogue line; text shown after listening", speaker=anna, text_reveal="afterAudio")
    lab.line("options_text_only", "Subito! Vuole anche un cornetto?", "Dialogue line; text only", speaker=luca, mode="text")
    lab.line("options_audio_only", "No, grazie. Solo il caffè.", "Dialogue line; audio only, read on request", speaker=anna, mode="audio", read_aloud="manual")
    lab.line("options_automatic", "Ecco il suo caffè.", "Dialogue line; read aloud automatically although the Story reads on request", speaker=luca, read_aloud="automatic")
    lab.finish_story()
    lab.start_canonical_lesson("Assign", "Assign places items into destinations (Build 256 Revision 7): tap an item, then the group or slot that takes it; Check grades every destination at once. A group may take any number of items, a slot takes one; a reusable item stays in the bank. The presets Sort into groups and Fill the slots author these examples (Revision 7 follow-up). Gaps in a text are authored in the canonical editor; picture regions, grid cells and drag placement wait for a later version.")
    lab.start_round("assign_bins", "Groups and slots", "Sort the words into their groups, or fill each slot with the right word. Tap a word, then its destination; Check when every word is placed.")
    lab.assign("assign_groups", "sort_into_groups", "categories", "Sort the words: animals or plants?",
               [("gatto", "gatto"), ("cane", "cane"), ("rosa", "rosa"), ("pino", "pino")],
               [("animals", "Animals"), ("plants", "Plants")],
               {"animals": ["gatto", "cane"], "plants": ["rosa", "pino"]},
               "Sort into groups; a group takes any number of items (capacity unlimited), reuse forbidden",
               "Animals: gatto, cane; Plants: rosa, pino", capacity="unlimited")
    lab.assign("assign_groups_three", "sort_into_groups", "categories", "Sort the words: animal, plant or object?",
               [("gatto", "gatto"), ("cane", "cane"), ("rosa", "rosa"), ("pino", "pino"), ("tavolo", "tavolo"), ("sedia", "sedia")],
               [("animals", "Animals"), ("plants", "Plants"), ("objects", "Objects")],
               {"animals": ["gatto", "cane"], "plants": ["rosa", "pino"], "objects": ["tavolo", "sedia"]},
               "Sort into groups; three groups, every word in one",
               "Animals: gatto, cane; Plants: rosa, pino; Objects: tavolo, sedia", capacity="unlimited")
    lab.assign("assign_slots", "fill_the_slots", "slots", "Which article goes with each noun?",
               [("il", "il"), ("la", "la")], [("s1", "… gatto"), ("s2", "… casa")],
               {"s1": ["il"], "s2": ["la"]},
               "Fill the slots; one item per slot, a second placement replaces the first",
               "… gatto: il; … casa: la")
    lab.assign("assign_slots_reuse", "fill_the_slots", "slots", "Which article goes with each noun? An article may serve twice.",
               [("il", "il"), ("la", "la")], [("s1", "… cane"), ("s2", "… libro"), ("s3", "… casa")],
               {"s1": ["il"], "s2": ["il"], "s3": ["la"]},
               "Fill the slots; a word may fill more than one slot (reuse allowed), the item stays in the bank",
               "… cane: il; … libro: il; … casa: la", reuse="allowed")
    lab.start_canonical_lesson("Page", "A Page is a card the learner reads and continues (Build 258): headings, paragraphs with bold and italic, quotes, lists, pictures, audio and video links, each with its alignment and a colour from a palette that stays readable in light and dark themes. Nothing is scored. The Page preset authors these examples; a video link opens in the browser.")
    lab.start_round("pages", "Pages", "Read each page and press Continue. The second page has a picture, a Listen button and a video link that opens in your browser.")
    lab.page("page_textbook", [
        {"type": "text", "text": "Il caffè in Italia", "textStyle": "heading1", "align": "center"},
        {"type": "text", "text": "In Italy a **caffè** is an espresso. People often drink it *standing* at the bar, in a few sips.", "align": "justify"},
        {"type": "text", "text": "Un caffè, per favore.", "language": "target", "textStyle": "quote", "align": "center", "readAloud": True},
        {"type": "text", "text": "Coffee words", "textStyle": "heading2"},
        {"type": "text", "text": "**espresso**: a small, strong coffee\n**cappuccino**: coffee with foamed milk\n**macchiato**: espresso with a drop of milk", "textStyle": "bulleted"},
        {"type": "text", "text": "Say *buongiorno*.\nOrder at the counter.\nPay at the till.", "textStyle": "numbered"},
        {"type": "text", "text": "Tip: a cappuccino is a morning drink.", "align": "end", "color": "accent"},
    ], "Page; headings, bold and italic, justify, a quote read aloud, bulleted and numbered lists, an accent colour")
    lab.page("page_media", [
        {"type": "text", "text": "Al bar", "textStyle": "heading2", "color": "blue"},
        {"type": "image", "text": "A cup of coffee on a bar counter", "asset": "assets/exercise_images/coffee.webp", "size": "large"},
        {"type": "audio", "text": "Buongiorno! Un caffè, per favore.", "language": "target", "required": False},
        {"type": "text", "text": "Careful: at the bar, *un caffè* is never a large mug of coffee.", "color": "red"},
        {"type": "text", "text": "**Grazie!** is always welcome.", "align": "center", "color": "green"},
        {"type": "link", "text": "Watch how to order a coffee", "align": "center", "url": "https://www.example.org/qql/ordering-coffee"},
        {"type": "text", "text": "The video opens in your browser; QuisquisLingo does not play it.", "color": "grey"},
    ], "Page; a large picture with its caption, a Listen button, red, green and grey text, and a video link")

    return lab


def course_v11(lab: Laboratory) -> dict:
    """The Course before conversion: the v11 original the converter tests read."""
    value = {
        "formatVersion": 11, "publicationState": "published", "lessonNumberingMode": "lesson",
        "defaultLessonIconStyle": "monochrome", "courseId": COURSE_ID,
        "originType": "bundledOfficial", "publisherId": "org.quisquislingo",
        "publisherName": "QuisquisLingo", "officialCourseVersion": "1.0.0",
        "officialReleaseDateUtc": STAMP,
        "officialReleaseNotes": "Build 254: original English-to-Italian Exercise Laboratory covering every current authoring preset and its supported modes.",
        "distributionChannel": "bundled", "publisherVerificationStatus": "verified",
        "originalCourseCreator": {"type": "publisher", "id": "org.quisquislingo", "displayName": "QuisquisLingo"},
        "originalCreatedAtUtc": STAMP, "modifiedAtUtc": STAMP,
        "learningLanguage": "Italian", "interfaceLanguage": "English",
        "sourceLanguage": "English", "sourceLanguageTag": "en-GB",
        "targetLanguage": "Italian", "targetLanguageTag": "it-IT",
        "title": "QQL Demo: Italian Exercise Lab", "ttsLanguage": "it-IT", "audioMode": "tts",
        "authors": [{"name": "QuisquisLingo", "roles": ["Author"]}],
        "license": "All rights reserved", "derivativeWorksPolicy": "allowed",
        "courseDescription": "An English-to-Italian laboratory for trying every current Exercise type and its meaningful authoring options. Five Lessons group Select, Input, Arrange, Match and Presentation; a sixth Lesson is a Story, a seventh holds Assign (Sort into groups, Fill the slots) and an eighth shows Pages. Inspect or Fork the Course in Course Studio to study how the exercises are authored. Enable Audio Exercises and Text-to-speech to include all listening and pronunciation examples; ordinary lesson progression remains in effect.",
        # Build 259 Revision 8: temporarySample is the Private course flag; a demo is for everyone.
        "textDirection": "ltr", "temporarySample": False, "flagCode": "IT",
        "createDuels": False,
        "mediaAttributions": [{
            "author": "QuisquisLingo", "license": "All rights reserved",
            "title": "Italian Exercise Lab printed-character specimens",
            "source": "Original deterministic block lettering generated by tools/generate_exercise_laboratory_254.py; no external font or image source.",
            "appliesTo": "Embedded A, E and È PNGs, including the blue E variant, in Recognize characters examples.",
        }],
        "keywords": ["exercise laboratory", "authoring", "Italian", "examples"],
        "lessons": lab.lessons,
    }
    return value


def course(lab: Laboratory) -> dict:
    # The Story Lesson joins after the v11 original (Build 256 Revision 5):
    # its lines and covers pass through the converter in their canonical
    # shape; the fixture written from course_v11 omits it, and the Dart
    # parity test skips it.
    v11 = course_v11(lab)
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
    v11["lessons"] = [*lessons, *lab.story_lessons]
    value = convert_course_v11_to_v12(v11)
    for lesson, source in zip(value["lessons"], v11["lessons"]):
        lesson["guidebook"] = lab_guidebook(source)
    value["roundNumberingMode"] = "off"
    for lesson in value["lessons"]:
        for round_data in lesson["rounds"]:
            round_data["roundType"] = "story" if round_data.get("flow") else "practice"
    value["storyNarrator"] = {"name": "Narrator", "language": "source"}
    value["storyCharacters"] = [
        {"id": "qql_lab254_character_anna", "name": "Anna", "avatar": "assets/avatars/cat.png",
         "language": "target", "voice": "female"},
        {"id": "qql_lab254_character_luca", "name": "Luca", "avatar": "assets/avatars/dog.png",
         "language": "target", "voice": "male"},
    ]
    # Build 258: a Course with a Page needs a build that draws Pages.
    value["minimumAppBuild"] = 258000
    # The checksum excludes the local verification status.
    checksum_value = dict(value)
    checksum_value.pop("publisherVerificationStatus")
    canonical = json.dumps(checksum_value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    value["officialChecksum"] = hashlib.sha256(canonical).hexdigest()
    return value


def _canonical(key: str, exercise: dict) -> dict:
    return {"id": f"qql_labfuture_{key}", "publicationState": "published",
            "kind": "exercise", "required": True, "exercise": exercise}


def _intro(key: str, text: str) -> dict:
    # Build 257: a Round's introduction is a Before you start card.
    return {"id": f"qql_labfuture_intro_{key}", "publicationState": "published",
            "kind": "exercise", "required": False,
            "exercise": before_you_start(text, updated_at=STAMP, guidebook_button=True)}


def _future_round(key: str, title: str, content: list[dict], *, visual: str = "generic",
                  flow: dict | None = None) -> dict:
    value = {"id": f"qql_labfuture_round_{key}", "publicationState": "published",
             "updatedAt": STAMP, "title": title, "visualType": visual,
             "roundType": "story" if flow is not None else "practice", "content": content}
    if flow is not None:
        value["flow"] = flow
    return value


def _speak(prompt: str, *, mode: str, evaluation: str, answers: list[str] | None = None) -> dict:
    exercise = {"updatedAt": STAMP, "primitive": "speak",
                "options": _ordered_options({"speechMode": mode}),
                "prompt": [text(prompt)]}
    value = {"mode": evaluation}
    if answers:
        value["answers"] = answers
    exercise["evaluation"] = _ordered_evaluation(value)
    return exercise


def _ink(prompt: str, *, mode: str = "trace") -> dict:
    return {"updatedAt": STAMP, "primitive": "ink",
            "options": _ordered_options({"inkMode": mode}),
            "prompt": [text(prompt)], "evaluation": {"mode": "none"}}


def _submit(prompt: str, *, kind: str = "audio") -> dict:
    return {"updatedAt": STAMP, "primitive": "submit",
            "options": _ordered_options({"submissionType": kind}),
            "prompt": [text(prompt)], "evaluation": {"mode": "presence"}}


def _select(key: str, question: str, choices: list[str]) -> dict:
    ids = [f"qql_labfuture_{key}_{index}" for index in range(len(choices))]
    return {"updatedAt": STAMP, "primitive": "select",
            "prompt": [text(question, "question")],
            "items": [{"id": item_id, "content": [text(choice)]} for item_id, choice in zip(ids, choices)],
            "evaluation": {"mode": "exactItem", "correctItemIds": [ids[0]]}}


def future(root: dict) -> dict:
    """The fixture Course (plan A.12): Speak, Ink and Submit exercises, a
    Story ending on a Speak step and a Story whose flow branches, on the
    Laboratory's Course root with its own identity. Never bundled: the
    tests read it from test/fixtures/v12."""
    anna = "qql_lab254_character_anna"
    speak = _future_round("speak", "Speak", [
        _intro("speak", "Speaking exercises wait for a later version: this Round shows how they are stored."),
        _canonical("speak_repeat", _speak("Buongiorno!", mode="repeat", evaluation="transcriptionMatch", answers=["Buongiorno!"])),
        _canonical("speak_free", _speak("Say what you had for breakfast.", mode="freeResponse", evaluation="manual")),
    ])
    ink = _future_round("ink_submit", "Ink and Submit", [
        _intro("ink_submit", "Handwriting and hand-in exercises wait for a later version."),
        _canonical("ink_trace", _ink("Trace the letter è.")),
        _canonical("submit_audio", _submit("Record yourself greeting a friend.")),
    ])
    ends = [
        _canonical("ends_cover", story_cover(updated_at=STAMP, title_line="Say it back")),
        _canonical("ends_line", story_line("Buongiorno! Un caffè, per favore.", updated_at=STAMP, speaker_id=anna)),
        _canonical("ends_speak", _speak("Repeat: Un caffè, per favore.", mode="repeat", evaluation="transcriptionMatch", answers=["Un caffè, per favore."])),
    ]
    ends_story = _future_round("ends_on_speech", "A Story that ends on speech",
                               [_intro("ends", "A Story whose last step this version cannot play ends unrecorded."), *ends],
                               visual="story",
                               flow=story_flow([(c["id"], True) for c in ends], title="Say it back"))
    branch = [
        _canonical("branch_cover", story_cover(updated_at=STAMP, title_line="Coffee or tea")),
        _canonical("branch_question", _select("branch_question", "What does Anna order?", ["Un caffè", "Un tè"])),
        _canonical("branch_coffee", story_line("Un caffè, per favore.", updated_at=STAMP, speaker_id=anna)),
        _canonical("branch_tea", story_line("Un tè, per favore.", updated_at=STAMP, speaker_id=anna)),
        _canonical("branch_end", story_line("Grazie!", updated_at=STAMP, speaker_id=anna)),
    ]
    ids = [c["id"] for c in branch]
    cover, question, coffee, tea, end = ids
    branching_flow = {
        "start": cover,
        "nodes": [
            {"id": cover, "kind": "exercise", "contentId": cover,
             "transitions": [{"trigger": "next", "target": question}]},
            {"id": question, "kind": "exercise", "contentId": question,
             "transitions": [
                 {"trigger": "onChoice", "target": coffee, "choiceItemId": f"{question}_0"},
                 {"trigger": "onChoice", "target": tea, "choiceItemId": f"{question}_1"},
                 {"trigger": "next", "target": end},
             ]},
            {"id": coffee, "kind": "exercise", "contentId": coffee,
             "transitions": [{"trigger": "next", "target": end}]},
            {"id": tea, "kind": "exercise", "contentId": tea,
             "transitions": [{"trigger": "next", "target": end}]},
            {"id": end, "kind": "exercise", "contentId": end},
        ],
        "presentation": "scroll", "title": "Coffee or tea", "log": "dialogue",
    }
    branching = _future_round("branching", "A branching Story",
                              [_intro("branching", "A Story whose flow branches on a choice cannot start in this version."), *branch],
                              visual="story", flow=branching_flow)
    lesson = {
        "lessonId": "qql_labfuture_lesson", "publicationState": "published", "updatedAt": STAMP,
        "title": "Future", "section": False,
        "guidebook": guidebook([guidebook_module(
            "qql_labfuture_module", "What waits for a later build",
            overview="What QuisquisLingo stores but cannot play yet: Speak, Ink and Submit exercises, a Story ending on speech and a Story whose flow branches. Kept, editable and exported unchanged; skipped by learners.",
        )]),
        "rounds": [speak, ink, ends_story, branching],
        "duel": {"id": "qql_labfuture_duel", "title": "Future Duel"},
    }
    value = dict(root)
    value["courseId"] = FUTURE_ID
    value["title"] = "Temporary Demo: Laboratory of the future"
    value["officialReleaseNotes"] = "Build 256 Revision 7: the test-only fixture of what this version cannot play yet."
    value["courseDescription"] = "A test-only Course beside the Exercise Laboratory: Speak, Ink and Submit exercises, a Story that ends on a Speak step and a Story whose flow branches. Nothing in it plays in this version; the Audit reports each piece as information or a warning, and every service keeps it unchanged."
    value["keywords"] = ["exercise laboratory", "future", "speak", "ink", "submit", "branching"]
    value["lessons"] = [lesson]
    # No Page here (Build 258): the fixture keeps no build requirement.
    value.pop("minimumAppBuild", None)
    checksum_value = dict(value)
    checksum_value.pop("publisherVerificationStatus")
    canonical = json.dumps(checksum_value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    value["officialChecksum"] = hashlib.sha256(canonical).hexdigest()
    return value


def coverage(lab: Laboratory) -> str:
    preset_counts: dict[str, int] = {}
    for case in lab.cases:
        preset_counts[case["preset"]] = preset_counts.get(case["preset"], 0) + 1
    preset_count = len([preset for preset in preset_counts if not preset.startswith("canonical:")])
    rows = [
        "# Build 254 Exercise Laboratory coverage", "",
        "This document and the JSON are generated together by `tools/generate_exercise_laboratory_254.py`. Run its `--check` mode to detect drift. The current repository model, editor and learner are the source of truth; the Course does not add a new primitive or engine feature.", "",
        f"- Course: **Exercise Laboratory**, `{COURSE_ID}`.",
        "- Direction: English (`en-GB`) → Italian (`it-IT`); TTS `it-IT`.",
        "- Model 11, official Course version 1.0.0; all Lessons, Rounds and Content are Published.",
        f"- Exactly eight Lessons (six primitives, a Story and Pages), {sum(len(lesson['rounds']) for lesson in [*lab.lessons, *lab.story_lessons])} Rounds and {len(lab.cases)} runnable examples across all {preset_count} authoring presets (the Assign Lesson uses the presets Sort into groups and Fill the slots since the Build 256 Revision 7 follow-up).",
        "- Course rights explicitly allow Fork, so the bundled original can be inspected and a derivative can use the ordinary authoring/confirm/export/import paths.",
        "- Create Duels is off: Presentation is non-evaluable and the Course is not padded to manufacture Duel pools. The required per-Lesson Duel metadata is retained.",
        "- This Course leaves existing Course identities, learner data and media assets unchanged.", "",
        "## Source inventory and supported modes", "",
        f"The authoring registry is `lib/models/exercise_authoring.dart`. Every one of its {preset_count} presets has at least one example below.", "",
        "| Lesson | Preset | Examples |", "| --- | --- | ---: |",
    ]
    for lesson in ("Select", "Input", "Arrange", "Match", "Presentation", "Story", "Assign"):
        for preset, count in preset_counts.items():
            if any(c["lesson"] == lesson and c["preset"] == preset for c in lab.cases):
                rows.append(f"| {lesson} | `{preset}` | {count} |")
    rows.extend([
        "", "## Case matrix and answer keys", "",
        "The suffix below follows `qql_lab254_` in the stable Content/Exercise ID. Answer positions are deliberately not used as keys: Select and Match shuffle displayed options. Expression answers are examples of accepted variants, not necessarily their exhaustive expansion.", "",
        "| Lesson / Round | ID suffix | Preset | Capability | Correct response |",
        "| --- | --- | --- | --- | --- |",
    ])
    def cell(value: str) -> str:
        return value.replace("|", "\\|").replace("\n", " ")
    for case in lab.cases:
        values = [f"{case['lesson']} / {case['round']}", case["id"].removeprefix("qql_lab254_"),
                  case["preset"], case["capability"], case["answer"]]
        rows.append("| " + " | ".join(cell(value) for value in values) + " |")
    rows.extend([
        "", "## Boundaries and intentionally excluded combinations", "",
        "- Select single-answer questions check immediately. Choose multiple selection uses exact set equality: its minimum count controls whether Check is enabled, not how many answers are correct. Minimum counts above the correct-set size would make a valid response impossible and are excluded.",
        "- Choose inline gaps and multiple selection are mutually exclusive authoring modes. Inline Select reuses an option in separate gaps; each tap fills one gap. Inline Arrange consumes an occurrence and therefore needs separate IDs for repeated words. Each mode demonstrates zero, one and two distractors; no more than two are allowed.",
        "- Pick the translation has exactly one correct answer, two to five distinct text options, no inline gaps, no multiple selection, and no authored spoken prompt. Its optional target-language pronunciation never makes it an audio-dependent exercise.",
        "- Recognize characters is Select in both directions. Image to text has one or more prompt images and text-only options; Text to image has a text prompt and image-only options. A/E/È specimens are original deterministic 160×160 PNGs embedded in the Course, below 50 KB each. They do not claim handwriting recognition, OCR or speech recognition. No new Image Bank entries are installed.",
        "- Select the image uses the renderer's supported named icons and existing bundled image paths. Arbitrary Course-owned or embedded image options are not claimed for that legacy icon preset; portable image-only options are exercised by Recognize characters.",
        "- Input uses the editor's normal case/punctuation/whitespace normalization with accents preserved. Answer expressions have a hard 128-result limit. The examples demonstrate literal lines, optional text, independent and linked alternatives, scoped/whole reorder, and combinations. Invalid syntax, zero-result/overflow expansions, arbitrary normalization settings and unexposed input modes are not learner exercises.",
        "- Type the missing word expects a complete word whose first Unicode grapheme is shared by all accepted alternatives. It is not an Input-style character-recognition direction. Listen for missing words uses distinct complete transcript words in displayed order.",
        "- Build the translation records literal complete answers and distinct block occurrences; expressions, typo tolerance and similarity-ranked acceptance do not apply. Word order and Image-prompt ordering each expose one correct authored order. Image-prompt ordering has no distractors.",
        "- Match the pairs supports a variable count; the three named specialised Match presets require exactly three pairs. Images as matching operands and arbitrary many-to-many relationships are not exposed by the current authoring/learner paths.",
        "- Assign (Build 256 Revision 7) plays groups (categories in columns) and slots by tapping an item and then its destination, graded as exact assignments; the Laboratory authors them with Sort into groups and Fill the slots (Revision 7 follow-up, 29 September 2026). A group takes any number of items; a slot takes one; a reusable item stays in the bank; a word that belongs nowhere stays in the bank. Gaps in a text play too but have no preset and no Laboratory example (the owner prefers the inline gap presets); picture regions, grid cells, drag placement and the other Assign evaluation modes stay readable but not executable.",
        "- Flashcard coverage includes all six meaningful combinations of optional audio, usage, and usage translation (a translation requires usage). The learner buttons currently read Got it / Review again; JSON completion actions remain understood / review_later. Cards are non-evaluable and earn no correct-answer base XP. Optional omissions produce existing informational/warning Audit findings, not invalid content.",
        "- Flashcard image content is excluded: the current Presentation↔Exercise projection does not preserve images on an authoring round trip. Rich textual explanation/example/vocabulary/text/dialogue kinds share the presentation path but are not additional current Exercise picker presets. GuideBook explanations and Round introductions demonstrate explanatory text through their normal authoring surfaces.",
        "- Audio mode is On-Device TTS. Every spoken prompt is authored Italian, uses it-IT and needs an available native voice. Learner Enable Audio Exercises and Text-to-speech must be on to include every audio example; Authoring Preview ignores the learner switches. No recording transcript was guessed and no voice or MP3 is fabricated. Course audio modes and recorded-media transport are independent of the exercise primitive and covered by the separate Edge Cases Course.",
        "- Existing bundled pictures remain references to the app's Image Bank; the four distinct character PNG payloads travel inside Course JSON. No absolute local file paths or missing media placeholders are used.",
        "", "## Verification seams", "",
        "1. `python -X utf8 tools/generate_exercise_laboratory_254.py --check`: deterministic JSON/checksum and coverage-document readback.",
        "2. `python -X utf8 tools/validate_courses.py`: Course Model structure, timestamps, stable unique IDs, references, publication and official checksum.",
        "3. `test/exercise_laboratory_254_test.dart` checks the actual asset's Audit and canonical model round trip, then rebuilds all 80 examples through ExerciseDraftBuilder (and ScriptRecognitionController for its image modes), comparing semantic fields and each result's model round trip. Separate preservation assertions cover Flashcard usage and usage translation. Editor route tests include `exercise_authoring_252_characterization_test.dart`, `select_editor_238_test.dart`, `arrange_gap_fill_editor_238_test.dart`, `script_recognition_226_03_test.dart` and `translation_choice_239_test.dart`.",
        "4. The same Lab suite completes all 80 examples through RoundScreen Preview using actual controls and grading, including repeated blocks, reusable gaps, exact multiple-selection sets and audio matching. Additional cases finish an alternate Build translation answer and a Review again/Got it cycle. Speech is stubbed only at the playback seam; these tests do not establish native voice quality or normal progression persistence.",
        "5. Export/import of the Course through the normal ZIP and embedded-image JSON routes preserves this Course's identity, content wrappers, answers and character PNG bytes. A Fork gets a new identity through the existing rights-aware operation.",
        "", "These are verification seams, not a claim that commands have been run. Fresh integrated results are recorded in the Build 254 validation document.", "",
    ])
    rows = [row.replace("all 80 examples", f"all {len(lab.cases)} examples") for row in rows]
    return "\n".join(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    lab = laboratory()
    laboratory_course = course(lab)
    outputs = {ASSET: json.dumps(laboratory_course, ensure_ascii=False, indent=2) + "\n", COVERAGE: coverage(lab),
               FIXTURE: json.dumps(future(laboratory_course), ensure_ascii=False, indent=2) + "\n"}
    for path, expected in outputs.items():
        if args.check:
            if not path.is_file() or path.read_text(encoding="utf-8") != expected:
                raise SystemExit(f"Generated output differs: {path.relative_to(ROOT)}")
        else:
            path.write_text(expected, encoding="utf-8", newline="\n")
    lessons = [*lab.lessons, *lab.story_lessons]
    print(f"Exercise Laboratory {'verified' if args.check else 'generated'}: {len(lessons)} Lessons, {sum(len(l['rounds']) for l in lessons)} Rounds, {len(lab.cases)} examples, {len({c['preset'] for c in lab.cases})} presets.")


if __name__ == "__main__":
    main()
