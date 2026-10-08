#!/usr/bin/env python3
"""Release integrity checks for the built-in QuisquisLingo Image Bank."""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path, PurePosixPath
from typing import Any

try:
    from PIL import Image
except ImportError:
    print("Pillow is required: python -m pip install Pillow", file=sys.stderr)
    raise SystemExit(2)

# Build 264 Revision 4: the one measure of a picture lost on a white page.
from outline_light_edges import EDGE_WHITE_LIMIT, edge_white_share


ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT / "assets" / "exercise_images"
METADATA_CATALOG = BANK / "metadata_v2.json"
# Build 264 Revision 1: the flags of the library are the World Flags' own
# SVGs, one record for each World Flag, with the flag's credit.
WORLD_FLAGS_MANIFEST = ROOT / "assets" / "world_flags" / "manifest.json"
WORLD_FLAGS_PREFIX = "assets/world_flags/flags/"
# Build 264 Revision 8: the Lesson icons are in the library too, as the
# category lesson_icons, one record for each icon of the Lesson icon catalog
# (their PNG files are checked by tools/validate_lesson_icons.py).
LESSON_ICONS_PREFIX = "assets/lesson_icons/"
LESSON_ICON_CATALOG = ROOT / "lib" / "services" / "lesson_icon_catalog.dart"
VALIDATOR_VERSION = "2.9.0"
MAX_BYTES = 50 * 1024
# Build 265 (owner, 7 October 2026): every bundled record outside the
# character categories carries at least five tags besides its name (Revisions
# 5 to 7 reported it, Revision 8 refuses it); no record carries more than 32
# tags or a tag longer than 80 characters. Image Banks an Admin imports keep
# their own rule (at least one tag).
MIN_TAGS = 5
MAX_TAGS = 32
MAX_TAG_LENGTH = 80
# Owner decisions of 5 October 2026 (Build 264): character pictures may be
# opaque; every other picture uses transparency.
# Since Build 264 Revision 2 every character category starts with
# "characters_".
CHARACTER_CATEGORY_PREFIXES = ("characters_",)
CHARACTER_CATEGORIES = frozenset()
# Words of an ID that are not part of a character's Unicode name.
GLYPH_ID_EXTRA_WORDS = frozenset({"isolated"})
# The categories of lib/models/image_categories.dart (Build 264 Revision 2).
ALLOWED_CATEGORIES = frozenset(
    {
        "actions",
        "animals",
        "appearance",
        "architecture",
        "art_cinema",
        "body_parts",
        "business_work",
        "celebrations",
        "characters_accented",
        "characters_arabic",
        "characters_armenian",
        "characters_blocks",
        "characters_chinese",
        "characters_confusables",
        "characters_currency",
        "characters_cyrillic",
        "characters_devanagari",
        "characters_diacritics",
        "characters_georgian",
        "characters_greek",
        "characters_hebrew",
        "characters_hiragana",
        "characters_katakana",
        "characters_korean",
        "characters_latin",
        "characters_maths",
        "characters_punctuation",
        "characters_symbols",
        "characters_thai",
        "city_places",
        "clock_times",
        "clothing_accessories",
        "colors",
        "communication",
        "concepts",
        "construction_farming",
        "crime_law",
        "culture_traditions",
        "death_remembrance",
        "directions_positions",
        "economy_finance",
        "emotions",
        "everyday_objects",
        "flags",
        "food_descriptions",
        "food_drinks",
        "games",
        "grammar",
        "grammar_time",
        "greetings_expressions",
        "health_care",
        "health_illness",
        "historical_figures",
        "hobbies_leisure",
        "home_household",
        "ideas_opinions",
        "jobs_professions",
        "landmarks",
        "languages",
        "lesson_icons",
        "life_stages",
        "literary_characters",
        "maps_navigation",
        "materials_commodities",
        "movement",
        "mythology",
        "nature",
        "numbers",
        "opposites",
        "other",
        "people_family",
        "personality",
        "politics",
        "pronouns_be_have",
        "quantity_pointing",
        "question_words",
        "relationships",
        "religious_figures",
        "restaurant",
        "school_work",
        "services",
        "shapes_patterns",
        "shopping",
        "sizes_dimensions",
        "sports",
        "street_signs",
        "symbols",
        "technology",
        "time_calendar",
        "tools",
        "transport",
        "travel",
        "units",
        "utilities",
    }
)

