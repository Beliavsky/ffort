#!/usr/bin/env python3
"""Independent PURE/SIMPLE oracles, safety checks and rejection boundaries.

Uses the CLI directly; GNU Fortran is only an oracle, never an execution backend.
Compiler runs occur in fresh temporary directories to prevent stale .mod reuse.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import math
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def execute(argv, cwd=None):
    try:
        proc = subprocess.run([str(arg) for arg in argv], cwd=cwd or ROOT,
                              text=True, capture_output=True, timeout=15,
                              stdin=subprocess.DEVNULL)
        return dict(code=proc.returncode, out=proc.stdout, err=proc.stderr)
    except subprocess.TimeoutExpired as exc:
        def txt(value):
            return value.decode(errors='replace') if isinstance(value, bytes) else value or ''
        return dict(code=None, out=txt(exc.stdout), err='TIMEOUT '+txt(exc.stderr))
    except OSError as exc:
        return dict(code=None, out='', err=str(exc))


def compare(actual, expected, rel_tol=2e-6, abs_tol=1e-7, mode="tokens"):
    if mode == "lines":
        return actual.rstrip("\r\n") == expected.rstrip("\r\n")
    actual, expected = actual.split(), expected.split()
    if len(actual) != len(expected):
        return False
    for got, want in zip(actual, expected):
        try:
            a, b = float(got.replace('D', 'E').replace('d', 'e')), float(want)
        except ValueError:
            if got != want:
                return False
        else:
            if not math.isfinite(a):
                return False
            if re.fullmatch(r'[+-]?\d+', want):
                if a != int(want):
                    return False
            elif not math.isclose(a, b, rel_tol=rel_tol, abs_tol=abs_tol):
                return False
    return True


def candidate_errors(case, check, result):
    category = case['category']
    expected_check = 0 if category in ('success', 'runtime') else 1
    expected_run = 0 if category == 'success' else 2 if category == 'runtime' else 1
    errors = []
    for name, stage, expected in [('check', check, expected_check), ('run', result, expected_run)]:
        if stage['code'] != expected:
            errors.append(f'{name} expected exit {expected}, got {stage["code"]}')
        if expected and not stage['err'].strip():
            errors.append(name+': missing error diagnostic')
        if not expected and stage['err'].strip():
            errors.append(name+': unexpected success diagnostic')
    if check['out'].strip():
        errors.append('check stdout leak')
    if not compare(result['out'], case['expected_stdout'],
                   case.get('rel_tol',2e-6),case.get('abs_tol',1e-7),case.get('compare_mode','tokens')):
        errors.append('stdout mismatch/leak')
    if case.get('diagnostic'):
        diagnostic = '\n'.join(re.sub(r'^.*?:\d+:\d+:', '', line)
                               for line in result['err'].splitlines())
        if case['diagnostic'].lower() not in diagnostic.lower():
            errors.append('missing diagnostic '+case['diagnostic'])
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', help='Single executable path (no shell command)')
    parser.add_argument('--gfortran')
    parser.add_argument('--only', default='', help='Regular expression selecting case names')
    parser.add_argument('--result', default='results.json')
    args = parser.parse_args()
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran')
    versions = {}
    for name, executable in [('candidate', args.candidate), ('gfortran', args.gfortran)]:
        if executable:
            versions[name] = dict(path=executable, version=execute([executable, '--version']))
    # A valid SIMPLE prefix must be tested before using a compiler as a native
    # SIMPLE oracle. A second probe detects syntax-only/incomplete support.
    capability = None
    if args.gfortran:
        with tempfile.TemporaryDirectory(prefix='simple-capability-') as folder:
            base = Path(folder)
            valid = (ROOT/'cases/simple_attr_type_function.f90').read_text()
            invalid = (ROOT/'cases/simple_calls_pure_function.f90').read_text()
            probes = {}
            for label, text in [('valid',valid),('invalid_callee',invalid)]:
                source = base/(label+'.f90')
                source.write_text(text)
                probes[label] = execute([args.gfortran,'-std=f2023','-pedantic-errors',
                    '-fsyntax-only',source], folder)
            capability = dict(probes=probes, native_simple_oracle=(
                probes['valid']['code']==0 and probes['invalid_callee']['code']==1))
    records = []
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        if not re.search(args.only, case['name']):
            continue
        source = ROOT/case['source']
        row = dict(case=case, errors=[])
        if args.gfortran:
            if case['baseline'] == 'skip':
                row['gnu_skipped'] = True
            else:
                with tempfile.TemporaryDirectory(prefix='purity-oracle-') as folder:
                    binary = Path(folder)/'reference'
                    native_simple = case['has_simple'] and capability['native_simple_oracle']
                    oracle_source = source
                    baseline = case['baseline']
                    row['oracle_mode'] = 'direct_fortran'
                    if case['has_simple'] and not native_simple:
                        oracle_source = ROOT/case['pure_reference']
                        row['oracle_mode'] = 'simple_lowered_to_pure_arithmetic_only'
                    elif native_simple:
                        baseline = ('run' if case['category']=='success' else
                                    'compile' if case['category'] in ('runtime','unsupported') else 'reject')
                    row['oracle_baseline'] = baseline
                    compiled = execute([args.gfortran, '-std=f2023' if native_simple else '-std=f2018', '-pedantic-errors',
                                        '-fcheck=all', '-O0', oracle_source, '-o', binary], folder)
                    row['gnu_compile'] = compiled
                    if baseline == 'reject':
                        if compiled['code'] != 1:
                            row['errors'].append('GNU did not cleanly reject')
                    elif compiled['code'] != 0:
                        row['errors'].append('GNU compile failed')
                    elif baseline == 'runtime':
                        ran = execute([binary], folder)
                        row['gnu_run'] = ran
                        if ran['code'] in (None, 0) or not compare(ran['out'], case['expected_stdout']):
                            row['errors'].append('GNU runtime rejection/output mismatch')
                        if case.get('diagnostic','').lower() not in ran['err'].lower():
                            row['errors'].append('GNU runtime diagnostic mismatch')
                    elif baseline == 'run':
                        ran = execute([binary], folder)
                        row['gnu_run'] = ran
                        if ran['code'] != 0 or not compare(ran['out'], case['expected_stdout'],
                                case.get('rel_tol',2e-6),case.get('abs_tol',1e-7),case.get('compare_mode','tokens')):
                            row['errors'].append('GNU oracle mismatch')
        if args.candidate:
            checked = execute([args.candidate, '--check', source])
            ran = execute([args.candidate]+case.get('args', [])+[source])
            row['check'], row['run'] = checked, ran
            row['errors'] += candidate_errors(case, checked, ran)
        status = 'FAIL '+', '.join(row['errors']) if row['errors'] else 'PASS'
        if row.get('gnu_skipped') and not args.candidate:
            status = 'SKIP (interpreter safety policy; no GNU oracle claimed)'
        print(case['name']+': '+status, flush=True)
        records.append(row)
    if not records:
        parser.error('No cases selected')
    summary = dict(total=len(records), failed=sum(bool(row['errors']) for row in records))
    if args.candidate:
        summary['candidate_checked'] = len(records)
    if args.gfortran:
        summary['gnu_checked'] = sum(not row.get('gnu_skipped', False) for row in records)
        summary['gnu_skipped'] = sum(row.get('gnu_skipped', False) for row in records)
        summary['gnu_lowered_simple'] = sum(row.get('oracle_mode')=='simple_lowered_to_pure_arithmetic_only' for row in records)
        summary['gnu_direct_fortran'] = sum(row.get('oracle_mode')=='direct_fortran' for row in records)
        summary['gnu_executed'] = sum('gnu_run' in row for row in records)
        summary['gnu_compile_only'] = sum(row.get('oracle_baseline') == 'compile' for row in records)
        summary['gnu_compile_rejections'] = sum(row.get('oracle_baseline') == 'reject' for row in records)
    result = dict(tools=versions, simple_capability=capability, limitations='SIMPLE-to-PURE references test ordinary output and PURE constraints only, never the additional SIMPLE requirements. Original SIMPLE outcomes use independent expectations from the standard.', compiler_flags=dict(direct_or_lowered=['-std=f2018','-pedantic-errors','-fcheck=all','-O0'],native_simple=['-std=f2023','-pedantic-errors','-fcheck=all','-O0']), utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  summary=summary, records=records,
                  manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
                  source_sha256={row['case']['source']: hashlib.sha256((ROOT/row['case']['source']).read_bytes()).hexdigest()
                                 for row in records})
    result['reference_sha256'] = {row['case']['pure_reference']: hashlib.sha256((ROOT/row['case']['pure_reference']).read_bytes()).hexdigest() for row in records if row['case'].get('pure_reference')}
    if args.candidate:
        result['candidate_sha256'] = hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
    (ROOT/args.result).write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(summary, indent=2))
    return bool(summary['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
