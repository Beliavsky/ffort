#!/usr/bin/env python3
"""Regression tests for safe oracle gating and fail-closed output checks."""
import copy
import unittest
from run_tests import equal, source_cases, verify_case


def result(status=0,stdout='',stderr='',**kwargs):
    return dict(status=status,stdout=stdout,stderr=stderr,**kwargs)


class TestRealHarness(unittest.TestCase):
    def test_named_sources_are_unique_and_portable(self):
        cases=source_cases()
        self.assertEqual(len(cases),len({c['name'] for c in cases}))
        for c in cases:
            self.assertTrue(c['source'].isascii(),c['name'])
            self.assertLessEqual(max(map(len,c['source'].splitlines())),132,c['name'])
            self.assertIn(c['mode'],['pass','reject','unsupported','runtime'])

    def test_numeric_and_shape_mismatches_fail(self):
        self.assertTrue(equal('4 8 1.25 T','4 8 1.25000000 T'))
        for a,b in [('4 8','4 4'),('1 2','1'),('T','F'),('NaN','NaN'),('Inf','Inf'),('1.2','1.3')]:
            self.assertFalse(equal(a,b),(a,b))

    def test_zero_absolute_tolerance_and_signed_zero(self):
        for a,b in [('0.0','1.0e-308'),('1e-300','1e-301'),('0.0','-0.0'),('-0.0','0.0')]:
            self.assertFalse(equal(a,b),(a,b))
        self.assertTrue(equal('-0.0','-0.000E+0'))
        self.assertTrue(equal('2.2250738585072014e-308','2.2250738585072014d-308'))

    def test_integer_type_and_exact_value(self):
        self.assertFalse(equal('9007199254740993','9007199254740992'))
        self.assertFalse(equal('4.0','4'))
        self.assertFalse(equal('4','4e0'))
        self.assertTrue(equal('+4','4'))

    def test_text_and_exponent_normalization(self):
        self.assertTrue(equal('1.25D+02 2d-3','1.25e+02 2E-3'))
        self.assertTrue(equal('MixedCase text','MixedCase text'))
        self.assertFalse(equal('MixedCase','mixedcase'))
        self.assertFalse(equal('domain','eomain'))
        self.assertFalse(equal('1.0d+0','text'))

    def test_valid_gnu_failure_is_not_waived(self):
        self.assertFalse(verify_case(dict(mode='pass'),result(1,stderr='compile error'),None,result(),result()))

    def test_invalid_source_requires_gnu_rejection(self):
        good=result();fail=result(1,stderr='compile error')
        self.assertTrue(verify_case(dict(mode='reject'),fail,None,fail,fail))
        self.assertFalse(verify_case(dict(mode='reject'),good,None,fail,fail))
        self.assertFalse(verify_case(dict(mode='reject'),fail,good,fail,fail))

    def test_unsafe_gnu_execution_is_not_accepted(self):
        good=result();failed=result(2,stderr='uninitialized')
        case=dict(mode='runtime',diagnostic='uninitialized')
        self.assertTrue(verify_case(case,good,None,good,failed))
        self.assertFalse(verify_case(case,good,good,good,failed))
        for mode in ['unsupported','reject']:
            reject=result(1,stderr='unsupported')
            g=reject if mode=='reject' else good
            self.assertFalse(verify_case(dict(mode=mode),g,good,reject,reject))

    def test_nonempty_failure_diagnostics_required(self):
        case=dict(mode='reject');fail=result(1,stderr='compile error')
        for target in ['gnu','check','run']:
            processes=[copy.deepcopy(fail),None,copy.deepcopy(fail),copy.deepcopy(fail)]
            processes[{'gnu':0,'check':2,'run':3}[target]]['stderr']=''
            self.assertFalse(verify_case(case,*processes),target)

    def test_wrong_exits_signals_timeouts_and_leaks(self):
        case=dict(mode='reject');fail=result(1,stderr='compile error')
        for status in [0,2,-9,None]:
            for position in [2,3]:
                processes=[copy.deepcopy(fail),None,copy.deepcopy(fail),copy.deepcopy(fail)]
                processes[position]['status']=status
                self.assertFalse(verify_case(case,*processes),(status,position))
        for position in [0,2,3]:
            for bad in [dict(timeout=True),dict(launch_error=True),dict(stdout='123')]:
                processes=[copy.deepcopy(fail),None,copy.deepcopy(fail),copy.deepcopy(fail)]
                processes[position].update(bad)
                self.assertFalse(verify_case(case,*processes),(position,bad))
        self.assertFalse(verify_case(case,result(-9,stderr='signal'),None,fail,fail))
        # Success must not ignore an interpreter timeout or diagnostic.
        self.assertFalse(verify_case(dict(mode='pass'),result(),result(stdout='1.0'),
                                     result(),result(stdout='1.0',timeout=True)))
        self.assertFalse(verify_case(dict(mode='pass'),result(),result(stdout='1.0'),
                                     result(stderr='unexpected'),result(stdout='1.0')))

    def test_runtime_stdout_leak_and_wrong_exit_fail(self):
        case=dict(mode='runtime',diagnostic='overflow')
        for status,stdout,stderr in [(1,'','overflow'),(2,'123','overflow'),(2,'',''),(-9,'','overflow')]:
            self.assertFalse(verify_case(case,result(),None,result(),result(status,stdout,stderr)))


if __name__=='__main__':
    unittest.main()
