#!/usr/bin/env python3
"""Structural validation for the bundled, offline phrase dataset."""

import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATEGORIES_PATH = ROOT / "assets/data/phrase_categories.json"
PHRASES_PATH = ROOT / "assets/data/phrases.json"
EXPECTED_PHRASES = 500
REQUIRED_CATEGORIES = {
    "greetings",
    "introductions",
    "numbers",
    "money",
    "time",
    "dates",
    "questions",
    "common_answers",
    "food",
    "shopping",
    "transport",
    "directions",
    "workplace",
    "boss_supervisor",
    "factory",
    "accommodation",
    "apartment_landlord",
    "restaurant",
    "street_food",
    "convenience_store",
    "taxi",
    "public_transport",
    "health",
    "hospital_clinic",
    "pharmacy",
    "police",
    "immigration_documents",
    "bank",
    "phone_sim",
    "job_search",
    "salary",
    "overtime",
    "leave",
    "emergency",
    "daily_life",
}
HIGH_RISK_CATEGORIES = {
    "workplace",
    "boss_supervisor",
    "factory",
    "health",
    "hospital_clinic",
    "pharmacy",
    "police",
    "immigration_documents",
    "job_search",
    "salary",
    "overtime",
    "leave",
    "emergency",
}
REQUIRED_PHRASE_FIELDS = ("id", "categoryId", "thai", "my", "pronunciation", "en")
OPTIONAL_PHRASE_FIELDS = ("thaiMale", "thaiFemale", "note")


def normalized(value: str) -> str:
    value = unicodedata.normalize("NFC", value)
    return re.sub(r"\s+", " ", value.strip().casefold())


def has_control_characters(value: str) -> bool:
    return any(unicodedata.category(char) in {"Cc", "Cs"} for char in value)


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)


