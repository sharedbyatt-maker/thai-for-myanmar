#!/usr/bin/env python3
"""Build the small Windows course-audio tool, without generated/test MP3s or models."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile
from course_audio_plan import course_audio_plan

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    'Start_Audio_Studio.bat', 'THIRD_PARTY_NOTICES.md',
    'tool/course_audio_plan.py', 'tool/generate_thai_audio.py',
    'assets/data/phrases.json', 'assets/data/phrase_categories.json',
    'assets/data/course_v2.json', 'assets/data/thai_audio_manifest.json',
    'assets/data/course_audio_manifest.json',
    'docs/LOCAL_AUDIO_STUDIO.md', 'docs/AUDIO_UNITS_1_5.md',
] + [f'tool/audio_studio/{name}' for name in (
    'server.py', 'engine.py', 'start.ps1', 'requirements.txt', 'model-lock.json',
    'index.html', 'ui.js', 'ui.css')]


def package(root, output):
    root, output = Path(root), Path(output)
    course = json.loads((root / 'assets/data/course_v2.json').read_text(encoding='utf-8'))
    units = [u['id'] for u in course['units'][:5]]
    plan = course_audio_plan(root, units)
    payloads = {path: (root / path).read_bytes() for path in FILES}
    payloads['ဖတ်ရန်_README.txt'] = payloads['docs/AUDIO_UNITS_1_5.md']
    snapshot = {'packageVersion': 1, 'sourceCourseSha256': plan['sourceSha256'],
                'unitIds': units, 'newRecordings': plan['newRecordings'],
                'missingBindings': plan['missingBindings'],
                'files': {name: hashlib.sha256(raw).hexdigest() for name, raw in payloads.items()}}
    payloads['package-manifest.json'] = (json.dumps(snapshot, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
    output.parent.mkdir(parents=True, exist_ok=True)
    temp = output.with_suffix('.tmp.zip')
    with zipfile.ZipFile(temp, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, raw in payloads.items():
            archive.writestr('Thai_Audio_Studio_Units_1-5/' + name, raw)
    temp.replace(output)
    return snapshot


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'build/Thai_Audio_Studio_Units_1-5.zip')
    args = parser.parse_args()
    result = package(ROOT, args.output)
    print(f"{args.output}: {result['newRecordings']} new recordings planned; no audio generated")
