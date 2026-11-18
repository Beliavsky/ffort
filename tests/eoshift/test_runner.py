#!/usr/bin/env python3
"""Independent checks that malformed candidate outcomes cannot pass the runner."""
import unittest
from run_tests import compare, candidate_errors, output_errors, clean_success, gnu_rejection_errors
from verify_registry import validate_registry_text


def outcome(code=0, out='', err=''):
    return dict(code=code, out=out, err=err)


class RunnerTests(unittest.TestCase):
    def test_registry_duplicates_are_rejected(self):
        with self.assertRaises(ValueError):validate_registry_text('NUM_INTRINSICS=2; name="eoshift"; name="eoshift"')
    def test_registry_count_mismatch_is_rejected(self):
        with self.assertRaises(ValueError):validate_registry_text('NUM_INTRINSICS=2; name="eoshift"')
    def test_each_intrinsic_identity_is_required(self):
        self.assertEqual(validate_registry_text('NUM_INTRINSICS=1; name="eoshift"'),1)
        with self.assertRaises(ValueError):validate_registry_text('NUM_INTRINSICS=1; name="cshift"')
    def test_character_records_are_exact(self):
        c=dict(expected_stdout='header A 1',exact_lines={'1':'A  \n'})
        self.assertEqual(output_errors(c,'header\nA  \n 1\n'),[])
        for bad in ['header\nA\n 1\n','header\n A \n 1\n','header A 1']:
            self.assertTrue(output_errors(c,bad))

    def test_default_tolerance_is_exact(self):
        self.assertFalse(compare('0.7853981633974484','0.7853981633974483'))
        self.assertTrue(compare('0.7853981633974484','0.7853981633974483',4e-15,0))

    def test_zero_cannot_mask_subnormal_with_relative_tolerance(self):
        self.assertFalse(compare('0.0','1.40129846e-45',3e-7,0))
        self.assertFalse(compare('0.0','4.9406564584124654e-324',4e-15,0))

    def test_binary_domain_error_does_not_leak_prefix(self):
        case=dict(category='runtime',expected_stdout='',diagnostic='EOSHIFT')
        self.assertEqual(candidate_errors(case,outcome(),outcome(2,err='EOSHIFT non-finite')),[])
        self.assertTrue(candidate_errors(case,outcome(),outcome(2,out='must not leak',err='EOSHIFT non-finite')))

    def test_subnormal_is_not_zero(self):
        self.assertFalse(compare('0.0', '4.9406564584124654e-324', rel_tol=4e-15, abs_tol=0))
        self.assertTrue(compare('4.9406564584124654e-324', '4.9406564584124654e-324', abs_tol=0))

    def test_integers_are_exact(self):
        self.assertFalse(compare('9223372036854775806', '9223372036854775807',3e-7,0))
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
        good = outcome(code=2, err='case.f90:3:4: EOSHIFT overflow')
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
            self.assertFalse(compare(got,want,3e-7,0))
        self.assertTrue(compare('-0.0D-400','-0.000',0,0))

    def test_wide_integer_real_token_is_exact(self):
        self.assertFalse(compare('9007199254740992.0','9007199254740993',3e-7,0))
        self.assertFalse(compare('9223372036854775806.0','9223372036854775807',3e-7,0))
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

    def test_success_stderr_requires_exact_silence(self):
        c=dict(category='success',expected_stdout='1')
        for leak in [' ', '\t', '\n', ' \t\n']:
            self.assertTrue(candidate_errors(c,outcome(err=leak),outcome(out='1')))
            self.assertTrue(candidate_errors(c,outcome(),outcome(out='1',err=leak)))

    def test_check_stdout_requires_exact_silence(self):
        c=dict(category='success',expected_stdout='1')
        for leak in [' ', '\t', '\n', ' \t\n']:
            self.assertTrue(candidate_errors(c,outcome(out=leak),outcome(out='1')))

    def test_negative_empty_stdout_rejects_whitespace(self):
        for category,code in [('reject',1),('runtime',2)]:
            c=dict(category=category,expected_stdout='',diagnostic='failure')
            check=outcome(code=1,err='failure') if category=='reject' else outcome()
            for leak in [' ', '\t', '\n', ' \t\n']:
                self.assertTrue(candidate_errors(c,check,outcome(code=code,out=leak,err='failure')))
            self.assertEqual(candidate_errors(c,check,outcome(code=code,err='failure')),[])

    def test_positive_empty_stdout_rejects_whitespace(self):
        c=dict(category='success',expected_stdout='')
        self.assertEqual(candidate_errors(c,outcome(),outcome()),[])
        for leak in [' ', '\t', '\n', ' \t\n']:
            self.assertTrue(candidate_errors(c,outcome(),outcome(out=leak)))

    def test_gnu_success_stderr_requires_exact_silence(self):
        self.assertTrue(clean_success(outcome()))
        for leak in [' ', '\t', '\n', ' \t\n']:
            self.assertFalse(clean_success(outcome(err=leak)))
        self.assertFalse(clean_success(outcome(code=2)))

    def test_expected_formatted_whitespace_is_retained(self):
        c=dict(expected_stdout=' \t\n',exact_stdout=True)
        self.assertEqual(output_errors(c,' \t\n'),[])
        for wrong in ['', '\n', '  \t\n']:
            self.assertTrue(output_errors(c,wrong))


class PrefixTests(unittest.TestCase):
    def test_formatted_prefix_is_byte_exact(self):
        c=dict(expected_stdout='A B T',exact_prefix=' A B\n')
        self.assertEqual(output_errors(c,' A B\n T'),[])
        for bad in ['A B\n T',' A B T',' A  B\n T']:
            self.assertTrue(output_errors(c,bad))

class OracleBoundaryTests(unittest.TestCase):
    def test_ordinary_gnu_rejection_is_still_exit_one(self):
        self.assertEqual(gnu_rejection_errors({},outcome(1,err='invalid source')),[])
        for code in [0,4,-11,None]:self.assertTrue(gnu_rejection_errors({},outcome(code,err='invalid source')))
    def test_known_crash_requires_explicit_status_and_marker(self):
        c=dict(gnu_limitation='documented GNU crash',gnu_compile_exit=4,gnu_compile_diagnostic='internal compiler error')
        self.assertEqual(gnu_rejection_errors(c,outcome(4,err='internal compiler error')),[])
        self.assertTrue(gnu_rejection_errors(c,outcome(1,err='internal compiler error')))
        self.assertTrue(gnu_rejection_errors(c,outcome(4,err='some unrelated failure')))
    def test_unclassified_crash_never_passes(self):
        for c in [dict(gnu_compile_exit=4),dict(gnu_compile_exit=4,gnu_limitation='known'),dict(gnu_compile_exit=4,gnu_compile_diagnostic='ICE')]:
            self.assertTrue(gnu_rejection_errors(c,outcome(4,err='ICE')))
    def test_known_gnu_defect_cannot_leak_stdout(self):
        c=dict(gnu_limitation='known',gnu_compile_diagnostic='wrong length')
        self.assertEqual(gnu_rejection_errors(c,outcome(1,err='wrong length')),[])
        for out in [' ', '\n', 'extra']:self.assertTrue(gnu_rejection_errors(c,outcome(1,out=out,err='wrong length')))

if __name__ == '__main__':
    unittest.main()
