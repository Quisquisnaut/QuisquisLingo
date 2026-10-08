#!/usr/bin/env python3
"""Give light pictures a soft grey edge so they stay visible on a white page.

Owner decision of 5 October 2026 (Build 264 Revision 4, option B2): a grey
ring is drawn just outside a picture only where its edge is light; coloured
parts of the edge get nothing. `tools/validate_images.py` refuses a picture
whose outer edge is mostly near-white (`edge_white_share` >= 0.5).

Usage:
  python tools/outline_light_edges.py FILE.webp ...   outline new pictures
                                                      (near-white edge >= 25%)
  python tools/outline_light_edges.py --catalog       outline the bundled
                                                      pictures the validator
                                                      refuses (edge >= 50%)
Add --dry-run to list what would change. Files are rewritten in place as
256 x 256 WebP within 50 KiB: lossless when the original was lossless and
the result fits, otherwise lossy from quality 92 down.
"""

from __future__ import annotations

import argparse
import io
import json
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageFilter, ImageStat
except ImportError:
    print("Pillow is required: python -m pip install Pillow", file=sys.stderr)
    raise SystemExit(2)

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets" / "exercise_images" / "metadata_v2.json"
MAX_BYTES = 50 * 1024
# The validator's limit: at this share of near-white edge a picture is lost
# on a white page.
EDGE_WHITE_LIMIT = 0.5
# This tool outlines from a lower share, so pictures that are partly lost
# are helped too (230 pictures in Build 264 Revision 4).
OUTLINE_FROM = 0.25
OUTLINE_COLOR = (150, 160, 168)
OUTLINE_WIDTH = 3


def edge_white_share(image: Image.Image) -> float:
    """The share of the figure's 1-pixel outer edge (alpha >= 128) that is
    near-white (luminance > 225)."""
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    if alpha.getbbox() is None:
        return 0.0
    edge = ImageChops.subtract(alpha, alpha.filter(ImageFilter.MinFilter(3)))
    edge_pixels = ImageStat.Stat(edge).sum[0] / 255
    if edge_pixels == 0:
        return 0.0
    light = rgba.convert("L").point(lambda v: 255 if v > 225 else 0)
    light_edge = ImageStat.Stat(ImageChops.multiply(edge, light)).sum[0] / 255
    return light_edge / edge_pixels


def outline_light_edges(image: Image.Image) -> Image.Image:
    """The picture with a soft grey ring outside its light edge parts."""
    rgba = image.convert("RGBA")
    width = OUTLINE_WIDTH
    alpha = rgba.getchannel("A").point(lambda v: 255 if v >= 100 else 0)
    ring = ImageChops.subtract(alpha.filter(ImageFilter.MaxFilter(width * 2 + 1)), alpha)
    light = ImageChops.multiply(
        rgba.convert("L").point(lambda v: 255 if v > 215 else 0), alpha
    )
    near_light = light.filter(ImageFilter.MaxFilter(width * 2 + 3)).filter(
        ImageFilter.GaussianBlur(1.2)
    )
    mask = ImageChops.multiply(ring, near_light).filter(ImageFilter.GaussianBlur(0.7))
    layer = Image.new("RGBA", rgba.size, OUTLINE_COLOR + (0,))
    layer.putalpha(mask.point(lambda v: v * 215 // 255))
    result = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
    result.alpha_composite(layer)
    result.alpha_composite(rgba)
    return result


def encode(image: Image.Image, lossless: bool) -> bytes:
    if lossless:
        buffer = io.BytesIO()
        image.save(buffer, "WEBP", lossless=True, quality=100, method=6, exact=False)
        if buffer.tell() <= MAX_BYTES:
            return buffer.getvalue()
    for quality in (92, 90, 88, 85, 80):
        buffer = io.BytesIO()
        image.save(buffer, "WEBP", quality=quality, method=6, alpha_quality=100)
        if buffer.tell() <= MAX_BYTES:
            return buffer.getvalue()
    raise ValueError("the outlined picture does not fit 50 KiB")


def is_lossless(path: Path) -> bool:
    with path.open("rb") as file:
        return b"VP8L" in file.read(64)


def catalog_paths() -> list[Path]:
    records = json.loads(CATALOG.read_text(encoding="utf-8"))["records"]
    return [
        ROOT / record["assetPath"]
        for record in records
        if record["assetPath"].endswith(".webp")
        # Character pictures may be opaque tiles; they keep their look.
        and not record["category"].startswith("characters_")
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("files", nargs="*", type=Path)
    parser.add_argument("--catalog", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    arguments = parser.parse_args()
    paths = catalog_paths() if arguments.catalog else arguments.files
    # The catalog was outlined from 25% once (Build 264 Revision 4); running
    # it again must not draw a second ring, so it only fixes what the
    # validator refuses.
    outline_from = EDGE_WHITE_LIMIT if arguments.catalog else OUTLINE_FROM
    if not paths:
        parser.error("name WebP files or pass --catalog")
    changed = 0
    for path in paths:
        with Image.open(path) as opened:
            image = opened.convert("RGBA")
        share = edge_white_share(image)
        if share < outline_from:
            continue
        data = encode(outline_light_edges(image), is_lossless(path))
        after = edge_white_share(Image.open(io.BytesIO(data)))
        print(f"{path.name}: near-white edge {share:.0%} -> {after:.0%}")
        if after >= EDGE_WHITE_LIMIT:
            print(f"  still mostly near-white: redraw {path.name}", file=sys.stderr)
        if not arguments.dry_run:
            path.write_bytes(data)
        changed += 1
    print(f"{changed} picture(s) {'to outline' if arguments.dry_run else 'outlined'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
