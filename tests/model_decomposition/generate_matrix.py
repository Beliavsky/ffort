#!/usr/bin/env python3
"""Independent binary-model and ASCII inverse checks, never candidate-derived."""
from pathlib import Path
import json,math
ROOT=Path(__file__).resolve().parent

def model():
    lines=[];values=[]
    for x in [0.,-0.,.125,-.125,.75,-.75,1.,-1.,2.,-2.,10.,-10.,1024.,-1024.]:
        token=repr(x)+'d0';fraction,exponent=math.frexp(x)
        lines.append(f'print *,fraction({token}),exponent({token})')
        values.extend([fraction,exponent])
        for i in [-10,0,3,10]:
            lines.append(f'print *,set_exponent({token},{i}_8)')
            values.append(math.ldexp(fraction,i))
    return 'program p\nimplicit none\n'+'\n'.join(lines)+'\nend program\n',' '.join(map(str,values))

def verify_matrix():
    source,expected=model()
    case=next(c for c in json.loads((ROOT/'manifest.json').read_text())['cases'] if c['name']=='binary_matrix')
    if (ROOT/case['source']).read_text()!=source or case['expected_stdout']!=expected:
        raise SystemExit('Independent binary-model fixture or expected values differ')
    return len(expected.split())
if __name__=='__main__':print('Verified independent model values:',verify_matrix())
