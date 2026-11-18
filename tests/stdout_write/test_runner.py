#!/usr/bin/env python3
"""Self-tests for strict outcomes, independent values and GNU safety policy."""
import unittest
from run_tests import compare, candidate_errors, validate_case
from test_staging import output_ok


class RunnerTests(unittest.TestCase):
    def case(self, category='runtime', **extra):
        return dict(category=category, baseline='compile', expected_stdout='', **extra)

    def stage(self, code, out='', err=''):
        return dict(code=code, out=out, err=err)

    def test_staging_numeric_count_values_and_finite(self):
        self.assertTrue(output_ok(b'0.125 0.125', 'numeric', 2))
        self.assertFalse(output_ok(b'0.125', 'numeric', 2))
        self.assertFalse(output_ok(b'0.125 0.5', 'numeric', 2))
        self.assertFalse(output_ok(b'NaN', 'numeric', 1))

    def test_staging_atomic_prefix(self):
        self.assertTrue(output_ok(b'', 'over'))
        self.assertFalse(output_ok(b' ', 'over'))
        self.assertTrue(output_ok(b'before\n', 'over_prior'))
        self.assertFalse(output_ok(b'before\nx', 'over_prior'))

    def test_staging_exact_rejects_truncated_record(self):
        self.assertFalse(output_ok(b' xxx\n', 'exact'))

    def test_runtime_exit_and_diagnostic(self):
        self.assertFalse(candidate_errors(self.case(), self.stage(0), self.stage(2, err='bad bound')))
        self.assertTrue(candidate_errors(self.case(), self.stage(1, err='bad'), self.stage(1, err='bad')))

    def test_static_exit_and_diagnostic(self):
        c = self.case('reject')
        self.assertFalse(candidate_errors(c, self.stage(1, err='bad'), self.stage(1, err='bad')))
        self.assertTrue(candidate_errors(c, self.stage(0), self.stage(0)))

    def test_rejection_cannot_emit_even_whitespace(self):
        self.assertTrue(candidate_errors(self.case(), self.stage(0), self.stage(2, out='\n', err='bad')))
        self.assertTrue(candidate_errors(self.case(), self.stage(0, out=' '), self.stage(2, err='bad')))

    def test_failure_needs_diagnostic(self):
        self.assertTrue(candidate_errors(self.case(), self.stage(0), self.stage(2)))

    def test_success_cannot_emit_stderr(self):
        c = dict(category='success', expected_stdout='4')
        self.assertTrue(candidate_errors(c, self.stage(0), self.stage(0, out='4', err='warning')))

    def test_path_cannot_satisfy_diagnostic(self):
        c = self.case(diagnostic='uninitialized')
        self.assertTrue(candidate_errors(c, self.stage(0), self.stage(2, err='/tmp/uninitialized.f90:1:1: Other error')))

    def test_no_undefined_gnu_execution(self):
        for category in ('runtime', 'reject'):
            with self.assertRaises(ValueError):
                validate_case(dict(category=category, baseline='run', expected_stdout=''))

    def test_no_gnu_runtime_or_skipped_baselines(self):
        for baseline in ('runtime', 'skip', 'unknown'):
            with self.assertRaises(ValueError):
                validate_case(dict(category='runtime', baseline=baseline, expected_stdout=''))

    def test_no_expected_output_on_rejection(self):
        with self.assertRaises(ValueError):
            validate_case(dict(category='runtime', baseline='compile', expected_stdout='PASS'))

    def test_completed_record_is_exact_prefix(self):
        c = self.case(completed_stdout='before\n', compare_mode='exact')
        self.assertFalse(candidate_errors(c, self.stage(0), self.stage(2, out='before\n', err='bad')))
        self.assertTrue(candidate_errors(c, self.stage(0), self.stage(2, out='before\n42', err='bad')))
        self.assertTrue(candidate_errors(c, self.stage(0), self.stage(2, out='', err='bad')))

    def test_completed_record_requires_runtime_compile_only(self):
        with self.assertRaises(ValueError):
            validate_case(dict(category='success', baseline='run', expected_stdout='', completed_stdout='x'))

    def test_allowed_stages(self):
        for category, baseline in (('success', 'run'), ('runtime', 'compile'), ('reject', 'compile'), ('reject', 'reject')):
            validate_case(dict(category=category, baseline=baseline, expected_stdout=''))

    def test_unknown_category(self):
        with self.assertRaises(ValueError):
            validate_case(dict(category='other', baseline='compile', expected_stdout=''))

    def test_exact_large_integer(self):
        self.assertTrue(compare('10000000001', '10000000001'))
        self.assertFalse(compare('10000000002', '10000000001'))
        self.assertFalse(compare('4.000001', '4'))

    def test_real_and_nonfinite(self):
        self.assertTrue(compare('1.25D+0', '1.25'))
        self.assertFalse(compare('nan', '1.25'))
        self.assertFalse(compare('inf', '1.25'))

    def test_all_tokens_required(self):
        self.assertFalse(compare('4 5', '4'))
        self.assertFalse(compare('F', 'T'))
        self.assertFalse(compare('', '4'))


if __name__ == '__main__':
    unittest.main()
