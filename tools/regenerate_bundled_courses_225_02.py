#!/usr/bin/env python3
"""Deterministically regenerate the bundled Course Model v6 assets.

Existing assets contribute only reviewed course metadata and Guidebook material.
Legacy exercises and their IDs are deliberately discarded rather than migrated.
Build 225.04 adds immutable official provenance without changing the reviewed
Build 225.02 course content.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "assets" / "courses"
EXISTING = (
    ("NL", "dutch_en.json"),
    ("EN", "english_es.json"),
    ("FI", "finnish_en.json"),
    ("DE", "german_en.json"),
    ("IT", "italian_en.json"),
    ("PT", "portuguese_en.json"),
    ("ES", "spanish_en.json"),
    ("CY", "welsh_en.json"),
)
BASE_TIME = datetime(2026, 9, 4, 8, 0, tzinfo=timezone.utc)


def _official_checksum(course: dict[str, object]) -> str:
    excluded = {"officialChecksum", "publisherVerificationStatus", "publisherSignature"}
    canonical = {
        key: json.loads(json.dumps(value, ensure_ascii=False))
        for key, value in course.items()
        if key not in excluded
    }
    # CourseAuthor canonical serialization retains the compatibility-facing
    # primary role beside the complete roles list.
    if canonical.get("derivativeWorksPolicy") in (None, "unspecified"):
        canonical.pop("derivativeWorksPolicy", None)
    for author in canonical.get("authors", []):
        roles = author.get("roles", [])
        if roles:
            author["role"] = roles[0]
    encoded = json.dumps(
        canonical,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _with_official_provenance(
    course: dict[str, object], *, official_version: str, release_notes: str
) -> dict[str, object]:
    output: dict[str, object] = {}
    for key, value in course.items():
        if key in {
            "originType",
            "publisherId",
            "publisherName",
            "officialCourseVersion",
            "officialReleaseDateUtc",
            "officialChecksum",
            "officialReleaseNotes",
            "distributionChannel",
            "publisherVerificationStatus",
        }:
            continue
        output[key] = value
        if key == "courseId":
            output.update(
                {
                    "originType": "bundledOfficial",
                    "publisherId": "org.quisquislingo",
                    "publisherName": "QuisquisLingo",
                    "officialCourseVersion": official_version,
                    "officialReleaseDateUtc": "2026-09-04T00:00:00.000Z",
                    "officialChecksum": "",
                    "officialReleaseNotes": release_notes,
                    "distributionChannel": "bundled",
                    "publisherVerificationStatus": "verified",
                }
            )
    output["officialChecksum"] = _official_checksum(output)
    # Keep the checksum beside the other provenance fields in human-readable
    # JSON rather than at the end of a very large course document.
    ordered: dict[str, object] = {}
    for key, value in output.items():
        ordered[key] = value
        if key == "officialReleaseDateUtc":
            ordered["officialChecksum"] = output["officialChecksum"]
    return ordered


TARGET_COPY = {
    "NL": {
        "reading": "Vandaag oefenen we samen de uitdrukking ‘{target}’ in deze les.",
        "listening": "Luister goed: vandaag gebruiken we samen de uitdrukking {target}.",
        "gap": "Vandaag gebruiken we de uitdrukking ___ in de les.",
        "dialogue": "De docent zegt: ‘{target}’.",
        "dialogue_question": "Welk antwoord laat zien dat je het begrijpt?",
        "dialogue_answers": ["Ik begrijp het.", "Ik luister niet."],
    },
    "EN": {
        "reading": "Today we practise the expression “{target}” together in class.",
        "listening": "Listen carefully: today we use the expression {target} together.",
        "gap": "Today we use the expression ___ in class.",
        "dialogue": "The teacher says, “{target}”.",
        "dialogue_question": "Which response shows that you understood?",
        "dialogue_answers": ["I understand.", "I am not listening."],
    },
    "FI": {
        "reading": "Tänään harjoittelemme yhdessä ilmausta ”{target}” tällä tunnilla.",
        "listening": "Kuuntele tarkasti: tänään käytämme yhdessä ilmausta {target}.",
        "gap": "Tänään käytämme tunnilla ilmausta ___.",
        "dialogue": "Opettaja sanoo: ”{target}”.",
        "dialogue_question": "Mikä vastaus osoittaa, että ymmärsit?",
        "dialogue_answers": ["Ymmärrän.", "En kuuntele."],
    },
    "DE": {
        "reading": "Heute üben wir gemeinsam den Ausdruck „{target}“ im Unterricht.",
        "listening": "Hör gut zu: Heute verwenden wir gemeinsam den Ausdruck {target}.",
        "gap": "Heute verwenden wir im Unterricht den Ausdruck ___.",
        "dialogue": "Die Lehrerin sagt: „{target}“.",
        "dialogue_question": "Welche Antwort zeigt, dass du verstanden hast?",
        "dialogue_answers": ["Ich verstehe.", "Ich höre nicht zu."],
    },
    "IT": {
        "reading": "Oggi ripassiamo insieme l’espressione «{target}» durante la lezione.",
        "listening": "Ascolta bene: oggi usiamo insieme l’espressione {target}.",
        "gap": "Oggi usiamo l’espressione ___ durante la lezione.",
        "dialogue": "L’insegnante dice: «{target}».",
        "dialogue_question": "Quale risposta mostra che hai capito?",
        "dialogue_answers": ["Ho capito.", "Non sto ascoltando."],
    },
    "PT": {
        "reading": "Hoje praticamos juntos a expressão «{target}» durante a aula.",
        "listening": "Escuta com atenção: hoje usamos juntos a expressão {target}.",
        "gap": "Hoje usamos a expressão ___ durante a aula.",
        "dialogue": "A professora diz: «{target}».",
        "dialogue_question": "Qual resposta mostra que compreendeste?",
        "dialogue_answers": ["Compreendi.", "Não estou a ouvir."],
    },
    "ES": {
        "reading": "Hoy practicamos juntos la expresión «{target}» durante la clase.",
        "listening": "Escucha con atención: hoy usamos juntos la expresión {target}.",
        "gap": "Hoy usamos la expresión ___ durante la clase.",
        "dialogue": "La profesora dice: «{target}».",
        "dialogue_question": "¿Qué respuesta muestra que lo has entendido?",
        "dialogue_answers": ["Lo entiendo.", "No estoy escuchando."],
    },
    "CY": {
        "reading": "Heddiw rydyn ni’n ymarfer yr ymadrodd “{target}” gyda’n gilydd.",
        "listening": "Gwrandewch yn ofalus: heddiw rydyn ni’n defnyddio {target} gyda’n gilydd.",
        "gap": "Heddiw rydyn ni’n defnyddio’r ymadrodd ___ yn y wers.",
        "dialogue": "Mae’r athrawes yn dweud: “{target}”.",
        "dialogue_question": "Pa ateb sy’n dangos eich bod wedi deall?",
        "dialogue_answers": ["Dw i’n deall.", "Dw i ddim yn gwrando."],
    },
    "KO": {
        "reading": "오늘은 수업에서 “{target}” 표현을 함께 천천히 연습해요.",
        "listening": "잘 들어 보세요. 오늘은 {target} 표현을 함께 연습해요.",
        "gap": "오늘은 수업에서 ___ 표현을 함께 사용해요.",
        "dialogue": "선생님이 “{target}”라고 말해요.",
        "dialogue_question": "알아들었다면 어떻게 대답해요?",
        "dialogue_answers": ["알겠어요.", "안 듣고 있어요."],
    },
}


def _iso(course_index: int, lesson_index: int, sequence: int) -> str:
    # All nine assets were regenerated in this tranche on 2026-09-04. Keep
    # that real content date stable while ordering mutations within a course.
    # `course_index` remains part of the signature to make call sites explicit,
    # but must not move another course onto a fabricated future date.
    _ = course_index
    value = BASE_TIME + timedelta(hours=lesson_index, minutes=sequence)
    return value.isoformat(timespec="milliseconds").replace("+00:00", "Z")


def _item(item_id: str, text: str) -> dict[str, object]:
    return {
        "id": item_id,
        "content": [{"role": "primary", "type": "text", "text": text}],
    }


def _select(
    exercise_id: str,
    preset: str,
    timestamp: str,
    prompt: list[dict[str, str]],
    options: list[str],
) -> dict[str, object]:
    item_ids = [f"{exercise_id}_i{index + 1}" for index in range(len(options))]
    return {
        "id": exercise_id,
        "publicationState": "published",
        "kind": "exercise",
        "required": True,
        "editorTemplate": preset,
        "exercise": {
            "updatedAt": timestamp,
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


def _options(values: list[str], correct_index: int, count: int = 3) -> list[str]:
    return [values[(correct_index + offset) % len(values)] for offset in range(count)]


def _source_question(code: str, kind: str, source: str, target_language: str) -> str:
    if code == "EN":
        return {
            "choice": f"¿Cómo se dice «{source}» en inglés?",
            "listen": "¿Qué expresión oyes?",
            "meaning": "¿Qué significa la expresión destacada?",
            "review": "¿Qué expresión se practica?",
        }[kind]
    return {
        "choice": f"How do you say “{source}” in {target_language}?",
        "listen": "Which expression do you hear?",
        "meaning": "What does the highlighted expression mean?",
        "review": "Which expression is being practised?",
    }[kind]


def _round(
    *,
    code: str,
    course_index: int,
    lesson_index: int,
    round_index: int,
    target_language: str,
    vocabulary: list[tuple[str, str]],
    intro: str | None,
) -> dict[str, object]:
    prefix = f"qql_{code.lower()}_l{lesson_index + 1:02d}_r{round_index + 1:02d}"
    targets = [entry[0] for entry in vocabulary]
    sources = [entry[1] for entry in vocabulary]
    copy = TARGET_COPY[code]
    content: list[dict[str, object]] = []
    if intro is not None:
        content.append(
            {
                "id": f"{prefix}_intro",
                "publicationState": "published",
                "kind": "text",
                "required": False,
                "role": "lesson_intro",
                "text": intro,
            }
        )

    def add_select(
        preset: str, prompt: list[dict[str, str]], options: list[str]
    ) -> None:
        number = len(content) + 1
        content.append(
            _select(
                f"{prefix}_e{number:02d}",
                preset,
                _iso(course_index, lesson_index, round_index * 12 + number),
                prompt,
                options,
            )
        )

    first = round_index % 4
    second = (round_index + 1) % 4
    third = (round_index + 2) % 4
    fourth = (round_index + 3) % 4
    add_select(
        "choice",
        [
            {
                "role": "primary",
                "type": "text",
                "text": _source_question(
                    code, "choice", sources[first], target_language
                ),
            }
        ],
        _options(targets, first),
    )
    add_select(
        "choice",
        [
            {
                "role": "primary",
                "type": "text",
                "text": _source_question(
                    code, "choice", sources[second], target_language
                ),
            }
        ],
        _options(targets, second),
    )
    add_select(
        "listening_choice",
        [
            {"role": "primary", "type": "audio", "text": targets[third]},
            {
                "role": "question",
                "type": "text",
                "text": _source_question(code, "listen", "", target_language),
            },
        ],
        _options(targets, third),
    )
    add_select(
        "listening_comprehension",
        [
            {
                "role": "passage",
                "type": "audio",
                "text": str(copy["listening"]).format(target=targets[fourth]),
            },
            {
                "role": "question",
                "type": "text",
                "text": _source_question(code, "review", "", target_language),
            },
        ],
        _options(targets, fourth),
    )
    add_select(
        "reading_comprehension",
        [
            {
                "role": "passage",
                "type": "text",
                "text": str(copy["reading"]).format(target=targets[first]),
            },
            {
                "role": "question",
                "type": "text",
                "text": _source_question(code, "review", "", target_language),
            },
        ],
        _options(targets, first),
    )
    add_select(
        "dialogue_response",
        [
            {
                "role": "passage",
                "type": "text",
                "text": str(copy["dialogue"]).format(target=targets[second]),
            },
            {
                "role": "question",
                "type": "text",
                "text": str(copy["dialogue_question"]),
            },
        ],
        list(copy["dialogue_answers"]),
    )
    add_select(
        "contextual_comprehension",
        [
            {
                "role": "context",
                "type": "text",
                "text": str(copy["reading"]).format(target=targets[third]),
            },
            {
                "role": "question",
                "type": "text",
                "text": _source_question(code, "meaning", "", target_language),
            },
        ],
        _options(sources, third),
    )
    if len(content) < 8:
        add_select(
            "gap_choice",
            [
                {
                    "role": "question",
                    "type": "text",
                    "text": str(copy["gap"]),
                }
            ],
            _options(targets, fourth),
        )

    round_data: dict[str, object] = {
        "id": prefix,
        "publicationState": "published",
        "updatedAt": _iso(course_index, lesson_index, round_index * 12),
        "visualType": ("generic", "listening", "story", "test")[round_index],
        "content": content,
    }
    if round_index in (0, 2):
        round_data["title"] = ("First steps", "Comprehension")[round_index // 2]
    return round_data


def _guidebook(
    code: str, lesson_index: int, source_content: list[dict[str, object]]
) -> dict[str, object]:
    output = []
    for index, item in enumerate(source_content):
        kind = str(item.get("kind", "text"))
        text = str(item.get("text", "")).strip()
        if not text:
            continue
        output.append(
            {
                "id": f"qql_{code.lower()}_l{lesson_index + 1:02d}_g{index + 1:02d}",
                "publicationState": "published",
                "kind": kind,
                "required": bool(item.get("required", False)),
                **({"role": item["role"]} if item.get("role") else {}),
                "text": text,
            }
        )
    return {"content": output}


def _vocabulary(guidebook: dict[str, object], lesson_id: str) -> list[tuple[str, str]]:
    values: list[tuple[str, str]] = []
    for item in guidebook.get("content", []):
        if not isinstance(item, dict) or item.get("kind") != "vocabulary":
            continue
        text = item.get("text")
        if not isinstance(text, str) or "=" not in text:
            continue
        target, source = (part.strip() for part in text.split("=", 1))
        if target and source:
            values.append((target, source))
    if len(values) < 4:
        raise ValueError(f"{lesson_id}: at least four Guidebook vocabulary pairs required")
    return values[:4]


def _regenerate_existing(code: str, filename: str, course_index: int) -> dict[str, object]:
    path = COURSES / filename
    source = json.loads(path.read_text(encoding="utf-8"))
    lessons = source.get("lessons")
    if not isinstance(lessons, list) or len(lessons) != 9:
        raise ValueError(f"{filename}: expected exactly nine Lessons")
    generated_lessons = []
    for lesson_index, old in enumerate(lessons):
        if not isinstance(old, dict):
            raise ValueError(f"{filename}: Lesson {lesson_index + 1} is invalid")
        old_guidebook = old.get("guidebook")
        old_content = old_guidebook.get("content") if isinstance(old_guidebook, dict) else None
        if not isinstance(old_content, list):
            raise ValueError(f"{filename}: Lesson {lesson_index + 1} has no Guidebook")
        guidebook = _guidebook(code, lesson_index, old_content)
        lesson_id = f"qql_{code.lower()}_l{lesson_index + 1:02d}"
        vocabulary = _vocabulary(guidebook, lesson_id)
        overview = next(
            (
                str(item["text"])
                for item in guidebook["content"]
                if item.get("role") == "overview"
            ),
            f"Practise {source['targetLanguage']} vocabulary in context.",
        )
        lesson = {
            "lessonId": lesson_id,
            "publicationState": "published",
            "updatedAt": _iso(course_index, lesson_index, 0),
            "title": str(old.get("title", f"Lesson {lesson_index + 1}")),
            "section": bool(old.get("section", False)),
            **(
                {"sectionName": str(old["sectionName"])}
                if old.get("section") and old.get("sectionName")
                else {}
            ),
            **(
                {"themeIconAsset": str(old["themeIconAsset"])}
                if old.get("themeIconAsset")
                else {}
            ),
            "guidebook": guidebook,
            "rounds": [
                _round(
                    code=code,
                    course_index=course_index,
                    lesson_index=lesson_index,
                    round_index=round_index,
                    target_language=str(source["targetLanguage"]),
                    vocabulary=vocabulary,
                    intro=overview if round_index == 0 else None,
                )
                for round_index in range(4)
            ],
            "duel": {"id": f"{lesson_id}_duel", "title": "Duel"},
        }
        generated_lessons.append(lesson)
    source.update(
        {
            "formatVersion": 6,
            "version": "1.6.0",
            "courseVersion": "1.6.0",
            "contentRevision": "bundled-v22502-model-v6",
            "lastUpdated": "2026-09-04",
            "updateSummary": (
                "Deterministically regenerated for Build 225.02 with Course Model v6, "
                "stable timestamps, globally unique content IDs and Duel-ready practice."
            ),
            "courseDescription": (
                "TEMPORARY SAMPLE course regenerated for Course Model v6."
            ),
            "lessons": generated_lessons,
        }
    )
    return _with_official_provenance(
        source,
        official_version=str(source["version"]),
        release_notes="Build 225.02 deterministic bundled course release.",
    )


KOREAN_LESSONS = (
    ("Greetings and introductions", "Foundations", (("안녕하세요", "hello"), ("저는 민수예요", "I am Minsu"), ("만나서 반가워요", "nice to meet you"), ("이름이 뭐예요?", "what is your name?"))),
    ("Courtesy, thanks and apologies", "Foundations", (("감사합니다", "thank you"), ("천만에요", "you’re welcome"), ("죄송합니다", "I’m sorry"), ("괜찮아요", "it’s okay"))),
    ("People and family", "People and quantities", (("어머니", "mother"), ("아버지", "father"), ("형제자매", "siblings"), ("우리 가족이에요", "this is my family"))),
    ("Numbers and quantities", "People and quantities", (("하나", "one"), ("둘", "two"), ("세 개 주세요", "three, please"), ("얼마예요?", "how much is it?"))),
    ("Food and drinks", "Everyday life", (("물 주세요", "water, please"), ("커피 한 잔 주세요", "one coffee, please"), ("맛있어요", "it is delicious"), ("채식 메뉴가 있어요?", "do you have a vegetarian menu?"))),
    ("Home and everyday objects", "Everyday life", (("집", "home"), ("책", "book"), ("문을 열어 주세요", "please open the door"), ("열쇠가 어디에 있어요?", "where is the key?"))),
    ("Time and daily activities", "Everyday life", (("지금 몇 시예요?", "what time is it now?"), ("아침에 일어나요", "I get up in the morning"), ("매일 공부해요", "I study every day"), ("저녁에 쉬어요", "I rest in the evening"))),
    ("Places, transport and directions", "Getting around", (("역이 어디예요?", "where is the station?"), ("버스로 가요", "I go by bus"), ("왼쪽으로 가세요", "go to the left"), ("여기에서 가까워요", "it is close from here"))),
    ("Travel and practical phrases", "Getting around", (("표 한 장 주세요", "one ticket, please"), ("공항에 가고 싶어요", "I want to go to the airport"), ("도와주세요", "please help me"), ("화장실이 어디예요?", "where is the restroom?"))),
)


def _korean_course(course_index: int) -> dict[str, object]:
    icons = (
        "speech_bubbles.png", "family.png", "school.png", "food.png", "home.png",
        "coffee.png", "directions.png", "train.png", "airport.png",
    )
    lessons = []
    for lesson_index, (title, section_name, vocabulary) in enumerate(KOREAN_LESSONS):
        lesson_id = f"qql_ko_l{lesson_index + 1:02d}"
        guide_content = [
            {
                "id": f"{lesson_id}_g01",
                "publicationState": "published",
                "kind": "explanation",
                "required": False,
                "role": "overview",
                "text": f"{title}: practise four useful Korean expressions in a polite beginner register.",
            },
            {
                "id": f"{lesson_id}_g02",
                "publicationState": "published",
                "kind": "text",
                "required": False,
                "role": "goal",
                "text": "Recognise, understand and use the expressions in short everyday contexts.",
            },
            *[
                {
                    "id": f"{lesson_id}_g{index + 3:02d}",
                    "publicationState": "published",
                    "kind": "vocabulary",
                    "required": False,
                    "role": "vocabulary",
                    "text": f"{target} = {source}",
                }
                for index, (target, source) in enumerate(vocabulary)
            ],
            {
                "id": f"{lesson_id}_g07",
                "publicationState": "published",
                "kind": "example",
                "required": False,
                "role": "example",
                "text": vocabulary[0][0],
            },
            {
                "id": f"{lesson_id}_g08",
                "publicationState": "published",
                "kind": "example",
                "required": False,
                "role": "example",
                "text": vocabulary[1][0],
            },
        ]
        rounds = [
            _round(
                code="KO",
                course_index=course_index,
                lesson_index=lesson_index,
                round_index=round_index,
                target_language="Korean",
                vocabulary=list(vocabulary),
                intro=str(guide_content[0]["text"]) if round_index == 0 else None,
            )
            for round_index in range(4)
        ]
        if lesson_index == 0:
            exercise_id = f"qql_ko_l01_r04_e08"
            item_values = ("잘", "지내세요", "어떻게", "요즘")
            item_ids = [f"{exercise_id}_i{index + 1}" for index in range(4)]
            rounds[3]["content"][-1] = {
                "id": exercise_id,
                "publicationState": "published",
                "kind": "exercise",
                "required": True,
                "editorTemplate": "build_translation",
                "exercise": {
                    "updatedAt": _iso(course_index, lesson_index, 47),
                    "prompt": [{"role": "primary", "type": "text", "text": "How are you?"}],
                    "interaction": {
                        "kind": "arrange",
                        "items": [
                            _item(item_id, value)
                            for item_id, value in zip(item_ids, item_values, strict=True)
                        ],
                    },
                    "evaluation": {
                        "kind": "ordered_items",
                        "correctOrders": [
                            {"text": "잘 지내세요?", "itemIds": [item_ids[0], item_ids[1]]},
                            {"text": "어떻게 지내세요?", "itemIds": [item_ids[2], item_ids[1]]},
                            {"text": "요즘 어떻게 지내세요?", "itemIds": [item_ids[3], item_ids[2], item_ids[1]]},
                        ],
                    },
                },
            }
        lessons.append(
            {
                "lessonId": lesson_id,
                "publicationState": "published",
                "updatedAt": _iso(course_index, lesson_index, 0),
                "title": title,
                "section": lesson_index in (0, 2, 4, 7),
                **(
                    {"sectionName": section_name}
                    if lesson_index in (0, 2, 4, 7)
                    else {}
                ),
                "themeIconAsset": f"assets/lesson_icons/{icons[lesson_index]}",
                "guidebook": {"content": guide_content},
                "rounds": rounds,
                "duel": {"id": f"{lesson_id}_duel", "title": "Duel"},
            }
        )
    course = {
        "formatVersion": 6,
        "publicationState": "published",
        "lessonNumberingMode": "lesson",
        "defaultLessonIconStyle": "monochrome",
        "courseId": "sample_ko_en_ko",
        "learningLanguage": "Korean",
        "interfaceLanguage": "English",
        "sourceLanguage": "English",
        "targetLanguage": "Korean",
        "title": "Korean",
        "ttsLanguage": "ko-KR",
        "version": "1.0.0",
        "contentRevision": "bundled-v22502-model-v6",
        "updateSummary": "Added the deterministic beginner Korean bundled course for Build 225.02.",
        "audioMode": "tts",
        "author": "QuisquisLingo course team",
        "authors": [{"name": "QuisquisLingo course team", "roles": ["Course Creator"]}],
        "license": "All rights reserved",
        "languageVariant": "Contemporary polite Korean",
        "startLevel": "Beginner",
        "targetLevel": "Beginner",
        "courseVersion": "1.0.0",
        "lastUpdated": "2026-09-04",
        "courseDescription": "TEMPORARY SAMPLE beginner Korean course using Hangul and a consistent polite register.",
        "sourceLanguageTag": "en-GB",
        "targetLanguageTag": "ko-KR",
        "textDirection": "ltr",
        "flagCode": "KR",
        "temporarySample": True,
        "lessons": lessons,
    }
    return _with_official_provenance(
        course,
        official_version="1.0.0",
        release_notes="Build 225.02 deterministic Korean bundled course release.",
    )


def _render(data: dict[str, object]) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def regenerate(*, check: bool = False) -> list[tuple[Path, str]]:
    outputs: list[tuple[Path, str]] = []
    for course_index, (code, filename) in enumerate(EXISTING):
        path = COURSES / filename
        rendered = _render(_regenerate_existing(code, filename, course_index))
        if check:
            if path.read_text(encoding="utf-8") != rendered:
                raise ValueError(f"{filename}: generated bytes differ from the asset")
        else:
            path.write_text(rendered, encoding="utf-8", newline="\n")
        outputs.append((path, hashlib.sha256(rendered.encode("utf-8")).hexdigest()))
    korean = COURSES / "korean_en.json"
    rendered = _render(_korean_course(len(EXISTING)))
    if check:
        if korean.read_text(encoding="utf-8") != rendered:
            raise ValueError("korean_en.json: generated bytes differ from the asset")
    else:
        korean.write_text(rendered, encoding="utf-8", newline="\n")
    outputs.append((korean, hashlib.sha256(rendered.encode("utf-8")).hexdigest()))
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify that a regeneration would reproduce the committed bytes",
    )
    args = parser.parse_args()
    action = "verified" if args.check else "regenerated"
    for path, digest in regenerate(check=args.check):
        print(f"{path.name}: {action} for Build 225.04; sha256={digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
