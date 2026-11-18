#!/usr/bin/env python3
"""Self-tests for the differential runner, without a compiler or candidate."""
import unittest
from run_tests import equivalent, successful_check, output_matches


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


class DecimalComparisonTests(unittest.TestCase):
    def test_tiny_nonzero_is_not_zero(self):
        for tiny in ['1e-400', '-1D-400', '1e-9999999']:
            self.assertFalse(equivalent('0.0', tiny))
            self.assertFalse(equivalent(tiny, '0.0'))
            self.assertFalse(equivalent('0', tiny))

    def test_distinct_tiny_values_do_not_coalesce(self):
        self.assertFalse(equivalent('1e-400', '2e-400'))
        self.assertFalse(equivalent('-1e-400', '1e-400'))
        self.assertFalse(equivalent('1e-9999999', '2e-9999999'))
        self.assertTrue(equivalent('1e-400', '1.0D-400'))

    def test_real_signed_zero(self):
        self.assertTrue(equivalent('0.0', '+0D0'))
        self.assertTrue(equivalent('-0.0', '-0D0'))
        self.assertFalse(equivalent('0.0', '-0.0'))
        self.assertFalse(equivalent('-0D0', '0E-999'))
        self.assertFalse(equivalent('0', '-0.0'))

    def test_scoped_nonzero_relative_tolerance(self):
        self.assertTrue(equivalent('1.0', '1.0000005', rel_tol=8e-7))
        self.assertFalse(equivalent('1.0', '1.0000005', rel_tol=1e-12))
        self.assertTrue(equivalent('1e-400', '1.0000005e-400', rel_tol=8e-7))
        self.assertFalse(equivalent('1e-400', '1.0000005e-400', rel_tol=1e-12))
        self.assertFalse(equivalent('0.0', '1e-400', rel_tol=0.9))

    def test_exact_relative_boundary(self):
        self.assertTrue(equivalent('1.0', '0.9', rel_tol=0.1))
        self.assertFalse(equivalent('1.0', '0.89999999999999999999', rel_tol=0.1))

    def test_binary64_finite_rounding_boundary(self):
        self.assertTrue(equivalent('1.7976931348623158e308', '1.7976931348623158e308'))
        self.assertFalse(equivalent('1.7976931348623159e308', '1.7976931348623159e308'))
        self.assertFalse(equivalent('1e999', '1e999'))

    def test_invalid_tolerances_are_rejected(self):
        for tolerance in [float('nan'),float('inf'),-1,1]:
            self.assertFalse(equivalent('1.0','1.0',rel_tol=tolerance))
        self.assertTrue(equivalent('1.0','1.00',rel_tol=0))
        self.assertFalse(equivalent('1.0','1.00001',rel_tol=0))


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


class FormatByteTests(unittest.TestCase):
    def test_exact_preserves_spaces_and_records(self):
        for changed in ['a b\n','ab','ab\n\n','AB\n','ab \n']:
            self.assertFalse(output_matches(changed,'ab\n',{}))
        self.assertTrue(output_matches('ab\n','ab\n',{}))

    def test_independent_expected_bytes(self):
        self.assertFalse(output_matches('wrong\n','wrong\n',{'stdout':'right\n'}))

    def test_log10_mixed_output_scope(self):
        case={'comparison':'first_formatted_then_list'}
        a='exact formatted record\n0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0\n'
        b='exact formatted record\n 0D0 1D0 2D0 3D0 4D0 5D0 6D0 7D0\n'
        self.assertTrue(output_matches(a,b,case))
        self.assertFalse(output_matches(a.replace('exact ','exact  '),b,case))
        self.assertFalse(output_matches(a.replace('7.0','7.1'),b,case))
        self.assertFalse(output_matches(a+'\n',b,case))

if __name__ == '__main__':
    unittest.main()
