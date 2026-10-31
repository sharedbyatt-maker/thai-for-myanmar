"""Read-only Thai content linting. Never rewrites phrases or audio mappings."""
from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import re

# Use bundled dictionaries only. CI and local audits never fetch models/corpora.
os.environ["PYTHAINLP_OFFLINE"] = "1"

from pythainlp.corpus import thai_words
from pythainlp.spell import NorvigSpellChecker
from pythainlp.tokenize import word_tokenize
from pythainlp.util import normalize

ROOT = Path(__file__).resolve().parents[1]
THAI_WORD = re.compile(r"^[\u0e01-\u0e3a\u0e40-\u0e4e]+$")
UNSAFE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]")


def audit(rows: list[dict], source_hash: str) -> dict:
    words = thai_words()
    checker = NorvigSpellChecker(custom_dict=words, min_freq=1)
    findings, errors, cache = [], [], {}
    seen = set()
    forms = 0
    for row in rows:
        phrase_id = row.get("id")
        if not isinstance(phrase_id, str) or not phrase_id or phrase_id in seen:
            errors.append({"id": phrase_id, "issue": "invalid_or_duplicate_id"})
            continue
        seen.add(phrase_id)
        for field in ("thai", "thaiMale", "thaiFemale"):
            text = row.get(field)
            if text is None and field != "thai":
                continue
            forms += 1
            if not isinstance(text, str) or not text.strip():
                errors.append({"id": phrase_id, "field": field, "issue": "empty_thai"})
                continue
            if UNSAFE.search(text) or re.search(r"[\u1000-\u109f]", text):
                errors.append({"id": phrase_id, "field": field, "issue": "unsafe_or_mixed_script"})
            if text not in cache:
                normalized = normalize(text)
                tokens = word_tokenize(text, engine="newmm", keep_whitespace=False)
                unknown = sorted({t for t in tokens if len(t) >= 2 and THAI_WORD.fullmatch(t) and t not in words})
                suggestions = []
                for token in unknown:
                    candidates = sorted(set(checker.spell(token)) - {token})[:3]
                    suggestions.append({"token": token, "candidates": candidates})
                cache[text] = (normalized, tokens, suggestions)
            normalized, tokens, suggestions = cache[text]
            if normalized != text or suggestions:
                findings.append({
                    "id": phrase_id, "field": field, "text": text,
                    "tokens": tokens,
                    **({"normalization_candidate": normalized} if normalized != text else {}),
                    **({"dictionary_review": suggestions} if suggestions else {}),
                })
    return {
        "schemaVersion": 1, "engine": "PyThaiNLP",
        "engineVersion": importlib.metadata.version("pythainlp"),
        "sourceSha256": source_hash,
        "policy": "Read-only suggestions for human review; not translation, grammar or pronunciation certification.",
        "summary": {"phrases": len(rows), "forms": forms, "errors": len(errors), "reviewItems": len(findings)},
        "errors": errors, "reviewItems": findings,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=ROOT / "assets/data/phrases.json")
    parser.add_argument("--output", type=Path, default=ROOT / "build/content-audit.json")
    args = parser.parse_args()
    if args.output.resolve() == args.input.resolve():
        parser.error("Report output cannot overwrite the input corpus")
    data = args.input.read_bytes()
    rows = json.loads(data)
    if not isinstance(rows, list) or not all(isinstance(row, dict) for row in rows):
        parser.error("Input must be a list of phrase objects")
    result = audit(rows, hashlib.sha256(data).hexdigest())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result["summary"], ensure_ascii=False))
    print(f"Report: {args.output}")
    print("Review suggestions do not change any text. Human review is required.")
    return 1 if result["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
