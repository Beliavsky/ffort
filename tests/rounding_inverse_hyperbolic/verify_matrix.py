"""Reconstruct the exact rounding matrix independently of interpreter/GNU output."""
from pathlib import Path
import json,math,struct
ROOT=Path(__file__).resolve().parent

def model():
    values=[-16777216.,-16777215.,-2.7,-2.5,-2.2,-2.,-1.5,-1.,-.50000006,-.5,-.49999997,-.1,-0.,0.,.1,.49999997,.5,.50000006,1.,1.5,2.,2.2,2.5,2.7,16777215.,16777216.]
    f32=lambda x:struct.unpack('f',struct.pack('f',x))[0]
    lines=[];expected=[]
    for input_kind in (4,8):
        for output_kind in (4,8):
            for value in values:
                argument=f32(value) if input_kind==4 else value
                whole=math.trunc(argument)
                fractional=abs(argument-whole)
                nearest=whole+(1 if argument>0 else -1) if fractional>=.5 else whole
                token=repr(value).replace('e','E' if input_kind==4 else 'D')
                if 'E' not in token and 'D' not in token:token+=('e0' if input_kind==4 else 'd0')
                lines.append(f'print *,aint({token},{output_kind}),anint({token},{output_kind})')
                # Both operations preserve the input sign when their result is zero.
                signed=[math.copysign(0.0,argument) if x==0 else float(x) for x in (whole,nearest)]
                expected.extend(str(f32(x) if output_kind==4 else x) for x in signed)
    return 'program p\nimplicit none\n'+'\n'.join(lines)+'\nend program\n',' '.join(expected)+'\n'

def verify_matrix():
    source,expected=model()
    if (ROOT/'cases/rounding_matrix.f90').read_text()!=source:
        raise SystemExit('Independent rounding matrix source differs')
    matches=[x for x in json.loads((ROOT/'manifest.json').read_text())['cases'] if x['name']=='rounding_matrix']
    if len(matches)!=1 or matches[0]['expected_stdout']!=expected or matches[0]['rel_tol']!=0 or matches[0]['abs_tol']!=0:
        raise SystemExit('Independent rounding matrix expectation differs')
    return 208

if __name__=='__main__':print(verify_matrix(),'independent rounding values verified')
