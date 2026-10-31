import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
import zipfile
from unittest.mock import patch

STUDIO_PATH = Path(__file__).resolve().parents[1] / "audio_studio"
sys.path.insert(0, str(STUDIO_PATH))
import server
import engine


class FakeEngine:
    def prepare(self, progress, cancelled):
        progress("Fake test engine")

    def synthesize(self, text, speaker, speed):
        return b"test-audio"


class StudioTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        data = self.root / "assets/data"
        data.mkdir(parents=True)
        phrases = [{"id": "hello", "thai": "สวัสดี", "thaiMale": "สวัสดีครับ", "thaiFemale": "สวัสดีค่ะ"},
                   {"id": "neutral", "thai": "ไม่เป็นไร"}]
        (data / "phrases.json").write_text(json.dumps(phrases), encoding="utf-8")
        (data / "phrase_categories.json").write_text("[]", encoding="utf-8")
        def verify(path):
            if path.read_bytes() != b"test-audio":
                raise ValueError("Invalid test audio")
        self.studio = server.Studio(root=self.root, engine=FakeEngine(), verify=verify)

    def wait(self):
        self.studio.thread.join(timeout=5)
        self.assertFalse(self.studio.thread.is_alive())
        return self.studio.snapshot()

    def test_preview_and_app_compatible_zip(self):
        self.studio.start({"mode": "preview", "text": "สวัสดีครับ"})
        self.assertTrue(self.wait()["audio"])
        self.studio.start({"mode": "all"})
        state = self.wait()
        self.assertEqual((state["status"], state["done"], state["total"]), ("complete", 3, 3))
        archive = self.studio.work / "jobs" / state["job"] / "audio.zip"
        with zipfile.ZipFile(archive) as z:
            manifest = json.loads(z.read("assets/data/thai_audio_manifest.json"))
            self.assertEqual(len(manifest["entries"]), 3)
            for row in manifest["entries"]:
                self.assertEqual(z.read("assets/" + row["asset"]), b"test-audio")
            self.assertEqual(json.loads(z.read("generation-report.json"))["status"], "complete")
        self.studio.start({"mode": "all"})
        self.assertEqual(self.wait()["report"]["reused"], 3)

    def test_invalid_text_voice_speed_and_mode_rejected(self):
        for data in [{"mode": "delete"}, {"mode": "preview", "text": "English only"},
                     {"mode": "all", "male": 2}, {"mode": "all", "female": 9},
                     {"mode": "all", "speed": -1}, {"mode": "preview", "text": "ก" * 501}]:
            with self.assertRaises(ValueError):
                self.studio.start(data)

    def test_course_pack_deduplicates_aliases_and_never_overwrites_legacy_manifest(self):
        data = self.root / 'assets/data'
        (data / 'thai_audio_manifest.json').write_text('{"schemaVersion":1,"entries":[]}')
        (data / 'course_audio_manifest.json').write_text('{"schemaVersion":1,"entries":[]}')
        line = {'male':'น้ำ', 'female':'น้ำ', 'sources':{}}
        (data / 'course_v2.json').write_text(json.dumps({'version':'test', 'lines':{'c2_a':line, 'c2_b':line}}), encoding='utf-8')
        original = (data / 'thai_audio_manifest.json').read_bytes()
        self.studio.start({'mode':'course'})
        state = self.wait()
        self.assertEqual((state['status'], state['done']), ('complete', 1))
        self.assertEqual((data / 'thai_audio_manifest.json').read_bytes(), original)
        with zipfile.ZipFile(self.studio.work / 'jobs' / state['job'] / 'audio.zip') as z:
            self.assertNotIn('assets/data/thai_audio_manifest.json', z.namelist())
            self.assertNotIn('assets/data/phrases.json', z.namelist())
            entries = json.loads(z.read('assets/data/course_audio_manifest.json'))['entries']
            self.assertEqual({e['phraseId'] for e in entries}, {'c2_a', 'c2_b'})
            self.assertEqual(len({e['asset'] for e in entries}), 1)
            self.assertEqual(json.loads(z.read('course-source.json'))['newRecordings'], 1)

    def test_single_job_stop_and_partial_zip(self):
        entered, release = threading.Event(), threading.Event()
        class Slow(FakeEngine):
            def synthesize(self, text, speaker, speed):
                entered.set()
                release.wait(3)
                return b"test-audio"
        self.studio.engine = Slow()
        self.studio.start({"mode": "all"})
        self.assertTrue(entered.wait(2))
        with self.assertRaises(ValueError):
            self.studio.start({"mode": "all"})
        self.studio.cancel.set()
        release.set()
        state = self.wait()
        self.assertEqual(state["status"], "stopped")
        self.assertTrue(state["download"])
        with zipfile.ZipFile(self.studio.work / "jobs" / state["job"] / "audio.zip") as z:
            report = json.loads(z.read("generation-report.json"))
            self.assertEqual(report["status"], "incomplete")
            self.assertLess(report["readyForms"], report["requestedForms"])

    def test_http_session_origin_path_and_json_protection(self):
        httpd = server.ThreadingHTTPServer(("127.0.0.1", 0), server.make_handler(self.studio))
        worker = threading.Thread(target=httpd.serve_forever, daemon=True)
        worker.start()
        self.addCleanup(httpd.server_close)
        self.addCleanup(httpd.shutdown)
        base = f"http://127.0.0.1:{httpd.server_port}"
        def request(path, token=True, headers=None, data=None):
            h = {"X-Studio-Token": self.studio.token} if token else {}
            h.update(headers or {})
            req = urllib.request.Request(base + path, headers=h, data=data)
            try:
                with urllib.request.urlopen(req, timeout=2) as response:
                    return response.status, response.read()
            except urllib.error.HTTPError as error:
                return error.code, error.read()
        self.assertEqual(request("/api/config", token=False)[0], 403)
        self.assertEqual(request("/api/config", headers={"Host": "evil.example"})[0], 403)
        self.assertEqual(request("/api/config", headers={"Origin": "https://evil.example"})[0], 403)
        self.assertEqual(request("/download/../../secret")[0], 404)
        self.assertEqual(request("/api/config")[0], 200)
        code, body = request("/")
        self.assertEqual(code, 200)
        self.assertNotIn(b"__TOKEN__", body)
        self.assertEqual(request("/api/start", headers={"Content-Type": "text/plain"}, data=b"{}")[0], 400)
        self.assertEqual(request("/api/start", headers={"Content-Type": "application/json"}, data=b"[")[0], 400)
        code, body = request("/api/start", headers={"Content-Type": "application/json"}, data=b'{"mode":"sample"}')
        self.assertEqual(code, 202)
        state = self.wait()
        self.assertEqual(request("/download/" + state["job"])[0], 200)

    def test_model_lock_has_only_reviewed_relative_files(self):
        self.assertEqual(engine.LOCK["revision"], "abf63dc118365bea784fa881bdd1dce4b2cc1fd4")
        for name, digest in engine.LOCK["files"].items():
            self.assertFalse(Path(name).is_absolute())
            self.assertNotIn("..", Path(name).parts)
            self.assertEqual(len(digest), 64)
        self.assertIn("onnx/decoder_fp32.onnx", engine.LOCK["files"])

    def test_local_engine_errors_keep_diagnostics_without_cloud_setup_message(self):
        local = engine.KokoroEngine(self.root / "model")
        with patch.object(local, "_synthesize", side_effect=RuntimeError("test ONNX failure")):
            with self.assertRaisesRegex(ValueError, "Local Thai engine failed.*test ONNX failure"):
                local.synthesize("สวัสดีครับ", 9, 1.0)
        with patch.object(local, "_synthesize", side_effect=MemoryError("bad_alloc")):
            with self.assertRaisesRegex(ValueError, "ran out of memory"):
                local.synthesize("สวัสดีครับ", 9, 1.0)


if __name__ == "__main__":
    unittest.main()
