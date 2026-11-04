"""Exact-text inventory for the deferred local course audio pack."""
import hashlib
import json
from pathlib import Path


def unit_line_ids(course, unit_ids):
    """Include lesson references and every nested spoken sentence part."""
    known = {u['id'] for u in course['units']}
    if (not isinstance(unit_ids, list) or not unit_ids or
            any(not isinstance(uid, str) or uid not in known for uid in unit_ids)):
        raise ValueError('Choose valid course units')
    selected = set(unit_ids)
    ids = set()
    for unit in course['units']:
        if unit['id'] not in selected:
            continue
        ids.update(unit['words'])
        ids.update(unit['models'])
        for lesson in unit['lessons']:
            for step in lesson['steps']:
                if 'line' in step:
                    ids.add(step['line'])
                ids.update(step.get('lines', []))
    pending = list(ids)
    while pending:
        for parts in course['lines'][pending.pop()].get('parts', {}).values():
            for pid in parts:
                if pid not in ids:
                    ids.add(pid)
                    pending.append(pid)
    return ids


def course_audio_plan(root, unit_ids=None):
    root = Path(root)
    raw = (root / 'assets/data/course_v2.json').read_bytes()
    course = json.loads(raw)
    selected = unit_line_ids(course, unit_ids) if unit_ids is not None else set(course['lines'])
    base = json.loads((root / 'assets/data/thai_audio_manifest.json').read_text())['entries']
    extra = json.loads((root / 'assets/data/course_audio_manifest.json').read_text())['entries']
    available = {(e['phraseId'], e['form'], e['thai']) for e in base + extra}
    pending, reused = {}, 0
    required = 0
    for lid, line in course['lines'].items():
        forms = [('shared', line['male'])] if line['male'] == line['female'] else [(s, line[s]) for s in ['male', 'female']]
        for form, thai in forms:
            required += lid in selected
            styles = ['male', 'female'] if form == 'shared' else [form]
            if all(any((line['sources'].get(s) or lid, f, thai) in available for f in [s, 'shared']) for s in styles):
                reused += lid in selected
                continue
            key = (form, thai)
            row = pending.setdefault(key, dict(phraseId=lid, form=form, thai=thai, targets=[]))
            row['targets'].append(dict(phraseId=lid, form=form))
    requests = sorted(pending.values(), key=lambda r: (r['phraseId'], r['form']))
    # Keep the global representative ID so sample/scoped/full runs share cache keys.
    requests = [{**r, 'targets': [t for t in r['targets'] if t['phraseId'] in selected]}
                for r in requests if any(t['phraseId'] in selected for t in r['targets'])]
    scope = {'unitIds': [u['id'] for u in course['units'] if u['id'] in set(unit_ids)]} if unit_ids is not None else {}
    return dict(**scope, schemaVersion=1, courseVersion=course['version'], sourceSha256=hashlib.sha256(raw).hexdigest(),
                status='audio-deferred' if requests else 'technical-coverage-complete', humanListeningReview='pending',
                requiredBindings=required, reusedBindings=reused, missingBindings=required-reused,
                newRecordings=len(requests), requests=requests)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, default=Path('build/course-audio-plan.json'))
    parser.add_argument('--units', nargs='+', help='Optional unit IDs, e.g. u01 u02 u03 u04 u05')
    args = parser.parse_args()
    report = course_audio_plan(args.root, args.units)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    print({k: v for k, v in report.items() if k != 'requests'})
