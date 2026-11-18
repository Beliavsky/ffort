#!/usr/bin/env python3
"""Self-tests for summary validation and exact user-source preservation."""
import hashlib
from pathlib import Path
import unittest
from run_tests import SAMPLE, summary_valid
from profile_capacity import expected_outcome, successful_outcome


class RunnerTests(unittest.TestCase):
    def test_requested_source_is_exact(self):
        self.assertEqual(hashlib.sha256(SAMPLE.encode()).hexdigest(),
                         '8ca60049335c05462cf7ad6449ba7b32b69a2413f0a3bc137f4484eda5db5477')
        self.assertEqual((Path(__file__).resolve().parents[2]/'examples/random_summary_100000.f90').read_text(), SAMPLE)

    def test_summary_range(self):
        self.assertTrue(summary_valid('.00001 .99999 .501'))
        self.assertTrue(summary_valid('0 .999999 .499'))
        for text in ('-.00001 .99999 .5', '0 1 .5', '0 .99999 .9', '.1 .999 .5', '0 .8 .5'):
            self.assertFalse(summary_valid(text), text)

    def test_summary_shape_and_finiteness(self):
        for text in ('', '0 .99', '0 .999 .5 1', '0 nan .5', '0 inf .5', 'a b c'):
            self.assertFalse(summary_valid(text), text)


class CapacityProfileTests(unittest.TestCase):
    @staticmethod
    def outcome(status=0, stdout='6\n', stderr=''):
        return dict(status=status, stdout=stdout, stderr=stderr)

    def test_candidate_clean_success(self):
        self.assertTrue(expected_outcome(self.outcome(stdout='  6 \n'), 0, '6'))

    def test_candidate_success_rejects_stderr(self):
        for stderr in ('stderr sentinel', 'warning: allocation failed', ' \n'):
            self.assertFalse(expected_outcome(self.outcome(stderr=stderr), 0, '6'), stderr)

    def test_gnu_clean_success(self):
        self.assertTrue(successful_outcome(self.outcome(), '6'))

    def test_gnu_success_rejects_stderr(self):
        for stderr in ('stderr sentinel', 'runtime warning', '\n'):
            self.assertFalse(successful_outcome(self.outcome(stderr=stderr), '6'), stderr)

    def test_success_rejects_wrong_status(self):
        for status in (1, 2, -9, None):
            got=self.outcome(status=status)
            self.assertFalse(expected_outcome(got, 0, '6'))
            self.assertFalse(successful_outcome(got, '6'))

    def test_success_rejects_wrong_or_extra_stdout(self):
        for stdout in ('', '7', '6 extra', 'before\n6'):
            got=self.outcome(stdout=stdout)
            self.assertFalse(expected_outcome(got, 0, '6'))
            self.assertFalse(successful_outcome(got, '6'))

    def test_negative_named_diagnostic(self):
        got=self.outcome(status=2, stdout='', stderr='source.f90:3:1: Array storage ALLOCATION failed')
        self.assertTrue(expected_outcome(got, 2, '', 'allocation'))
        got=self.outcome(status=1, stdout='', stderr='source.f90:3:1: Total array element limit exceeded')
        self.assertTrue(expected_outcome(got, 1, '', 'limit'))

    def test_negative_rejects_wrong_status(self):
        for status in (0, 1, -9, None):
            got=self.outcome(status=status, stdout='', stderr='source.f90:3:1: array storage allocation failed')
            self.assertFalse(expected_outcome(got, 2, '', 'allocation'))

    def test_negative_rejects_missing_or_wrong_diagnostic(self):
        for stderr in ('', 'stderr sentinel', 'execution step limit exceeded'):
            got=self.outcome(status=2, stdout='', stderr=stderr)
            self.assertFalse(expected_outcome(got, 2, '', 'allocation'))

    def test_negative_rejects_empty_expected_diagnostic(self):
        got=self.outcome(status=2, stdout='', stderr='source.f90:3:1: array storage allocation failed')
        for diagnostic in ('', ' \n'):
            self.assertFalse(expected_outcome(got, 2, '', diagnostic))

    def test_negative_rejects_host_failures(self):
        for marker in ('Fortran runtime error: allocation failed', 'Backtrace:',
                       'Program received signal SIGSEGV', 'SIGABRT',
                       'Segmentation fault', 'Fatal error: allocation failed',
                       'internal compiler error: allocation', 'ICE: allocation'):
            for stderr in (marker, 'source.f90:3:1: array allocation failed\n'+marker):
                got=self.outcome(status=2, stdout='', stderr=stderr)
                self.assertFalse(expected_outcome(got, 2, '', 'allocation'), stderr)

    def test_negative_requires_source_location(self):
        for stderr in ('allocation failed', 'STOP 2 allocation',
                       'source.f90:3: allocation failed', 'source.f90:x:1: allocation failed'):
            got=self.outcome(status=2, stdout='', stderr=stderr)
            self.assertFalse(expected_outcome(got, 2, '', 'allocation'), stderr)

    def test_negative_rejects_program_output(self):
        for stdout in ('body sentinel', ' ', '\n'):
            got=self.outcome(status=2, stdout=stdout, stderr='source.f90:3:1: array storage allocation failed')
            self.assertFalse(expected_outcome(got, 2, '', 'allocation'))


if __name__=='__main__':
    unittest.main()
