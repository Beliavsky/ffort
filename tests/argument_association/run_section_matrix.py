#!/usr/bin/env python3
"""Deterministic Python/GNU/interpreter oracle for nested strided dummy bindings.

108 programs cover caller lower bounds -3/1/4, extents 0/1/2/3/5/9, and outer
strides -3/-2/-1/1/2/3. Dummy lower bounds and inner strides vary independently.
No expected result is derived from the interpreter or GNU executable.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import itertools
import json
import tempfile
from run_tests import execute, compare

ROOT = Path(__file__).resolve().parent


def fixtures():
    for number, (lower, extent, step) in enumerate(itertools.product(
            (-3, 1, 4), (0, 1, 2, 3, 5, 9), (-3, -2, -1, 1, 2, 3))):
        upper = lower+extent-1
        first, last = (lower, upper) if step > 0 else (upper, lower)
        selected = list(range(first, last+(1 if step > 0 else -1), step))
        dummy_lower = (-3, 0, 1, 4)[number % 4]
        inner_step = (1, -2, 3, -1, 2, -3)[(number//6) % 6]
        n = len(selected)
        inner_first, inner_last = ((0, n-1) if inner_step > 0 else (n-1, 0))
        inner = list(range(inner_first, inner_last+(1 if inner_step > 0 else -1), inner_step))
        data = list(range(1, extent+1))
        for ordinal, index in enumerate(inner, 1):
            data[selected[index]-lower] += 100*ordinal
        for index in selected:
            data[index-lower] += 7
        source = f'''program main
implicit none
integer :: a({lower}:{upper}),i
do i={lower},{upper}
a(i)=i-({lower})+1
end do
call change(a({first}:{last}:{step}))
print *,a
print *,checksum(a),size(a)
contains
subroutine change(x)
integer, intent(inout) :: x({dummy_lower}:)
integer :: lo,hi
lo={dummy_lower}+({inner_first})
hi={dummy_lower}+({inner_last})
call next(x(lo:hi:{inner_step}))
x=x+7
end subroutine change
subroutine next(y)
integer, intent(inout) :: y(7:)
integer :: j
do j=1,size(y)
y(7+j-1)=y(7+j-1)+100*j
end do
end subroutine next
integer function checksum(x) result(r)
integer, intent(in) :: x(:)
integer :: j
r=0
do j=1,size(x)
r=r+x(j)
end do
end function checksum
end program main
'''
        yield dict(name=f'binding_matrix_{number:03d}', source=source,
                   parameters=dict(lower=lower,extent=extent,stride=step,
                                   dummy_lower=dummy_lower,inner_stride=inner_step),
                   expected_stdout=' '.join(map(str,data+[sum(data),len(data)])))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate')
    parser.add_argument('--gfortran')
    parser.add_argument('--result', default='section-matrix-results.json')
    args = parser.parse_args()
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran')
    records = []
    for case in fixtures():
        row = dict(case=case,errors=[])
        with tempfile.TemporaryDirectory(prefix='argument-section-matrix-') as folder:
            folder=Path(folder); source=folder/'case.f90'; binary=folder/'reference'
            source.write_text(case['source'])
            if args.gfortran:
                compiled=execute([args.gfortran,'-std=f2018','-pedantic-errors',
                                  '-fcheck=all','-O0',source,'-o',binary],folder)
                row['gnu_compile']=compiled
                if compiled['code'] != 0:
                    row['errors'].append('GNU compile failed')
                else:
                    ran=execute([binary],folder);row['gnu_run']=ran
                    if ran['code'] != 0 or not compare(ran['out'],case['expected_stdout']):
                        row['errors'].append('GNU/Python oracle mismatch')
            if args.candidate:
                check=execute([args.candidate,'--check',source],folder)
                ran=execute([args.candidate,source],folder)
                row['check'],row['run']=check,ran
                if check['code'] != 0 or check['out'].strip():
                    row['errors'].append('candidate check failed/output leak')
                if ran['code'] != 0 or not compare(ran['out'],case['expected_stdout']):
                    row['errors'].append('candidate/Python oracle mismatch')
        records.append(row)
        print(case['name']+': '+('FAIL '+', '.join(row['errors']) if row['errors'] else 'PASS'),flush=True)
    summary=dict(total=len(records),failed=sum(bool(r['errors']) for r in records))
    if args.candidate: summary['candidate_checked']=len(records)
    if args.gfortran: summary['gnu_checked']=len(records)
    result=dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),summary=summary,records=records)
    if args.candidate:
        result['candidate_sha256']=hashlib.sha256(Path(args.candidate).read_bytes()).hexdigest()
    (ROOT/args.result).write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
    return bool(summary['failed'])


if __name__=='__main__':
    raise SystemExit(main())
