#!/usr/bin/env python3
"""Verify original str_int provenance and optionally run GNU/candidate oracles.

Candidate execution needs REPEAT, literal substrings and bare DO. By default
only GNU is required by the standalone REPEAT verifier; the combined release
must also supply --candidate. No source body is rewritten for either backend.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import shutil
import subprocess
import tempfile
ROOT=Path(__file__).resolve().parent

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def execute(argv,cwd):
    try:
        p=subprocess.run([str(x) for x in argv],cwd=cwd,capture_output=True,text=True,
                         timeout=30,stdin=subprocess.DEVNULL)
        return dict(code=p.returncode,out=p.stdout,err=p.stderr)
    except subprocess.TimeoutExpired:
        return dict(code=None,out='',err='Timed out after 30 seconds')

def verify_provenance():
    data=json.loads((ROOT/'original-source-map.json').read_text())
    source=ROOT/data['source']
    assert digest(source)==data['source_sha256'],'Original xutilities source changed'
    lines=source.read_bytes().splitlines(keepends=True)
    for routine in data['routines']:
        body=b''.join(lines[routine['first_line']-1:routine['last_line']])
        assert hashlib.sha256(body).hexdigest()==routine['byte_sha256'],'Original body bytes changed'
        assert hashlib.sha256(body.replace(b'\r\n',b'\n')).hexdigest()==routine['normalized_sha256'],'Body evidence changed'
        fixture=(ROOT/routine['fixture']).read_bytes()
        assert fixture.count(body)==1,'Original routine body missing, changed or duplicated'
    return data

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--candidate'); ap.add_argument('--gfortran')
    ap.add_argument('--expect-blocker',help='Explicitly verify an isolated-feature rejection, not success')
    ap.add_argument('--result',default='original-results.json')
    args=ap.parse_args()
    if not args.candidate and not args.gfortran:ap.error('Supply --candidate and/or --gfortran')
    if args.expect_blocker and not args.candidate:ap.error('--expect-blocker needs --candidate')
    data=verify_provenance(); fixture=ROOT/data['routines'][0]['fixture']; errors=[]
    report=dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        original_sha256=data['source_sha256'],fixture_sha256=digest(fixture),
        expected_stdout=data['expected_stdout'],provenance='Original body bytes verified including CRLF endings')
    with tempfile.TemporaryDirectory(prefix='str-int-oracle-') as temp:
        temp=Path(temp)
        if args.gfortran:
            compiler=Path(args.gfortran).resolve(); binary=temp/'reference'
            flags=['-std=f2018','-pedantic-errors','-fcheck=all','-O0']
            report['gnu_version']=execute([compiler,'--version'],temp)
            report['compiler_flags']=flags
            compiled=execute([compiler,*flags,fixture,'-o',binary],temp); report['gnu_compile']=compiled
            if compiled['code']!=0:errors.append('GNU compile failed')
            else:
                ran=execute([binary],temp); report['gnu_run']=ran
                if ran['code']!=0 or ran['err'] or ran['out']!=data['expected_stdout']:
                    errors.append('GNU execution or exact output mismatch')
        if args.candidate:
            original=Path(args.candidate).resolve(); candidate=temp/'candidate'; shutil.copy2(original,candidate)
            report['candidate_path']=str(original); report['candidate_sha256']=digest(candidate)
            report['candidate_version']=execute([candidate,'--version'],temp)
            checked=execute([candidate,'--check',fixture],temp); ran=execute([candidate,fixture],temp)
            report['candidate_check']=checked; report['candidate_run']=ran
            if args.expect_blocker:
                report['candidate_expected_blocker']=args.expect_blocker
                if checked['code']!=1 or ran['code']!=1 or checked['out'] or ran['out'] or args.expect_blocker not in ran['err']:
                    errors.append('Isolated candidate blocker changed')
            elif checked['code']!=0 or checked['out'] or checked['err'] or ran['code']!=0 or ran['err'] or ran['out']!=data['expected_stdout']:
                errors.append('Candidate execution or exact output mismatch')
    report['errors']=errors; (ROOT/args.result).write_text(json.dumps(report,indent=2)+'\n')
    print('Original str_int: '+('FAIL '+', '.join(errors) if errors else 'PASS'))
    return bool(errors)
if __name__=='__main__':raise SystemExit(main())
