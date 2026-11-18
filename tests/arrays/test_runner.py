#!/usr/bin/env python3
"""Self-tests for the extra array safety assertions in the CLI runner."""
import copy
import unittest
from unittest.mock import patch
import run_corpus as runner

class RuntimeAssessmentTests(unittest.TestCase):
    def setUp(self):
        self.case=dict(category='runtime',expected_stdout='99',diagnostic='uninitialized')
        self.valid=dict(passed=True,errors=[],run=dict(stdout='99\n',stderr='uninitialized array element'))

    def assess(self, result):
        with patch.object(runner.shared,'assess_candidate',return_value=copy.deepcopy(result)):
            return runner.assess_candidate(self.case,['unused'],1)

    def test_accepts_exact_prior_output(self):
        self.assertTrue(self.assess(self.valid)['passed'])

    def test_rejects_partial_failed_print(self):
        self.valid['run']['stdout']='99\npartial 7\n'
        self.assertFalse(self.assess(self.valid)['passed'])

    def test_rejects_missing_prior_output(self):
        self.valid['run']['stdout']=''
        self.assertFalse(self.assess(self.valid)['passed'])

    def test_rejects_wrong_diagnostic(self):
        self.valid['run']['stderr']='some other problem'
        self.assertFalse(self.assess(self.valid)['passed'])

    def test_preserves_shared_failure(self):
        self.valid['errors']=['wrong exit code']
        self.assertFalse(self.assess(self.valid)['passed'])

class BoundsOracleTests(unittest.TestCase):
    def assess(self, code, stderr, *, timeout=False):
        compiled=dict(returncode=0,timeout=False,stdout='',stderr='')
        ran=dict(returncode=code,timeout=timeout,stdout='',stderr=stderr)
        with patch.object(runner,'execute',side_effect=[compiled,ran]):
            return runner.assess_baseline(dict(baseline='bounds_runtime',source='placeholder.f90'),'gfortran',1)

    def test_accepts_checked_bounds_failure(self):
        self.assertTrue(self.assess(2,'Index 3 above upper bound 2')['passed'])

    def test_rejects_clean_exit(self):
        self.assertFalse(self.assess(0,'bound')['passed'])

    def test_rejects_process_crash(self):
        self.assertFalse(self.assess(-11,'bound')['passed'])

    def test_rejects_missing_bounds_diagnostic(self):
        self.assertFalse(self.assess(2,'unrelated runtime failure')['passed'])

    def test_rejects_timeout(self):
        self.assertFalse(self.assess(None,'bound',timeout=True)['passed'])

if __name__=='__main__': unittest.main()
