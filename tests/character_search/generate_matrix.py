#!/usr/bin/env python3
"""Independent character-membership model; check the retained exhaustive fixture."""
from pathlib import Path
import itertools,json
ROOT=Path(__file__).resolve().parent

def build():
    strings=[''.join(x) for n in range(4) for x in itertools.product('ab ',repeat=n)]
    sets=[''.join(x) for n in range(3) for x in itertools.product('ab ',repeat=n)]
    source=['program p','implicit none'];expected=[];n=0
    for op in ['scan','verify']:
        for string in strings:
            for chars in sets:
                for back in [False,True]:
                    n+=1
                    indices=[i+1 for i,c in enumerate(string)
                             if ((c in chars) if op=='scan' else (c not in chars))]
                    expected.append(str((indices[-1] if back else indices[0]) if indices else 0))
                    b='.true.' if back else '.false.'
                    forms=[f"{op}('{string}','{chars}',{b})",
                           f"{op}('{string}','{chars}',{b},8)",
                           f"{op}(back={b},kind=4,string='{string}',set='{chars}')",
                           f"{op}('{string}',kind=8,back={b},set='{chars}')"]
                    source.append('print *, '+forms[n%4])
    source.append('end program')
    return '\n'.join(source)+'\n',' '.join(expected),n

def verify_matrix():
    source,expected,n=build()
    entries=json.loads((ROOT/'manifest.json').read_text())['cases']
    case=next(c for c in entries if c['name']=='exhaustive_small_strings')
    assert (ROOT/case['source']).read_text()==source,'Exhaustive source/model mismatch'
    assert case['expected_stdout']==expected,'Exhaustive expected values/model mismatch'
    assert case['oracle_values']==n==2080,'Exhaustive case-count mismatch'

if __name__=='__main__':
    verify_matrix()
    print('PASS: 2,080 independent character-membership model values and source forms')
