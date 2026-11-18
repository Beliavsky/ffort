#!/usr/bin/env python3
"""Independent mathematical expected values; never reads candidate output."""
from pathlib import Path
import json
import math
ROOT=Path(__file__).resolve().parent

def model():
    lines=[];values=[]
    for x in [-8,-3,-1,0,1,3,8]:
        for y in [-4,0,4]:
            lines.append(f'print *,dim({x},{y}),sign({x},{y})')
            values.extend([max(x-y,0),abs(x) if y>=0 else -abs(x)])
    for x in [-3.75,-2.5,-1.25,-.25,.125,.5,1.,1.5,2.,3.,10.,30.]:
        lines.append(f'print *,log_gamma({x}d0)');values.append(math.lgamma(x))
    return 'program p\nimplicit none\n'+'\n'.join(lines)+'\nend program\n',' '.join(map(str,values))

def verify_matrix():
    source,expected=model()
    case=next(c for c in json.loads((ROOT/'manifest.json').read_text())['cases'] if c['name']=='matrix')
    if (ROOT/case['source']).read_text()!=source or case['expected_stdout']!=expected:
        raise SystemExit('Independent elementary-math matrix source or expected model differs')
    return len(expected.split())
if __name__=='__main__':print('Verified independently modeled values:',verify_matrix())
