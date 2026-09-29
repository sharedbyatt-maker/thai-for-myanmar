#!/usr/bin/env python3
"""Validate phrase-to-audio mappings and report exact coverage and size."""

import json
import sys
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
PHRASES_PATH = ROOT / "assets/data/phrases.json"
CATEGORIES_PATH = ROOT / "assets/data/phrase_categories.json"
MANIFEST_PATH = ROOT / "assets/data/thai_audio_manifest.json"
AUDIO_ROOT = ROOT / "assets/audio"


def fail(message: str) -> None:
    raise ValueError(message)


def read_json(path: Path):
    with path.open(encoding="utf-8") as source:
        return json.load(source)


def selected_text(phrase: dict, style: str) -> str:
    variant = phrase.get("thaiMale" if style == "male" else "thaiFemale")
    return variant if variant else phrase["thai"]


def safe_asset_path(raw_path: object) -> Path:
    if not isinstance(raw_path, str):
        fail("audio asset path must be a string")
    path = PurePosixPath(raw_path)
    if (
        path.as_posix() != raw_path
        or len(path.parts) != 3
        or path.is_absolute()
        or path.suffix.lower() != ".mp3"
        or path.parts[:2] != ("audio", "thai")
        or any(part in {"", ".", ".."} for part in path.parts)
        or "\\" in raw_path
    ):
        fail(f"unsafe or unsupported audio asset path: {raw_path!r}")
    candidate = ROOT / "assets" / Path(*path.parts)
    try:
        candidate.resolve().relative_to((ROOT / "assets").resolve())
    except ValueError:
        fail(f"audio asset escapes assets directory: {raw_path!r}")
    return candidate


def main() -> int:
    phrases = read_json(PHRASES_PATH)
    categories = read_json(CATEGORIES_PATH)
    manifest = read_json(MANIFEST_PATH)
    if len(phrases) != 500:
        fail(f"expected exactly 500 phrases; found {len(phrases)}")
    if len(categories) != 35:
        fail(f"expected exactly 35 categories; found {len(categories)}")
    if not isinstance(manifest, dict) or manifest.get("schemaVersion") != 1:
        fail("audio manifest schemaVersion must be 1")

    phrase_by_id = {phrase["id"]: phrase for phrase in phrases}
    if len(phrase_by_id) != len(phrases):
        fail("phrase IDs must be unique")

    raw_entries = manifest.get("entries")
    if not isinstance(raw_entries, list):
        fail("audio manifest entries must be a list")

    entries = {}
    mapped_paths = set()
    for index, entry in enumerate(raw_entries):
        if not isinstance(entry, dict):
            fail(f"entry {index} must be an object")
        phrase_id = entry.get("phraseId")
        form = entry.get("form")
        thai = entry.get("thai")
        asset = entry.get("asset")
        if phrase_id not in phrase_by_id:
            fail(f"entry {index} refers to unknown phrase ID {phrase_id!r}")
        if form not in {"shared", "male", "female"}:
            fail(f"entry {index} has unknown form {form!r}")
        if not isinstance(thai, str) or not thai.strip():
            fail(f"entry {index} has empty Thai source text")

        phrase = phrase_by_id[phrase_id]
        if form == "shared":
            expected = {selected_text(phrase, "male"), selected_text(phrase, "female")}
        else:
            expected = {selected_text(phrase, form)}
        if thai not in expected:
            fail(f"stale Thai text for {phrase_id}/{form}: {thai!r}")

        key = (phrase_id, form)
        if key in entries:
            fail(f"duplicate mapping for {phrase_id}/{form}")
        path = safe_asset_path(asset)
        if not path.is_file():
            fail(f"audio file is missing: {path.relative_to(ROOT)}")
        if path.stat().st_size <= 0:
            fail(f"audio file is empty: {path.relative_to(ROOT)}")
        entries[key] = {"thai": thai, "asset": asset, "path": path}
        mapped_paths.add(asset)

    actual_audio_files = set()
    if AUDIO_ROOT.exists():
        for path in AUDIO_ROOT.rglob("*"):
            if path.is_file() and path.suffix.lower() in {
                ".mp3",
                ".wav",
                ".m4a",
                ".aac",
                ".ogg",
                ".opus",
                ".flac",
            }:
                actual_audio_files.add(path.relative_to(ROOT / "assets").as_posix())
    orphaned = actual_audio_files - mapped_paths
    if orphaned:
        fail(f"unmapped audio files: {', '.join(sorted(orphaned))}")

    expected_forms = []
    covered_phrases = set()
    for phrase in phrases:
        has_male = bool(phrase.get("thaiMale"))
        has_female = bool(phrase.get("thaiFemale"))
        if has_male and has_female:
            phrase_forms = [
                ("male", selected_text(phrase, "male")),
                ("female", selected_text(phrase, "female")),
            ]
        elif not has_male and not has_female:
            phrase_forms = [("shared", phrase["thai"])]
        else:
            male_text = selected_text(phrase, "male")
            female_text = selected_text(phrase, "female")
            phrase_forms = (
                [("shared", male_text)]
                if male_text == female_text
                else [("male", male_text), ("female", female_text)]
            )

        for form, thai in phrase_forms:
            expected_forms.append((phrase["id"], form, thai))
            specific = entries.get((phrase["id"], form))
            shared = entries.get((phrase["id"], "shared"))
            if form == "shared":
                is_covered = bool(shared and shared["thai"] == thai)
            else:
                is_covered = (specific and specific["thai"] == thai) or (
                    shared and shared["thai"] == thai
                )
            if is_covered:
                covered_phrases.add(phrase["id"])

    covered_forms = sum(
        1
        for phrase_id, form, thai in expected_forms
        if (
            (entry := entries.get((phrase_id, form)))
            and entry["thai"] == thai
        )
        or (
            form != "shared"
            and (entry := entries.get((phrase_id, "shared")))
            and entry["thai"] == thai
        )
    )

    unique_paths = {entry["path"] for entry in entries.values()}
    total_bytes = sum(path.stat().st_size for path in unique_paths)
    both_variant_count = sum(
        bool(phrase.get("thaiMale") and phrase.get("thaiFemale"))
        for phrase in phrases
    )
    neutral_count = sum(
        not phrase.get("thaiMale") and not phrase.get("thaiFemale")
        for phrase in phrases
    )
    selected_texts = [thai for _, _, thai in expected_forms]
    duplicate_texts = len(selected_texts) - len(set(selected_texts))

    print(
        "Corpus: "
        f"{len(phrases)} phrases / {len(categories)} categories; "
        f"{both_variant_count} with male and female forms / "
        f"{neutral_count} neutral; {len(expected_forms)} selected forms"
    )
    print(
        "Audio: "
        f"{len(covered_phrases)} phrases covered; "
        f"{covered_forms}/{len(expected_forms)} selected forms covered; "
        f"{len(expected_forms) - covered_forms} missing"
    )
    print(
        "Mappings: "
        f"male={sum(form == 'male' for _, form in entries)}; "
        f"female={sum(form == 'female' for _, form in entries)}; "
        f"shared={sum(form == 'shared' for _, form in entries)}; "
        f"files={len(unique_paths)}; size={total_bytes} bytes"
    )
    print(
        f"Selected Thai text: {sum(map(len, selected_texts))} characters; "
        f"{duplicate_texts} duplicate text instances"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, KeyError, TypeError, json.JSONDecodeError, ValueError) as error:
        print(f"Audio manifest validation failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
