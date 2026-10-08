#!/usr/bin/env python3
"""Checks, offline, that tools/generate_world_flags.py would rebuild the
bundled language-related World Flags exactly.

Build 264 Revision 9: the generator had drifted from the bundle (five
language flags added by hand, ten pins and four sets of Flag Game colours
changed by hand), so regenerating would have dropped or altered them. This
check needs no download and no flag-icons checkout: for every language flag
the generator must take the bundled file (its SHA-1 matches the pin), build
the manifest entity exactly, list the same language suggestions and write
the same license notice. Run it after any change to the World Flags.
"""

from __future__ import annotations

import difflib
import importlib.util
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FLAGS = ROOT / "assets" / "world_flags"


def _no_network(*_: object, **__: object) -> None:
    raise RuntimeError("the check must not download anything")


def main() -> int:
    spec = importlib.util.spec_from_file_location(
        "generate_world_flags", ROOT / "tools" / "generate_world_flags.py"
    )
    generator = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(generator)
    urllib.request.urlopen = _no_network

    manifest = json.loads((FLAGS / "manifest.json").read_text(encoding="utf-8"))
    by_id = {entity["id"]: entity for entity in manifest["entities"]}
    issues: list[str] = []
    for flag in generator.LANGUAGE_RELATED:
        flag_id = str(flag["id"])
        try:
            data, svg = generator.read_language_asset(flag, None, FLAGS / "flags")
        except RuntimeError as error:
            issues.append(f"{flag_id}: the bundled file does not match its pin ({error})")
            continue
        built = generator.language_entity(flag, data, svg)
        for left, right in generator.BANNED_PAIRS:
            if flag_id == left:
                built["avoidAsDistractorWith"].append(right)
            if flag_id == right:
                built["avoidAsDistractorWith"].append(left)
        expected = by_id.get(flag_id)
        if built != expected:
            fields = sorted(
                key
                for key in set(built) | set(expected or {})
                if built.get(key) != (expected or {}).get(key)
            )
            issues.append(f"{flag_id}: the manifest entity differs in {', '.join(fields)}")
    bundled_ids = {
        entity["id"]
        for entity in manifest["entities"]
        if entity["category"] == "communityOrRegionalFlagAssociatedWithLanguage"
    }
    tool_ids = {str(flag["id"]) for flag in generator.LANGUAGE_RELATED}
    if tool_ids != bundled_ids:
        issues.append(
            "language flags only bundled: "
            f"{sorted(bundled_ids - tool_ids)}; only in the tool: {sorted(tool_ids - bundled_ids)}"
        )
    if list(generator.LANGUAGE_SUGGESTIONS) != manifest["languageSuggestions"]:
        issues.append("the language suggestions differ from the manifest's")
    notice = generator.language_license_notice()
    bundled_notice = (FLAGS / "LICENSE-language-related-flags.md").read_text(encoding="utf-8")
    if notice != bundled_notice:
        diff = difflib.unified_diff(
            bundled_notice.splitlines(), notice.splitlines(), "bundled", "tool", n=0, lineterm=""
        )
        issues.append("the license notice differs:\n" + "\n".join(diff))
    print(
        f"World Flags generator: {len(tool_ids)} language flags checked offline; "
        f"{len(issues)} issue(s)"
    )
    for issue in issues:
        print(f"  - {issue}")
    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