# Historical reference only: these sets do not constrain future additions.
# QQL 234's visual audit found 92 images requiring semantic replacement. The
# other 19 final retained assets were already clean; five receive padding-only normalization
# so every final bank image has a transparent outer border.
AUDITED_CLEAN_FILENAMES = frozenset(
    {
        "apple.webp",
        "backpack.webp",
        "book.webp",
        "boy.webp",
        "bread.webp",
        "car.webp",
        "cat.webp",
        "chair.webp",
        "coffee.webp",
        "eye.webp",
        "grandfather.webp",
        "hat.webp",
        "hospital.webp",
        "house.webp",
        "train.webp",
        "tree.webp",
        "wallet.webp",
        "water.webp",
        "woman.webp",
    }
)
PADDING_ONLY_FILENAMES = frozenset(
    {
        "boy.webp",
        "eye.webp",
        "grandfather.webp",
        "hat.webp",
        "hospital.webp",
    }
)


def load_metadata_records(path: Path, issues: list[str]) -> list[dict[str, Any]]:
    try:
        decoded = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        issues.append(f"cannot read {path.relative_to(ROOT).as_posix()}: {error}")
        return []
    if not isinstance(decoded, dict) or decoded.get("schemaVersion") != 1:
        issues.append(
            f"metadata catalog has an unsupported schema: "
            f"{path.relative_to(ROOT).as_posix()}"
        )
        return []
    decoded = decoded.get("records")
    if not isinstance(decoded, list):
        issues.append(f"metadata catalog has no records list: {path.relative_to(ROOT).as_posix()}")
        return []
    result: list[dict[str, Any]] = []
    for index, value in enumerate(decoded):
        if not isinstance(value, dict):
            issues.append(f"{path.name}[{index}] is not an object")
            continue
        result.append(value)
    return result


def required_text(
    item: dict[str, Any],
    key: str,
    location: str,
    issues: list[str],
) -> str:
    value = item.get(key)
    if not isinstance(value, str) or not value.strip():
        issues.append(f"{location}: {key} must be a non-empty string")
        return ""
    if value != value.strip():
        issues.append(f"{location}: {key} has surrounding whitespace")
    return value.strip()


def normalized_tags(
    item: dict[str, Any],
    key: str,
    location: str,
    issues: list[str],
) -> tuple[str, ...]:
    value = item.get(key)
    if not isinstance(value, list) or not value:
        issues.append(f"{location}: {key} must contain at least one tag")
        return ()
    tags: list[str] = []
    for index, tag in enumerate(value):
        if not isinstance(tag, str) or not tag:
            issues.append(f"{location}: {key}[{index}] must be a non-empty string")
            continue
        if tag != tag.strip():
            issues.append(f"{location}: tag has surrounding whitespace: {tag!r}")
        tags.append(tag)
    keys = [word_key(tag) for tag in tags]
    if len(set(keys)) != len(keys):
        issues.append(f"{location}: tags are not unique (capitals and spaces ignored)")
    return tuple(tags)


def word_key(value: str) -> str:
    """A name or tag as the rules compare it: capitals and spacing ignored,
    accents kept (the library search keeps them too)."""
    return re.sub(r"\s+", " ", value.strip().lower())


def is_character_category(category: str) -> bool:
    return category.startswith(CHARACTER_CATEGORY_PREFIXES) or (
        category in CHARACTER_CATEGORIES
    )


