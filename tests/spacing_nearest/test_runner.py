#!/usr/bin/env python3
"""Independent result-comparison and diagnostic checks for this runner."""
import unittest
from run_tests import compare, candidate_errors
class RunnerChecks(unittest.TestCase):
    def test_tiny_not_zero(self):
        self.assertFalse(compare('0','2.2204460492503131E-16',2e-8,0))
    def test_subnormal_not_zero(self):
        self.assertFalse(compare('0','4.9406564584124654E-324',2e-8,0))
    def test_nearest_not_identity(self):
        self.assertFalse(compare('1','1.00000012',2e-8,0))
    def test_exact_flags(self):
        self.assertTrue(compare('T F 8','T F 8'))
        self.assertFalse(compare('T T 8','T F 8'))
    def test_nonfinite_rejected(self):
        self.assertFalse(compare('Infinity','1'))
        self.assertFalse(compare('NaN','1'))
    def test_policy_failure_and_atomic_prefix(self):
        case=dict(category='runtime',expected_stdout='retained',diagnostic='nonzero')
        check=dict(code=0,out='',err='')
        run=dict(code=2,out='retained\n',err='x.f90:4:1: direction nonzero')
        self.assertEqual(candidate_errors(case,check,run),[])
        run['out']='retained 99'
        self.assertTrue(candidate_errors(case,check,run))
if __name__=='__main__':unittest.main()
