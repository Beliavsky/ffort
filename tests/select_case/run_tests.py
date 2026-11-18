#!/usr/bin/env python3
"""SELECT CASE, CHARACTER and array PARAMETER differential tests."""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import math
import re
import shutil
import subprocess
import tempfile
ROOT=Path(__file__).resolve().parent

def execute(argv,cwd=None):
    try:
        ran=subprocess.run([str(a) for a in argv],cwd=cwd or ROOT,text=True,capture_output=True,timeout=20,stdin=subprocess.DEVNULL)
        return dict(code=ran.returncode,out=ran.stdout,err=ran.stderr)
    except subprocess.TimeoutExpired as exc:
        return dict(code=None,out='',err='TIMEOUT '+str(exc))
    except OSError as exc:
        return dict(code=None,out='',err=str(exc))

def number(token):
    return float(token.replace('D','E').replace('d','e'))

def compare(actual,expected,rel_tol=2e-6,abs_tol=1e-7):
    actual,expected=actual.split(),expected.split()
    if len(actual)!=len(expected): return False
    for got,want in zip(actual,expected):
        if want=='R':
            try: value=number(got)
            except ValueError: return False
            if not math.isfinite(value) or not 0<=value<1: return False
            continue
        try: a,b=number(got),number(want)
        except ValueError:
            if got!=want:return False
        else:
            if not math.isfinite(a):return False
            if re.fullmatch(r'[+-]?\d+',want):
                if a!=int(want):return False
            elif not math.isclose(a,b,rel_tol=rel_tol,abs_tol=abs_tol):return False
    return True

