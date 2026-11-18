#!/usr/bin/env python3
"""Bounded release 0.36 cross-feature checks, with independent GNU oracles."""
from pathlib import Path
import argparse
from contextlib import ExitStack
import datetime
from decimal import Decimal, InvalidOperation
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
# Keep all runtime safety checks; only suppress the expected noncontiguous actual
# copy-in/copy-out temporary warning. All remaining GNU stderr still fails.
FLAGS = ['-std=f2018', '-pedantic-errors', '-fcheck=all,no-array-temps', '-O0']


def execute(argv, cwd):
    def decode(value):
        return value.decode('utf-8', errors='surrogateescape') if isinstance(value, bytes) else value or ''
    try:
        ran = subprocess.run([str(a) for a in argv], cwd=cwd,
                             capture_output=True, timeout=30,
                             stdin=subprocess.DEVNULL)
        return dict(code=ran.returncode, out=decode(ran.stdout), err=decode(ran.stderr),
                    argv=[str(a) for a in argv], cwd=str(cwd))
    except subprocess.TimeoutExpired as exc:
        return dict(code=None, out=decode(exc.stdout), err='TIMEOUT: ' + decode(exc.stderr),
                    argv=[str(a) for a in argv], cwd=str(cwd))
    except OSError as exc:
        return dict(code=None, out='', err=str(exc),
                    argv=[str(a) for a in argv], cwd=str(cwd))


def compare(actual, expected, mode="exact"):
    """Compare exact records or finite numeric-only tokens with exact integers."""
    if mode == "exact":
        return actual == expected
    if mode not in ("numeric_tokens", "tokens"):
        raise ValueError("Unknown output comparison mode")
    actual, expected = actual.split(), expected.split()
    if len(actual) != len(expected):
        return False
    for got, want in zip(actual, expected):
        try:
            a = Decimal(got.replace('D', 'E').replace('d', 'e'))
            b = Decimal(want.replace('D', 'E').replace('d', 'e'))
        except InvalidOperation:
            if mode == 'tokens' and got == want:
                continue
            return False
        if not a.is_finite() or not b.is_finite():
            return False
        if re.fullmatch(r'[+-]?\d+', want):
            if a != b:
                return False
        elif abs(a - b) > Decimal('2e-6') * max(abs(a), abs(b)):
            return False
    return True


def output_errors(case, output, gnu=False):
    errors = []
    expected = case.get('gnu_stdout', case['expected_stdout']) if gnu else case.get('completed_stdout', '') + case['expected_stdout']
    if not compare(output, expected, case.get('compare_mode', 'exact')):
        errors.append('stdout mismatch/leak')
    return errors


def candidate_errors(case, checked, ran):
    category = case['category']
    errors = []
    for label, result, code in [
        ('check', checked, 1 if category == 'reject' else 0),
        ('run', ran, {'success': 0, 'reject': 1, 'runtime': 2}[category]),
    ]:
        if re.search(r'Fortran runtime error:|Backtrace:|Segmentation fault|SIGSEGV', result['err'], re.I):
            errors.append(label + ': host crash diagnostic')
        if result['code'] != code:
            errors.append(f'{label}: expected exit {code}, got {result["code"]}')
        if code and not result['err'].strip():
            errors.append(label + ': missing diagnostic')
        if not code and result['err'] != (case.get('stderr_exact', '') if label == 'run' else ''):
            errors.append(label + ': unexpected success diagnostic')
    if checked['out']:
        errors.append('check stdout leak')
    errors += output_errors(case, ran['out'])
    if category != 'success' and ran['out'] != case.get('completed_stdout', ''):
        errors.append('rejection stdout leak')
    diagnostic = case.get('diagnostic', '')
    for label, result in [('check', checked), ('run', ran)]:
        if diagnostic and (label == 'run' or category == 'reject'):
            # Source paths must not accidentally satisfy the diagnostic contract.
            message = re.sub(r'(?m)^.*?:\d+:\d+:\s*', '', result['err'])
            if diagnostic.casefold() not in message.casefold():
                errors.append(label + ': missing diagnostic ' + diagnostic)
    return errors


def snapshot_candidate(selected, candidate):
    before = hashlib.sha256(selected.read_bytes()).hexdigest()
    shutil.copy2(selected, candidate)
    copied = hashlib.sha256(candidate.read_bytes()).hexdigest()
    after = hashlib.sha256(selected.read_bytes()).hexdigest()
    if (not candidate.stat().st_size or not os.access(candidate, os.X_OK) or
            before != copied or after != copied):
        raise ValueError('Candidate changed during snapshot or was empty/nonexecutable; wait for the build to finish')
    return copied


