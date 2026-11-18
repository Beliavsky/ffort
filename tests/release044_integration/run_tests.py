#!/usr/bin/env python3
"""Release044 composition: exact text/Decimal output, never an amplitude tolerance."""
from pathlib import Path
from decimal import Decimal,InvalidOperation
from contextlib import ExitStack
import argparse,datetime,hashlib,json,os,re,shutil,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
FLAGS=['-std=f2023','-pedantic-errors','-fcheck=all,no-array-temps','-ffpe-trap=invalid,zero,overflow','-O0']
MANIFEST_SHA256='06a56407e65170e7ecaef9e5f74ae31f4266252d0bf4c9a04e1b75bb330ba58d' # Fixed before final execution.
TOKEN=re.compile(r'[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eEdD][+-]?[0-9]+)?\Z')
def digest(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def execute(argv,cwd):
    argv=list(map(str,argv))
    try:
        p=subprocess.run(argv,cwd=cwd,stdin=subprocess.DEVNULL,capture_output=True,timeout=120)
        return dict(code=p.returncode,out=p.stdout.decode('utf8','surrogateescape'),err=p.stderr.decode('utf8','surrogateescape'),argv=argv)
    except (OSError,subprocess.TimeoutExpired) as e:return dict(code=None,out='',err=type(e).__name__+': '+str(e),argv=argv)
def crash(r):return r['code'] is None or r['code']<0 or bool(re.search(r'Fortran runtime error:|Backtrace:|Segmentation fault|SIGSEGV|internal compiler error',r['err'],re.I))
def exact_numeric(actual,expected):
    tokens=actual.split()
    if len(tokens)!=len(expected):return False
    for a,b in zip(tokens,expected):
        if not TOKEN.fullmatch(a) or not TOKEN.fullmatch(b):return False
        try:a,b=Decimal(a.replace('D','e').replace('d','e')),Decimal(b.replace('D','e').replace('d','e'))
        except InvalidOperation:return False
        if not a.is_finite() or not b.is_finite() or a!=b:return False
        if a.is_zero() and a.is_signed()!=b.is_signed():return False
    return True
def output_errors(c,out):
    if 'numeric' in c:return [] if exact_numeric(out,c['numeric']) else ['exact Decimal/signed-zero mismatch']
    return [] if out==c['expected'] else ['exact stdout mismatch']
def validate(c):
    allowed={'name','source','sha256','category','gnu','expected','diagnostic','note','numeric','budget'}
    if set(c)-allowed:raise ValueError('unknown case fields or unapproved tolerance')
    if 'budget' in c and (type(c['budget']) is not int or not 1<=c['budget']<=50000000):raise ValueError('invalid bounded execution budget')
    if c['category'] not in ('success','runtime','reject') or c['gnu'] not in ('run','compile','reject'):raise ValueError('unknown category')
    if c['category']!='success' and (not c['diagnostic'] or 'numeric' in c):raise ValueError('failure needs exact output and diagnostic')
    if c['category']=='runtime' and c['gnu']=='run':raise ValueError('unsafe GNU runtime')
    if c['category']=='reject' and c['expected']:raise ValueError('reject output')
    if c['gnu']=='compile' and not c['note']:raise ValueError('compile-only scope note required')
    if 'numeric' in c and (not c['numeric'] or not exact_numeric(' '.join(c['numeric']),c['numeric'])):raise ValueError('invalid exact numeric reference')
    if not re.fullmatch('[a-z0-9_]+',c['name']) or c['source']!='cases/'+c['name']+'.f90':raise ValueError('invalid source path')
def provenance(root=ROOT):
    path=root/'synthetic-manifest.json'
    if MANIFEST_SHA256 and digest(path)!=MANIFEST_SHA256:raise ValueError('pinned manifest changed')
    cases=json.loads(path.read_text())['cases']
    if len({c['name'] for c in cases})!=len(cases):raise ValueError('duplicate case')
    for c in cases:
        validate(c)
        if digest(root/c['source'])!=c['sha256']:raise ValueError('source bytes changed '+c['source'])
    return cases
def candidate_errors(c,check,run):
    errors=[]
    for name,r,want in [('check',check,1 if c['category']=='reject' else 0),('run',run,dict(success=0,runtime=2,reject=1)[c['category']])]:
        if crash(r):errors.append(name+' host failure')
        if r['code']!=want:errors.append(name+' exit status')
        if (not want and r['err']) or (want and not r['err'].strip()):errors.append(name+' diagnostics')
        if want and c['diagnostic'].casefold() not in re.sub(r'(?m)^.*?:\d+:\d+:\s*','',r['err']).casefold():errors.append(name+' missing '+c['diagnostic'])
    if check['out']:errors.append('check stdout leak')
    return errors+output_errors(c,run['out'])
def snapshot(src,dst):
    before=digest(src);shutil.copy2(src,dst)
    if before!=digest(src) or before!=digest(dst) or not dst.stat().st_size or not os.access(dst,os.X_OK):raise ValueError('candidate snapshot race/empty/nonexecutable')
    return before
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--candidate');ap.add_argument('--gfortran');ap.add_argument('--only',default='');ap.add_argument('--result',default='results.json');a=ap.parse_args()
    if not(a.candidate or a.gfortran):ap.error('supply candidate and/or GNU')
    cases=[c for c in provenance() if re.search(a.only,c['name'])]
    if not cases:ap.error('empty selection')
    pins={p:digest(ROOT/p) for p in ['synthetic-manifest.json','run_tests.py',*[c['source'] for c in cases]]}
    tools={};rows=[]
    with ExitStack() as stack:
        cand=None
        if a.candidate:
            src=Path(a.candidate).resolve(strict=True);folder=Path(stack.enter_context(tempfile.TemporaryDirectory(prefix='release044-frozen-')));cand=folder/'candidate';h=snapshot(src,cand)
            tools['candidate']=dict(path=str(src),sha256=h,version=execute([cand,'--version'],folder))
        compiler=shutil.which(a.gfortran) if a.gfortran else None
        if a.gfortran and not compiler:ap.error('GNU not found')
        if compiler:tools['gfortran']=dict(path=compiler,version=execute([compiler,'--version'],ROOT))
        for t in tools.values():
            v=t['version']
            if v['code']!=0 or v['err'] or not v['out'].strip():raise ValueError('tool version probe failed')
        for c in cases:
            row=dict(name=c['name'],source_sha256=c['sha256'],case=c,errors=[])
            with tempfile.TemporaryDirectory(prefix='release044-case-') as temp:
                folder=Path(temp);src=folder/(c['name']+'.f90');src.write_bytes((ROOT/c['source']).read_bytes())
                if compiler:
                    binary=folder/'gnu';comp=execute([compiler,*FLAGS,src,'-o',binary],folder);row['gnu_compile']=comp
                    want=1 if c['gnu']=='reject' else 0
                    if crash(comp) or comp['code']!=want or comp['out'] or (want and not comp['err'].strip()) or (not want and comp['err']):row['errors'].append('GNU compile status/diagnostic')
                    if comp['code']==0 and c['gnu']=='run':
                        r=execute([binary],folder);row['gnu_run']=r
                        if crash(r) or r['code']!=0 or r['err']:row['errors'].append('GNU runtime status/diagnostic')
                        row['errors']+=['GNU '+s for s in output_errors(c,r['out'])]
                if cand:
                    ck=execute([cand,'--check',src],folder);r=execute([cand,'--max-steps',str(c.get('budget',50000000)),src],folder);row.update(check=ck,run=r);row['errors']+=candidate_errors(c,ck,r)
                    if 'gnu_run' in row and c['category']=='success':
                        matches=exact_numeric(r['out'],row['gnu_run']['out'].split()) if 'numeric' in c else r['out']==row['gnu_run']['out']
                        if not matches:row['errors'].append('strict GNU differential mismatch')
            rows.append(row);print(c['name']+': '+('FAIL '+str(row['errors']) if row['errors'] else 'PASS'),flush=True)
        integrity=['changed '+p for p,h in pins.items() if digest(ROOT/p)!=h]
        provenance()
        if cand and digest(cand)!=tools['candidate']['sha256']:integrity.append('changed executable snapshot')
        summary=dict(total=len(rows),failed=sum(bool(r['errors']) for r in rows),integrity_failed=len(integrity),candidate_checked=len(rows) if cand else 0,gnu_checked=sum('gnu_compile' in r for r in rows),gnu_skipped=sum('gnu_compile' not in r for r in rows),gnu_executed=sum('gnu_run' in r for r in rows),gnu_compile_only=sum(c['gnu']=='compile' for c in cases) if compiler else 0,gnu_compile_rejections=sum(c['gnu']=='reject' for c in cases) if compiler else 0)
        result=dict(candidate_sha256=tools.get('candidate',{}).get('sha256'),summary=summary,tools=tools,records=rows,integrity_errors=integrity,source_pins=pins,flags=FLAGS,utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
        (ROOT/a.result).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(summary));return bool(summary['failed'] or integrity)
if __name__=='__main__':raise SystemExit(main())
