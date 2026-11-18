#!/usr/bin/env python3
"""Bounded numeric-model inquiries: GNU differential and fail-closed cases."""
import argparse, hashlib, json, math, re, subprocess, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parent

def run(cmd, cwd):
    p = subprocess.run([str(x) for x in cmd], cwd=cwd, text=True, capture_output=True, timeout=30)
    return dict(status=p.returncode, stdout=p.stdout, stderr=p.stderr)

def equal(a, b):
    a = a.lower().replace('d','e').split(); b = b.lower().replace('d','e').split()
    if len(a) != len(b): return False
    for x,y in zip(a,b):
        if re.fullmatch(r'[+-]?\d+',x) and re.fullmatch(r'[+-]?\d+',y):
            if int(x) != int(y): return False
            continue
        try:
            if not math.isclose(float(x),float(y),rel_tol=1e-14,abs_tol=0.0): return False
        except ValueError:
            if x != y: return False
    return True

def main():
    p=argparse.ArgumentParser(); p.add_argument('--candidate',type=Path,required=True)
    p.add_argument('--gfortran',default='gfortran'); p.add_argument('--result',default='results.json')
    p.add_argument('--original-dir',type=Path,default=ROOT/'original')
    a=p.parse_args(); a.candidate=a.candidate.resolve()
    cases=[]
    for name in ('scalars','arrays','descriptors','no_evaluation','composition','shadowing'):
        cases.append((name,(ROOT/(name+'.f90')).read_text(),'pass',''))
    for op in ('epsilon','radix','tiny','huge'):
        for label,args,diagnostic in (
            ('empty','','requires one X'),('excess','1.0,2.0','requires one X'),
            ('logical','.true.','requires'),('character',"'a'",'requires'),
            ('keyword','a=1.0','Unknown keyword'),('duplicate','x=1.0,x=2.0','Repeated actual'),
            ('after_keyword','x=1.0,2.0','Positional argument'),('kind_keyword','1.0,kind=8','Unknown keyword')):
            cases.append((op+'_'+label,'program p\nprint *,'+op+'('+args+')\nend program\n','reject',diagnostic))
        for label,arg in (('real16','1.0_16'),('integer2','1_2')):
            if op in ('epsilon','tiny') and label=='integer2': continue
            cases.append((op+'_'+label,'program p\nprint *,'+op+'('+arg+')\nend program\n','unsupported',''))
    for op in ('epsilon','tiny'):
        cases.append((op+'_integer','program p\nprint *,'+op+'(1)\nend program\n','reject','requires REAL'))
    component_prefix='module types\nimplicit none\ntype :: item\nreal(8)::x\ninteger::i\nend type\nend module\nprogram p\nuse types\nimplicit none\ntype(item)::v\nreal(8)::a(2)\nprint *,999\nprint *,'
    for op in ('epsilon','tiny','huge','radix'):
        for label,operand in (('direct','v%x'),('arithmetic','v%x+1d0'),('call','sqrt(v%x)'),('constructor','[v%x,1d0]'),('subscript','a(v%i)')):
            cases.append((op+'_component_'+label,component_prefix+op+'('+operand+')\nend program\n','unsupported','component operands are unsupported'))
    provenance=json.loads((ROOT/'original-provenance.json').read_text())
    for item in provenance['files']:
        if hashlib.sha256((ROOT/item['file']).read_bytes()).hexdigest()!=item['sha256']:
            raise AssertionError('Original source changed: '+item['file'])
    if hashlib.sha256((ROOT/provenance['license']).read_bytes()).hexdigest()!=provenance['license_sha256']:
        raise AssertionError('Original license changed')
    originals=[]
    if a.original_dir:
        for name in ('demo_floor','demo_radix','demo_tiny'):
            path=a.original_dir/(name+'.f90'); raw=path.read_bytes()
            expected_hash=next(item['sha256'] for item in provenance['files'] if item['file']=='original/'+path.name)
            if hashlib.sha256(raw).hexdigest()!=expected_hash:
                raise AssertionError('External original source changed: '+str(path))
            originals.append(dict(name=name,sha256=hashlib.sha256(raw).hexdigest(),source=str(path)))
            cases.append((name,raw.decode(),'pass',''))
    results=[]
    with tempfile.TemporaryDirectory(prefix='numeric-model-') as td:
        tmp=Path(td)
        for name,source,expected,diagnostic in cases:
            src=tmp/(name+'.f90'); src.write_text(source); exe=tmp/'oracle'
            g=run([a.gfortran,'-std=f2018','-fcheck=all',src,'-o',exe],tmp)
            o=run([exe],tmp) if g['status']==0 and expected=='pass' else None
            c=run([a.candidate,'--check',src],tmp); r=run([a.candidate,src],tmp)
            if expected=='pass':
                ok=g['status']==0 and o['status']==0 and c['status']==0 and not c['stdout'] and not c['stderr'] and r['status']==0 and not r['stderr'] and equal(r['stdout'],o['stdout'])
            else:
                ok=(g['status']!=0 if expected=='reject' else g['status']==0) and c['status']==1 and r['status']==1 and not c['stdout'] and not r['stdout'] and diagnostic in c['stderr'] and diagnostic in r['stderr']
            results.append(dict(name=name,expected=expected,pass_=ok,gfortran=g,oracle=o,check=c,candidate=r))
            print(('PASS' if ok else 'FAIL')+': '+name,flush=True)
    result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),total=len(results),failed=sum(not c['pass_'] for c in results),originals=originals,cases=results)
    out=Path(a.result); out=out if out.is_absolute() else ROOT/out
    out.write_text(json.dumps(result,indent=2)+'\n')
    print('Total:',result['total'],'failed:',result['failed']); return bool(result['failed'])
if __name__=='__main__': raise SystemExit(main())
