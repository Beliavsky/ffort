#!/usr/bin/env python3
"""Frozen bounded process queries, independent GNU oracles and fail-closed boundaries."""
from decimal import Decimal, InvalidOperation
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import platform
import re
import shutil
import subprocess
import sys
import tempfile

from generate_cases import build

ROOT=Path(__file__).resolve().parent
INTEGER=re.compile(r'[+-]?[0-9]+\Z')
REAL=re.compile(r'[+-]?(?:(?:[0-9]+\.?[0-9]*)|(?:\.[0-9]+))(?:[EeDd][+-]?[0-9]+)?\Z')
NONFINITE=re.compile(r'[+-]?(?:s?nan|inf(?:inity)?)(?:\([^)]*\)|[0-9]*)?\Z',re.IGNORECASE)
BINARY64_MAX=Decimal.from_float(sys.float_info.max)

def sha256(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def execute(argv,cwd=None,executable=None,timeout=15):
    argv=[str(value) for value in argv]
    try:
        proc=subprocess.run(argv,cwd=cwd or ROOT,executable=executable,stdin=subprocess.DEVNULL,
                            capture_output=True,timeout=timeout)
        return dict(code=proc.returncode,out=proc.stdout.decode('latin-1'),
                    err=proc.stderr.decode('latin-1'))
    except subprocess.TimeoutExpired as exc:
        def decode(value): return value.decode('latin-1') if isinstance(value,bytes) else value or ''
        return dict(code=None,out=decode(exc.stdout),err='TIMEOUT '+decode(exc.stderr))
    except OSError as exc:
        return dict(code=None,out='',err=str(exc))

def token_records(text):
    """Keep record boundaries/terminators; only spaces and tabs separate tokens."""
    parts=re.split(r'(\r\n|\r|\n)',text)
    records=[]
    for index in range(0,len(parts),2):
        body=parts[index]
        ending=parts[index+1] if index+1<len(parts) else ''
        tokens=re.split(r'[ \t]+',body.strip(' \t')) if body.strip(' \t') else []
        records.append((tokens,ending,body if not tokens else None))
    return records

def compare(actual,expected,mode='lines'):
    """Byte-exact CHARACTER records; optional exact Decimal tokens within records.

    Captures are reversible Latin-1 byte maps, not lossy Unicode text. Numeric
    token mode is unused by the current corpus and has no tolerance allowance.
    """
    if mode not in ('lines','tokens'): raise ValueError('Unknown comparison mode: '+mode)
    if expected=='': return actual==''
    if mode=='lines': return actual==expected
    got,want=token_records(actual),token_records(expected)
    if len(got)!=len(want): return False
    for (a_tokens,a_end,a_blank),(b_tokens,b_end,b_blank) in zip(got,want):
        if a_end!=b_end or a_blank!=b_blank or len(a_tokens)!=len(b_tokens): return False
        for a,b in zip(a_tokens,b_tokens):
            if NONFINITE.fullmatch(a) or NONFINITE.fullmatch(b): return False
            if REAL.fullmatch(b):
                if not REAL.fullmatch(a): return False
                if INTEGER.fullmatch(b) and not INTEGER.fullmatch(a): return False
                try:
                    x=Decimal(a.replace('d','e').replace('D','E'))
                    y=Decimal(b.replace('d','e').replace('D','E'))
                    if not x.is_finite() or not y.is_finite(): return False
                    if x.copy_abs()>BINARY64_MAX or y.copy_abs()>BINARY64_MAX: return False
                    if x!=y: return False
                    if x.is_zero() and x.is_signed()!=y.is_signed(): return False
                except (InvalidOperation,ValueError): return False
            elif a!=b: return False
    return True

def expected_output(case,cwd):
    expected=case['expected_stdout']
    if isinstance(expected,str): return expected
    kind=expected['type']
    if kind=='cwd_trim': return str(cwd)+'\n'
    value=str(cwd)
    if kind=='original_exe_name': value+='\\'+case['source_spelling']
    elif kind!='cwd': raise ValueError('Unknown expected output kind')
    width=expected['width']
    if len(value)>width: raise ValueError('Controlled test path exceeds output width')
    return '['+value.ljust(width)+']\n'

def diagnostics_only(stderr):
    # Never let a filename or source excerpt satisfy a required error phrase.
    return '\n'.join(re.sub(r'^.*?:\d+:\d+:\s*','',line) for line in stderr.splitlines()
                     if not re.match(r'^\s*\d+\s*\|',line))

def candidate_errors(case,check,run,expected):
    category=case['category']
    check_code=0 if category in ('success','runtime') else 1
    run_code={'success':0,'runtime':2,'reject':1}[category]
    errors=[]
    for name,stage,code in [('check',check,check_code),('run',run,run_code)]:
        if stage['code']!=code: errors.append(f'{name}: expected exit {code}, got {stage["code"]}')
        if code and not stage['err'].strip(): errors.append(name+': missing error diagnostic')
        if not code and stage['err']!='': errors.append(name+': unexpected success diagnostic')
    if check['out']!='': errors.append('check stdout leak')
    if not compare(run['out'],expected,case.get('compare_mode','lines')): errors.append('stdout mismatch/leak')
    if case.get('diagnostic') and case['diagnostic'].lower() not in diagnostics_only(run['err']).lower():
        errors.append('missing diagnostic '+case['diagnostic'])
    return errors

def gnu_compile_errors(case,result):
    errors=[]
    reject=case['baseline']=='reject'
    expected=1 if reject else 0
    if result['code']!=expected: errors.append(f'GNU compile: expected exit {expected}, got {result["code"]}')
    if result['out']!='': errors.append('GNU compile stdout leak')
    if reject and not result['err'].strip(): errors.append('GNU missing rejection diagnostic')
    if not reject and result['err']!='': errors.append('GNU unexpected successful compile diagnostic')
    return errors

def gnu_success_errors(case,result,expected):
    errors=[]
    if result['code']!=0: errors.append('GNU execution failed')
    if not compare(result['out'],expected,case.get('compare_mode','lines')): errors.append('GNU stdout mismatch/leak')
    if result['err']!='': errors.append('GNU unexpected success diagnostic')
    return errors

def verify_frozen():
    files=build()
    for name,data in files.items():
        if not (ROOT/name).is_file() or (ROOT/name).read_bytes()!=data:
            raise ValueError('Frozen generator replay mismatch: '+name)
    expected={name for name in files if name.startswith('cases/')}
    actual={str(path.relative_to(ROOT)) for path in (ROOT/'cases').glob('*.f90')}
    if actual!=expected: raise ValueError('Frozen fixture inventory changed')
    return json.loads(files['manifest.json'])['cases']

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate',help='Single executable path, never a shell command')
    parser.add_argument('--gfortran',help='GNU Fortran executable')
    parser.add_argument('--only',default='',help='Case-name regular expression')
    parser.add_argument('--result',default='results.json')
    args=parser.parse_args()
    if not args.candidate and not args.gfortran: parser.error('Supply --candidate and/or --gfortran')
    try: cases=verify_frozen()
    except (OSError,ValueError) as exc: parser.error(str(exc))
    records=[]
    initial_hash=None
    if args.candidate:
        args.candidate=str(Path(args.candidate).resolve())
        if not Path(args.candidate).is_file(): parser.error('Candidate does not exist')
        initial_hash=sha256(args.candidate)
    if args.gfortran:
        resolved=shutil.which(args.gfortran)
        if not resolved: parser.error('GNU Fortran executable not found')
        args.gfortran=str(Path(resolved).resolve())
    for case in cases:
        if not re.search(args.only,case['name']): continue
        row=dict(case=case,errors=[])
        with tempfile.TemporaryDirectory(prefix='process-query-') as folder:
            cwd=Path(folder)
            source=cwd/case['source_spelling']
            source.write_bytes((ROOT/case['source']).read_bytes())
            expected=expected_output(case,cwd)
            if args.gfortran:
                flags=['-std='+case['dialect'],'-pedantic-errors','-fcheck=all','-O0']
                if case['baseline']=='run':
                    binary=cwd/'reference'
                    command=[args.gfortran]+flags+[case['source_spelling'],'-o',str(binary)]
                else:
                    binary=None
                    command=[args.gfortran]+flags+['-c',case['source_spelling'],'-o','reference.o']
                compiled=execute(command,cwd)
                row['gnu_compile']=compiled
                row['gnu_flags']=flags
                row['errors']+=gnu_compile_errors(case,compiled)
                if not row['errors'] and case['baseline']=='run':
                    # Do not call [binary]: the virtual program name is the source-file spelling.
                    ran=execute([case['source_spelling']],cwd,executable=str(binary))
                    row['gnu_run']=ran
                    row['errors']+=gnu_success_errors(case,ran,expected)
            if args.candidate:
                checked=execute([args.candidate,'--check',case['source_spelling']],cwd)
                ran=execute([args.candidate]+case['args']+[case['source_spelling']],cwd)
                row['check'],row['run']=checked,ran
                row['errors']+=candidate_errors(case,checked,ran,expected)
            # Literal test expectations remain portable; dynamic cwd evidence is identified, not frozen into source.
            row['expected_stdout']=expected
        print(case['name']+(': FAIL '+', '.join(row['errors']) if row['errors'] else ': PASS'),flush=True)
        records.append(row)
    if not records: parser.error('No cases selected')
    summary=dict(total=len(records),failed=sum(bool(row['errors']) for row in records),
                 candidate_checked=len(records) if args.candidate else 0,
                 gnu_executed=sum('gnu_run' in row for row in records),
                 gnu_compile_only=sum(args.gfortran is not None and row['case']['baseline']=='compile' for row in records),
                 gnu_compile_rejections=sum(args.gfortran is not None and row['case']['baseline']=='reject' for row in records))
    result=dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),platform=platform.platform(),
                python_version=platform.python_version(),summary=summary,records=records,
                manifest_sha256=sha256(ROOT/'manifest.json'),provenance_sha256=sha256(ROOT/'provenance.json'),
                generator_sha256=sha256(ROOT/'generate_cases.py'),runner_sha256=sha256(Path(__file__)),
                source_sha256={case['source']:sha256(ROOT/case['source']) for case in cases})
    if args.gfortran: result['gfortran_version']=execute([args.gfortran,'--version'])
    if args.candidate:
        result['candidate_version']=execute([args.candidate,'--version'])
        result['candidate_sha256']=initial_hash
        try: final_hash=sha256(args.candidate)
        except OSError: final_hash=None
        result['candidate_final_sha256']=final_hash
        if final_hash!=initial_hash:
            result['candidate_changed_during_run']=True
            summary['failed']+=1
            print('FAIL: Candidate executable changed during verification')
    (ROOT/args.result).write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
    return bool(summary['failed'])

if __name__=='__main__': raise SystemExit(main())
