#!/usr/bin/env python3
"""Independent exact-input, 120-digit mathematical references; optional mpmath1.3.0."""
from pathlib import Path
import hashlib,json,math,random,struct
import mpmath as mp
ROOT=Path(__file__).resolve().parent
mp.mp.dps=120
NAMES=['erf','bessel_j0','bessel_j1','bessel_jn','bessel_y0','bessel_y1','bessel_yn']
def f32(x):return struct.unpack('f',struct.pack('f',x))[0]
def next32(x,positive):
 if x==0:return float.fromhex('0x1p-149')*(1 if positive else -1)
 b=struct.unpack('I',struct.pack('f',x))[0];b+=(1 if x>0 else -1)*(1 if positive else -1)
 return struct.unpack('f',struct.pack('I',b))[0]
files=[]
for k in [4,8]:
 cast=f32 if k==4 else float
 tiny=float.fromhex('0x1p-126' if k==4 else '0x1p-1022');sub=float.fromhex('0x1p-149' if k==4 else '0x1p-1074');huge=float.fromhex('0x1.fffffep127' if k==4 else '0x1.fffffffffffffp1023')
 for name in NAMES:
  rows=[];values=[];is_y=name.startswith('bessel_y');is_n=name.endswith('n');is_erf=name=='erf'
  orders=[0,1,2,5,16,32] if is_n else [int(name[-1]) if not is_erf else 0]
  for n in orders:
   xs=[2**-20,.125,.5,1.,2.,4.,8.,16.,32.,64.,128.,1024.,2**20]
   if not is_y:xs += [0.,-0.,sub,tiny,2**-100,1e-10,-.17,-1.,-32.,-2**20]
   if is_erf:xs += [huge,-huge,1e20,-1e20]
   rng=random.Random(3900+k+n+NAMES.index(name)*100)
   xs += [rng.uniform(2**-20,128) for _ in range(14)]
   xs += [2**rng.uniform(-20,20) for _ in range(10)]
   for x in xs:values.append((n,cast(x),False))
   if not is_erf:
    for ordinal in [1,2,3,20]:
     root=(mp.besselyzero if is_y else mp.besseljzero)(n,ordinal)
     x=cast(float(root));values.append((n,x,True))
     for positive in [False,True]:values.append((n,next32(x,positive) if k==4 else math.nextafter(x,math.inf if positive else -math.inf),True))
  seen=set()
  for n,x,nearroot in values:
   if (n,x.hex()) in seen:continue
   seen.add((n,x.hex()))
   z=mp.mpf(x)
   ref=mp.erf(z) if is_erf else (mp.bessely(n,z) if is_y else mp.besselj(n,z))
   if abs(ref)>mp.mpf(huge):continue # Explicit runtime overflow cases live in focused suite.
   envelope=mp.sqrt(2/(mp.pi*abs(z))) if z else mp.mpf(1)
   text=format(x,'.9e' if k==4 else '.17e')+f'_{k}'
   rows.append(dict(index=len(rows)+1,kind=k,function=name,n=n,x_hex=x.hex(),input_literal=text,reference=mp.nstr(ref,115),near_root=nearroot,oscillatory=not is_erf and (nearroot or abs(x)>=max(1,n)),envelope=mp.nstr(envelope,115)))
  n=len(rows);args='orders(i),x(i)' if is_n else 'x(i)'
  lines=['program accuracy','implicit none',f'integer::i,orders({n})',f'real({k})::x({n})','orders=[ &']
  lines += [','.join(str(row['n']) for row in rows[j:j+12])+(', &' if j+12<n else ']') for j in range(0,n,12)]
  lines+=['x=[ &']+[','.join(row['input_literal'] for row in rows[j:j+3])+(', &' if j+3<n else ']') for j in range(0,n,3)]
  lines+=['do i=1,size(x)',f'print *,i,dble({name}({args}))','end do','end program']
  p=ROOT/f'accuracy_{name}_real{k}.f90';p.write_text('\n'.join(lines)+'\n')
  files.append(dict(file=p.name,kind=k,function=name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),rows=rows))
result=dict(generator='mpmath1.3.0,120 decimal digits, exact binary inputs; deterministic seed; independent analytic Bessel and error functions',mpmath_version=mp.__version__,sources=['https://dlmf.nist.gov/10.2','https://dlmf.nist.gov/10.8','https://dlmf.nist.gov/7.2'],policy='ERF:2 ULP REAL4,4 ULP REAL8. Bessel nonoscillatory:4epsilon REAL4 or64epsilon REAL8 relative plus2 smallest subnormals. Oscillatory abs(X)>=max(1,N), and explicit root neighbors:16epsilon times max(abs(reference),sqrt(2/(pi*abs(x)))) plus2 smallest subnormals. This amplitude-scaled absolute budget accounts for the ill-conditioned relative error near any zero. No normal non-root result may collapse to zero.',files=files,total=sum(len(f['rows']) for f in files))
(ROOT/'accuracy_reference.json').write_text(json.dumps(result,indent=2)+'\n');print('Generated',result['total'],'independent references')
