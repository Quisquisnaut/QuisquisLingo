"""Course Model v12 (Build 256) helpers shared by the bundled-Course generators
and tools/validate_courses.py.

`convert_course_v11_to_v12` mirrors `Exercise.convertV11` and the converter
library in lib/ (`lib/models/course_models.dart`,
`lib/services/course_model_v12_converter.dart`) rule for rule, so a Course a
generator builds in the v11 shape becomes the same v12 Course the Dart tool
would produce; `test/course_model_v12_256_test.dart` proves the two agree on
the bundled Courses. The vocabularies below are the registry's
(`lib/models/canonical/`); Session 5 replaces them with the generated
capability description.
"""
from __future__ import annotations

import copy
import re

# The exercise vocabulary comes from docs/capabilities_v12.json, written by
# `dart run tools/export_capabilities.dart` from the Dart registry (Build 256
# Revision 6): primitives, evaluation modes per primitive, option specs per
# primitive and the option declaration order that decides the JSON output order.
from qql_capabilities import EVALUATION_MODES, OPTION_ORDER, OPTIONS, PRIMITIVES  # noqa: E402,F401

EVALUATION_KEYS = ["mode", "correctItemIds", "assignments", "answers",
                   "literalAnswers", "targetAnswers", "numeric", "pattern",
                   "correctOrders", "relations", "acceptedTargets"]

CONTENT_KINDS = {"exercise", "explanation", "example", "vocabulary", "text",
                 "image", "audio", "dialogue"}

LEGACY_TYPE = {
    "choose_answer": "choice", "choose_picture": "icon_choice",
    "what_do_you_hear": "listening_choice", "build_sentence": "word_order",
    "build_word": "image_word", "match_words": "word_match",
    "match_sounds": "audio_match", "flashcard": "flashcard",
    "explanation": "flashcard", "example": "flashcard",
    "vocabulary": "flashcard", "text": "flashcard", "dialogue": "flashcard",
}
KIND_TYPE = {"select": "choice", "input": "fill_blank", "arrange": "word_order",
             "match": "matching", "presentation": "flashcard"}


# The older recipe a Build 256 Revision 4 catalogue preset is built on
# (mirrors lib/models/preset_successors.dart, presetRecipeBaseOf).
PRESET_BASE = {
    "choice_target": "choice",
    "choice_source": "choice",
    "listening_choose_target": "listening_choice",
    "listening_choose_source": "listening_choice",
    "listening_answer_target": "listening_comprehension",
    "listening_answer_source": "listening_comprehension",
    "reading_answer_target": "reading_comprehension",
    "type_translation_to_target": "type_translation",
    "type_translation_to_source": "type_translation",
    "build_translation_to_target": "build_translation",
    "build_translation_to_source": "build_translation",
    "picture_flashcard": "flashcard",
    "true_false": "choice",
    "one_word_fills_all": "gap_choice",
    "complete_text": "missing_word",
    "missing_letters": "missing_word",
    "gap_blocks": "word_order",
    "sentence_order": "word_order",
    "picture_blocks": "word_order",
    "listening_image_choice": "icon_choice",
    "spell_heard": "image_word",
    "picture_choice": "choice",
    "picture_name": "fill_blank",
    "spell_word": "image_word",
    "picture_word_match": "word_match",
    "note_card": "flashcard",
}


def legacy_type(template: str, kind: str) -> str:
    if template in LEGACY_TYPE:
        return LEGACY_TYPE[template]
    if template in PRESET_BASE:
        return PRESET_BASE[template]
    if template:
        return template
    return KIND_TYPE.get(kind, kind)


def _ordered_options(options: dict) -> dict:
    return {key: options[key] for key in OPTION_ORDER if key in options}


def _ordered_evaluation(evaluation: dict) -> dict:
    return {key: evaluation[key] for key in EVALUATION_KEYS if key in evaluation}


def _with_audio(elements: list, playback: str) -> list:
    return [dict(e, playback=playback) if e.get("type") == "audio" else e
            for e in elements]


