#!/usr/bin/env python3
"""Release integrity checks for the built-in QuisquisLingo Image Bank."""

from __future__ import annotations

import json
import sys
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT / "assets" / "exercise_images"
METADATA_CATALOG = BANK / "metadata_v2.json"
EXPECTED_ASSET_COUNT = 111
MAX_BYTES = 50 * 1024
ALLOWED_CATEGORIES = frozenset(
    {
        "actions",
        "animals",
        "body_parts",
        "city_public_places",
        "clothing_accessories",
        "emotions",
        "food",
        "food_drinks",
        "home",
        "home_household",
        "nature",
        "other",
        "people_family",
        "school_work",
        "technology",
        "transport",
    }
)

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
    if len(set(tags)) != len(tags):
        issues.append(f"{location}: tags are not unique")
    return tuple(tags)


def metadata_record(
    item: dict[str, Any],
    index: int,
    issues: list[str],
) -> dict[str, Any]:
    location = f"metadata_v2.json.records[{index}]"
    expected_keys = {"id", "label", "category", "tags", "assetPath", "origin"}
    if set(item) != expected_keys:
        issues.append(
            f"{location}: fields differ; expected {sorted(expected_keys)}, "
            f"found {sorted(item)}"
        )
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
    runtime = [
        metadata_record(item, index, issues)
        for index, item in enumerate(raw_runtime)
    ]
    if len(runtime) != EXPECTED_ASSET_COUNT:
        issues.append(
            f"metadata_v2.json: expected {EXPECTED_ASSET_COUNT} entries, found {len(runtime)}"
        )

    for field in ("id", "label", "assetPath"):
        values = [item[field] for item in runtime]
        normalized_values = [value.casefold() for value in values]
        if len(set(normalized_values)) != len(normalized_values):
            issues.append(
                f"metadata_v2.json: {field} values are not case-insensitively unique"
            )

    declared_paths = {item["assetPath"] for item in runtime if item["assetPath"]}
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
            width, height, alpha_is_used = vp8l_info(path)
        except (OSError, ValueError) as error:
            issues.append(f"invalid lossless WebP {logical_path}: {error}")
            continue
        if (width, height) != (256, 256):
            issues.append(f"wrong dimensions {logical_path}: {width}x{height}")
        if not alpha_is_used:
            issues.append(f"VP8L alpha flag is not set: {logical_path}")

    physical_names = {PurePosixPath(path).name for path in physical_paths}
    semantic_replacements = physical_names - AUDITED_CLEAN_FILENAMES
    if len(AUDITED_CLEAN_FILENAMES) != 19 or len(semantic_replacements) != 92:
        issues.append("QQL 234 audit classification is not 92 replaced / 19 retained")
    if not PADDING_ONLY_FILENAMES <= AUDITED_CLEAN_FILENAMES:
        issues.append("padding-only files must be part of the audited-clean set")
    if not PADDING_ONLY_FILENAMES <= physical_names:
        issues.append("one or more padding-only normalization files are missing")

    print(
        f"Image Bank: {len(runtime)} assets; "
        f"92 semantic replacements; 5 padding-only normalizations; "
        f"{len(issues)} issue(s)"
    )
    for issue in issues:
        print(f"  - {issue}")
    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
