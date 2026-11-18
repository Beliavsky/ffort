#!/usr/bin/env python3
"""Strict bounded release038 integration checks; candidate snapshot mandatory."""
from pathlib import Path
from decimal import Decimal,InvalidOperation,localcontext
from contextlib import ExitStack
import argparse,datetime,hashlib,json,math,os,re,shutil,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all,no-array-temps','-ffpe-trap=invalid,zero,overflow','-O0']
ORIGINALS={'original/demo_associated.f90':(529,'1e0128c3c5a5d8ec3b7aa153c46848a1d72a7cda50aa885398f43e177e4d800f'),'original/demo_cshift.f90':(857,'86868f08e1dc9d4b533e4b170734d02d6006642397486ce4160420b08eaf2fbd'),'original/demo_erfc_scaled.f90':(172,'5ef51f96c838eb70a0c957526bf636032600c67d504a17faf42837ca479563e0')}
LICENSE='5bc2186f9c1ed8a9555dc8bd396ff19672e5a9bd35cb06cf16f996856667a96b'
def digest(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def execute(argv,cwd):
    argv=list(map(str,argv))
    try:
        p=subprocess.run(argv,cwd=cwd,stdin=subprocess.DEVNULL,capture_output=True,timeout=30)
        return dict(code=p.returncode,out=p.stdout.decode('utf8','surrogateescape'),err=p.stderr.decode('utf8','surrogateescape'),argv=argv)
    except (OSError,subprocess.TimeoutExpired) as e:return dict(code=None,out='',err=type(e).__name__+': '+str(e),argv=argv)
def crash(r):return r['code'] is None or r['code']<0 or bool(re.search(r'Fortran runtime error:|Backtrace:|Segmentation fault|SIGSEGV|internal compiler error',r['err'],re.I))
def numeric_errors(out,refs):
    tok=out.split()
    if len(tok)!=len(refs):return ['numeric count/order mismatch']
    errors=[]
    with localcontext() as ctx:
        ctx.prec=160
        for i,(t,r) in enumerate(zip(tok,refs)):
            try:v=Decimal(t.replace('D','E').replace('d','e'))
            except InvalidOperation:errors.append('invalid numeric token '+str(i));continue
            want=Decimal(r['value']);ulp=Decimal(r['ulp']);budget=Decimal(r['max_ulp'])
            if not v.is_finite():errors.append('nonfinite token '+str(i));continue
            if want!=0 and v==0:errors.append('nonzero reference became zero '+str(i));continue
            if abs(v-want)>ulp*budget:errors.append('fixed ULP error '+str(i))
    return errors
def numeric_differential(actual,reference,refs):
    a,b=actual.split(),reference.split()
    if len(a)!=len(refs) or len(b)!=len(refs):return False
    with localcontext() as ctx:
        ctx.prec=160
        for x,y,r in zip(a,b,refs):
            try:x,y=Decimal(x.replace('D','E').replace('d','e')),Decimal(y.replace('D','E').replace('d','e'))
            except InvalidOperation:return False
            if not x.is_finite() or not y.is_finite() or abs(x-y)>Decimal(r['ulp'])*r['max_ulp']:return False
    return True
def output_errors(c,out,gnu=False):
    if c.get('numeric'):return numeric_errors(out,c['numeric'])
    wanted=c.get('gnu_expected',c['expected']) if gnu else c['expected']
    return [] if out==wanted else ['stdout mismatch']
def validate(c):
    if c['category'] not in ('success','runtime','reject') or c['gnu'] not in ('run','compile','reject'):raise ValueError('unknown category')
    if c['category']!='success' and (not c['diagnostic'] or c.get('numeric')):raise ValueError('failure needs exact output and diagnostic')
    if c['category']=='runtime' and c['gnu']=='run':raise ValueError('unsafe GNU runtime')
    if c['category']=='reject' and c['expected']:raise ValueError('reject output')
    if c['gnu']=='compile' and not c['note']:raise ValueError('compile-only scope note required')
    for r in c.get('numeric',[]):
        if r['kind'] not in (4,8) or r['max_ulp']!={4:2,8:4}[r['kind']]:raise ValueError('unapproved numeric budget')
        if not Decimal(r['value']).is_finite() or Decimal(r['ulp'])<=0:raise ValueError('invalid oracle')
def provenance(root=ROOT):
    m=json.loads((root/'original-source-map.json').read_text())
    if {c['source'] for c in m['originals']}!=set(ORIGINALS) or len(m['originals'])!=3:raise ValueError('original source set changed')
    for c in m['originals']:
        b=(root/c['source']).read_bytes();pin=ORIGINALS[c['source']]
        if (len(b),hashlib.sha256(b).hexdigest())!=pin or (c['bytes'],c['sha256'])!=pin or c['upstream_commit']!='fc14233036d910e3678d350efc24609e11475067':raise ValueError('original bytes/provenance changed')
    if m['license']['path']!='original/LICENSE' or m['license']['sha256']!=LICENSE or digest(root/'original/LICENSE')!=LICENSE:raise ValueError('license changed')
    return m
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
    prov=provenance();syn=json.loads((ROOT/'synthetic-manifest.json').read_text());cases=[c for c in syn['cases']+prov['originals'] if re.search(a.only,c['name'])]
    if not cases:ap.error('empty selection')
    for c in cases:validate(c)
    pins={p:digest(ROOT/p) for p in ['synthetic-manifest.json','original-source-map.json',*[c['source'] for c in cases]]}
    for c in cases:
        if pins[c['source']]!=c['sha256']:raise ValueError('fixture changed '+c['source'])
    tools={};rows=[]
    with ExitStack() as stack:
        cand=None
        if a.candidate:
            src=Path(a.candidate).resolve(strict=True);folder=Path(stack.enter_context(tempfile.TemporaryDirectory(prefix='release038-frozen-')));cand=folder/'candidate';h=snapshot(src,cand)
            tools['candidate']=dict(path=str(src),sha256=h,version=execute([cand,'--version'],folder))
        compiler=shutil.which(a.gfortran) if a.gfortran else None
        if a.gfortran and not compiler:ap.error('GNU not found')
        if compiler:tools['gfortran']=dict(path=compiler,version=execute([compiler,'--version'],ROOT))
        for t in tools.values():
            v=t['version']
            if v['code']!=0 or v['err'] or not v['out'].strip():raise ValueError('tool version probe failed')
        for c in cases:
            row=dict(name=c['name'],case=c,errors=[])
            with tempfile.TemporaryDirectory(prefix='release038-case-') as temp:
                folder=Path(temp);src=folder/(c['name']+'.f90');src.write_bytes((ROOT/c['source']).read_bytes())
                if compiler:
                    binary=folder/'gnu';comp=execute([compiler,*FLAGS,src,'-o',binary],folder);row['gnu_compile']=comp
                    want=1 if c['gnu']=='reject' else 0
                    if crash(comp) or comp['code']!=want or comp['out'] or (want and not comp['err'].strip()) or (not want and comp['err']):row['errors'].append('GNU compile status/diagnostic')
                    if comp['code']==0 and c['gnu']=='run':
                        r=execute([binary],folder);row['gnu_run']=r
                        if crash(r) or r['code']!=0 or r['err']:row['errors'].append('GNU runtime status/diagnostic')
                        row['errors']+=['GNU '+s for s in output_errors(c,r['out'],True)]
                if cand:
                    ck=execute([cand,'--check',src],folder);r=execute([cand,src],folder);row.update(check=ck,run=r);row['errors']+=candidate_errors(c,ck,r)
                    if 'gnu_run' in row and c['category']=='success' and not c.get('gnu_expected'):
                        if c.get('numeric'):
                            if not numeric_differential(r['out'],row['gnu_run']['out'],c['numeric']):row['errors'].append('fixed ULP GNU differential mismatch')
                        elif r['out']!=row['gnu_run']['out']:row['errors'].append('strict GNU differential mismatch')
            rows.append(row);print(c['name']+': '+('FAIL '+str(row['errors']) if row['errors'] else 'PASS'),flush=True)
        integrity=[]
        for p,h in pins.items():
            if digest(ROOT/p)!=h:integrity.append('changed '+p)
        provenance()
        if cand and digest(cand)!=tools['candidate']['sha256']:integrity.append('changed executable snapshot')
        summary=dict(total=len(rows),failed=sum(bool(r['errors']) for r in rows),integrity_failed=len(integrity),candidate_checked=len(rows) if cand else 0,gnu_executed=sum('gnu_run' in r for r in rows),gnu_compile_only=sum(c['gnu']=='compile' for c in cases) if compiler else 0,gnu_rejected=sum(c['gnu']=='reject' for c in cases) if compiler else 0)
        (ROOT/a.result).write_text(json.dumps(dict(summary=summary,tools=tools,records=rows,integrity_errors=integrity,source_pins=pins,flags=FLAGS,utc=datetime.datetime.now(datetime.timezone.utc).isoformat()),indent=2)+'\n');print(json.dumps(summary));return bool(summary['failed'] or integrity)
if __name__=='__main__':raise SystemExit(main())