def _with_text_language(elements: list, role: str, language: str) -> list:
    # A language the element states wins over the one the preset implies.
    return [dict(e, language=language)
            if e.get("type") == "text" and e.get("role", "primary") == role and "language" not in e else e
            for e in elements]


def _with_item_language(items: list, language: str) -> list:
    return [dict(item, content=[
        dict(e, language=language)
        if e.get("type") == "text" and e.get("role", "primary") == "primary" and "language" not in e else e
        for e in item.get("content", [])
    ]) for item in items]


def _primary_text(elements: list) -> str | None:
    for element in elements:
        if element.get("type") == "text" and element.get("role", "primary") == "primary":
            return element.get("text", "")
    return None


def _without_primary_text(elements: list) -> list:
    out, removed = [], False
    for element in elements:
        if (not removed and element.get("type") == "text"
                and element.get("role", "primary") == "primary"):
            removed = True
            continue
        out.append(element)
    return out


def _missing_word_layout(transcript: str, words: list[str]) -> list | None:
    if not words:
        return None
    out, cursor, lower = [], 0, transcript.lower()
    for i, raw in enumerate(words):
        word = raw.strip()
        if not word:
            return None
        index = lower.find(word.lower(), cursor)
        if index < 0:
            return None
        if index > cursor:
            out.append({"type": "text", "text": transcript[cursor:index]})
        out.append({"type": "target", "targetId": f"gap_{i + 1}"})
        cursor = index + len(word)
    if cursor < len(transcript):
        out.append({"type": "text", "text": transcript[cursor:]})
    return out


def presentation_to_exercise(presentation: dict, updated_at: str) -> dict:
    actions = presentation.get("completion", {}).get("actions", ["understood", "review_later"])
    if "understood" in actions or "review_later" in actions:
        mode = "understoodReview"
    elif not actions:
        mode = "automatic"
    elif "acknowledge" in actions:
        mode = "acknowledge"
    else:
        mode = "continue"
    exercise = {"updatedAt": updated_at, "primitive": "presentation"}
    if mode != "continue":
        exercise["options"] = {"completionMode": mode}
    exercise["prompt"] = copy.deepcopy(presentation.get("content", []))
    exercise["evaluation"] = {"mode": "none"}
    return exercise


