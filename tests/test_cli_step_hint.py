#!/usr/bin/env python3
"""CLI-only budget advice; internal API text is covered by the native test."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('executable',type=Path)
p.add_argument('--baseline',type=Path)
a=p.parse_args()
exe=str(a.executable.resolve())
checks=0

def run(arguments,binary=exe):
    return subprocess.run([binary,*map(str,arguments)],text=True,capture_output=True,timeout=20)

def assert_ok(condition,details):
    global checks
    assert condition,details
    checks+=1

with tempfile.TemporaryDirectory(prefix='cli-step-hint-') as folder:
    folder=Path(folder)
    loop=folder/'loop.f90'
    loop.write_text('program p\nimplicit none\ninteger::x\ndo\nx=1\nend do\nend program\n')
    finite=folder/'finite.f90'
    finite.write_text('program p\nimplicit none\ninteger::x\nx=1\nend program\n')
    for options,limit in [([],1000000),(['--max-steps','1'],1),(['--max-steps','37'],37),
                          (['--max-steps','0000037'],37),(['--max-steps','1','--max-steps','19'],19)]:
        args=[*options,loop]
        r=run(args)
        expected=f'execution step limit exceeded (current limit: {limit}); use --max-steps N to set the execution budget (positive 64-bit integer)'
        match=re.fullmatch(re.escape(str(loop))+r':([1-9][0-9]*):([1-9][0-9]*): '+re.escape(expected)+r'\n',r.stderr)
        assert_ok(r.returncode==2 and r.stdout=='' and bool(match),(options,r.returncode,r.stdout,r.stderr))
        if a.baseline:
            b=run(args,str(a.baseline.resolve()))
            old=re.fullmatch(re.escape(str(loop))+r':([1-9][0-9]*):([1-9][0-9]*): execution step limit exceeded\n',b.stderr)
            assert_ok(b.returncode==2 and b.stdout=='' and bool(old) and match.groups()==old.groups(),(b.stderr,r.stderr))
    for options in [[],['--max-steps','1']]:
        r=run(['--check',*options,loop])
        assert_ok(r.returncode==0 and r.stdout=='' and r.stderr=='',r)
    r=run(['--max-steps','1',finite]);assert_ok(r.returncode==2 and '--max-steps N' in r.stderr,r)
    for limit in ['10','9223372036854775807']:
        r=run(['--max-steps',limit,finite]);assert_ok(r.returncode==0 and r.stdout=='' and r.stderr=='',r)
    bad=folder/'undefined.f90';bad.write_text('program p\nimplicit none\ninteger::x\nprint *,x\nend program\n')
    r=run([bad]);assert_ok(r.returncode==2 and r.stdout=='' and 'uninitialized' in r.stderr.lower() and 'current limit' not in r.stderr and '--max-steps N' not in r.stderr,r)
    r=run(['--max-steps','0',finite]);assert_ok(r.returncode==1 and r.stdout=='' and 'must be positive' in r.stderr and 'current limit' not in r.stderr,r)
    r=run(['--max-steps','9223372036854775808',finite]);assert_ok(r.returncode==1 and r.stdout=='' and 'Invalid --max-steps' in r.stderr and 'current limit' not in r.stderr,r)
print(f'PASS: {checks} CLI step-budget checks')
