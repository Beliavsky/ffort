#!/usr/bin/env python3
"""Self-test output matching and fail-closed candidate assessment."""
import unittest
from run_tests import compare,candidate_errors
class RunnerTests(unittest.TestCase):
    def test_real64_tight_tolerance(self):
        self.assertTrue(compare('1.0000000000001','1.0',rel_tol=1e-12,abs_tol=1e-14))
        self.assertFalse(compare('1.00000001','1.0',rel_tol=1e-12,abs_tol=1e-14))
    def test_exact_format_spacing(self):
        self.assertTrue(compare('    3\n','    3',mode='lines'))
        self.assertFalse(compare(' 3\n','    3',mode='lines'))
    def test_real_roundoff(self):
        self.assertTrue(compare('4.59999990','4.6'))
    def test_integer_exactness(self):
        self.assertFalse(compare('4.000001','4'))
    def test_integer64_exactness(self):
        self.assertTrue(compare('9007199254740993','9007199254740993'))
        self.assertFalse(compare('9007199254740992','9007199254740993'))
    def test_tokens(self):
        self.assertFalse(compare('4 5','4'))
        self.assertFalse(compare('','4'))
        self.assertFalse(compare('F','T'))
    def test_nonfinite(self):
        self.assertFalse(compare('nan','4.6'))
        self.assertFalse(compare('inf','4.6'))
    def test_fortran_exponent(self):
        self.assertTrue(compare('4.6D+0','4.6'))
    def test_static_output_leak(self):
        case=dict(category='invalid',expected_stdout='',diagnostic=None)
        self.assertTrue(candidate_errors(case,dict(code=1,out='',err='bad'),dict(code=1,out='123',err='bad')))
    def test_runtime_output(self):
        case=dict(category='runtime',expected_stdout='123',diagnostic='uninitialized')
        self.assertFalse(candidate_errors(case,dict(code=0,out='',err=''),dict(code=2,out='123',err='Uninitialized result')))
    def test_path_cannot_satisfy_diagnostic(self):
        case=dict(category='runtime',expected_stdout='',diagnostic='uninitialized')
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err=''),dict(code=2,out='',err='/tmp/uninitialized.f90:1:1: Other failure')))
    def test_missing_diagnostic(self):
        case=dict(category='invalid',expected_stdout='',diagnostic=None)
        self.assertTrue(candidate_errors(case,dict(code=1,out='',err=''),dict(code=1,out='',err='')))
    def test_success_diagnostic(self):
        case=dict(category='success',expected_stdout='T',diagnostic=None)
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err=''),dict(code=0,out='T',err='unexpected')))
    def test_wrong_exit(self):
        case=dict(category='runtime',expected_stdout='',diagnostic=None)
        self.assertTrue(candidate_errors(case,dict(code=1,out='',err='bad'),dict(code=1,out='',err='bad')))
if __name__=='__main__':unittest.main()
