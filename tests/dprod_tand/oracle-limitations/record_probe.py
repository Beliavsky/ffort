#!/usr/bin/env python3
"""Record GNU degree-tangent near-pole accuracy; never relax normal comparison."""
from pathlib import Path
from decimal import Decimal
import argparse,hashlib,json,subprocess,tempfile,sys,math
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent))
from verify_accuracy import reference

def run(argv):
 p=subprocess.run(list(map(str,argv)),capture_output=True,text=True,timeout=30,stdin=subprocess.DEVNULL)
 return dict(argv=list(map(str,argv)),exit=p.returncode,stdout=p.stdout,stderr=p.stderr)

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--gfortran',required=True);ap.add_argument('--candidate',required=True);a=ap.parse_args()
 source=ROOT/'near_pole.f90';candidate=Path(a.candidate).resolve();records=[]
 for opt in ['-O0','-O2']:
  with tempfile.TemporaryDirectory() as td:
   exe=Path(td)/'gnu';comp=run([a.gfortran,'-std=gnu','-pedantic-errors','-fcheck=all',opt,source,'-o',exe]);assert comp['exit']==0,comp
   out=run([exe]);assert out['exit']==0 and not out['stderr'].strip(),out;records.append(dict(compile=comp,run=out))
 result=run([candidate,source]);assert result['exit']==0 and not result['stderr'].strip(),result
 xs=[math.nextafter(90.,-math.inf),math.nextafter(90.,math.inf)];expected=[reference(x,8) for x in xs]
 tokens=[Decimal(v) for v in result['stdout'].split()];assert len(tokens)==10
 assert tokens[8:]==[Decimal(-1),Decimal(-1)]
 for offset,want in [(0,expected[0]),(4,expected[1])]:
  for index in [1,2,3]:assert abs(tokens[offset+index]-Decimal.from_float(want)) <= abs(Decimal.from_float(want))*Decimal('2e-15')
 report=dict(source=source.name,source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),GNU_version=run([a.gfortran,'--version'])['stdout'],GNU=records,candidate=result,candidate_sha256=hashlib.sha256(candidate.read_bytes()).hexdigest(),independent_reference=dict(method='Decimal precision110; Machin atan series computes pi, sine/cosine series after exact represented-degree reduction, rounded to binary64',inputs=[x.hex() for x in xs],expected=expected),classification='Isolated GNU near-pole accuracy disagreement and REAL4 runtime negative-zero sign difference. Compile-only in focused GNU manifest; not execution agreement. Normal comparisons retain strict scoped tolerances.')
 (ROOT/'gnu14-receipt.json').write_text(json.dumps(report,indent=2)+'\n');print('Near-pole receipt verified independently')
if __name__=='__main__':main()