def glyph_issue(record: dict[str, Any]) -> str | None:
    """Whether a character picture's name is the character its ID names.

    An ID ending in a code point (`_00e9`) must name that character; a
    letter or kana named in words (`char_greek_capital_alpha`) must have a
    Unicode name ending in the ID's last word. Chinese characters are named
    by meaning, so only their single-character name is checked.
    """
    image_id = record["id"]
    label = record["label"]
    if "char_" not in image_id or len(label) != 1:
        return None
    tail = image_id.split("char_", 1)[1]
    code_point = re.search(r"_([0-9a-f]{4,5})$", tail)
    if code_point:
        if ord(label) != int(code_point.group(1), 16):
            return f"{image_id}: name {label!r} is not U+{code_point.group(1).upper()}"
        return None
    try:
        name = unicodedata.name(label).lower()
    except ValueError:
        return f"{image_id}: name {label!r} has no Unicode name"
    if name.startswith("cjk unified ideograph"):
        return None
    words = [part for part in tail.split("_") if part and part not in GLYPH_ID_EXTRA_WORDS]
    if not words:
        return f"{image_id}: the ID names no character"
    unicode_words = set(re.split(r"[^a-z0-9]+", name))
    if words[-1] not in unicode_words:
        return f"{image_id}: name {label!r} is {name.upper()}"
    return None


def metadata_record(
    item: dict[str, Any],
    index: int,
    issues: list[str],
) -> dict[str, Any]:
    location = f"metadata_v2.json.records[{index}]"
    expected_keys = {"id", "label", "category", "tags", "assetPath", "origin"}
    if not expected_keys <= set(item) <= expected_keys | {"attribution"}:
        issues.append(
            f"{location}: fields differ; expected {sorted(expected_keys)} "
            f"and an optional attribution, found {sorted(item)}"
        )
    attribution = item.get("attribution")
    if attribution is not None and (
        not isinstance(attribution, dict)
        or not set(attribution) <= {"author", "license", "title", "source"}
        or not all(
            isinstance(attribution.get(field), str) and attribution[field].strip()
            for field in ("author", "license")
        )
    ):
        issues.append(f"{location}: attribution needs an author and a license")
    result = {
        "id": required_text(item, "id", location, issues),
        "label": required_text(item, "label", location, issues),
        "category": required_text(item, "category", location, issues),
        "tags": normalized_tags(item, "tags", location, issues),
        "assetPath": required_text(item, "assetPath", location, issues),
        "origin": required_text(item, "origin", location, issues),
    }
    if result["category"] not in ALLOWED_CATEGORIES:
        issues.append(f"{location}: unsupported category {result['category']!r}")
    if result["origin"] != "bundled":
        issues.append(f"{location}: bundled metadata origin must be 'bundled'")
    # Every image has a tag besides its name, and the name is never repeated
    # as a tag: the library search reads the name already (owner, Build 264).
    if result["label"] and any(
        word_key(tag) == word_key(result["label"]) for tag in result["tags"]
    ):
        issues.append(f"{location}: a tag repeats the name {result['label']!r}")
    # Build 265 Revision 8: enough tags to be found, not so many that they
    # stop meaning anything; character pictures have no minimum.
    tag_count = len(result["tags"])
    if not is_character_category(result["category"]) and tag_count < MIN_TAGS:
        issues.append(
            f"{location}: {result['id']} has {tag_count} tag(s); at least {MIN_TAGS} "
            "outside the character categories"
        )
    if tag_count > MAX_TAGS:
        issues.append(f"{location}: {result['id']} has {tag_count} tags; at most {MAX_TAGS}")
    for tag in result["tags"]:
        if len(tag) > MAX_TAG_LENGTH:
            issues.append(
                f"{location}: {result['id']} has a tag over {MAX_TAG_LENGTH} characters: {tag!r}"
            )
    return result


