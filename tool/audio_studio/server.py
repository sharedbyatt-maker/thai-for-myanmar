#!/usr/bin/env python3
"""Loopback-only Thai Audio Studio. Run Start_Audio_Studio.bat on Windows."""
import argparse
import hmac
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import mimetypes
from pathlib import Path
import re
import secrets
import sys
import threading
import time
from urllib.parse import parse_qs, urlsplit
import uuid
import webbrowser
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
from engine import KokoroEngine, SPEAKERS, LOCK, validate_choices, validate_text, verify_mp3
from generate_thai_audio import make_plan, build_bundle, write_json
from course_audio_plan import course_audio_plan


class Studio:
    def __init__(self, root=ROOT, work=None, engine=None, verify=verify_mp3):
        self.root = Path(root)
        self.work = Path(work) if work else self.root / "build/audio-studio"
        self.engine = engine or KokoroEngine(self.work / "model")
        self.verify = verify
        self.token = secrets.token_urlsafe(32)
        self.guard = threading.Lock()
        self.cancel = threading.Event()
        self.thread = None
        self.state = {"status": "idle", "message": "Ready. Start with a preview.", "done": 0, "total": 0}
        self.phrases = json.loads((self.root / "assets/data/phrases.json").read_text(encoding="utf-8"))

    def update(self, **values):
        with self.guard:
            self.state.update(values)

    def snapshot(self):
        with self.guard:
            return dict(self.state)

    def start(self, data):
        mode = data.get("mode")
        if mode not in {"preview", "sample", "all", "course"}:
            raise ValueError("Choose preview, sample, all or course")
        if mode == "course" and not (self.root / "assets/data/course_v2.json").is_file():
            raise ValueError("Course data is not available in this checkout")
        course = course_audio_plan(self.root) if mode == "course" else None
        if course is not None and not course["requests"]:
            raise ValueError("No missing course recordings. Existing files are retained.")
        male, female, speed = data.get("male", 9), data.get("female", 2), data.get("speed", 1.0)
        validate_choices(male, female, speed)
        text = validate_text(data.get("text")) if mode == "preview" else None
        speaker = data.get("speaker", female)
        if type(speaker) is not int or speaker not in {row[0] for row in SPEAKERS}:
            raise ValueError("Unknown preview voice")
        with self.guard:
            if self.thread is not None and self.thread.is_alive():
                raise ValueError("A job is already running. Wait or press Stop.")
            job_id = uuid.uuid4().hex
            self.cancel.clear()
            total = len(course["requests"]) if course else (1 if mode == "preview" else len(make_plan(self.phrases, mode)))
            self.state = {"status": "running", "message": "Preparing local engine...", "done": 0,
                          "total": total, "job": job_id, "mode": mode}
            self.thread = threading.Thread(target=self.run, args=(job_id, mode, text, speaker, male, female, speed, course), daemon=True)
            self.thread.start()
        return job_id

    def run(self, job_id, mode, text, speaker, male, female, speed, course=None):
        job = self.work / "jobs" / job_id
        try:
            job.mkdir(parents=True)
            self.engine.prepare(lambda message: self.update(message=message), self.cancel.is_set)
            if self.cancel.is_set():
                raise ValueError("Stopped before generation")
            if mode == "preview":
                self.update(message="Generating preview on your CPU...")
                path = job / "preview.mp3"
                path.write_bytes(self.engine.synthesize(text, speaker, speed))
                self.verify(path)
                self.update(status="complete", message="Preview ready. Listen below.", done=1, audio=True)
                return
            plan = [{k: row[k] for k in ["phraseId", "form", "thai"]} for row in course["requests"]] if course else make_plan(self.phrases, mode)
            voices = {form: f"kokoro:{LOCK['revision']}:speaker={sid}:speed={speed}:mp3-v1"
                      for form, sid in [("male", male), ("female", female), ("shared", female)]}
            def synthesize(row):
                if self.cancel.is_set():
                    raise ValueError("Stopped. Completed files are saved and can be reused.")
                self.update(message=f"Generating {row['phraseId']} / {row['form']}")
                return self.engine.synthesize(row["thai"], male if row["form"] == "male" else female, speed)
            def verify(path):
                if self.cancel.is_set():
                    raise ValueError("Stopped. Completed files are saved and can be reused.")
                self.verify(path)
                self.update(done=self.snapshot()["done"] + 1)
            bundle = job / "bundle"
            try:
                report = build_bundle(plan, voices, self.work / "cache", bundle, synthesize, verify)
            finally:
                if (bundle / "generation-report.json").is_file():
                    # Carry source/provenance into the exported pack, never production assets.
                    write_json(bundle / "local-engine.json", {
                        "model": LOCK["repository"], "revision": LOCK["revision"],
                        "licenseDeclaration": LOCK["license"], "humanListeningReview": "pending",
                        "maleSpeaker": male, "femaleSpeaker": female, "speed": speed,
                    })
                    if course:
                        # A course pack can never overwrite the original 990-entry manifest.
                        original = bundle / "assets/data/thai_audio_manifest.json"
                        generated = json.loads(original.read_text(encoding="utf-8"))["entries"]
                        requests = {(r["phraseId"], r["form"]): r for r in course["requests"]}
                        expanded = []
                        for row in generated:
                            for alias in requests[(row["phraseId"], row["form"])]["targets"]:
                                expanded.append({**row, **alias})
                        existing = json.loads((self.root / "assets/data/course_audio_manifest.json").read_text(encoding="utf-8"))["entries"]
                        replacements = {(e["phraseId"], e["form"]) for e in expanded}
                        write_json(bundle / "assets/data/course_audio_manifest.json", {"schemaVersion": 1, "entries": [e for e in existing if (e["phraseId"], e["form"]) not in replacements] + expanded})
                        original.unlink()
                        write_json(bundle / "course-source.json", course)
                    else:
                        for name in ["phrases.json", "phrase_categories.json"]:
                            (bundle / "assets/data" / name).write_bytes((self.root / "assets/data" / name).read_bytes())
                    (bundle / "AUDIO_SOURCE.txt").write_text(
                        f"Thai Kokoro: https://huggingface.co/{LOCK['repository']}\n"
                        f"Revision: {LOCK['revision']}\nModel-card license: Apache-2.0.\n"
                        "Generated locally. Human listening review and source/voice rights review remain pending.\n"
                        "This tool does not import or publish audio automatically.\n", encoding="utf-8")
                    with zipfile.ZipFile(job / "audio.zip", "w", zipfile.ZIP_DEFLATED) as archive:
                        for path in bundle.rglob("*"):
                            if path.is_file():
                                archive.write(path, path.relative_to(bundle).as_posix())
                    self.update(download=True)
            self.update(status="complete", message=f"Ready: {report['readyForms']} MP3 files. Review before importing.",
                        done=report["readyForms"], report=report)
        except Exception as error:
            message = str(error) if isinstance(error, ValueError) else f"{type(error).__name__}: {str(error)[:300]}"
            self.update(status="stopped" if self.cancel.is_set() else "error", message=message)