def convert_exercise(preset: str, exercise: dict, missing_words: list[str] | None = None) -> dict:
    """The v12 exercise for a v11 exercise object (`prompt`, `interaction`,
    `evaluation`, `hint`, `feedback`, `missingWords`)."""
    exercise = copy.deepcopy(exercise)
    interaction = exercise["interaction"]
    evaluation = exercise["evaluation"]
    kind = interaction["kind"]
    type_ = legacy_type(preset, kind)
    prompt = list(exercise.get("prompt", []))
    items = list(interaction.get("items", []))
    v11_layout = interaction.get("layout", [])
    gaps = [e["text"] for e in v11_layout if e.get("type") == "gap"]
    missing = list(missing_words if missing_words is not None else exercise.get("missingWords", []))
    options: dict = {}
    targets: list = []
    layout: list = []
    feedback = {}
    raw_feedback = exercise.get("feedback") or {}
    if raw_feedback.get("correct"):
        feedback["correct"] = raw_feedback["correct"]
    if raw_feedback.get("incorrect"):
        feedback["incorrect"] = raw_feedback["incorrect"]

    def layout_of() -> list:
        return [{"type": "target", "targetId": e["text"]} if e.get("type") == "gap"
                else {"type": "text", "text": e.get("text", "")} for e in v11_layout]

    def assignments_of() -> list:
        gap_assignments = evaluation.get("gapAssignments", {})
        return [{"targetId": gap, "itemIds": [gap_assignments[gap]]}
                for gap in gaps if gap in gap_assignments]

    if type_ == "flashcard" or kind == "presentation":
        primitive = "presentation"
        options["completionMode"] = "understoodReview"
        usage = [next((e.get("text", "") for e in item.get("content", []) if e.get("type") == "text"), "")
                 for item in items]
        new_prompt = []
        for element in prompt:
            if element.get("type") == "text" and element.get("role", "primary") != "question":
                new_prompt.append(dict(element, role="term"))
            elif element.get("type") == "text":
                new_prompt.append(dict(element, role="meaning"))
            elif element.get("type") == "audio":
                new_prompt.append(dict(element, role="audio"))
            else:
                new_prompt.append(element)
        if usage:
            new_prompt.append({"role": "usage", "type": "text", "text": usage[0]})
        if len(usage) > 1:
            new_prompt.append({"role": "usage_translation", "type": "text", "text": usage[1]})
        prompt, items = new_prompt, []
        canonical = {"mode": "none"}
    elif kind == "select":
        primitive = "select"
        multiple = interaction.get("maxSelections", 1) > 1
        if multiple:
            options["selectionMode"] = "multiple"
            minimum = interaction.get("minSelections", 1)
            if minimum != 1:
                options["minimumSelections"] = max(minimum, 1)
            options["maximumSelections"] = interaction["maxSelections"]
            options["evaluationTiming"] = "explicit"
        if gaps:
            options["layout"] = "inline"
            options["itemReuse"] = "unlimited"
            options["evaluationTiming"] = "explicit"
            targets = [{"id": gap} for gap in gaps]
            layout = layout_of()
            canonical = {"mode": "exactItem", "assignments": assignments_of()}
        else:
            canonical = {"mode": "exactSet" if multiple else "exactItem",
                         "correctItemIds": list(evaluation.get("correctItemIds", []))}
        if type_ in {"listening_choice", "listening_comprehension", "contextual_comprehension", "icon_choice"}:
            prompt = _with_audio(prompt, "automatic")
        if type_ in {"translation_choice_to_target", "translation_choice_to_source"}:
            # Pick the translation is solvable without audio: optional.
            prompt = [dict(e, required=False) if e.get("type") == "audio" else e for e in prompt]
        if type_ == "translation_choice_to_target":
            prompt = _with_text_language(prompt, "question", "source")
            items = _with_item_language(items, "target")
        elif type_ == "translation_choice_to_source":
            prompt = _with_text_language(prompt, "question", "target")
            items = _with_item_language(items, "source")
        elif type_ == "dialogue_response":
            # The text a Dialogue response answers is a situation.
            prompt = [dict(e, role="situation") if e.get("type") == "text" and e.get("role") == "passage" else e
                      for e in prompt]
        elif type_ == "script_recognition":
            # Recognize characters shows character specimens, not illustrations.
            prompt = [dict(e, role="character") if e.get("type") == "image" else e for e in prompt]
            items = [dict(item, content=[dict(e, role="character") if e.get("type") == "image" else e
                                         for e in item.get("content", [])])
                     for item in items]
    elif kind == "input":
        primitive = "input"
        normalization = evaluation.get("normalization", {})
        if normalization.get("case") == "preserve":
            options["caseHandling"] = "exact"
        if normalization.get("punctuation") == "preserve":
            options["punctuationHandling"] = "exact"
        if normalization.get("whitespace") == "preserve":
            options["whitespaceHandling"] = "exact"
        if normalization.get("accents") == "ignore":
            options["accentHandling"] = "ignore"
        if type_ in {"type_translation", "type_missing_word"}:
            options["typoTolerance"] = "conservative"
        accepted = list(evaluation.get("acceptedAnswers", []))
        spoken = next((e.get("text", "").strip() for e in prompt if e.get("type") == "audio"), None)
        literal = ([spoken] if type_ in {"fill_blank", "listening_spelling", "type_translation"}
                   and spoken and spoken not in accepted else [])
        canonical = {"mode": "expression", "answers": accepted}
        if literal:
            canonical["literalAnswers"] = literal
        if type_ == "type_missing_word":
            sentence = _primary_text(prompt)
            match = re.search(r"_{3,}", sentence or "")
            if sentence is not None and match:
                options["layout"] = "inlineGaps"
                targets = [{"id": "gap_1", "reveal": "firstGrapheme"}]
                layout = []
                if match.start() > 0:
                    layout.append({"type": "text", "text": sentence[:match.start()]})
                layout.append({"type": "target", "targetId": "gap_1"})
                if match.end() < len(sentence):
                    layout.append({"type": "text", "text": sentence[match.end():]})
                prompt = _without_primary_text(prompt)
                canonical = {"mode": "expression",
                             "targetAnswers": [{"targetId": "gap_1", "answers": accepted}]}
        elif type_ == "missing_word":
            transcript = _primary_text(prompt)
            words = missing if missing else accepted
            built = _missing_word_layout(transcript, words) if transcript is not None else None
            if built is not None:
                options["cardinality"] = "multiple"
                options["layout"] = "inlineGaps"
                targets = [{"id": f"gap_{i + 1}"} for i in range(len(words))]
                layout = built
                prompt = _with_audio(_without_primary_text(prompt), "automatic")
                canonical = {"mode": "expression", "targetAnswers": [
                    {"targetId": f"gap_{i + 1}", "answers": [word]} for i, word in enumerate(words)]}
            else:
                prompt = _with_audio(prompt, "automatic")
        elif type_ == "listening_spelling":
            prompt = _with_audio(prompt, "automatic")
        elif type_ == "type_translation":
            prompt = _with_text_language(prompt, "primary", "source")
            prompt = _with_text_language(prompt, "clue", "source")
            feedback["showAlternatives"] = "ranked"
    elif kind == "arrange":
        primitive = "arrange"
        if type_ == "image_word":
            prompt = _with_audio(prompt, "automatic")
            options["joiner"] = "none"
            options["unusedItems"] = "forbidden"
        if gaps:
            options["placementMode"] = "inlineGaps"
            options["layout"] = "inline"
            targets = [{"id": gap} for gap in gaps]
            layout = layout_of()
            canonical = {"mode": "gapAssignments", "assignments": assignments_of()}
        else:
            orders = list(evaluation.get("correctOrders", []))
            canonical = {"mode": "acceptedOrders" if len(orders) > 1 else "exactOrder",
                         "correctOrders": orders}
        if type_ == "build_translation":
            prompt = _with_text_language(prompt, "primary", "source")
            prompt = _with_text_language(prompt, "clue", "source")
            feedback["showAlternatives"] = "all"
    elif kind == "match":
        primitive = "match"
        pairs = [pair for pair in evaluation.get("pairs", []) if len(pair) == 2]
        left = {pair[0] for pair in pairs}
        right = {pair[1] for pair in pairs}
        items = [dict(item, side="left" if item["id"] in left else "right"
                      if item["id"] in right else ("left" if i % 2 == 0 else "right"))
                 for i, item in enumerate(items)]
        canonical = {"mode": "exactRelations", "relations": [list(pair) for pair in pairs]}
        # The v11 presets implied the languages of the two sides.
        side_languages = {"matching": ("target", "source"), "word_match": ("source", "target")}.get(type_)
        if side_languages:
            items = [dict(item, content=[
                dict(e, language=side_languages[0] if item["side"] == "left" else side_languages[1])
                if e.get("type") == "text" and e.get("role", "primary") == "primary" and "language" not in e else e
                for e in item.get("content", [])]) for item in items]
    else:
        raise ValueError(f"unknown interaction kind {kind!r}")

    out = {"updatedAt": exercise["updatedAt"], "primitive": primitive}
    if options:
        out["options"] = _ordered_options(options)
    out["prompt"] = prompt
    if items:
        out["items"] = items
    if targets:
        out["targets"] = targets
    if layout:
        out["layout"] = layout
    out["evaluation"] = _ordered_evaluation(
        {k: v for k, v in canonical.items() if v not in ([], None, "")})
    if feedback:
        out["feedback"] = feedback
    if exercise.get("hint"):
        out["hint"] = exercise["hint"]
    return out


