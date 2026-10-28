import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("generator", Path(__file__).parents[1] / "generate_thai_audio.py")
g = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(g)


class AudioGenerationTests(unittest.TestCase):
    def setUp(self):
        self.rows = g.make_plan([
            {"id": "hello", "thai": "สวัสดี", "thaiMale": "สวัสดีครับ", "thaiFemale": "สวัสดีค่ะ"},
            {"id": "neutral", "thai": "ไม่เป็นไร"},
        ])
        self.voices = {"male": g.MALE, "female": g.FEMALE, "shared": g.FEMALE}

    @staticmethod
    def verify(path):
        if path.read_bytes() != b"test-audio":
            raise ValueError("bad audio")

    def test_exact_forms_and_neutral_mapping(self):
        self.assertEqual([r["form"] for r in self.rows], ["male", "female", "shared"])
        self.assertEqual(self.rows[1]["thai"], "สวัสดีค่ะ")

    def test_rejects_traversal_and_duplicate_ids(self):
        for rows in [[{"id": "../bad", "thai": "ก"}], [{"id": "x", "thai": "ก"}] * 2]:
            with self.assertRaises(ValueError):
                g.make_plan(rows)

    def test_partial_failure_is_saved_and_retry_reuses_only_verified_files(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            calls = []

            def failing(row):
                calls.append(row)
                if len(calls) == 2:
                    raise ValueError("simulated quota error")
                return b"test-audio"

            with self.assertRaises(ValueError):
                g.build_bundle(self.rows, self.voices, root / "cache", root / "first", failing, self.verify)
            report = json.loads((root / "first/generation-report.json").read_text())
            self.assertEqual((report["status"], report["readyForms"], len(report["missing"])), ("incomplete", 1, 2))
            calls.clear()

            def good(row):
                calls.append(row)
                return b"test-audio"

            report = g.build_bundle(self.rows, self.voices, root / "cache", root / "second", good, self.verify)
            self.assertEqual((report["generated"], report["reused"]), (2, 1))
            self.assertEqual(len(calls), 2)
            self.assertEqual(len(list((root / "second/assets/audio/thai").glob("*.mp3"))), 3)

    def test_corrupt_cache_text_and_voice_changes_trigger_regeneration(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            synth = lambda row: b"test-audio"
            g.build_bundle(self.rows, self.voices, root / "cache", root / "first", synth, self.verify)
            digest = g.fingerprint(self.rows[0], self.voices)
            (root / "cache" / f"{digest}.mp3").write_bytes(b"corrupted")
            rows = [dict(r) for r in self.rows]
            rows[1]["thai"] += "!"
            report = g.build_bundle(rows, self.voices, root / "cache", root / "second", synth, self.verify)
            self.assertEqual((report["generated"], report["reused"]), (2, 1))
            voices = {**self.voices, "shared": g.MALE}
            report = g.build_bundle(rows, voices, root / "cache", root / "third", synth, self.verify)
            self.assertEqual((report["generated"], report["reused"]), (1, 2))

    def test_character_limit_blocks_all_paid_calls(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            def forbidden(row):
                self.fail("No synthesis allowed over character limit")
            with self.assertRaises(ValueError):
                g.build_bundle(self.rows, self.voices, root / "cache", root / "out", forbidden, self.verify, max_characters=1)

    def test_invalid_audio_is_never_added_to_manifest(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            with self.assertRaises(ValueError):
                g.build_bundle(self.rows, self.voices, root / "cache", root / "out", lambda row: b"bad", self.verify)
            manifest = json.loads((root / "out/assets/data/thai_audio_manifest.json").read_text())
            self.assertEqual(manifest["entries"], [])


if __name__ == "__main__":
    unittest.main()
