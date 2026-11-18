#!/usr/bin/env python3
"""Bounded release 0.31 cross-feature checks, with independent GNU oracles."""
from pathlib import Path
import argparse
from contextlib import ExitStack
import datetime
from decimal import Decimal, InvalidOperation
import hashlib
import json
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
FLAGS = ['-std=f2018', '-pedantic-errors', '-fcheck=all', '-O0']


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
    lines = output.splitlines()
    for line, wanted in case.get('formatted_lines', {}).items():
        if int(line) >= len(lines) or lines[int(line)] != wanted:
            errors.append('formatted CHARACTER line mismatch')
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
    if checked['out'].strip():
        errors.append('check stdout leak')
    errors += output_errors(case, ran['out'])
    diagnostic = case.get('diagnostic', '')
    for label, result in [('check', checked), ('run', ran)]:
        if diagnostic and (label == 'run' or category == 'reject'):
            # Source paths must not accidentally satisfy the diagnostic contract.
            message = re.sub(r'(?m)^.*?:\d+:\d+:\s*', '', result['err'])
            if diagnostic.casefold() not in message.casefold():
                errors.append(label + ': missing diagnostic ' + diagnostic)
    return errors


def provenance_errors(root=ROOT):
    """Verify original bodies by exact byte spans, including source CRLF."""
    errors = []
    try:
        provenance = json.loads((root / 'provenance.json').read_bytes())
        source = (root / provenance['source']).read_bytes()
        wrapper = (root / provenance['wrapper']).read_bytes()
        if hashlib.sha256(source).hexdigest() != provenance['source_sha256']:
            errors.append('Original utility source hash mismatch')
        if hashlib.sha256(wrapper).hexdigest() != provenance['wrapper_sha256']:
            errors.append('Original-body wrapper hash mismatch')
        lines = source.splitlines(keepends=True)
        for body in provenance['bodies']:
            original = b''.join(lines[body['first_line']-1:body['last_line']])
            extracted = wrapper[body['wrapper_start_byte']:body['wrapper_end_byte']]
            if (original != extracted or len(original) != body['byte_count'] or
                    hashlib.sha256(original).hexdigest() != body['sha256']):
                errors.append('Original body bytes mismatch: ' + body['name'])
    except (OSError, KeyError, TypeError, ValueError) as exc:
        errors.append('Provenance validation failed: ' + str(exc))
    return errors


def main():
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
    initial_provenance_errors = provenance_errors()
    source_hashes = {case['source']: hashlib.sha256((ROOT / case['source']).read_bytes()).hexdigest()
                     for case in cases}
    with ExitStack() as stack:
        tools = {}
        candidate = None
        if args.candidate:
            selected = Path(args.candidate).resolve(strict=True)
            folder = stack.enter_context(tempfile.TemporaryDirectory(prefix='release031-candidate-'))
            candidate = Path(folder) / selected.name
            shutil.copy2(selected, candidate)
            tools['candidate'] = dict(path=str(selected),
                                      sha256=hashlib.sha256(candidate.read_bytes()).hexdigest(),
                                      version=execute([candidate, '--version'], folder))
        compiler = None
        if args.gfortran:
            compiler = shutil.which(args.gfortran)
            if not compiler:
                ap.error('GNU compiler not found: ' + args.gfortran)
            compiler = str(Path(compiler).resolve())
            tools['gfortran'] = dict(path=compiler, version=execute([compiler, '--version'], ROOT))
        records = []
        for case in cases:
            source = ROOT / case['source']
            row = dict(case=case, errors=[])
            if compiler:
                if case['baseline'] == 'skip':
                    row['gnu_skipped'] = case['scope_note']
                else:
                    with tempfile.TemporaryDirectory(prefix='release031-gnu-') as folder:
                        binary = Path(folder) / 'reference'
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
                with tempfile.TemporaryDirectory(prefix='release031-run-') as folder:
                    checked = execute([candidate, '--check', source], folder)
                    ran = execute([candidate, source], folder)
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
        integrity_errors = initial_provenance_errors + provenance_errors()
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
                      scope='Synthetic bounded composition tests plus one exact variable_names wrapper. '
                            'Only the three procedure bodies named in provenance.json are original; '
                            'no full xutilities execution is claimed. Compile-only and policy-skip '
                            'cases are not GNU execution comparisons.',
                      provenance=json.loads((ROOT / 'provenance.json').read_bytes()),
                      manifest_sha256=hashlib.sha256(manifest_bytes).hexdigest(),
                      source_sha256=source_hashes, integrity_errors=integrity_errors)
        if candidate:
            report['candidate_sha256'] = tools['candidate']['sha256']
        (ROOT / args.result).write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(summary, indent=2))
        return bool(summary['failed'] or summary['integrity_failed'])


if __name__ == '__main__':
    raise SystemExit(main())