# The successor of every preset the Build 256 Revision 4 catalogue retired
# (mirrors lib/models/preset_successors.dart): the converter records it.
PRESET_SUCCESSOR = {
    "choice": "choice_target",
    "fill_blank": "type_missing_word",
    "matching": "word_match",
    "listening_choice": "listening_answer_target",
    "listening_comprehension": "listening_answer_target",
    "reading_comprehension": "reading_answer_target",
    "contextual_comprehension": "reading_answer_target",
    "dialogue_response": "reading_answer_target",
    "reading_answer_source": "reading_answer_target",
    "type_translation": "type_translation_to_target",
    "build_translation": "build_translation_to_target",
    "gap_choice_inline": "gap_blocks",
}


def convert_content(content: dict, round_updated_at: str | None = None) -> dict:
    """The v12 Content for a v11 Content object, in the Dart key order."""
    content = copy.deepcopy(content)
    template = content.pop("editorTemplate", "") or ""
    metadata = dict(content.pop("authoringMetadata", {}) or {})
    if template:
        metadata["presetId"] = PRESET_SUCCESSOR.get(template, template)
    kind = content.get("kind")
    exercise = None
    if kind == "presentation" or "presentation" in content:
        presentation = content.pop("presentation")
        if not metadata:
            metadata = {"presetId": "flashcard"}
        kind = "exercise"
        exercise = presentation_to_exercise(presentation, round_updated_at or "1970-01-01T00:00:00.000Z")
    elif (content.get("role") == "lesson_intro" and "exercise" not in content
          and isinstance(content.get("text"), str)):
        # Build 257: a v11 Lesson introduction becomes a Before you start
        # card offering the GuideBook, as the note did (mirrors Dart).
        metadata["presetId"] = "before_you_start"
        kind = "exercise"
        exercise = before_you_start(content.pop("text"), guidebook_button=True,
                                    updated_at=round_updated_at or "1970-01-01T00:00:00.000Z")
        content.pop("role")
    elif isinstance(content.get("exercise"), dict) and "primitive" in content["exercise"]:
        # Build 256 Revision 5: a Story's lines and covers have no v11 recipe
        # and are authored in the canonical shape, so they pass through. The
        # v11 fixtures never contain them; the Dart converter never sees them.
        exercise = copy.deepcopy(content["exercise"])
    elif isinstance(content.get("exercise"), dict):
        exercise = convert_exercise(template, content["exercise"])
        # An Arrange with inline gaps is Pick the words for the gaps; a
        # Choose with inline gaps has no preset since Build 259 Revision 4
        # (mirrors Dart).
        layout = (content["exercise"].get("interaction") or {}).get("layout", [])
        if any(e.get("type") == "gap" for e in layout):
            if template == "choice":
                metadata.pop("presetId", None)
            elif template in ("word_order", "build_translation"):
                metadata["presetId"] = "gap_blocks"
    out = {"id": content["id"], "publicationState": content["publicationState"],
           "kind": kind, "required": content.get("required", True)}
    if metadata:
        out["authoringMetadata"] = metadata
    if content.get("role"):
        out["role"] = content["role"]
    if content.get("sourceRefs"):
        out["sourceRefs"] = content["sourceRefs"]
    if exercise is not None:
        out["exercise"] = exercise
    if content.get("text"):
        out["text"] = content["text"]
    return out


