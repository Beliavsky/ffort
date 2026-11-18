#!/usr/bin/env python3
"""Verify original source preservation and the current full-file subset boundary."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parent
EXPECTED = 'c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--result', type=Path, default=ROOT/'full-source-result.json')
    args = parser.parse_args()
    exe = args.candidate.resolve()
    source = ROOT/'source/xutilities.f90'
    raw = source.read_bytes()
    assert len(raw) == 338883 and hashlib.sha256(raw).hexdigest() == EXPECTED
    cap=int(re.search(r"max_array_elements\s*=\s*(\d+)", (ROOT.parents[1]/"src/fi_ir.f90").read_text()).group(1))
    records = []
    for mode in ('check', 'run'):
        proc = subprocess.run([str(exe)]+(['--check'] if mode == 'check' else [])+[str(source)],
                              capture_output=True, text=True, timeout=60)
        assert proc.returncode == 1 and proc.stdout == '', (mode, proc)
        assert f':9329:55: Total array element limit exceeded ({cap})' in proc.stderr, (mode, proc.stderr)
        assert 'byte limit' not in proc.stderr
        records.append(dict(mode=mode, status=proc.returncode, stdout=proc.stdout, stderr=proc.stderr))
    result = dict(source_bytes=len(raw), source_sha256=EXPECTED,
                  candidate_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(), cases=records)
    args.result.write_text(json.dumps(result, indent=2)+'\n')
    print(f'PASS: exact 338883-byte original preserved; check/run reject at 9329:55 at the configured {cap}-element resource cap, status 1 with no stdout')

if __name__ == '__main__':
    main()
