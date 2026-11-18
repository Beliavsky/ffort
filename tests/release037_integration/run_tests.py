#!/usr/bin/env python3
"""Bounded release 0.37 cross-feature checks, with independent GNU oracles."""
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
FLAGS = ['-std=f2018', '-pedantic-errors', '-fcheck=all,no-array-temps', '-ffpe-trap=invalid,zero,overflow', '-O0']


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


PINNED_BODIES = {'ran_uni_vec': {'name': 'ran_uni_vec', 'source_start_line': 510, 'source_end_line': 514, 'source_byte_start': 22503, 'source_byte_end_exclusive': 22651, 'sha256': '312c71eaec10db632f2ba6a53a19daab76a1f174a9b25e8db74c0d4ea28b5ac1', 'bytes': 148, 'crlf_lines': 5}, 'runif_vec': {'name': 'runif_vec', 'source_start_line': 2651, 'source_end_line': 2658, 'source_byte_start': 91982, 'source_byte_end_exclusive': 92306, 'sha256': 'f852e063312c3de550d52d2f5eadc0131885a30473e00229e741dd2285df10e2', 'bytes': 324, 'crlf_lines': 8}, 'random_logical_vec': {'name': 'random_logical_vec', 'source_start_line': 6192, 'source_end_line': 6200, 'source_byte_start': 212322, 'source_byte_end_exclusive': 212632, 'sha256': '37d747d8c3cded9700b1039a469e667c5f522c5fd85a474c31b42e8116f20efd', 'bytes': 310, 'crlf_lines': 9}, 'random_logical_matrix': {'name': 'random_logical_matrix', 'source_start_line': 6202, 'source_end_line': 6210, 'source_byte_start': 212635, 'source_byte_end_exclusive': 213002, 'sha256': '59f9ec828b184615ad2324ddc665e962eb2b1f04500ada33ecdbdb01e7a426fe', 'bytes': 367, 'crlf_lines': 9}, 'random_logical_3d': {'name': 'random_logical_3d', 'source_start_line': 6212, 'source_end_line': 6220, 'source_byte_start': 213005, 'source_byte_end_exclusive': 213378, 'sha256': 'fe16ab433961759064948a9a9a68229107033a4c1d962fe8ed661d338c7da893', 'bytes': 373, 'crlf_lines': 9}, 'random_matrix': {'name': 'random_matrix', 'source_start_line': 7847, 'source_end_line': 7851, 'source_byte_start': 272387, 'source_byte_end_exclusive': 272563, 'sha256': 'd81d96a437e46b5b58be45978b56067e028b7337a5af83f309fcda4af98bfe41', 'bytes': 176, 'crlf_lines': 5}, 'quick_sort': {'name': 'quick_sort', 'source_start_line': 8870, 'source_end_line': 8942, 'source_byte_start': 306403, 'source_byte_end_exclusive': 308920, 'sha256': 'c12792b8b58af0814e11fabc91840133b8f943f306e32ece55cb68cab6529366', 'bytes': 2517, 'crlf_lines': 73}}
PINNED_ORIGINALS = {'original/demo_fraction.f90': (272, 'f05c01017d8d1446ceb5324071ef10f4a3a3d9ecde1434aca781eb840ade998e'), 'original/demo_set_exponent.f90': (200, '982d8ea1d3055133355bd176ba30871444f4de872ee6f891dc5efadca6abe2ea'), 'original/demo_iachar.f90': (978, '5773f26159b0c794f1dcbaf069f3b340de6c9e294fb56af5f15c8ea6f5cd7243'), 'original/demo_spacing.f90': (352, '4439ef7a072003f8998cfb34007d81688343c92c6b09f54248967bb231225010')}

PINNED_WRAPPERS = {'original/utility_module.f90': (4314, 'a90941784ecfe41e7e1f190b4c763ca66213f5858cfa7cc923ceb666f52b2a0d')}

def check_original_bodies():
    mapping = json.loads((ROOT / 'original-source-map.json').read_text())
    original = (ROOT / mapping['original_source']).read_bytes()
    expected_hash = 'c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
    if mapping['original_source_sha256'] != expected_hash or hashlib.sha256(original).hexdigest() != expected_hash:
        raise ValueError('Original utility fingerprint changed')
    if len(mapping['wrappers']) != 1:
        raise ValueError('Expected one exact dependency closure')
    if {entry['path'] for entry in mapping['wrappers']} != set(PINNED_WRAPPERS):
        raise ValueError('Unexpected wrapper source set')
    seen = set()
    for entry in mapping['wrappers']:
        wrapper = (ROOT / entry['path']).read_bytes()
        if (len(wrapper), hashlib.sha256(wrapper).hexdigest()) != PINNED_WRAPPERS[entry['path']]:
            raise ValueError('Original wrapper or synthetic scaffolding changed')
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
    if case.get('gnu_extension') not in (None,'isnan'):
        raise ValueError('Unrecognized GNU extension scope')
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
            folder = stack.enter_context(tempfile.TemporaryDirectory(prefix='release037-candidate-'))
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
                    with tempfile.TemporaryDirectory(prefix='release037-gnu-') as folder:
                        binary = Path(folder) / 'reference'
                        source = Path(folder) / (case['name'] + '.f90')
                        source.write_bytes(fixture)
                        flags = FLAGS + (['-fall-intrinsics'] if case.get('gnu_extension') == 'isnan' else [])
                        compiled = execute([compiler, *flags, source, '-o', binary], folder)
                        row['gnu_compile'] = compiled
                        row['errors'] += gnu_compile_errors(case, compiled)
                        if compiled['code'] == 0 and case['baseline'] == 'run':
                            ran = execute([binary], folder)
                            row['gnu_run'] = ran
                            if ran['code'] != 0 or ran['err']:
                                row['errors'].append('GNU execution failed or emitted diagnostic')
                            row['errors'] += ['GNU ' + err for err in output_errors(case, ran['out'], gnu=True)]
            if candidate:
                with tempfile.TemporaryDirectory(prefix='release037-run-') as folder:
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
                      scope='Bounded model decomposition, ASCII, spacing/adjacent-value, ordinary impure RNG and finite-only ISNAN composition. Seven exact utility bodies including nested sort closure; not a full-library support claim.',
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
