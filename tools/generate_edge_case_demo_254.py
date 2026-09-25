#!/usr/bin/env python3
"""Regenerate only the QQL 254 Italian-to-English edge-case demo.

The Course identity was allocated once with Course.newCourseId(). Regeneration
preserves it and every authored ID. Existing bundled media are referenced without
copying, renaming or changing them. Run --check to detect asset drift without writes.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/courses/edge_case_it_en.json"
COURSE_ID = "course_6f6a1fa3-b834-4936-b324-92fb57f73502"
STAMP = "2026-09-25T00:00:00.000Z"
PREFIX = "qql_edge_254_"
VOCAB_UNICODE_ID = PREFIX + "v_caffè_日本語"


def pid(case: str) -> str:
    return PREFIX + case


def text(value: str, role: str = "primary", kind: str = "text") -> dict:
    return {"role": role, "type": kind, "text": value}


def image(name: str, alternative: str) -> dict:
    return {"role": "clue", "type": "image", "text": alternative,
            "asset": f"assets/exercise_images/{name}.webp"}


def item(case: str, index: int, value: str) -> dict:
    return {"id": f"{pid(case)}_i{index}", "content": [text(value)]}


def exercise(case: str, preset: str, prompt: list, interaction: dict,
             evaluation: dict, *, draft: bool = False, refs: tuple = ()) -> dict:
    value = {"id": pid(case), "publicationState": "draft" if draft else "published",
             "kind": "exercise", "required": True, "editorTemplate": preset,
             "exercise": {"updatedAt": STAMP, "prompt": prompt,
                          "interaction": interaction, "evaluation": evaluation}}
    if refs:
        value["sourceRefs"] = list(refs)
    return value


def select(case: str, question: str, options: list[str], *, correct: int = 1,
           preset: str = "choice", before: tuple = (), draft: bool = False,
           refs: tuple = (), correct_indices: tuple = ()) -> dict:
    choices = correct_indices or (correct,)
    return exercise(case, preset, [*before, text(question, "question")],
                    {"kind": "select", "minSelections": len(choices),
                     "maxSelections": len(choices),
                     "items": [item(case, i, value) for i, value in enumerate(options, 1)]},
                    {"kind": "selected_items",
                     "correctItemIds": [f"{pid(case)}_i{i}" for i in choices]},
                    draft=draft, refs=refs)


def input_case(case: str, prompt: str, answers: list[str], *,
               preset: str = "type_translation", audio: str | None = None,
               refs: tuple = ()) -> dict:
    prompts = [text(prompt)]
    if audio is not None:
        prompts.append(text(audio, kind="audio"))
    return exercise(case, preset, prompts, {"kind": "input", "inputType": "text"},
                    {"kind": "text_match", "acceptedAnswers": answers}, refs=refs)


def arrange(case: str, prompt: str, blocks: list[str], orders: list[list[int]], *,
            preset: str = "word_order", images: tuple = ()) -> dict:
    separator = "" if preset == "image_word" else " "
    return exercise(case, preset, [text(prompt, "clue"), *images],
                    {"kind": "arrange",
                     "items": [item(case, i, value) for i, value in enumerate(blocks, 1)]},
                    {"kind": "ordered_items", "correctOrders": [
                        {"text": separator.join(blocks[i - 1] for i in order),
                         "itemIds": [f"{pid(case)}_i{i}" for i in order]}
                        for order in orders]})


def gaps(case: str, prompt: str, blocks: list[str], layout: list,
         assignments: list[int], *, select_mode: bool = False) -> dict:
    mode = "select" if select_mode else "arrange"
    interaction = {"kind": mode,
                   "items": [item(case, i, value) for i, value in enumerate(blocks, 1)],
                   "layout": [text(f"{pid(case)}_g{part}", kind="gap")
                              if isinstance(part, int) else text(part) for part in layout]}
    if select_mode:
        interaction.update(minSelections=1, maxSelections=1)
    return exercise(case, "choice" if select_mode else "word_order",
                    [text(prompt, "primary" if select_mode else "clue")], interaction,
                    {"kind": "selected_items" if select_mode else "gap_items",
                     "gapAssignments": {f"{pid(case)}_g{i}": f"{pid(case)}_i{choice}"
                                        for i, choice in enumerate(assignments, 1)}})


def note(case: str, value: str, *, kind: str = "explanation", role: str = "overview",
         draft: bool = False, refs: tuple = ()) -> dict:
    result = {"id": pid(case), "publicationState": "draft" if draft else "published",
              "kind": kind, "required": False, "role": role, "text": value}
    if refs:
        result["sourceRefs"] = list(refs)
    return result


def round_case(case: str, title: str, contents: list, *, visual: str = "generic",
               draft: bool = False) -> dict:
    value = {"id": pid(case), "publicationState": "draft" if draft else "published",
             "updatedAt": STAMP, "visualType": visual, "content": contents}
    if title:
        value["title"] = title
    return value


def lesson(case: str, title: str, rounds: list, vocabulary: list[str], *,
           overview: str, draft: bool = False, draft_guidebook: bool = False,
           section: str | None = None, icon: str | None = None,
           extra_guidebook: tuple = ()) -> dict:
    guidebook = {"content": [note(case + "_overview", overview),
                            *[note(f"{case}_v{i}", pair, kind="vocabulary", role="vocabulary")
                              for i, pair in enumerate(vocabulary, 1)], *extra_guidebook]}
    if draft_guidebook:
        guidebook["publicationState"] = "draft"
    value = {"lessonId": pid(case), "publicationState": "draft" if draft else "published",
             "updatedAt": STAMP, "title": title, "section": section is not None,
             "guidebook": guidebook, "rounds": rounds,
             "duel": {"id": pid(case + "_duel"), "title": "Duel"}}
    if section is not None:
        value["sectionName"] = section
    if icon is not None:
        value["themeIconAsset"] = f"assets/lesson_icons/{icon}.png"
    return value


def build_course() -> dict:
    long_passage = (
        "On a rainy afternoon, the librarian opens a small notebook and reads a visitor's message. "
        "The visitor writes the names café, naïve, São Tomé, Łódź, 東京, 서울, Αθήνα and القاهرة, "
        "then adds a smiling face 🙂 and a musical note ♫. These names are quoted text, not new "
        "language lessons. The shelves hold dictionaries, maps, old photographs and books with "
        "very long titles. A child asks why the same word can appear twice in a sentence. The "
        "librarian answers that repetition can be intentional and that each printed occurrence "
        "still has its own place. Outside, the rain stops, a red bicycle leans against a wall, "
        "and the clock above the door shows five o'clock. "
    ) * 2 + "The notebook is blue."
    long_answer = (
        "Today I am writing a careful message to my friend because the train is late, "
        "the station is crowded, and I would like to explain that I will arrive after dinner "
        "with a small blue suitcase and a book about the history of our town."
    )
    l1 = lesson("l01", "Testi lunghi, Unicode e opzioni: café · 東京 · القاهرة · 🙂", [
        round_case("r01", "Scelte minime, numerose e ripetute", [
            note("intro01", "Demo di collaudo: risposte e avvisi intenzionali sono nella matrice 254. "
                 "Completa i casi Published; i casi Draft restano nell’Editor.", role="lesson_intro"),
            select("e01_min", "Traduci «sì» in inglese.", ["yes", "no"]),
            select("e02_max_translation", "una finestra", ["a window", "a door", "a roof", "a wall", "a floor"],
                   preset="translation_choice_to_target"),
            select("e03_many", "Quale numero inglese corrisponde a «dodici»?", [
                "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"], correct=12),
            select("e04_duplicate", "Quale colore inglese corrisponde a «rosso»? Le due opzioni blue sono intenzionali.",
                   ["red", "blue", "blue"]),
            select("e05_unicode", "Nella nota «café / café — 東京・서울・Αθήνα・القاهرة 🙂», traduci «ciao».",
                   ["hello", "goodbye"], refs=(VOCAB_UNICODE_ID,)),
            select("e06_multi", "Seleziona entrambi i nomi di animali in inglese.",
                   ["cat", "chair", "dog", "window"], correct_indices=(1, 3)),
        ]),
        round_case("r02", "Passaggi e risposte estese", [
            select("e07_long", "Di che colore è il quaderno?", ["blue", "red", "green"],
                   preset="reading_comprehension", before=(text(long_passage, "passage"),)),
            input_case("e08_long_answer", "Traduci: Oggi scrivo un messaggio accurato al mio amico perché il treno "
                       "è in ritardo, la stazione è affollata e vorrei spiegare che arriverò dopo cena con una piccola "
                       "valigia blu e un libro sulla storia della nostra città.", [long_answer]),
            input_case("e09_accents", "Scrivi il prestito inglese per un piccolo locale dove bere un caffè: café. "
                       "Sono accettate le forme Unicode composta e decomposta.", ["café", "café"],
                       refs=(VOCAB_UNICODE_ID,)),
            input_case("e10_names", "Copia esattamente questa citazione con nomi internazionali: 東京 서울 Αθήνα القاهرة",
                       ["東京 서울 Αθήνα القاهرة"], preset="fill_blank"),
        ], visual="story"),
        round_case("r03", "Blocchi ripetuti e risposte alternative", [
            arrange("e11_repeat", "Ricostruisci: Mi piace molto, molto questo libro.",
                    ["I", "really", "really", "like", "this", "book"], [[1, 2, 3, 4, 5, 6]]),
            arrange("e12_alternatives", "Traduci: Oggi studio a casa.",
                    ["I", "study", "at", "home", "today"], [[1, 2, 3, 4, 5], [5, 1, 2, 3, 4]],
                    preset="build_translation"),
            arrange("e13_many_blocks", "Ricostruisci la frase inglese: Il piccolo gatto nero dorme sempre "
                    "tranquillamente vicino alla finestra aperta della nostra calda cucina ogni pomeriggio.",
                    ["the", "small", "black", "cat", "always", "sleeps", "quietly", "beside", "the", "open",
                     "window", "in", "our", "warm", "kitchen", "every", "afternoon", "outside", "never"],
                    [list(range(1, 18))]),
        ])
    ], ["yes = sì", "a window → una finestra", "red - rosso", "blue: blu", "hello = ciao", "hello = ciao"],
       overview="Casi validi per testo lungo, caratteri Unicode, opzioni numerose e ripetizioni intenzionali.",
       section="Collaudo dei contenuti — Unicode e confini", icon="school",
       extra_guidebook=(note("v_caffè_日本語", "café = caffè", kind="vocabulary", role="vocabulary"),))
    l2 = lesson("l02", "Uno o più gap, blocchi e opzioni collegate", [
        round_case("r04", "Arrange: uno e più gap", [
            note("intro02", "Completa i gap: Arrange consuma un blocco distinto per ogni occorrenza; "
                 "Select permette di riutilizzare la stessa opzione.", role="lesson_intro"),
            gaps("e14_arrange_min", "Completa la frase inglese con l’unico blocco.", ["tea"],
                 ["I drink", 1, "."], [1]),
            gaps("e15_arrange_repeat", "Completa con due occorrenze distinte di very.",
                 ["very", "very", "never"], ["It is", 1, ",", 2, "cold."], [1, 2]),
            gaps("e16_arrange_phrases", "Inserisci le espressioni nei due gap.",
                 ["would like", "a cup of tea", "has been", "a glass of milk"],
                 ["I", 1, 2, ", please."], [1, 2]),
        ]),
        round_case("r05", "Select: gap singolo e riuso", [
            gaps("e17_select_min", "Completa: un gatto.", ["cat"], ["a", 1], [1], select_mode=True),
            gaps("e18_select_linked", "Completa entrambe le domande riutilizzando la stessa opzione.",
                 ["Was", "Were", "Are"], [1, "she happy?", 2, "he late?"], [1, 1], select_mode=True),
            gaps("e19_select_distinct", "Completa con due opzioni diverse.",
                 ["am", "to", "is", "from"], ["I", 1, "going", 2, "London."], [1, 2], select_mode=True),
        ])
    ], ["tea = tè", "very = molto", "would like = vorrei", "a cup of tea = una tazza di tè"],
       overview="Arrange usa occorrenze separate; Select può riutilizzare una stessa opzione in più gap.")
    l3 = lesson("l03", "Immagini, MP3 e fallback TTS", [
        round_case("r06", "Con e senza immagini", [
            note("intro03", "Confronta immagini e testo, poi verifica i campioni MP3 e le frasi TTS. "
                 "Le registrazioni preinstallate sono campioni di riproduzione, senza trascrizione verificata.", role="lesson_intro"),
            arrange("e20_image_letters", "Componi il nome inglese dell’animale nell’immagine.",
                    ["c", "a", "t"], [[1, 2, 3]], preset="image_word", images=(image("cat", "gatto"),)),
            select("e21_image", "Come si chiama in inglese il cibo raffigurato?", ["ice cream", "bread", "rice"],
                   before=(image("ice_cream", "gelato"),)),
            select("e22_no_image", "Traduci «gelato» senza un’immagine di supporto.", ["ice cream", "bread", "rice"]),
            select("e23_two_images", "Quale coppia inglese descrive le due immagini nell’ordine mostrato?",
                   ["cat and dog", "dog and cat", "cat and bird"],
                   before=(image("cat", "gatto"), image("dog", "cane"))),
        ]),
        round_case("r07", "Riproduzione registrata e sintesi", [
            select("e24_mp3", "Collaudo MP3 1: se senti il campione, scegli «audio riprodotto». "
                   "Il campione preinstallato non ha una trascrizione verificata; questa è una prova di riproduzione.",
                   ["audio riprodotto", "nessun audio"], preset="listening_choice",
                   before=(text("recorded sample one", kind="audio"),)),
            select("e25_mp3_sequence", "Collaudo MP3 1 + 2: verifica che si sentano due campioni in sequenza. "
                   "Le etichette audio sono identificatori di collaudo, non trascrizioni.",
                   ["due campioni riprodotti", "riproduzione incompleta"], preset="listening_choice",
                   before=(text("recorded sample one recorded sample two", kind="audio"),)),
            select("e26_tts", "Quale animale è vicino alla finestra nel testo pronunciato?",
                   ["cat", "dog", "bird"], preset="listening_comprehension",
                   before=(text("The little cat is sitting beside the open window.", "passage", "audio"),)),
            input_case("e27_tts_spelling", "Scrivi la frase inglese che senti.",
                       ["We are ready to leave."], preset="listening_spelling", audio="We are ready to leave."),
        ], visual="listening")
    ], ["cat = gatto", "dog = cane", "ice cream = gelato", "window = finestra"],
       overview="Modalità iniziale Hybrid: i campioni MP3 verificano la riproduzione; le frasi inglesi non mappate "
       "usano TTS. Attiva Enable Audio Exercises e Text-to-speech per eseguire tutti i casi.", icon="speech_bubbles")
    l4 = lesson("l04", "Published con discendenti Draft", [
        round_case("r08", "", [
            note("intro04", "Qui il Learner mostra soltanto i contenuti Published. "
                 "Il GuideBook, un Exercise e il Round successivo sono Draft validi.", role="lesson_intro"),
            select("e28_published", "Traduci «pronto» in inglese.", ["ready", "late"]),
            select("e29_draft_exercise", "Caso Draft valido: traduci «tardi» in inglese.", ["late", "ready"], draft=True),
        ], visual="test"),
        round_case("r09_draft", "Round Draft con contenuto valido", [
            select("e30_under_draft_round", "Contenuto Published sotto Round Draft: traduci «presto».", ["early", "late"]),
        ], draft=True),
    ], ["ready = pronto", "late = tardi"], overview="Il primo Round non ha titolo personalizzato. "
       "Il GuideBook e il secondo Round sono Draft; il Learner vede soltanto il primo Exercise Published.",
       draft_guidebook=True,
       extra_guidebook=(note("l04_draft_vocab", "early = presto", kind="vocabulary", role="vocabulary", draft=True),))
    l5 = lesson("l05_draft", "Lesson Draft valida — candidato per copia e confronto", [
        round_case("r10_under_draft_lesson", "Round Published sotto Lesson Draft", [
            note("intro05", "Questa Lesson Draft è una struttura completa per ispezione e Preview; "
                 "il Learner la omette anche se i suoi discendenti sono Published.", role="lesson_intro"),
            select("e31_under_draft_lesson", "Traduci «una copia» in inglese.", ["a copy", "a window"]),
        ])
    ], ["a copy = una copia"], overview="Lesson intenzionalmente Draft con struttura completa. "
       "Ispezionala nell’Editor o in Preview; il Learner la omette.", draft=True)
    course = {
        "formatVersion": 11, "publicationState": "published", "lessonNumberingMode": "lesson",
        "defaultLessonIconStyle": "monochrome", "createDuels": False,
        "courseId": COURSE_ID, "originType": "bundledOfficial", "publisherId": "org.quisquislingo",
        "publisherName": "QuisquisLingo", "officialCourseVersion": "1.0.0",
        "officialReleaseDateUtc": STAMP, "officialReleaseNotes": "QQL Build 254: edge-case demonstration Course.",
        "distributionChannel": "bundled", "publisherVerificationStatus": "verified",
        "originalCourseCreator": {"type": "publisher", "id": "org.quisquislingo", "displayName": "QuisquisLingo"},
        "originalCreatedAtUtc": STAMP, "modifiedAtUtc": STAMP,
        "learningLanguage": "English", "interfaceLanguage": "Italian",
        "sourceLanguage": "Italian", "targetLanguage": "English",
        "sourceLanguageTag": "it-IT", "targetLanguageTag": "en-GB",
        "title": "AI-Slop Demo: Edge Case Course",
        "ttsLanguage": "en-GB", "audioMode": "hybrid",
        "authors": [{"name": "QuisquisLingo — AI-generated test content", "roles": ["Author"]}],
        "license": "All rights reserved; derivative works allowed for this test Course.",
        "derivativeWorksPolicy": "allowed", "courseDescription":
            "TEMPORARY AI-GENERATED TEST COURSE. Italiano → inglese. Per trovarlo abilita Show unavailable: "
            "contiene strutture Draft valide, omesse nel Learner. Include due avvisi Audit intenzionali "
            "(opzioni duplicate e testo lungo). Hybrid prova MP3 preinstallati e fallback TTS; i campioni MP3 "
            "non hanno una trascrizione verificata e sono solo prove di riproduzione. Fork abilita i collaudi "
            "Copy as New Course e Merge su copie personali. Non è un percorso didattico revisionato.",
        "textDirection": "ltr", "flagCode": "GB", "temporarySample": True,
        "keywords": ["demo", "edge cases", "Unicode", "audio", "Draft"],
        "audioLibrary": [
            {"id": pid("audio_01"), "text": "recorded sample one", "filePath": "assets/audio/en_sample/sample_1.mp3"},
            {"id": pid("audio_02"), "text": "recorded sample two", "filePath": "assets/audio/en_sample/sample_2.mp3"},
        ],
        "lessons": [l1, l2, l3, l4, l5],
    }
    canonical = {key: value for key, value in course.items()
                 if key not in {"officialChecksum", "publisherVerificationStatus", "publisherSignature"}}
    course["officialChecksum"] = hashlib.sha256(json.dumps(
        canonical, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")).hexdigest()
    return course


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check reproducibility without writing")
    args = parser.parse_args()
    encoded = json.dumps(build_course(), ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != encoded:
            print(f"OUT OF DATE: {OUTPUT.relative_to(ROOT)}")
            return 1
        print(f"OK: {OUTPUT.relative_to(ROOT)} matches its deterministic generator")
    else:
        OUTPUT.write_text(encoded, encoding="utf-8", newline="\n")
        print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
