#!/usr/bin/env python3
"""Bounded release 0.33 cross-feature checks, with independent GNU oracles."""
from pathlib import Path
import argparse
from contextlib import ExitStack
import datetime
from decimal import Decimal, InvalidOperation
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
# Keep all runtime safety checks; only suppress the expected noncontiguous actual
# copy-in/copy-out temporary warning. All remaining GNU stderr still fails.
FLAGS = ['-std=f2018', '-pedantic-errors', '-fcheck=all,no-array-temps', '-O0']


def execute(argv, cwd):
    try:
        ran = subprocess.run([str(a) for a in argv], cwd=cwd, text=True,
                             capture_output=True, timeout=30,
                             stdin=subprocess.DEVNULL)
        return dict(code=ran.returncode, out=ran.stdout, err=ran.stderr,
                    argv=[str(a) for a in argv], cwd=str(cwd))
    except (OSError, subprocess.TimeoutExpired) as exc:
        return dict(code=None, out='', err=str(exc),
                    argv=[str(a) for a in argv], cwd=str(cwd))


def compare(actual, expected):
    """Compare literal expected tokens, with exact integers and finite reals."""
    actual, expected = actual.split(), expected.split()
    if len(actual) != len(expected):
        return False
    for got, want in zip(actual, expected):
        try:
            a = Decimal(got.replace('D', 'E').replace('d', 'e'))
            b = Decimal(want.replace('D', 'E').replace('d', 'e'))
        except InvalidOperation:
            if got != want:
                return False
            continue
        if not a.is_finite() or not b.is_finite():
            return False
        if re.fullmatch(r'[+-]?\d+', want):
            if a != b:
                return False
        elif abs(a - b) > max(Decimal('2e-6') * max(abs(a), abs(b)), Decimal('1e-7')):
            return False
    return True


def output_errors(case, output):
    errors = []
    if not compare(output, case['expected_stdout']):
        errors.append('stdout mismatch/leak')
    return errors


def candidate_errors(case, checked, ran):
    category = case['category']
    errors = []
    for label, result, code in [
        ('check', checked, 1 if category == 'reject' else 0),
        ('run', ran, {'success': 0, 'reject': 1, 'runtime': 2}[category]),
    ]:
        if result['code'] != code:
            errors.append(f'{label}: expected exit {code}, got {result["code"]}')
        if code and not result['err'].strip():
            errors.append(label + ': missing diagnostic')
        if not code and result['err'].strip():
            errors.append(label + ': unexpected success diagnostic')
    if checked['out']:
        errors.append('check stdout leak')
    errors += output_errors(case, ran['out'])
    if category != 'success' and ran['out'] and 'stdout mismatch/leak' not in errors:
        errors.append('stdout mismatch/leak')
    diagnostic = case.get('diagnostic', '')
    for label, result in [('check', checked), ('run', ran)]:
        if diagnostic and (label == 'run' or category == 'reject'):
            # Source paths must not accidentally satisfy the diagnostic contract.
            message = re.sub(r'(?m)^.*?:\d+:\d+:\s*', '', result['err'])
            if diagnostic.casefold() not in message.casefold():
                errors.append(label + ': missing diagnostic ' + diagnostic)
    return errors


def snapshot_candidate(selected, candidate):
    before = hashlib.sha256(selected.read_bytes()).hexdigest()
    shutil.copy2(selected, candidate)
    copied = hashlib.sha256(candidate.read_bytes()).hexdigest()
    after = hashlib.sha256(selected.read_bytes()).hexdigest()
    if (not candidate.stat().st_size or not os.access(candidate, os.X_OK) or
            before != copied or after != copied):
        raise ValueError('Candidate changed during snapshot or was empty/nonexecutable; wait for the build to finish')
    return copied


def check_original_bodies():
    mapping = json.loads((ROOT / 'original-source-map.json').read_text())
    original = (ROOT / mapping['original_source']).read_bytes()
    wrapper = (ROOT / mapping['wrapper']).read_bytes()
    if hashlib.sha256(original).hexdigest() != mapping['original_source_sha256']:
        raise SystemExit('Original utility fingerprint changed')
    if hashlib.sha256(wrapper).hexdigest() != mapping['wrapper_sha256']:
        raise SystemExit('Original body wrapper fingerprint changed')
    for routine in mapping['routines']:
        body = original[routine['source_byte_start']:routine['source_byte_end_exclusive']]
        begin = routine['wrapper_byte_start']
        if (hashlib.sha256(body).hexdigest() != routine['sha256'] or
                wrapper[begin:begin + len(body)] != body):
            raise SystemExit('Original utility body changed: ' + routine['name'])
    return mapping


def source_bytes(case):
    return b'\n'.join((ROOT / path).read_bytes()
                      for path in [*case.get('support_sources', []), case['source']])


