#!/usr/bin/env python3
"""Evaluate a CLI interpreter independently, optionally with GNU Fortran baseline.

Contract: COMMAND source.f90 executes; COMMAND --check source.f90 checks.
Exit 0 = success, 1 = static syntax/semantic/unsupported error, 2 = runtime error.
All static checks must happen before any program output. Numeric stdout matching
allows default REAL roundoff, but output count and all text tokens are exact.
"""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import hashlib
import shutil
import json
import math
from pathlib import Path
import re
import shlex
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent
NUMERIC = re.compile(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[edED][+-]?\d+)?$')

def execute(argv, cwd=None, timeout=6):
    start = time.monotonic()
    try:
        result = subprocess.run(argv, cwd=cwd, text=True, capture_output=True, timeout=timeout, stdin=subprocess.DEVNULL)
        return dict(argv=argv, returncode=result.returncode, stdout=result.stdout[:20000], stderr=result.stderr[:20000], seconds=round(time.monotonic()-start,4), timeout=False)
    except subprocess.TimeoutExpired as error:
        def txt(value): return value.decode(errors='replace') if isinstance(value, bytes) else value or ''
        return dict(argv=argv, returncode=None, stdout=txt(error.stdout)[:20000], stderr=txt(error.stderr)[:20000], seconds=round(time.monotonic()-start,4), timeout=True)
    except OSError as error:
        return dict(argv=argv, returncode=None, stdout='', stderr=str(error), seconds=round(time.monotonic()-start,4), timeout=False)

def compare_output(actual, expected):
    a, e = actual.split(), expected.split()
    if len(a) != len(e): return False, f'Expected {len(e)} output tokens, got {len(a)}: {actual!r}'
    for i, (av, ev) in enumerate(zip(a, e)):
        if NUMERIC.fullmatch(av) and NUMERIC.fullmatch(ev):
            if re.fullmatch(r'[+-]?\d+',av) and re.fullmatch(r'[+-]?\d+',ev):
                match = int(av) == int(ev)
            else:
                af = float(av.replace('D','E').replace('d','e'))
                ef = float(ev.replace('D','E').replace('d','e'))
                match = math.isfinite(af) and (af == int(ev) if re.fullmatch(r'[+-]?\d+',ev) else math.isclose(af,ef,rel_tol=2e-6,abs_tol=1e-7))
        else:
            def boolean(v): return {'T':'T','F':'F','.true.':'T','.false.':'F'}.get(v,v)
            match = boolean(av) == boolean(ev)
        if not match: return False, f'Token {i+1}: expected {ev!r}, got {av!r}'
    return True, ''

def assess_candidate(case, command, timeout):
    source = str((ROOT/case['source']).resolve())
    checked = execute(command+['--check',source],timeout=timeout)
    ran = execute(command+[source],timeout=timeout)
    errors = []
    category = case['category']
    expected_check = 0 if category in ('success','runtime') else 1
    expected_run = 0 if category == 'success' else 2 if category == 'runtime' else 1
    for stage, result, code in [('check',checked,expected_check),('run',ran,expected_run)]:
        if result['timeout']: errors.append(f'{stage}: timed out')
        elif result['returncode'] != code: errors.append(f'{stage}: expected exit {code}, got {result["returncode"]}')
        if stage=='check' and result['stdout'].strip(): errors.append('check: produced stdout')
        if code and not (result['stdout']+result['stderr']).strip(): errors.append(f'{stage}: no diagnostic')
        if 'Traceback (most recent call last)' in result['stderr']: errors.append(f'{stage}: uncaught Python exception')
    if category not in ('success','runtime') and ran['stdout'].strip(): errors.append('run: static failure produced stdout (fail-closed violation)')
    if category=='success' and ran['returncode']==0:
        correct, why = compare_output(ran['stdout'],case['expected_stdout'])
        if not correct: errors.append(why)
        if 'expected_stdout_lines' in case and len(ran['stdout'].splitlines()) != case['expected_stdout_lines']:
            errors.append(f'Expected {case["expected_stdout_lines"]} output lines, got {len(ran["stdout"].splitlines())}')
    return dict(passed=not errors, errors=errors, check=checked, run=ran)

