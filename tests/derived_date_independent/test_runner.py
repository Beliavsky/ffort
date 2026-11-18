#!/usr/bin/env python3
"""Self-test output, STOP and source-preservation accounting."""
from pathlib import Path
import hashlib
import json
import unittest
import generate_cases
from run_tests import run_errors, check_errors

ROOT = Path(__file__).resolve().parent


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.case = dict(expected_stdout='BEFORE\n',stop=None)
        self.good = dict(code=0,out='BEFORE\n',err='')

    def test_clean_success(self):
        self.assertFalse(run_errors(self.case,self.good))

    def test_extra_output(self):
        self.assertTrue(run_errors(self.case,dict(self.good,out='BEFORE\nAFTER\n')))

    def test_missing_output(self):
        self.assertTrue(run_errors(self.case,dict(self.good,out='')))

    def test_exit_failure(self):
        self.assertTrue(run_errors(self.case,dict(self.good,code=2)))

    def test_timeout_failure(self):
        self.assertTrue(run_errors(self.case,dict(self.good,code=None)))

    def test_stderr_failure(self):
        self.assertTrue(run_errors(self.case,dict(self.good,err='unexpected')))

    def test_stop_success(self):
        self.case['stop']='Invalid month'
        self.assertFalse(run_errors(self.case,dict(self.good,err='STOP Invalid month\n')))

    def test_stop_missing_message(self):
        self.case['stop']='Invalid month'
        self.assertTrue(run_errors(self.case,self.good))

    def test_stop_wrong_message(self):
        self.case['stop']='Invalid month'
        self.assertTrue(run_errors(self.case,dict(self.good,err='STOP Invalid year\n')))

    def test_stop_must_not_fail(self):
        self.case['stop']='Invalid month'
        self.assertTrue(run_errors(self.case,dict(self.good,code=2,err='Invalid month')))

    def test_check_clean(self):
        self.assertFalse(check_errors(dict(code=0,out='',err='')))

    def test_check_failure(self):
        self.assertTrue(check_errors(dict(code=1,out='',err='bad')))

    def test_check_stdout_leak(self):
        self.assertTrue(check_errors(dict(code=0,out='BEFORE\n',err='')))

    def test_check_stderr_leak(self):
        self.assertTrue(check_errors(dict(code=0,out='',err='STOP bad')))

    def test_manifest_and_determinism(self):
        before = {p.relative_to(ROOT):p.read_bytes() for p in [ROOT/'manifest.json',*sorted((ROOT/'cases').glob('*.f90'))]}
        manifest = generate_cases.generate()
        after = {p:p0.read_bytes() for p,p0 in [(p,ROOT/p) for p in before]}
        self.assertEqual(before,after)
        names = [c['name'] for c in manifest['cases']]
        self.assertEqual(len(names),len(set(names)))
        self.assertEqual(len(names),73)

    def test_original_exact_hash(self):
        manifest = json.loads((ROOT/'manifest.json').read_text())
        self.assertEqual(manifest['original_sha256'],
                         '6fd0bf18eaeb76fcc5d64e6a5c4dcfa9a50c29b805fde623483a51329b05364e')
        self.assertEqual(hashlib.sha256((ROOT/'user_exact_month_date.f90').read_bytes()).hexdigest(),manifest['original_sha256'])


if __name__ == '__main__':
    unittest.main()
