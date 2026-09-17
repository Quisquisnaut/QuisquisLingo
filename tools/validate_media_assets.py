#!/usr/bin/env python3
"""Validate QQL media references, provenance, uniqueness and locked audio."""

from __future__ import annotations

import hashlib
import json
import re
import struct
import sys
from collections import defaultdict
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
AUDIO = ASSETS / "audio"
AUDIO_LOCK = ROOT / "tools" / "media_asset_hashes.json"
WORLD_FLAGS = ASSETS / "world_flags"
WORLD_FLAG_MANIFEST = WORLD_FLAGS / "manifest.json"
IMAGE_METADATA = ASSETS / "exercise_images" / "metadata_v2.json"
BRAND_LOGO = ASSETS / "branding" / "qql_logo_4.png"
MEDIA_EXTENSIONS = frozenset(
    {".gif", ".jpeg", ".jpg", ".mp3", ".png", ".svg", ".wav", ".webp"}
)
EXPECTED_AUDIO_DIRECTORIES = frozenset(
    {
        "assets/audio/",
        "assets/audio/cy_sample/",
        "assets/audio/de_sample/",
        "assets/audio/en_sample/",
        "assets/audio/es_sample/",
        "assets/audio/fi_sample/",
        "assets/audio/it_sample/",
        "assets/audio/nl_sample/",
        "assets/audio/pt_sample/",
    }
)
STATIC_ASSET_REFERENCE = re.compile(
    r"['\"](assets/[A-Za-z0-9 _./-]+\.(?:gif|jpe?g|mp3|png|svg|wav|webp))['\"]",
    re.IGNORECASE,
)
UNSAFE_SVG = re.compile(
    r"<script\b|<foreignObject\b|\bon\w+\s*=|"
    r"(?:href|src)\s*=\s*['\"]https?://|<marker\b|"
    r"marker-(?:mid|start|end)\s*=\s*['\"](?!none['\"])",
    re.IGNORECASE,
)
QQL234_RENDERER_NORMALIZED_FLAG_IDS = frozenset(
    {"aragonese", "livonian", "piedmontese", "sicilian", "west_frisian"}
)
QQL238_RENDERER_NORMALIZED_FLAG_IDS = frozenset(
    {"mirandese", "romansh", "sardinian", "venetian"}
)
QQL234_RENDERER_INCOMPATIBLE_SVG = re.compile(
    r"<style\b|"
    r"<metadata\b|<sodipodi:namedview\b|<inkscape:perspective\b|"
    r"<defs\b[^>]*/>|(?s:<defs\b[^>]*>\s*</defs>)",
    re.IGNORECASE,
)


def logical_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def exact_case_exists(relative_path: str, *, directory: bool | None = None) -> bool:
    logical = PurePosixPath(relative_path.rstrip("/"))
    if logical.is_absolute() or not logical.parts or ".." in logical.parts:
        return False
    current = ROOT
    for part in logical.parts:
        if not current.is_dir() or part not in {child.name for child in current.iterdir()}:
            return False
        current /= part
    if directory is True:
        return current.is_dir()
    if directory is False:
        return current.is_file()
    return current.exists()


def load_json(path: Path, issues: list[str]) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        issues.append(f"cannot read {logical_path(path)}: {error}")
        return None


