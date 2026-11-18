#!/usr/bin/env python3
import re
from pathlib import Path

def verify_registry(text):
    names=re.findall(r'name\s*=\s*"([a-z][a-z0-9_]*)"',text)
    if len(names)!=131 or len(set(names))!=131:
        raise ValueError('Expected exactly131 unique intrinsic registry names')
    if re.findall(r'NUM_INTRINSICS\s*=\s*(\d+)\b',text)!=['131']:
        raise ValueError('Expected one exact NUM_INTRINSICS=131 declaration')
    if any(names.count(n)!=1 for n in ['maskl','maskr','shiftr','trailz']):
        raise ValueError('Required masks/shift/TRAILZ name missing or duplicated')

if __name__=='__main__':
    root=Path(__file__).resolve().parents[2]
    verify_registry((root/'vendor/fortfront/src/utilities/intrinsic_registry.f90').read_text())
    print('PASS: 131 unique intrinsic registry names; masks/shift/TRAILZ registered once')
