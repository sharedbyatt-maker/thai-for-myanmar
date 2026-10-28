#!/usr/bin/env python3
"""Prepare review-only Thai MP3 bundles. No paid requests without --generate."""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
MALE = "th-TH-Chirp3-HD-Charon"
FEMALE = "th-TH-Chirp3-HD-Kore"


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def make_plan(phrases, scope="all"):
    if not isinstance(phrases, list) or not phrases:
        raise ValueError("Expected a non-empty phrase list")
    result, seen = [], set()
    for phrase in phrases:
        phrase_id = phrase["id"]
        if not isinstance(phrase_id, str) or not re.fullmatch(r"[a-z0-9_\-]+", phrase_id):
            raise ValueError("Unsafe phrase ID")
        if phrase_id in seen:
            raise ValueError("Duplicate phrase ID")
        seen.add(phrase_id)
        male = phrase.get("thaiMale") or phrase["thai"]
        female = phrase.get("thaiFemale") or phrase["thai"]
        forms = [("shared", male)] if male == female else [("male", male), ("female", female)]
        for form, text in forms:
            if not isinstance(text, str) or not text.strip() or len(text.encode("utf-8")) > 4500:
                raise ValueError("Invalid or oversized Thai text")
            result.append({"phraseId": phrase_id, "form": form, "thai": text})
    if scope == "sample":
        # Include neutral and polite forms using the same stable five-phrase sample.
        ids = {p["id"] for p in phrases[:5]}
        result = [row for row in result if row["phraseId"] in ids]
    return result


