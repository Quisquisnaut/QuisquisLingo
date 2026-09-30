#!/usr/bin/env python3
"""Offline structural validation for bundled Course Model v12 JSON.

The exercise vocabularies (primitives, options, evaluation modes) come from
docs/capabilities_v12.json, the capability description written by
`dart run tools/export_capabilities.dart` from the registry in
lib/models/canonical/ (Build 256 Revision 6), through tools/qql_capabilities.py
and tools/qql_course_v12.py.
"""
from __future__ import annotations

import base64
import binascii
import hashlib
import json
import re
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from qql_course_v12 import CONTENT_KINDS, EVALUATION_MODES, OPTIONS, PRIMITIVES  # noqa: E402
from qql_capabilities import ELEMENT_ATTRIBUTES  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "assets" / "courses"
EXPECTED_TTS = {
    "exercise_laboratory_en_it.json": "it-IT",
    "edge_case_it_en.json": "en-GB",
    "piedmontais_en.json": "pms-IT",
}
TEXT_MODES = {"exactText", "acceptedTexts", "expression"}
ROUND_VISUAL_TYPES = {"listening", "story", "generic", "test"}
PUBLICATION_STATES = {"draft", "published"}
LESSON_NUMBERING_MODES = {"lesson", "unit", "topic", "module", "skill", "chapter", "stage", "step", "part", "other", "numberOnly", "none"}
LESSON_ICON_STYLES = {"monochrome", "coloredLessonNumbers"}
LESSON_ICON_PATHS = set(re.findall(
    r"assets/lesson_icons/[a-z0-9_]+\.png",
    (ROOT / "lib" / "services" / "lesson_icon_catalog.dart").read_text(encoding="utf-8"),
))
UTC_TIMESTAMP = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$")


