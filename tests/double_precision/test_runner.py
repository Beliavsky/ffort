#!/usr/bin/env python3
"""Independent checks that malformed candidate outcomes cannot pass the runner."""
import unittest
from run_tests import compare, candidate_errors, output_errors


def outcome(code=0, out='', err=''):
    return dict(code=code, out=out, err=err)


class RunnerTests(unittest.TestCase):
    def test_subnormal_is_not_zero(self):
        self.assertFalse(compare('0.0', '4.9406564584124654e-324', abs_tol=0))
        self.assertTrue(compare('4.9406564584124654e-324', '4.9406564584124654e-324', abs_tol=0))

    def test_integers_are_exact(self):
        self.assertFalse(compare('9223372036854775806', '9223372036854775807'))
        self.assertTrue(compare('9223372036854775807', '9223372036854775807'))

    def test_nonfinite_and_extra_output_rejected(self):
        for actual in ['nan', 'inf', '-inf', '0 999']:
            self.assertFalse(compare(actual, '0'))

    def test_success_requires_clean_outcomes(self):
        case = dict(category='success', expected_stdout='1')
        self.assertEqual(candidate_errors(case, outcome(), outcome(out='1')), [])
        for check, run in [(outcome(out='leak'), outcome(out='1')),
                           (outcome(), outcome(code=-11, out='1')),
                           (outcome(err='unexpected'), outcome(out='1')),
                           (outcome(), outcome(out='1', err='unexpected'))]:
            self.assertTrue(candidate_errors(case, check, run))

    def test_runtime_error_requires_correct_stage_and_diagnostic(self):
        case = dict(category='runtime', expected_stdout='', diagnostic='overflow')
        good = outcome(code=2, err='case.f90:3:4: test overflow')
        self.assertEqual(candidate_errors(case, outcome(), good), [])
        self.assertTrue(candidate_errors(case, outcome(code=1, err='overflow'), good))
        self.assertTrue(candidate_errors(case, outcome(), outcome(code=2)))
        self.assertTrue(candidate_errors(case, outcome(), outcome(code=2, err='wrong')))
        self.assertTrue(candidate_errors(case, outcome(), outcome(code=2, out='leak', err='overflow')))

    def test_source_rejection_requires_both_stages(self):
        case = dict(category='reject', expected_stdout='')
        rejected = outcome(code=1, err='not supported')
        self.assertEqual(candidate_errors(case, rejected, rejected), [])
        self.assertTrue(candidate_errors(case, rejected, outcome(code=2, err='runtime')))
        self.assertTrue(candidate_errors(case, outcome(code=1), rejected))

    def test_exact_adjacent_decimal_values_do_not_coalesce(self):
        self.assertFalse(compare('1.00000000000000001', '1.00000000000000002', 0, 0))
        self.assertFalse(compare('10000000000000000000000000000000001.0',
                                 '10000000000000000000000000000000002.0', 0, 0))
        self.assertTrue(compare('1.0D+0', '1.0000000', 0, 0))

    def test_decimal_underflow_does_not_coalesce(self):
        self.assertFalse(compare('0.0', '1e-1000', 0, 0))
        self.assertFalse(compare('1e-1000', '2e-1000', 0, 0))
        self.assertTrue(compare('1D-1000', '1e-1000', 0, 0))

    def test_zero_sign_is_preserved_even_with_tolerance(self):
        for got,want in [('0.0','-0.0'),('-0.0','0.0'),('0','-0'),('-0','0.0')]:
            self.assertFalse(compare(got,want,0,0))
            self.assertFalse(compare(got,want))
        self.assertTrue(compare('-0.0D-400','-0.000',0,0))

    def test_wide_integer_real_token_is_exact(self):
        self.assertFalse(compare('9007199254740992.0','9007199254740993'))
        self.assertFalse(compare('9223372036854775806.0','9223372036854775807'))
        self.assertTrue(compare('9223372036854775807.0','9223372036854775807'))

    def test_nonfinite_expected_values_are_rejected(self):
        for got,want in [('NaN','NaN'),('Infinity','Infinity'),('1.0','NaN')]:
            self.assertFalse(compare(got,want,0,0))

    def test_tolerance_is_explicitly_scoped(self):
        self.assertTrue(compare('0.8813735871','0.8813735870',1e-8,0))
        self.assertFalse(compare('0.8813735871','0.8813735870',0,0))
        self.assertFalse(compare('0.0','1e-1000',1e-6,0))

    def test_exact_case_metadata_reaches_comparator(self):
        case=dict(expected_stdout='1.00000000000000002 -0.0',rel_tol=0,abs_tol=0)
        self.assertTrue(output_errors(case,'1.00000000000000001 -0.0'))
        self.assertTrue(output_errors(case,'1.00000000000000002 0.0'))
        self.assertEqual(output_errors(case,'1.00000000000000002 -0.0'),[])

    def test_invalid_tolerances_are_rejected(self):
        for rel,absolute in [(-1,0),(0,-1),(float('nan'),0),(0,float('inf'))]:
            self.assertFalse(compare('1.0','1.0',rel,absolute))

    def test_formatted_output_is_exact_when_requested(self):
        case = dict(expected_stdout=' 1\n', exact_stdout=True)
        self.assertEqual(output_errors(case, ' 1\n'), [])
        self.assertTrue(output_errors(case, '1\n'))


if __name__ == '__main__':
    unittest.main()