def exact_case_exists(relative_path: str) -> bool:
    logical = PurePosixPath(relative_path)
    if logical.is_absolute() or ".." in logical.parts:
        return False
    current = ROOT
    for part in logical.parts:
        if not current.is_dir() or part not in {child.name for child in current.iterdir()}:
            return False
        current /= part
    return current.is_file()


def vp8l_info(path: Path) -> tuple[int, int, bool]:
    data = path.read_bytes()
    if len(data) < 21 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        raise ValueError("not a RIFF WebP")
    if int.from_bytes(data[4:8], "little") + 8 != len(data):
        raise ValueError("RIFF size does not match file size")

    chunks: dict[bytes, list[bytes]] = {}
    offset = 12
    while offset < len(data):
        if offset + 8 > len(data):
            raise ValueError("truncated WebP chunk header")
        fourcc = data[offset : offset + 4]
        chunk_size = int.from_bytes(data[offset + 4 : offset + 8], "little")
        start = offset + 8
        end = start + chunk_size
        if end > len(data):
            raise ValueError(f"truncated {fourcc.decode('ascii', errors='replace')} chunk")
        chunks.setdefault(fourcc, []).append(data[start:end])
        offset = end + (chunk_size & 1)
    if offset != len(data):
        raise ValueError("invalid WebP chunk padding")
    if b"VP8 " in chunks or len(chunks.get(b"VP8L", [])) != 1:
        raise ValueError("image is not a single lossless VP8L bitstream")

    payload = chunks[b"VP8L"][0]
    if len(payload) < 5 or payload[0] != 0x2F:
        raise ValueError("invalid VP8L signature")
    bits = int.from_bytes(payload[1:5], "little")
    width = (bits & 0x3FFF) + 1
    height = ((bits >> 14) & 0x3FFF) + 1
    alpha_is_used = bool((bits >> 28) & 1)
    version = bits >> 29
    if version != 0:
        raise ValueError(f"unsupported VP8L version {version}")
    return width, height, alpha_is_used


