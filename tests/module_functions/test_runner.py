#!/usr/bin/env python3
"""Self-test output matching and fail-closed candidate assessment."""
import unittest
from run_tests import compare,candidate_errors
class RunnerTests(unittest.TestCase):
    def test_real_roundoff(self):
        self.assertTrue(compare('4.59999990','4.6'))
    def test_integer_exactness(self):
        self.assertFalse(compare('4.000001','4'))
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
    def test_wrong_exit(self):
        case=dict(category='runtime',expected_stdout='',diagnostic=None)
        self.assertTrue(candidate_errors(case,dict(code=1,out='',err='bad'),dict(code=1,out='',err='bad')))
if __name__=='__main__':unittest.main()
