#!/usr/bin/env python3
"""Large metadata through both recognizers, runtime and an independent GNU oracle."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def utility_scale():
    """Exactly 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2997 symbols."""
    public = [f'g{i}' for i in range(1, 125)] + [f'p{i}' for i in range(125, 423)] + ['p551']
    lines = ['module library', 'implicit none', 'private']
    lines += [f'public :: {name}' for name in public]
    for i in range(1, 125):
        lines += [f'interface g{i}', f'module procedure p{i}', 'end interface']
    lines += ['contains']
    for i in range(1, 552):
        lines += [f'subroutine p{i}(x)', 'integer, intent(inout) :: x', 'integer :: a,b,c,d',
                  f'x=x+{i}', 'end subroutine']
    lines += ['end module', 'program main', 'use library, only: &']
    lines += [name + (', &' if i < len(public)-1 else '') for i, name in enumerate(public)]
    lines += ['implicit none', 'integer :: x'] + [f'integer :: v{i}' for i in range(1, 242)]
    lines += ['x=0', 'call g1(x)', 'call p551(x)', 'print *,x', 'end']
    return '\n'.join(lines)+'\n'


def procedure_chain(n, cycle=False):
    lines = ['module library', 'contains']
    for i in range(1, n+1):
        lines += [f'subroutine p{i}()']
        if i < n:
            lines += [f'call p{i+1}()']
        elif cycle:
            lines += ['call p1()']
        lines += ['end subroutine']
    return '\n'.join(lines+['end module', 'program main', 'print *,1', 'end'])+'\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--gfortran', required=True)
    parser.add_argument('--result', type=Path, default=Path(__file__).with_name('results.json'))
    args = parser.parse_args()
    exe = args.candidate.resolve()
    limit_text = (ROOT/'src/fi_limits.f90').read_text()
    limits = {name: int(re.search(rf'{name}\s*=\s*(\d+)', limit_text).group(1))
              for name in ('max_symbols', 'max_procedures', 'max_generics', 'max_access_names', 'max_only_names')}
    records = []
    with tempfile.TemporaryDirectory(prefix='fi-metadata-') as folder:
        folder = Path(folder)

        def run(command):
            p = subprocess.run([str(x) for x in command], cwd=folder, capture_output=True,
                               text=True, timeout=180, stdin=subprocess.DEVNULL)
            return dict(status=p.returncode, stdout=p.stdout, stderr=p.stderr)

        def check(name, source, output='', diagnostic='', oracle=False):
            path = folder/(name+'.f90')
            path.write_text(source)
            record = dict(name=name, source_bytes=len(source), source_sha256=hashlib.sha256(source.encode()).hexdigest())
            for mode in ('check', 'run'):
                got = run([exe]+(['--check'] if mode == 'check' else [])+[path])
                record[mode] = got
                assert got['status'] == (1 if diagnostic else 0), (name, mode, got)
                assert got['stdout'].strip() == (output if mode == 'run' and not diagnostic else ''), (name, mode, got)
                if diagnostic:
                    assert diagnostic in got['stderr'], (name, mode, got)
                else:
                    assert got['stderr'] == '', (name, mode, got)
            if oracle:
                target = folder/(name+'.exe')
                got = run([args.gfortran, '-std=f2018', '-pedantic-errors', '-fcheck=all', path, '-o', target])
                record['oracle_compile'] = got
                assert got['status'] == 0, (name, got)
                got = run([target])
                record['oracle_run'] = got
                assert got['status'] == 0 and got['stdout'].strip() == output, (name, got)
            records.append(record)

        check('utilities_metadata_scale', utility_scale(), output='552', oracle=True)
        check('procedure_capacity', procedure_chain(limits['max_procedures']), output='1')
        check('long_recursive_cycle', procedure_chain(80, cycle=True), diagnostic='Recursive module function cycles')
        check('above_procedure_capacity', procedure_chain(limits['max_procedures']+1), diagnostic='Procedure limit exceeded')
        for n in (limits['max_symbols'], limits['max_symbols']+1):
            source='program main\n'+'\n'.join(f'integer :: v{i}' for i in range(n))+'\nend\n'
            check(f'symbol_count_{n}', source, diagnostic='Symbol limit exceeded' if n > limits['max_symbols'] else '')
        n=limits['max_generics']
        source='module library\n'+''.join(f'interface g{i}\nmodule procedure worker\nend interface\n' for i in range(n))
        source+='contains\nsubroutine worker()\nend subroutine\nend module\nprogram main\nprint *,1\nend\n'
        check('generic_capacity', source, output='1')
        raw=(ROOT/'tests/utilities_slices/source/xutilities.f90').read_bytes()
        original=folder/'xutilities.f90'
        original.write_bytes(raw)
        array_cap=int(re.search(r'max_array_elements\s*=\s*(\d+)',(ROOT/'src/fi_ir.f90').read_text()).group(1))
        got=run([exe,'--check',original])
        assert got['status']==1 and got['stdout']=='' and f':9329:55: Total array element limit exceeded ({array_cap})' in got['stderr'], got
        records.append(dict(name='untouched_utilities',source_bytes=len(raw),source_sha256=hashlib.sha256(raw).hexdigest(),check=got))
    result=dict(candidate_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(),limits=limits,cases=records)
    args.result.write_text(json.dumps(result,indent=2)+'\n')
    print(f'PASS: {len(records)} metadata CLI cases, utility-scale GNU Fortran comparison')


if __name__=='__main__':
    main()
