#!/usr/bin/env python3
"""Generate QQL Demo: English from Italian (Build 260 Revision 2, owner
request of 1 October 2026).

One Lesson with a GuideBook: three ordinary Rounds, the Story "Al bar",
three more ordinary Rounds, the Story "Alla stazione". The 36 exercises of
the ordinary Rounds are of 36 different types and are mixed at random with a
fixed seed, six to a Round; the Lesson's first Round opens with a Before
you start card that offers the GuideBook (Build 260 Revision 3: the only
card). The mix keeps one exercise that needs audio and
at most one card (flashcard or note) per Round, so every Round still plays
with Audio Exercises off. The Course is Italian-based, so its learner panel
is in Italian (Build 260 Revisions 0 and 1). The Course ID was allocated
once (UUIDv4); regeneration keeps every ID. Uses only stdlib. Run --check to
verify without writing.
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
from generate_piedmontais_demo_254 import (  # noqa: E402
    arrange, audio, choose, enter, flashcard, gaps, image, match, note, picture_card, text, turn,
)
from qql_course_v12 import becomes_exercise, convert_course_v11_to_v12, story_cover, story_flow, story_line  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/courses/english_from_italian_it_en.json"
# Allocated once (UUIDv4) in Build 260 Revision 2.
COURSE_ID = "course_65dce83b-fd0a-4b83-a5a1-8f8b97a58d05"
PREFIX = "enit_65dce83b"
STAMP = "2026-10-01T00:00:00.000Z"
SEED = 260002
PER_ROUND = 6
PRACTICE_ROUNDS = 6
# The audio exercises need Audio Exercises on; the cards score nothing.
AUDIO_PRESETS = {"listening_choose_target", "listening_answer_target", "listening_spelling",
                 "missing_word", "spell_heard", "listening_image_choice"}
CARD_PRESETS = {"flashcard", "picture_flashcard", "note_card"}
AUDIO_NOTE = (
    "L'audio usa la sintesi vocale del dispositivo con en-GB: gli esercizi di ascolto richiedono "
    "una voce inglese sul dispositivo."
)

OVERVIEW = (
    "Primi passi in inglese: saluti e parole di cortesia, cibo e bevande, animali, colori e il "
    "verbo to be. Sei Round mescolano tipi di esercizi diversi; dopo il terzo una Story ti porta "
    "al bar, alla fine una seconda Story alla stazione. " + AUDIO_NOTE)
NOTES = [
    "A o an. Si usa a davanti a un suono consonantico (a cat, a dog) e an davanti a un suono "
    "vocalico (an apple, an orange). The vale per tutto: the cat, the apple.",
    "Il verbo to be. I am, you are, he, she, it is: I am a student, you are Tom, it is a cat. "
    "Nel parlato si accorcia: I'm, you're, it's.",
    "L'aggettivo prima del nome. In inglese l'aggettivo precede il nome e non cambia: the red "
    "book, the white cat, two red books.",
    "Saluti. Good morning si dice fino a mezzogiorno, good night prima di andare a dormire; "
    "hello e hi per salutare, goodbye e bye per congedarsi.",
]
VOCABULARY = [
    "ciao = hello, hi",
    "buongiorno = good morning",
    "buonanotte = good night",
    "arrivederci = goodbye",
    "a domani = see you tomorrow",
    "come stai? = how are you?",
    "bene, grazie = fine, thanks",
    "grazie = thank you",
    "prego = you're welcome",
    "per favore = please",
    "mi chiamo Anna = my name is Anna",
    "il pane = the bread",
    "l'acqua = the water",
    "il latte = the milk",
    "il caffè = the coffee",
    "il tè = the tea",
    "la mela = the apple",
    "l'arancia = the orange",
    "il gatto = the cat",
    "il cane = the dog",
    "il cavallo = the horse",
    "la mucca = the cow",
    "il maiale = the pig",
    "la pecora = the sheep",
    "il libro = the book",
    "rosso = red",
    "bianco = white",
    "nero = black",
    "caldo = hot",
    "freddo = cold",
    "grande = big",
    "piccolo = small",
    "il treno = the train",
    "il binario = the platform",
    "che ore sono? = what time is it?",
]


def practice_exercises() -> list[dict]:
    """The 36 exercises of the ordinary Rounds, one per type, before the mix."""
    return [
        choose("choice_target", [text("Come si dice «pane» in inglese?", "question")],
               ["bread", "water", "milk"]),
        choose("choice_source", [text("Che cosa significa «you're welcome»?", "question", "source")],
               ["grazie", "prego", "per favore"], 1, language="source"),
        choose("true_false", [text("A cat is an animal.", "question")], ["Vero", "Falso"], 0,
               language="source"),
        # Pick the missing word has an Instruction or context since Build 260
        # Revision 3.
        choose("gap_choice", [text("Scegli la forma giusta di to be."), text("I ___ a student.", "question")],
               ["is", "am", "are"], 1),
        choose("icon_choice", [text("Seleziona l'immagine di «dog».", "question")], ["cat", "horse", "dog"], 2,
               pictures=["cat", "horse", "dog"]),
        choose("listening_choose_target", [text("Ascolta il saluto."), audio("good morning")],
               ["good night", "good morning", "goodbye"], 1),
        choose("listening_answer_target", [audio("I have a cat and a dog.", "passage"),
                                           text("Which animal comes first?", "question")],
               ["a dog", "a cat", "a horse"], 1),
        choose("reading_answer_target", [text("Anna incontra Tom la mattina.", "context", "source"),
                                         *turn("Good morning, Tom!", "Anna"),
                                         *turn("Good morning, Anna! How are you?", "Tom"),
                                         text("What does Tom ask?", "question")],
               ["How are you?", "Good night!", "Thank you!"]),
        enter("type_translation_to_target", [text("grazie")], ["thank you", "thanks"]),
        enter("type_translation_to_source", [text("good night", language="target")],
              ["buonanotte", "buona notte"]),
        arrange("build_translation_to_target", [text("il libro rosso")], ["book", "red", "the", "a"],
                [[2, 1, 0]]),
        arrange("build_translation_to_source", [text("the white cat", language="target")],
                ["gatto", "bianco", "il", "cane"], [[2, 0, 1]], language="source"),
        choose("translation_choice_to_target", [text("il cane", "question")],
               ["the dog", "the cat", "the horse"]),
        choose("translation_choice_to_source", [text("see you tomorrow", "question")],
               ["buonanotte", "a domani", "per favore"], 1),
        enter("complete_text", [text("I have a cat and a dog.")], [], missingWords=["cat", "dog"],
              hint="Uno miagola, l'altro abbaia."),
        enter("missing_letters", [text("I like apples.")], [], missingWords=["ppl"],
              hint="Un frutto rosso o verde."),
        enter("type_missing_word", [text("I drink ___ every day.")], ["water"],
              hint="La bevi quando hai sete."),
        enter("listening_spelling", [text("Scrivi la parola che senti."), audio("apple")], []),
        enter("missing_word", [text("Good morning, how are you?"), audio("Good morning, how are you?")], [],
              missingWords=["morning", "you"]),
        match("word_match", "Abbina le parole italiane a quelle inglesi.",
              [("pane", "bread"), ("acqua", "water"), ("latte", "milk")]),
        match("super_match", "Abbina gli opposti.", [("hot", "cold"), ("big", "small"), ("black", "white")]),
        match("picture_word_match", "Abbina ogni animale alla sua parola.",
              [("cow", "cow"), ("pig", "pig"), ("sheep", "sheep")]),
        arrange("word_order", [text("Metti in ordine la domanda per chiedere come sta qualcuno.", "clue")],
                ["are", "How", "you"], [[1, 0, 2]]),
        gaps("gap_blocks", "Completa la presentazione.", ["My", ("name",), ("is",), "Anna."], ["are"]),
        choose("one_word_fills_all", [text("I have ___ cat and ___ dog.", "question")], ["an", "a", "is"], 1),
        arrange("sentence_order", [text("Tom incontra Anna per strada e la saluta per primo.", "clue")],
                ["Hello, Anna!", "Hi, Tom! How are you?", "Fine, thanks."], [[0, 1, 2]]),
        arrange("image_word", [text("Scrivi in inglese l'animale della foto.", "clue"), image("dog", "Un cane")],
                # The spelling presets store the blocks in the word's order; the
                # Round shuffles them.
                ["d", "o", "g"], [[0, 1, 2]]),
        arrange("spell_word", [text("gatto", "clue", "source")], ["c", "a", "t"], [[0, 1, 2]]),
        arrange("spell_heard", [audio("milk")], ["m", "i", "l", "k"], [[0, 1, 2, 3]]),
        choose("listening_image_choice", [audio("horse")], ["cow", "horse", "pig"], 1,
               pictures=["cow", "horse", "pig"]),
        choose("picture_choice", [text("Che cos'è?"), image("apple", "Una mela", "picture")],
               ["an orange", "an egg", "an apple"], 2),
        enter("picture_name", [text("Che cos'è?"), image("bread", "Pane", "picture")], ["{the} bread"]),
        arrange("picture_blocks", [text("Che cos'è?"), image("cat", "Un gatto", "picture")], ["a", "cat", "an"],
                [[0, 1]], hint="Ricorda l'articolo."),
        picture_card("coffee", "caffè", "coffee", "A coffee, please.", "Un caffè, per favore."),
        note("A o an?", "A davanti a un suono consonantico: a cat, a dog. An davanti a un suono vocalico: "
                        "an apple, an egg."),
        flashcard("thank you", "grazie", "Thank you, Anna!", "Grazie, Anna!"),
    ]


def preset_of(content: dict) -> str:
    return content["editorTemplate"]


def mixed_rounds(exercises: list[dict]) -> list[list[dict]]:
    """Six Rounds of six, mixed at random: one audio exercise in each Round
    and never two cards in one."""
    audio_ones = [c for c in exercises if preset_of(c) in AUDIO_PRESETS]
    others = [c for c in exercises if preset_of(c) not in AUDIO_PRESETS]
    assert len(audio_ones) == PRACTICE_ROUNDS and len(others) == PRACTICE_ROUNDS * (PER_ROUND - 1)
    for attempt in range(1000):
        generator = random.Random(SEED + attempt)
        heard, rest = audio_ones[:], others[:]
        generator.shuffle(heard)
        generator.shuffle(rest)
        rounds = []
        for number in range(PRACTICE_ROUNDS):
            members = rest[number * (PER_ROUND - 1):(number + 1) * (PER_ROUND - 1)] + [heard[number]]
            generator.shuffle(members)
            rounds.append(members)
        if all(sum(preset_of(c) in CARD_PRESETS for c in members) <= 1 for members in rounds):
            return rounds
    raise AssertionError("no mix met the rules")


def with_ids(content: dict, content_id: str) -> dict:
    """The Content with its ID and its items' IDs, as the Piedmontese demo
    names them."""
    content = copy.deepcopy(content)
    content["id"] = content_id
    if content["kind"] != "exercise":
        return content
    payload = content["exercise"]
    payload["updatedAt"] = STAMP
    items = payload["interaction"].get("items", [])
    ids = {item["id"]: f"{content_id}_{item['id']}" for item in items}
    for item in items:
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
    return content


def introduction(round_id: str, text_value: str) -> dict:
    """A Lesson introduction, which the conversion turns into a Before you
    start card offering the GuideBook (Build 257)."""
    return {"id": f"{round_id}_intro", "publicationState": "published", "kind": "text",
            "required": False, "role": "lesson_intro", "text": text_value}


def practice_round(number: int, round_id: str, members: list[dict]) -> dict:
    # Only the Lesson's first Round opens with a card (Build 260 Revision 3).
    content = [introduction(round_id, (
        f"Primi passi: {PRACTICE_ROUNDS} Round di esercizi di tipi diversi e due Story. Apri il GuideBook "
        "per le note e le parole."))] if number == 1 else []
    content += [with_ids(member, f"{round_id}_e{index:02d}") for index, member in enumerate(members, 1)]
    return {"id": round_id, "publicationState": "published", "updatedAt": STAMP,
            "visualType": "generic", "title": f"Pratica {number}", "content": content}


TOM, EMMA, ANNA, BEN = (f"{PREFIX}_character_{name}" for name in ("tom", "emma", "anna", "ben"))
NARRATOR = ""


def story_round(round_id: str, title: str, cover: tuple[str, str, str],
                steps: list[tuple[str, object]]) -> dict:
    """A Story: its cover, then lines (speaker, text) and exercises (a v11
    exercise Content) in order; no card, as it is not the Lesson's first
    Round."""
    content = []
    picture, alternative, title_line = cover
    content.append({"id": f"{round_id}_cover", "publicationState": "published", "kind": "exercise",
                    "required": True, "editorTemplate": "story_cover",
                    "exercise": story_cover(updated_at=STAMP, picture=f"assets/exercise_images/{picture}.webp",
                                            alternative=alternative, title_line=title_line)})
    for index, (speaker, step) in enumerate(steps, 1):
        step_id = f"{round_id}_s{index:02d}"
        if isinstance(step, str):
            content.append({"id": step_id, "publicationState": "published", "kind": "exercise",
                            "required": True, "editorTemplate": "dialogue_line",
                            "exercise": story_line(step, updated_at=STAMP, speaker_id=speaker)})
        else:
            content.append(with_ids(step, step_id))
    return {"id": round_id, "publicationState": "published", "updatedAt": STAMP,
            "visualType": "story", "title": title, "content": content,
            "flow": story_flow([(c["id"], becomes_exercise(c)) for c in content], title=title)}


def cafe_story(round_id: str) -> dict:
    return story_round(round_id, "Al bar", ("coffee", "Un caffè", "At the café"), [
        (NARRATOR, "Tom entra in un bar di Londra."),
        (EMMA, "Good morning! What would you like?"),
        (TOM, "A coffee, please."),
        ("", choose("translation_choice_to_source", [text("A coffee, please.", "question")],
                    ["Un caffè, per favore.", "Un tè, grazie.", "Buongiorno!"])),
        (EMMA, "Here you are. That's two pounds."),
        (TOM, "Thank you!"),
        ("", choose("choice_source", [text("Che cosa ordina Tom?", "question", "source")],
                    ["un tè", "un caffè", "un succo"], 1, language="source")),
        (EMMA, "You're welcome. Have a nice day!"),
    ])


def station_story(round_id: str) -> dict:
    return story_round(round_id, "Alla stazione", ("train", "Un treno", "At the station"), [
        (NARRATOR, "Anna è alla stazione: vuole andare a Oxford."),
        (ANNA, "Excuse me, where is the train to Oxford?"),
        (BEN, "It's on platform two."),
        ("", choose("true_false", [text("The train to Oxford is on platform two.", "question")],
                    ["Vero", "Falso"], 0, language="source")),
        (ANNA, "Thank you. What time is it?"),
        (BEN, "It's ten o'clock."),
        ("", arrange("word_order", [text("Metti in ordine la domanda di Anna.", "clue")],
                     ["time", "What", "it", "is"], [[1, 0, 3, 2]])),
        (NARRATOR, "Anna sale sul treno. Buon viaggio!"),
    ])


def guidebook(lesson_id: str) -> dict:
    def entry(number: int, kind: str, role: str, value: str) -> dict:
        return {"id": f"{lesson_id}_g{number:02d}", "publicationState": "published", "kind": kind,
                "required": False, "role": role, "text": value}
    content = [entry(1, "explanation", "overview", OVERVIEW)]
    for value in NOTES:
        content.append(entry(len(content) + 1, "explanation", "grammar", value))
    for word in VOCABULARY:
        # The Review reads "prompt = answer"; its other separators stay out.
        assert word.count(" = ") == 1 and ":" not in word and " - " not in word and " → " not in word, word
        content.append(entry(len(content) + 1, "vocabulary", "vocabulary", word))
    return {"content": content}


def build_course_v11() -> dict:
    lesson_id = f"{PREFIX}_l01"
    exercises = practice_exercises()
    presets = [preset_of(c) for c in exercises]
    assert len(exercises) == PRACTICE_ROUNDS * PER_ROUND and len(set(presets)) == len(presets), presets
    groups = mixed_rounds(exercises)
    rounds = []

    def round_id() -> str:
        return f"{lesson_id}_r{len(rounds) + 1:02d}"

    for number, members in enumerate(groups, 1):
        rounds.append(practice_round(number, round_id(), members))
        if number == 3:
            rounds.append(cafe_story(round_id()))
    rounds.append(station_story(round_id()))
    lesson = {
        "lessonId": lesson_id, "publicationState": "published", "updatedAt": STAMP,
        "section": False, "title": "Primi passi",
        "themeIconAsset": "assets/lesson_icons/speech_bubbles.png",
        "guidebook": guidebook(lesson_id),
        "rounds": rounds,
        "duel": {"id": f"{lesson_id}_duel", "title": "Duel"},
    }
    return {
        "formatVersion": 11, "publicationState": "published",
        "lessonNumberingMode": "lesson", "defaultLessonIconStyle": "monochrome",
        "createDuels": False, "courseId": COURSE_ID, "originType": "bundledOfficial",
        "publisherId": "org.quisquislingo", "publisherName": "QuisquisLingo",
        "officialCourseVersion": "1.0.0", "officialReleaseDateUtc": STAMP,
        "officialReleaseNotes": "QQL Build 260 Revision 2: one Lesson with a GuideBook, six Rounds of six "
                                "exercises of different types mixed at random and two Stories.",
        "distributionChannel": "bundled", "publisherVerificationStatus": "verified",
        "originalCourseCreator": {"type": "publisher", "id": "org.quisquislingo", "displayName": "QuisquisLingo"},
        "originalCreatedAtUtc": STAMP, "modifiedAtUtc": STAMP,
        "learningLanguage": "English", "interfaceLanguage": "Italian",
        "sourceLanguage": "Italian", "targetLanguage": "English",
        "title": "QQL Demo: English from Italian", "ttsLanguage": "en-GB", "audioMode": "tts",
        "authors": [{"name": "Claude by Anthropic (AI-generated sample; not linguistically reviewed)",
                     "roles": ["Author"]}],
        "license": "All rights reserved",
        "derivativeWorksPolicy": "forbidden",
        "languageVariant": "British English; introductory AI-authored examples awaiting review",
        "startLevel": "Beginner", "targetLevel": "Beginner",
        "courseDescription": (
            "ESEMPIO TEMPORANEO GENERATO DALL'IA, NON REVISIONATO. Dall'italiano all'inglese: una Lezione "
            "con GuideBook, sei Round di sei esercizi di tipi diversi mescolati a caso e due Story, al bar "
            "e alla stazione. I contenuti servono per le prove e vanno revisionati prima di usarli per "
            "insegnare. " + AUDIO_NOTE),
        "sourceLanguageTag": "it-IT", "targetLanguageTag": "en-GB",
        # Build 259 Revision 8: temporarySample is the Private course flag; a demo is for everyone.
        "textDirection": "ltr", "worldFlagId": "united_kingdom", "temporarySample": False,
        "lessons": [lesson],
    }


def build_course() -> dict:
    course = convert_course_v11_to_v12(build_course_v11())
    course["storyNarrator"] = {"name": "Narratore", "language": "source"}
    course["storyCharacters"] = [
        {"id": TOM, "name": "Tom", "avatar": "assets/avatars/kid.png", "language": "target", "voice": "male"},
        {"id": EMMA, "name": "Emma", "avatar": "assets/avatars/cat.png", "language": "target", "voice": "female"},
        {"id": ANNA, "name": "Anna", "avatar": "assets/avatars/monkey.png", "language": "target",
         "voice": "female"},
        {"id": BEN, "name": "Ben", "avatar": "assets/avatars/dog.png", "language": "target", "voice": "male"},
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
        print(f"PASS: {OUTPUT.relative_to(ROOT)} is reproducible; 1 Lesson, "
              f"{PRACTICE_ROUNDS} mixed Rounds of {PER_ROUND} and 2 Stories")
        return 0
    OUTPUT.write_text(rendered, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
