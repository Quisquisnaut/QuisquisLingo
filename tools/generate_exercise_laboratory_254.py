#!/usr/bin/env python3
"""Generate the original, deterministic Exercise Laboratory Course Model v11.

Only this course and its coverage document are written. Existing courses and
media are inputs, never rewritten. --check verifies the committed outputs.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/courses/exercise_laboratory_en_it.json"
COVERAGE = ROOT / "docs/254_LABORATORY_COVERAGE.md"
# Allocated once with Course.newCourseId(); regeneration retains the identity.
COURSE_ID = "course_50d68435-d2c2-4b63-9a0b-b23161357f1d"
STAMP = "2026-09-25T00:00:00.000Z"
NORMALIZATION = {
    "case": "ignore", "punctuation": "ignore",
    "whitespace": "normalize", "accents": "preserve",
}


def text(value: str, role: str = "primary") -> dict:
    return {"role": role, "type": "text", "text": value}


def audio(value: str, role: str = "primary") -> dict:
    return {"role": role, "type": "audio", "text": value}


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


class Laboratory:
    def __init__(self) -> None:
        self.lessons: list[dict] = []
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
            }]},
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
               hint: str = "") -> None:
        items = [{"id": f"item_{i}", "content": [text(value)]} for i, value in enumerate(answers)]
        if icons:
            for item, icon in zip(items, icons, strict=True):
                item["content"].append(text(icon, "icon"))
        self.add(key, preset, prompts,
                 {"kind": "select", "minSelections": 1, "maxSelections": 1, "items": items},
                 {"kind": "selected_items", "correctItemIds": [f"item_{correct}"]},
                 capability, answers[correct], hint=hint)

    def multi(self, key: str, prompt: str, answers: list[str], correct: list[int],
              minimum: int, capability: str) -> None:
        self.add(key, "choice", [text(prompt)],
                 {"kind": "select", "minSelections": minimum, "maxSelections": len(answers),
                  "items": [{"id": f"item_{i}", "content": [text(v)]} for i, v in enumerate(answers)]},
                 {"kind": "selected_items", "correctItemIds": [f"item_{i}" for i in correct]},
                 capability, " + ".join(answers[i] for i in correct))

    def gaps(self, key: str, preset: str, instruction: str, parts: list[str | tuple[str]],
             distractors: list[str], capability: str, *, spoken: str = "") -> None:
        select = preset == "choice"
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
                orders: list[list[int]], capability: str) -> None:
        separator = "" if preset == "image_word" else " "
        correct_orders = [{"text": separator.join(tokens[i] for i in order),
                           "itemIds": [f"item_{i}" for i in order]} for order in orders]
        self.add(key, preset, prompts,
                 {"kind": "arrange", "items": [{"id": f"item_{i}", "content": [text(v)]} for i, v in enumerate(tokens)]},
                 {"kind": "ordered_items", "correctOrders": correct_orders},
                 capability, " / ".join(order["text"] for order in correct_orders))

    def match(self, key: str, preset: str, instruction: str, pairs: list[tuple[str, str]], capability: str) -> None:
        items = []
        for index, (left, right) in enumerate(pairs):
            items.extend([
                {"id": f"item_{index * 2}", "content": [audio(left) if preset == "audio_match" else text(left)]},
                {"id": f"item_{index * 2 + 1}", "content": [text(right)]},
            ])
        self.add(key, preset, [text(instruction)], {"kind": "match", "items": items},
                 {"kind": "matched_items", "pairs": [[f"item_{i * 2}", f"item_{i * 2 + 1}"] for i in range(len(pairs))]},
                 capability, "; ".join(f"{left} = {right}" for left, right in pairs))

    def card(self, key: str, term: str, meaning: str, capability: str, *,
             usage: str = "", translation: str = "", spoken: str = "") -> None:
        elements = [text(term, "term"), text(meaning, "meaning")]
        if spoken:
            elements.append(audio(spoken, "audio"))
        if usage:
            elements.append(text(usage, "usage"))
        if translation:
            assert usage
            elements.append(text(translation, "usage_translation"))
        identity = "qql_lab254_" + key
        self.round["content"].append({
            "id": identity, "publicationState": "published", "kind": "presentation",
            "required": True, "editorTemplate": "flashcard",
            "presentation": {"content": elements, "completion": {"actions": ["understood", "review_later"]}},
        })
        self.cases.append({"id": identity, "lesson": self.lesson["title"], "round": self.round["title"],
                           "preset": "flashcard", "capability": capability,
                           "answer": "Got it; or Review again, then Got it on the repeated card"})


def laboratory() -> Laboratory:
    lab = Laboratory()
    lab.start_lesson("Select", "Choose an answer, select a complete set, or fill fixed gaps with reusable options. The Rounds also demonstrate images, characters, reading, dialogue, listening and both translation directions. Listening needs Enable Audio Exercises and Text-to-speech in Audio Settings; Preview ignores those learner switches.")
    lab.start_round("select_basics", "Single and multiple answers", "Read the instruction carefully. Single-answer questions check immediately. Multiple-answer questions wait for Check; select every correct option and no distractor.")
    lab.choose("select_single", "choice", [text("How do you say ‘thank you’ in Italian?")], ["grazie", "prego"], 0, "Single selection; two text options; immediate feedback")
    lab.choose("select_image_prompt", "choice", [text("How do you say ‘the apple’ in Italian?"), image("apple", "An apple")], ["la mela", "il pane", "il latte"], 0, "Single selection with a supplementary prompt image")
    lab.multi("select_multiple", "Which words are Italian colours? Select all correct answers.", ["rosso", "blu", "pane", "libro"], [0, 1], 2, "Multiple selection; exact correct set; minimum equals two correct answers")
    lab.multi("select_minimum", "Which words name an animal? Select all correct answers.", ["gatto", "cane", "casa", "sole"], [0, 1], 1, "Multiple selection; minimum one permits partial submission but only the exact two-answer set is correct")
    lab.multi("select_one_in_multi", "Which word means ‘yes’? Select the correct answer, then press Check.", ["sì", "no", "mai"], [0], 1, "Multiple-selection presentation with one correct answer and an explicit Check")

    lab.start_round("select_gaps", "Fixed sentences and reusable choices", "In Fill in the blank, choose one missing expression. In the fixed-sentence exercises, fill each gap; an option can be used again. You can remove, move and swap answers before Check.")
    lab.choose("select_gap_preset", "gap_choice", [text("Il gatto ___ sul divano.", "question")], ["dorme", "dormono", "dormire"], 0, "Fill in the blank preset; one ___ gap and non-revealing hint", hint="The subject is one animal.")
    lab.gaps("select_gap_one", "choice", "Complete the Italian greeting.", ["Buon", ("giorno",), "!"], [], "Inline Select; one gap; zero distractors")
    lab.gaps("select_gap_distinct", "choice", "Complete the sentence about Anna.", ["Anna", ("è",), "a", ("casa",), "."], ["siamo"], "Inline Select; two distinct options; one distractor")
    lab.gaps("select_gap_reuse", "choice", "Complete both sentences. The same word can be used twice.", ["Luca", ("è",), "italiano. Anna", ("è",), "italiana."], ["sono", "siamo"], "Inline Select; one reusable option assigned to two gaps; two distractors")
    lab.gaps("select_gap_audio", "choice", "Listen and complete the sentence.", ["Io", ("bevo",), ("acqua",), "."], ["mangio"], "Inline Select with optional spoken prompt", spoken="Io bevo acqua.")

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
    lab.add("script_text_image", "script_recognition", [text("Select the image of È (E with a grave accent).")],
            {"kind": "select", "minSelections": 1, "maxSelections": 1,
             "items": [{"id": f"item_{i}", "content": [{"role": "primary", "type": "image", "asset": glyph_asset(letter)}]} for i, letter in enumerate(("E", "È", "A"))]},
            {"kind": "selected_items", "correctItemIds": ["item_1"]},
            "Recognize characters; text to image-only options; Italian accented character", "Image È")

    lab.start_round("select_context", "Reading and conversations", "Read the passage or conversation before choosing an answer. Contextual comprehension can use a passage, labelled speakers, or both.", "story")
    lab.choose("select_reading", "reading_comprehension", [text("Anna abita a Roma. Ogni mattina va al lavoro in autobus.", "passage"), text("Come va al lavoro Anna?", "question")], ["In autobus.", "In treno.", "A piedi."], 0, "Reading comprehension; passage plus separate question")
    lab.choose("select_dialogue", "dialogue_response", [text("Un amico ti offre un bicchiere d'acqua.", "passage"), text("Vuoi accettare. Qual è la risposta adatta?", "question")], ["Sì, grazie.", "No, grazie."], 0, "Dialogue response; exactly two alternatives")
    lab.choose("context_text", "contextual_comprehension", [text("La biblioteca apre alle nove e chiude alle diciotto.", "context"), text("A che ora apre la biblioteca?", "question")], ["Alle nove.", "Alle diciotto.", "A mezzogiorno."], 0, "Contextual comprehension; Text mode")
    lab.choose("context_dialogue", "contextual_comprehension", [{**text("Dov'è la stazione?", "dialogue_turn"), "speaker": "Anna"}, {**text("È vicino al parco.", "dialogue_turn"), "speaker": "Luca"}, text("Dov'è la stazione?", "question")], ["Vicino al parco.", "In biblioteca.", "Lontano dalla città."], 0, "Contextual comprehension; structured dialogue without prose context")
    lab.choose("context_text_dialogue_image", "contextual_comprehension", [text("Anna e Luca sono in cucina.", "context"), {**text("Vuoi una mela?", "dialogue_turn"), "speaker": "Anna"}, {**text("Sì, grazie.", "dialogue_turn"), "speaker": "Luca"}, image("apple", "An apple", "context"), text("Che cosa offre Anna?", "question")], ["Una mela.", "Un libro.", "Un caffè."], 0, "Contextual comprehension; text, structured dialogue and supplementary image")

    lab.start_round("select_listening", "Listening and context", "Enable Audio Exercises and Text-to-speech to practise every item here. Use the replay control as needed. Listen for meaning as well as for individual words.", "listening")
    lab.choose("select_listening_word", "listening_choice", [audio("Buongiorno."), text("Choose the greeting you hear.", "question")], ["Buongiorno.", "Buonasera.", "Buonanotte."], 0, "What do you hear; audio prompt and written answers")
    lab.choose("select_listening_passage", "listening_comprehension", [audio("Maria compra due mele e un chilo di pane al mercato.", "passage"), text("Dove fa la spesa Maria?", "question")], ["Al mercato.", "A scuola.", "In stazione."], 0, "Listen and choose; passage audio and separate question")
    lab.choose("context_audio", "contextual_comprehension", [audio("Il treno per Roma parte dal binario tre.", "context"), text("Da quale binario parte il treno?", "question")], ["Dal binario tre.", "Dal binario uno.", "Dal binario cinque."], 0, "Contextual comprehension; Audio mode")
    lab.choose("context_text_audio", "contextual_comprehension", [text("Luca legge un libro in giardino.", "context"), audio("Luca legge un libro in giardino.", "context"), text("Che cosa legge Luca?", "question")], ["Un libro.", "Una lettera.", "Un giornale."], 0, "Contextual comprehension; Text and audio mode")
    lab.choose("context_all", "contextual_comprehension", [text("Anna e Luca parlano dopo pranzo.", "context"), audio("Vuoi un caffè? Sì, senza zucchero.", "context"), {**text("Vuoi un caffè?", "dialogue_turn"), "speaker": "Anna"}, {**text("Sì, senza zucchero.", "dialogue_turn"), "speaker": "Luca"}, image("coffee", "A cup of coffee", "context"), text("Come vuole il caffè Luca?", "question")], ["Senza zucchero.", "Con molto zucchero.", "Con il gelato."], 0, "Contextual comprehension; text, audio, structured dialogue and image together")

    lab.start_round("select_translation", "Two translation directions", "Read the language named in the instruction. QQL supplies the instruction for each direction. Pronunciation is optional; these questions remain available with Audio Exercises off.")
    lab.choose("translation_target_two", "translation_choice_to_target", [text("Good morning.", "question")], ["Buongiorno.", "Buonanotte."], 0, "Pick translation to target; minimum two answers; no image")
    lab.choose("translation_target_five", "translation_choice_to_target", [text("The cat is sleeping.", "question"), image("cat", "A cat")], ["Il gatto dorme.", "Il cane dorme.", "Il gatto mangia.", "Il gatto corre.", "Il gatto beve."], 0, "Pick translation to target; maximum five answers; optional image")
    lab.choose("translation_source_two", "translation_choice_to_source", [text("Grazie.", "question")], ["Thank you.", "Goodbye."], 0, "Pick translation to source; minimum two answers; no image")
    lab.choose("translation_source_five", "translation_choice_to_source", [text("La mela è rossa.", "question"), image("apple", "An apple")], ["The apple is red.", "The apple is green.", "The pear is red.", "The apple is small.", "The apple is yellow."], 0, "Pick translation to source; maximum five answers; optional image")

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
    lab.enter("input_first_alternatives", "type_missing_word", [text("In fattoria vive un ___.")], ["cane", "cavallo"], "Type the missing word; multiple complete words sharing the first grapheme", hint="Both accepted animals begin with the same letter.")
    lab.enter("input_first_unicode", "type_missing_word", [text("Il mio amico francese si chiama ___.")], ["Émile", "Étienne"], "Type the missing word; accented first Unicode grapheme and proper names", hint="Two traditional French male names are accepted.")

    lab.start_round("input_listening", "Transcriptions and missing words", "Enable Audio Exercises and Text-to-speech. For a transcription, type the whole utterance. For missing words, complete the numbered fields in transcript order.", "listening")
    lab.enter("input_listen_word", "listening_spelling", [audio("Grazie.")], ["grazie"], "Type what you hear; one word")
    lab.enter("input_listen_sentence", "listening_spelling", [text("Type the sentence about the train."), audio("Il treno parte alle nove.")], ["il treno parte alle nove"], "Type what you hear; complete sentence and normal punctuation handling")
    lab.enter("input_listen_variants", "listening_spelling", [text("Type the short statement about a feeling."), audio("Sono felice.")], ["sono felice", "io sono felice"], "Type what you hear; more than one explicitly accepted transcription")
    lab.enter("input_missing_one", "missing_word", [text("Anna mangia una mela."), audio("Anna mangia una mela.")], ["mela"], "Listen for missing words; one transcript gap", missing=["mela"])
    lab.enter("input_missing_many", "missing_word", [text("Luca legge un libro in giardino."), audio("Luca legge un libro in giardino.")], ["legge", "libro", "giardino"], "Listen for missing words; three distinct gaps in transcript order", missing=["legge", "libro", "giardino"], answer="1 legge; 2 libro; 3 giardino")

    lab.start_lesson("Arrange", "Build an Italian answer from words, phrases, letters or syllables. Ordinary Arrange consumes each block once; repeated words need repeated blocks. Inline Arrange fills fixed gaps with distinct blocks. Word order and Build the translation allow zero, one or two distractors; Image-prompt ordering allows none.")
    lab.start_round("arrange_words", "Word and phrase blocks", "Tap blocks to build the answer. You can remove a chosen block before checking. Repeated words are separate occurrences.")
    lab.arrange("arrange_zero", "word_order", [text("Put the Italian sentence in order: The cat sleeps.", "clue")], ["Il", "gatto", "dorme"], [[0, 1, 2]], "Word order; zero distractors")
    lab.arrange("arrange_one", "word_order", [text("Put the Italian sentence in order: Anna drinks water.", "clue")], ["Anna", "beve", "acqua", "pane"], [[0, 1, 2]], "Word order; one distractor")
    lab.arrange("arrange_two", "word_order", [text("Put the Italian sentence in order: The train leaves today.", "clue")], ["Il", "treno", "parte", "oggi", "ieri", "dorme"], [[0, 1, 2, 3]], "Word order; two distinct target-language distractors")
    lab.arrange("arrange_repeat", "word_order", [text("Build: Anna eats bread and Luca eats rice.", "clue")], ["Anna", "mangia", "pane", "e", "Luca", "mangia", "riso"], [[0, 1, 2, 3, 4, 5, 6]], "Word order; repeated visible words use separate block occurrences")
    lab.arrange("arrange_phrases", "word_order", [text("Build: I go to school by bus.", "clue")], ["Vado", "a scuola", "in autobus"], [[0, 1, 2]], "Word order; multiword phrase blocks")

    lab.start_round("arrange_gaps", "Fixed sentences and consumed blocks", "Fill each gap using a separate block. Unlike Select, placing a block removes that occurrence from the available bank. Duplicate words need two blocks. Gap contents can be removed, moved or swapped.")
    lab.gaps("arrange_gap_one", "word_order", "Complete the sentence.", ["Il gatto", ("dorme",), "."], [], "Inline Arrange; one gap; no distractors")
    lab.gaps("arrange_gap_many", "word_order", "Complete the sentence about Anna's drink.", ["Anna", ("beve",), ("acqua",), "."], ["mangia"], "Inline Arrange; two gaps; one distractor")
    lab.gaps("arrange_gap_repeat", "word_order", "Complete the sentences using separate blocks.", ["Luca", ("è",), "italiano. Anna", ("è",), "italiana."], ["sono", "siamo"], "Inline Arrange; repeated text requires distinct tile IDs; two distractors")
    lab.gaps("arrange_gap_audio", "word_order", "Listen and complete the sentence.", ["Io vado", ("a scuola",), ("in autobus",), "."], [], "Inline Arrange; phrase blocks and spoken prompt", spoken="Io vado a scuola in autobus.")

    lab.start_round("arrange_translations", "Build translations", "Translate the English prompt using the available literal blocks. Some questions accept more than one complete translation. Answer-expression notation and typo tolerance do not apply to this exercise type.")
    lab.arrange("build_single", "build_translation", [text("I drink water.")], ["Bevo", "acqua"], [[0, 1]], "Build translation; one literal answer and no distractors")
    lab.arrange("build_multiple", "build_translation", [text("I eat bread.")], ["Io", "mangio", "pane", "acqua"], [[1, 2], [0, 1, 2]], "Build translation; multiple valid orders with optional subject; one block unused by every answer")
    lab.arrange("build_phrase", "build_translation", [text("I go to school by train.")], ["Vado", "a scuola", "in treno", "in autobus", "a casa"], [[0, 1, 2]], "Build translation; phrase blocks and two distractors")
    lab.arrange("build_repeat", "build_translation", [text("Anna drinks water and Luca drinks milk.")], ["Anna", "beve", "acqua", "e", "Luca", "beve", "latte"], [[0, 1, 2, 3, 4, 5, 6]], "Build translation; repeated word occurrences")
    lab.gaps("build_gap", "build_translation", "Anna reads a book.", ["Anna", ("legge",), "un", ("libro",), "."], ["caffè"], "Build translation; inline gaps with one distractor")
    lab.gaps("build_gap_audio", "build_translation", "We drink water.", ["Noi", ("beviamo",), ("acqua",), "."], [], "Build translation; inline gaps and spoken prompt", spoken="Noi beviamo acqua.")

    lab.start_round("arrange_images", "Letters and syllables", "Use every available block to write the Italian word for the picture. There are no distractors. Each repeated letter is a separate block.")
    lab.arrange("image_letters", "image_word", [text("Build the Italian word for this fruit.", "clue"), image("apple", "An apple")], ["m", "e", "l", "a"], [[0, 1, 2, 3]], "Image-prompt ordering; individual letter blocks")
    lab.arrange("image_syllables", "image_word", [text("Build the Italian word for this animal.", "clue"), image("cat", "A cat")], ["gat", "to"], [[0, 1]], "Image-prompt ordering; syllable blocks")
    lab.arrange("image_repeated_letters", "image_word", [text("Build the Italian word for this fruit. Use the singular word.", "clue"), image("bananas", "Bananas")], ["b", "a", "n", "a", "n", "a"], [[0, 1, 2, 3, 4, 5]], "Image-prompt ordering; repeated individual letters",)

    lab.start_lesson("Match", "Match each item on the left to its partner. The shuffled columns preserve stable pair identities. Match the pairs can use a variable number of text pairs; Match the words, Match related words and Listen and match use exactly three pairs. Listen and match needs audio enabled.")
    lab.start_round("match_text", "Words, meanings and relationships", "Match every row before Check. For related words, read whether the task asks for synonyms or opposites.")
    lab.match("match_single", "matching", "Match the Italian greeting with its English meaning.", [("ciao", "hello")], "Match the pairs; smallest supported one-pair form")
    lab.match("match_four", "matching", "Match each Italian phrase with its English meaning.", [("a domani", "see you tomorrow"), ("per favore", "please"), ("buon viaggio", "have a good trip"), ("a presto", "see you soon")], "Match the pairs; variable four-pair form with phrases")
    lab.match("match_words", "word_match", "Match the English words with their Italian translations.", [("water", "acqua"), ("bread", "pane"), ("book", "libro")], "Match the words; exactly three source-to-target pairs")
    lab.match("match_synonyms", "super_match", "Abbina ogni parola al suo sinonimo.", [("felice", "contento"), ("veloce", "rapido"), ("grande", "ampio")], "Match related words; exactly three target-language synonym pairs")
    lab.start_round("match_audio", "Listen and match", "Enable Audio Exercises and Text-to-speech. Play each sound and match it to the English meaning. Three sounds have three distinct partners and no distractors.", "listening")
    lab.match("match_sounds", "audio_match", "Listen and match each Italian word with its English meaning.", [("acqua", "water"), ("pane", "bread"), ("libro", "book")], "Listen and match; three audio-to-text pairs with distinct sound and answer labels")
    lab.start_round("match_opposites", "Opposites", "Match these familiar Italian words to their opposites.")
    lab.match("match_opposites", "super_match", "Abbina ogni parola al suo contrario.", [("caldo", "freddo"), ("alto", "basso"), ("aperto", "chiuso")], "Match related words; exactly three target-language opposite pairs")

    lab.start_lesson("Presentation", "Flashcards present material without a scored answer. Got it completes a card; Review again schedules it again later in this Round. These six cards cover all meaningful combinations of optional pronunciation, usage and usage translation. A usage translation only appears with a usage sentence. Cards with pronunciation audio follow learner Audio Settings.")
    lab.start_round("presentation_text", "Cards without pronunciation", "Read each card. Try Review again once, then Got it when the card returns. These cards can be studied without audio and do not earn correct-answer base XP.")
    lab.card("card_minimal", "ciao", "hello", "Term and meaning only; no usage or pronunciation")
    lab.card("card_usage", "grazie", "thank you", "Term, meaning and usage; no translation or pronunciation", usage="Grazie per il libro.")
    lab.card("card_usage_translation", "pane", "bread", "Term, meaning, usage and usage translation; no pronunciation", usage="Compro il pane.", translation="I buy the bread.")
    lab.start_round("presentation_audio", "Cards with pronunciation", "Enable Audio Exercises and Text-to-speech to include these cards. Play the word or the usage sentence, then choose Got it or Review again.", "listening")
    lab.card("card_audio", "buongiorno", "good morning", "Term and meaning with pronunciation; no usage", spoken="buongiorno")
    lab.card("card_audio_usage", "libro", "book", "Term, meaning, pronunciation and usage; no usage translation", usage="Leggo un libro.", spoken="libro")
    lab.card("card_complete", "acqua", "water", "Term, meaning, pronunciation, usage and usage translation", usage="Bevo un bicchiere d'acqua.", translation="I drink a glass of water.", spoken="acqua")
    return lab


def course(lab: Laboratory) -> dict:
    value = {
        "formatVersion": 11, "publicationState": "published", "lessonNumberingMode": "lesson",
        "defaultLessonIconStyle": "monochrome", "courseId": COURSE_ID,
        "originType": "bundledOfficial", "publisherId": "org.quisquislingo",
        "publisherName": "QuisquisLingo", "officialCourseVersion": "1.0.0",
        "officialReleaseDateUtc": STAMP,
        "officialReleaseNotes": "Build 254: original English-to-Italian Exercise Laboratory covering all 24 current authoring presets and their supported modes.",
        "distributionChannel": "bundled", "publisherVerificationStatus": "verified",
        "originalCourseCreator": {"type": "publisher", "id": "org.quisquislingo", "displayName": "QuisquisLingo"},
        "originalCreatedAtUtc": STAMP, "modifiedAtUtc": STAMP,
        "learningLanguage": "Italian", "interfaceLanguage": "English",
        "sourceLanguage": "English", "sourceLanguageTag": "en-GB",
        "targetLanguage": "Italian", "targetLanguageTag": "it-IT",
        "title": "Exercise Laboratory", "ttsLanguage": "it-IT", "audioMode": "tts",
        "authors": [{"name": "QuisquisLingo", "roles": ["Author"]}],
        "license": "All rights reserved", "derivativeWorksPolicy": "allowed",
        "courseDescription": "An English-to-Italian laboratory for trying every current Exercise type and its meaningful authoring options. Five Lessons group Select, Input, Arrange, Match and Presentation. Inspect or Fork the Course in Course Studio to study how the exercises are authored. Enable Audio Exercises and Text-to-speech to include all listening and pronunciation examples; ordinary lesson progression remains in effect.",
        "textDirection": "ltr", "temporarySample": True, "flagCode": "IT",
        "createDuels": False,
        "mediaAttributions": [{
            "author": "QuisquisLingo", "license": "All rights reserved",
            "title": "Exercise Laboratory printed-character specimens",
            "source": "Original deterministic block lettering generated by tools/generate_exercise_laboratory_254.py; no external font or image source.",
            "appliesTo": "Embedded A, E and È PNGs, including the blue E variant, in Recognize characters examples.",
        }],
        "keywords": ["exercise laboratory", "authoring", "Italian", "examples"],
        "lessons": lab.lessons,
    }
    # The checksum excludes the local verification status.
    checksum_value = dict(value)
    checksum_value.pop("publisherVerificationStatus")
    canonical = json.dumps(checksum_value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    value["officialChecksum"] = hashlib.sha256(canonical).hexdigest()
    return value


def coverage(lab: Laboratory) -> str:
    preset_counts: dict[str, int] = {}
    for case in lab.cases:
        preset_counts[case["preset"]] = preset_counts.get(case["preset"], 0) + 1
    rows = [
        "# Build 254 Exercise Laboratory coverage", "",
        "This document and the JSON are generated together by `tools/generate_exercise_laboratory_254.py`. Run its `--check` mode to detect drift. The current repository model, editor and learner are the source of truth; the Course does not add a new primitive or engine feature.", "",
        f"- Course: **Exercise Laboratory**, `{COURSE_ID}`.",
        "- Direction: English (`en-GB`) → Italian (`it-IT`); TTS `it-IT`.",
        "- Model 11, official Course version 1.0.0; all Lessons, Rounds and Content are Published.",
        f"- Exactly five Lessons, {sum(len(lesson['rounds']) for lesson in lab.lessons)} Rounds and {len(lab.cases)} runnable examples across all {len(preset_counts)} authoring presets.",
        "- Course rights explicitly allow Fork, so the bundled original can be inspected and a derivative can use the ordinary authoring/confirm/export/import paths.",
        "- Create Duels is off: Presentation is non-evaluable and the Course is not padded to manufacture Duel pools. The required per-Lesson Duel metadata is retained.",
        "- This Course leaves existing Course identities, learner data and media assets unchanged.", "",
        "## Source inventory and supported modes", "",
        "The authoring registry is `lib/models/exercise_authoring.dart`. Its 24 presets map to Select (11), Input (5), Arrange (3), Match (4), and Presentation (1). `lib/services/exercise_draft_builder.dart` exposes the additional Choose multiple-selection/inline-gap modes and Word order/Build the translation inline-gap modes. `lib/widgets/script_recognition_editor.dart` exposes both character-recognition directions. `lib/screens/round_screen.dart` is the completion/evaluation reference.", "",
        "| Lesson | Preset | Examples |", "| --- | --- | ---: |",
    ]
    for lesson in ("Select", "Input", "Arrange", "Match", "Presentation"):
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
    return "\n".join(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    lab = laboratory()
    outputs = {ASSET: json.dumps(course(lab), ensure_ascii=False, indent=2) + "\n", COVERAGE: coverage(lab)}
    for path, expected in outputs.items():
        if args.check:
            if not path.is_file() or path.read_text(encoding="utf-8") != expected:
                raise SystemExit(f"Generated output differs: {path.relative_to(ROOT)}")
        else:
            path.write_text(expected, encoding="utf-8", newline="\n")
    print(f"Exercise Laboratory {'verified' if args.check else 'generated'}: {len(lab.lessons)} Lessons, {sum(len(l['rounds']) for l in lab.lessons)} Rounds, {len(lab.cases)} examples, {len({c['preset'] for c in lab.cases})} presets.")


if __name__ == "__main__":
    main()
