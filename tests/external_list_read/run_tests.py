#!/usr/bin/env python3
"""External list-directed READ and bounded BACKSPACE differential suite.

Uses the CLI directly; GNU Fortran is only an oracle, never an execution backend.
Compiler runs occur in fresh temporary directories to prevent stale .mod reuse.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
from decimal import Decimal, InvalidOperation
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def execute(argv, cwd=None):
    try:
        proc = subprocess.run([str(arg) for arg in argv], cwd=cwd or ROOT,
                              capture_output=True, timeout=15,
                              stdin=subprocess.DEVNULL)
        return dict(code=proc.returncode, out=proc.stdout.decode('utf-8','surrogateescape'),
                    err=proc.stderr.decode('utf-8','surrogateescape'))
    except subprocess.TimeoutExpired as exc:
        def txt(value):
            return value.decode('utf-8','surrogateescape') if isinstance(value, bytes) else value or ''
        return dict(code=None, out=txt(exc.stdout), err='TIMEOUT '+txt(exc.stderr))
    except OSError as exc:
        return dict(code=None, out='', err=str(exc))


NUMBER=re.compile(r'[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eEdD][+-]?[0-9]+)?')
NONFINITE=re.compile(r'[+-]?(?:s?nan[0-9]*|inf(?:inity)?)',re.I)


def compare(actual, expected, mode="tokens"):
    # Exact decoded-byte modes preserve CHARACTER padding and line endings.
    if mode in ("bytes", "lines"):
        return actual == expected
    if mode != "tokens":
        return False
    # A no-output contract must not accept blank lines or spaces.
    if expected == '':
        return actual == ''
    actual, expected = actual.split(), expected.split()
    if len(actual) != len(expected):
        return False
    for got, want in zip(actual, expected):
        if NONFINITE.fullmatch(got) or NONFINITE.fullmatch(want):
            return False
        numeric_got=bool(NUMBER.fullmatch(got))
        numeric_want=bool(NUMBER.fullmatch(want))
        if numeric_got or numeric_want:
            if not (numeric_got and numeric_want):
                return False
            try:
                a = Decimal(got.replace('D','E').replace('d','e'))
                b = Decimal(want.replace('D','E').replace('d','e'))
            except InvalidOperation:
                return False
            if not a.is_finite() or not b.is_finite() or a != b:
                return False
            if a.is_zero() and a.is_signed() != b.is_signed():
                return False
        elif got != want:
            return False
    return True


HOST_FAILURE = re.compile(
    r"fortran runtime (?:error|warning)|runtime error:|backtrace|program received signal|"
    r"signal\s+(?:sig[a-z]+|[0-9]+)|segmentation fault|segfault|sigsegv|sigabrt|sigfpe|sigbus|"
    r"internal compiler error|\bICE\b|addresssanitizer|undefinedbehaviorsanitizer|"
    r"stack smashing|core dumped|fatal signal", re.IGNORECASE)


def expected_error_text(case):
    """Pinned source location/message, never inferred from current candidate output."""
    expected = case.get('expected_diagnostic')
    source = case.get('source')
    if not isinstance(expected, dict) or not isinstance(source, str) or not source:
        return None
    line, column, message = (expected.get(key) for key in ('line', 'column', 'message'))
    if (type(line) is not int or line <= 0 or type(column) is not int or column <= 0 or
            not isinstance(message, str) or not message or '\n' in message or '\r' in message):
        return None
    return f"{ROOT/source}:{line}:{column}: {message}\n"


def candidate_errors(case, check, result):
    category = case['category']
    expected_check = 0 if category in ('success', 'runtime') else 1
    expected_run = 0 if category == 'success' else 2 if category == 'runtime' else 1
    errors = []
    if category not in ('success', 'runtime', 'invalid'):
        errors.append('unknown candidate category')
    diagnostic = expected_error_text(case)
    for name, stage, expected in [('check', check, expected_check), ('run', result, expected_run)]:
        if stage['code'] != expected:
            errors.append(f'{name} expected exit {expected}, got {stage["code"]}')
        if stage['code'] is None or stage['code'] < 0 or stage['code'] >= 128:
            errors.append(name+': unexpected host termination')
        if HOST_FAILURE.search(stage['out']+'\n'+stage['err']):
            errors.append(name+': host failure marker')
        if expected:
            if not stage['err'].strip():
                errors.append(name+': missing error diagnostic')
            if diagnostic is None:
                errors.append(name+': missing pinned diagnostic')
            elif stage['err'] != diagnostic:
                errors.append(name+': source diagnostic mismatch')
        elif stage['err'] != '':
            errors.append(name+': unexpected success diagnostic')
    if check['out'] != '':
        errors.append('check stdout leak')
    if not compare(result['out'], case['expected_stdout'], case.get('compare_mode','tokens')):
        errors.append('stdout mismatch/leak')
    return errors


def load_cases(require_pins=True, only=""):
    cases = json.loads((ROOT/'manifest.json').read_text())['cases']
    ledger = json.loads((ROOT/'diagnostics.json').read_text())
    if ledger.get('schema_version') != 1 or not isinstance(ledger.get('negative_cases'), dict):
        raise ValueError('Invalid pinned diagnostic ledger')
    entries = ledger['negative_cases']
    names = [case['name'] for case in cases]
    if len(set(names)) != len(names):
        raise ValueError('Duplicate case names')
    if set(entries) != {case['name'] for case in cases if case['category'] != 'success'}:
        raise ValueError('Pinned diagnostic coverage differs from negative cases')
    result = []
    for original in cases:
        case = dict(original)
        if not re.search(only,case['name']):
            continue
        if case.get('baseline') not in ('run','compile','reject','runtime','skip'):
            raise ValueError('Unknown GNU baseline: '+case['name'])
        if case.get('compare_mode','tokens') not in ('tokens','bytes','lines'):
            raise ValueError('Unknown comparator: '+case['name'])
        source=case.get('source')
        if not isinstance(source,str) or Path(source).is_absolute() or '..' in Path(source).parts:
            raise ValueError('Unsafe fixture path: '+case['name'])
        if not isinstance(case.get('expected_stdout'),str):
            raise ValueError('Invalid expected stdout: '+case['name'])
        for unit,data in case.get('inputs',{}).items():
            if not re.fullmatch(r'[1-9][0-9]*',unit) or int(unit)>2147483647 or not isinstance(data,str):
                raise ValueError('Invalid fixture input: '+case['name'])
        if case['category'] not in ('success','runtime','invalid'):
            raise ValueError('Unknown candidate category: '+case['name'])
        if case['category'] != 'success':
            entry = entries[case['name']]
            data = (ROOT/case['source']).read_bytes()
            if entry.get('source') != case['source'] or entry.get('source_sha256') != hashlib.sha256(data).hexdigest():
                raise ValueError('Pinned diagnostic source differs: '+case['name'])
            case['expected_diagnostic'] = {key:entry.get(key) for key in ('line','column','message')}
            if require_pins and expected_error_text(case) is None:
                raise ValueError('Invalid pinned diagnostic: '+case['name'])
        result.append(case)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', help='Single executable path (no shell command)')
    parser.add_argument('--gfortran')
    parser.add_argument('--original-source',type=Path,default=ROOT.parent/'utilities_slices/source/xutilities.f90')
    parser.add_argument('--only', default='', help='Regular expression selecting case names')
    parser.add_argument('--result', default='results.json')
    args = parser.parse_args()
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran')
    versions = {}
    for name, executable in [('candidate', args.candidate), ('gfortran', args.gfortran)]:
        if executable:
            versions[name] = dict(path=executable, version=execute([executable, '--version']))
    provenance = json.loads((ROOT/'provenance.json').read_text())
    original = args.original_source.read_bytes()
    if hashlib.sha256(original).hexdigest() != provenance['source_sha256']:
        parser.error('Original xutilities source SHA-256 differs from recorded provenance')
    source_lines = original.splitlines(keepends=True)
    preserved_bodies=[]
    for body in provenance['bodies']:
        data=b''.join(source_lines[body['start_line']-1:body['end_line']])
        if hashlib.sha256(data).hexdigest()!=body['sha256']:
            parser.error('Original utility body bytes differ: '+body['procedure'])
        preserved_bodies.append(data)
    try:
        cases = load_cases(require_pins=bool(args.candidate),only=args.only)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        parser.error(str(exc))
    records = []
    for case in cases:
        if not re.search(args.only, case['name']):
            continue
        source = ROOT/case['source']
        row = dict(case=case, errors=[])
        if case.get('original_body'):
            fixture=source.read_bytes()
            if any(body not in fixture for body in preserved_bodies):
                row['errors'].append('Original utility body CRLF bytes differ')
        if args.gfortran:
            if case['baseline'] == 'skip':
                row['gnu_skipped'] = True
            else:
                with tempfile.TemporaryDirectory(prefix='internal-read-oracle-') as folder:
                    binary = Path(folder)/'reference'
                    for number,data in case.get('inputs',{}).items():
                        (Path(folder)/('fort.'+number)).write_bytes(data.encode())
                    compiled = execute([args.gfortran, '-std=f2018', '-pedantic-errors',
                                        '-fcheck=all', '-O0', source, '-o', binary], folder)
                    row['gnu_compile'] = compiled
                    if case['baseline'] == 'reject':
                        if compiled['code'] != 1:
                            row['errors'].append('GNU did not cleanly reject')
                    elif compiled['code'] != 0:
                        row['errors'].append('GNU compile failed')
                    elif compiled['out'] != '' or compiled['err'] != '':
                        row['errors'].append('GNU successful compilation stream leak')
                    elif case['baseline'] == 'runtime':
                        ran = execute([binary], folder)
                        row['gnu_run'] = ran
                        if ran['code'] != case.get('gnu_runtime_status',1) or not compare(ran['out'], case['expected_stdout']):
                            row['errors'].append('GNU runtime rejection/output mismatch')
                        if case.get('diagnostic','').lower() not in ran['err'].lower():
                            row['errors'].append('GNU runtime diagnostic mismatch')
                    elif case['baseline'] == 'run':
                        ran = execute([binary], folder)
                        row['gnu_run'] = ran
                        if ran['code'] != 0 or ran['err'] != '' or not compare(ran['out'], case['expected_stdout'],
                                case.get('compare_mode','tokens')):
                            row['errors'].append('GNU oracle mismatch')
        if args.candidate:
            with tempfile.TemporaryDirectory(prefix='external-read-candidate-') as folder:
                bindings=[]
                for number,data in case.get('inputs',{}).items():
                    file=Path(folder)/('input-'+number+'.txt')
                    file.write_bytes(data.encode())
                    bindings += ['--input',number+'='+str(file)]
                checked = execute([args.candidate, '--check']+bindings+[source],folder)
                ran = execute([args.candidate]+bindings+case.get('args', [])+[source],folder)
                for number,data in case.get('inputs',{}).items():
                    file=Path(folder)/('input-'+number+'.txt')
                    if not file.is_file() or file.read_bytes()!=data.encode():
                        row['errors'].append('input binding file changed: '+number)
                leftovers=[p.name for p in Path(folder).iterdir() if p.name.startswith('fort.')]
                if leftovers: row['errors'].append('implicit external files created: '+str(leftovers))
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
        summary['gnu_executed'] = sum('gnu_run' in row for row in records)
        summary['gnu_runtime_rejections'] = sum(row['case']['baseline'] == 'runtime' for row in records)
        summary['gnu_successful_executions'] = sum(row['case']['baseline'] == 'run' for row in records)
        summary['gnu_compile_only'] = sum(row['case']['baseline'] == 'compile' for row in records)
        summary['gnu_compile_rejections'] = sum(row['case']['baseline'] == 'reject' for row in records)
    result = dict(tools=versions, compiler_flags=['-std=f2018','-pedantic-errors','-fcheck=all','-O0'], utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  summary=summary, records=records,
                  manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
                  diagnostic_ledger_sha256=hashlib.sha256((ROOT/'diagnostics.json').read_bytes()).hexdigest(),
                  source_sha256={row['case']['source']: hashlib.sha256((ROOT/row['case']['source']).read_bytes()).hexdigest()
                                 for row in records})
    if args.candidate:
        result['candidate_sha256'] = hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
    (ROOT/args.result).write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(summary, indent=2))
    return bool(summary['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
