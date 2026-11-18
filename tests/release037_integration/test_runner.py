#!/usr/bin/env python3
"""Independent runner checks; no compiler output is used as an expected oracle."""
import copy
import hashlib
import json
import tempfile
import subprocess
import shutil
import sys
from contextlib import contextmanager
import unittest
from pathlib import Path
from unittest.mock import patch
import run_tests as runner


def result(code=0, out='', err=''):
    return dict(code=code, out=out, err=err)


def case(**kw):
    base = dict(name='sample', category='success', baseline='run', expected_stdout='x \n', compare_mode='exact')
    base.update(kw)
    return base


class ProcessTests(unittest.TestCase):
    def test_timeout_retains_bytes_without_becoming_rejection(self):
        failure=subprocess.TimeoutExpired(['candidate'],30,output=b'prior\n',stderr=b'partial')
        with patch.object(runner.subprocess,'run',side_effect=failure):
            got=runner.execute(['candidate'],runner.ROOT)
        self.assertIsNone(got['code'])
        self.assertEqual(got['out'],'prior\n')
        self.assertTrue(got['err'].startswith('TIMEOUT:'))

    def test_os_failure_not_success(self):
        with patch.object(runner.subprocess,'run',side_effect=OSError('missing executable')):
            got=runner.execute(['candidate'],runner.ROOT)
        self.assertIsNone(got['code'])
        self.assertEqual(got['out'],'')
        self.assertIn('missing executable',got['err'])


class OutputTests(unittest.TestCase):
    def test_exact_character_spaces(self):
        for wrong in ('x\n', 'x  \n', ' x \n', 'x \n\n'):
            self.assertFalse(runner.compare(wrong, 'x \n'))
        self.assertTrue(runner.compare('x \n', 'x \n'))

    def test_exact_character_not_numeric(self):
        self.assertFalse(runner.compare('1.0\n', '1\n'))

    def test_exact_record_ending(self):
        self.assertFalse(runner.compare('x\r\n', 'x\n'))
        self.assertFalse(runner.compare('x', 'x\n'))

    def test_finite_numeric_formatting(self):
        self.assertTrue(runner.compare('2.0000 9.0D+0 -0.75', '2 9.0 -0.75', 'numeric_tokens'))

    def test_tiny_zero_cannot_pass(self):
        self.assertFalse(runner.compare('0', '2.2250738585072014e-308', 'numeric_tokens'))
        self.assertFalse(runner.compare('0', '1.1754943508222875e-38', 'tokens'))

    def test_upstream_tokens_keep_words_and_exact_integer(self):
        self.assertTrue(runner.compare('value 2.0 T', 'value 2 T', 'tokens'))
        self.assertFalse(runner.compare('wrong 2.0 T', 'value 2 T', 'tokens'))
        self.assertFalse(runner.compare('value 9007199254740992', 'value 9007199254740993', 'tokens'))
        self.assertFalse(runner.compare('value NaN', 'value NaN', 'tokens'))

    def test_large_integer_exactness(self):
        self.assertFalse(runner.compare('9007199254740992', '9007199254740993', 'numeric_tokens'))

    def test_numeric_only(self):
        self.assertFalse(runner.compare('text 1', 'text 1', 'numeric_tokens'))

    def test_nonfinite(self):
        for token in ('NaN', 'sNaN', 'Inf', '-Infinity'):
            self.assertFalse(runner.compare(token, token, 'numeric_tokens'))

    def test_large_finite_real(self):
        self.assertTrue(runner.compare('1.0000001e999', '1e999', 'numeric_tokens'))
        self.assertFalse(runner.compare('2e999', '1e999', 'numeric_tokens'))

    def test_wrong_numeric_count(self):
        self.assertFalse(runner.compare('1 2', '1', 'numeric_tokens'))

    def test_success_stderr_exact(self):
        self.assertEqual(runner.candidate_errors(case(), result(), result(out='x \n')), [])
        self.assertTrue(runner.candidate_errors(case(), result(), result(out='x \n', err='warning\n')))

    def test_bare_stop_stderr_exact(self):
        c = case(stderr_exact='STOP\n')
        self.assertEqual(runner.candidate_errors(c, result(), result(out='x \n', err='STOP\n')), [])
        self.assertTrue(runner.candidate_errors(c, result(), result(out='x \n', err='STOP 0\n')))

    def test_atomic_failure_preserves_completed_record(self):
        c = case(category='runtime', baseline='compile', expected_stdout='', completed_stdout='before\n', diagnostic='mismatch')
        self.assertEqual(runner.candidate_errors(c, result(), result(2, 'before\n', 'mismatch')), [])
        for out in ('', 'before\npartial', 'before\n\n', ' before\n'):
            self.assertTrue(runner.candidate_errors(c, result(), result(2, out, 'mismatch')))

    def test_whitespace_leaks_fail(self):
        c = case(category='reject', baseline='compile', expected_stdout='', diagnostic='unsupported')
        self.assertTrue(runner.candidate_errors(c, result(1, ' \n', 'unsupported'), result(1, '', 'unsupported')))
        self.assertTrue(runner.candidate_errors(c, result(1, '', 'unsupported'), result(1, ' \n', 'unsupported')))

    def test_crash_not_rejection(self):
        c = case(category='runtime', baseline='compile', expected_stdout='', diagnostic='unallocated')
        for code in (-11, None, 1):
            self.assertTrue(runner.candidate_errors(c, result(), result(code, '', 'unallocated')))
        self.assertTrue(runner.candidate_errors(c, result(), result(2, '', 'Fortran runtime error: unallocated\nBacktrace:')))

    def test_runtime_must_check_successfully(self):
        c = case(category='runtime', baseline='compile', expected_stdout='', diagnostic='unallocated')
        self.assertTrue(runner.candidate_errors(c, result(1, '', 'unallocated'), result(2, '', 'unallocated')))

    def test_diagnostic_filename_is_not_evidence(self):
        c = case(category='reject', baseline='compile', expected_stdout='', diagnostic='unsupported')
        bad = result(1, '', '/path/unsupported.f90:1:2: another failure\n')
        self.assertTrue(runner.candidate_errors(c, bad, bad))

    def test_missing_diagnostic(self):
        c = case(category='reject', baseline='compile', expected_stdout='', diagnostic='unsupported')
        self.assertTrue(runner.candidate_errors(c, result(1), result(1)))

    def test_boundary_gnu_output_separate(self):
        c = case(category='reject', baseline='run', expected_stdout='', gnu_stdout='GNU only\n', diagnostic='unsupported')
        self.assertEqual(runner.output_errors(c, 'GNU only\n', gnu=True), [])
        self.assertEqual(runner.output_errors(c, ''), [])
        self.assertTrue(runner.output_errors(c, 'GNU only\n'))
        self.assertTrue(runner.output_errors(c, '', gnu=True))


