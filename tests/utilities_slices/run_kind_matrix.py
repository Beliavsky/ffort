#!/usr/bin/env python3
"""Optional-argument/INTEGER64 matrix against the explicit REAL32/REAL64 model.

These are supported-model policy checks, not comparisons with GNU's wider kinds.
Generated source is temporary; arguments and results remain reproducible.
"""
from pathlib import Path
import argparse,itertools,json,subprocess,hashlib,tempfile
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--candidate',required=True,type=Path)
parser.add_argument('--result',type=Path,default=Path(__file__).with_name('kind-matrix-results.json'))
args=parser.parse_args()
EXE=args.candidate.resolve()
temporary=tempfile.TemporaryDirectory(prefix='fi-kind-matrix-')
ROOT=Path(temporary.name)
names=('p','r','radix')
cases=[]
def lit(n):
    if n == -(2**63): return '(-9223372036854775807_8-1_8)'
    return str(n)+'_8'
def expect(v):
    p,r,radix=(v.get(k,d) for k,d in zip(names,(0,0,2)))
    if radix != 2:return -5
    if p<=6 and r<=37:return 4
    if p<=15 and r<=307:return 8
    if p>15 and r>307:return -3
    if p>15:return -1
    return -2
for mask in range(8):
    present=[name for k,name in enumerate(names) if mask&(1<<k)]
    pools={'p':(-2**63,-1,0,6,7,15,16,10000,2**63-1),
           'r':(-2**63,-1,0,37,38,307,308,10000,2**63-1),
           'radix':(-2**63,-1,0,2,10,2**63-1)}
    for values in itertools.product(*(pools[k] for k in present)):
        v=dict(zip(present,values))
        # all named argument permutations; rotate case for name folding.
        for permutation in itertools.permutations(present):
            call='selected_real_kind('+','.join(k.upper()+'='+lit(v[k]) for k in permutation)+')'
            cases.append((call,expect(v)))
        # Every allowable positional prefix followed by reordered keywords.
        prefix=0
        while prefix<len(names) and names[prefix] in v:
            prefix+=1
            for permutation in itertools.permutations([k for k in present if k not in names[:prefix]]):
                fields=[lit(v[k]) for k in names[:prefix]]+[k+'='+lit(v[k]) for k in permutation]
                cases.append(('selected_real_kind('+','.join(fields)+')',expect(v)))
cases=list(dict.fromkeys(cases))
results=[]
for start in range(0,len(cases),80):
    block=cases[start:start+80]
    source='program main\nimplicit none\n'+'\n'.join('print *, '+call for call,_ in block)+'\nend\n'
    # Keep every line within the supported physical source limit.
    source=source.replace(',R=',', &\n R=').replace(',RADIX=',', &\n RADIX=')
    source=source.replace(',r=',', &\n r=').replace(',radix=',', &\n radix=')
    source=source.replace(',(-922337',', &\n (-922337').replace(',922337',', &\n 922337')
    path=ROOT/f'matrix_{start//80:03}.f90';path.write_text(source)
    result=subprocess.run([str(EXE),str(path)],capture_output=True,text=True,timeout=60)
    values=list(map(int,result.stdout.split())) if result.returncode==0 else []
    wanted=[expected for call,expected in block]
    row={'file':path.name,'count':len(block),'code':result.returncode,'matches':values==wanted and result.returncode==0 and not result.stderr,'err':result.stderr}
    if values!=wanted:row['expected']=wanted;row['actual']=values;row['calls']=[x[0] for x in block]
    results.append(row)
args.result.write_text(json.dumps({'candidate_sha256':hashlib.sha256(EXE.read_bytes()).hexdigest(),'cases':len(cases),'results':results},indent=2)+'\n')
print('matrix cases',len(cases),'batches',len(results),'failures',sum(not r['matches'] for r in results))
for row in results:
    if not row['matches']:print(row)

temporary.cleanup()
raise SystemExit(1 if any(not row['matches'] for row in results) else 0)