def main() -> int:
    errors = 0
    try:
        categories = json.loads(CATEGORIES_PATH.read_text(encoding="utf-8"))
        phrases = json.loads(PHRASES_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"cannot read content JSON: {error}")
        return 1

    if not isinstance(categories, list) or not isinstance(phrases, list):
        fail("both content files must contain JSON arrays")
        return 1

    category_ids = []
    for index, category in enumerate(categories):
        if not isinstance(category, dict):
            fail(f"category row {index + 1} is not an object")
            errors += 1
            continue
        category_id = category.get("id")
        if not isinstance(category_id, str) or not category_id.strip():
            fail(f"category row {index + 1} has no ID")
            errors += 1
            continue
        category_ids.append(category_id)
        if not re.fullmatch(r"[a-z0-9_]+", category_id):
            fail(f"category {category_id!r} has an invalid stable ID")
            errors += 1
        for field in ("my", "th", "en", "kind", "icon"):
            value = category.get(field)
            if not isinstance(value, str) or not value.strip():
                fail(f"category {category_id} is missing {field}")
                errors += 1
            elif value != value.strip() or has_control_characters(value):
                fail(f"category {category_id} has malformed {field}")
                errors += 1
        if category.get("kind") not in {"learn", "situation", "both"}:
            fail(f"category {category_id} has invalid kind")
            errors += 1

    category_set = set(category_ids)
    if len(category_ids) != len(category_set):
        fail("duplicate category IDs found")
        errors += 1
    missing_categories = REQUIRED_CATEGORIES - category_set
    if missing_categories:
        fail(f"required categories missing: {', '.join(sorted(missing_categories))}")
        errors += 1

    seen_ids = set()
    used_categories = set()
    seen_phrases = set()
    seen_text = {field: {} for field in ("thai", "my", "en")}
    if len(phrases) != EXPECTED_PHRASES:
        fail(
            f"phrase corpus has {len(phrases)} records "
            f"(expected exactly {EXPECTED_PHRASES})"
        )
        errors += 1

    for index, phrase in enumerate(phrases):
        row = f"phrase row {index + 1}"
        if not isinstance(phrase, dict):
            fail(f"{row} is not an object")
            errors += 1
            continue

        for field in REQUIRED_PHRASE_FIELDS:
            value = phrase.get(field)
            if not isinstance(value, str) or not value.strip():
                fail(f"{row} has missing or invalid {field}")
                errors += 1
            elif value != value.strip() or has_control_characters(value):
                fail(f"{row} has malformed {field}")
                errors += 1

        phrase_id = phrase.get("id")
        if not isinstance(phrase_id, str) or not phrase_id.strip():
            continue
        if not re.fullmatch(r"[a-z0-9_]+", phrase_id):
            fail(f"{phrase_id} has an invalid stable ID")
            errors += 1
        if phrase_id in seen_ids:
            fail(f"duplicate phrase ID: {phrase_id}")
            errors += 1
        seen_ids.add(phrase_id)

        category_id = phrase.get("categoryId")
        if not isinstance(category_id, str) or category_id not in category_set:
            fail(f"{phrase_id} references unknown category {category_id!r}")
            errors += 1
        else:
            used_categories.add(category_id)

        for field in ("keywords", "tags"):
            values = phrase.get(field)
            if not isinstance(values, list) or not values or any(
                not isinstance(value, str)
                or not value.strip()
                or value != value.strip()
                or has_control_characters(value)
                for value in values
            ):
                fail(f"{phrase_id} needs a non-empty {field} list of clean text")
                errors += 1
            elif len({normalized(value) for value in values}) != len(values):
                fail(f"{phrase_id} has duplicate {field}")
                errors += 1

        tags = phrase.get("tags")
        if not isinstance(tags, list):
            tags = []
        if category_id in HIGH_RISK_CATEGORIES and "high-risk" not in tags:
            fail(f"{phrase_id} in {category_id} must be marked high-risk")
            errors += 1
        if (
            "high-risk" in tags
            and category_id not in HIGH_RISK_CATEGORIES
            and "allergy" not in tags
        ):
            fail(f"{phrase_id} has an unexpected high-risk tag")
            errors += 1
        if category_id == "emergency" and "emergency" not in tags:
            fail(f"{phrase_id} in emergency must carry the emergency tag")
            errors += 1
        if "emergency" in tags and category_id != "emergency":
            fail(f"{phrase_id} has an emergency tag outside the emergency category")
            errors += 1

        for field in OPTIONAL_PHRASE_FIELDS:
            if field in phrase:
                value = phrase[field]
                if not isinstance(value, str) or not value.strip():
                    fail(f"{phrase_id} has malformed {field}")
                    errors += 1
                elif value != value.strip() or has_control_characters(value):
                    fail(f"{phrase_id} has malformed {field}")
                    errors += 1

        has_male = "thaiMale" in phrase
        has_female = "thaiFemale" in phrase
        if has_male != has_female:
            fail(f"{phrase_id} must provide both Thai polite variants or neither")
            errors += 1
        if has_male and isinstance(phrase.get("thaiMale"), str):
            # A polite particle can naturally close the first clause in a
            # multi-clause phrase, as in emergency requests.
            if "ครับ" not in phrase["thaiMale"]:
                fail(f"{phrase_id} male Thai variant must include ครับ")
                errors += 1
        if has_female and isinstance(phrase.get("thaiFemale"), str):
            if not any(particle in phrase["thaiFemale"] for particle in ("ค่ะ", "คะ")):
                fail(f"{phrase_id} female Thai variant must include ค่ะ or คะ")
                errors += 1
            if "นะค่ะ" in phrase["thaiFemale"]:
                fail(f"{phrase_id} female Thai variant should use นะคะ")
                errors += 1
            if re.search(
                r"(?:ไหม|หรือเปล่า|หรือยัง|เท่าไหร่|ที่ไหน|วันไหน|เวลาไหน|"
                r"กี่[^ ]*|ไหน|อะไร(?:บ้าง)?|ใคร|เมื่อไหร่|อย่างไร|ยังไง|ทำไม)ค่ะ$",
                phrase["thaiFemale"].rstrip(),
            ):
                fail(f"{phrase_id} female Thai question should end with คะ")
                errors += 1
        thai_text = phrase.get("thai")
        if isinstance(thai_text, str) and "นะค่ะ" in thai_text:
            fail(f"{phrase_id} Thai text contains the malformed particle นะค่ะ")
            errors += 1

        values = {field: phrase.get(field) for field in ("thai", "my", "en")}
        if all(isinstance(value, str) and value.strip() for value in values.values()):
            for field, value in values.items():
                key = normalized(value)
                previous = seen_text[field].get(key)
                if previous is not None:
                    fail(f"duplicate normalized {field} text: {previous} and {phrase_id}")
                    errors += 1
                else:
                    seen_text[field][key] = phrase_id

            exact_key = (normalized(values["thai"]), normalized(values["my"]))
            if exact_key in seen_phrases:
                fail(f"duplicate Thai/Myanmar phrase pair at {phrase_id}")
                errors += 1
            seen_phrases.add(exact_key)

        for field in REQUIRED_PHRASE_FIELDS[2:] + OPTIONAL_PHRASE_FIELDS:
            value = phrase.get(field)
            if isinstance(value, str) and any(char in value for char in "<>\u0000"):
                fail(f"{phrase_id} contains suspicious markup/control characters in {field}")
                errors += 1

    unused = category_set - used_categories
    if unused:
        fail(f"categories with no phrases: {', '.join(sorted(unused))}")
        errors += 1

    if errors:
        print(f"Content validation FAILED: {errors} issue(s).", file=sys.stderr)
        return 1
    print(
        f"Content validation PASS: {len(phrases)} structurally valid phrases, "
        f"{len(categories)} categories, {len(used_categories)} categories used."
    )
    print("Language fluency is not automatically certified by structural validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
