#!/usr/bin/env python3
"""Freeze source-checked successful GNU outputs; never turn compiler acceptance into valid execution."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent
cases=[]
for report in ['gnu-results.json','gnu-shape-results.json']:
    for row in json.loads((R/report).read_text()):
        name=row['name'];src=name+'.f90';raw=(R/src).read_bytes()
        assert hashlib.sha256(raw).hexdigest()==row['sha256']
        success=row.get('run_allowed','run_code' in row)
        case=dict(name=name,source=src,source_sha256=row['sha256'],category='success' if success else 'reject',baseline='run' if success else ('reject' if row['compile_code']==1 else 'compile'),compare_mode=row.get('compare_mode','numeric_records'))
        if success:
            assert row['compile_code']==0 and row['compile_stdout']=='' and row['compile_stderr']==''
            assert row['run_code']==0 and row['stderr']==''
            output=row['stdout'].encode('latin1');filename=name+'.stdout';(R/filename).write_bytes(output)
            case.update(expected_file=filename,expected_sha256=hashlib.sha256(output).hexdigest())
        else:
            assert row['compile_code'] in (0,1)
            assert 'run_code' not in row
            case['expected_stdout']=''
        if name=='nested_control_index_reuse':
            case['note']='GNU accepts this syntax, but it repeats a statement-entity name within the outer implied-DO scope (F2018 7.8 C7115 and 19.4 paragraph2); compile-only, never execute.'
        cases.append(case)
assert len(cases)==len({x['name'] for x in cases})
(R/'manifest.json').write_text(json.dumps({'feature':'constructor metadata inquiry, initialization and nested control followups','cases':cases},indent=2)+'\n')
print(f'Generated {len(cases)} independent followup fixtures')