PINNED_BODIES = {'filter_matrix_rows': {'name': 'filter_matrix_rows', 'source_start_line': 8657, 'source_end_line': 8679, 'source_byte_start': 298453, 'source_byte_end_exclusive': 299543, 'sha256': '2988489e747a2cdc7f9045e0deae9af543a6121642d9a70632cc66a0a2969473', 'bytes': 1090, 'crlf_lines': 23}, 'true_pos_func': {'name': 'true_pos_func', 'source_start_line': 1552, 'source_end_line': 1564, 'source_byte_start': 55675, 'source_byte_end_exclusive': 56003, 'sha256': 'b3d307baf5b780746d191aedf2080a17d2ba353b2013b310ef07f82d63c2582b', 'bytes': 328, 'crlf_lines': 13}, 'set_alloc_real_matrix': {'name': 'set_alloc_real_matrix', 'source_start_line': 2610, 'source_end_line': 2616, 'source_byte_start': 90287, 'source_byte_end_exclusive': 90590, 'sha256': '8f3d6e5bf4905c86ab26bfd09a8c2e3684823e524eaf2fccb6bad291f06f68b4', 'bytes': 303, 'crlf_lines': 7}}
PINNED_ORIGINALS = {'original/demo_dim.f90': (457, 'd894b5c29f4ffa0cb81f736dfead6381d7df934d353375eab557e07f40368add'), 'original/demo_sign.f90': (672, 'f471c0005b0b9fa9d77368bc7d768fbea6e3ea6267b16461dd4592c042f93548'), 'original/demo_log_gamma.f90': (220, '735dee251c5a432312db060823831930b7d94879c293f8d218bdf7b29f842aa6'), 'original/demo_parity.f90': (479, 'd3c8632021980a15da5fe1f81c6a7808284b68e18b37c38f6b4580c879965c50'), 'original/demo_radix.f90': (298, '26d8cf197178d37750dff0c96d2dcbf75b8669b3947fb690939f2f5bef8926ad'), 'original/demo_tiny.f90': (216, 'b03d5cb3b10b20438914014a0a85732b2e7a6e4c5c4265c4e72d02dc2a797d71'), 'original/demo_floor.f90': (659, 'c6cb094c810fa53d2c354083c5d5e089190b0d0b5cc5c98067bf15ce0053fba3')}

def check_original_bodies():
    mapping = json.loads((ROOT / 'original-source-map.json').read_text())
    original = (ROOT / mapping['original_source']).read_bytes()
    expected_hash = 'c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
    if mapping['original_source_sha256'] != expected_hash or hashlib.sha256(original).hexdigest() != expected_hash:
        raise ValueError('Original utility fingerprint changed')
    if len(mapping['wrappers']) != 1:
        raise ValueError('Expected one exact dependency closure')
    seen = set()
    for entry in mapping['wrappers']:
        wrapper = (ROOT / entry['path']).read_bytes()
        if hashlib.sha256(wrapper).hexdigest() != entry['sha256']:
            raise ValueError('Original wrapper fingerprint changed')
        for routine in entry['routines']:
            name = routine['name']
            if name in seen or name not in PINNED_BODIES:
                raise ValueError('Unexpected or duplicate utility body')
            seen.add(name)
            for key, want in PINNED_BODIES[name].items():
                if routine[key] != want:
                    raise ValueError('Original utility provenance contract changed: ' + key)
            body = original[routine['source_byte_start']:routine['source_byte_end_exclusive']]
            begin = routine['wrapper_byte_start']
            if (hashlib.sha256(body).hexdigest() != routine['sha256'] or
                    wrapper[begin:begin + len(body)] != body or
                    len(body) != routine['bytes'] or body.count(b'\r\n') != routine['crlf_lines'] or
                    original[:routine['source_byte_start']].count(b'\n') + 1 != routine['source_start_line']):
                raise ValueError('Original utility body changed: ' + name)
    if seen != set(PINNED_BODIES):
        raise ValueError('Original dependency closure incomplete')
    if (len(mapping['originals']) != len(PINNED_ORIGINALS) or
            {e['path'] for e in mapping['originals']} != set(PINNED_ORIGINALS)):
        raise ValueError('Original M_intrinsics file set changed')
    for entry in mapping['originals']:
        if entry['upstream_commit'] != 'fc14233036d910e3678d350efc24609e11475067':
            raise ValueError('Original upstream revision changed')
        data = (ROOT / entry['path']).read_bytes()
        if (len(data), hashlib.sha256(data).hexdigest()) != PINNED_ORIGINALS[entry['path']]:
            raise ValueError('Original M_intrinsics bytes changed')
        if (entry['bytes'],entry['sha256']) != PINNED_ORIGINALS[entry['path']]:
            raise ValueError('Original M_intrinsics manifest changed')
    license = mapping['license']
    if hashlib.sha256((ROOT / license['path']).read_bytes()).hexdigest() != '5bc2186f9c1ed8a9555dc8bd396ff19672e5a9bd35cb06cf16f996856667a96b':
        raise ValueError('Original MIT license changed')
    return mapping


