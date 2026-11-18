#!/usr/bin/env python3
"""Self-test output matching and fail-closed candidate assessment."""
import unittest
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from run_tests import compare,candidate_errors
class RunnerTests(unittest.TestCase):
    def test_generator_reproducible(self):
        root=Path(__file__).resolve().parent
        with tempfile.TemporaryDirectory(prefix='purity-generator-') as folder:
            temp=Path(folder)
            (temp/'generate_cases.py').write_bytes((root/'generate_cases.py').read_bytes())
            result=subprocess.run([sys.executable,str(temp/'generate_cases.py')],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual((temp/'manifest.json').read_bytes(),(root/'manifest.json').read_bytes())
            self.assertEqual(sorted(p.name for p in (temp/'cases').glob('*.f90')),
                             sorted(p.name for p in (root/'cases').glob('*.f90')))
            for case in json.loads((temp/'manifest.json').read_text())['cases']:
                self.assertEqual((temp/case['source']).read_bytes(),(root/case['source']).read_bytes())
                if case.get('pure_reference'):
                    self.assertEqual((temp/case['pure_reference']).read_bytes(),(root/case['pure_reference']).read_bytes())
    def test_case_classifications(self):
        root=Path(__file__).resolve().parent
        cases={c['name']:c for c in json.loads((root/'manifest.json').read_text())['cases']}
        self.assertEqual(cases['pure_host_read_unsupported']['category'],'unsupported')
        self.assertEqual(cases['simple_host_read_invalid']['category'],'invalid')
        self.assertEqual(cases['simple_calls_pure_function']['baseline'],'compile')
        self.assertEqual(cases['pure_calls_ordinary_function']['baseline'],'reject')
    def test_reference_does_not_rewrite_dummy_identifier(self):
        root=Path(__file__).resolve().parent
        source=(root/'pure_references/simple_keyword_named_simple.f90').read_text()
        self.assertIn('pure integer function compute(simple)',source)
        self.assertIn('compute(simple=4)',source)
        self.assertIn('rr=simple+3',source)
    def test_reference_preserves_comments_and_literals(self):
        root=Path(__file__).resolve().parent
        source=(root/'pure_references/simple_char_dummy.f90').read_text()
        self.assertIn('! simple subroutine bogus(xx)',source)
        self.assertIn('call accept("simple subroutine adjust(xx)")',source)
        self.assertIn('pure subroutine accept(txt)',source)
    def test_missing_success_output(self):
        case=dict(category='success',expected_stdout='17')
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err=''),dict(code=0,out='',err='')))
    def test_unexpected_success_diagnostic(self):
        case=dict(category='success',expected_stdout='123')
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err='bad'),dict(code=0,out='123',err='')))
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
