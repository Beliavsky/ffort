#!/usr/bin/env python3
"""Host timing contracts, source guards and environment-sensitive observations.

Uses the CLI directly; GNU Fortran is only an oracle, never an execution backend.
Compiler runs occur in fresh temporary directories to prevent stale .mod reuse.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import math
import platform
import re
import subprocess
import tempfile
import contextlib

ROOT = Path(__file__).resolve().parent


def execute(argv, cwd=None):
    try:
        proc = subprocess.run([str(arg) for arg in argv], cwd=cwd or ROOT,
                              capture_output=True, timeout=15,
                              stdin=subprocess.DEVNULL)
        return dict(code=proc.returncode, out=proc.stdout.decode("latin-1"), err=proc.stderr.decode("latin-1"), argv=[str(arg) for arg in argv])
    except subprocess.TimeoutExpired as exc:
        def txt(value):
            return value.decode('latin-1') if isinstance(value, bytes) else value or ''
        return dict(code=None, out=txt(exc.stdout), err='TIMEOUT '+txt(exc.stderr))
    except OSError as exc:
        return dict(code=None, out='', err=str(exc))


def compare(actual, expected, rel_tol=2e-6, abs_tol=1e-7, mode="tokens"):
    # Empty output means no bytes, not an empty token stream.
    if expected == "":
        return actual == ""
    if mode == "lines":
        # Permit the conventional final record terminator, preserving padding
        # and extra blank records rather than stripping all trailing newlines.
        return (actual != "" and
                actual.replace("\r\n", "\n").removesuffix("\n") ==
                expected.replace("\r\n", "\n").removesuffix("\n"))
    # Synthetic contract fixtures emit one PASS record; preserve extra records.
    if expected == 'PASS\n':
        return re.fullmatch(r' *PASS\n',actual) is not None
    return actual == expected


def observe_cpu(result):
    if result['code'] != 0 or result['err'] != '':
        return ['CPU_TIME observation failed']
    lines = result['out'].splitlines()
    if len(lines) != 3:
        return ['CPU_TIME observation must contain exactly three records']
    for line in lines:
        m = re.fullmatch(r'Processor Time =\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eEdD][+-]?\d+)?) seconds\.', line)
        if not m or not math.isfinite(float(m[1].replace('D','E').replace('d','e'))) or float(m[1].replace('D','E').replace('d','e')) < 0:
            return ['CPU_TIME observation is malformed, nonfinite or decreasing']
    return []


def observe_clock(result):
    # Exact full original is intentionally stopped at its enormous loop.
    if result['code'] != 2 or 'step limit' not in result['err']:
        return ['original SYSTEM_CLOCK did not reach the bounded loop stop']
    lines = result['out'].splitlines()
    if len(lines) != 9 or lines[0].strip() != 'accuracy may vary with argument type!' or lines[1].strip() != 'query all arguments' or lines[-1].strip() != 'time some computation':
        return ['original SYSTEM_CLOCK prefix mismatch']
    for offset,kind in [(2,64),(5,32)]:
        nums=[]
        for j,label in enumerate(['COUNT_MAX','COUNT_RATE','CURRENT COUNT']):
            m=re.fullmatch(r'\s*'+label+r'\('+str(kind)+r'bit\)=\s*([+-]?\d+)\s*',lines[offset+j])
            if not m:return ['original SYSTEM_CLOCK numeric record mismatch']
            nums.append(int(m[1]))
        maximum,rate,count=nums
        if rate == 0:
            if maximum != 0 or count != -(2**(kind-1)-1):return ['invalid unavailable SYSTEM_CLOCK observation']
        elif rate < 0 or maximum < 0 or count < 0 or count > maximum:
            return ['invalid available SYSTEM_CLOCK observation']
    return []


def candidate_errors(case, check, result):
    category=case['category'];errors=[]
    expected_check=1 if category=='reject' else 0
    if check['code'] != expected_check:errors.append('wrong check exit')
    if check['out'] != '':errors.append('check stdout leak')
    if expected_check:
        if not check['err'].strip():errors.append('missing check diagnostic')
    elif check['err'] != '':errors.append('unexpected check diagnostic')
    if category=='original_cpu':return errors+observe_cpu(result)
    if category=='original_clock':return errors+observe_clock(result)
    expected_run=0 if category=='success' else 1 if category=='reject' else 2
    if result['code'] != expected_run:errors.append('wrong run exit')
    if expected_run:
        if not result['err'].strip():errors.append('missing runtime diagnostic')
    elif result['err'] != '':errors.append('unexpected runtime diagnostic')
    if not compare(result['out'],case['expected_stdout']):errors.append('stdout mismatch/leak')
    if case.get('diagnostic') and case['diagnostic'].lower() not in result['err'].lower():errors.append('missing expected diagnostic')
    return errors



def gnu_compile_errors(case, result):
    if case['baseline'] == 'reject':
        return [] if result['code'] == 1 and result['err'].strip() and result['out'] == '' else ['GNU did not cleanly reject']
    return [] if result['code'] == 0 and result['out'] == '' else ['GNU compile failed or stdout leak']


def gnu_success_errors(case, result):
    errors = []
    if result['code'] != 0 or not compare(result['out'], case['expected_stdout'],
            case.get('rel_tol',2e-6),case.get('abs_tol',1e-7),case.get('compare_mode','tokens')):
        errors.append('GNU oracle mismatch')
    if result['err'] != '':
        errors.append('GNU unexpected success diagnostic')
    return errors


def validate_sources(root=ROOT):
    expected=json.loads((root/'source-hashes.json').read_text())
    actual={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted((root/'cases').glob('*.f90'))}
    if expected != actual:
        raise ValueError('frozen timing source inventory/hash mismatch')
    return actual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', help='Single executable path (no shell command)')
    parser.add_argument('--gfortran')
    parser.add_argument('--only', default='', help='Regular expression selecting case names')
    parser.add_argument('--result', default='results.json')
    parser.add_argument('--artifacts', help='Retained GNU build directory (default: a fresh system temporary directory)')
    args = parser.parse_args()
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran')
    initial_sources = validate_sources()
    initial_candidate_hash = None
    if args.candidate:
        candidate_path = Path(args.candidate).expanduser().resolve()
        if not candidate_path.is_file():
            parser.error('Candidate executable does not exist: '+str(candidate_path))
        args.candidate = str(candidate_path)
        initial_candidate_hash = hashlib.sha256(candidate_path.read_bytes()).hexdigest()
    artifacts = None
    if args.gfortran:
        artifacts = Path(args.artifacts).resolve() if args.artifacts else Path(tempfile.mkdtemp(prefix='timing-oracles-'))
        artifacts.mkdir(parents=True, exist_ok=True)
    records = []
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        if not re.search(args.only, case['name']):
            continue
        source = ROOT/case['source']
        row = dict(case=case, errors=[])
        if hashlib.sha256(source.read_bytes()).hexdigest() != initial_sources[case['source']]:
            raise ValueError('source changed before execution: '+case['source'])
        if args.gfortran:
            if case['baseline'] == 'skip':
                row['gnu_skipped'] = True
            else:
                with contextlib.nullcontext(tempfile.mkdtemp(prefix=case['name']+'-', dir=artifacts)) as folder:
                    binary = Path(folder)/'reference'
                    compiled = execute([args.gfortran, '-std=f2018', '-pedantic-errors',
                                        '-fcheck=all', '-O0', source, '-o', binary], folder)
                    row['gnu_compile'] = compiled
                    row['errors'] += gnu_compile_errors(case, compiled)
                    if case['baseline'] == 'reject' or compiled['code'] != 0:
                        pass
                    elif case['baseline'] == 'runtime':
                        ran = execute([binary], folder)
                        row['gnu_run'] = ran
                        if ran['code'] != case.get('gnu_exit',2) or not ran['err'].strip() or not compare(ran['out'], case['expected_stdout']):
                            row['errors'].append('GNU runtime rejection/output mismatch')
                        if case.get('gnu_diagnostic',case.get('diagnostic','')).lower() not in ran['err'].lower():
                            row['errors'].append('GNU runtime diagnostic mismatch')
                    elif case['baseline'] == 'observe':
                        ran = execute([binary], folder)
                        row['gnu_observation'] = ran
                        row['errors'] += observe_cpu(ran)
                    elif case['baseline'] == 'run':
                        ran = execute([binary], folder)
                        row['gnu_run'] = ran
                        row['errors'] += gnu_success_errors(case, ran)
        if args.candidate:
            checked = execute([args.candidate, '--check', source])
            ran = execute([args.candidate]+case.get('args', [])+[source])
            row['check'], row['run'] = checked, ran
            row['errors'] += candidate_errors(case, checked, ran)
        if hashlib.sha256(source.read_bytes()).hexdigest() != initial_sources[case['source']]:
            row['errors'].append('source changed during execution')
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
        summary['gnu_environment_observations'] = sum('gnu_observation' in row for row in records)
        summary['gnu_compile_only'] = sum(row['case']['baseline'] == 'compile' for row in records)
        summary['gnu_rejections'] = sum(row['case']['baseline'] == 'reject' for row in records)
        summary['specification_only'] = sum('oracle' in row['case'] for row in records)
    result = dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  summary=summary, records=records, platform=platform.platform(),
                  python_version=platform.python_version(),
                  manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
                  source_sha256={row['case']['source']: hashlib.sha256((ROOT/row['case']['source']).read_bytes()).hexdigest()
                                 for row in records})
    if args.gfortran:
        result['gfortran_version'] = execute([args.gfortran, '--version'])
    if args.candidate:
        result['candidate_version'] = execute([args.candidate, '--version'])
        result['candidate_sha256'] = initial_candidate_hash
        try:
            final_hash = hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
        except OSError:
            final_hash = None
        result['candidate_final_sha256'] = final_hash
        if final_hash != initial_candidate_hash:
            result['candidate_changed_during_run'] = True
            summary['failed'] += 1
            print('FAIL: candidate executable changed during verification')
    if validate_sources() != initial_sources:
        raise ValueError('source inventory changed during verification')
    (ROOT/args.result).write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(summary, indent=2))
    return bool(summary['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
