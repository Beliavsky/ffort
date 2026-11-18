#!/usr/bin/env python3
"""Regenerate independent120-digit references; requires mpmath1.3.0."""
from pathlib import Path
import hashlib,json,math,random,struct
import mpmath as mp
ROOT=Path(__file__).resolve().parent
mp.mp.dps=120

def f32(x):return struct.unpack('f',struct.pack('f',x))[0]
def adjacent(x,k,toward_positive):
 if k==8:return math.nextafter(x,math.inf if toward_positive else -math.inf)
 if x==0:return struct.unpack('f',struct.pack('I',1 if toward_positive else 0x80000001))[0]
 bits=struct.unpack('I',struct.pack('f',x))[0];bits+=(1 if x>0 else -1)*(1 if toward_positive else -1)
 return struct.unpack('f',struct.pack('I',bits))[0]
def reference(x):
 z=mp.mpf(x)
 if z<=50:return mp.exp(z*z)*mp.erfc(z),'mpmath120 exp(x²)*erfc(x), only x<=50'
 term=mp.mpf(1);total=term
 for n in range(1,121):
  term*=-(2*n-1)/(2*z*z);total+=term
 next_term=term*(-241)/(2*z*z)
 assert abs(next_term)<mp.mpf('1e-120')*abs(total)
 return total/(mp.sqrt(mp.pi)*z),'120-term asymptotic; relative remainder<1e-120'
allrows=[];files=[];boundaries=[]
for k in [4,8]:
 maxv=float.fromhex('0x1.fffffep127' if k==4 else '0x1.fffffffffffffp1023');minv=float.fromhex('0x1p-149' if k==4 else '0x1p-1074');tiny=float.fromhex('0x1p-126' if k==4 else '0x1p-1022')
 limit=9.3824138641357421875 if k==4 else 26.628735713751489
 last=-limit;outside=adjacent(last,k,False)
 good,_=reference(last);bad,_=reference(outside)
 assert good<=mp.mpf(maxv)<bad
 boundaries.append(dict(kind=k,last_finite_input_hex=last.hex(),next_overflow_input_hex=outside.hex(),huge_hex=maxv.hex(),last_result=mp.nstr(good,100),next_result=mp.nstr(bad,100)))
 values=[-limit,-8,-4,-1,-.46875,-.17,-tiny,-minv,-0.,0.,minv,tiny,1e-9,.17,.46875,1.,2.,4.,8.,16.,26.,50.,64.,1e4,1e8,maxv]
 if k==8:values += [-26.6,-26.,-20.,-10.,1e150,1e300,1e307,3e307,1e308]
 for v in [-limit,.46875,4.,26.,1e8,maxv]:
  v=f32(v) if k==4 else v
  for pos in [False,True]:
   a=adjacent(v,k,pos)
   if math.isfinite(a) and -limit<=a<=maxv:values.append(a)
 rng=random.Random(4100+k)
 values += [rng.uniform(-limit,30) for _ in range(100)]
 values += [10**rng.uniform(-20,math.log10(maxv)-.01) for _ in range(80)]
 if k==4:values=[f32(x) for x in values]
 values=list(dict.fromkeys(float(x) for x in values));rows=[];literals=[]
 for i,x in enumerate(values,1):
  y,method=reference(x);assert 0<y<=mp.mpf(maxv)
  text=format(x,'.9e' if k==4 else '.17e')+f'_{k}'
  rows.append(dict(index=i,kind=k,x_hex=x.hex(),input_literal=text,reference=mp.nstr(y,100),reference_method=method))
  literals.append(text)
 name=f'accuracy_real{k}.f90';source='program accuracy\nimplicit none\ninteger::i\nreal('+str(k)+')::x('+str(len(rows))+')\nx=[ &\n'+', &\n'.join(','.join(literals[j:j+3]) for j in range(0,len(literals),3))+']\ndo i=1,size(x)\nprint *,i,dble(erfc_scaled(x(i)))\nend do\nend program\n';p=ROOT/name;p.write_text(source);files.append(dict(file=name,kind=k,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),rows=rows));allrows+=rows
result=dict(generator='mpmath1.3.0,120 decimal digits; exact binary input from float.hex, fixed random seed; DLMF7.12.1 positive remainder bound',source='https://dlmf.nist.gov/7.12',mpmath_version=mp.__version__,negative_boundaries=boundaries,files=files,total=len(allrows))
(ROOT/'accuracy_reference.json').write_text(json.dumps(result,indent=2)+'\n');print('reference points',len(allrows))
