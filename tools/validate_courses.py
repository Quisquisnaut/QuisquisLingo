#!/usr/bin/env python3
"""Offline structural validation for bundled Course Model v6 JSON."""
from __future__ import annotations

import base64
import binascii
import json
import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "assets" / "courses"
EXPECTED_TTS = {
    "dutch_en.json": "nl-NL",
    "english_es.json": "en-GB",
    "finnish_en.json": "fi-FI",
    "german_en.json": "de-DE",
    "italian_en.json": "it-IT",
    "korean_en.json": "ko-KR",
    "portuguese_en.json": "pt-PT",
    "spanish_en.json": "es-ES",
    "welsh_en.json": "cy-GB",
}
INTERACTIONS = {"select", "input", "arrange", "match"}
EVALUATIONS = {"selected_items", "text_match", "ordered_items", "matched_items"}
CONTENT_KINDS = {"exercise", "presentation", "explanation", "example", "vocabulary", "text", "image", "audio", "dialogue"}
ROUND_VISUAL_TYPES = {"listening", "story", "generic", "test"}
PUBLICATION_STATES = {"draft", "published"}
LESSON_NUMBERING_MODES = {"lesson", "unit", "topic", "module", "skill", "chapter", "stage", "step", "part", "other", "numberOnly", "none"}
LESSON_ICON_STYLES = {"monochrome", "coloredLessonNumbers"}
LESSON_ICON_PATHS = set(re.findall(
    r"assets/lesson_icons/[a-z0-9_]+\.png",
    (ROOT / "lib" / "services" / "lesson_icon_catalog.dart").read_text(encoding="utf-8"),
))
UTC_TIMESTAMP = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$")


def _ordered_text(value: str) -> str:
    return re.sub(r"[.!?…]+$", "", " ".join(value.strip().split())).casefold()


def _timestamp(value: object, where: str, issues: list[str]) -> None:
    if not isinstance(value, str) or not UTC_TIMESTAMP.fullmatch(value):
        issues.append(f"{where}: updatedAt must be an ISO 8601 UTC timestamp ending in Z")
        return
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        issues.append(f"{where}: updatedAt is not valid")


