#!/usr/bin/env python3
"""Self-tests for independent fixture generation and strict runner assertions."""
import json
import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from run_tests import compare,candidate_errors,output_errors
ROOT=Path(__file__).resolve().parent
class RunnerTests(unittest.TestCase):
    def test_reproducible_generation(self):
        with tempfile.TemporaryDirectory() as folder:
            temp=Path(folder);(temp/'generate_cases.py').write_bytes((ROOT/'generate_cases.py').read_bytes())
            ran=subprocess.run([sys.executable,temp/'generate_cases.py'],capture_output=True,text=True)
            self.assertEqual(ran.returncode,0,ran.stderr)
            self.assertEqual((temp/'manifest.json').read_bytes(),(ROOT/'manifest.json').read_bytes())
            self.assertEqual(sorted(p.name for p in (temp/'cases').glob('*.f90')),sorted(p.name for p in (ROOT/'cases').glob('*.f90')))
            for f in (temp/'cases').glob('*.f90'):self.assertEqual(f.read_bytes(),(ROOT/'cases'/f.name).read_bytes())
    def test_exact_user_sources_unchanged(self):
        for name,digest in [('user_exact_mean_initialized','12e72c4669721ba920638191881b6465b7efe2847a7ac10eb34700bc61cd698e'),('user_exact_mean_random','f856c8130ed9a42ca8d6027318c7adc5875ce921455bb460ec2b5f2502d61525')]:
            self.assertEqual(hashlib.sha256((ROOT/'cases'/(name+'.f90')).read_bytes()).hexdigest(),digest)
    def test_random_range(self):
        self.assertTrue(compare('0 0.99999999','R R'))
        for text in ('-0.1','1','1.01','NaN','Inf','-Inf','word'):self.assertFalse(compare(text,'R'))
    def test_random_count(self):
        self.assertFalse(compare('0.2','R R'));self.assertFalse(compare('0.2 0.3','R'))
    def test_random_and_sentinels(self):
        self.assertTrue(compare('-1 .23 -1','-1 R -1'))
        self.assertFalse(compare('.2 .23 -1','-1 R -1'))
    def test_random_statistics_reject_constant(self):
        self.assertTrue(output_errors({'statistics':4096},' '.join(['0.5']*4096)))
    def test_random_statistics_reject_missing_sample(self):
        self.assertTrue(output_errors({'statistics':4096},' '.join(['0.5']*4095)))
    def test_random_statistics_reject_nonnumeric_nonfinite(self):
        self.assertTrue(output_errors({'statistics':4},'a b c d'))
        self.assertTrue(output_errors({'statistics':4},'0 NaN Inf 1'))
    def test_random_statistics_accept_balanced_spread(self):
        self.assertFalse(output_errors({'statistics':4096},' '.join(str((i+.5)/4096) for i in range(4096))))
    def test_successive_calls_must_advance(self):
        c={'expected_stdout':'R R R R','distinct_halves':True}
        self.assertTrue(output_errors(c,'.1 .2 .1 .2'));self.assertFalse(output_errors(c,'.1 .2 .3 .4'))
    def test_nonfinite(self):
        for s in ('NaN','Inf','-Inf'):self.assertFalse(compare(s,'1.0'))
    def test_exact_integer(self):self.assertFalse(compare('8.000001','8'))
    def test_exponent(self):self.assertTrue(compare('7.5D-1','.75'))
    def test_reject_must_not_print(self):
        self.assertTrue(candidate_errors(dict(category='invalid',expected_stdout=''),dict(code=1,out='',err='bad'),dict(code=1,out='991',err='bad')))
    def test_check_must_not_print(self):
        self.assertTrue(candidate_errors(dict(category='success',expected_stdout='1'),dict(code=0,out='1',err=''),dict(code=0,out='1',err='')))
    def test_missing_diagnostic(self):
        self.assertTrue(candidate_errors(dict(category='invalid',expected_stdout=''),dict(code=1,out='',err=''),dict(code=1,out='',err='')))
    def test_runtime_retains_prior_record(self):
        c=dict(category='runtime',expected_stdout='71',diagnostic='uninitialized')
        self.assertFalse(candidate_errors(c,dict(code=0,out='',err=''),dict(code=2,out='71',err='uninitialized read')))
        self.assertTrue(candidate_errors(c,dict(code=0,out='',err=''),dict(code=2,out='71 0',err='uninitialized read')))
    def test_path_is_not_a_diagnostic(self):
        self.assertTrue(candidate_errors(dict(category='runtime',expected_stdout='',diagnostic='uninitialized'),dict(code=0,out='',err=''),dict(code=2,out='',err='/tmp/uninitialized.f90:2:2: Other failure')))
    def test_selector_boundary_is_explicit(self):
        cases={c['name']:c for c in json.loads((ROOT/'manifest.json').read_text())['cases']}
        for name in ('real_selector_arithmetic','real_selector_const_abs','real_selector_procedure_header','real_selector_direct_kind_procedure_header'):
            self.assertEqual(cases[name]['category'],'unsupported')
            self.assertEqual(cases[name]['baseline'],'compile')
            self.assertTrue(cases[name]['boundary_note'])
        for name in ('real_selector_direct_kind_result_declaration','real_selector_undefined_array_kind','real_selector_constructor_kind'):
            self.assertEqual(cases[name]['category'],'success')
    def test_category_and_oracle_separation(self):
        cases={c['name']:c for c in json.loads((ROOT/'manifest.json').read_text())['cases']}
        self.assertEqual(cases['random_seed_unsupported']['category'],'success')
        self.assertEqual(cases['random_seed_unsupported']['baseline'],'run')
        self.assertEqual(cases['random_seed_unsupported']['expected_stdout'],'991')
        self.assertEqual(cases['random_invalid_integer']['baseline'],'reject')
        self.assertEqual(cases['random_runtime_unselected_undefined']['baseline'],'skip')
        self.assertEqual(cases['constructor_unsupported_implied_do']['baseline'],'run')
if __name__=='__main__':unittest.main()
