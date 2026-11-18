#!/usr/bin/env python3
"""Independent array-constructor implied-DO oracles, strict comparisons and fail-closed checks.

No shell, fpm, candidate build, or GNU fallback is used. GNU compilation/runs and
candidate --check/execution are separate processes. Only valid success programs
execute under GNU; negative fixtures are compile-only. Compile-only negatives never execute under GNU, even when the
candidate is missing or fails. --record-oracles is an explicit maintainer operation.
"""
from pathlib import Path
from decimal import Decimal, InvalidOperation, localcontext
import argparse
import datetime
import hashlib
import json
import re
import subprocess
import tempfile
import contextlib

ROOT = Path(__file__).resolve().parent
FLAGS = ['-std=f2018', '-pedantic-errors', '-fcheck=all', '-O0', '-ffree-line-length-none']
INTEGER = re.compile(r'^[+-]?\d+$')
NUMBER = re.compile(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eEdD][+-]?\d+)?$')
NONFINITE = re.compile(r'[+-]?(?:inf(?:inity)?|nan(?:\([^)]*\))?)', re.IGNORECASE)

# A rounded decimal just above HUGE(binary64) can still describe a finite value.
# The exact round-to-nearest overflow midpoint itself, or larger, cannot.
with localcontext() as _context:
    _context.prec = 400
    _REAL_OVERFLOW_MIDPOINT = Decimal(2)**1024 - Decimal(2)**970


def sha(data):
    return hashlib.sha256(data).hexdigest()


def execute(argv, cwd=None, timeout=45):
    try:
        proc = subprocess.run([str(arg) for arg in argv], cwd=cwd or ROOT,
                              capture_output=True, timeout=timeout,
                              stdin=subprocess.DEVNULL)
        # Latin-1 is a reversible bytes-to-text map, with no newline conversion.
        return dict(code=proc.returncode, out=proc.stdout.decode('latin1'),
                    err=proc.stderr.decode('latin1'))
    except subprocess.TimeoutExpired as exc:
        return dict(code=None, out=(exc.stdout or b'').decode('latin1'),
                    err='TIMEOUT '+(exc.stderr or b'').decode('latin1'))
    except OSError as exc:
        return dict(code=None, out='', err=str(exc))


def finite_decimal(token):
    value = Decimal(token.replace('D', 'E').replace('d', 'e'))
    return value if value.is_finite() and value.copy_abs() < _REAL_OVERFLOW_MIDPOINT else None


def numeric_token_equal(got, want):
    """Exact integers/Decimal values; no float rounding, tolerances or NaN equality."""
    if NONFINITE.fullmatch(got) or NONFINITE.fullmatch(want):
        return False
    ga, wa = bool(NUMBER.fullmatch(got)), bool(NUMBER.fullmatch(want))
    if ga != wa:
        return False
    if not ga:
        return got == want
    if INTEGER.fullmatch(got) and INTEGER.fullmatch(want):
        if int(got) != int(want):
            return False
        return int(got) != 0 or got.startswith('-') == want.startswith('-')
    try:
        a = finite_decimal(got)
        b = finite_decimal(want)
    except InvalidOperation:
        return False
    return a is not None and b is not None and a == b and (a != 0 or a.is_signed() == b.is_signed())


def compare(actual, expected, mode='numeric_records'):
    if mode == 'exact':
        return actual == expected
    if mode == 'numeric_prefix_exact':
        if actual.endswith('\n') != expected.endswith('\n') or '\r' in actual or '\r' in expected:
            return False
        aa, bb = actual.split('\n'), expected.split('\n')
        if len(aa) != len(bb):
            return False
        for ar, br in zip(aa, bb):
            a = re.fullmatch(r' *([+-]?\d+)( .*)', ar)
            b = re.fullmatch(r' *([+-]?\d+)( .*)', br)
            if bool(a) != bool(b):
                return False
            if a:
                if not numeric_token_equal(a[1], b[1]) or a[2] != b[2]:
                    return False
            elif ar != br:
                return False
        return True
    if mode != 'numeric_records':
        raise ValueError('Unknown comparator '+mode)
    # Preserve record count, blank records, final newline and carriage returns.
    # Only list-directed horizontal field padding is processor-dependent.
    if actual.endswith('\n') != expected.endswith('\n') or '\r' in actual or '\r' in expected:
        return False
    a, b = actual.split('\n'), expected.split('\n')
    if len(a) != len(b):
        return False
    for ar, br in zip(a, b):
        aa, bb = ar.split(), br.split()
        if len(aa) != len(bb) or not all(numeric_token_equal(x, y) for x, y in zip(aa, bb)):
            return False
    return True


