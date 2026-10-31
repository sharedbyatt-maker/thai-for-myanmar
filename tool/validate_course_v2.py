"""Validate authored curriculum, dependencies, learned-only choices and audio aliases."""
import json
from pathlib import Path
import re
from course_audio_plan import course_audio_plan


def validate(course):
    assert course['schemaVersion'] == 2
    known_units, lesson_ids = set(), set()
    for unit in course['units']:
        assert unit['id'] not in known_units
        assert set(unit['prerequisites']) <= known_units, unit['id']
        known_units.add(unit['id'])
        assert unit['goal'] and unit['tips'] and len(unit['lessons']) >= 4
        introduced = set()
        for lesson in unit['lessons']:
            assert lesson['id'] not in lesson_ids
            lesson_ids.add(lesson['id'])
            assert lesson['steps']
            for step in lesson['steps']:
                assert step['kind'] in {'teach', 'notice', 'choice', 'build', 'dialogue', 'reflect'}
                ids = ([step['line']] if 'line' in step else []) + step.get('lines', [])
                assert all(i in course['lines'] for i in ids)
                if step['kind'] in {'teach', 'notice'}:
                    introduced.update(ids)
                if step['kind'] in {'choice', 'build', 'dialogue'}:
                    assert set(ids) <= introduced, (lesson['id'], ids)
        assert set(unit['models']) <= introduced
    for key, line in course['lines'].items():
        assert key == line['id'] and re.fullmatch(r'[a-z0-9_]+', key)
        assert line['my'] and line['male'] and line['female']
        for style in ['male', 'female']:
            assert not re.search(r'[\u1000-\u109f\x00-\x1f]', line[style]), key
            parts = line['parts'].get(style, [])
            if parts:
                assert ''.join(course['lines'][p][style] for p in parts) == line[style], key
    return len(lesson_ids)


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    course = json.loads((root / 'assets/data/course_v2.json').read_text())
    count = validate(course)
    report = course_audio_plan(root)
    # Every declared reused mapping is checked against the original exact text.
    entries = json.loads((root / 'assets/data/thai_audio_manifest.json').read_text())['entries']
    for line in course['lines'].values():
        for style, source in line['sources'].items():
            if source:
                assert any(e['phraseId'] == source and e['thai'] == line[style] and e['form'] in [style, 'shared'] for e in entries)
    print(f"Course: {len(course['units'])} units, {count} lessons; {report['newRecordings']} deferred recordings, {report['reusedBindings']} reused bindings")
