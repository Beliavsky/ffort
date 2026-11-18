#!/usr/bin/env python3
"""Compare exact-input mathematical references, separately from GNU agreement."""
import argparse,hashlib,json,math,struct,subprocess,tempfile
from pathlib import Path
from decimal import Decimal,localcontext
ROOT=Path(__file__).resolve().parent

def run(args,cwd):
 p=subprocess.run([str(x) for x in args],cwd=cwd,text=True,capture_output=True,timeout=60)
 return dict(status=p.returncode,stdout=p.stdout,stderr=p.stderr)
def ulp(value,k):
 if k==8:return math.ulp(value)
 f=struct.unpack('f',struct.pack('f',abs(value)))[0];bits=struct.unpack('I',struct.pack('f',f))[0]
 nxt=struct.unpack('f',struct.pack('I',bits+1))[0]
 if not math.isfinite(nxt):nxt=struct.unpack('f',struct.pack('I',bits-1))[0]
 return abs(nxt-f)
def assess(output,rows,k):
 lines=output.splitlines();assert len(lines)==len(rows),'wrong output count'
 out=[]
 with localcontext() as ctx:
  ctx.prec=120
  eps=Decimal(2)**(-23 if k==4 else -52);sub=Decimal(2)**(-149 if k==4 else -1074);tiny=Decimal(2)**(-126 if k==4 else -1022)
  for line,row in zip(lines,rows):
   words=line.split();assert len(words)==2 and int(words[0])==row['index'],'wrong output index'
   got=Decimal(words[1].replace('D','E').replace('d','e'));ref=Decimal(row['reference'])
   if row['function']=='erf':budget=Decimal(2 if k==4 else 4)*Decimal(ulp(float(ref),k))
   elif row['oscillatory']:budget=16*eps*max(abs(ref),Decimal(row['envelope']))+2*sub
   else:budget=Decimal(4 if k==4 else 64)*eps*abs(ref)+2*sub
   err=abs(got-ref)/budget if got.is_finite() else Decimal('Infinity')
   nonzero=not (got==0 and abs(ref)>=tiny and not row['near_root'])
   out.append(dict(index=row['index'],x_hex=row['x_hex'],n=row['n'],near_root=row['near_root'],result=str(got),budget_fraction=float(err) if err.is_finite() and err<=Decimal('1e308') else None,passed=got.is_finite() and nonzero and err<=1))
 return out

def known_gnu_difference(spec,row,result):
 return (not result['passed'] and
         (spec['function'],spec['kind'],row['n'],row['x_hex'])==('bessel_jn',4,16,'0x1.0000000000000p+3') and
         Decimal(result['result'])==Decimal('0.000078006436524447054') and
         result['budget_fraction'] is not None and 1<result['budget_fraction']<1.2)

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',type=Path,default=ROOT/'accuracy-results.json');a=ap.parse_args();a.candidate=a.candidate.resolve();ref=json.loads((ROOT/'accuracy_reference.json').read_text());records=[]
 with tempfile.TemporaryDirectory(prefix='erf-bessel-accuracy-') as temp:
  temp=Path(temp)
  for spec in ref['files']:
   src=ROOT/spec['file'];assert hashlib.sha256(src.read_bytes()).hexdigest()==spec['sha256'];k=spec['kind']
   check=run([a.candidate,'--check',src],temp);assert check==dict(status=0,stdout='',stderr=''),check
   candidate=run([a.candidate,src],temp);assert candidate['status']==0 and not candidate['stderr'],candidate
   compile=run([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow',src,'-o',temp/'oracle'],temp);assert compile['status']==0,compile
   oracle=run([temp/'oracle'],temp);assert oracle['status']==0 and not oracle['stderr'],oracle
   c=assess(candidate['stdout'],spec['rows'],k);g=assess(oracle['stdout'],spec['rows'],k)
   # One independently verified GNU REAL4 JN recurrence exceeds our stricter
   # mathematical budget; do not relabel it as candidate/GNU agreement.
   known=[];unexpected=[]
   for rr,gr in zip(spec['rows'],g):
    if gr['passed']:continue
    if known_gnu_difference(spec,rr,gr):
     known.append(dict(gr,reason='GNU REAL4 JN(16,8) exceeds four-epsilon relative budget; widened candidate passes'))
    else:unexpected.append(gr)
   records.append(dict(kind=k,function=spec['function'],points=len(c),candidate=c,gnu=g,gnu_known_precision_differences=known,gnu_unexpected=unexpected,check=check,compile=compile))
   print(spec['function'],'REAL',k,'points',len(c),'candidate failures',sum(not x['passed'] for x in c),'maximum budget fraction',max(x['budget_fraction'] if x['budget_fraction'] is not None else float('inf') for x in c),'GNU failures',sum(not x['passed'] for x in g),flush=True)
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),reference_sha256=hashlib.sha256((ROOT/'accuracy_reference.json').read_bytes()).hexdigest(),total=sum(r['points'] for r in records),failed=sum(not c['passed'] for r in records for c in r['candidate'])+sum(len(r['gnu_unexpected']) for r in records),records=records)
 a.result.write_text(json.dumps(result,indent=2,allow_nan=False)+'\n');return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
