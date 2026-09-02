#!/usr/bin/env python3
"""Generate the additive QQL world-flag manifest and verified assets.

The ISO Online Browsing Platform is the authority. RIPE NCC publishes a
machine-readable HTML table using the ISO 3166-1 names/codes and states that it
updates the table whenever ISO 3166/MA changes the official list. Artwork is
copied from a pinned checkout of lipis/flag-icons v7.5.0 (MIT). The approved
language-related community/regional flags are fetched from individually pinned
Wikimedia Commons files with their hashes, authors and licenses recorded.
"""

from __future__ import annotations

import argparse
import colorsys
import hashlib
import html
import json
import re
import shutil
import urllib.request
from pathlib import Path


RIPE_ISO_URL = (
    "https://www.ripe.net/community/internet-governance/"
    "internet-technical-community/the-rir-system/list-of-country-codes-and-rirs/"
)
ISO_AUTHORITY_URL = "https://www.iso.org/obp/ui/#iso:code:3166"
UN_AUTHORITY_URL = "https://www.un.org/en/about-us/member-states"
FLAG_SOURCE_URL = "https://github.com/lipis/flag-icons/tree/v7.5.0"
MARKER_STAR_ALPHA2 = frozenset({"US", "UM"})
US_STAR_PATH = "m14 0 9 27L0 10h28L5 27z"
US_STAR_ROWS = (
    (11, (16, 77, 138, 199, 260, 320)),
    (37, (47, 108, 169, 229, 290)),
    (63, (16, 77, 138, 199, 260, 320)),
    (89, (47, 108, 169, 229, 290)),
    (115, (16, 77, 138, 199, 260, 320)),
    (141, (47, 108, 169, 229, 290)),
    (166, (16, 77, 138, 199, 260, 320)),
    (192, (47, 108, 169, 229, 290)),
    (218, (16, 77, 138, 199, 260, 320)),
)

# ISO 3166-1 entities that are not UN Member States. The complement of this
# set in the current 249-entry ISO list is the authoritative 193-member pool.
NON_UN_ISO_ALPHA2 = frozenset(
    """
    AX AS AI AQ AW BM BQ BV IO VG KY CX CC CK CW FK FO GF PF TF GI GL GP GU
    GG HM HK IM JE MO MQ YT MS NC NU NF MP PN PR RE BL SH MF PM SX SJ GS TW
    TK TC UM VI WF EH PS VA
    """.split()
)

DISPLAY_OVERRIDES = {
    "BO": "Bolivia",
    "BN": "Brunei",
    "CD": "Democratic Republic of the Congo",
    "CG": "Republic of the Congo",
    "CI": "Côte d'Ivoire",
    "FK": "Falkland Islands",
    "FM": "Micronesia",
    "GB": "United Kingdom",
    "IR": "Iran",
    "KP": "North Korea",
    "KR": "South Korea",
    "LA": "Laos",
    "MD": "Moldova",
    "NL": "Netherlands",
    "PS": "Palestine",
    "RU": "Russia",
    "SY": "Syria",
    "TW": "Taiwan",
    "TZ": "Tanzania",
    "US": "United States",
    "VA": "Vatican City",
    "VE": "Venezuela",
    "VG": "British Virgin Islands",
    "VI": "U.S. Virgin Islands",
}

SHORTLIST = (
    ("england", "England", "gb-eng", "shortlist", "GB-ENG"),
    ("scotland", "Scotland", "gb-sct", "shortlist", "GB-SCT"),
    ("wales", "Wales", "gb-wls", "shortlist", "GB-WLS"),
    ("kosovo", "Kosovo", "xk", "shortlist", None),
    ("northern_ireland", "Northern Ireland", "gb-nir", "shortlist", "GB-NIR"),
    ("catalonia", "Catalonia", "es-ct", "shortlist", None),
    ("basque_country", "Basque Country", "es-pv", "shortlist", None),
    ("galicia", "Galicia", "es-ga", "shortlist", None),
)

