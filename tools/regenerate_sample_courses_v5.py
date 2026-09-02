#!/usr/bin/env python3
"""Regenerate bundled sample Lesson metadata for Course Model v5."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "assets" / "courses"
ICON_CATALOG = ROOT / "lib" / "services" / "lesson_icon_catalog.dart"


def _icon_paths_by_id() -> dict[str, str]:
    source = ICON_CATALOG.read_text(encoding="utf-8")
    entries = re.findall(
        r"LessonIconOption\(\s*id: '([^']+)',\s*"
        r"assetPath: '([^']+)',\s*label: '[^']+',\s*\)",
        source,
    )
    if not entries:
        raise ValueError("Lesson icon catalog could not be parsed")
    return dict(entries)


def _render_like_existing_samples(course: dict[str, object]) -> str:
    """Keep the historical extra indentation inside the root Lesson array."""
    lines = json.dumps(course, ensure_ascii=False, indent=2).splitlines()
    lessons_start = lines.index('  "lessons": [')
    for index in range(lessons_start + 1, len(lines) - 2):
        lines[index] = "    " + lines[index]
    return "\n".join(lines) + "\n"


def regenerate(path: Path, icon_paths: dict[str, str]) -> None:
    course = json.loads(path.read_text(encoding="utf-8"))
    assert isinstance(course, dict)
    raw_lessons = course.get("lessons")
    if not isinstance(raw_lessons, list):
        raise ValueError(f"{path.name}: expected a root lessons list")
    course["formatVersion"] = 5
    course["version"] = "1.5.7"
    course["courseVersion"] = "1.5.7"
    course["contentRevision"] = "sample-lessons-v223"
    course["lastUpdated"] = "2026-09-02"
    course["updateSummary"] = (
        "Regenerated bundled sample courses for Course Model v5 Lessons, "
        "Section navigation metadata and complete Lesson theme icons."
    )
    course["courseDescription"] = (
        "TEMPORARY SAMPLE course regenerated for Course Model v5."
    )

    regenerated = []
    for index, original in enumerate(course["lessons"]):
        lesson = dict(original)
        lesson_id = lesson.pop("lessonId", lesson.pop("id", None))
        if not lesson_id:
            raise ValueError(f"{path.name}: Lesson {index + 1} has no identity")

        section_names = (
            ("Fundamentos", "Vida cotidiana", "Viajes")
            if path.name == "english_es.json"
            else ("Foundations", "Everyday Life", "Travel")
        )
        section_name = section_names[index // 3]
        theme_icon_ids = (
            "conversation",
            "family",
            "school",
            "food",
            "home",
            "coffee",
            "directions",
            "train",
            "airport",
        )
        theme_icon = icon_paths[theme_icon_ids[index]]
        title = lesson.pop("title")
        if index == 7:
            title = (
                "Transporte, direcciones y compra de billetes en la estación de tren"
                if path.name == "english_es.json"
                else "Transport, directions and buying tickets at the railway station"
            )

        item = {
            "lessonId": lesson_id,
            "title": title,
            "section": True,
            "sectionName": section_name,
            "themeIconAsset": theme_icon,
        }
        item.update(
            {
                key: value
                for key, value in lesson.items()
                if key
                not in {
                    "section",
                    "sectionName",
                    "themeIconAsset",
                    "imageAsset",
                }
            }
        )
        if path.name == "italian_en.json" and index in (0, 3, 7):
            meaningful_titles = {
                0: "Greetings and introductions",
                3: "Ordering food",
                7: "At the railway station",
            }
            rounds = item.get("rounds")
            if isinstance(rounds, list) and rounds:
                rounds[0]["title"] = meaningful_titles[index]
        regenerated.append(item)
    course["lessons"] = regenerated
    path.write_text(_render_like_existing_samples(course), encoding="utf-8")


def main() -> int:
    paths = sorted(COURSES.glob("*.json"))
    if not paths:
        raise FileNotFoundError("No bundled sample courses found")
    icon_paths = _icon_paths_by_id()
    for path in paths:
        regenerate(path, icon_paths)
        print(f"{path.name}: regenerated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
