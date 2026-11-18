#!/usr/bin/env python3
"""Focused runner self-tests: literal oracles and clean failure boundaries."""
import unittest
from run_tests import candidate_errors, compare, output_errors


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

    def test_output_leaks(self):
        self.assertFalse(compare('debug 1', '1'))
        self.assertFalse(compare('1 2', '1'))

    def test_character_padding(self):
        case = dict(expected_stdout='xy', formatted_lines={'0': 'xy  '})
        self.assertEqual(output_errors(case, 'xy  \n'), [])
        self.assertIn('formatted CHARACTER line mismatch', output_errors(case, 'xy\n'))

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


if __name__ == '__main__':
    unittest.main()