LANGUAGE_RELATED = (
    {
        "id": "sami",
        "name": "Sámi",
        "aliases": ["Sami", "Saami", "Sápmi"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/1/1b/Sami_flag.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Sami_flag.svg",
        "sha1": "e07bb487ff14695b91fd76a81eb1f697cc4e1049",
        "license": "Public domain",
        "author": "Jeltz",
    },
    {
        "id": "roma",
        "name": "Roma",
        "aliases": ["Romani"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/1/10/Flag_of_the_Romani_people.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Flag_of_the_Romani_people.svg",
        "sha1": "912077276e66dbde9017a01542bff5cf4588f93c",
        "license": "Public domain",
        "author": "AdiJapan",
    },
    {
        "id": "sorbian",
        "name": "Sorbian",
        "aliases": ["Sorbs", "Lusatian Sorbs"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/c/c0/Flag_of_Sorbs.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Flag_of_Sorbs.svg",
        "sha1": "d2ba8008939d77e6d2a2b586cc1b8de905299709",
        "license": "Public domain",
        "author": "Mysid",
    },
    {
        "id": "breton",
        "name": "Breton",
        "aliases": ["Brittany", "Gwenn-ha-du"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/2/29/Flag_of_Brittany_%28Gwenn_ha_du%29.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Flag_of_Brittany_(Gwenn_ha_du).svg",
        "sha1": "74396a0634b69885126907fb21edb6c1c998ad79",
        "license": "Public domain",
        "author": "Gryffindor",
    },
    {
        "id": "corsican",
        "name": "Corsican",
        "aliases": ["Corsica"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/7/7c/Flag_of_Corsica.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Flag_of_Corsica.svg",
        "sha1": "10f049eb79b7a8fa9b79547ea0961c876e4a32a1",
        "license": "CC0 1.0",
        "author": "Patricia.fidi",
    },
    {
        "id": "occitan",
        "name": "Occitan",
        "aliases": ["Occitania"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/4/45/Flag_of_Occitania.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Flag_of_Occitania.svg",
        "sha1": "99aca283b853ad17c2da2a7384561e7bf551f6d2",
        "license": "Public domain",
        "author": "Nimlar",
    },
    {
        "id": "cornish",
        "name": "Cornish",
        "aliases": ["Cornwall", "Saint Piran's Flag"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/b/b8/Flag_of_Cornwall.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Flag_of_Cornwall.svg",
        "sha1": "013c1beccfadde20546eb86aba7ffa2fd9dcf599",
        "license": "Public domain",
        "author": "Jon Harald Søby",
    },
    {
        "id": "friulian",
        "name": "Friulian",
        "aliases": ["Friuli"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/e/eb/Friuli_Flag.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Friuli_Flag.svg",
        "sha1": "81613fb7063b738b2f1fdd2200be7f36189deee5",
        "license": "CC BY-SA 3.0",
        "author": "Ipankonin",
    },
    {
        "id": "sardinian",
        "name": "Sardinian",
        "aliases": ["Sardinia"],
        "url": "https://upload.wikimedia.org/wikipedia/commons/4/4e/Flag_of_Sardinia%2C_Italy.svg",
        "sourcePage": "https://commons.wikimedia.org/wiki/File:Flag_of_Sardinia,_Italy.svg",
        "sha1": "593068e1d9b8b1a96010d21ee2be2ba2483a15e9",
        "license": "CC BY-SA 3.0",
        "author": "Angelus",
    },
)

BANNED_PAIRS = (
    ("romania", "chad"),
    ("monaco", "indonesia"),
    ("ireland", "cote_d_ivoire"),
    ("mali", "guinea"),
    ("netherlands", "luxembourg"),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--flag-icons", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("assets/world_flags"))
    parser.add_argument("--iso-html", type=Path)
    parser.add_argument(
        "--language-flags",
        type=Path,
        help="Optional cache containing <id>.svg for the pinned Wikimedia assets",
    )
    return parser.parse_args()


def read_iso_html(snapshot: Path | None) -> str:
    if snapshot is not None:
        return snapshot.read_text(encoding="utf-8")
    request = urllib.request.Request(
        RIPE_ISO_URL,
        headers={"User-Agent": "QuisquisLingo world-flag dataset generator"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


def strip_markup(value: str) -> str:
    value = re.sub(r"<[^>]+>", "", value)
    return html.unescape(value).replace("\xa0", " ").strip()


def parse_iso_rows(raw: str) -> list[dict[str, str]]:
    body_match = re.search(r"<tbody>(.*?)</tbody>", raw, re.S | re.I)
    if not body_match:
        raise RuntimeError("RIPE ISO table body not found")
    rows = []
    for row in re.findall(r"<tr>(.*?)</tr>", body_match.group(1), re.S | re.I):
        cells = [strip_markup(value) for value in re.findall(r"<td>(.*?)</td>", row, re.S | re.I)]
        if len(cells) != 4:
            continue
        name, alpha2, alpha3, region = cells
        if re.fullmatch(r"[A-Z]{2}", alpha2) and re.fullmatch(r"[A-Z]{3}", alpha3):
            rows.append({"name": name, "alpha2": alpha2, "alpha3": alpha3, "region": region})
    if len(rows) != 249:
        raise RuntimeError(f"Expected 249 ISO rows, found {len(rows)}")
    return rows


def english_name(row: dict[str, str]) -> str:
    code = row["alpha2"]
    if code in DISPLAY_OVERRIDES:
        return DISPLAY_OVERRIDES[code]
    words = row["name"].lower().split()
    small = {"and", "of", "the"}
    rendered = []
    for index, word in enumerate(words):
        rendered.append(word if index and word in small else word[:1].upper() + word[1:])
    return " ".join(rendered).replace("D'", "d'")


def slug(name: str) -> str:
    normalized = name.lower().replace("côte", "cote").replace("å", "a")
    return re.sub(r"[^a-z0-9]+", "_", normalized).strip("_")


def color_tags(svg: str) -> list[str]:
    colors = re.findall(r"#[0-9a-fA-F]{3,8}\b", svg)
    tags = set()
    for raw in colors:
        value = raw[1:]
        if len(value) in (3, 4):
            value = "".join(char * 2 for char in value[:3])
        if len(value) < 6:
            continue
        r, g, b = (int(value[index : index + 2], 16) / 255 for index in (0, 2, 4))
        hue, saturation, lightness = colorsys.rgb_to_hls(r, g, b)
        if lightness >= 0.85 and saturation <= 0.25:
            tags.add("color:white")
        elif lightness <= 0.18:
            tags.add("color:black")
        elif saturation <= 0.18:
            tags.add("color:gray")
        else:
            degrees = hue * 360
            if degrees < 18 or degrees >= 345:
                tags.add("color:red")
            elif degrees < 55:
                tags.add("color:orange")
            elif degrees < 75:
                tags.add("color:yellow")
            elif degrees < 165:
                tags.add("color:green")
            elif degrees < 255:
                tags.add("color:blue")
            elif degrees < 300:
                tags.add("color:purple")
            else:
                tags.add("color:red")
    return sorted(tags)


def read_language_asset(spec: dict[str, object], cache: Path | None) -> tuple[bytes, str]:
    entity_id = str(spec["id"])
    if cache is not None:
        data = (cache.resolve() / f"{entity_id}.svg").read_bytes()
    else:
        request = urllib.request.Request(
            str(spec["url"]),
            headers={"User-Agent": "QuisquisLingo world-flag dataset generator"},
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read()
    digest = hashlib.sha1(data).hexdigest()
    if digest != spec["sha1"]:
        raise RuntimeError(
            f"Unexpected SHA-1 for {entity_id}: expected {spec['sha1']}, found {digest}"
        )
    svg = data.decode("utf-8-sig")
    unsafe_patterns = (
        r"<script\b",
        r"<foreignObject\b",
        r"\bon\w+\s*=",
        r"(?:href|src)\s*=\s*['\"]https?://",
    )
    if "<svg" not in svg or any(re.search(pattern, svg, re.I) for pattern in unsafe_patterns):
        raise RuntimeError(f"Unsafe or invalid SVG markup for {entity_id}")
    return data, svg


def language_license_notice() -> str:
    lines = [
        "# Language-related flag artwork provenance",
        "",
        "These nine SVGs are sourced from Wikimedia Commons and are separate from",
        "the MIT-licensed `lipis/flag-icons` collection. They depict community or",
        "regional flags associated with languages; QQL does not claim that they are",
        "universally official language flags.",
        "",
        "Each downloaded file is pinned by the SHA-1 shown below. Public-domain and",
        "CC0 status, or CC BY-SA attribution terms, are declared on the linked Commons",
        "file-description page.",
        "",
    ]
    license_urls = {
        "CC0 1.0": "https://creativecommons.org/publicdomain/zero/1.0/",
        "CC BY-SA 3.0": "https://creativecommons.org/licenses/by-sa/3.0/",
    }
    for spec in LANGUAGE_RELATED:
        license_name = str(spec["license"])
        license_link = license_urls.get(license_name)
        rendered_license = (
            f"[{license_name}]({license_link})" if license_link else license_name
        )
        lines.extend(
            [
                f"- **{spec['name']}** (`{spec['id']}.svg`) — {rendered_license}; "
                f"author: {spec['author']}; [source page]({spec['sourcePage']}); "
                f"SHA-1 `{spec['sha1']}`.",
            ]
        )
    lines.extend(
        [
            "",
            "The Wikimedia Commons site text and metadata have their own terms; this",
            "notice records only the license declared for each redistributed SVG.",
            "",
        ]
    )
    return "\n".join(lines)


def renderer_compatible_marker_stars(svg: str, alpha2: str) -> str:
    """Expand the two flag-icons star markers unsupported by flutter_svg."""
    marker_id = alpha2.lower() + "-a"
    marker_block = re.compile(
        rf'  <marker id="{marker_id}" markerHeight="30" markerWidth="30">\r?\n'
        rf'    <path fill="#fff" d="{US_STAR_PATH}"/>\r?\n'
        rf'  </marker>\r?\n'
        rf'  <path fill="none" marker-mid="url\(#{marker_id}\)"[^>]*/>'
    )
    stars = [
        f'    <path d="{US_STAR_PATH}" transform="translate({x} {y})"/>'
        for y, row in US_STAR_ROWS
        for x in row
    ]
    replacement = '  <g fill="#fff">\n' + "\n".join(stars) + "\n  </g>"
    rendered, substitutions = marker_block.subn(replacement, svg)
    if substitutions != 1 or len(stars) != 50:
        raise RuntimeError(f"Could not normalize star markers for {alpha2}")
    return rendered


def main() -> None:
    args = parse_args()
    flag_root = args.flag_icons.resolve()
    source_flags = flag_root / "flags" / "4x3"
    license_file = flag_root / "LICENSE"
    if not source_flags.is_dir() or not license_file.is_file():
        raise RuntimeError("flag-icons checkout is missing flags/4x3 or LICENSE")

    rows = parse_iso_rows(read_iso_html(args.iso_html))
    if len({row["alpha2"] for row in rows}) != 249:
        raise RuntimeError("ISO alpha-2 values are not unique")
    if len(set(NON_UN_ISO_ALPHA2) & {row["alpha2"] for row in rows}) != 56:
        raise RuntimeError("Non-UN ISO complement does not match current ISO data")

    output = args.output.resolve()
    flags_output = output / "flags"
    flags_output.mkdir(parents=True, exist_ok=True)
    for existing in flags_output.glob("*.svg"):
        existing.unlink()

    entities = []
    id_by_alpha2 = {}
    for row in rows:
        display_name = english_name(row)
        entity_id = slug(display_name)
        source = source_flags / f"{row['alpha2'].lower()}.svg"
        if not source.is_file():
            raise RuntimeError(f"Missing flag-icons asset for {row['alpha2']}")
        destination = flags_output / f"{entity_id}.svg"
        if row["alpha2"] in MARKER_STAR_ALPHA2:
            destination.write_text(
                renderer_compatible_marker_stars(
                    source.read_text(encoding="utf-8"), row["alpha2"]
                ),
                encoding="utf-8",
            )
        else:
            shutil.copyfile(source, destination)
        id_by_alpha2[row["alpha2"]] = entity_id
        aliases = [] if row["name"].casefold() == display_name.casefold() else [row["name"].title()]
        entities.append(
            {
                "id": entity_id,
                "displayNameEn": display_name,
                "assetPath": f"assets/world_flags/flags/{entity_id}.svg",
                "isoAlpha2": row["alpha2"],
                "isoAlpha3": row["alpha3"],
                "category": "unMember" if row["alpha2"] not in NON_UN_ISO_ALPHA2 else "isoExtra",
                "aliases": aliases,
                "distractorTags": sorted(set(color_tags(source.read_text(encoding="utf-8"))) | {f"rir:{row['region'].lower().replace(' ', '_')}"}),
                "avoidAsDistractorWith": [],
            }
        )

    for entity_id, name, source_code, category, subdivision in SHORTLIST:
        source = source_flags / f"{source_code}.svg"
        if not source.is_file():
            raise RuntimeError(f"Missing extra flag-icons asset {source_code}.svg")
        destination = flags_output / f"{entity_id}.svg"
        shutil.copyfile(source, destination)
        entity = {
            "id": entity_id,
            "displayNameEn": name,
            "assetPath": f"assets/world_flags/flags/{entity_id}.svg",
            "category": category,
            "aliases": [],
            "distractorTags": sorted(set(color_tags(source.read_text(encoding="utf-8"))) | {"region:europe"}),
            "avoidAsDistractorWith": [],
        }
        if subdivision is not None:
            entity["subdivisionCode"] = subdivision
        entities.append(entity)

    for spec in LANGUAGE_RELATED:
        data, svg = read_language_asset(spec, args.language_flags)
        entity_id = str(spec["id"])
        destination = flags_output / f"{entity_id}.svg"
        destination.write_bytes(data)
        entities.append(
            {
                "id": entity_id,
                "displayNameEn": spec["name"],
                "assetPath": f"assets/world_flags/flags/{entity_id}.svg",
                "category": "communityOrRegionalFlagAssociatedWithLanguage",
                "aliases": spec["aliases"],
                "artworkSourcePage": spec["sourcePage"],
                "artworkLicense": spec["license"],
                "artworkAuthor": spec["author"],
                "artworkSha1": spec["sha1"],
                "distractorTags": sorted(set(color_tags(svg)) | {"region:europe"}),
                "avoidAsDistractorWith": [],
            }
        )

    by_id = {entity["id"]: entity for entity in entities}
    if len(by_id) != len(entities):
        raise RuntimeError("World flag entity IDs are not unique")
    names = [entity["displayNameEn"].casefold() for entity in entities]
    if len(set(names)) != len(names):
        raise RuntimeError("World flag English display names are not unique")
    for left, right in BANNED_PAIRS:
        if left not in by_id or right not in by_id:
            raise RuntimeError(f"Unknown banned distractor pair: {left}, {right}")
        by_id[left]["avoidAsDistractorWith"].append(right)
        by_id[right]["avoidAsDistractorWith"].append(left)

    entities.sort(key=lambda entity: entity["displayNameEn"].casefold())
    manifest = {
        "schemaVersion": 1,
        "generatedAt": "2026-09-02",
        "sources": {
            "isoAuthority": ISO_AUTHORITY_URL,
            "isoMachineReadableCrossCheck": RIPE_ISO_URL,
            "unMembers": UN_AUTHORITY_URL,
            "artwork": FLAG_SOURCE_URL,
            "artworkLicense": "MIT",
            "languageRelatedArtwork": "Wikimedia Commons file pages recorded per entity",
            "languageRelatedLicenseNotice": "assets/world_flags/LICENSE-language-related-flags.md",
        },
        "counts": {
            "entities": len(entities),
            "iso": sum("isoAlpha2" in entity for entity in entities),
            "unMembers": sum(entity["category"] == "unMember" for entity in entities),
            "isoExtras": sum(entity["category"] == "isoExtra" for entity in entities),
            "shortlist": sum(entity["category"] == "shortlist" for entity in entities),
            "languageRelatedFlags": sum(
                entity["category"]
                == "communityOrRegionalFlagAssociatedWithLanguage"
                for entity in entities
            ),
        },
        "entities": entities,
    }
    output.mkdir(parents=True, exist_ok=True)
    manifest_path = output / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    shutil.copyfile(license_file, output / "LICENSE-flag-icons.txt")
    (output / "LICENSE-language-related-flags.md").write_text(
        language_license_notice(), encoding="utf-8"
    )
    digest = hashlib.sha256(manifest_path.read_bytes()).hexdigest()
    print(json.dumps({"counts": manifest["counts"], "manifestSha256": digest}, indent=2))


if __name__ == "__main__":
    main()
