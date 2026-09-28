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
REQUIRED_CATEGORIES = {
    "greetings", "introductions", "numbers", "money", "time", "dates",
    "questions", "common_answers", "food", "shopping", "transport",
    "directions", "workplace", "boss_supervisor", "factory",
    "accommodation", "apartment_landlord", "restaurant", "street_food",
    "convenience_store", "taxi", "public_transport", "health",
    "hospital_clinic", "pharmacy", "police", "immigration_documents",
    "bank", "phone_sim", "job_search", "salary", "overtime", "leave",
    "emergency", "daily_life",
}
HIGH_RISK_CATEGORIES = {
    "boss_supervisor", "factory", "health", "hospital_clinic", "pharmacy",
    "police", "immigration_documents", "job_search", "salary", "overtime",
    "leave", "emergency",
}
REQUIRED_PHRASE_FIELDS = ("id", "categoryId", "thai", "my", "pronunciation", "en")


def normalized(value: str) -> str:
    value = unicodedata.normalize("NFC", value)
    return re.sub(r"\s+", " ", value.strip().casefold())


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
        for field in ("my", "th", "en", "kind", "icon"):
            if not isinstance(category.get(field), str) or not category[field].strip():
                fail(f"category {category_id} is missing {field}")
                errors += 1
        if category.get("kind") not in {"learn", "situation", "both"}:
            fail(f"category {category_id} has invalid kind")
            errors += 1

    if len(category_ids) != len(set(category_ids)):
        fail("duplicate category IDs found")
        errors += 1
    missing_categories = REQUIRED_CATEGORIES - set(category_ids)
    if missing_categories:
        fail(f"required categories missing: {', '.join(sorted(missing_categories))}")
        errors += 1

    seen_ids = set()
    seen_phrases = set()
    used_categories = set()
    if len(phrases) < 60:
        fail(f"starter corpus is too small: {len(phrases)} records (minimum 60)")
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
        if category_id not in set(category_ids):
            fail(f"{phrase_id} references unknown category {category_id!r}")
            errors += 1
        else:
            used_categories.add(category_id)
        for field in ("keywords", "tags"):
            values = phrase.get(field)
            if not isinstance(values, list) or not values or any(
                not isinstance(value, str) or not value.strip() for value in values
            ):
                fail(f"{phrase_id} needs a non-empty {field} list of text")
                errors += 1
        if category_id in HIGH_RISK_CATEGORIES and "high-risk" not in phrase.get("tags", []):
            fail(f"{phrase_id} in {category_id} must be marked high-risk")
            errors += 1

        thai = phrase.get("thai")
        myanmar = phrase.get("my")
        if isinstance(thai, str) and isinstance(myanmar, str):
            exact_key = (normalized(thai), normalized(myanmar))
            if exact_key in seen_phrases:
                fail(f"duplicate Thai/Myanmar phrase pair at {phrase_id}")
                errors += 1
            seen_phrases.add(exact_key)
            if any(char in thai for char in "<>\u0000"):
                fail(f"{phrase_id} contains suspicious markup/control characters")
                errors += 1
            if thai != thai.strip() or myanmar != myanmar.strip():
                fail(f"{phrase_id} has leading or trailing whitespace")
                errors += 1

        for variant in ("thaiMale", "thaiFemale"):
            if variant in phrase and (
                not isinstance(phrase[variant], str) or not phrase[variant].strip()
            ):
                fail(f"{phrase_id} has malformed {variant}")
                errors += 1

    unused = set(category_ids) - used_categories
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
