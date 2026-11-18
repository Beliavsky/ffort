#!/usr/bin/env python3
"""Replay fixture generation in isolation, proving committed inputs stay untouched."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent


def sha(data):
    return hashlib.sha256(data).hexdigest()


def check():
    manifest = json.loads((ROOT/'manifest.json').read_text())
    sources = [case['source'] for case in manifest['cases']]
    files = sources + ['manifest.json', 'provenance.json']
    before = {name: (ROOT/name).read_bytes() for name in files}
    utility = ROOT.parent/'utilities_slices/source/xutilities.f90'
    utility_before = utility.read_bytes()
    generator_before = (ROOT/'generate_cases.py').read_bytes()
    expected_case_set = set(sources)
    errors = []
    rows = []
    with tempfile.TemporaryDirectory(prefix='output-implied-do-generator-') as folder:
        isolated = Path(folder)/'tests/output_implied_do'
        (isolated/'cases').mkdir(parents=True)
        sibling = isolated.parent/'utilities_slices/source'
        sibling.mkdir(parents=True)
        # Only the generator and its two original inputs enter the temporary tree.
        # All 100 other source fixtures must be recreated, rather than copied.
        shutil.copyfile(ROOT/'generate_cases.py', isolated/'generate_cases.py')
        shutil.copyfile(ROOT/'cases/demo_trim_original.f90', isolated/'cases/demo_trim_original.f90')
        shutil.copyfile(utility, sibling/'xutilities.f90')
        proc = subprocess.run([sys.executable, str(isolated/'generate_cases.py')],
                              cwd=isolated, capture_output=True, timeout=30)
        if proc.returncode != 0 or proc.stderr != b'':
            errors.append('Isolated generator failed or emitted stderr')
        generated_set = {str(path.relative_to(isolated)) for path in (isolated/'cases').glob('*.f90')}
        if generated_set != expected_case_set:
            errors.append('Isolated fixture names differ')
        for name in files:
            generated = (isolated/name).read_bytes() if (isolated/name).is_file() else None
            exact = generated == before[name]
            if not exact:
                errors.append('Replay bytes differ: '+name)
            rows.append(dict(file=name, original_sha256=sha(before[name]),
                             replay_sha256=sha(generated) if generated is not None else None,
                             exact=exact))
    for row in rows:
        unchanged = (ROOT/row['file']).read_bytes() == before[row['file']]
        row['original_unchanged_after_replay'] = unchanged
        if not unchanged:
            errors.append('Committed bytes changed: '+row['file'])
    utility_unchanged = utility.read_bytes() == utility_before
    generator_unchanged = (ROOT/'generate_cases.py').read_bytes() == generator_before
    if not utility_unchanged or not generator_unchanged:
        errors.append('Generator or utility input changed')
    return dict(summary=dict(fixtures=len(sources), metadata_files=2,
                             exact_files=sum(row['exact'] for row in rows),
                             originals_unchanged=all(row['original_unchanged_after_replay'] for row in rows),
                             failed=len(errors)), errors=errors,
                generator_sha256=sha(generator_before), generator_unchanged=generator_unchanged,
                utility_sha256=sha(utility_before), utility_unchanged=utility_unchanged,
                process=dict(code=proc.returncode, stdout=proc.stdout.decode('latin1'),
                             stderr=proc.stderr.decode('latin1')), files=rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--result', type=Path, default=ROOT/'generator-replay-results.json')
    args = parser.parse_args()
    report = check()
    result = args.result if args.result.is_absolute() else ROOT/args.result
    result.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report['summary'], indent=2))
    return bool(report['errors'])

if __name__ == '__main__':
    raise SystemExit(main())