def assess_baseline(case, compiler, timeout):
    mode = case['baseline']
    if mode=='skip': return dict(skipped=True, reason='Interpreter safety contract is stronger than portable Fortran and GNU checking; no compiler oracle claimed.')
    with tempfile.TemporaryDirectory(prefix='fortran-reference-') as tmp:
        exe = str(Path(tmp)/'reference')
        argv=[compiler,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',str((ROOT/case['source']).resolve()),'-o',exe]
        compiled=execute(argv,cwd=tmp,timeout=timeout)
        errors=[]
        if mode=='reject':
            if compiled['returncode'] != 1: errors.append(f'Reference compiler did not cleanly reject source (exit {compiled["returncode"]})')
            return dict(passed=not errors, errors=errors, compile=compiled)
        if compiled['returncode']!=0: errors.append('Reference compiler did not compile source')
        result=dict(passed=not errors, errors=errors, compile=compiled)
        if mode=='run' and compiled['returncode']==0:
            ran=execute([exe],cwd=tmp,timeout=timeout)
            result['run']=ran
            if ran['returncode']!=0: errors.append('Reference executable failed')
            else:
                correct,why=compare_output(ran['stdout'],case['expected_stdout'])
                if not correct: errors.append(why)
                if 'expected_stdout_lines' in case and len(ran['stdout'].splitlines()) != case['expected_stdout_lines']:
                    errors.append('Reference output line count differs from oracle')
            result['passed']=not errors
        return result

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate',help='Executable/command, shell-like quoting. No shell is invoked.')
    parser.add_argument('--gfortran',help='GNU Fortran executable for independent baseline.')
    parser.add_argument('--only',help='Regex selecting case names.')
    parser.add_argument('--timeout',type=float,default=6)
    parser.add_argument('--results',type=Path,default=ROOT/'results.json')
    args=parser.parse_args()
    if not args.candidate and not args.gfortran: parser.error('Give --candidate and/or --gfortran')
    command=shlex.split(args.candidate) if args.candidate else None
    cases=json.loads((ROOT/'manifest.json').read_text())['cases']
    if args.only: cases=[c for c in cases if re.search(args.only,c['name'])]
    if not cases: parser.error('No cases match the requested selection')
    records=[]
    versions={}
    if args.gfortran: versions['gfortran']=execute([args.gfortran,'--version'])
    for case in cases:
        row=dict(case=case)
        if args.gfortran: row['baseline']=assess_baseline(case,args.gfortran,args.timeout)
        if command: row['candidate']=assess_candidate(case,command,args.timeout)
        records.append(row)
        statuses=[]
        for key in ('baseline','candidate'):
            if key not in row: continue
            result=row[key]
            status='SKIP' if result.get('skipped') else 'PASS' if result['passed'] else 'FAIL'
            statuses.append(key+':'+status)
            if status=='FAIL': statuses.append('; '.join(result['errors']))
        print(f'{case["name"]}: '+', '.join(statuses),flush=True)
    summary={}
    for key in ('baseline','candidate'):
        selected=[r for r in records if key in r]
        if not selected: continue
        summary[key]=dict(total=len(selected),passed=sum(r[key].get('passed',False) for r in selected),failed=sum(not r[key].get('passed',False) and not r[key].get('skipped',False) for r in selected),skipped=sum(r[key].get('skipped',False) for r in selected),by_category={})
        for category in sorted(set(r['case']['category'] for r in selected)):
            group=[r for r in selected if r['case']['category']==category]
            summary[key]['by_category'][category]=dict(total=len(group),passed=sum(r[key].get('passed',False) for r in group),failed=sum(not r[key].get('passed',False) and not r[key].get('skipped',False) for r in group),skipped=sum(r[key].get('skipped',False) for r in group))
    source_hashes = {c['source']:hashlib.sha256((ROOT/c['source']).read_bytes()).hexdigest() for c in cases}
    metadata = dict(recorded_utc=datetime.now(timezone.utc).isoformat(), manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(), source_sha256=source_hashes)
    if command:
        binary=shutil.which(command[0])
        if binary and Path(binary).is_file(): metadata['candidate_executable_sha256']=hashlib.sha256(Path(binary).read_bytes()).hexdigest()
    payload=dict(schema_version=1,metadata=metadata,summary=summary,versions=versions,results=records)
    args.results.parent.mkdir(parents=True,exist_ok=True)
    args.results.write_text(json.dumps(payload,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
    return 1 if any(item['failed'] for item in summary.values()) else 0
if __name__=='__main__': raise SystemExit(main())
