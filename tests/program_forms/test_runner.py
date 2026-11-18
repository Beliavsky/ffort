#!/usr/bin/env python3
"""Self-tests of independent stage/value checking, never interpreter internals."""
import sys
import unittest
import run_tests as runner

def result(code=0, out='', err=''):
    return dict(returncode=code, stdout=out, stderr=err)

class ValueChecks(unittest.TestCase):
    def test_spacing(self): self.assertTrue(runner.compare(' 1\t2\nT F ', '1 2 T F'))
    def test_exact_large_integer(self): self.assertFalse(runner.compare('2147483646','2147483647'))
    def test_integral_real_exact(self): self.assertFalse(runner.compare('2.147483646E9','2147483647'))
    def test_integral_real_format(self): self.assertTrue(runner.compare('1.67772160E7','16777216'))
    def test_real_roundoff(self): self.assertTrue(runner.compare('0.100000001','0.1'))
    def test_real_error(self): self.assertFalse(runner.compare('0.1001','0.1'))
    def test_nonfinite(self): self.assertFalse(runner.compare('NaN','0.1'))
    def test_missing_output(self): self.assertFalse(runner.compare('1','1 2'))
    def test_extra_output(self): self.assertFalse(runner.compare('1 2','1'))
    def test_logical(self): self.assertFalse(runner.compare('F','T'))
    def test_empty(self): self.assertTrue(runner.compare('',''))

class StageChecks(unittest.TestCase):
    def assess(self, kind='success', check=None, execution=None):
        return runner.candidate_errors(dict(kind=kind,expected='32'),check or result(),execution or result(out='32'))
    def test_good_success(self): self.assertFalse(self.assess())
    def test_wrong_value(self): self.assertTrue(self.assess(execution=result(out='31')))
    def test_check_output(self): self.assertTrue(self.assess(check=result(out='32')))
    def test_success_crash(self): self.assertTrue(self.assess(execution=result(-11,'32')))
    def test_good_rejection(self): self.assertFalse(self.assess('reject',result(1,err='bad source'),result(1,err='bad source')))
    def test_silent_acceptance(self): self.assertTrue(self.assess('reject',result(),result()))
    def test_static_output(self): self.assertTrue(self.assess('reject',result(1,err='error'),result(1,'99','error')))
    def test_rejection_diagnostic(self): self.assertTrue(self.assess('reject',result(1),result(1)))
    def test_rejection_crash(self): self.assertTrue(self.assess('reject',result(-11,err='error'),result(-11,err='error')))
    def test_good_runtime(self): self.assertFalse(self.assess('runtime',result(),result(2,err='runtime error')))
    def test_wrong_runtime_stage(self): self.assertTrue(self.assess('runtime',result(1,err='error'),result(1,err='error')))
    def test_runtime_output(self): self.assertTrue(self.assess('runtime',result(),result(2,'unexpected','error')))
    def test_runtime_no_diagnostic(self): self.assertTrue(self.assess('runtime',result(),result(2)))
    def test_timeout(self):
        output=runner.run([sys.executable,'-c','import time;print("started",flush=True);time.sleep(2)'],timeout=.05)
        self.assertIsNone(output['returncode'])
        self.assertTrue(output['timeout'])
        self.assertIsInstance(output['stdout'],str)
        self.assertTrue(self.assess('reject',output,output))

if __name__=='__main__': unittest.main()
