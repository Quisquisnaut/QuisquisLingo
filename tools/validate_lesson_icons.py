#!/usr/bin/env python3
"""Validate the fixed QuisquisLingo Lesson theme-icon library."""

from __future__ import annotations

import binascii
import re
import struct
import sys
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ICON_DIRECTORY = ROOT / "assets" / "lesson_icons"
CATALOG = ROOT / "lib" / "services" / "lesson_icon_catalog.dart"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def _paeth(left: int, above: int, upper_left: int) -> int:
    estimate = left + above - upper_left
    distances = (
        abs(estimate - left),
        abs(estimate - above),
        abs(estimate - upper_left),
    )
    return (left, above, upper_left)[distances.index(min(distances))]


def _decode_png(path: Path) -> tuple[tuple[int, int], bool, int]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("invalid PNG signature")
    offset = len(PNG_SIGNATURE)
    dimensions: tuple[int, int] | None = None
    compressed = bytearray()
    saw_end = False
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError("truncated PNG chunk")
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload_start = offset + 8
        payload_end = payload_start + length
        if payload_end + 4 > len(data):
            raise ValueError("truncated PNG payload")
        payload = data[payload_start:payload_end]
        expected_crc = struct.unpack(">I", data[payload_end : payload_end + 4])[0]
        actual_crc = binascii.crc32(kind + payload) & 0xFFFFFFFF
        if actual_crc != expected_crc:
            raise ValueError(f"invalid CRC in {kind.decode('ascii', 'replace')} chunk")
        if kind == b"IHDR":
            if length != 13:
                raise ValueError("invalid IHDR length")
            width, height, bit_depth, color_type, compression, filtering, interlace = (
                struct.unpack(">IIBBBBB", payload)
            )
            if (bit_depth, color_type, compression, filtering, interlace) != (
                8,
                6,
                0,
                0,
                0,
            ):
                raise ValueError("icons must be non-interlaced 8-bit RGBA PNGs")
            dimensions = (width, height)
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            saw_end = True
            break
        offset = payload_end + 4
    if dimensions is None or not compressed or not saw_end:
        raise ValueError("required PNG chunks are missing")
    decoded = zlib.decompress(bytes(compressed))
    width, height = dimensions
    stride = width * 4
    if len(decoded) != (stride + 1) * height:
        raise ValueError("decoded RGBA scanline size is invalid")
    previous = bytearray(stride)
    has_transparency = False
    colors: set[tuple[int, int, int]] = set()
    for row_index in range(height):
        start = row_index * (stride + 1)
        filter_type = decoded[start]
        if filter_type > 4:
            raise ValueError(f"unsupported PNG row filter {filter_type}")
        source = decoded[start + 1 : start + 1 + stride]
        row = bytearray(stride)
        for index, value in enumerate(source):
            left = row[index - 4] if index >= 4 else 0
            above = previous[index]
            upper_left = previous[index - 4] if index >= 4 else 0
            predictor = (
                0
                if filter_type == 0
                else left
                if filter_type == 1
                else above
                if filter_type == 2
                else (left + above) // 2
                if filter_type == 3
                else _paeth(left, above, upper_left)
            )
            row[index] = (value + predictor) & 0xFF
        has_transparency = has_transparency or any(alpha < 255 for alpha in row[3::4])
        colors.update(
            (row[index], row[index + 1], row[index + 2])
            for index in range(0, len(row), 4)
            if row[index + 3] > 0
        )
        previous = row
    return dimensions, has_transparency, len(colors)


def main() -> int:
    issues: list[str] = []
    catalog_source = CATALOG.read_text(encoding="utf-8")
    catalog_paths = set(
        re.findall(r"assets/lesson_icons/[a-z0-9_]+\.png", catalog_source)
    )
    disk_paths = {
        path.relative_to(ROOT).as_posix()
        for path in ICON_DIRECTORY.glob("*.png")
        if path.is_file()
    }
    if catalog_paths != disk_paths:
        missing = sorted(catalog_paths - disk_paths)
        extra = sorted(disk_paths - catalog_paths)
        if missing:
            issues.append(f"catalog assets missing from disk: {', '.join(missing)}")
        if extra:
            issues.append(f"uncatalogued PNG assets: {', '.join(extra)}")
    for path in sorted(ICON_DIRECTORY.glob("*")):
        if not path.is_file() or path.suffix.lower() != ".png":
            continue
        try:
            dimensions, has_transparency, color_count = _decode_png(path)
            if dimensions != (256, 256):
                issues.append(f"{path.name}: dimensions are {dimensions}, expected 256x256")
            if not has_transparency:
                issues.append(f"{path.name}: image has no transparent pixels")
            if color_count > 4:
                issues.append(
                    f"{path.name}: has {color_count} visible RGB colors, expected at most 4"
                )
        except (OSError, ValueError, zlib.error) as error:
            issues.append(f"{path.name}: {error}")
    print(f"Lesson icons: {len(disk_paths)} assets; {len(issues)} issue(s)")
    for issue in issues:
        print(f"  - {issue}")
    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
