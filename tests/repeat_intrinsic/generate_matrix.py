#!/usr/bin/env python3
"""Build an independent, blank-sensitive cross-product oracle using Python repetition."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parent

def matrix():
    statements=[]; expected=[]
    for s in ('', 'x', ' a ', "a'b", '  '):
        literal="'"+s.replace("'","''")+"'"
        for n in (0,1,2,3,7):
            for expression in (f'repeat({literal},{n})',f'repeat(ncopies={n}_8,string={literal})',
                               f'repeat(string={literal},ncopies={n}+0)'):
                statements.append("print '(a)', '<'//"+expression+"//'>'")
                expected.append('<'+s*n+'>\n')
    return 'program p\nimplicit none\n'+'\n'.join(statements)+'\nend program\n',''.join(expected)

def verify_matrix():
    source,expected=matrix()
    assert (ROOT/'cases/matrix.f90').read_text()==source, 'Matrix source differs'
    rows=json.loads((ROOT/'manifest.json').read_text())['cases']
    row=next(c for c in rows if c['name']=='matrix')
    assert row['expected_stdout']==expected and row['exact_stdout'], 'Matrix oracle differs'

if __name__=='__main__':
    source,expected=matrix()
    (ROOT/'cases/matrix.f90').write_text(source)
    manifest=json.loads((ROOT/'manifest.json').read_text())
    manifest['cases']=[c for c in manifest['cases'] if c['name']!='matrix']
    manifest['cases'].append(dict(name='matrix',source='cases/matrix.f90',category='success',
        baseline='run',expected_stdout=expected,exact_stdout=True,oracle_values=75))
    (ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
