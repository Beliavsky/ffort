#!/usr/bin/env python3
"""Independent finite real rounding and inverse hyperbolic tests."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,subprocess,tempfile
from verify_matrix import verify_matrix
from decimal import Decimal, InvalidOperation, localcontext
ROOT=Path(__file__).resolve().parent

def execute(argv,cwd=None):
    try:
        p=subprocess.run(list(map(str,argv)),cwd=cwd or ROOT,text=True,capture_output=True,timeout=20,stdin=subprocess.DEVNULL)
        return dict(code=p.returncode,out=p.stdout,err=p.stderr)
    except (OSError,subprocess.TimeoutExpired) as exc:
        return dict(code=None,out='',err=str(exc))

def number(token):
    return Decimal(token.replace('D','E').replace('d','e'))

def compare(actual,expected,rel_tol=2e-6,abs_tol=1e-7):
    actual,expected=actual.split(),expected.split()
    if len(actual)!=len(expected): return False
    try: relative,absolute=Decimal(str(rel_tol)),Decimal(str(abs_tol))
    except InvalidOperation:return False
    if not relative.is_finite() or not absolute.is_finite() or relative<0 or absolute<0:return False
    for got,want in zip(actual,expected):
        try: a,b=number(got),number(want)
        except InvalidOperation:
            if got!=want:return False
        else:
            if not a.is_finite() or not b.is_finite():return False
            # Signed zero is observable and may not disappear through tolerance.
            if a.is_zero() and b.is_zero() and a.is_signed()!=b.is_signed():return False
            # Exact cases and integer expectations never round through binary64.
            if (relative==0 and absolute==0) or re.fullmatch(r'[+-]?\d+',want):
                if a!=b:return False
            else:
                with localcontext() as ctx:
                    ctx.prec=max(50,len(a.as_tuple().digits),len(b.as_tuple().digits))+16
                    if abs(a-b)>max(absolute,relative*max(abs(a),abs(b))):return False
    return True

def output_errors(case,output):
    if case.get('exact_stdout') and output != case['expected_stdout']:
        return ['exact formatted stdout mismatch']
    if not compare(output,case['expected_stdout'],case.get('rel_tol',2e-6),case.get('abs_tol',1e-7)):
        return ['stdout mismatch/leak']
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
    verify_matrix()
    provenance=json.loads((ROOT/'upstream.json').read_text())
    for f in provenance['files']:
        if hashlib.sha256((ROOT/f['file']).read_bytes()).hexdigest()!=f['sha256']:
            raise SystemExit('Original source bytes differ: '+f['file'])
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--candidate');ap.add_argument('--gfortran');ap.add_argument('--only',default='')
    ap.add_argument('--result',default='results.json');args=ap.parse_args()
    if not args.candidate and not args.gfortran:ap.error('Supply a candidate and/or GNU compiler')
    records=[];snapshot=None;versions={}
    if args.candidate:
        selected=Path(args.candidate).resolve();snapshot=tempfile.TemporaryDirectory(prefix='real-math-candidate-')
        copied=Path(snapshot.name)/selected.name;shutil.copy2(selected,copied);args.candidate=str(copied)
        versions['candidate']=dict(path=str(selected),version=execute([copied,'--version']))
    if args.gfortran:versions['gfortran']=dict(path=args.gfortran,version=execute([args.gfortran,'--version']))
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        if not re.search(args.only,case['name']):continue
        src=ROOT/case['source'];row=dict(case=case,errors=[])
        if args.gfortran:
            with tempfile.TemporaryDirectory(prefix='real-math-oracle-') as cwd:
                exe=Path(cwd)/'reference';flags=case.get('gnu_flags',['-std=f2018','-pedantic-errors','-fcheck=all','-O0'])
                compiled=execute([args.gfortran,*flags,src,'-o',exe],cwd);row['gnu_compile']=compiled
                if case['baseline']=='reject':
                    if compiled['code']!=1:row['errors'].append('GNU did not cleanly reject')
                elif compiled['code']!=0:row['errors'].append('GNU compile failed')
                elif case['baseline']=='run':
                    ran=execute([exe],cwd);row['gnu_run']=ran
                    if ran['code']!=0 or ran['err'].strip():row['errors'].append('GNU execution failed')
                    row['errors']+=['GNU '+e for e in output_errors(case,ran['out'])]
        if args.candidate:
            checked=execute([args.candidate,'--check',src]);ran=execute([args.candidate,src])
            row['check']=checked;row['run']=ran;row['errors']+=candidate_errors(case,checked,ran)
        print(case['name']+': '+('PASS' if not row['errors'] else 'FAIL '+', '.join(row['errors'])),flush=True)
        records.append(row)
    if not records:ap.error('No cases selected')
    summary=dict(total=len(records),failed=sum(bool(r['errors']) for r in records))
    if args.candidate:summary['candidate_checked']=len(records)
    if args.gfortran:
        summary.update(gnu_checked=len(records),gnu_executed=sum('gnu_run' in r for r in records),
                       gnu_compile_only=sum(r['case']['baseline']=='compile' for r in records),
                       gnu_compile_rejections=sum(r['case']['baseline']=='reject' for r in records))
    report=dict(tools=versions,summary=summary,records=records,utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
        source_sha256={r['case']['source']:hashlib.sha256((ROOT/r['case']['source']).read_bytes()).hexdigest() for r in records})
    if args.candidate:report['candidate_sha256']=hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
    (ROOT/args.result).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(summary,indent=2))
    if snapshot:snapshot.cleanup()
    return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
