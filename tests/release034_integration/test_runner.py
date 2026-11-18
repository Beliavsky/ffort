#!/usr/bin/env python3
"""Independent runner checks; no compiler output is used as an expected oracle."""
import copy
import hashlib
import json
import tempfile
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

    def test_gnu_rejection_status(self):
        c = case(baseline='reject')
        self.assertEqual(runner.gnu_compile_errors(c, result(1, err='error')), [])
        for status in (None, -11, 0, 2):
            self.assertTrue(runner.gnu_compile_errors(c, result(status, err='error')))


class IdentityTests(unittest.TestCase):
    def test_original_closures(self):
        mapping = runner.check_original_bodies()
        self.assertEqual([len(w['routines']) for w in mapping['wrappers']], [4, 3])
        self.assertEqual(len({r['name'] for w in mapping['wrappers'] for r in w['routines']}), 6)

    def test_corrupt_original_wrapper_detected(self):
        mapping = runner.check_original_bodies()
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = (runner.ROOT / mapping['original_source']).read_bytes()
            mapping = copy.deepcopy(mapping)
            mapping['original_source'] = 'original.f90'
            (root / 'original.f90').write_bytes(source)
            (root / 'original').mkdir()
            for entry in mapping['wrappers']:
                (root / entry['path']).write_bytes((runner.ROOT / entry['path']).read_bytes())
            (root / 'original-source-map.json').write_text(json.dumps(mapping))
            path = root / mapping['wrappers'][0]['path']
            path.write_bytes(path.read_bytes().replace(b'\r\n', b'\n'))
            with patch.object(runner, 'ROOT', root), self.assertRaises(ValueError):
                runner.check_original_bodies()

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