class ContractTests(unittest.TestCase):
    def test_manifest_contract(self):
        for c in json.loads((runner.ROOT / 'manifest.json').read_text())['cases']:
            runner.validate_case(c)

    def test_unknown_extension_rejected(self):
        with self.assertRaises(ValueError):
            runner.validate_case(case(gnu_extension="arbitrary"))

    def test_runtime_gnu_execution_forbidden(self):
        with self.assertRaises(ValueError):
            runner.validate_case(case(category='runtime', expected_stdout='', diagnostic='bad'))

    def test_boundary_needs_gnu_oracle(self):
        with self.assertRaises(ValueError):
            runner.validate_case(case(category='reject', expected_stdout='', diagnostic='bad'))

    def test_numeric_mode_cannot_contain_character(self):
        with self.assertRaises(ValueError):
            runner.validate_case(case(compare_mode='numeric_tokens'))

    def test_compile_stdout_rejected(self):
        self.assertTrue(runner.gnu_compile_errors(case(), result(out='unexpected')))

    def test_compile_warning_rejected(self):
        self.assertTrue(runner.gnu_compile_errors(case(), result(err='Warning: unknown\n')))

    def test_only_specific_forall_warning_allowed(self):
        warning = '/tmp/case.f90:17:52:\n\n   17 | forall (i=1:len(string)) tf(i) = string(i:i) == char\n      |                                                    1\nWarning: Fortran 2018 obsolescent feature: FORALL construct at (1)\n'
        c = case(gnu_compile_warning='forall_obsolescent')
        self.assertEqual(runner.gnu_compile_errors(c, result(err=warning)), [])
        self.assertTrue(runner.gnu_compile_errors(c, result(err=warning + 'other text\n')))
        self.assertTrue(runner.gnu_compile_errors(case(), result(err=warning)))

    def test_gnu_crash_is_not_rejection(self):
        self.assertTrue(runner.gnu_compile_errors(case(baseline='reject'),result(1,err='internal compiler error')))

    def test_no_silent_differential_opt_out(self):
        with self.assertRaises(ValueError):
            runner.validate_case(case(differential=False))

    def test_skip_requires_reason(self):
        with self.assertRaises(ValueError):
            runner.validate_case(case(baseline='skip'))

    def test_gnu_rejection_status(self):
        c = case(baseline='reject')
        self.assertEqual(runner.gnu_compile_errors(c, result(1, err='error')), [])
        for status in (None, -11, 0, 2):
            self.assertTrue(runner.gnu_compile_errors(c, result(status, err='error')))