def expected_output(case):
    return (ROOT/case['expected_file']).read_bytes().decode('latin1') if 'expected_file' in case else case['expected_stdout']


def candidate_errors(case, checked, ran, expected):
    category = case['category']
    wanted_check = 1 if category == 'reject' else 0
    wanted_run = {'success': 0, 'reject': 1, 'runtime': 2}[category]
    errors = []
    for label, stage, wanted in [('check', checked, wanted_check), ('run', ran, wanted_run)]:
        if stage['code'] != wanted:
            errors.append(f'{label}: expected exit {wanted}, got {stage["code"]}')
        if wanted == 0 and stage['err'] != '':
            errors.append(label+': successful stderr is not truly empty')
        if wanted != 0 and not stage['err'].strip():
            errors.append(label+': missing diagnostic')
    if checked['out'] != '':
        errors.append('check: stdout is not truly empty')
    if category != 'success' and ran['out'] != expected:
        errors.append('failed statement leaked or changed completed stdout')
    elif category == 'success' and not compare(ran['out'], expected, case['compare_mode']):
        errors.append('stdout mismatch')
    if case.get('diagnostic') and case['diagnostic'].lower() not in ran['err'].lower():
        errors.append('missing diagnostic fragment: '+case['diagnostic'])
    return errors


def validate_case(case):
    if case['category'] not in ('success', 'runtime', 'reject') or case['baseline'] not in ('run', 'compile', 'reject'):
        raise ValueError('Unknown candidate/GNU category')
    if (case['category'] == 'success') != (case['baseline'] == 'run'):
        raise ValueError('Only success fixtures may execute with GNU')
    if case['category'] == 'runtime' and case['baseline'] != 'compile':
        raise ValueError('Safety failures must use compile-only GNU')
    if case['category'] != 'success' and case.get('expected_stdout','') != case.get('completed_stdout',''):
        raise ValueError('Failures may emit only previously completed records')
    source = ROOT/case['source']
    if sha(source.read_bytes()) != case['source_sha256']:
        raise ValueError('Source fingerprint changed: '+case['name'])


def check_original_sources():
    provenance = json.loads((ROOT/'provenance.json').read_text())
    original = ROOT/provenance['original_utility_source']
    raw = original.read_bytes()
    if sha(raw) != provenance['original_utility_sha256']:
        raise ValueError('Original utility source fingerprint changed')
    lines = raw.splitlines(keepends=True)
    for item in provenance['extracts']:
        start, end = item['original_lines']
        body = b''.join(lines[start-1:end])
        if sha(body) != item['body_sha256'] or len(body) != item['body_bytes']:
            raise ValueError('Original body fingerprint changed: '+item['name'])
        harness = (ROOT/item['source']).read_bytes()
        if harness.count(body) != 1:
            raise ValueError('Body bytes/CRLF changed or duplicated: '+item['name'])