def main() -> int:
    issues: list[str] = []
    raw_runtime = load_metadata_records(METADATA_CATALOG, issues)
    raw_by_id = {item.get("id"): item for item in raw_runtime}
    runtime = [
        metadata_record(item, index, issues)
        for index, item in enumerate(raw_runtime)
    ]
    if not runtime:
        issues.append("metadata_v2.json: catalog must contain at least one asset")

    for field in ("id", "assetPath"):
        values = [item[field] for item in runtime]
        normalized_values = [value.casefold() for value in values]
        if len(set(normalized_values)) != len(normalized_values):
            issues.append(
                f"metadata_v2.json: {field} values are not case-insensitively unique"
            )

    # A name is unique within its category, compared exactly: A and a are
    # two letters.
    names: dict[tuple[str, str], str] = {}
    for item in runtime:
        key = (item["category"], item["label"])
        if key in names:
            issues.append(
                f"metadata_v2.json: {item['id']} has the name {item['label']!r} "
                f"of {names[key]} in {item['category']}"
            )
        names.setdefault(key, item["id"])

    glyphs_checked = 0
    for item in runtime:
        if not is_character_category(item["category"]):
            continue
        glyphs_checked += 1
        issue = glyph_issue(item)
        if issue:
            issues.append(issue)
    character_paths = {
        item["assetPath"] for item in runtime if is_character_category(item["category"])
    }

    world_flags = json.loads(WORLD_FLAGS_MANIFEST.read_text(encoding="utf-8"))["entities"]
    flag_paths = [item["assetPath"] for item in runtime if item["category"] == "flags"]
    world_flag_paths = sorted(entity["assetPath"] for entity in world_flags)
    if sorted(flag_paths) != world_flag_paths:
        issues.append(
            "the flag records must be the World Flags, one record each: "
            f"{len(flag_paths)} records, {len(world_flag_paths)} World Flags"
        )
    for item in runtime:
        if item["category"] == "flags" and "attribution" not in raw_by_id.get(item["id"], {}):
            issues.append(f"{item['id']}: a flag record carries its flag's credit")
        if item["assetPath"].startswith(WORLD_FLAGS_PREFIX) and item["category"] != "flags":
            issues.append(f"{item['id']}: a World Flag picture belongs to flags")

    icon_paths = sorted(
        item["assetPath"] for item in runtime if item["category"] == "lesson_icons"
    )
    catalog_icon_paths = sorted(
        set(
            re.findall(
                r"assets/lesson_icons/[a-z0-9_]+\.png",
                LESSON_ICON_CATALOG.read_text(encoding="utf-8"),
            )
        )
    )
    if icon_paths != catalog_icon_paths:
        issues.append(
            "the lesson_icons records must be the Lesson icons, one record each: "
            f"{len(icon_paths)} records, {len(catalog_icon_paths)} icons"
        )
    for item in runtime:
        if item["assetPath"].startswith(LESSON_ICONS_PREFIX) and item["category"] != "lesson_icons":
            issues.append(f"{item['id']}: a Lesson icon picture belongs to lesson_icons")

    declared_paths = {
        item["assetPath"]
        for item in runtime
        if item["assetPath"]
        and not item["assetPath"].startswith(WORLD_FLAGS_PREFIX)
        and not item["assetPath"].startswith(LESSON_ICONS_PREFIX)
    }
    physical_paths = {
        path.relative_to(ROOT).as_posix() for path in BANK.glob("*.webp")
    }
    missing = sorted(declared_paths - physical_paths)
    unexpected = sorted(physical_paths - declared_paths)
    if missing:
        issues.append(f"manifest assets missing on disk: {', '.join(missing)}")
    if unexpected:
        issues.append(f"unmanifested WebP files: {', '.join(unexpected)}")

    for logical_path in sorted(declared_paths):
        if not logical_path.startswith("assets/exercise_images/"):
            issues.append(f"asset path is outside the Image Bank: {logical_path}")
            continue
        if not exact_case_exists(logical_path):
            issues.append(f"missing or case-mismatched path: {logical_path}")
            continue
        path = ROOT / PurePosixPath(logical_path)
        size = path.stat().st_size
        if size > MAX_BYTES:
            issues.append(f"over 50 KiB: {logical_path} ({size} bytes)")
        try:
            with Image.open(path) as image:
                if image.format != "WEBP":
                    issues.append(f"not a WebP image: {logical_path}")
                    continue
                if getattr(image, "n_frames", 1) != 1:
                    issues.append(f"multiple frames are not allowed: {logical_path}")
                    continue
                image.load()
                width, height = image.size
                if (width, height) != (256, 256):
                    issues.append(f"wrong dimensions {logical_path}: {width}x{height}")
                if logical_path not in character_paths:
                    if "A" not in image.getbands():
                        issues.append(f"missing alpha channel: {logical_path}")
                    elif image.getchannel("A").getextrema()[0] == 255:
                        issues.append(f"no transparent pixels: {logical_path}")
                    elif edge_white_share(image) >= EDGE_WHITE_LIMIT:
                        issues.append(
                            f"edge mostly near-white, lost on a white page: {logical_path} "
                            "(python tools/outline_light_edges.py FILE)"
                        )
        except (OSError, ValueError, Image.DecompressionBombError) as error:
            issues.append(f"invalid WebP {logical_path}: {error}")

    print(
        f"Image Bank validator {VALIDATOR_VERSION}: {len(runtime)} metadata records; "
        f"{len(physical_paths)} WebP files; {len(flag_paths)} World Flags; "
        f"{len(icon_paths)} Lesson icons; "
        f"{glyphs_checked} character pictures; "
        f"{len(issues)} issue(s)"
    )
    for issue in issues:
        print(f"  - {issue}")
    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