def validate(path: Path, global_ids: dict[str, str]) -> list[str]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return [f"root: cannot read valid UTF-8 JSON: {error}"]
    if not isinstance(data, dict):
        return ["root: course must be an object"]
    issues: list[str] = []
    ids: set[str] = set()
    pending_refs: list[tuple[str, str]] = []

    def add_id(value: object, where: str) -> None:
        if not isinstance(value, str) or not value.strip():
            issues.append(f"{where}: missing ID")
            return
        if value in ids:
            issues.append(f"{where}: duplicate ID within course: {value}")
        ids.add(value)
        previous = global_ids.get(value)
        if previous is not None and previous != path.name:
            issues.append(f"{where}: globally duplicate ID {value} (also in {previous})")
        else:
            global_ids[value] = path.name

    if data.get("formatVersion") != 6:
        issues.append("root: formatVersion must be 6; legacy formats are unsupported")
    if data.get("publicationState") not in PUBLICATION_STATES:
        issues.append("root: invalid publicationState")
    if data.get("lessonNumberingMode") not in LESSON_NUMBERING_MODES:
        issues.append("root: missing or invalid lessonNumberingMode")
    if data.get("defaultLessonIconStyle") not in LESSON_ICON_STYLES:
        issues.append("root: missing or invalid defaultLessonIconStyle")
    if data.get("lessonNumberingMode") == "other" and not str(data.get("customLessonLabel", "")).strip():
        issues.append("root: customLessonLabel is required for Other")
    for old in ("topics", "chapters", "supportUrl"):
        if old in data:
            issues.append(f"root: legacy {old} field is unsupported")
    if not isinstance(data.get("temporarySample"), bool):
        issues.append("root: temporarySample must be a boolean")
    if data.get("ttsLanguage") != EXPECTED_TTS[path.name]:
        issues.append(f"root: expected TTS locale {EXPECTED_TTS[path.name]}, found {data.get('ttsLanguage')!r}")
    if path.name == "korean_en.json":
        if (data.get("sourceLanguage"), data.get("targetLanguage")) != ("English", "Korean"):
            issues.append("root: Korean direction must be English to Korean")
        if data.get("flagCode") != "KR":
            issues.append("root: Korean course must use the South Korean KR flag")
    add_id(data.get("courseId"), "root")

    lesson_icon_assets = data.get("lessonIconAssets", [])
    managed_icon_ids: set[str] = set()
    if not isinstance(lesson_icon_assets, list):
        issues.append("root: lessonIconAssets must be a list")
        lesson_icon_assets = []
    for index, asset in enumerate(lesson_icon_assets, 1):
        where = f"lesson icon asset {index}"
        if not isinstance(asset, dict):
            issues.append(f"{where}: must be an object")
            continue
        asset_id = asset.get("assetId")
        if not isinstance(asset_id, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", asset_id):
            issues.append(f"{where}: invalid assetId")
            continue
        if asset_id in managed_icon_ids:
            issues.append(f"{where}: duplicate assetId {asset_id}")
        managed_icon_ids.add(asset_id)
        encoded = asset.get("base64Png")
        try:
            png = base64.b64decode(encoded, validate=True) if isinstance(encoded, str) else b""
        except (binascii.Error, ValueError):
            png = b""
        if len(png) < 24 or png[:8] != b"\x89PNG\r\n\x1a\n" or png[12:16] != b"IHDR":
            issues.append(f"{where}: invalid PNG")
        elif int.from_bytes(png[16:20], "big") != 256 or int.from_bytes(png[20:24], "big") != 256:
            issues.append(f"{where}: PNG must be 256x256")

    def validate_content(content: dict[str, object], where: str) -> None:
        add_id(content.get("id"), where)
        if content.get("publicationState") not in PUBLICATION_STATES:
            issues.append(f"{where}: invalid publicationState")
        kind = content.get("kind")
        if kind not in CONTENT_KINDS:
            issues.append(f"{where}: unknown Content kind {kind}")
        refs = content.get("sourceRefs", [])
        if not isinstance(refs, list):
            issues.append(f"{where}: sourceRefs must be a list")
        else:
            for ref in refs:
                if isinstance(ref, str) and ref.strip():
                    pending_refs.append((ref, where))
                else:
                    issues.append(f"{where}: invalid sourceRef")
        if kind == "exercise":
            exercise = content.get("exercise")
            if not isinstance(exercise, dict):
                issues.append(f"{where}: exercise payload missing")
                return
            _timestamp(exercise.get("updatedAt"), f"{where} exercise", issues)
            interaction = exercise.get("interaction")
            evaluation = exercise.get("evaluation")
            if not isinstance(interaction, dict) or interaction.get("kind") not in INTERACTIONS:
                issues.append(f"{where}: invalid interaction")
                interaction = {}
            if not isinstance(evaluation, dict) or evaluation.get("kind") not in EVALUATIONS:
                issues.append(f"{where}: invalid evaluation")
                evaluation = {}
            for old in ("accepted", "correctOrder", "caseSensitive", "ignorePunctuation", "ignoreAccents"):
                if old in evaluation:
                    issues.append(f"{where}: legacy evaluation field {old} is unsupported")
            items = interaction.get("items", [])
            if not isinstance(items, list):
                issues.append(f"{where}: interaction.items must be a list")
                items = []
            item_ids: list[str] = []
            item_values: dict[str, str] = {}
            for item_index, item in enumerate(items, 1):
                if not isinstance(item, dict):
                    issues.append(f"{where}: Item {item_index} must be an object")
                    continue
                item_id = item.get("id")
                add_id(item_id, f"{where} Item {item_index}")
                if not isinstance(item_id, str):
                    continue
                item_ids.append(item_id)
                parts = item.get("content", [])
                if isinstance(parts, list):
                    item_values[item_id] = next((str(part.get("text", "")) for part in parts if isinstance(part, dict) and part.get("type") == "text"), "")
            correct_ids = evaluation.get("correctItemIds", [])
            if not isinstance(correct_ids, list):
                issues.append(f"{where}: correctItemIds must be a list")
            elif any(item_id not in item_ids for item_id in correct_ids):
                issues.append(f"{where}: correctItemIds references a missing Item")
            pairs = evaluation.get("pairs", [])
            if not isinstance(pairs, list):
                issues.append(f"{where}: pairs must be a list")
            elif any(not isinstance(pair, list) or len(pair) != 2 or any(value not in item_ids for value in pair) for pair in pairs):
                issues.append(f"{where}: invalid matched_items pair")
            if evaluation.get("kind") == "text_match":
                accepted = evaluation.get("acceptedAnswers")
                if not isinstance(accepted, list) or not any(isinstance(value, str) and value.strip() for value in accepted):
                    issues.append(f"{where}: text_match requires non-empty acceptedAnswers")
            if interaction.get("kind") == "input" and evaluation.get("kind") != "text_match":
                issues.append(f"{where}: input interaction must use text_match evaluation")
            if interaction.get("kind") == "arrange":
                orders = evaluation.get("correctOrders")
                if not isinstance(orders, list) or not orders:
                    issues.append(f"{where}: arrange requires non-empty correctOrders")
                else:
                    normalized: set[str] = set()
                    for order_index, order in enumerate(orders, 1):
                        if not isinstance(order, dict):
                            issues.append(f"{where}: correctOrders {order_index} must be an object")
                            continue
                        text = order.get("text")
                        sequence = order.get("itemIds")
                        if not isinstance(text, str) or not text.strip():
                            issues.append(f"{where}: correctOrders {order_index} needs literal text")
                            continue
                        key = _ordered_text(text)
                        if key in normalized:
                            issues.append(f"{where}: duplicate normalized correct translation")
                        normalized.add(key)
                        if not isinstance(sequence, list) or not sequence:
                            issues.append(f"{where}: correctOrders {order_index} needs itemIds")
                            continue
                        if len(sequence) != len(set(sequence)):
                            issues.append(f"{where}: correctOrders {order_index} reuses an Item ID")
                        if any(item_id not in item_ids for item_id in sequence):
                            issues.append(f"{where}: correctOrders {order_index} references a missing Item")
                            continue
                        if _ordered_text(" ".join(item_values.get(item_id, "") for item_id in sequence)) != key:
                            issues.append(f"{where}: correctOrders {order_index} is not constructible")
        if kind == "presentation":
            presentation = content.get("presentation")
            completion = presentation.get("completion") if isinstance(presentation, dict) else None
            actions = completion.get("actions", []) if isinstance(completion, dict) else []
            if not {"understood", "review_later"}.issubset(set(actions)):
                issues.append(f"{where}: presentation must support understood and review_later")

    lessons = data.get("lessons")
    if not isinstance(lessons, list):
        return issues + ["root: lessons must be a list"]
    if len(lessons) != 9:
        issues.append(f"root: bundled course must contain exactly 9 Lessons, found {len(lessons)}")
    for lesson_index, lesson in enumerate(lessons, 1):
        where_lesson = f"lesson {lesson_index}"
        if not isinstance(lesson, dict):
            issues.append(f"{where_lesson}: must be an object")
            continue
        for old in ("id", "topicId", "role", "assessment", "imageAsset"):
            if old in lesson:
                issues.append(f"{where_lesson}: legacy field {old} is unsupported")
        add_id(lesson.get("lessonId"), where_lesson)
        _timestamp(lesson.get("updatedAt"), where_lesson, issues)
        if lesson.get("publicationState") not in PUBLICATION_STATES:
            issues.append(f"{where_lesson}: invalid publicationState")
        section = lesson.get("section", False)
        section_name = lesson.get("sectionName")
        if not isinstance(section, bool):
            issues.append(f"{where_lesson}: section must be a boolean")
        elif section and (not isinstance(section_name, str) or not section_name.strip()):
            issues.append(f"{where_lesson}: sectionName is required")
        elif not section and isinstance(section_name, str) and section_name.strip():
            issues.append(f"{where_lesson}: sectionName must be absent")
        icon = lesson.get("themeIconAsset")
        if icon is not None:
            managed = re.fullmatch(r"course-assets/lesson-icons/([A-Za-z0-9_-]+)\.png", icon) if isinstance(icon, str) else None
            if managed and managed.group(1) not in managed_icon_ids:
                issues.append(f"{where_lesson}: unresolved managed themeIconAsset: {icon}")
            elif not managed and (not isinstance(icon, str) or icon not in LESSON_ICON_PATHS or not (ROOT / icon).is_file()):
                issues.append(f"{where_lesson}: invalid or missing themeIconAsset: {icon}")
        guidebook = lesson.get("guidebook")
        guide_content = guidebook.get("content") if isinstance(guidebook, dict) else None
        if not isinstance(guide_content, list) or not guide_content:
            issues.append(f"{where_lesson}: guidebook.content must be non-empty")
        else:
            for content_index, content in enumerate(guide_content, 1):
                if isinstance(content, dict):
                    validate_content(content, f"{where_lesson} guidebook content {content_index}")
                else:
                    issues.append(f"{where_lesson} guidebook content {content_index}: must be an object")
        duel = lesson.get("duel")
        if not isinstance(duel, dict):
            issues.append(f"{where_lesson}: duel must be an object")
        else:
            add_id(duel.get("id"), f"{where_lesson} duel")
            if set(duel) - {"id", "title"}:
                issues.append(f"{where_lesson} duel: unsupported fields")
        rounds = lesson.get("rounds")
        if not isinstance(rounds, list):
            issues.append(f"{where_lesson}: rounds must be a list")
            continue
        for round_index, round_data in enumerate(rounds, 1):
            round_where = f"{where_lesson} round {round_index}"
            if not isinstance(round_data, dict):
                issues.append(f"{round_where}: must be an object")
                continue
            add_id(round_data.get("id"), round_where)
            _timestamp(round_data.get("updatedAt"), round_where, issues)
            if round_data.get("publicationState") not in PUBLICATION_STATES:
                issues.append(f"{round_where}: invalid publicationState")
            if round_data.get("visualType") not in ROUND_VISUAL_TYPES:
                issues.append(f"{round_where}: invalid visualType")
            if "title" in round_data and not isinstance(round_data["title"], str):
                issues.append(f"{round_where}: title must be a string")
            content_items = round_data.get("content")
            if not isinstance(content_items, list) or not content_items:
                issues.append(f"{round_where}: content must be non-empty")
                continue
            if round_index == 1:
                first = content_items[0]
                if not isinstance(first, dict) or first.get("role") != "lesson_intro" or first.get("kind") == "exercise":
                    issues.append(f"{round_where}: first Content must be a non-exercise lesson_intro")
            for content_index, content in enumerate(content_items, 1):
                if isinstance(content, dict):
                    validate_content(content, f"{round_where} content {content_index}")
                else:
                    issues.append(f"{round_where} content {content_index}: must be an object")
    for reference, where in pending_refs:
        if reference not in ids:
            issues.append(f"{where}: sourceRefs references missing Content {reference}")
    return issues


def main() -> int:
    files = sorted(COURSES.glob("*.json"))
    if {path.name for path in files} != set(EXPECTED_TTS):
        print(f"Expected exactly these nine bundled files: {sorted(EXPECTED_TTS)}")
        print(f"Found: {[path.name for path in files]}")
        return 1
    total = 0
    global_ids: dict[str, str] = {}
    for path in files:
        issues = validate(path, global_ids)
        total += len(issues)
        print(f"{path.name}: {'OK' if not issues else f'{len(issues)} issue(s)'}")
        for issue in issues:
            print(f"  - {issue}")
    print(f"Validated {len(files)} bundled Course Model v6 files.")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