def _official_checksum(course: dict[str, object]) -> str:
    excluded = {"officialChecksum", "publisherVerificationStatus", "publisherSignature"}
    canonical = {
        key: json.loads(json.dumps(value, ensure_ascii=False))
        for key, value in course.items()
        if key not in excluded
    }
    if canonical.get("derivativeWorksPolicy") in (None, "unspecified"):
        canonical.pop("derivativeWorksPolicy", None)
    encoded = json.dumps(
        canonical, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _ordered_text(value: str) -> str:
    return re.sub(r"[.!?…]+$", "", " ".join(value.strip().split())).casefold()


def _portable_png(asset: str) -> bool:
    """Bounded structural check; Flutter's import validator decodes the pixels."""
    prefix = "data:image/png;base64,"
    if not asset.startswith(prefix) or len(asset) > 68300:
        return False
    encoded = asset[len(prefix):]
    try:
        png = base64.b64decode(encoded, validate=True)
    except (binascii.Error, ValueError):
        return False
    return (
        24 <= len(png) <= 50 * 1024
        and base64.b64encode(png).decode("ascii") == encoded
        and png[:8] == b"\x89PNG\r\n\x1a\n"
        and png[12:16] == b"IHDR"
        and 1 <= int.from_bytes(png[16:20], "big") <= 4096
        and 1 <= int.from_bytes(png[20:24], "big") <= 4096
    )


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

    if data.get("formatVersion") != 12:
        issues.append("root: formatVersion must be 12; legacy formats are unsupported")
    if data.get("publicationState") not in PUBLICATION_STATES:
        issues.append("root: invalid publicationState")
    if data.get("lessonNumberingMode") not in LESSON_NUMBERING_MODES:
        issues.append("root: missing or invalid lessonNumberingMode")
    if data.get("defaultLessonIconStyle") not in LESSON_ICON_STYLES:
        issues.append("root: missing or invalid defaultLessonIconStyle")
    if data.get("originType") != "bundledOfficial":
        issues.append("root: bundled course originType must be bundledOfficial")
    if data.get("derivativeWorksPolicy") not in (None, "allowed", "forbidden", "unspecified"):
        issues.append("root: derivativeWorksPolicy must be allowed, forbidden or unspecified")
    if "forkProvenance" in data:
        issues.append("root: official courses cannot contain custom forkProvenance")
    if data.get("publisherId") != "org.quisquislingo":
        issues.append("root: bundled publisherId must be org.quisquislingo")
    if data.get("publisherName") != "QuisquisLingo":
        issues.append("root: bundled publisherName must be QuisquisLingo")
    if data.get("publisherVerificationStatus") != "verified":
        issues.append("root: bundled publisher verification must be verified")
    if data.get("distributionChannel") != "bundled":
        issues.append("root: bundled distributionChannel must be bundled")
    if not isinstance(data.get("officialCourseVersion"), str) or not data.get("officialCourseVersion"):
        issues.append("root: officialCourseVersion is required")
    if data.get("officialChecksum") != _official_checksum(data):
        issues.append("root: officialChecksum does not match canonical course content")
    _timestamp(data.get("officialReleaseDateUtc"), "root official release", issues)
    _timestamp(data.get("originalCreatedAtUtc"), "root original Course creation", issues)
    _timestamp(data.get("modifiedAtUtc"), "root modification", issues)
    if data.get("originalCourseCreator") != {
        "type": "publisher",
        "id": "org.quisquislingo",
        "displayName": "QuisquisLingo",
    }:
        issues.append("root: bundled originalCourseCreator must identify the publisher")
    if data.get("lessonNumberingMode") == "other" and not str(data.get("customLessonLabel", "")).strip():
        issues.append("root: customLessonLabel is required for Other")
    for old in (
        "topics",
        "chapters",
        "supportUrl",
        "creatorProfileId",
        "ownership",
        "createdByProfileId",
        "createdByUsername",
        "createdAtUtc",
        "lastModifiedByProfileId",
        "lastModifiedByUsername",
        "lastModifiedAtUtc",
        "lastUpdated",
        "author",
        "version",
        "updateSummary",
        "contentRevision",
        "parentCourseId",
        "derivedFromVersion",
    ):
        if old in data:
            issues.append(f"root: legacy {old} field is unsupported")
    authors = data.get("authors", [])
    if not isinstance(authors, list):
        issues.append("root: authors must be a list")
    else:
        for index, author in enumerate(authors, 1):
            if not isinstance(author, dict):
                issues.append(f"root: author {index} must be an object")
                continue
            if "role" in author:
                issues.append(f"root: author {index} uses obsolete scalar role")
            if not isinstance(author.get("roles"), list):
                issues.append(f"root: author {index} roles must be a list")
    if not isinstance(data.get("temporarySample"), bool):
        issues.append("root: temporarySample must be a boolean")
    if data.get("ttsLanguage") != EXPECTED_TTS[path.name]:
        issues.append(f"root: expected TTS locale {EXPECTED_TTS[path.name]}, found {data.get('ttsLanguage')!r}")
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
            prompt = exercise.get("prompt")
            # An inline layout carries the exercise's text, so a prompt may be
            # empty when the layout is not (Type the missing word, Listen for
            # missing words).
            if not isinstance(prompt, list) or (not prompt and not exercise.get("layout")):
                issues.append(f"{where}: exercise prompt must be a non-empty list")
                prompt = []
            for prompt_index, element in enumerate(prompt, 1):
                if not isinstance(element, dict):
                    issues.append(f"{where}: prompt element {prompt_index} must be an object")
                    continue
                # Build 258: the Page attributes of an element.
                element_type = element.get("type")
                for key, spec in ELEMENT_ATTRIBUTES.items():
                    if key not in element:
                        continue
                    value = element[key]
                    label = f"{where}: prompt element {prompt_index} {key}"
                    if element_type not in spec["types"]:
                        issues.append(f"{label} does not apply to type {element_type}")
                    elif spec["values"] and value not in spec["values"]:
                        issues.append(f"{label} {value!r} is not one of {spec['values']}")
                    elif spec["type"] == "boolean" and not isinstance(value, bool):
                        issues.append(f"{label} must be true or false")
                    elif spec["type"] == "string" and not isinstance(value, str):
                        issues.append(f"{label} must be a string")
                    elif value in spec["text_only"] and element_type != "text":
                        issues.append(f"{label} {value!r} applies to text only")
                if element_type == "link":
                    url = element.get("url")
                    if not (isinstance(url, str) and re.match(r"^https://[^/\s]+", url)):
                        issues.append(
                            f"{where}: prompt link {prompt_index} needs an https address"
                        )
                if element.get("type") == "image":
                    asset = element.get("asset")
                    if isinstance(asset, str) and _portable_png(asset):
                        pass
                    elif not isinstance(asset, str) or not asset.startswith(
                        "assets/exercise_images/"
                    ):
                        issues.append(
                            f"{where}: prompt image {prompt_index} must reference "
                            "the bundled exercise-image library or a bounded portable PNG"
                        )
                    elif not (ROOT / asset).is_file():
                        issues.append(
                            f"{where}: prompt image {prompt_index} is missing: {asset}"
                        )
                    if not isinstance(element.get("text"), str) or not str(
                        element.get("text", "")
                    ).strip():
                        issues.append(
                            f"{where}: prompt image {prompt_index} needs a text alternative"
                        )
            primitive = exercise.get("primitive")
            if primitive not in PRIMITIVES:
                issues.append(f"{where}: unknown primitive {primitive!r}")
                return
            for legacy in ("interaction", "editorTemplate"):
                if legacy in exercise:
                    issues.append(f"{where}: legacy field {legacy} is unsupported in v12")
            options = exercise.get("options", {})
            if not isinstance(options, dict):
                issues.append(f"{where}: options must be an object")
                options = {}
            specs = OPTIONS[primitive]
            for key, value in options.items():
                spec = specs.get(key)
                if spec is None:
                    issues.append(f"{where}: option {key} does not apply to {primitive}")
                elif spec is int:
                    if not isinstance(value, int) or isinstance(value, bool):
                        issues.append(f"{where}: option {key} must be a whole number")
                elif spec is bool:
                    if not isinstance(value, bool):
                        issues.append(f"{where}: option {key} must be true or false")
                elif spec == "language":
                    if not isinstance(value, str) or not value.strip():
                        issues.append(f"{where}: option {key} must be a language tag")
                elif value not in spec:
                    issues.append(f"{where}: option {key} value {value!r} is not one of {spec}")
            joiner = "" if options.get("joiner") == "none" else " "
            items = exercise.get("items", [])
            if not isinstance(items, list):
                issues.append(f"{where}: items must be a list")
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
                side = item.get("side")
                if primitive == "match" and side not in {"left", "right"}:
                    issues.append(f"{where}: Match Item {item_index} needs a side")
                elif primitive != "match" and side is not None:
                    issues.append(f"{where}: only Match Items carry a side")
            targets = exercise.get("targets", [])
            if not isinstance(targets, list):
                issues.append(f"{where}: targets must be a list")
                targets = []
            target_ids: list[str] = []
            for target_index, target in enumerate(targets, 1):
                if not isinstance(target, dict) or not isinstance(target.get("id"), str) or not target["id"].strip():
                    issues.append(f"{where}: target {target_index} needs an id")
                    continue
                target_ids.append(target["id"])
                if "reveal" in target and target["reveal"] != "firstGrapheme":
                    issues.append(f"{where}: target {target_index} has an unknown reveal")
                if "region" in target:
                    region = target["region"]
                    if not isinstance(region, dict) or any(not isinstance(region.get(k), (int, float)) for k in ("x", "y", "width", "height")):
                        issues.append(f"{where}: target {target_index} region needs numeric x, y, width and height")
            if len(set(target_ids)) != len(target_ids):
                issues.append(f"{where}: target IDs must be unique")
            layout = exercise.get("layout", [])
            if not isinstance(layout, list):
                issues.append(f"{where}: layout must be a list")
                layout = []
            layout_targets: list[str] = []
            for element_index, element in enumerate(layout, 1):
                if not isinstance(element, dict):
                    issues.append(f"{where}: layout element {element_index} must be an object")
                elif element.get("type") == "target":
                    layout_targets.append(str(element.get("targetId", "")))
                elif element.get("type") != "text" or not isinstance(element.get("text"), str):
                    issues.append(f"{where}: layout element {element_index} must be text or target")
            if any(target not in target_ids for target in layout_targets):
                issues.append(f"{where}: layout refers to an unknown target")
            if layout and set(layout_targets) != set(target_ids):
                issues.append(f"{where}: every target must appear in the layout")
            evaluation = exercise.get("evaluation")
            if not isinstance(evaluation, dict):
                issues.append(f"{where}: evaluation must be an object")
                evaluation = {}
            mode = evaluation.get("mode")
            if mode not in EVALUATION_MODES[primitive]:
                issues.append(f"{where}: evaluation mode {mode!r} is not legal for {primitive}")
            known_keys = {"mode", "correctItemIds", "assignments", "answers", "literalAnswers", "targetAnswers", "numeric", "pattern", "correctOrders", "relations", "acceptedTargets"}
            for key in evaluation:
                if key not in known_keys:
                    issues.append(f"{where}: unknown evaluation field {key}")
            correct_ids = evaluation.get("correctItemIds", [])
            if not isinstance(correct_ids, list):
                issues.append(f"{where}: correctItemIds must be a list")
            elif any(item_id not in item_ids for item_id in correct_ids):
                issues.append(f"{where}: correctItemIds references a missing Item")
            assignments = evaluation.get("assignments", [])
            assigned_items: list[str] = []
            if not isinstance(assignments, list):
                issues.append(f"{where}: assignments must be a list")
                assignments = []
            for assignment in assignments:
                if not isinstance(assignment, dict) or assignment.get("targetId") not in target_ids:
                    issues.append(f"{where}: assignment refers to an unknown target")
                    continue
                assigned = assignment.get("itemIds", [])
                if not isinstance(assigned, list) or not assigned or any(i not in item_ids for i in assigned):
                    issues.append(f"{where}: assignment refers to a missing Item")
                else:
                    assigned_items.extend(assigned)
            if mode in {"exactItem", "gapAssignments", "exactAssignments"} and target_ids:
                if {a.get("targetId") for a in assignments if isinstance(a, dict)} != set(target_ids):
                    issues.append(f"{where}: every target needs exactly one assignment")
                elif primitive in {"select", "arrange"} and len(set(item_ids) - set(assigned_items)) > 2:
                    issues.append(f"{where}: gap exercise has more than two distractors")
            relations = evaluation.get("relations", [])
            if not isinstance(relations, list):
                issues.append(f"{where}: relations must be a list")
            elif any(not isinstance(pair, list) or len(pair) != 2 or any(value not in item_ids for value in pair) for pair in relations):
                issues.append(f"{where}: invalid Match relation")
            if primitive == "match" and not relations:
                issues.append(f"{where}: Match needs relations")
            if primitive == "input" and mode in TEXT_MODES:
                answers = evaluation.get("answers", [])
                target_answers = evaluation.get("targetAnswers", [])
                if target_ids:
                    if not isinstance(target_answers, list) or {t.get("targetId") for t in target_answers if isinstance(t, dict)} != set(target_ids):
                        issues.append(f"{where}: every Input target needs targetAnswers")
                    elif any(not isinstance(t.get("answers"), list) or not any(isinstance(a, str) and a.strip() for a in t["answers"]) for t in target_answers):
                        issues.append(f"{where}: every Input target needs a non-empty answer")
                elif not isinstance(answers, list) or not any(isinstance(a, str) and a.strip() for a in answers):
                    issues.append(f"{where}: Input needs non-empty answers")
            if primitive == "arrange" and mode in {"exactOrder", "acceptedOrders"}:
                orders = evaluation.get("correctOrders")
                if not isinstance(orders, list) or not orders:
                    issues.append(f"{where}: arrange requires non-empty correctOrders")
                else:
                    if (mode == "exactOrder") != (len(orders) == 1):
                        issues.append(f"{where}: exactOrder means one order, acceptedOrders several")
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
                        if _ordered_text(joiner.join(item_values.get(item_id, "") for item_id in sequence)) != key:
                            issues.append(f"{where}: correctOrders {order_index} is not constructible")
            if primitive == "presentation":
                if mode != "none":
                    issues.append(f"{where}: a Presentation is never scored")
                if not prompt:
                    issues.append(f"{where}: a Presentation needs content")
    lessons = data.get("lessons")
    if not isinstance(lessons, list):
        return issues + ["root: lessons must be a list"]
    expected_lessons = {
        # The Page Lesson (Build 258 Revision 3) is the eighth.
        "exercise_laboratory_en_it.json": 8,
        "edge_case_it_en.json": 6,
        # Listen and choose (Build 259 Revision 2) adds two Lessons.
        "piedmontais_en.json": 41,
    }.get(path.name, 9)
    if len(lessons) != expected_lessons:
        issues.append(
            f"root: bundled course must contain exactly {expected_lessons} Lessons, "
            f"found {len(lessons)}"
        )
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
                # Build 257: a Lesson's first Round opens with a Before you
                # start card (a presentation with an intro text element).
                first = content_items[0]
                first_exercise = first.get("exercise") if isinstance(first, dict) else None
                is_intro_card = (
                    isinstance(first_exercise, dict)
                    and first_exercise.get("primitive") == "presentation"
                    and any(isinstance(e, dict) and e.get("role") == "intro" and e.get("type") == "text"
                            for e in first_exercise.get("prompt", []))
                )
                if not is_intro_card:
                    issues.append(f"{round_where}: first Content must be a Before you start card")
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
        print(f"Expected exactly these bundled files: {sorted(EXPECTED_TTS)}")
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
    print(f"Validated {len(files)} bundled Course Model v12 files.")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
