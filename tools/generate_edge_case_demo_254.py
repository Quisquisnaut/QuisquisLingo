#!/usr/bin/env python3
"""Regenerate only the QQL 254 Italian-to-English edge-case demo.

The Course identity was allocated once with Course.newCourseId(). Regeneration
preserves it and every authored ID. Existing bundled media are referenced without
copying, renaming or changing them. Run --check to detect drift without writes.

Build 259 Revision 5 (owner request) took the Course out of the bundle. The
generator writes two files with the same content:
- demo_courses/edge_case_it_en.json, the Course to import (Import or Open
  from...): a custom Course with its own identity, since a bundled official
  Course is never imported and the bundled identity stays reserved;
- test/fixtures/v12/edge_case_it_en.json, the former bundled Course, which the
  tests register as a bundled fixture (test/support/edge_case_fixture.dart).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qql_course_v12 import becomes_exercise, convert_course_v11_to_v12, story_cover, story_flow, story_line  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "test/fixtures/v12/edge_case_it_en.json"
EXTERNAL_OUTPUT = ROOT / "demo_courses/edge_case_it_en.json"
COURSE_ID = "course_6f6a1fa3-b834-4936-b324-92fb57f73502"
# The importable Course's identity and its QQL-user Maintainer, allocated once
# (UUIDv4) in Build 259 Revision 5.
EXTERNAL_COURSE_ID = "course_ef03d1b5-dccc-4fbb-88da-100473cddaad"
EXTERNAL_MAINTAINER = "afb065f8-701c-48d2-85f7-c80d44abecb9"
OFFICIAL_ONLY_KEYS = (
    "publisherId", "publisherName", "officialCourseVersion", "officialReleaseDateUtc",
    "officialReleaseNotes", "distributionChannel", "publisherVerificationStatus",
    "officialChecksum", "publisherSignature",
)
STAMP = "2026-09-25T00:00:00.000Z"
# Build 255 Revision 6 released version 1.1.0: the license text now says only
# "All rights reserved"; derivative works stay allowed for this test Course.
# Revision 7 released version 1.1.1: the Course flag is QQL's English flag
# (EN); "GB", which QQL does not draw, showed the neutral flag.
# Build 256 Revision 5 released version 1.2.0: a Story Lesson (a cover,
# lines, one of them audio only, and an exercise that needs the Story's audio).
RELEASE_STAMP = "2026-09-28T00:00:00.000Z"
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


# Build 266 (GuideBook Modules): each Lesson's GuideBook is one module for
# now (the converter writes "Module 1"; this names it). Revision 3 of Build
# 266 adds the module cases (two modules, an empty one, a long Overview).
MODULE_TITLES = {
    "l01": "Sì, colori e saluti",
    "l02": "Al tè",
    "l03": "Animali e cose",
    "l04": "Pronto, tardi, presto",
    "l05_draft": "Parole da copiare",
    "l06": "Al bar",
}


def name_modules(course: dict) -> None:
    for lesson in course["lessons"]:
        case = lesson["lessonId"].removeprefix(PREFIX)
        for module in lesson["guidebook"]["modules"]:
            module["id"] = lesson["lessonId"] + "_module"
            module["title"] = MODULE_TITLES[case]


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
    # Read and answer's text is in the source language, Italian here (Build
    # 256 Revision 7 fourth follow-up); it stays long for EXERCISE_TEXT_LONG.
    long_passage = (
        "In un pomeriggio di pioggia, la bibliotecaria apre un piccolo quaderno e legge il messaggio di un visitatore. "
        "Il visitatore scrive i nomi café, naïve, São Tomé, Łódź, 東京, 서울, Αθήνα e القاهرة, "
        "poi aggiunge una faccina sorridente 🙂 e una nota musicale ♫. Questi nomi sono testo citato, non "
        "nuove lezioni di lingua. Gli scaffali contengono dizionari, mappe, vecchie fotografie e libri con "
        "titoli lunghissimi. Un bambino chiede perché la stessa parola può comparire due volte in una frase. "
        "La bibliotecaria risponde che la ripetizione può essere voluta e che ogni occorrenza stampata ha "
        "comunque il suo posto. Fuori smette di piovere, una bicicletta rossa è appoggiata a un muro e "
        "l’orologio sopra la porta segna le cinque. "
    ) * 2 + "Il quaderno è blu."
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
            # Read and answer (Build 256 Revision 7 fourth follow-up): the
            # long text explains in the source language; the question is in
            # the target language.
            select("e07_long", "What colour is the notebook?", ["blue", "red", "green"],
                   preset="reading_answer_target",
                   before=({**text(long_passage, "context"), "language": "source"},)),
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
        # Build 259 Revision 4 (owner decision): Pick the words for the gaps
        # uses each word once, so the three former Select gap cases fill
        # their gaps with words; a word needed twice is offered twice.
        round_case("r05", "Una parola per gap", [
            gaps("e17_select_min", "Completa: un gatto.", ["cat"], ["a", 1], [1]),
            gaps("e18_select_linked", "Completa entrambe le domande: la stessa parola serve due volte.",
                 ["Was", "Was", "Were", "Are"], [1, "she happy?", 2, "he late?"], [1, 2]),
            gaps("e19_select_distinct", "Completa con due parole diverse.",
                 ["am", "to", "is", "from"], ["I", 1, "going", 2, "London."], [1, 2]),
        ])
    ], ["tea = tè", "very = molto", "would like = vorrei", "a cup of tea = una tazza di tè"],
       overview="Ogni parola riempie un solo gap; una parola che serve due volte è offerta due volte.")
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
    def story_entry(case: str, preset: str, payload: dict) -> dict:
        return {"id": pid(case), "publicationState": "published", "kind": "exercise",
                "required": True, "editorTemplate": preset, "exercise": payload}

    marta = pid("character_marta")
    story_content = [
        note("intro06", "Una Story (Build 256 Revision 5): la copertina, le battute del narratore e di Marta "
             "(una solo audio) e un esercizio che richiede l’audio della Story. Le battute non si saltano mai; "
             "l’esercizio segnato è saltato con Audio Exercises off.", role="lesson_intro"),
        story_entry("e32_cover", "story_cover", story_cover(
            updated_at=STAMP, picture="assets/exercise_images/coffee.webp",
            alternative="Una tazza di caffè", title_line="At the bar")),
        story_entry("e33_narrator", "dialogue_line", story_line(
            "Marta entra nel bar e saluta.", updated_at=STAMP)),
        story_entry("e34_audio_only", "dialogue_line", story_line(
            "Good morning! A coffee, please.", updated_at=STAMP, speaker_id=marta, mode="audio")),
        # The question sits between the lines, as a Story alternates them.
        select("e36_needs_audio", "Che cosa ordina Marta?", ["a coffee", "a tea"]),
        story_entry("e35_thanks", "dialogue_line", story_line(
            "Thank you!", updated_at=STAMP, speaker_id=marta)),
    ]
    story_round = round_case("r11_story", "At the bar", story_content, visual="story")
    story_round["flow"] = story_flow(
        [(content["id"], becomes_exercise(content)) for content in story_content],
        title="At the bar", requires_audio={pid("e36_needs_audio")})
    # A Story of covers alone (owner decision, 28 September 2026): nothing to
    # score, no XP, and the intentional Audit warning STORY_WITHOUT_DIALOGUE.
    covers_content = [
        note("intro07", "Una Story di sole copertine: niente battute, niente esercizi, nessun XP; "
             "l’Audit segnala STORY_WITHOUT_DIALOGUE, un avviso intenzionale.", role="lesson_intro"),
        story_entry("e37_cover_market", "story_cover", story_cover(
            updated_at=STAMP, picture="assets/exercise_images/bread.webp",
            alternative="Una pagnotta", title_line="Al mercato")),
        story_entry("e38_cover_bar", "story_cover", story_cover(
            updated_at=STAMP, picture="assets/exercise_images/coffee.webp",
            alternative="Una tazza di caffè", title_line="Al bar")),
        story_entry("e39_cover_home", "story_cover", story_cover(
            updated_at=STAMP, picture="assets/exercise_images/house.webp",
            alternative="Una casa", title_line="A casa")),
    ]
    covers_round = round_case("r12_covers", "Tre copertine", covers_content, visual="story")
    covers_round["flow"] = story_flow(
        [(content["id"], becomes_exercise(content)) for content in covers_content],
        title="Tre copertine")
    l6 = lesson("l06", "Storia: al bar (a Story)", [story_round, covers_round], ["a coffee = un caffè"],
                overview="Una Story: copertina, battute (una solo audio) alternate a un esercizio che richiede "
                "l’audio della Story; il narratore parla italiano, Marta inglese. Poi una Story di sole "
                "copertine, senza nulla da valutare.")
    course = {
        "formatVersion": 11, "publicationState": "published", "lessonNumberingMode": "lesson",
        "defaultLessonIconStyle": "monochrome", "createDuels": False,
        "courseId": COURSE_ID, "originType": "bundledOfficial", "publisherId": "org.quisquislingo",
        "publisherName": "QuisquisLingo", "officialCourseVersion": "1.2.0",
        "officialReleaseDateUtc": RELEASE_STAMP, "officialReleaseNotes": "QQL Build 256 Revision 5: a Story Lesson (a cover, lines, one of them audio only, and an exercise that needs the Story's audio).",
        "distributionChannel": "bundled", "publisherVerificationStatus": "verified",
        "originalCourseCreator": {"type": "publisher", "id": "org.quisquislingo", "displayName": "QuisquisLingo"},
        "originalCreatedAtUtc": STAMP, "modifiedAtUtc": RELEASE_STAMP,
        "learningLanguage": "English", "interfaceLanguage": "Italian",
        "sourceLanguage": "Italian", "targetLanguage": "English",
        "sourceLanguageTag": "it-IT", "targetLanguageTag": "en-GB",
        "title": "Temporary Demo: Edge Case Course",
        "ttsLanguage": "en-GB", "audioMode": "hybrid",
        "authors": [{"name": "QuisquisLingo — AI-generated test content", "roles": ["Author"]}],
        "license": "All rights reserved",
        "derivativeWorksPolicy": "allowed", "courseDescription":
            "TEMPORARY AI-GENERATED TEST COURSE. Italiano → inglese. Per trovarlo abilita Show unavailable: "
            "contiene strutture Draft valide, omesse nel Learner. Include tre avvisi Audit intenzionali "
            "(opzioni duplicate, testo lungo e una Story di sole copertine). Hybrid prova MP3 preinstallati e fallback TTS; i campioni MP3 "
            "non hanno una trascrizione verificata e sono solo prove di riproduzione. Fork abilita i collaudi "
            "Copy as New Course e Merge su copie personali. Non è un percorso didattico revisionato.",
        # Build 259 Revision 8: temporarySample is the Private course flag; a demo is for everyone.
        "textDirection": "ltr", "flagCode": "EN", "temporarySample": False,
        "keywords": ["demo", "edge cases", "Unicode", "audio", "Draft"],
        "audioLibrary": [
            {"id": pid("audio_01"), "text": "recorded sample one", "filePath": "assets/audio/en_sample/sample_1.mp3"},
            {"id": pid("audio_02"), "text": "recorded sample two", "filePath": "assets/audio/en_sample/sample_2.mp3"},
        ],
        "storyNarrator": {"name": "Narratore", "language": "source"},
        "storyCharacters": [{"id": marta, "name": "Marta", "avatar": "assets/avatars/kid.png",
                             "language": "target", "voice": "female"}],
        "lessons": [l1, l2, l3, l4, l5, l6],
    }
    course = convert_course_v11_to_v12(course)
    name_modules(course)
    canonical = {key: value for key, value in course.items()
                 if key not in {"officialChecksum", "publisherVerificationStatus", "publisherSignature"}}
    course["officialChecksum"] = hashlib.sha256(json.dumps(
        canonical, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")).hexdigest()
    return course


def build_external_course() -> dict:
    """The same Course as a custom Course ready to import: its own identity,
    a QQL-user creator and Maintainer, a Course version and no publisher
    provenance. Derivative works stay allowed, so an importer can Fork it."""
    course = {key: value for key, value in build_course().items() if key not in OFFICIAL_ONLY_KEYS}
    creator = {"type": "qqlUser", "id": EXTERNAL_MAINTAINER, "displayName": "QuisquisLingo"}
    rest = {key: value for key, value in course.items()
            if key not in {"courseId", "originType", "originalCourseCreator", "originalCreatedAtUtc"}}
    return {
        "formatVersion": rest.pop("formatVersion"),
        "courseId": EXTERNAL_COURSE_ID,
        "originType": "custom",
        "originalCourseCreator": creator,
        "maintainer": {"profileId": EXTERNAL_MAINTAINER},
        "originalCreatedAtUtc": STAMP,
        "courseVersion": "1",
        "lastVersionEditorProfileId": EXTERNAL_MAINTAINER,
        "lastVersionEditorDisplayName": "QuisquisLingo",
        **rest,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check reproducibility without writing")
    args = parser.parse_args()
    outputs = [(OUTPUT, build_course()), (EXTERNAL_OUTPUT, build_external_course())]
    stale = False
    for path, course in outputs:
        encoded = json.dumps(course, ensure_ascii=False, indent=2) + "\n"
        if args.check:
            if not path.is_file() or path.read_text(encoding="utf-8") != encoded:
                print(f"OUT OF DATE: {path.relative_to(ROOT)}")
                stale = True
            else:
                print(f"OK: {path.relative_to(ROOT)} matches its deterministic generator")
        else:
            path.write_text(encoded, encoding="utf-8", newline="\n")
            print(f"Wrote {path.relative_to(ROOT)}")
    return 1 if stale else 0


if __name__ == "__main__":
    raise SystemExit(main())
