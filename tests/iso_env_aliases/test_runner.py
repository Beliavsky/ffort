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
        good = outcome(code=2, err='case.f90:3:4: SET_EXPONENT overflow')
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

    def test_formatted_output_is_exact_when_requested(self):
        case = dict(expected_stdout=' 1\n', exact_stdout=True)
        self.assertEqual(output_errors(case, ' 1\n'), [])
        self.assertTrue(output_errors(case, '1\n'))


if __name__ == '__main__':
    unittest.main()