def validate_case(case):
    if case['category'] not in ('success', 'runtime', 'reject'):
        raise ValueError('Unknown candidate category')
    if case['baseline'] not in ('run', 'compile', 'reject', 'skip'):
        raise ValueError('Unknown GNU stage')
    if case['compare_mode'] not in ('exact', 'numeric_tokens', 'tokens'):
        raise ValueError('Unknown comparator')
    if case['category'] != 'success' and case['expected_stdout']:
        raise ValueError('Failure stdout must be an explicit completed prefix')
    if case.get('completed_stdout') and case['category'] != 'runtime':
        raise ValueError('Only runtime failures can preserve completed records')
    if case['category'] == 'runtime' and case['baseline'] == 'run':
        raise ValueError('Never execute unsafe runtime probes with GNU')
    if case['category'] == 'reject' and case['baseline'] == 'run' and 'gnu_stdout' not in case:
        raise ValueError('GNU-only boundary requires an independent GNU oracle')
    if case['baseline'] == 'skip' and not case.get('scope_note'):
        raise ValueError('Skipped GNU checks require a scope reason')
    if case.get('differential', True) is not True:
        raise ValueError('Successful GNU cases must compare candidate and reference directly')
    if case['category'] != 'success' and not case.get('diagnostic'):
        raise ValueError('Failures require specific diagnostic contract')
    if case['compare_mode'] == 'numeric_tokens' and not compare(case['expected_stdout'],case['expected_stdout'],'numeric_tokens'):
        raise ValueError('Numeric token mode requires finite numeric-only output')


def source_bytes(case):
    return b'\n'.join((ROOT / path).read_bytes()
                      for path in [*case.get('support_sources', []), case['source']])


def gnu_compile_errors(case, result):
    errors = []
    if re.search(r'Fortran runtime error:|Backtrace:|Segmentation fault|SIGSEGV|internal compiler error', result['err'], re.I):
        errors.append('GNU compiler crash diagnostic')
    if result['out']:
        errors.append('GNU compiler stdout leak')
    if case['baseline'] == 'reject':
        if result['code'] != 1 or not result['err'].strip():
            errors.append('GNU did not cleanly reject')
        return errors
    if result['code'] != 0:
        return errors + ['GNU compile failed']
    allowed = ''
    if case.get('gnu_compile_warning') == 'forall_obsolescent':
        allowed = (r'[^\n]+:\d+:\d+:\n\n\s*\d+ \| forall[^\n]*\n'
                   r'\s*\|[^\n]*\nWarning: Fortran 2018 obsolescent feature: FORALL construct at \(1\)\n')
    if result['err'] and (not allowed or not re.fullmatch(allowed, result['err'])):
        errors.append('GNU unexpected compile diagnostic')
    return errors


