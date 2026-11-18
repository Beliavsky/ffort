#!/usr/bin/env python3
"""Additional CLI/resource-boundary regressions; no compiler oracle is claimed."""
import argparse
from pathlib import Path
import subprocess
import tempfile
import re

ROOT=Path(__file__).resolve().parents[1]
limit_text=(ROOT/'src/fi_limits.f90').read_text()
source_limit=int(re.search(r'max_source_bytes\s*=\s*(\d+)',limit_text,re.I).group(1))
symbol_limit=int(re.search(r'max_symbols\s*=\s*(\d+)',limit_text,re.I).group(1))

parser=argparse.ArgumentParser()
parser.add_argument('executable',type=Path)
args=parser.parse_args()
exe=str(args.executable.resolve())
passed=0

def check(argv,code,diagnostic):
    global passed
    r=subprocess.run([exe]+argv,stdin=subprocess.DEVNULL,capture_output=True,text=True,timeout=10)
    assert r.returncode==code,(argv,r.returncode,r.stderr)
    assert not r.stdout.strip(),(argv,r.stdout)
    assert diagnostic in r.stderr,(argv,r.stderr,diagnostic)
    passed+=1

with tempfile.TemporaryDirectory(prefix='fi-cli-') as folder:
    d=Path(folder)
    sources={
      'empty': ('','Expected END PROGRAM'),
      'nonascii': ('program p\nimplicit none\n\x00\nend program\n','Only ASCII'),
      'long_line': ("program p\nimplicit none\nprint *,'"+'a'*140+"'\nend program\n",'132 columns'),
      'large': ('!'+'a'*source_limit,f'{source_limit}-byte'),
      'nested': ('program p\nimplicit none\n'+'if(.true.) then\n'*65+'end if\n'*65+'end program\n','Block nesting'),
      'symbols': ('program p\nimplicit none\n'+''.join(f'integer :: x{i}\n' for i in range(symbol_limit+1))+'end program\n','Symbol limit'),
      'name': ('program p\nimplicit none\ninteger :: '+'x'*64+'\nend program\n','Name exceeds'),
      'print_items': ('program p\nimplicit none\nprint *,'+','.join('1' for _ in range(65))+'\nend program\n','132 columns'),
      'intrinsic_args': ('program p\nimplicit none\nprint *, min('+','.join('1' for _ in range(17))+')\nend program\n','argument limit'),
    }
    for name,(source,diagnostic) in sources.items():
        p=d/(name+'.f90');p.write_text(source)
        check(['--check',str(p)],1,diagnostic)
    p=d/'ok.f90';p.write_text('program p\nimplicit none\ninteger :: x\nx=1\nprint *,x\nend program\n')
    check([],1,'Expected END PROGRAM')  # Empty nonterminal stdin is now batch source.
    check([str(d/'missing.f90')],1,'Cannot read')
    check(['--unknown'],1,'Unknown option')
    check(['--max-steps','0',str(p)],1,'must be positive')
    check(['--max-steps','1,2',str(p)],1,'decimal integer')
    check(['--max-steps','9999999999999999999999999',str(p)],1,'Invalid --max-steps')
    check(['--max-steps','1',str(p)],2,'step limit')
    check([str(p),str(p)],1,'exactly one source')
print(f'PASS: {passed} CLI/resource contracts')
