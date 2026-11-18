#!/usr/bin/env python3
"""Array resource-policy boundaries derived from the one public source constant.

GNU Fortran is an independent language/output oracle, not a resource-limit oracle.
All probes are generated in a temporary directory; old corpus sources are intact.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SAMPLE = '''program main
implicit none
integer, parameter :: dp = kind(1.0d0), n = 10**5
real(kind=dp) :: x(n)
call random_number(x)
print*,minval(x),maxval(x),sum(x)/n
end program main
'''


def program(declarations, body, procedures=''):
    return 'program p\nimplicit none\n'+declarations+'\n'+body+'\n'+(
        'contains\n'+procedures+'\n' if procedures else '')+'end program p\n'


def run(command, cwd):
    try:
        p = subprocess.run([str(v) for v in command], cwd=cwd, capture_output=True,
                           text=True, timeout=45, stdin=subprocess.DEVNULL)
        return dict(code=p.returncode, out=p.stdout, err=p.stderr)
    except (subprocess.TimeoutExpired, OSError) as exc:
        return dict(code=None, out='', err=str(exc))


def summary_valid(output):
    try:
        lo, hi, mean = map(float, output.split())
        return all(math.isfinite(v) for v in (lo, hi, mean)) and 0 <= lo < .01 and .99 < hi < 1 and .45 < mean < .55
    except (ValueError, TypeError):
        return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--gfortran', required=True)
    parser.add_argument('--result', type=Path, default=Path('results.json'))
    args = parser.parse_args()
    if not args.result.is_absolute():
        args.result=Path(__file__).resolve().parent/args.result
    source = (ROOT/'src/fi_ir.f90').read_text()
    match = re.search(r'integer,\s*parameter\s*::\s*max_array_elements\s*=\s*(\d+)\b', source, re.I)
    if not match:
        raise SystemExit('Cannot read max_array_elements from fi_ir.f90')
    limit = int(match.group(1))
    source_limit=int(re.search(r'max_source_bytes\s*=\s*(\d+)',
                    (ROOT/'src/fi_limits.f90').read_text(),re.I).group(1))
    if limit < 100000 or limit >= 2147483647:
        raise SystemExit('Expected a configurable array cap in [100000, 2147483647)')
    cases = []

    def add(name, text, expected='', category='success', diagnostic='', options=(), oracle='run'):
        cases.append(dict(name=name, source=text, expected=str(expected), category=category,
                          diagnostic=diagnostic, options=list(options), oracle=oracle))

    add('requested_random_100000', SAMPLE, 'random')
    cases[-1]['source_message']='Sentinel_c207f0db00048191b72b7e7d4af94f29'
    if (ROOT/'examples/random_summary_100000.f90').read_text() != SAMPLE:
        raise SystemExit('Exact requested example differs from regression source')
    add('requested_random_low_budget', SAMPLE, category='runtime', diagnostic='step limit', options=('--max-steps', '100'), oracle='compile')
    add('rank_one_at_limit', program(f'integer :: aa({limit})', f'aa(1)=7\naa({limit})=9\nprint *,size(aa),aa(1),aa({limit})'), f'{limit} 7 9')
    add('aggregate_at_limit', program(f'integer :: aa({limit//2}),bb({limit-limit//2})', 'print *,size(aa)+size(bb)'), limit)
    add('whole_assignment_at_limit', program(f'integer :: aa({limit})', 'aa=3\nprint *,sum(aa),minval(aa),maxval(aa)'), f'{3*limit} 3 3', options=('--max-steps', str(10*limit)))
    add('random_at_limit', SAMPLE.replace('10**5', str(limit)), 'random', options=('--max-steps', str(10*limit)))
    add('rank_two_at_limit', program(f'integer :: aa({limit},1)', f'aa(1,1)=7\naa({limit},1)=9\nprint *,size(aa),aa(1,1),aa({limit},1)'), f'{limit} 7 9')
    for name, decl in [('rank_one_above_limit', f'integer :: aa({limit+1})'),
                       ('aggregate_above_limit', f'integer :: aa({limit//2}),bb({limit-limit//2+1})'),
                       ('rank_two_above_limit', f'integer :: aa({limit+1},1)'),
                       ('rank_two_huge_product', 'integer :: aa(2147483647,2147483647)'),
                       ('rank_one_huge_extent', 'integer :: aa(-2147483647:2147483647)')]:
        add(name, program(decl, 'print *,991'), category='static', diagnostic='limit' if 'huge_extent' not in name else 'INTEGER range', oracle='skip' if 'huge' in name else 'compile')
    add('wide_integer_bounds_no_overflow', program('integer :: aa(-9223372036854775807_8:9223372036854775807_8)', 'print *,991'), category='static', diagnostic='Array bound exceeds supported INTEGER range', oracle='skip')
    # Zero total storage is legal; products/reductions still check their result size.
    add('wide_empty_storage', program(f'integer :: aa({limit+1},0)', 'print *,size(aa),size(aa,1)'), f'0 {limit+1}')
    add('reduction_result_at_limit', program(f'integer :: aa({limit},0)', 'print *,sum(sum(aa,dim=2))'), '0', options=('--max-steps', str(10*limit)))
    add('reduction_result_above_limit', program(f'integer :: aa({limit+1},0)', 'print *,sum(sum(aa,dim=2))'), category='runtime', diagnostic='limit', oracle='compile')
    add('matmul_result_at_limit', program(f'integer :: aa({limit},0),bb(0,1)', 'print *,sum(matmul(aa,bb))'), '0', options=('--max-steps', str(10*limit)))
    add('matmul_result_above_limit', program(f'integer :: aa({limit+1},0),bb(0,1)', 'print *,sum(matmul(aa,bb))'), category='runtime', diagnostic='limit', oracle='compile')
    add('constructor_at_limit', program(f'integer :: aa({limit//2}),bb({limit-limit//2})', 'aa=1\nbb=1\nprint *,sum([aa,bb])'), limit, options=('--max-steps', str(10*limit)))
    add('constructor_static_above_limit', program(f'integer :: aa({limit})', 'print *,sum([aa,1])'), category='static', diagnostic='limit', oracle='compile')
    add('constructor_dynamic_above_limit', program(f'integer :: aa({limit}),nn', f'nn={limit}\nprint *,sum([aa(:nn),1])'), category='runtime', diagnostic='limit', oracle='compile')
    sub = 'subroutine visit(xx,yy)\ninteger,intent(in)::xx(:),yy(:)\nprint *,size(xx)+size(yy)\nend subroutine'
    add('call_actuals_at_limit', program(f'integer :: aa({limit//2}),bb({limit-limit//2})', 'call visit(aa,bb)', sub), limit, options=('--max-steps', str(10*limit)))
    add('call_actuals_above_limit', program(f'integer :: aa({limit//2+1})', 'call visit(aa,aa)', sub), category='runtime', diagnostic='argument array element limit', oracle='compile')
    sublocal = f'subroutine visit(xx,yy)\ninteger,intent(in)::xx(:),yy(:)\ninteger::zz({limit//2})\nprint *,991\nend subroutine'
    add('frame_storage_above_limit', program(f'integer :: aa({limit//2})', 'call visit(aa,aa)', sublocal), category='runtime', diagnostic='total array element limit', options=('--max-steps', str(10*limit)), oracle='compile')
    add('parameter_at_limit', program(f'integer,parameter :: aa({limit})=1', 'print *,size(aa),aa(1)'), f'{limit} 1', options=('--max-steps', str(10*limit)))
    add('initializer_above_limit', program(f'integer :: aa({limit+1})=1', 'print *,991'), category='static', diagnostic='limit', oracle='compile')
    add('expanded_print_unchanged', program('integer :: aa(65537)', 'print *,aa'), category='runtime', diagnostic='PRINT expanded value limit exceeded (65536)', oracle='compile')
    add('character_limit_unchanged', program('character(65537)::ss', 'print *,991'), category='static', diagnostic='CHARACTER length limit', oracle='compile')
    add('source_limit_independent', '!'+'a'*source_limit+'\n', category='static',
        diagnostic=f'{source_limit}-byte', oracle='skip')
    # A larger storage cap must not silently raise the default 1,000,000 work budget.
    add('default_work_limit_unchanged', program('integer::ii,ss', 'ss=0\ndo ii=1,1000000\nss=1\nend do\nprint *,ss'), category='runtime', diagnostic='step limit', oracle='compile')
    records = []
    with tempfile.TemporaryDirectory(prefix='array-limit-tests-') as temp:
        folder = Path(temp)
        for case in cases:
            path = folder/(case['name']+'.f90')
            path.write_text(case['source'])
            record = dict(case=case, errors=[])
            check = run([args.candidate.resolve(), '--check', path], folder)
            executed = run([args.candidate.resolve(), *case['options'], path], folder)
            record.update(check=check, run=executed)
            code = 1 if case['category']=='static' else 2 if case['category']=='runtime' else 0
            if check['code'] != (1 if code==1 else 0) or check['out']:
                record['errors'].append('unexpected check status/output')
            if executed['code'] != code:
                record['errors'].append('unexpected execution status')
            if code:
                if executed['out'] or case['diagnostic'].lower() not in '\n'.join(line.split(': ',1)[-1] for line in executed['err'].splitlines()).lower():
                    record['errors'].append('failure diagnostic/output mismatch')
            elif case['expected']=='random':
                repeat = run([args.candidate.resolve(), *case['options'], path], folder)
                record['repeat'] = repeat
                if not summary_valid(executed['out']) or repeat['out'] != executed['out'] or repeat['code'] != 0:
                    record['errors'].append('random range/summary/repeatability failure')
                if case['name']=='requested_random_100000':
                    state=104729; values=[]
                    for _ in range(100000):
                        state=16807*state%2147483647
                        values.append(state/2147483647)
                    expected=[min(values),max(values),sum(values)/100000]
                    got=list(map(float,executed['out'].split())) if summary_valid(executed['out']) else []
                    if len(got)!=3 or any(not math.isclose(a,b,rel_tol=1e-13,abs_tol=1e-14) for a,b in zip(got,expected)):
                        record['errors'].append('independent RNG recurrence mismatch')
            elif executed['out'].split() != case['expected'].split():
                record['errors'].append('numeric output mismatch')
            if case['oracle']!='skip':
                binary=folder/'reference'
                compiled=run([args.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all',path,'-o',binary],folder)
                record['gnu_compile']=compiled
                if compiled['code'] != 0:
                    record['errors'].append('GNU reference compilation failure')
                elif case['oracle']=='run':
                    reference=run([binary],folder);record['gnu_run']=reference
                    valid=summary_valid(reference['out']) if case['expected']=='random' else reference['out'].split()==case['expected'].split()
                    if reference['code'] != 0 or not valid:
                        record['errors'].append('GNU reference output failure')
            record['passed']=not record['errors']; records.append(record)
            print(case['name']+': '+('PASS' if record['passed'] else 'FAIL '+', '.join(record['errors'])),flush=True)
    payload=dict(max_array_elements=limit, candidate_sha256=hashlib.sha256(args.candidate.read_bytes()).hexdigest(),
                 total=len(records),passed=sum(r['passed'] for r in records),results=records)
    payload['summary']=dict(total=len(records), failed=sum(not r['passed'] for r in records),
        candidate_checked=len(records), gnu_checked=sum(c['oracle']!='skip' for c in cases),
        gnu_skipped=sum(c['oracle']=='skip' for c in cases))
    payload['source_sha256']={c['name']:hashlib.sha256(c['source'].encode()).hexdigest() for c in cases}
    args.result.parent.mkdir(parents=True,exist_ok=True)
    args.result.write_text(json.dumps(payload,indent=2)+'\n')
    print(f"{payload['passed']}/{payload['total']} passed; max_array_elements={limit}")
    return int(payload['passed']!=payload['total'])


if __name__=='__main__':
    raise SystemExit(main())
