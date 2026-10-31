import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

PATH = Path(__file__).resolve().parents[1] / "audit_thai_content.py"
spec = importlib.util.spec_from_file_location("content_audit", PATH)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ContentAuditTests(unittest.TestCase):
    def test_report_cannot_overwrite_its_source(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "phrases.json"
            path.write_text("[]", encoding="utf-8")
            result = subprocess.run([sys.executable, str(PATH), "--input", str(path), "--output", str(path)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(path.read_text(encoding="utf-8"), "[]")

    def test_audit_is_read_only_and_deterministic(self):
        rows = [{"id": "hello", "thai": "สวัสดีค่ะ", "my": "မင်္ဂလာပါ။"}]
        before = repr(rows)
        first = module.audit(rows, "source-hash")
        self.assertEqual(module.audit(rows, "source-hash"), first)
        self.assertEqual(repr(rows), before)
        self.assertEqual(first["summary"]["errors"], 0)
        self.assertEqual(first["sourceSha256"], "source-hash")

    def test_bad_ids_empty_text_and_unsafe_script_fail(self):
        result = module.audit([
            {"id": "one", "thai": ""},
            {"id": "one", "thai": "สวัสดี"},
            {"id": "two", "thai": "สวัสดี\u202e"},
            {"id": "three", "thai": "สวัสดีမင်္ဂလာပါ"},
        ], "hash")
        self.assertEqual(result["summary"]["errors"], 4)

    def test_normalization_is_a_suggestion_not_an_edit(self):
        text = "สวัสดีี"
        result = module.audit([{"id": "one", "thai": text}], "hash")
        self.assertEqual(result["reviewItems"][0]["text"], text)
        self.assertNotEqual(result["reviewItems"][0]["normalization_candidate"], text)


if __name__ == "__main__":
    unittest.main()
