"""Exact source diagnostics and GNU checks for bounded PURE internal WRITE."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import tempfile

R = Path(__file__).resolve().parent
CRASH = re.compile(r'backtrace|traceback|fortran runtime error|internal compiler error|'
                   r'segmentation fault|sigsegv|sigabrt|program received signal|'
                   r'core dumped|addresssanitizer|undefinedbehaviorsanitizer|'
                   r'stack trace|\bice\b', re.IGNORECASE)

def run(args, cwd):
    p = subprocess.run([str(x) for x in args], cwd=cwd, capture_output=True, timeout=60)
    return dict(code=p.returncode, out=p.stdout.decode(), err=p.stderr.decode())

def clean_host(result):
    return not CRASH.search(result['out']+'\n'+result['err'])

def expected_diagnostic(case, source):
    d = case['diagnostic']
    return f"{source}:{d['line']}:{d['column']}: {d['message']}\n"

def candidate_matches(case, check, actual, source):
    if not clean_host(check) or not clean_host(actual):
        return False
    if case['kind'] == 'pass':
        return (check == dict(code=0, out='', err='') and
                actual == dict(code=0, out=case['expected'], err=''))
    expected = dict(code=1, out='', err=expected_diagnostic(case, source))
    return check == expected and actual == expected

def oracle_matches(case, compiled, reference):
    if not clean_host(compiled):
        return False
    if compiled['code'] != (0 if case['gnu'] == 'pass' else 1):
        return False
    if case['gnu'] == 'fail' and not compiled['err']:
        return False
    if case['kind'] == 'pass':
        return reference == dict(code=0, out=case['expected'], err='')
    # Policy/unsupported and invalid-source cases are never GNU executions.
    return reference is None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--candidate', type=Path, required=True)
    ap.add_argument('--gfortran', default='gfortran')
    ap.add_argument('--result', type=Path, default=R/'results.json')
    a = ap.parse_args()
    a.candidate = a.candidate.resolve()
    rows = []
    with tempfile.TemporaryDirectory(prefix='pure-internal-write-') as tmp:
        for case in json.loads((R/'manifest.json').read_text()):
            source = R/'cases'/(case['name']+'.f90')
            assert hashlib.sha256(source.read_bytes()).hexdigest() == case['sha256']
            check = run([a.candidate, '--check', source], tmp)
            actual = run([a.candidate, source], tmp)
            compiled = run([a.gfortran, '-std=f2018', '-pedantic-errors', '-fcheck=all',
                            '-ffpe-trap=invalid,zero,overflow', source, '-o', Path(tmp)/'ref'], tmp)
            reference = None
            if case['kind'] == 'pass' and compiled['code'] == 0:
                reference = run([Path(tmp)/'ref'], tmp)
            ok = (candidate_matches(case, check, actual, source) and
                  oracle_matches(case, compiled, reference))
            rows.append(dict(**case, passed=bool(ok), check=check, run=actual,
                             compile=compiled, reference=reference))
            print(('PASS' if ok else 'FAIL'), case['name'])
            if not ok:
                print(check, actual, compiled)
    result = dict(candidate_sha256=hashlib.sha256(a.candidate.read_bytes()).hexdigest(),
                  total=len(rows), failed=sum(not x['passed'] for x in rows), cases=rows)
    a.result.write_text(json.dumps(result, indent=2)+'\n')
    return bool(result['failed'])

if __name__ == '__main__':
    raise SystemExit(main())
