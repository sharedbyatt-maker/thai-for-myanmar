import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tool'))
from course_audio_plan import course_audio_plan
from validate_course_v2 import validate

class CourseToolsTests(unittest.TestCase):
    def setUp(self):
        self.course = json.loads((ROOT / 'assets/data/course_v2.json').read_text())

    def test_full_authored_path_and_exact_audio_inventory(self):
        self.assertEqual(validate(self.course), 178)
        first = course_audio_plan(ROOT)
        self.assertEqual(first, course_audio_plan(ROOT))
        self.assertEqual((first['newRecordings'], first['reusedBindings']), (426, 53))
        self.assertGreater(first['missingBindings'], first['newRecordings'])
        keys = [(r['form'], r['thai']) for r in first['requests']]
        self.assertEqual(len(keys), len(set(keys)))
        self.assertEqual(sum(len(r['targets']) for r in first['requests']), first['missingBindings'])
        for r in first['requests']:
            for t in r['targets']:
                line = self.course['lines'][t['phraseId']]
                self.assertEqual(line['male' if t['form'] == 'shared' else t['form']], r['thai'])

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