def self_test():
    midpoint = str(int(_REAL_OVERFLOW_MIDPOINT)) + '.0'
    below_midpoint = str(int(_REAL_OVERFLOW_MIDPOINT) - 1) + '.0'
    above_midpoint = str(int(_REAL_OVERFLOW_MIDPOINT) + 1) + '.0'
    tests = [
        ('nan-payload', not numeric_token_equal('NaN(payload)', 'NaN(payload)')),
        ('nan-payload-signed-case', not numeric_token_equal('-nAn(0xDEAD)', '-nAn(0xDEAD)')),
        ('nan-empty-payload', not numeric_token_equal('+NAN()', '+NAN()')),
        ('infinity-signed-case', not numeric_token_equal('+iNfInItY', '+iNfInItY')),
        ('nan-either-side', not numeric_token_equal('NaN(payload)', 'T') and not numeric_token_equal('T', 'NaN(payload)')),
        ('overflow-large-exponent', not numeric_token_equal('1e9999', '1e9999')),
        ('overflow-large-negative', not numeric_token_equal('-1D9999', '-1D9999')),
        ('overflow-midpoint', not numeric_token_equal(midpoint, midpoint)),
        ('overflow-midpoint-negative', not numeric_token_equal('-'+midpoint, '-'+midpoint)),
        ('overflow-above-midpoint', not numeric_token_equal(above_midpoint, above_midpoint)),
        ('finite-below-midpoint', numeric_token_equal(below_midpoint, below_midpoint)),
        ('finite-above-huge-rounded', numeric_token_equal('1.7976931348623158e308', '1.7976931348623158e308')),
        ('overflow-rounded', not numeric_token_equal('1.7976931348623159e308', '1.7976931348623159e308')),
        ('tiny-exact', numeric_token_equal('1e-9999', '1.000D-9999')),
        ('tiny-distinct', not numeric_token_equal('1e-9999', '2e-9999')),
        ('tiny-not-zero', not numeric_token_equal('1e-9999', '0.0')),
        ('tiny-negative-not-zero', not numeric_token_equal('-1e-9999', '-0.0')),
        ('integer-semantics-unchanged', numeric_token_equal('1'+'0'*400, '1'+'0'*400)),
        ('real-integer-overflow-pair', not numeric_token_equal('1e400', '1'+'0'*400)),
        ('prefix-padding-allowed', compare('  2  elements of x not in y:\n','2  elements of x not in y:\n','numeric_prefix_exact')),
        ('prefix-tail-spaces-exact', not compare('2 elements of x not in y:\n','2  elements of x not in y:\n','numeric_prefix_exact')),
        ('prefix-character-spaces-exact', not compare(' cat \n',' cat\n','numeric_prefix_exact')),
        ('prefix-integer-precision', not compare('9007199254740992 x\n','9007199254740993 x\n','numeric_prefix_exact')),
        ('prefix-record-count', not compare('2 x\n\n','2 x\n','numeric_prefix_exact')),
        ('int64-neighbours', not compare('9007199254740992\n','9007199254740993\n')),
        ('int64-extreme', not compare('9223372036854775806\n','9223372036854775807\n')),
        ('decimal-neighbours', not compare('1.0000000000000000000000001\n','1.0000000000000000000000002\n')),
        ('D-exponent', compare('1.25D+00\n','1.2500000000000000E+00\n')),
        ('equivalent-decimal-int', compare('9007199254740993.0\n','9007199254740993\n')),
        ('rounded-decimal-int', not compare('9007199254740992.0\n','9007199254740993\n')),
        ('signed-zero', not compare('-0.000000\n','0.000000\n')),
        ('signed-zero-exponents', compare('-0.0D+00\n','-0.0000E+02\n')),
        ('signed-integer-zero', not compare('-0\n','0\n')),
        ('nonfinite', not compare('NaN Inf -Infinity\n','NaN Inf -Infinity\n')),
        ('logical-case-exact', not compare('t\n','T\n')),
        ('character-exact', not compare('[a  ]\n','[a ]\n','exact')),
        ('blank-record', not compare('\n1\n','1\n')),
        ('final-newline', not compare('1','1\n')),
        ('extra-record', not compare('1\n\n','1\n')),
        ('missing-token', not compare('1\n','1 2\n')),
        ('padding', compare('           1    2\n',' 1 2\n')),
        ('not-global-D-replace', not compare('D\n','E\n')),
        ('carriage-return', not compare('1\r\n','1\n')),
    ]
    case=dict(category='success',compare_mode='numeric_records')
    good=dict(code=0,out='',err='')
    tests += [('stderr-whitespace', bool(candidate_errors(case, good, dict(code=0,out='1\n',err=' '),'1\n'))),
              ('check-stdout-whitespace', bool(candidate_errors(case, dict(code=0,out=' ',err=''),dict(code=0,out='1\n',err=''),'1\n')))]
    runtime=dict(category='runtime',compare_mode='exact')
    tests += [('atomic-extra-space', bool(candidate_errors(runtime,good,dict(code=2,out='before\n ',err='error'),'before\n'))),
              ('wrong-runtime-status', bool(candidate_errors(runtime,good,dict(code=1,out='before\n',err='error'),'before\n')))]
    failed = [name for name, ok in tests if not ok]
    if failed:
        raise AssertionError('Harness self-tests failed: '+', '.join(failed))
    return len(tests)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', type=Path, help='Single frozen executable, not a shell command')
    parser.add_argument('--gfortran', help='GNU compiler path, used only for independent oracle processes')
    parser.add_argument('--only', default='', help='Case name regular expression')
    parser.add_argument('--result', type=Path, default=ROOT/'results.json')
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--record-oracles', action='store_true', help='Explicitly regenerate success stdout files with GNU')
    args = parser.parse_args()
    num_self_tests = self_test()
    check_original_sources()
    if args.self_test:
        print(f'PASS: {num_self_tests} adversarial harness checks and original-source fingerprints')
        return 0
    if not args.candidate and not args.gfortran:
        parser.error('Supply --candidate and/or --gfortran, or --self-test')
    if args.record_oracles and (not args.gfortran or args.candidate):
        parser.error('--record-oracles requires --gfortran and forbids --candidate')
    candidate = args.candidate.resolve() if args.candidate else None
    candidate_hash = sha(candidate.read_bytes()) if candidate else None
    versions = {name:dict(path=str(path),version=execute([path,'--version']))
                for name,path in [('candidate',candidate),('gfortran',args.gfortran)] if path}
    records=[]
    frozen = json.loads((ROOT/'expected_hashes.json').read_text()) if (ROOT/'expected_hashes.json').exists() else {}
    generated={}
    oracle_dir = ROOT/'evidence'/('gnu-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ'))
    if args.gfortran:
        oracle_dir.mkdir(parents=True)
    for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
        validate_case(case)
        if not re.search(args.only,case['name']):
            continue
        source=ROOT/case['source']; row=dict(case=case,errors=[])
        expected=None
        if not args.record_oracles:
            expected=expected_output(case)
            if 'expected_file' in case and sha(expected.encode('latin1')) != frozen.get(case['expected_file']):
                raise ValueError('Oracle snapshot fingerprint missing or changed: '+case['name'])
        if args.gfortran:
            with contextlib.nullcontext(oracle_dir/case['name']) as folder:
                folder.mkdir()
                exe=Path(folder)/'reference'
                command=[args.gfortran,*FLAGS,source]
                command += ['-o',exe] if case['baseline']=='run' else ['-fsyntax-only']
                compiled=execute(command,folder)
                (folder/'compile.stdout').write_bytes(compiled['out'].encode('latin1'))
                (folder/'compile.stderr').write_bytes(compiled['err'].encode('latin1'))
                row['gnu_compile']=compiled
                row['gnu_command']=[str(x) for x in command]
                row['gnu_evidence_directory']=str(folder)
                if case['baseline']=='reject':
                    if compiled['code']!=1 or not compiled['err'].strip() or compiled['out']:
                        row['errors'].append('GNU did not cleanly reject the compile-rejection fixture')
                elif compiled['code']!=0 or compiled['out']:
                    row['errors'].append('GNU compile failed or emitted stdout')
                elif case['baseline']=='run':
                    ran=execute([exe],folder);row['gnu_run']=ran
                    (folder/'run.stdout').write_bytes(ran['out'].encode('latin1'))
                    (folder/'run.stderr').write_bytes(ran['err'].encode('latin1'))
                    if ran['code']!=0 or ran['err']!='' or compiled['err']!='':
                        row['errors'].append('GNU success process failed or stderr was not empty')
                    elif args.record_oracles:
                        generated[case['expected_file']]=ran['out'].encode('latin1')
                    elif not compare(ran['out'],expected,case['compare_mode']):
                        row['errors'].append('GNU stdout differs from committed oracle')
        if candidate:
            checked=execute([candidate,'--check',source])
            ran=execute([candidate,*case.get('args',[]),source])
            row['check']=checked;row['run']=ran
            row['errors'] += candidate_errors(case,checked,ran,expected)
        print(case['name']+(': PASS' if not row['errors'] else ': FAIL '+', '.join(row['errors'])),flush=True)
        records.append(row)
    if not records:
        parser.error('No cases selected')
    if candidate and sha(candidate.read_bytes()) != candidate_hash:
        raise RuntimeError('Candidate executable changed during the suite')
    failed=sum(bool(row['errors']) for row in records)
    if args.record_oracles and not failed:
        for name,raw in generated.items():
            (ROOT/name).write_bytes(raw);frozen[name]=sha(raw)
        (ROOT/'expected_hashes.json').write_text(json.dumps(frozen,indent=2)+'\n')
    summary=dict(total=len(records),failed=failed,harness_self_tests=num_self_tests,
                 candidate_checked=len(records) if candidate else 0,
                 gnu_executed=sum('gnu_run' in row for row in records),
                 gnu_compile_only=sum(row['case']['baseline']=='compile' for row in records) if args.gfortran else 0,
                 gnu_compile_rejections=sum(row['case']['baseline']=='reject' for row in records) if args.gfortran else 0)
    report=dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),summary=summary,tools=versions,
                candidate_sha256=candidate_hash,compiler_flags=FLAGS,manifest_sha256=sha((ROOT/'manifest.json').read_bytes()),
                records=records)
    result=args.result if args.result.is_absolute() else ROOT/args.result
    result.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
    return bool(failed)

if __name__=='__main__':
    raise SystemExit(main())