def iter_strings(value: Any) -> Iterable[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for nested in value.values():
            yield from iter_strings(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from iter_strings(nested)


def validate_audio(issues: list[str]) -> int:
    decoded = load_json(AUDIO_LOCK, issues)
    if not isinstance(decoded, dict) or decoded.get("schemaVersion") != 1:
        issues.append("tools/media_asset_hashes.json has an unsupported schema")
        return 0
    hashes = decoded.get("audioSha256")
    if not isinstance(hashes, dict) or any(
        not isinstance(path, str) or not isinstance(digest, str)
        for path, digest in hashes.items()
    ):
        issues.append("tools/media_asset_hashes.json has an invalid audioSha256 map")
        return 0

    expected = set(hashes)
    actual = {
        logical_path(path)
        for path in AUDIO.rglob("*")
        if path.is_file() and path.suffix.lower() in {".mp3", ".wav"}
    }
    if len(expected) != 19:
        issues.append(f"audio hash lock must contain 19 files, found {len(expected)}")
    if expected != actual:
        missing = sorted(expected - actual)
        unexpected = sorted(actual - expected)
        if missing:
            issues.append(f"locked audio missing on disk: {', '.join(missing)}")
        if unexpected:
            issues.append(f"unlocked audio files: {', '.join(unexpected)}")

    if any("/nap_sample/" in f"/{path}" for path in actual):
        issues.append("Neapolitan sample audio is outside QQL 234 scope")

    for relative_path in sorted(expected & actual):
        path = ROOT / PurePosixPath(relative_path)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        expected_digest = hashes[relative_path]
        if not re.fullmatch(r"[0-9a-f]{64}", expected_digest):
            issues.append(f"invalid locked SHA-256: {relative_path}")
        elif digest != expected_digest:
            issues.append(
                f"audio SHA-256 mismatch: {relative_path}; "
                f"expected {expected_digest}, found {digest}"
            )
        header = path.read_bytes()[:12]
        if path.suffix.lower() == ".wav" and not (
            header.startswith(b"RIFF") and header[8:12] == b"WAVE"
        ):
            issues.append(f"invalid WAV header: {relative_path}")
        if path.suffix.lower() == ".mp3" and not (
            header.startswith(b"ID3")
            or (len(header) >= 2 and header[0] == 0xFF and header[1] & 0xE0 == 0xE0)
        ):
            issues.append(f"invalid MP3 header: {relative_path}")

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    declared = {
        match.group(1)
        for match in re.finditer(r"^\s*-\s+(assets/[^\s#]+/)\s*$", pubspec, re.MULTILINE)
    }
    missing_directories = EXPECTED_AUDIO_DIRECTORIES - declared
    if missing_directories:
        issues.append(
            "pubspec is missing explicit audio directories: "
            + ", ".join(sorted(missing_directories))
        )
    return len(actual)


def validate_world_flags(issues: list[str]) -> int:
    decoded = load_json(WORLD_FLAG_MANIFEST, issues)
    if not isinstance(decoded, dict) or decoded.get("schemaVersion") != 1:
        issues.append("world-flag manifest has an unsupported schema")
        return 0
    entities = decoded.get("entities")
    counts = decoded.get("counts")
    if not isinstance(entities, list) or not isinstance(counts, dict):
        issues.append("world-flag manifest has invalid entities/counts")
        return 0

    ids: set[str] = set()
    declared_paths: set[str] = set()
    language_count = 0
    notice_path = WORLD_FLAGS / "LICENSE-language-related-flags.md"
    notice = notice_path.read_text(encoding="utf-8") if notice_path.is_file() else ""
    if not notice:
        issues.append("language-related flag license notice is missing")

    for index, entity in enumerate(entities):
        if not isinstance(entity, dict):
            issues.append(f"world flag entity {index} is not an object")
            continue
        entity_id = entity.get("id")
        asset_path = entity.get("assetPath")
        if not isinstance(entity_id, str) or not entity_id or entity_id in ids:
            issues.append(f"world flag entity {index} has a missing/duplicate ID")
            continue
        ids.add(entity_id)
        if not isinstance(asset_path, str) or not asset_path:
            issues.append(f"world flag {entity_id} has no assetPath")
            continue
        declared_paths.add(asset_path)
        if not exact_case_exists(asset_path, directory=False):
            issues.append(f"world flag path is missing or case-mismatched: {asset_path}")
            continue
        path = ROOT / PurePosixPath(asset_path)
        try:
            svg = path.read_text(encoding="utf-8-sig")
        except (OSError, UnicodeError) as error:
            issues.append(f"cannot read world flag {entity_id}: {error}")
            continue
        if "<svg" not in svg or UNSAFE_SVG.search(svg):
            issues.append(f"unsafe or renderer-incompatible SVG: {asset_path}")
        if (
            entity_id
            in (QQL234_RENDERER_NORMALIZED_FLAG_IDS | QQL238_RENDERER_NORMALIZED_FLAG_IDS)
            and QQL234_RENDERER_INCOMPATIBLE_SVG.search(svg)
        ):
            issues.append(
                f"renderer-normalized SVG still has incompatible markup: {asset_path}"
            )

        if entity.get("category") == "communityOrRegionalFlagAssociatedWithLanguage":
            language_count += 1
            required = (
                "artworkSourcePage",
                "artworkLicense",
                "artworkAuthor",
                "artworkSha1",
            )
            if any(not isinstance(entity.get(field), str) or not entity[field] for field in required):
                issues.append(f"language-related flag {entity_id} lacks provenance")
                continue
            source_digest = entity.get("artworkSourceSha1", entity["artworkSha1"])
            if not isinstance(source_digest, str) or not re.fullmatch(
                r"[0-9a-f]{40}", source_digest
            ):
                issues.append(f"language-related flag has invalid source SHA-1: {entity_id}")
                continue
            if not re.fullmatch(r"[0-9a-f]{40}", entity["artworkSha1"]):
                issues.append(f"language-related flag has invalid bundled SHA-1: {entity_id}")
                continue
            if "artworkSourceSha1" in entity and source_digest == entity["artworkSha1"]:
                issues.append(f"language-related flag has redundant source SHA-1: {entity_id}")
            digest = hashlib.sha1(path.read_bytes()).hexdigest()
            if digest != entity["artworkSha1"]:
                issues.append(f"language-related flag SHA-1 mismatch: {entity_id}")
            if (
                source_digest not in notice
                or entity["artworkSha1"] not in notice
                or entity["artworkSourcePage"] not in notice
            ):
                issues.append(f"language-related flag is absent from license notice: {entity_id}")

    physical_paths = {
        logical_path(path) for path in (WORLD_FLAGS / "flags").glob("*.svg")
    }
    if physical_paths != declared_paths:
        missing = sorted(declared_paths - physical_paths)
        unexpected = sorted(physical_paths - declared_paths)
        if missing:
            issues.append(f"world-flag assets missing on disk: {', '.join(missing)}")
        if unexpected:
            issues.append(f"unmanifested world-flag SVGs: {', '.join(unexpected)}")

    calculated_counts = {
        "entities": len(entities),
        "iso": sum(isinstance(entity, dict) and "isoAlpha2" in entity for entity in entities),
        "unMembers": sum(
            isinstance(entity, dict) and entity.get("category") == "unMember"
            for entity in entities
        ),
        "isoExtras": sum(
            isinstance(entity, dict) and entity.get("category") == "isoExtra"
            for entity in entities
        ),
        "shortlist": sum(
            isinstance(entity, dict) and entity.get("category") == "shortlist"
            for entity in entities
        ),
        "languageRelatedFlags": language_count,
    }
    if counts != calculated_counts:
        issues.append(
            f"world-flag counts differ: declared {counts}, calculated {calculated_counts}"
        )
    if calculated_counts != {
        "entities": 281,
        "iso": 249,
        "unMembers": 193,
        "isoExtras": 56,
        "shortlist": 8,
        "languageRelatedFlags": 24,
    }:
        issues.append(f"unexpected QQL 235 world-flag dataset: {calculated_counts}")
    return len(entities)


def validate_brand_logo(issues: list[str]) -> None:
    try:
        data = BRAND_LOGO.read_bytes()
    except OSError as error:
        issues.append(f"cannot read canonical brand logo: {error}")
        return
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        issues.append("canonical brand logo is not a valid PNG header")
        return
    width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
        ">IIBBBBB", data[16:29]
    )
    if width <= 0 or height <= 0 or bit_depth not in {8, 16}:
        issues.append("canonical brand logo has invalid PNG dimensions/bit depth")
    if color_type not in {4, 6}:
        issues.append("canonical brand logo PNG does not carry an alpha channel")
    if (compression, filtering, interlace) != (0, 0, 0):
        issues.append("canonical brand logo uses unexpected PNG encoding fields")
    main_source = (ROOT / "lib" / "main.dart").read_text(encoding="utf-8")
    if "assets/branding/qql_logo_4.png" not in main_source:
        issues.append("startup no longer references the canonical brand logo")


def validate_asset_references(issues: list[str]) -> int:
    references: set[str] = set()
    for path in (ROOT / "lib").rglob("*.dart"):
        source = path.read_text(encoding="utf-8")
        references.update(match.group(1) for match in STATIC_ASSET_REFERENCE.finditer(source))

    image_metadata = load_json(IMAGE_METADATA, issues)
    image_records = (
        image_metadata.get("records") if isinstance(image_metadata, dict) else None
    )
    image_assets = (
        {
            entry.get("assetPath")
            for entry in image_records
            if isinstance(entry, dict) and isinstance(entry.get("assetPath"), str)
        }
        if isinstance(image_records, list)
        else set()
    )
    course_image_references: set[str] = set()
    for path in (ASSETS / "courses").glob("*.json"):
        decoded = load_json(path, issues)
        for value in iter_strings(decoded):
            if value.startswith("assets/"):
                references.add(value)
            if value.startswith("assets/exercise_images/"):
                course_image_references.add(value)

    for reference in sorted(references):
        if "$" in reference:
            continue
        if not exact_case_exists(reference, directory=False):
            issues.append(f"missing or case-mismatched production asset reference: {reference}")
    unknown_course_images = course_image_references - image_assets
    if unknown_course_images:
        issues.append(
            "bundled Courses reference images outside canonical metadata: "
            + ", ".join(sorted(unknown_course_images))
        )

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    for match in re.finditer(r"^\s*-\s+(assets/[^\s#]+)\s*$", pubspec, re.MULTILINE):
        reference = match.group(1)
        if not exact_case_exists(reference, directory=reference.endswith("/")):
            issues.append(f"missing or case-mismatched pubspec asset: {reference}")
    return len(references)


def validate_no_byte_duplicates(issues: list[str]) -> int:
    media = [
        path
        for path in ASSETS.rglob("*")
        if path.is_file() and path.suffix.lower() in MEDIA_EXTENSIONS
    ]
    by_digest: dict[str, list[str]] = defaultdict(list)
    for path in media:
        by_digest[hashlib.sha256(path.read_bytes()).hexdigest()].append(logical_path(path))
    duplicates = [paths for paths in by_digest.values() if len(paths) > 1]
    for paths in duplicates:
        issues.append(f"byte-identical media files: {', '.join(sorted(paths))}")
    return len(media)


def main() -> int:
    issues: list[str] = []
    audio_count = validate_audio(issues)
    world_flag_count = validate_world_flags(issues)
    validate_brand_logo(issues)
    reference_count = validate_asset_references(issues)
    media_count = validate_no_byte_duplicates(issues)
    print(
        "Media assets: "
        f"{media_count} files; {audio_count} locked audio; "
        f"{world_flag_count} world flags; {reference_count} static references; "
        f"{len(issues)} issue(s)"
    )
    for issue in issues:
        print(f"  - {issue}")
    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
