#!/usr/bin/env python3
"""Release checks for the built-in QuisquisLingo Image Bank."""
from pathlib import Path
import json, sys
ROOT=Path(__file__).resolve().parents[1]
BANK=ROOT/'assets'/'exercise_images'
MAX=50*1024
REC=15*1024

def main():
    issues=[]
    manifest=json.loads((BANK/'manifest.json').read_text(encoding='utf-8'))
    ids=set(); paths=set()
    for item in manifest:
        iid=str(item.get('id','')).strip(); path=str(item.get('assetPath','')).strip()
        if not iid or iid in ids: issues.append(f'duplicate/missing id: {iid!r}')
        ids.add(iid)
        if not path or path in paths: issues.append(f'duplicate/missing asset path: {path!r}')
        paths.add(path)
        if path.startswith('assets/'):
            f=ROOT/path
            if not f.exists(): issues.append(f'missing file: {path}')
            elif f.stat().st_size>MAX: issues.append(f'over 50 KB: {path} ({f.stat().st_size} bytes)')
    print(f'Image Bank: {len(manifest)} assets; {len(issues)} issue(s)')
    for x in issues: print('  -',x)
    return 1 if issues else 0
if __name__=='__main__': sys.exit(main())