def fingerprint(row, voices):
    source = {**row, "voice": voices[row["form"]], "encoding": "MP3", "pipelineVersion": 1}
    return hashlib.sha256(json.dumps(source, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def verify_mp3(path):
    """Decode the whole file; never promote empty, truncated or non-audio responses."""
    if not path.is_file() or path.stat().st_size == 0:
        raise ValueError("Missing or empty MP3")
    check = subprocess.run(
        ["ffmpeg", "-v", "error", "-xerror", "-i", str(path), "-f", "null", "-"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60, check=False,
    )
    if check.returncode:
        raise ValueError("MP3 decode failed")


def cloud_synthesizer(voices):
    # Credentials are read only here: planning and unit tests need no cloud packages.
    from google.auth.transport.requests import AuthorizedSession
    from google.oauth2 import service_account

    raw = os.environ.get("GOOGLE_TTS_CREDENTIALS_JSON", "")
    if not raw:
        raise ValueError("Set the GOOGLE_TTS_CREDENTIALS_JSON GitHub secret")
    try:
        info = json.loads(raw)
        credentials = service_account.Credentials.from_service_account_info(
            info, scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
    except Exception:
        raise ValueError("Invalid Google service-account JSON secret") from None
    session = AuthorizedSession(credentials)
    project = info.get("project_id")
    if not project:
        raise ValueError("Service-account JSON has no project_id")
    headers = {"x-goog-user-project": project}
    # Validate both selected voices before the first billable synthesis call.
    response = session.get(
        "https://texttospeech.googleapis.com/v1/voices?languageCode=th-TH",
        headers=headers, timeout=60,
    )
    if response.status_code != 200:
        raise ValueError(f"Voice preflight failed (HTTP {response.status_code}); check API, billing and IAM")
    available = {v["name"] for v in response.json().get("voices", []) if "th-TH" in v.get("languageCodes", [])}
    if not set(voices.values()) <= available:
        raise ValueError("A configured Thai voice is unavailable; no synthesis started")

    def synthesize(row):
        payload = {
            "input": {"text": row["thai"]},
            "voice": {"languageCode": "th-TH", "name": voices[row["form"]]},
            "audioConfig": {"audioEncoding": "MP3"},
        }
        for attempt in range(4):
            response = session.post(
                "https://texttospeech.googleapis.com/v1/text:synthesize",
                json=payload, headers=headers, timeout=90,
            )
            if response.status_code == 200:
                try:
                    audio = base64.b64decode(response.json()["audioContent"], validate=True)
                    if not audio:
                        raise ValueError()
                    return audio
                except Exception:
                    raise ValueError("Google returned invalid audioContent") from None
            if response.status_code not in {429, 500, 502, 503, 504} or attempt == 3:
                # Never print response bodies, request headers or credentials.
                raise ValueError(f"Synthesis failed (HTTP {response.status_code}); partial bundle preserved")
            time.sleep(2 ** (attempt + 1))
        raise AssertionError("unreachable")

    return synthesize


def build_bundle(plan, voices, cache, output, synthesize, verify=verify_mp3, max_characters=100000):
    """Checkpoint each success; export only exact-text, exact-voice verified files."""
    if output.exists():
        raise ValueError("Output already exists; choose a fresh output directory")
    cache.mkdir(parents=True, exist_ok=True)
    audio_dir = output / "assets/audio/thai"
    audio_dir.mkdir(parents=True)
    manifest_path = output / "assets/data/thai_audio_manifest.json"
    entries, missing, generated, reused = [], [], 0, 0
    requested_characters = sum(len(r["thai"]) for r in plan)
    if requested_characters > max_characters:
        raise ValueError("Character safety limit exceeded before synthesis")
    error = None
    try:
        for index, row in enumerate(plan):
            digest = fingerprint(row, voices)
            filename = f'{row["phraseId"]}_{row["form"]}_{digest[:16]}.mp3'
            cached = cache / f"{digest}.mp3"
            receipt = cache / f"{digest}.json"
            valid = False
            if cached.is_file() and receipt.is_file():
                try:
                    saved = json.loads(receipt.read_text(encoding="utf-8"))
                    valid = saved.get("sha256") == hashlib.sha256(cached.read_bytes()).hexdigest()
                    if valid:
                        verify(cached)
                except (ValueError, OSError, subprocess.SubprocessError):
                    valid = False
            if valid:
                reused += 1
            else:
                audio = synthesize(row)
                temp = cache / f"{digest}.tmp.mp3"
                temp.write_bytes(audio)
                verify(temp)
                temp.replace(cached)
                write_json(receipt, {
                    "fingerprint": digest, "voice": voices[row["form"]],
                    "sha256": hashlib.sha256(audio).hexdigest(),
                })
                generated += 1
            shutil.copyfile(cached, audio_dir / filename)
            entries.append({**row, "asset": f"audio/thai/{filename}"})
            write_json(manifest_path, {"schemaVersion": 1, "entries": entries})
            print(f"Audio {index + 1}/{len(plan)} ready", flush=True)
    except Exception as exc:
        # Preserve successes and stop instead of making hundreds of failing calls.
        error = str(exc) if isinstance(exc, ValueError) else "Request or audio verification failed; inspect cloud setup and retry"
        missing = plan[len(entries):]
    report = {
        "status": "incomplete" if error else "complete",
        "humanReview": "pending", "requestedForms": len(plan),
        "readyForms": len(entries), "generated": generated, "reused": reused,
        "sourceCharacters": requested_characters, "voices": voices,
        "missing": missing, "error": error,
    }
    write_json(manifest_path, {"schemaVersion": 1, "entries": entries})
    write_json(output / "generation-report.json", report)
    (output / "REVIEW_BEFORE_IMPORT.txt").write_text(
        "Generated Thai audio; human listening review is pending.\n"
        "Check generation-report.json status and all phrases before importing.\n"
        "Copy assets/ into the repository root only after review; then validate, build and test.\n",
        encoding="utf-8",
    )
    if error:
        raise ValueError(error)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scope", choices=["sample", "all"], default="all")
    parser.add_argument("--generate", action="store_true", help="Allow billable Google Cloud requests")
    parser.add_argument("--output", type=Path, default=ROOT / "build/thai-audio")
    parser.add_argument("--cache", type=Path, default=ROOT / "build/thai-audio-cache")
    parser.add_argument("--max-characters", type=int, default=100000)
    args = parser.parse_args()
    phrases = json.loads((ROOT / "assets/data/phrases.json").read_text(encoding="utf-8"))
    plan = make_plan(phrases, args.scope)
    voices = {"male": MALE, "female": FEMALE, "shared": FEMALE}
    characters = sum(len(r["thai"]) for r in plan)
    print(f"Plan: {len(plan)} files; {characters} source characters; scope={args.scope}")
    if characters > args.max_characters:
        raise ValueError("Character safety limit exceeded")
    if not args.generate:
        args.output.mkdir(parents=True, exist_ok=True)
        write_json(args.output / "generation-plan.json", {"voices": voices, "sourceCharacters": characters, "entries": plan})
        print("Plan only. No credentials used and no paid synthesis requested.")
        return
    if not shutil.which("ffmpeg"):
        raise ValueError("Install ffmpeg before generating audio")
    if args.output.exists():
        raise ValueError("Output already exists; choose a fresh output directory")
    synthesize = cloud_synthesizer(voices)
    report = build_bundle(plan, voices, args.cache, args.output, synthesize, max_characters=args.max_characters)
    print(f'Complete: {report["readyForms"]} files; generated={report["generated"]}; reused={report["reused"]}')


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        message = str(error) if isinstance(error, ValueError) else "Generation failed; check setup (credential details suppressed)"
        print(f"ERROR: {message}", file=sys.stderr)
        raise SystemExit(1)
