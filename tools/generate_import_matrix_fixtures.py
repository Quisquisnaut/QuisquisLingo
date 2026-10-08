"""Regenerate the small, synthetic Phase 20 import fixtures.

Run from the repository root: python tools/generate_import_matrix_fixtures.py
No third-party media or large binary files are needed.
"""

from pathlib import Path
import json
import struct
import zlib
from zipfile import ZIP_DEFLATED, ZipFile


OUT = Path("test/fixtures/import")
OUT.mkdir(parents=True, exist_ok=True)


def chunk(name: bytes, body: bytes) -> bytes:
    payload = name + body
    return struct.pack(">I", len(body)) + payload + struct.pack(">I", zlib.crc32(payload))


def png(width: int, height: int, *, animated: bool = False) -> bytes:
    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    # A tiny real raster for the positive control. Header-only adversarial
    # dimensions deliberately reuse it: inspection must reject before decode.
    rows = b"".join(b"\0" + b"\x80\x40\x20" * width for _ in range(height))
    animation = chunk(b"acTL", struct.pack(">II", 1, 0)) if animated else b""
    return signature + ihdr + animation + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b"")


valid_png = png(64, 40)
(OUT / "valid_flag.png").write_bytes(valid_png)
(OUT / "valid_icon.png").write_bytes(png(256, 256))
(OUT / "valid_cover.png").write_bytes(png(512, 512))
(OUT / "animated.png").write_bytes(png(64, 40, animated=True))
(OUT / "animated_icon.png").write_bytes(png(256, 256, animated=True))
(OUT / "oversized_header.png").write_bytes(
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", struct.pack(">IIBBBBB", 30000, 30000, 8, 2, 0, 0, 0))
    + valid_png[33:]
)
(OUT / "text_as_image.png").write_bytes(b"This is a web page, not a PNG.\n")

# MPEG-1 Layer III, 128 kb/s, 44.1 kHz; four contiguous synthetic frames.
frame = b"\xff\xfb\x90\x00" + bytes(413)
valid_mp3 = frame * 4
(OUT / "valid.mp3").write_bytes(valid_mp3)
(OUT / "truncated.mp3").write_bytes(frame[:37])
(OUT / "text_as_audio.mp3").write_bytes(b"<html>Save the actual MP3 file.</html>\n")
# ID3v2.3 APIC frame with a small body, followed by otherwise valid MP3 audio.
apic_body = b"\0image/png\0\x03\0not-picture-data"
apic_frame = b"APIC" + struct.pack(">I", len(apic_body)) + b"\0\0" + apic_body
id3 = b"ID3\x03\0\0" + bytes([0, 0, 0, len(apic_frame)]) + apic_frame
(OUT / "artwork.mp3").write_bytes(id3 + valid_mp3)

(OUT / "deep.json").write_text("[" * 70 + "0" + "]" * 70, encoding="utf-8")
(OUT / "invalid_utf8.json").write_bytes(b'{"name":"\xff"}')
(OUT / "nul_identity.json").write_text(
    json.dumps({"learnerProfileId": "bad\u0000id"}), encoding="utf-8"
)

with ZipFile(OUT / "unsafe_path.zip", "w", ZIP_DEFLATED) as archive:
    archive.writestr("../escape.txt", b"unsafe")
with ZipFile(OUT / "missing_manifest.zip", "w", ZIP_DEFLATED) as archive:
    archive.writestr("picture.png", valid_png)
with ZipFile(OUT / "animated_bank.zip", "w", ZIP_DEFLATED) as archive:
    archive.writestr(
        "image_bank_manifest.json",
        json.dumps(
            [{"id": "animated", "primary_term": "Animated", "keywords": ["animated"], "filename": "animated.png"}]
        ),
    )
    archive.writestr("animated.png", (OUT / "animated.png").read_bytes())
with ZipFile(OUT / "valid_bank.zip", "w", ZIP_DEFLATED) as archive:
    archive.writestr(
        "image_bank_manifest.json",
        json.dumps(
            [{"id": "valid", "primary_term": "Valid", "keywords": ["valid"], "filename": "valid_flag.png"}]
        ),
    )
    archive.writestr("valid_flag.png", valid_png)
