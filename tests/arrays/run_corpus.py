#!/usr/bin/env python3
"""Independent array CLI tests, using GNU Fortran only as a reference oracle."""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import shlex
import shutil
import tempfile

ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('independent_runner',ROOT.parent/'independent'/'run_corpus.py')
shared=importlib.util.module_from_spec(spec)
spec.loader.exec_module(shared)
shared.ROOT=ROOT
execute=shared.execute
compare_output=shared.compare_output

def assess_candidate(case, command, timeout):
    result=shared.assess_candidate(case,command,timeout)
    if case['category']=='runtime':
        ok,reason=compare_output(result['run']['stdout'],case['expected_stdout'])
        if not ok:
            result['errors'].append('Output before runtime failure: '+reason)
    if 'diagnostic' in case and case['diagnostic'].lower() not in result['run']['stderr'].lower():
        result['errors'].append('Missing diagnostic fragment: '+case['diagnostic'])
    result['passed']=not result['errors']
    return result

def assess_baseline(case, compiler, timeout):
    if case['baseline']=='skip' and case['category']=='success':
        return dict(skipped=True,reason=case['note'])
    if case['baseline']!='bounds_runtime':
        return shared.assess_baseline(case,compiler,timeout)
    # Bounds violations have a defined GNU -fcheck=bounds diagnostic, but neither
    # its exit code nor partial PRINT output is part of the interpreter contract.
    with tempfile.TemporaryDirectory(prefix='array-reference-') as folder:
        binary=str(Path(folder)/'reference')
        compiled=execute([compiler,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',str(ROOT/case['source']),'-o',binary],cwd=folder,timeout=timeout)
        errors=[]
        result=dict(compile=compiled,errors=errors)
        if compiled['timeout'] or compiled['returncode']!=0:
            errors.append('GNU reference did not compile bounds probe')
        else:
            ran=execute([binary],cwd=folder,timeout=timeout)
            result['run']=ran
            if ran['timeout'] or ran['returncode'] is None or ran['returncode']<=0 or 'bound' not in ran['stderr'].lower():
                errors.append('GNU reference did not report checked bounds violation')
        result['passed']=not errors
        return result

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate')
    parser.add_argument('--gfortran')
    parser.add_argument('--only')
    parser.add_argument('--timeout',type=float,default=8)
    parser.add_argument('--results',type=Path,default=ROOT/'results.json')
    args=parser.parse_args()
    if not args.candidate and not args.gfortran: parser.error('Supply candidate and/or gfortran')
    cases=json.loads((ROOT/'manifest.json').read_text())['cases']
    if args.only: cases=[case for case in cases if re.search(args.only,case['name'])]
    if not cases: parser.error('No selected cases')
    command=shlex.split(args.candidate) if args.candidate else None
    records=[]
    for case in cases:
        row=dict(case=case)
        if args.gfortran: row['baseline']=assess_baseline(case,args.gfortran,args.timeout)
        if command: row['candidate']=assess_candidate(case,command,args.timeout)
        records.append(row)
        statuses=[]
        for name in ('baseline','candidate'):
            if name not in row: continue
            result=row[name]
            status='SKIP' if result.get('skipped') else 'PASS' if result['passed'] else 'FAIL'
            statuses.append(name+':'+status)
            if status=='FAIL': statuses.extend(result['errors'])
        print(case['name']+': '+', '.join(statuses),flush=True)
    summary={}
    for name in ('baseline','candidate'):
        rows=[row for row in records if name in row]
        if not rows: continue
        def counts(group):
            return dict(total=len(group),passed=sum(bool(row[name].get('passed')) for row in group),failed=sum(not row[name].get('passed') and not row[name].get('skipped') for row in group),skipped=sum(bool(row[name].get('skipped')) for row in group))
        summary[name]=counts(rows)
        summary[name]['by_category']={category:counts([row for row in rows if row['case']['category']==category]) for category in sorted({row['case']['category'] for row in rows})}
    metadata=dict(recorded_utc=datetime.now(timezone.utc).isoformat(),manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),source_sha256={case['source']:hashlib.sha256((ROOT/case['source']).read_bytes()).hexdigest() for case in cases})
    if command:
        binary=shutil.which(command[0])
        if binary: metadata['candidate_executable_sha256']=hashlib.sha256(Path(binary).read_bytes()).hexdigest()
    payload=dict(schema_version=1,metadata=metadata,summary=summary,versions={'gfortran':execute([args.gfortran,'--version'])} if args.gfortran else {},results=records)
    args.results.parent.mkdir(parents=True,exist_ok=True)
    args.results.write_text(json.dumps(payload,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
    return int(any(item['failed'] for item in summary.values()))

if __name__=='__main__': raise SystemExit(main())