def convert_course_v11_to_v12(course: dict) -> dict:
    """A v12 copy of a v11 Course dict (checksums are the caller's job)."""
    course = copy.deepcopy(course)
    if course.get("formatVersion") != 11:
        raise ValueError("only Course Model v11 converts to v12")
    course["formatVersion"] = 12
    for lesson in course.get("lessons", []):
        guidebook = lesson.get("guidebook")
        if isinstance(guidebook, dict) and isinstance(guidebook.get("content"), list):
            guidebook["content"] = [convert_content(c) for c in guidebook["content"]]
        for round_ in lesson.get("rounds", []):
            round_["content"] = [convert_content(c, round_.get("updatedAt"))
                                 for c in round_.get("content", [])]
    return course


# ---------------------------------------------------------------------------
# Build 256 Revision 5: Stories. The generators author a Story's lines and
# covers directly in the canonical shape (there is no v11 recipe for them),
# in the key order Dart's toJson writes, so the official checksum computed
# here equals the one Dart computes from the parsed Course.


def story_line(line: str, *, updated_at: str, speaker_id: str = "",
               language: str | None = None, mode: str = "both",
               read_aloud: str = "story", text_reveal: str = "immediate") -> dict:
    """A Dialogue line exercise: `mode` is text, audio or both; `read_aloud`
    story (the Round's option), automatic or manual; `text_reveal` immediate
    or afterAudio (text and audio only)."""
    has_text, has_audio = mode != "audio", mode != "text"
    elements = []
    if has_text:
        element = {"role": "line", "type": "text", "text": line}
        if speaker_id:
            element["speakerId"] = speaker_id
        if language:
            element["language"] = language
        elements.append(element)
    if has_audio:
        element = {"role": "line", "type": "audio", "text": line}
        if speaker_id:
            element["speakerId"] = speaker_id
        if language:
            element["language"] = language
        if read_aloud in ("automatic", "manual"):
            element["playback"] = read_aloud
        if has_text:
            element["required"] = False
        elements.append(element)
    exercise = {"updatedAt": updated_at, "primitive": "presentation"}
    if has_text and has_audio and text_reveal == "afterAudio":
        exercise["options"] = {"textReveal": "afterAudio"}
    exercise["prompt"] = elements
    exercise["evaluation"] = {"mode": "none"}
    return exercise