def make_handler(studio):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass  # Keep the session token out of access logs.

        def send(self, status, body, content_type="application/json; charset=utf-8", download=False):
            if isinstance(body, dict):
                body = json.dumps(body, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Referrer-Policy", "no-referrer")
            self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; media-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'")
            if download:
                self.send_header("Content-Disposition", 'attachment; filename="thai-audio.zip"')
            self.end_headers()
            self.wfile.write(body)

        def allowed(self):
            expected = f"127.0.0.1:{self.server.server_port}"
            if self.headers.get("Host") != expected:
                return False
            origin = self.headers.get("Origin")
            if origin and origin != f"http://{expected}":
                return False
            query = parse_qs(urlsplit(self.path).query)
            token = self.headers.get("X-Studio-Token", query.get("token", [""])[0])
            return hmac.compare_digest(token, studio.token)

        def do_GET(self):
            if not self.allowed():
                self.send(403, {"error": "Open the private URL printed in the launcher window."})
                return
            path = urlsplit(self.path).path
            if path in {"/", "/ui.css", "/ui.js"}:
                name = {"/": "index.html", "/ui.css": "ui.css", "/ui.js": "ui.js"}[path]
                # Static resources authenticate via their own token query from the HTML.
                body = (HERE / name).read_bytes().replace(b"__TOKEN__", studio.token.encode())
                self.send(200, body, {"/": "text/html; charset=utf-8", "/ui.css": "text/css; charset=utf-8", "/ui.js": "text/javascript; charset=utf-8"}[path])
            elif path == "/api/state":
                self.send(200, studio.snapshot())
            elif path == "/api/config":
                course_count = course_audio_plan(studio.root)["newRecordings"] if (studio.root / "assets/data/course_v2.json").exists() else 0
                self.send(200, {"speakers": SPEAKERS, "phrases": studio.phrases[:5],
                                "files": len(make_plan(studio.phrases)), "phraseCount": len(studio.phrases), "courseFiles": course_count})
            elif re.fullmatch(r"/(audio|download)/[a-f0-9]{32}", path):
                kind, job = path.strip("/").split("/")
                file = studio.work / "jobs" / job / ("preview.mp3" if kind == "audio" else "audio.zip")
                if not file.is_file():
                    self.send(404, {"error": "File is not ready"})
                    return
                self.send(200, file.read_bytes(), "audio/mpeg" if kind == "audio" else "application/zip", kind == "download")
            else:
                self.send(404, {"error": "Not found"})

        def do_POST(self):
            if not self.allowed():
                self.send(403, {"error": "Session or origin rejected"})
                return
            try:
                if self.headers.get("Content-Type", "").split(";")[0] != "application/json":
                    raise ValueError("JSON required")
                size = int(self.headers.get("Content-Length", "0"))
                if not 0 < size <= 12000:
                    raise ValueError("Invalid request size")
                data = json.loads(self.rfile.read(size))
                if not isinstance(data, dict):
                    raise ValueError("Expected an object")
                path = urlsplit(self.path).path
                if path == "/api/start":
                    self.send(202, {"job": studio.start(data)})
                elif path == "/api/stop":
                    studio.cancel.set()
                    self.send(200, {"message": "Stopping after the current CPU operation finishes"})
                elif path == "/api/shutdown":
                    studio.cancel.set()
                    self.send(200, {"message": "Studio closed. You can close this tab."})
                    threading.Thread(target=self.server.shutdown, daemon=True).start()
                else:
                    self.send(404, {"error": "Not found"})
            except (ValueError, TypeError, KeyError) as error:
                self.send(400, {"error": str(error)})
    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()
    studio = Studio()
    server = ThreadingHTTPServer(("127.0.0.1", 0), make_handler(studio))
    url = f"http://127.0.0.1:{server.server_port}/?token={studio.token}"
    print("Thai Audio Studio: " + url, flush=True)
    print("Keep this window open. No card or cloud API key is needed.", flush=True)
    if not args.no_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        studio.cancel.set()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