def main():
    provenance = check_original_bodies()
    provenance_bytes = (ROOT / 'original-source-map.json').read_bytes()
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--candidate')
    ap.add_argument('--gfortran')
    ap.add_argument('--only', default='')
    ap.add_argument('--result', default='results.json')
    args = ap.parse_args()
    if not args.candidate and not args.gfortran:
        ap.error('Supply --candidate and/or --gfortran')
    manifest_bytes = (ROOT / 'manifest.json').read_bytes()
    cases = [case for case in json.loads(manifest_bytes)['cases']
             if re.search(args.only, case['name'])]
    if not cases:
        ap.error('No cases selected')
    source_hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
                     for case in cases for path in [*case.get('support_sources', []), case['source']]}
    with ExitStack() as stack:
        tools = {}
        candidate = None
        if args.candidate:
            selected = Path(args.candidate).resolve(strict=True)
            folder = stack.enter_context(tempfile.TemporaryDirectory(prefix='release033-candidate-'))
            candidate = Path(folder) / selected.name
            try:
                snapshot_candidate(selected, candidate)
            except ValueError as exc:
                ap.error(str(exc))
            tools['candidate'] = dict(path=str(selected),
                                      sha256=hashlib.sha256(candidate.read_bytes()).hexdigest(),
                                      version=execute([candidate, '--version'], folder))
            version = tools['candidate']['version']
            if version['code'] != 0 or version['err'] or not version['out'].strip():
                ap.error('Candidate snapshot failed its version probe')
        compiler = None
        if args.gfortran:
            compiler = shutil.which(args.gfortran)
            if not compiler:
                ap.error('GNU compiler not found: ' + args.gfortran)
            compiler = str(Path(compiler).resolve())
            tools['gfortran'] = dict(path=compiler, version=execute([compiler, '--version'], ROOT))
        records = []
        for case in cases:
            fixture = source_bytes(case)
            row = dict(case=case, errors=[])
            if compiler:
                if case['baseline'] == 'skip':
                    row['gnu_skipped'] = case['scope_note']
                else:
                    with tempfile.TemporaryDirectory(prefix='release033-gnu-') as folder:
                        binary = Path(folder) / 'reference'
                        source = Path(folder) / (case['name'] + '.f90')
                        source.write_bytes(fixture)
                        compiled = execute([compiler, *FLAGS, source, '-o', binary], folder)
                        row['gnu_compile'] = compiled
                        if case['baseline'] == 'reject':
                            if compiled['code'] != 1 or not compiled['err'].strip():
                                row['errors'].append('GNU did not cleanly reject')
                        elif compiled['code'] != 0:
                            row['errors'].append('GNU compile failed')
                        elif case['baseline'] == 'run':
                            ran = execute([binary], folder)
                            row['gnu_run'] = ran
                            if ran['code'] != 0 or ran['err'].strip():
                                row['errors'].append('GNU execution failed or emitted diagnostic')
                            row['errors'] += ['GNU ' + err for err in output_errors(case, ran['out'])]
            if candidate:
                with tempfile.TemporaryDirectory(prefix='release033-run-') as folder:
                    source = Path(folder) / (case['name'] + '.f90')
                    source.write_bytes(fixture)
                    checked = execute([candidate, '--check', source], folder)
                    ran = execute([candidate, *case.get('args', []), source], folder)
                row.update(check=checked, run=ran)
                row['errors'] += candidate_errors(case, checked, ran)
                if 'gnu_run' in row and not compare(ran['out'], row['gnu_run']['out']):
                    row['errors'].append('candidate/GNU differential mismatch')
            status = 'FAIL: ' + '; '.join(row['errors']) if row['errors'] else 'PASS'
            if row.get('gnu_skipped') and not candidate:
                status = 'SKIP (interpreter safety policy, no GNU oracle)'
            elif not row['errors'] and compiler and case['baseline'] == 'compile':
                status += ' (GNU compile-only)'
            elif not row['errors'] and row.get('gnu_skipped'):
                status += ' (GNU skipped: interpreter safety policy)'
            print(case['name'] + ': ' + status, flush=True)
            records.append(row)
        integrity_errors = []
        if (ROOT / 'original-source-map.json').read_bytes() != provenance_bytes:
            integrity_errors.append('Original provenance changed during verification')
        check_original_bodies()
        if (ROOT / 'manifest.json').read_bytes() != manifest_bytes:
            integrity_errors.append('Manifest changed during verification')
        for source, digest in source_hashes.items():
            if hashlib.sha256((ROOT / source).read_bytes()).hexdigest() != digest:
                integrity_errors.append('Fixture changed during verification: ' + source)
        if candidate and hashlib.sha256(candidate.read_bytes()).hexdigest() != tools['candidate']['sha256']:
            integrity_errors.append('Candidate snapshot changed during verification')
        summary = dict(total=len(records), failed=sum(bool(row['errors']) for row in records),
                       integrity_failed=len(integrity_errors))
        if candidate:
            summary['candidate_checked'] = len(records)
        if compiler:
            summary.update(gnu_checked=sum('gnu_skipped' not in row for row in records),
                           gnu_compiler_discrepancies=sum(bool(row['case'].get('compiler_discrepancy')) for row in records),
                           gnu_executed=sum('gnu_run' in row for row in records),
                           gnu_compile_only=sum(row['case']['baseline'] == 'compile' for row in records),
                           gnu_compile_rejections=sum(row['case']['baseline'] == 'reject' for row in records),
                           gnu_skipped=sum('gnu_skipped' in row for row in records))
        report = dict(tools=tools, summary=summary, records=records,
                      utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                      compiler_flags=FLAGS,
                      scope='Bounded specification-function/SAVE composition with existing pointer, explicit-dummy and elemental semantics. Five original utility bodies execute in one wrapper, not the full utility module. Compile-only boundaries are not GNU execution comparisons.',
                      original_source_provenance=provenance,
                      provenance_sha256=hashlib.sha256(provenance_bytes).hexdigest(),
                      manifest_sha256=hashlib.sha256(manifest_bytes).hexdigest(),
                      source_sha256=source_hashes, integrity_errors=integrity_errors)
        if candidate:
            report['candidate_sha256'] = tools['candidate']['sha256']
        (ROOT / args.result).write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(summary, indent=2))
        return bool(summary['failed'] or summary['integrity_failed'])


if __name__ == '__main__':
    raise SystemExit(main())
