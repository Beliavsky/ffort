#!/usr/bin/env python3
"""Optional Unix capacity benchmark with explicit address-space limits.

Run after building a chosen max_array_elements. GNU compares deterministic
outputs, not interpreter resource behavior. All test sources are generated.
The child guard avoids requesting an unbounded high-memory stress run.
"""
import argparse, hashlib, json, re, subprocess, sys, tempfile, time
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def successful_outcome(result, expected):
    """Runtime success requires the exact status and no diagnostic output."""
    return (result['status']==0 and result['stdout'].split()==expected.split()
            and result['stderr']=='')


HOST_FAILURE = re.compile(
    r'Fortran runtime error|Backtrace|Program received signal|\bSIG[A-Z0-9]+\b|'
    r'segmentation fault|fatal(?: error)?|internal compiler error|\bICE\b', re.I)
SOURCE_DIAGNOSTIC = re.compile(r'.+:[0-9]+:[0-9]+: [^\r\n]+(?:\r?\n)?')


def expected_outcome(result, code, expected, diagnostic=''):
    if code==0:
        return successful_outcome(result, expected)
    # An empty diagnostic must never make a negative probe pass vacuously.
    output_ok=(result['stdout'].split()==expected.split() if expected else result['stdout']=='')
    return (bool(diagnostic.strip()) and result['status']==code
            and output_ok
            and bool(SOURCE_DIAGNOSTIC.fullmatch(result['stderr']))
            and not HOST_FAILURE.search(result['stderr'])
            and diagnostic.lower() in result['stderr'].lower())


def child():
    import resource
    mib=int(sys.argv[2]);resource.setrlimit(resource.RLIMIT_AS,(mib*1024**2,mib*1024**2))
    start=time.perf_counter()
    p=subprocess.run(sys.argv[3:],capture_output=True,text=True,timeout=120)
    r=resource.getrusage(resource.RUSAGE_CHILDREN)
    print(json.dumps(dict(status=p.returncode,stdout=p.stdout,stderr=p.stderr,
        seconds=time.perf_counter()-start,peak_rss_kib=r.ru_maxrss,address_limit_mib=mib)))

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--candidate',required=True,type=Path)
    ap.add_argument('--gfortran',required=True)
    ap.add_argument('--limit',type=int,default=None,help='Must match the candidate build; default reads source')
    ap.add_argument('--memory-mib',type=int,default=1600)
    ap.add_argument('--result',type=Path,default=Path('capacity-profile.json'))
    a=ap.parse_args();exe=a.candidate.resolve()
    n=a.limit or int(re.search(r'max_array_elements\s*=\s*(\d+)',(ROOT/'src/fi_ir.f90').read_text()).group(1))
    if n not in (1000000,10000000):raise SystemExit('This measured profile covers 1e6 and 1e7 only')
    if a.memory_mib>1600:raise SystemExit('Refusing an unreviewed process memory limit above 1600 MiB')
    def program(decl,body,tail=''):
        return 'program p\nimplicit none\n'+decl+'\n'+body+'\n'+tail+'end program\n'
    cases=[
      ('static_storage',program(f'integer::a({n})',f'a(1)=7\na({n})=9\nprint *,size(a),a(1),a({n})'),f'{n} 7 9',a.memory_mib,0,''),
      ('staged_assignment',program(f'real(8)::a({n})','a=2.0d0\na=a+1.0d0\nprint *,int(sum(a),8)'),str(3*n),a.memory_mib,0,''),
      ('allocation_recovery',program('integer,allocatable::a(:)\ninteger::s',f'allocate(a({n}),stat=s)\nprint *,s/=0,allocated(a)'), 'T F',64,0,''),
      ('allocation_failure',program(f'integer::a({n})','print *,123'),'',64,2,'allocation'),
      ('above_limit',program(f'integer::a({n+1})','print *,123'),'',a.memory_mib,1,'limit'),
      ('tiny_forall',program('integer::a(3),i','forall(i=1:3) a(i)=i\nprint *,sum(a)'), '6',64,0,''),
      ('rank_three',program(f'integer::a(100,100,{n//10000})',f'a(100,100,{n//10000})=17\nprint *,size(a),a(100,100,{n//10000})'), f'{n} 17',a.memory_mib,0,''),
      ('pointer_alias',program(f'integer,target::a({n})\ninteger,pointer::view(:)',f'view=>a\nview({n})=23\nprint *,a({n}),size(view)'), f'23 {n}',a.memory_mib,0,'')]
    records=[]
    with tempfile.TemporaryDirectory(prefix='capacity-profile-') as tmp:
      tmp=Path(tmp)
      for name,source,expected,mib,code,diag in cases:
        path=tmp/(name+'.f90');path.write_text(source)
        command=[sys.executable,str(Path(__file__).resolve()),'--child',str(mib),str(exe),'--max-steps',str(20*n),str(path)]
        p=subprocess.run(command,capture_output=True,text=True,timeout=135)
        if p.returncode:raise RuntimeError(p.stdout+p.stderr)
        got=json.loads(p.stdout)
        ok=expected_outcome(got,code,expected,diag)
        record=dict(name=name,source=source,source_sha256=hashlib.sha256(source.encode()).hexdigest(),actual=got,passed=ok)
        if code==0 and name!='allocation_recovery':
          ref=tmp/'reference'
          c=subprocess.run([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all',str(path),'-o',str(ref)],capture_output=True,text=True,timeout=45)
          r=subprocess.run([str(ref)],capture_output=True,text=True,timeout=90) if c.returncode==0 else c
          record['gnu']=dict(status=r.returncode,stdout=r.stdout,stderr=r.stderr)
          record['passed']=ok and successful_outcome(record['gnu'],expected)
        records.append(record);print(name+': '+('PASS' if record['passed'] else 'FAIL'),flush=True)
    payload=dict(limit=n,candidate_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(),total=len(records),failed=sum(not r['passed'] for r in records),records=records)
    a.result.write_text(json.dumps(payload,indent=2)+'\n')
    return int(payload['failed']>0)

if __name__=='__main__':
    if len(sys.argv)>1 and sys.argv[1]=='--child':child()
    else:raise SystemExit(main())