class IdentityTests(unittest.TestCase):
    def test_original_closures(self):
        mapping = runner.check_original_bodies()
        self.assertEqual([len(w['routines']) for w in mapping['wrappers']], [7])
        self.assertEqual({r['name'] for w in mapping['wrappers'] for r in w['routines']}, set(runner.PINNED_BODIES))
        entry=mapping['wrappers'][0]['routines'][0]
        self.assertEqual(entry['bytes'],runner.PINNED_BODIES['ran_uni_vec']['bytes'])
        self.assertEqual(entry['crlf_lines'],5)

    def test_corrupt_original_wrapper_detected(self):
        mapping = runner.check_original_bodies()
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = (runner.ROOT / mapping['original_source']).read_bytes()
            mapping = copy.deepcopy(mapping)
            mapping['original_source'] = 'original.f90'
            (root / 'original.f90').write_bytes(source)
            shutil.copytree(runner.ROOT/'original',root/'original')
            for entry in mapping['wrappers']:
                (root / entry['path']).write_bytes((runner.ROOT / entry['path']).read_bytes())
            (root / 'original-source-map.json').write_text(json.dumps(mapping))
            path = root / mapping['wrappers'][0]['path']
            path.write_bytes(path.read_bytes().replace(b'\r\n', b'\n'))
            with patch.object(runner, 'ROOT', root), self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_missing_dependency_detected(self):
        with self.provenance_copy() as root:
            p=root/'original-source-map.json'
            mapping=json.loads(p.read_text());mapping['wrappers'][0]['routines'].pop()
            p.write_text(json.dumps(mapping))
            with patch.object(runner,'ROOT',root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_duplicate_original_manifest_detected(self):
        with self.provenance_copy() as root:
            p=root/'original-source-map.json';mapping=json.loads(p.read_text())
            mapping['originals'].append(mapping['originals'][0]);p.write_text(json.dumps(mapping))
            with patch.object(runner,'ROOT',root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_original_revision_mutation_detected(self):
        with self.provenance_copy() as root:
            p=root/'original-source-map.json';mapping=json.loads(p.read_text())
            mapping['originals'][0]['upstream_commit']='unverified';p.write_text(json.dumps(mapping))
            with patch.object(runner,'ROOT',root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_original_demo_mutation_detected(self):
        with self.provenance_copy() as root:
            p=root/'original/demo_fraction.f90';p.write_bytes(p.read_bytes()+b'! drift\n')
            with patch.object(runner,'ROOT',root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_license_mutation_detected(self):
        with self.provenance_copy() as root:
            (root/'original/M_INTRINSICS_LICENSE').write_bytes(b'changed')
            with patch.object(runner,'ROOT',root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_forged_crlf_contract_rejected(self):
        with self.provenance_copy() as root:
            p=root/'original-source-map.json'
            mapping=json.loads(p.read_text())
            mapping['wrappers'][0]['routines'][0]['crlf_lines']=0
            p.write_text(json.dumps(mapping))
            with patch.object(runner,'ROOT',root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_changed_original_source_rejected(self):
        with self.provenance_copy() as root:
            p=root/'original.f90';p.write_bytes(p.read_bytes()+b'! changed\n')
            with patch.object(runner,'ROOT',root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_forged_wrapper_hash_cannot_add_replacement_helper(self):
        with self.provenance_copy() as root:
            p=root/"original-source-map.json";mapping=json.loads(p.read_text())
            entry=mapping["wrappers"][0];q=root/entry["path"]
            data=q.read_bytes()+b"! added replacement helper\n"
            q.write_bytes(data);entry["sha256"]=hashlib.sha256(data).hexdigest()
            p.write_text(json.dumps(mapping))
            with patch.object(runner,"ROOT",root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    def test_forged_wrapper_hash_cannot_hide_body_edit(self):
        with self.provenance_copy() as root:
            p=root/'original-source-map.json';mapping=json.loads(p.read_text())
            entry=mapping['wrappers'][0];q=root/entry['path']
            data=bytearray(q.read_bytes());data[entry['routines'][0]['wrapper_byte_start']]=ord('!')
            q.write_bytes(data);entry['sha256']=hashlib.sha256(data).hexdigest()
            p.write_text(json.dumps(mapping))
            with patch.object(runner,'ROOT',root),self.assertRaises(ValueError):
                runner.check_original_bodies()

    @staticmethod
    @contextmanager
    def provenance_copy():
        mapping=copy.deepcopy(runner.check_original_bodies())
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)
            original=(runner.ROOT/mapping['original_source']).read_bytes()
            mapping['original_source']='original.f90'
            (root/'original.f90').write_bytes(original)
            shutil.copytree(runner.ROOT/'original',root/'original')
            for entry in mapping['wrappers']:
                (root/entry['path']).write_bytes((runner.ROOT/entry['path']).read_bytes())
            (root/'original-source-map.json').write_text(json.dumps(mapping))
            yield root

    def test_generator_replay_preserves_all_bytes(self):
        def fingerprints(root):
            return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest()
                for p in root.rglob('*') if p.is_file() and
                (p.suffix=='.f90' or p.name in ('manifest.json','original-source-map.json','M_INTRINSICS_LICENSE'))}
        expected=fingerprints(runner.ROOT)
        with tempfile.TemporaryDirectory() as folder:
            base=Path(folder);root=base/'release037_integration';root.mkdir()
            source=base/'utilities_slices/source';source.mkdir(parents=True)
            shutil.copy2(runner.ROOT.parent/'utilities_slices/source/xutilities.f90',source/'xutilities.f90')
            shutil.copytree(runner.ROOT/'original',root/'original')
            shutil.copy2(runner.ROOT/'original-program-inputs.json',root/'original-program-inputs.json')
            shutil.copy2(runner.ROOT/'prepare_cases.py',root/'prepare_cases.py')
            ran=subprocess.run([sys.executable,str(root/'prepare_cases.py')],capture_output=True)
            self.assertEqual((ran.returncode,ran.stdout,ran.stderr),(0,b'',b''))
            self.assertEqual(fingerprints(root),expected)

    def test_snapshot_identity(self):
        with tempfile.TemporaryDirectory() as folder:
            src, dst = Path(folder)/'source', Path(folder)/'copy'
            src.write_bytes(b'nonempty executable'); src.chmod(0o700)
            self.assertEqual(runner.snapshot_candidate(src, dst), hashlib.sha256(src.read_bytes()).hexdigest())
            self.assertEqual(src.read_bytes(), dst.read_bytes())

    def test_empty_and_nonexecutable_snapshot(self):
        for data, mode in ((b'', 0o700), (b'bytes', 0o600)):
            with tempfile.TemporaryDirectory() as folder:
                src, dst = Path(folder)/'source', Path(folder)/'copy'
                src.write_bytes(data);src.chmod(mode)
                with self.assertRaises(ValueError):
                    runner.snapshot_candidate(src, dst)

    def test_snapshot_copy_race(self):
        with tempfile.TemporaryDirectory() as folder:
            src, dst = Path(folder)/'source', Path(folder)/'copy'
            src.write_bytes(b'old');src.chmod(0o700)
            def race(a, b):
                b.write_bytes(b'new');b.chmod(0o700)
            with patch.object(runner.shutil, 'copy2', race), self.assertRaises(ValueError):
                runner.snapshot_candidate(src, dst)

    def test_snapshot_source_changes_during_copy(self):
        with tempfile.TemporaryDirectory() as folder:
            src, dst = Path(folder)/'source', Path(folder)/'copy'
            src.write_bytes(b'old');src.chmod(0o700)
            def race(a, b):
                b.write_bytes(a.read_bytes());b.chmod(0o700);a.write_bytes(b'changed')
            with patch.object(runner.shutil, 'copy2', race), self.assertRaises(ValueError):
                runner.snapshot_candidate(src, dst)


if __name__ == '__main__':
    unittest.main()