def story_cover(*, updated_at: str, picture: str = "", alternative: str = "",
                title_line: str = "") -> dict:
    """A Story cover exercise: the cover picture (a bundled exercise image
    with its text alternative) and an optional title line."""
    elements = []
    if picture:
        elements.append({"role": "picture", "type": "image", "text": alternative, "asset": picture})
    if title_line:
        elements.append({"role": "title", "type": "text", "text": title_line})
    return {"updatedAt": updated_at, "primitive": "presentation", "prompt": elements,
            "evaluation": {"mode": "none"}}


def before_you_start(text: str, *, updated_at: str, guidebook_button: bool = False) -> dict:
    """A Before you start card (Build 257): the note shown before its Round
    starts (role intro) and, when asked, an Open GuideBook button."""
    exercise = {"updatedAt": updated_at, "primitive": "presentation"}
    if guidebook_button:
        exercise["options"] = {"guidebookButton": True}
    exercise["prompt"] = [{"role": "intro", "type": "text", "text": text}]
    exercise["evaluation"] = {"mode": "none"}
    return exercise


# Build 258: a Page's blocks in the key order Dart's PromptElement.toJson
# writes, so the official checksum computed here equals Dart's.
_BLOCK_KEYS = ("role", "type", "text", "asset", "language", "playback", "required",
               "textStyle", "align", "color", "size", "readAloud", "url")


def page_exercise(blocks: list[dict], *, updated_at: str) -> dict:
    """A Page (Build 258): a presentation whose prompt elements are blocks
    (role block) with their Page attributes."""
    prompt = []
    for block in blocks:
        element = {"role": "block", **block}
        unknown = set(element) - set(_BLOCK_KEYS)
        assert not unknown, unknown
        prompt.append({key: element[key] for key in _BLOCK_KEYS if key in element})
    return {"updatedAt": updated_at, "primitive": "presentation", "prompt": prompt,
            "evaluation": {"mode": "none"}}


def complete_text_exercise(text: str, answers: list[str], *, updated_at: str,
                           instruction: str = "", hint: str = "") -> dict:
    """Complete the text in its canonical shape (Build 259 Revision 3): the
    text marks each gap with ___ and `answers` gives one answer expression
    per gap, in order, such as "[il|un] gatto". Mirrors the Dart recipe
    (ExerciseDraftBuilder._buildCompleteText)."""
    pieces = re.split(r"_{3,}", text.strip())
    gaps = len(pieces) - 1
    assert gaps > 0 and gaps == len(answers), (text, answers)
    layout = []
    for index, piece in enumerate(pieces):
        if piece:
            layout.append({"type": "text", "text": piece})
        if index < gaps:
            layout.append({"type": "target", "targetId": f"gap_{index + 1}"})
    value = {
        "updatedAt": updated_at, "primitive": "input",
        "options": _ordered_options({"layout": "inlineGaps", "cardinality": "multiple"}),
        "prompt": [{"role": "clue", "type": "text", "text": instruction}] if instruction else [],
        "targets": [{"id": f"gap_{i + 1}"} for i in range(gaps)],
        "layout": layout,
        "evaluation": _ordered_evaluation({"mode": "expression", "targetAnswers": [
            {"targetId": f"gap_{i + 1}", "answers": [answer]} for i, answer in enumerate(answers)]}),
    }
    if hint:
        value["hint"] = hint
    return value


