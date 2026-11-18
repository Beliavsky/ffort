#!/usr/bin/env python3
"""Check positive finite results against independent high-precision references."""
import argparse,hashlib,json,math,struct,subprocess,tempfile
from pathlib import Path
from decimal import Decimal,localcontext
ROOT=Path(__file__).resolve().parent

def run(args,cwd):
 p=subprocess.run([str(x) for x in args],cwd=cwd,text=True,capture_output=True,timeout=60)
 return dict(status=p.returncode,stdout=p.stdout,stderr=p.stderr)
def ulp(value,k):
 if k==8:return math.ulp(value)
 f=struct.unpack('f',struct.pack('f',value))[0];bits=struct.unpack('I',struct.pack('f',f))[0]
 nxt=struct.unpack('f',struct.pack('I',bits+1))[0]
 if not math.isfinite(nxt):nxt=struct.unpack('f',struct.pack('I',bits-1))[0]
 return abs(nxt-f)
def assess(output,rows,k):
 lines=output.splitlines();assert len(lines)==len(rows),'wrong output count'
 out=[]
 with localcontext() as ctx:
  ctx.prec=110
  for line,row in zip(lines,rows):
   words=line.split();assert len(words)==2 and int(words[0])==row['index']
   got=Decimal(words[1].replace('D','E').replace('d','e'));ref=Decimal(row['reference'])
   finite=got.is_finite() and got>0
   err=abs(got-ref)/Decimal(ulp(float(ref),k)) if got.is_finite() else Decimal('Infinity')
   out.append(dict(index=row['index'],x_hex=row['x_hex'],result=str(got),ulp_error=float(err) if err.is_finite() else None,passed=finite and err<=Decimal(2 if k==4 else 4)))
 return out

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--gfortran',default='gfortran');ap.add_argument('--result',type=Path,default=ROOT/'accuracy-results.json');a=ap.parse_args();a.candidate=a.candidate.resolve();ref=json.loads((ROOT/'accuracy_reference.json').read_text());records=[]
 with tempfile.TemporaryDirectory(prefix='erfcx-accuracy-') as temp:
  temp=Path(temp)
  for spec in ref['files']:
   src=ROOT/spec['file'];assert hashlib.sha256(src.read_bytes()).hexdigest()==spec['sha256'];k=spec['kind']
   check=run([a.candidate,'--check',src],temp);assert check==dict(status=0,stdout='',stderr=''),check
   candidate=run([a.candidate,src],temp);assert candidate['status']==0 and not candidate['stderr'],candidate
   compile=run([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-ffpe-trap=invalid,zero,overflow',src,'-o',temp/'oracle'],temp);assert compile['status']==0,compile
   oracle=run([temp/'oracle'],temp);assert oracle['status']==0 and not oracle['stderr'],oracle
   c=assess(candidate['stdout'],spec['rows'],k);g=assess(oracle['stdout'],spec['rows'],k)
   known=[];unexpected=[]
   for row,gr in zip(spec['rows'],g):
    if gr['passed']:continue
    # Known GNU14 cutoffs lose subnormals or overflow finite boundary results. No other
    # inaccurate/nonfinite result is silently exempted from the oracle check.
    if float.fromhex(row['x_hex'])>0 and Decimal(gr['result'])==0 and Decimal(row['reference'])<Decimal(float.fromhex('0x1p-126' if k==4 else '0x1p-1022')):
     known.append(dict(gr,reason='GNU runtime loses a mathematically representable positive subnormal'))
    elif float.fromhex(row['x_hex'])<0 and Decimal(gr['result'])==Decimal('Infinity') and Decimal(row['reference'])>Decimal(float.fromhex('0x1.fffffep127' if k==4 else '0x1.fffffffffffffp1023'))*Decimal('.99'):
     known.append(dict(gr,reason='GNU runtime premature negative-tail overflow for a finite result'))
    else:unexpected.append(gr)
   records.append(dict(kind=k,points=len(c),candidate=c,gnu=g,gnu_known_boundary_discrepancies=known,gnu_unexpected=unexpected,check=check,compile=compile))
   print('REAL',k,'points',len(c),'candidate failures',sum(not x['passed'] for x in c),'max ULP',max(x['ulp_error'] if x['ulp_error'] is not None else float('inf') for x in c),'GNU known boundary discrepancies',len(known),'GNU unexpected',len(unexpected))
 result=dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),reference_sha256=hashlib.sha256((ROOT/'accuracy_reference.json').read_bytes()).hexdigest(),total=sum(r['points'] for r in records),failed=sum(not c['passed'] for r in records for c in r['candidate'])+sum(len(r['gnu_unexpected']) for r in records),records=records)
 a.result.write_text(json.dumps(result,indent=2,allow_nan=False)+'\n');return result['failed']!=0
if __name__=='__main__':raise SystemExit(main())
