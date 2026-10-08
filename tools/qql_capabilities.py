"""The capability registry as the Python tools read it (Build 256 Revision 6).

`docs/capabilities_v12.json` is written by `dart run tools/export_capabilities.dart`
from `lib/models/canonical/` and pinned by
`test/capability_description_256_test.dart`; this module turns it into the
tables the generators and `validate_courses.py` use, so the Python side never
keeps a vocabulary of its own.

- PRIMITIVES: the nine primitive IDs in registry order.
- EVALUATION_MODES: primitive -> legal evaluation modes.
- OPTIONS: primitive -> option key -> spec (a list of legal values, `int`,
  `bool`, or the string "language").
- OPTION_ORDER: every option key in declaration order (JSON output order).
- DEFAULTS: primitive -> option key -> default value (absent when the
  option has no default).
"""
from __future__ import annotations

import json
from pathlib import Path

CAPABILITIES_PATH = Path(__file__).resolve().parents[1] / "docs" / "capabilities_v12.json"


def load(path: Path = CAPABILITIES_PATH) -> dict:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if data.get("formatVersion") != 12:
        raise ValueError(f"{path}: expected formatVersion 12")
    return data


def _spec(option: dict):
    kind = option["type"]
    if kind == "enumeration":
        return list(option["values"])
    if kind == "integer":
        return int
    if kind == "boolean":
        return bool
    if kind == "language":
        return "language"
    raise ValueError(f"unknown option type {kind!r}")


_DATA = load()
PRIMITIVES = [primitive["id"] for primitive in _DATA["primitives"]]
EVALUATION_MODES = {
    primitive["id"]: list(primitive["evaluationModes"]) for primitive in _DATA["primitives"]
}
OPTIONS = {
    primitive["id"]: {option["key"]: _spec(option) for option in primitive["options"]}
    for primitive in _DATA["primitives"]
}
DEFAULTS = {
    primitive["id"]: {
        option["key"]: option["default"]
        for option in primitive["options"]
        if option.get("default") is not None
    }
    for primitive in _DATA["primitives"]
}
OPTION_ORDER = list(_DATA["optionKeys"])
# Build 258: the Page attributes of prompt elements: key -> the element
# types it applies to, its legal values (or its "boolean" / "string" type)
# and the values allowed on text elements only.
ELEMENT_ATTRIBUTES = {
    attribute["key"]: {
        "types": set(attribute["elementTypes"]),
        "values": list(attribute.get("values", [])),
        "type": attribute.get("type"),
        "text_only": set(attribute.get("textOnlyValues", [])),
        # Build 265 Revision 11: the roles a text element needs to carry it.
        "text_roles": set(attribute.get("textRoles", [])),
    }
    for attribute in _DATA.get("elementAttributes", [])
}
