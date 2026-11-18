"""Independent Decimal/Machin-series degree-tangent reference, not GNU output."""
from decimal import Decimal,localcontext
from pathlib import Path
import json,struct
ROOT=Path(__file__).resolve().parent

def atan_series(x):
    total=term=x
    for n in range(1,180):
        term=-term*x*x
        total+=term/Decimal(2*n+1)
    return total

def reference(value,kind):
    f32=lambda x:struct.unpack('f',struct.pack('f',x))[0]
    x=f32(value) if kind==4 else value
    with localcontext() as c:
        c.prec=110
        a=Decimal.from_float(x);angle=abs(a)%Decimal(180)
        if angle==90:raise ValueError('singular degree tangent')
        if angle>90:angle-=180
        negative=a.is_signed()
        if angle==0:return -0.0 if negative else 0.0
        pi=16*atan_series(Decimal(1)/5)-4*atan_series(Decimal(1)/239)
        complement=abs(angle)>45
        rad=(90-abs(angle) if complement else angle)*pi/180
        sine=sterm=rad;cosine=cterm=Decimal(1)
        for n in range(1,100):
            sterm=-sterm*rad*rad/Decimal((2*n)*(2*n+1));sine+=sterm
            cterm=-cterm*rad*rad/Decimal((2*n-1)*(2*n));cosine+=cterm
        result=cosine/sine if complement else sine/cosine
        if complement and angle<0:result=-result
        if negative:result=-result
        result=float(result)
        return f32(result) if kind==4 else result

def model(kind):
    values=[-1048576.,-720.25,-360.,-180.5,-135.,-89.9,-80.,-60.,-45.,-30.,-0.5,-0.00001,-0.,0.,0.00001,0.5,30.,45.,60.,80.,89.9,135.,180.5,360.,720.25,1048576.]
    if kind==4:values=[v for v in values if v!=0 or not str(v).startswith('-')]
    source=f'program p\nimplicit none\nreal({kind})::x\n';expected=[]
    for value in values:
        token=repr(value)
        if 'e' in token:token=token.replace('e','d') if kind==8 else token
        elif kind==8:token+='d0'
        source+='x='+token+'\nprint *,tand(x)\n'
        expected.append(format(reference(value,kind),'.17E'))
    return source+'end program\n','\n'.join(expected)+'\n'

def verify_accuracy():
    cases=json.loads((ROOT/'manifest.json').read_text())['cases']
    for kind in (4,8):
        source,expected=model(kind);name='degree_accuracy'+str(kind)
        found=[c for c in cases if c['name']==name]
        if (ROOT/'cases'/(name+'.f90')).read_text()!=source or len(found)!=1 or found[0]['expected_stdout']!=expected:raise SystemExit('Degree reference fixture differs')
    near=[reference(x,8) for x in [89.99999999999999,90.00000000000001,-89.99999999999999,-90.00000000000001]]
    found=[c for c in cases if c['name']=='tand_near_poles'][0]
    if list(map(float,found['expected_stdout'].split()))!=near:raise SystemExit('Independent near-pole expectation differs')
    return 55
if __name__=='__main__':print(verify_accuracy(),'independent degree tangent values verified')