def output_errors(case,output):
    if case.get('exact_stdout') and output != case['expected_stdout']:
        return ['exact formatted stdout mismatch']
    if case.get('statistics'):
        try: values=list(map(number,output.split()))
        except ValueError:return ['nonnumeric random sample']
        n=case['statistics']
        if len(values)!=n:return ['wrong random sample count']
        if not all(math.isfinite(v) and 0<=v<1 for v in values):return ['random sample outside [0,1)']
        avg=sum(values)/n
        var=sum((v-avg)**2 for v in values)/n
        bins=[sum(i/4<=v<(i+1)/4 for v in values) for i in range(4)]
        # Deliberately loose smoke checks, not proof of randomness or a stringent
        # statistical hypothesis test. No GNU/candidate sequence comparison.
        if not .4<avg<.6:return ['random mean outside loose sanity envelope']
        if not .04<var<.12:return ['random variance outside loose sanity envelope']
        if min(bins)<=n/16:return ['random quartile coverage failure']
        if len(set(values))<=n/4:return ['random diversity failure']
    elif not compare(output,case['expected_stdout'],case.get('rel_tol',2e-6),case.get('abs_tol',1e-7)):
        return ['stdout mismatch/leak']
    if case.get('distinct_halves'):
        vals=output.split()
        if vals[:len(vals)//2]==vals[len(vals)//2:]:return ['successive random calls did not advance']
    return []

def candidate_errors(case,check,ran):
    category=case['category']; errors=[]
    expected_check=0 if category in ('success','runtime') else 1
    expected_run=0 if category=='success' else 2 if category=='runtime' else 1
    for label,result,code in [('check',check,expected_check),('run',ran,expected_run)]:
        if result['code']!=code:errors.append(f'{label} expected exit {code}, got {result["code"]}')
        if code and not result['err'].strip():errors.append(label+': missing diagnostic')
        if not code and result['err'].strip():errors.append(label+': unexpected success diagnostic')
    if check['out'].strip():errors.append('check stdout leak')
    errors+=output_errors(case,ran['out'])
    if case.get('diagnostic'):
        diagnostic='\n'.join(re.sub(r'^.*?:\d+:\d+:','',line) for line in ran['err'].splitlines())
        if case['diagnostic'].lower() not in diagnostic.lower():errors.append('missing diagnostic '+case['diagnostic'])
    return errors

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--candidate');ap.add_argument('--gfortran')
    ap.add_argument('--only',default='');ap.add_argument('--result',default='results.json')
    args=ap.parse_args()
    if not args.candidate and not args.gfortran:ap.error('Supply --candidate and/or --gfortran')
    original_candidate=args.candidate
    snapshot=None
    if args.candidate:
        snapshot=tempfile.TemporaryDirectory(prefix='mean-candidate-')
        selected=Path(args.candidate).resolve()
        copied=Path(snapshot.name)/selected.name
        shutil.copy2(selected,copied)
        args.candidate=str(copied)
    versions={k:dict(path=original_candidate if k=='candidate' else v,version=execute([v,'--version'])) for k,v in [('candidate',args.candidate),('gfortran',args.gfortran)] if v}
    records=[]
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        if not re.search(args.only,case['name']):continue
        source=ROOT/case['source'];row=dict(case=case,errors=[])
        if args.gfortran:
            if case['baseline']=='skip':row['gnu_skipped']=True
            else:
                with tempfile.TemporaryDirectory(prefix='mean-oracle-') as folder:
                    binary=Path(folder)/'reference'
                    compiled=execute([args.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',source,'-o',binary],folder)
                    row['gnu_compile']=compiled
                    if case['baseline']=='reject':
                        if compiled['code']!=1:row['errors'].append('GNU did not cleanly reject')
                    elif compiled['code']!=0:row['errors'].append('GNU compile failed')
                    elif case['baseline']=='run':
                        ran=execute([binary],folder);row['gnu_run']=ran
                        if ran['code']!=0:row['errors'].append('GNU execution failed')
                        row['errors'] += ['GNU '+err for err in output_errors(case,ran['out'])]
        if args.candidate:
            checked=execute([args.candidate,'--check',source]);ran=execute([args.candidate]+case.get('args',[])+[source])
            row['check'],row['run']=checked,ran
            row['errors']+=candidate_errors(case,checked,ran)
            if case.get('repeatable'):
                repeat=execute([args.candidate]+case.get('args',[])+[source]);row['repeat']=repeat
                if repeat['code']!=0 or repeat['out']!=ran['out'] or repeat['err']!=ran['err']:
                    row['errors'].append('documented per-execution RNG repeatability failed')
        status='FAIL '+', '.join(row['errors']) if row['errors'] else 'PASS'
        if row.get('gnu_skipped') and not args.candidate:status='SKIP (interpreter safety policy, no GNU oracle)'
        print(case['name']+': '+status,flush=True);records.append(row)
    if not records:ap.error('No cases selected')
    if args.candidate:
        streams={}
        for row in records:
            case=row['case']
            if not case.get('stream_group') or row['errors']:continue
            group=case['stream_group'];tokens=row['run']['out'].split()
            restored=[None]*len(tokens)
            for value,offset in zip(tokens,case['stream_order']):restored[offset]=value
            if group not in streams:streams[group]=restored
            elif streams[group]!=restored:
                row['errors'].append('candidate RNG traversal/empty/type-inquiry stream mismatch')
                print(case['name']+': FAIL metamorphic RNG stream mismatch',flush=True)
    summary=dict(total=len(records),failed=sum(bool(r['errors']) for r in records))
    if args.candidate:summary['candidate_checked']=len(records)
    if args.gfortran:
        summary.update(gnu_checked=sum(not r.get('gnu_skipped',False) for r in records),
            gnu_skipped=sum(r.get('gnu_skipped',False) for r in records),
            gnu_executed=sum('gnu_run' in r for r in records),
            gnu_compile_only=sum(r['case']['baseline']=='compile' for r in records),
            gnu_compile_rejections=sum(r['case']['baseline']=='reject' for r in records))
    report=dict(tools=versions,summary=summary,records=records,
        utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        compiler_flags=['-std=f2018','-pedantic-errors','-fcheck=all','-O0'],
        limits='RNG checks compare contracts, not GNU sequences. Loose statistical smoke tests are not randomness proofs. Repeatability checks apply only to the documented interpreter seed reset. No-argument RANDOM_SEED is supported; SIZE/PUT/GET remain unsupported.',
        manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
        source_sha256={r['case']['source']:hashlib.sha256((ROOT/r['case']['source']).read_bytes()).hexdigest() for r in records})
    if args.candidate:report['candidate_sha256']=hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
    (ROOT/args.result).write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
    if snapshot:snapshot.cleanup()
    return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
