#!/usr/bin/env python3
"""Self-tests for the focused differential harness, including RNG inequalities."""
import hashlib
from pathlib import Path
import unittest
import run_tests as r
import generate_cases as g

class HarnessTests(unittest.TestCase):
    def test_01_complete_numeric_output(self):
        self.assertTrue(r.compare('7.5 2.5','7.5 2.5',1e-13,1e-13))
    def test_02_no_extra_output(self):
        self.assertFalse(r.compare('7.5 99','7.5'))
    def test_03_no_missing_output(self):
        self.assertFalse(r.compare('7.5','7.5 2.5'))
    def test_04_no_nonfinite_output(self):
        for value in ('NaN','inf','-inf'):
            self.assertFalse(r.compare(value,'R'))
    def test_05_random_range(self):
        for value in ('-0.1','1.0','2.0'):
            self.assertFalse(r.compare(value,'R'))
    def test_06_moment_inequalities(self):
        case=dict(expected_stdout='R R',random_moments=True)
        self.assertFalse(r.output_errors(case,'.5 .3333333333333333'))
        self.assertTrue(r.output_errors(case,'.5 .6'))
        self.assertTrue(r.output_errors(case,'.5 .1'))
    def test_07_check_output_leak(self):
        c=dict(category='success',expected_stdout='7.5')
        self.assertIn('check stdout leak',r.candidate_errors(c,dict(code=0,out='oops',err=''),dict(code=0,out='7.5',err='')))
    def test_08_invalid_needs_diagnostic(self):
        c=dict(category='invalid',expected_stdout='')
        errors=r.candidate_errors(c,dict(code=1,out='',err=''),dict(code=1,out='',err=''))
        self.assertEqual(len(errors),2)
    def test_09_runtime_exit(self):
        c=dict(category='runtime',expected_stdout='')
        self.assertFalse(r.candidate_errors(c,dict(code=0,out='',err=''),dict(code=2,out='',err='checked error')))
    def test_10_exact_wide_integer_output(self):
        self.assertTrue(r.compare('9007199254740997','9007199254740997'))
        self.assertFalse(r.compare('9007199254740996','9007199254740997'))
        self.assertFalse(r.compare('9007199254740998','9007199254740997'))
    def test_11_regeneration(self):
        root=Path(__file__).resolve().parent
        files=[root/'manifest.json',*sorted((root/'cases').glob('*.f90'))]
        before={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
        g.main()
        after={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
        self.assertEqual(before,after)

if __name__=='__main__':unittest.main()
