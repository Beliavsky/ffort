#!/usr/bin/env python3
"""Self-tests for the differential runner, without a compiler or candidate."""
import unittest
from run_tests import equivalent, successful_check


class OutputComparisonTests(unittest.TestCase):
    def test_text_is_case_sensitive(self):
        self.assertFalse(equivalent('A', 'a'))
        self.assertFalse(equivalent('Done', 'done'))
        self.assertTrue(equivalent('A Done', 'A Done'))

    def test_character_d_is_not_an_exponent(self):
        for left, right in [('d', 'e'), ('D', 'E'), ('data', 'eata'),
                            ('id1D3', 'id1E3'), ('1D3x', '1E3x')]:
            with self.subTest(left=left, right=right):
                self.assertFalse(equivalent(left, right))
                self.assertTrue(equivalent(left, left))

    def test_complete_numeric_exponents(self):
        for left, right in [('1D3', '1E3'), ('-1.25d-2', '-.0125'),
                            ('+.5D+1', '5.0'), ('1.', '1.0000000000001')]:
            with self.subTest(left=left, right=right):
                self.assertTrue(equivalent(left, right))
        self.assertFalse(equivalent('1.0D0', '1.1E0'))

    def test_integers_are_exact(self):
        self.assertTrue(equivalent('+00042', '42'))
        self.assertFalse(equivalent('9007199254740992', '9007199254740993'))
        self.assertFalse(equivalent('9223372036854775806', '9223372036854775807'))

    def test_integer_real_comparisons_do_not_round(self):
        self.assertTrue(equivalent('9007199254740993', '9007199254740993.0'))
        self.assertFalse(equivalent('9007199254740993', '9007199254740992.0'))
        self.assertFalse(equivalent('9007199254740993.0', '9007199254740992'))
        self.assertFalse(equivalent('1', '1.0000000000001'))

    def test_nonfinite_is_rejected_even_if_identical(self):
        for token in ['nan', 'NaN', '-NaN', '+nan(payload)', 'inf',
                      '-Infinity', '+INF', '1e999', '-1D999']:
            with self.subTest(token=token):
                self.assertFalse(equivalent(token, token))
                self.assertFalse(equivalent(token, '0.0'))
                self.assertFalse(equivalent('0.0', token))

    def test_text_numeric_mismatch(self):
        self.assertFalse(equivalent('1.0', 'one'))
        self.assertFalse(equivalent('one', '1.0'))
        self.assertFalse(equivalent('text extra', 'text'))

    def test_list_directed_whitespace(self):
        self.assertTrue(equivalent('  text  1.0D0\n', 'text\t1.0E0'))
        self.assertTrue(equivalent('', ''))


class CheckGateTests(unittest.TestCase):
    def test_clean_success(self):
        self.assertTrue(successful_check({'status': 0, 'stdout': '', 'stderr': ''}))

    def test_nonzero_rejected(self):
        for status in [1, 2, -9]:
            self.assertFalse(successful_check({'status': status, 'stdout': '', 'stderr': ''}))

    def test_any_check_output_rejected(self):
        for stream in ['stdout', 'stderr']:
            for output in [' ', '\n', 'unexpected output']:
                result = {'status': 0, 'stdout': '', 'stderr': ''}
                result[stream] = output
                with self.subTest(stream=stream, output=output):
                    self.assertFalse(successful_check(result))


if __name__ == '__main__':
    unittest.main()
