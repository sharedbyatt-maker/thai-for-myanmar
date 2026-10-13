#!/usr/bin/env python3
"""Print exact-text recording jobs without credentials, API calls or file writes."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--limit', type=int, default=30,
                        help='Maximum phrase count, not voice/form count')
    parser.add_argument('--include-high-risk', action='store_true')
    args = parser.parse_args()
    if args.limit < 1:
        parser.error('--limit must be positive')
    phrases = json.loads((ROOT / 'assets/data/phrases.json').read_text(encoding='utf-8'))
    jobs = []
    selected = [p for p in phrases if args.include_high_risk or
                'high-risk' not in p['tags']][:args.limit]
    for phrase in selected:
        forms = [('male', phrase['thaiMale']), ('female', phrase['thaiFemale'])] \
            if 'thaiMale' in phrase else [('shared', phrase['thai'])]
        for form, text in forms:
            jobs.append({'phraseId': phrase['id'], 'form': form, 'thai': text,
                         'asset': f"audio/thai/{phrase['id']}__{form}.mp3"})
    print(json.dumps({'schemaVersion': 1, 'recordingJobs': jobs},
                     ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