def becomes_exercise(content: dict) -> bool:
    """Whether a v11 Content is an exercise once converted: an exercise, a
    presentation or, since Build 257, a Lesson introduction (a Before you
    start card). A Story's flow names such a node `exercise`."""
    return ("exercise" in content or "presentation" in content
            or content.get("role") == "lesson_intro")


def story_flow(entries: list[tuple[str, bool]], *, title: str, presentation: str = "scroll",
               log: str = "dialogue", read_aloud: str = "automatic",
               requires_audio: set[str] | frozenset[str] = frozenset()) -> dict:
    """A linear Story flow over (content ID, is exercise) pairs, chained with
    `next`; defaults are omitted as Dart omits them."""
    nodes = []
    for index, (content_id, is_exercise) in enumerate(entries):
        node = {"id": content_id, "kind": "exercise" if is_exercise else "content",
                "contentId": content_id}
        if index + 1 < len(entries):
            node["transitions"] = [{"trigger": "next", "target": entries[index + 1][0]}]
        if content_id in requires_audio:
            node["requiresAudio"] = True
        nodes.append(node)
    flow = {"start": entries[0][0], "nodes": nodes}
    if presentation != "step":
        flow["presentation"] = presentation
    if title:
        flow["title"] = title
    if log != "all":
        flow["log"] = log
    if read_aloud != "automatic":
        flow["readAloud"] = read_aloud
    return flow


def assign_exercise(*, updated_at: str, mode: str, instruction: str,
                    items: list[tuple[str, str]], targets: list[tuple[str, str]],
                    assignments: dict[str, list[str]], capacity: str = "single",
                    reuse: str = "forbidden", shuffle: bool = True,
                    sentence: list | None = None) -> dict:
    """An Assign exercise in its canonical shape (Build 256 Revision 7).
    `items` are (id, text); `targets` are (id, label): for groups and slots
    the layout is a label text before each target (an empty label gives a
    bare target); for gaps, `sentence` lists the text runs and (target id,)
    tuples in reading order and the layout option is inline. Exact
    assignments: `assignments` maps a target ID to the item IDs it holds.
    `instruction` is the Instruction or context, a primary text with no
    language (Build 259)."""
    options = {"targetMode": mode}
    if capacity != "single":
        options["targetCapacity"] = capacity
    if reuse != "forbidden":
        options["itemReuse"] = reuse
    if mode == "gaps":
        options["layout"] = "inline"
    if not shuffle:
        options["shuffleItems"] = False
    layout = []
    if mode == "gaps":
        for part in sentence or []:
            if isinstance(part, tuple):
                layout.append({"type": "target", "targetId": part[0]})
            else:
                layout.append({"type": "text", "text": part})
    else:
        for target_id, label in targets:
            if label:
                layout.append({"type": "text", "text": label})
            layout.append({"type": "target", "targetId": target_id})
    return {
        "updatedAt": updated_at, "primitive": "assign",
        "options": _ordered_options(options),
        "prompt": [{"role": "primary", "type": "text", "text": instruction}],
        "items": [{"id": item_id, "content": [{"role": "primary", "type": "text", "text": text}]}
                  for item_id, text in items],
        "targets": [{"id": target_id} for target_id, _ in targets],
        "layout": layout,
        "evaluation": _ordered_evaluation({
            "mode": "exactAssignments",
            "assignments": [{"targetId": target_id, "itemIds": item_ids}
                            for target_id, item_ids in assignments.items()],
        }),
    }
