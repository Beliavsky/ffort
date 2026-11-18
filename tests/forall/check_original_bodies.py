#!/usr/bin/env python3
"""Prove that the six utility procedure bodies were not rewritten."""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parent

def check():
    original = (ROOT.parent / 'utilities_slices/source/xutilities.f90').read_text()
    names = ('matrix_by_vector_real', 'repeat_int', 'repeat_real', 'sign_changes_real', 'ivec', 'diag')
    for name in names:
        pattern = rf'(?ims)^(?:pure )?function {name}\b.*?^end function {name}\b[^\n]*'
        source = re.search(pattern, original)
        wrapper = re.search(pattern, (ROOT / ('utility_' + name + '.f90')).read_text())
        if source is None or wrapper is None or source.group() != wrapper.group():
            raise SystemExit('Original utility body differs: ' + name)
    return len(names)

if __name__ == '__main__':
    print('PASS: unchanged original procedure bodies:', check())
