#!/usr/bin/env python3
"""Run independent date regressions against the interpreter and GNU Fortran."""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
FLAGS = ['-std=f2018', '-pedantic-errors', '-fcheck=all', '-O0']


def execute(argv, cwd=None):
    try:
        result = subprocess.run([str(a) for a in argv], cwd=cwd or ROOT,
                                text=True, capture_output=True, timeout=25,
                                stdin=subprocess.DEVNULL)
        return dict(code=result.returncode, out=result.stdout, err=result.stderr)
    except (OSError, subprocess.TimeoutExpired) as error:
        return dict(code=None, out='', err=str(error))


def run_errors(case, result):
    errors = []
    if result['code'] != 0:
        errors.append(f"expected normal termination, got {result['code']}")
    if result['out'] != case['expected_stdout']:
        errors.append('stdout mismatch or output after STOP')
    if case['stop']:
        if case['stop'] not in result['err']:
            errors.append('missing STOP message')
    elif result['err'].strip():
        errors.append('unexpected stderr')
    return errors


def check_errors(result):
    errors = []
    if result['code'] != 0:
        errors.append('valid source rejected during --check')
    if result['out'] or result['err']:
        errors.append('--check leaked output')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate')
    parser.add_argument('--gfortran')
    parser.add_argument('--only', default='')
    parser.add_argument('--result', default='results.json')
    args = parser.parse_args()
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran')
    cases = [case for case in json.loads((ROOT/'manifest.json').read_text())['cases']
             if re.search(args.only, case['name'])]
    if not cases:
        parser.error('No cases selected')
    records = []
    with tempfile.TemporaryDirectory(prefix='date-candidate-') as snapshot:
        candidate = None
        if args.candidate:
            candidate = Path(snapshot)/Path(args.candidate).name
            shutil.copy2(Path(args.candidate).resolve(), candidate)
        for case in cases:
            source = ROOT/case['source']
            record = dict(case=case, errors=[])
            if args.gfortran:
                with tempfile.TemporaryDirectory(prefix='date-oracle-') as folder:
                    binary = Path(folder)/'oracle'
                    built = execute([args.gfortran]+FLAGS+[source, '-o', binary],folder)
                    record['gnu_compile'] = built
                    if built['code'] != 0:
                        record['errors'].append('GNU compile failed')
                    else:
                        run = execute([binary],folder)
                        record['gnu_run'] = run
                        record['errors'] += ['GNU: '+s for s in run_errors(case,run)]
            if candidate:
                checked = execute([candidate,'--check',source])
                run = execute([candidate,source])
                record['check'], record['run'] = checked, run
                record['errors'] += check_errors(checked)+run_errors(case,run)
            status = 'FAIL '+', '.join(record['errors']) if record['errors'] else 'PASS'
            print(case['name']+': '+status,flush=True)
            records.append(record)
        summary = dict(total=len(records),failed=sum(bool(r['errors']) for r in records))
        if candidate: summary['candidate_checked'] = len(records)
        if args.gfortran:
            summary.update(gnu_checked=len(records),gnu_executed=sum('gnu_run' in r for r in records),
                           gnu_skipped=0,gnu_compile_only=0,gnu_compile_rejections=0)
        report = dict(summary=summary,records=records,compiler_flags=FLAGS,
                      utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                      manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
                      source_sha256={c['source']:hashlib.sha256((ROOT/c['source']).read_bytes()).hexdigest() for c in cases},
                      tools={name:dict(path=path,version=execute([path,'--version']))
                             for name,path in [('candidate',args.candidate),('gfortran',args.gfortran)] if path})
        if candidate: report['candidate_sha256'] = hashlib.sha256(candidate.read_bytes()).hexdigest()
        (ROOT/args.result).write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
    return bool(summary['failed'])


if __name__ == '__main__':
    raise SystemExit(main())
