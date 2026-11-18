#!/usr/bin/env python3
"""Focused runner self-tests: literal oracles and clean failure boundaries."""
import unittest
import tempfile
from pathlib import Path
from unittest.mock import patch
from run_tests import candidate_errors, compare, snapshot_candidate, check_original_bodies


def result(code=0, out='', err=''):
    return dict(code=code, out=out, err=err)


class RunnerTests(unittest.TestCase):
    def test_numeric_formatting(self):
        self.assertTrue(compare('2.0000000 9.0D+0 T', '2 9.0 T'))

    def test_integer_precision(self):
        self.assertFalse(compare('9007199254740993', '9007199254740992'))

    def test_nonfinite(self):
        for value in ('NaN', 'Infinity', '-Infinity'):
            self.assertFalse(compare(value, '1.0'))

    def test_wide_finite_real(self):
        self.assertFalse(compare('9e999', '1e999'))
        self.assertTrue(compare('1.0000001e999', '1e999'))

    def test_diagnostic_filename_does_not_count(self):
        case = dict(category='reject', expected_stdout='', diagnostic='unsupported')
        bad = result(1, err='/fixtures/unsupported.f90:3:9: another failure')
        self.assertTrue(candidate_errors(case, bad, bad))

    def test_output_leaks(self):
        self.assertFalse(compare('debug 1', '1'))
        self.assertFalse(compare('1 2', '1'))

    def test_clean_success(self):
        case = dict(category='success', expected_stdout='1')
        self.assertEqual(candidate_errors(case, result(), result(out='1')), [])

    def test_success_stderr(self):
        case = dict(category='success', expected_stdout='1')
        self.assertTrue(candidate_errors(case, result(), result(out='1', err='warning')))

    def test_rejection_not_crash(self):
        case = dict(category='reject', expected_stdout='', diagnostic='unsupported')
        self.assertEqual(candidate_errors(case, result(1, err='unsupported'), result(1, err='unsupported')), [])
        self.assertTrue(candidate_errors(case, result(1, err='unsupported'), result(-11, err='unsupported')))

    def test_runtime_not_check_rejection(self):
        case = dict(category='runtime', expected_stdout='')
        self.assertEqual(candidate_errors(case, result(), result(2, err='unallocated')), [])
        self.assertTrue(candidate_errors(case, result(1, err='unallocated'), result(1, err='unallocated')))

    def test_missing_diagnostic(self):
        case = dict(category='reject', expected_stdout='', diagnostic='unsupported')
        self.assertTrue(candidate_errors(case, result(1), result(1)))

    def test_check_stdout(self):
        case = dict(category='success', expected_stdout='1')
        self.assertIn('check stdout leak', candidate_errors(case, result(out='debug'), result(out='1')))

    def test_failure_output_leak(self):
        case = dict(category='runtime', expected_stdout='')
        self.assertIn('stdout mismatch/leak', candidate_errors(case, result(), result(2, out='123', err='failure')))

    def test_check_whitespace_is_leak(self):
        case = dict(category='success', expected_stdout='1')
        self.assertIn('check stdout leak', candidate_errors(case, result(out=' \n'), result(out='1')))

    def test_failure_whitespace_is_leak(self):
        case = dict(category='runtime', expected_stdout='')
        self.assertIn('stdout mismatch/leak', candidate_errors(case, result(), result(2, out=' \n', err='failure')))

    def test_runtime_crash_or_timeout_not_policy_rejection(self):
        case = dict(category='runtime', expected_stdout='', diagnostic='uninitialized')
        for code in (-11, None):
            self.assertTrue(candidate_errors(case, result(), result(code, err='uninitialized')))


class SnapshotAndProvenanceTests(unittest.TestCase):
    def test_original_body_identity(self):
        self.assertEqual(len(check_original_bodies()['routines']), 5)

    def test_candidate_snapshot(self):
        with tempfile.TemporaryDirectory() as folder:
            selected, copied = Path(folder) / 'selected', Path(folder) / 'copy'
            selected.write_bytes(b'program bytes')
            selected.chmod(0o700)
            self.assertEqual(len(snapshot_candidate(selected, copied)), 64)
            self.assertEqual(copied.read_bytes(), selected.read_bytes())

    def test_empty_candidate_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            selected, copied = Path(folder) / 'selected', Path(folder) / 'copy'
            selected.write_bytes(b'')
            selected.chmod(0o700)
            with self.assertRaises(ValueError):
                snapshot_candidate(selected, copied)

    def test_nonexecutable_candidate_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            selected, copied = Path(folder) / 'selected', Path(folder) / 'copy'
            selected.write_bytes(b'program bytes')
            selected.chmod(0o600)
            with self.assertRaises(ValueError):
                snapshot_candidate(selected, copied)

    def test_copy_race_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            selected, copied = Path(folder) / 'selected', Path(folder) / 'copy'
            selected.write_bytes(b'old program')
            selected.chmod(0o700)
            def race(src, dst):
                dst.write_bytes(b'new program')
                dst.chmod(0o700)
            with patch('run_tests.shutil.copy2', race):
                with self.assertRaises(ValueError):
                    snapshot_candidate(selected, copied)


if __name__ == '__main__':
    unittest.main()
