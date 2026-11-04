import copy
import tempfile
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tool'))
from course_audio_plan import course_audio_plan, unit_line_ids
from validate_course_v2 import validate

class CourseToolsTests(unittest.TestCase):
    def setUp(self):
        self.course = json.loads((ROOT / 'assets/data/course_v2.json').read_text())
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.unrecorded = Path(temp.name)
        data = self.unrecorded / 'assets/data'
        data.mkdir(parents=True)
        for name in ('course_v2.json', 'thai_audio_manifest.json'):
            (data / name).write_bytes((ROOT / 'assets/data' / name).read_bytes())
        (data / 'course_audio_manifest.json').write_text('{"schemaVersion":1,"entries":[]}')

    def test_full_authored_path_and_exact_audio_inventory(self):
        self.assertEqual(validate(self.course), 178)
        first = course_audio_plan(self.unrecorded)
        self.assertEqual(first, course_audio_plan(self.unrecorded))
        self.assertEqual((first['newRecordings'], first['reusedBindings']), (426, 53))
        self.assertGreater(first['missingBindings'], first['newRecordings'])
        keys = [(r['form'], r['thai']) for r in first['requests']]
        self.assertEqual(len(keys), len(set(keys)))
        self.assertEqual(sum(len(r['targets']) for r in first['requests']), first['missingBindings'])
        for r in first['requests']:
            for t in r['targets']:
                line = self.course['lines'][t['phraseId']]
                self.assertEqual(line['male' if t['form'] == 'shared' else t['form']], r['thai'])

    def test_first_five_scopes_include_parts_and_keep_global_cache_identity(self):
        units = ['u01', 'u02', 'u03', 'u04', 'u05']
        scoped = course_audio_plan(self.unrecorded, units)
        self.assertEqual((scoped['requiredBindings'], scoped['reusedBindings'], scoped['missingBindings'], scoped['newRecordings']), (101, 16, 85, 79))
        self.assertEqual(scoped['unitIds'], units)
        ids = unit_line_ids(self.course, units)
        for unit in self.course['units'][:5]:
            for lid in unit['models']:
                self.assertIn(lid, ids)
                for parts in self.course['lines'][lid]['parts'].values():
                    self.assertTrue(set(parts) <= ids)
        full = {(r['form'], r['thai']): r for r in course_audio_plan(self.unrecorded)['requests']}
        for row in scoped['requests']:
            self.assertEqual(row['phraseId'], full[(row['form'], row['thai'])]['phraseId'])
            self.assertTrue(all(t['phraseId'] in ids for t in row['targets']))
        for invalid in ([], ['u99'], 'u01', [None]):
            with self.assertRaises(ValueError):
                course_audio_plan(self.unrecorded, invalid)

    def test_imported_first_five_have_complete_exact_audio_coverage(self):
        scoped = course_audio_plan(ROOT, ['u01', 'u02', 'u03', 'u04', 'u05'])
        self.assertEqual((scoped['requiredBindings'], scoped['reusedBindings'], scoped['newRecordings']), (101, 101, 0))
        self.assertEqual(scoped['requests'], [])
        from validate_audio_manifest import validate_course_manifest
        manifest = json.loads((ROOT / 'assets/data/course_audio_manifest.json').read_text())
        self.assertEqual(len(validate_course_manifest(self.course, manifest)), 79)

    def test_course_audio_validator_rejects_stale_shared_duplicate_and_unsafe_entries(self):
        from validate_audio_manifest import validate_course_manifest
        manifest = json.loads((ROOT / 'assets/data/course_audio_manifest.json').read_text())
        entry = next(e for e in manifest['entries'] if e['form'] == 'shared')
        for changed in ({**entry, 'thai': entry['thai'] + 'ผิด'},
                        {**entry, 'asset': '../outside.mp3'},
                        {**entry, 'asset': 'audio/thai/not_present.mp3'},
                        {**entry, 'phraseId': 'unknown'},
                        {**entry, 'form': 'invalid'}):
            with self.assertRaises(ValueError):
                validate_course_manifest(self.course, {'schemaVersion': 1, 'entries': [changed]})
        with self.assertRaises(ValueError):
            validate_course_manifest(self.course, {'schemaVersion': 1, 'entries': [entry, entry]})
        # A shared entry must match both polite forms, not just one.
        split = next(e for e in manifest['entries'] if e['form'] == 'male')
        with self.assertRaises(ValueError):
            validate_course_manifest(self.course, {'schemaVersion': 1, 'entries': [{**split, 'form': 'shared'}]})

    def test_future_prerequisite_and_untaught_test_are_rejected(self):
        bad = copy.deepcopy(self.course)
        bad['units'][0]['prerequisites'] = ['u26']
        with self.assertRaises(AssertionError): validate(bad)
        bad = copy.deepcopy(self.course)
        bad['units'][0]['lessons'][0]['steps'].insert(0, {'kind':'choice','line':'c2_u01_01'})
        with self.assertRaises(AssertionError): validate(bad)

    def test_chunk_text_must_match_exact_whole_sentence(self):
        bad = copy.deepcopy(self.course)
        bad['lines']['c2_u01_03']['female'] = 'ผมชื่อเอกครับ'
        with self.assertRaises(AssertionError): validate(bad)

if __name__ == '__main__': unittest.main()
