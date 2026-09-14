#!/usr/bin/env python3
"""Build the clean-cut English exercise-image metadata catalog.

The QQL 234 manifest is used only as the reviewed development inventory. The
generated v2 catalog is the sole runtime metadata source; the application does
not read or migrate the older manifests or preference namespaces.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "exercise_images" / "manifest.json"
OUTPUT = ROOT / "assets" / "exercise_images" / "metadata_v2.json"

# Most reviewed QQL 234 entries put two English tags first. These explicit
# exceptions select the English terms where the older bilingual ordering did
# not follow that convention. This is curated build-time input, not language
# detection or runtime migration.
TAG_INDICES: dict[str, tuple[int, ...]] = {
    "bread": (0, 2),
    "apple": (0, 2),
    "cat": (0, 2),
    "coffee": (0, 2),
    "train": (0, 2),
    "tree": (0, 2),
    "body_parts_ear": (0, 2),
    "body_parts_eye": (0, 2),
    "body_parts_nose": (0, 2),
    "body_parts_mouth": (0, 2),
    "body_parts_hand": (0, 2),
    "body_parts_foot": (0, 2),
    "clothing_accessories_dress": (0,),
    "clothing_accessories_jacket": (0,),
    "clothing_accessories_shoes": (0,),
    "clothing_accessories_hat": (0,),
    "clothing_accessories_scarf": (0,),
    "clothing_accessories_shorts": (0,),
    "clothing_accessories_socks": (0,),
    "clothing_accessories_necklace": (0,),
    "clothing_accessories_wallet": (0,),
    "food_drinks_soup": (0,),
    "animals_bird": (0,),
    "home_household_pot": (0,),
}

TAG_OVERRIDES: dict[str, list[str]] = {
    "people_family_man": ["man", "adult man", "male", "friend"],
    "people_family_woman": ["woman", "adult woman", "female", "friend"],
    "actions_jump": ["jump", "jumping", "leap"],
}


def generate() -> str:
    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    if not isinstance(source, list) or len(source) != 111:
        raise ValueError("Expected the reviewed 111-image QQL 234 inventory")
    records: list[dict[str, object]] = []
    for entry in source:
        if not isinstance(entry, dict):
            raise ValueError("Image inventory entries must be objects")
        image_id = str(entry["id"])
        old_tags = [str(value) for value in entry.get("tags", [])]
        tags = TAG_OVERRIDES.get(image_id)
        if tags is None:
            indices = TAG_INDICES.get(image_id, (0, 1))
            try:
                tags = [old_tags[index] for index in indices]
            except IndexError as error:
                raise ValueError(f"{image_id}: reviewed English tag index missing") from error
        records.append(
            {
                "id": image_id,
                "label": str(entry["label"]),
                "category": str(entry["category"]),
                "tags": tags,
                "assetPath": str(entry["assetPath"]),
                "origin": "bundled",
            }
        )
    return json.dumps(
        {"schemaVersion": 1, "records": records},
        ensure_ascii=False,
        indent=2,
    ) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    rendered = generate()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != rendered:
            raise SystemExit("metadata_v2.json differs from deterministic output")
        print("metadata_v2.json: verified")
        return 0
    OUTPUT.write_text(rendered, encoding="utf-8", newline="\n")
    print(f"metadata_v2.json: generated {len(json.loads(rendered)['records'])} records")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
