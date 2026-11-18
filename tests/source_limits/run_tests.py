#!/usr/bin/env python3
"""Configured byte/token limits through the real CLI, with a GNU output oracle."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
BASE = b'program p\nimplicit none\nprint *,42\nend program p\n'


def padded(size, newline=b'\n'):
    base = BASE.replace(b'\n', newline)
    remaining = size-len(base)
    line = b'!'+b'x'*126+newline
    result = line*(remaining//len(line))
    remaining %= len(line)
    if remaining:
        # A short final comment need not end with a newline if prepended to a
        # full comment, but it must not consume PROGRAM. Add whitespace instead.
        if remaining < len(newline)+1:
            result += b' '*remaining
        else:
            result += b'!'+b'x'*(remaining-len(newline)-1)+newline
    result += base
    assert len(result) == size
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--gfortran', required=True)
    parser.add_argument('--result', type=Path, default=Path(__file__).with_name('results.json'))
    args = parser.parse_args()
    limits_text = (ROOT/'src/fi_limits.f90').read_text()
    limits = {name: int(re.search(rf'{name}\s*=\s*(\d+)', limits_text, re.I).group(1))
              for name in ('max_source_bytes', 'max_tokens')}
    cap = limits['max_source_bytes']
    token_cap = limits['max_tokens']
    assert 65537 < cap < 2147483645 and 20001 < token_cap < cap
    exe = args.candidate.resolve()
    results = []

    def run(command, cwd):
        proc = subprocess.run([str(x) for x in command], cwd=cwd, capture_output=True,
                              text=True, timeout=90, stdin=subprocess.DEVNULL)
        return {'code': proc.returncode, 'stdout': proc.stdout, 'stderr': proc.stderr}

    with tempfile.TemporaryDirectory(prefix='fi-source-limits-') as folder:
        directory = Path(folder)

        def check(name, data, success, diagnostic='', output='42', oracle=False):
            path = directory/(name+'.f90')
            path.write_bytes(data)
            record = {'name': name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
            for mode in ('check', 'run'):
                got = run([exe]+(['--check'] if mode == 'check' else [])+[path], directory)
                record[mode] = got
                assert got['code'] == (0 if success else 1), (name, mode, got)
                if success:
                    assert got['stdout'].strip() == ('' if mode == 'check' else output), (name, mode, got)
                    assert not got['stderr'], (name, mode, got)
                else:
                    assert not got['stdout'], (name, mode, got)
                    assert diagnostic in got['stderr'], (name, mode, got)
            if oracle:
                target = directory/(name+'.exe')
                got = run([args.gfortran, '-std=f2018', '-pedantic-errors', '-fcheck=all', path, '-o', target], directory)
                record['oracle_compile'] = got
                assert got['code'] == 0, (name, got)
                got = run([target], directory)
                record['oracle_run'] = got
                assert got['code'] == 0 and got['stdout'].strip() == output, (name, got)
            results.append(record)

        check('past_old_byte_limit', padded(65537), True, oracle=True)
        check('source_below_limit', padded(cap-1), True)
        check('source_at_limit', padded(cap), True, oracle=True)
        check('crlf_source_at_limit', padded(cap, b'\r\n'), True, oracle=True)
        check('source_above_limit', padded(cap+1), False, f'{cap}-byte')
        # Five real tokens plus the synthetic separator and EOF.
        tiny = b'program p\nend\n'
        check('past_old_token_limit', b'\n'*(20001-7)+tiny, True, output='')
        check('tokens_at_limit', b'\n'*(token_cap-7)+tiny, True, output='')
        check('tokens_above_limit', b'\n'*(token_cap-6)+tiny, False, 'Token limit exceeded')
        # The lexical limit remains independent of the enlarged source capacity.
        check('long_line_still_rejected', b'program p\n'+b' '*132+b'x\nend\n',
              False, '132 columns')
        check('nonascii_still_rejected', b'program p\n\x00\nend\n', False, 'Only ASCII')
    args.result.parent.mkdir(parents=True, exist_ok=True)
    args.result.write_text(json.dumps({'candidate_sha256': hashlib.sha256(exe.read_bytes()).hexdigest(), 'limits': limits, 'cases': results}, indent=2)+'\n')
    print(f'PASS: {len(results)} CLI source/token cases, 3 independent GNU Fortran comparisons')


if __name__ == '__main__':
    main()