def main():
    provenance = check_original_bodies()
    provenance_bytes = (ROOT / 'original-source-map.json').read_bytes()
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--candidate')
    ap.add_argument('--gfortran')
    ap.add_argument('--only', default='')
    ap.add_argument('--result', default='results.json')
    args = ap.parse_args()
    if not args.candidate and not args.gfortran:
        ap.error('Supply --candidate and/or --gfortran')
    manifest_bytes = (ROOT / 'manifest.json').read_bytes()
    cases = [case for case in json.loads(manifest_bytes)['cases']
             if re.search(args.only, case['name'])]
    if not cases:
        ap.error('No cases selected')
    for case in cases:
        validate_case(case)
    source_hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
                     for case in cases for path in [*case.get('support_sources', []), case['source']]}
    with ExitStack() as stack:
        tools = {}
        candidate = None
        if args.candidate:
            selected = Path(args.candidate).resolve(strict=True)
            folder = stack.enter_context(tempfile.TemporaryDirectory(prefix='release036-candidate-'))
            candidate = Path(folder) / selected.name
            try:
                snapshot_candidate(selected, candidate)
            except ValueError as exc:
                ap.error(str(exc))
            tools['candidate'] = dict(path=str(selected),
                                      sha256=hashlib.sha256(candidate.read_bytes()).hexdigest(),
                                      version=execute([candidate, '--version'], folder))
            version = tools['candidate']['version']
            if version['code'] != 0 or version['err'] or not version['out'].strip():
                ap.error('Candidate snapshot failed its version probe')
        compiler = None
        if args.gfortran:
            compiler = shutil.which(args.gfortran)
            if not compiler:
                ap.error('GNU compiler not found: ' + args.gfortran)
            compiler = str(Path(compiler).resolve())
            tools['gfortran'] = dict(path=compiler, version=execute([compiler, '--version'], ROOT))
            version = tools['gfortran']['version']
            if version['code'] != 0 or version['err'] or not version['out'].strip():
                ap.error('GNU compiler failed its version probe')
        records = []
        for case in cases:
            fixture = source_bytes(case)
            row = dict(case=case, errors=[])
            if compiler:
                if case['baseline'] == 'skip':
                    row['gnu_skipped'] = case['scope_note']
                else:
                    with tempfile.TemporaryDirectory(prefix='release036-gnu-') as folder:
                        binary = Path(folder) / 'reference'
                        source = Path(folder) / (case['name'] + '.f90')
                        source.write_bytes(fixture)
                        compiled = execute([compiler, *FLAGS, source, '-o', binary], folder)
                        row['gnu_compile'] = compiled
                        row['errors'] += gnu_compile_errors(case, compiled)
                        if compiled['code'] == 0 and case['baseline'] == 'run':
                            ran = execute([binary], folder)
                            row['gnu_run'] = ran
                            if ran['code'] != 0 or ran['err']:
                                row['errors'].append('GNU execution failed or emitted diagnostic')
                            row['errors'] += ['GNU ' + err for err in output_errors(case, ran['out'], gnu=True)]
            if candidate:
                with tempfile.TemporaryDirectory(prefix='release036-run-') as folder:
                    source = Path(folder) / (case['name'] + '.f90')
                    source.write_bytes(fixture)
                    checked = execute([candidate, '--check', source], folder)
                    ran = execute([candidate, *case.get('args', []), source], folder)
                row.update(check=checked, run=ran)
                row['errors'] += candidate_errors(case, checked, ran)
                if 'gnu_run' in row and case['category'] == 'success' and case.get('differential', True) and not compare(ran['out'], row['gnu_run']['out'], case['compare_mode']):
                    row['errors'].append('candidate/GNU differential mismatch')
            status = 'FAIL: ' + '; '.join(row['errors']) if row['errors'] else 'PASS'
            if row.get('gnu_skipped') and not candidate:
                status = 'SKIP (interpreter safety policy, no GNU oracle)'
            elif not row['errors'] and compiler and case['baseline'] == 'compile':
                status += ' (GNU compile-only)'
            elif not row['errors'] and row.get('gnu_skipped'):
                status += ' (GNU skipped: interpreter safety policy)'
            print(case['name'] + ': ' + status, flush=True)
            records.append(row)
        integrity_errors = []
        if (ROOT / 'original-source-map.json').read_bytes() != provenance_bytes:
            integrity_errors.append('Original provenance changed during verification')
        check_original_bodies()
        if (ROOT / 'manifest.json').read_bytes() != manifest_bytes:
            integrity_errors.append('Manifest changed during verification')
        for source, digest in source_hashes.items():
            if hashlib.sha256((ROOT / source).read_bytes()).hexdigest() != digest:
                integrity_errors.append('Fixture changed during verification: ' + source)
        if candidate and hashlib.sha256(candidate.read_bytes()).hexdigest() != tools['candidate']['sha256']:
            integrity_errors.append('Candidate snapshot changed during verification')
        summary = dict(total=len(records), failed=sum(bool(row['errors']) for row in records),
                       integrity_failed=len(integrity_errors))
        if candidate:
            summary['candidate_checked'] = len(records)
        if compiler:
            summary.update(gnu_checked=sum('gnu_skipped' not in row for row in records),
                           gnu_compiler_discrepancies=sum(bool(row['case'].get('compiler_discrepancy')) for row in records),
                           gnu_executed=sum('gnu_run' in row for row in records),
                           gnu_compile_only=sum(row['case']['baseline'] == 'compile' for row in records),
                           gnu_compile_rejections=sum(row['case']['baseline'] == 'reject' for row in records),
                           gnu_skipped=sum('gnu_skipped' in row for row in records))
        report = dict(tools=tools, summary=summary, records=records,
                      utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                      compiler_flags=FLAGS,
                      scope='Bounded DIM/SIGN/LOG_GAMMA, PARITY, metadata model inquiries, and read-only rank2 numeric row gather. Exact filter_matrix_rows dependency closure and seven unchanged M_intrinsics programs; not a full-library support claim.',
                      original_source_provenance=provenance,
                      provenance_sha256=hashlib.sha256(provenance_bytes).hexdigest(),
                      manifest_sha256=hashlib.sha256(manifest_bytes).hexdigest(),
                      source_sha256=source_hashes, integrity_errors=integrity_errors)
        if candidate:
            report['candidate_sha256'] = tools['candidate']['sha256']
        (ROOT / args.result).write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(summary, indent=2))
        return bool(summary['failed'] or summary['integrity_failed'])


if __name__ == '__main__':
    raise SystemExit(main())
