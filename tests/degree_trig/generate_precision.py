from pathlib import Path
import json,hashlib,struct,math
import mpmath as mp
mp.mp.dps=180
t=Path(__file__).resolve().parent;m=json.loads((t/'manifest.json').read_text());m['cases']=[c for c in m['cases'] if '_precision' not in c['name']]
def f32(x):return struct.unpack('f',struct.pack('f',x))[0]
def adjacent(x,k,d):
 if k==8:return math.nextafter(x, math.inf if d>0 else -math.inf)
 b=struct.unpack('I',struct.pack('f',x))[0]
 return struct.unpack('f',struct.pack('I',b+(d if x>=0 else -d)))[0]
def result(n,x,k):
 xx=mp.mpf(x.as_integer_ratio()[0])/x.as_integer_ratio()[1]
 if n=='asind':v=mp.asin(xx)*180/mp.pi
 elif n=='acosd':v=mp.acos(xx)*180/mp.pi
 else:
  num,den=x.as_integer_ratio()
  r=mp.mpf(abs(num)%(360*den))/den
  if n=='sind':
   sign=-1 if math.copysign(1,x)<0 else 1
   if r>=180:r-=180;sign=-sign
   if r>90:r=180-r
   if r==0:return math.copysign(0.,sign)
   v=sign*mp.sinpi(r/180)
  else:
   if r>180:r=360-r
   sign=1
   if r>90:r=180-r;sign=-1
   if r==90:return 0.
   v=sign*mp.cospi(r/180)
 out=float(v)
 if x==0 and n=='asind':out=math.copysign(0.,x)
 return f32(out) if k==4 else out
for n in ['acosd','asind','sind','cosd']:
 for k in [4,8]:
  tiny=2.**(-149 if k==4 else -1074);normal=2.**(-126 if k==4 else -1022)
  vals=[0.,0.,tiny,-tiny,normal,-normal] if n=='sind' and k==4 else [-0.,0.,tiny,-tiny,normal,-normal]
  if n in ['acosd','asind']:
   vals += [-1.,1.,adjacent(-1.,k,1),adjacent(1.,k,-1),0.5,-0.5,adjacent(0.5,k,1),adjacent(0.5,k,-1)]
  else:
   for a in [30.,60.,90.,180.,270.,360.,1048576.]:vals += [a,-a,adjacent(a,k,1),adjacent(a,k,-1)]
   vals += [float.fromhex('0x1.fffffep127') if k==4 else float.fromhex('0x1.fffffffffffffp1023'),1e20,1e30]
  vals=[f32(x) if k==4 else x for x in vals]
  for group in range(0,len(vals),8):
   v=vals[group:group+8];name=f'{n}_precision{k}_{group//8}'
   lines=['program p','implicit none',f'real({k})::x({len(v)}),y({len(v)})']
   for i,x in enumerate(v,1):lines += [f'x({i})={x:.17e}_{k}']
   lines += [f'y={n}(x)','print *,y','end program']
   src='\n'.join(lines)+'\n';f=t/'cases'/(name+'.f90');f.write_text(src)
   expected=' '.join(f'{result(n,x,k):.17e}' for x in v)+'\n'
   m['cases'].append(dict(name=name,source='cases/'+f.name,category='success',baseline='run',expected_stdout=expected,rel_tol=5e-7 if k==4 else 5e-15,abs_tol=0,sha256=hashlib.sha256(f.read_bytes()).hexdigest(),oracle='Independent mpmath 180-decimal-digit exact represented-value reduction, rounded to IEEE result kind.'))
(t/'manifest.json').write_text(json.dumps(m,indent=2)+'\n');print(len(m['cases']))
