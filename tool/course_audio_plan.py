"""Exact-text inventory for the deferred local course audio pack."""
import hashlib
import json
from pathlib import Path


def course_audio_plan(root):
    root = Path(root)
    raw = (root / 'assets/data/course_v2.json').read_bytes()
    course = json.loads(raw)
    base = json.loads((root / 'assets/data/thai_audio_manifest.json').read_text())['entries']
    extra = json.loads((root / 'assets/data/course_audio_manifest.json').read_text())['entries']
    available = {(e['phraseId'], e['form'], e['thai']) for e in base + extra}
    pending, reused = {}, 0
    required = 0
    for lid, line in course['lines'].items():
        forms = [('shared', line['male'])] if line['male'] == line['female'] else [(s, line[s]) for s in ['male', 'female']]
        for form, thai in forms:
            required += 1
            styles = ['male', 'female'] if form == 'shared' else [form]
            if all(any((line['sources'].get(s) or lid, f, thai) in available for f in [s, 'shared']) for s in styles):
                reused += 1
                continue
            key = (form, thai)
            row = pending.setdefault(key, dict(phraseId=lid, form=form, thai=thai, targets=[]))
            row['targets'].append(dict(phraseId=lid, form=form))
    requests = sorted(pending.values(), key=lambda r: (r['phraseId'], r['form']))
    return dict(schemaVersion=1, courseVersion=course['version'], sourceSha256=hashlib.sha256(raw).hexdigest(),
                status='audio-deferred' if requests else 'technical-coverage-complete', humanListeningReview='pending',
                requiredBindings=required, reusedBindings=reused, missingBindings=required-reused,
                newRecordings=len(requests), requests=requests)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, default=Path('build/course-audio-plan.json'))
    args = parser.parse_args()
    report = course_audio_plan(args.root)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    print({k: v for k, v in report.items() if k != 'requests'})
