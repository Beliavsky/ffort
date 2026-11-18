#!/usr/bin/env python3
"""Separate specification-only omission receipt; GNU observations are not an oracle."""
import argparse
import hashlib
import json
from pathlib import Path
import tempfile
from run_tests import ROOT, execute, compare


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--gfortran', required=True)
    parser.add_argument('--result', default='optional-target-receipt.json')
    args = parser.parse_args()
    binary_hash = hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
    cases = [c for c in json.loads((ROOT/'manifest.json').read_text())['cases'] if 'oracle' in c]
    rows = []
    for case in cases:
        source = ROOT/case['source']
        row = {'name': case['name'], 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
               'candidate_expected': case['expected_stdout'], 'errors': []}
        row['candidate'] = execute([args.candidate, source])
        if row['candidate']['code'] != 0 or not compare(row['candidate']['out'], case['expected_stdout']):
            row['errors'].append('candidate violates the documented omission expectation')
        with tempfile.TemporaryDirectory(prefix='associated-optional-') as directory:
            exe = Path(directory)/'oracle-observation'
            row['gnu_compile'] = execute([args.gfortran, '-std=f2018', '-pedantic-errors', '-fcheck=all', '-O0', source, '-o', exe], directory)
            if row['gnu_compile']['code'] != 0:
                row['errors'].append('GNU compile failed')
            else:
                row['gnu_observation'] = execute([exe], directory)
                observation = row['gnu_observation']
                if observation['code'] != 0 or observation['out'].split() not in [['T'], ['F']]:
                    row['errors'].append('GNU observation did not finish with one logical result')
                row['gnu_agrees_with_specification_expectation'] = compare(observation['out'], case['expected_stdout'])
        rows.append(row)
    result = {'scope': 'Three specification-only whole nonpointer OPTIONAL TARGET omission cases; not GNU differential coverage.',
              'standard_reference': json.loads((ROOT/'optional-target-standard.json').read_text()),
              'candidate_sha256': binary_hash, 'gfortran_version': execute([args.gfortran, '--version']), 'cases': rows}
    result['failed'] = sum(bool(r['errors']) for r in rows)
    if binary_hash != hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest():
        result['failed'] += 1
        result['candidate_changed'] = True
    (ROOT/args.result).write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps({'total': len(rows), 'failed': result['failed'], 'gnu_agreement': sum(r.get('gnu_agrees_with_specification_expectation', False) for r in rows)}, indent=2))
    return bool(result['failed'])

if __name__ == '__main__':
    raise SystemExit(main())
