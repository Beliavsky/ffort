#!/usr/bin/env python3
"""Adversarial contract tests; no interpreter or compiler invocation."""
import copy
import unittest
import run_tests as runner


class RunnerContracts(unittest.TestCase):
    def setUp(self):
        self.case=dict(category='success',expected_stdout='PASS\n')
        self.check=dict(code=0,out='',err='')
        self.run=dict(code=0,out=' PASS\n',err='')

    def test_valid(self):
        self.assertEqual(runner.candidate_errors(self.case,self.check,self.run),[])

    def test_success_noise(self):
        for stage,field,noise in [('check','out',' '),('check','out','\n'),('check','err',' '),('run','err','\n'),('run','out','PASS EXTRA\n'),('run','code',1)]:
            with self.subTest(stage=stage,field=field,noise=noise):
                c,r=copy.deepcopy(self.check),copy.deepcopy(self.run)
                (c if stage=='check' else r)[field]=noise
                self.assertTrue(runner.candidate_errors(self.case,c,r))

    def test_expected_empty_is_empty_bytes(self):
        c=dict(category='runtime',expected_stdout='',diagnostic='limit')
        for noise in (' ','\n','\t','PASS'):
            with self.subTest(noise=noise):
                self.assertTrue(runner.candidate_errors(c,self.check,dict(code=2,out=noise,err='step limit')))
        self.assertEqual(runner.candidate_errors(c,self.check,dict(code=2,out='',err='step limit')),[])

    def test_runtime_must_be_checked_successfully(self):
        c=dict(category='runtime',expected_stdout='')
        self.assertTrue(runner.candidate_errors(c,dict(code=1,out='',err='reject'),dict(code=2,out='',err='runtime')))

    def test_original_cpu_observations(self):
        good='Processor Time = 0.000 seconds.\nProcessor Time = .3E-5 seconds.\nProcessor Time = 1.234d-5 seconds.\n'
        self.assertEqual(runner.observe_cpu(dict(code=0,out=good,err='')),[])
        for out in [good+'\n',good.replace('0.000','NaN'),good.replace('0.000','Inf'),good.replace('0.000','-0.1'),good.replace('0.000','1e999'),good.replace('seconds.','seconds'),good[:30]]:
            with self.subTest(out=out):self.assertTrue(runner.observe_cpu(dict(code=0,out=out,err='')))
        self.assertTrue(runner.observe_cpu(dict(code=0,out=good,err=' ')))
        self.assertTrue(runner.observe_cpu(dict(code=2,out=good,err='failure')))

    def test_original_clock_observations(self):
        good=' accuracy may vary with argument type!\n query all arguments\n COUNT_MAX(64bit)= 9223372036854775807\n COUNT_RATE(64bit)= 1000000000\n CURRENT COUNT(64bit)= 17\n COUNT_MAX(32bit)= 2147483647\n COUNT_RATE(32bit)= 1000\n CURRENT COUNT(32bit)= 10\n time some computation\n'
        self.assertEqual(runner.observe_clock(dict(code=2,out=good,err='source:4:1: execution step limit exceeded')),[])
        for out in [good+'\n',good.replace('CURRENT COUNT(32bit)= 10','CURRENT COUNT(32bit)= -1'),good.replace('CURRENT COUNT(32bit)= 10','CURRENT COUNT(32bit)= 2147483648'),good.replace('COUNT_RATE(64bit)= 1000000000','COUNT_RATE(64bit)= NaN'),good.replace('time some computation','SUM= 10')]:
            with self.subTest(out=out):self.assertTrue(runner.observe_clock(dict(code=2,out=out,err='step limit')))
        self.assertTrue(runner.observe_clock(dict(code=0,out=good,err='')))

    def test_gnu_success_stderr_strict(self):
        self.assertTrue(runner.gnu_success_errors(self.case,dict(code=0,out='PASS',err=' ')))
        self.assertEqual(runner.gnu_success_errors(self.case,self.run),[])

if __name__=='__main__':
    unittest.main()
