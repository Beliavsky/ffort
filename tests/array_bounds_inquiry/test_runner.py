#!/usr/bin/env python3
"""Self-test output matching and fail-closed candidate assessment."""
import unittest
import tempfile
import json
import hashlib
from pathlib import Path
from run_tests import compare,candidate_errors,gnu_success_errors,verify_provenance
class RunnerTests(unittest.TestCase):
    def test_upstream_exact_bytes(self):
        verify_provenance()
    def test_upstream_changed_bytes(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            (root/'upstream.json').write_text(json.dumps({'files':{'example.f90':hashlib.sha256(b'original').hexdigest()}}))
            (root/'example.f90').write_bytes(b'original\n')
            with self.assertRaisesRegex(ValueError,'provenance mismatch'):
                verify_provenance(root)
    def test_upstream_missing_bytes(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            (root/'upstream.json').write_text(json.dumps({'files':{'example.f90':hashlib.sha256(b'original').hexdigest()}}))
            with self.assertRaisesRegex(ValueError,'provenance mismatch'):
                verify_provenance(root)
    def test_real64_tight_tolerance(self):
        self.assertTrue(compare('1.0000000000001','1.0',rel_tol=1e-12,abs_tol=1e-14))
        self.assertFalse(compare('1.00000001','1.0',rel_tol=1e-12,abs_tol=1e-14))
    def test_exact_format_spacing(self):
        self.assertTrue(compare('    3\n','    3',mode='lines'))
        self.assertFalse(compare(' 3\n','    3',mode='lines'))
    def test_relative_tiny_oracle(self):
        self.assertFalse(compare('0', '5e-300', rel_tol=1e-12, abs_tol=0))
        self.assertTrue(compare('5.000000000000001e-300', '5e-300', rel_tol=1e-12, abs_tol=0))
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
    def test_empty_output_rejects_whitespace(self):
        for mode in ('tokens','lines'):
            self.assertTrue(compare('','',mode=mode))
            for leak in (' ', '\t', '\n', '\r\n', '\n \n'):
                with self.subTest(mode=mode,leak=repr(leak)):
                    self.assertFalse(compare(leak,'',mode=mode))
    def test_check_stdout_requires_exact_empty(self):
        for category,code,run_code in [('success',0,0),('runtime',0,2),('reject',1,1)]:
            for leak in (' ', '\t', '\n'):
                with self.subTest(category=category,leak=repr(leak)):
                    case=dict(category=category,expected_stdout='',diagnostic=None)
                    errors=candidate_errors(case,dict(code=code,out=leak,err='bad' if code else ''),
                                            dict(code=run_code,out='',err='bad' if run_code else ''))
                    self.assertIn('check stdout leak',errors)
    def test_successful_check_stderr_requires_exact_empty(self):
        case=dict(category='success',expected_stdout='',diagnostic=None)
        for leak in (' ', '\t', '\n'):
            with self.subTest(leak=repr(leak)):
                self.assertIn('check: unexpected success diagnostic',
                    candidate_errors(case,dict(code=0,out='',err=leak),dict(code=0,out='',err='')))
    def test_successful_run_stderr_requires_exact_empty(self):
        case=dict(category='success',expected_stdout='',diagnostic=None)
        for leak in (' ', '\t', '\n'):
            with self.subTest(leak=repr(leak)):
                self.assertIn('run: unexpected success diagnostic',
                    candidate_errors(case,dict(code=0,out='',err=''),dict(code=0,out='',err=leak)))
    def test_empty_run_stdout_all_categories(self):
        for category,code,run_code in [('success',0,0),('runtime',0,2),('reject',1,1)]:
            for leak in (' ', '\t', '\n'):
                with self.subTest(category=category,leak=repr(leak)):
                    case=dict(category=category,expected_stdout='',diagnostic=None)
                    self.assertIn('stdout mismatch/leak',candidate_errors(case,
                        dict(code=code,out='',err='bad' if code else ''),
                        dict(code=run_code,out=leak,err='bad' if run_code else '')))
    def test_gnu_success_stderr_requires_exact_empty(self):
        case=dict(expected_stdout='')
        for leak in (' ', '\t', '\n'):
            with self.subTest(leak=repr(leak)):
                self.assertIn('GNU unexpected success diagnostic',
                              gnu_success_errors(case,dict(code=0,out='',err=leak)))
    def test_gnu_empty_stdout_requires_exact_empty(self):
        case=dict(expected_stdout='')
        for leak in (' ', '\t', '\n'):
            with self.subTest(leak=repr(leak)):
                self.assertIn('GNU oracle mismatch',gnu_success_errors(case,dict(code=0,out=leak,err='')))
    def test_character_padding_and_extra_records(self):
        want='adjusted: [sample string       ]\n'
        self.assertTrue(compare(want,want,mode='lines'))
        self.assertTrue(compare(want,want.replace('\n','\r\n'),mode='lines'))
        self.assertFalse(compare(want+'\n',want,mode='lines'))
        self.assertFalse(compare(want+' ',want,mode='lines'))
        self.assertFalse(compare(want.replace('       ]','      ]'),want,mode='lines'))
        self.assertFalse(compare('a\t','a ',mode='lines'))
        self.assertFalse(compare('','\n',mode='lines'))
        self.assertTrue(compare('\n','\n',mode='lines'))
    def test_gnu_positive_exact_character_output(self):
        case=dict(expected_stdout='[a  ]\n',compare_mode='lines')
        self.assertEqual(gnu_success_errors(case,dict(code=0,out='[a  ]\n',err='')),[])
        self.assertTrue(gnu_success_errors(case,dict(code=0,out='[a ]\n',err='')))
    def test_candidate_positive_empty_output(self):
        case=dict(category='success',expected_stdout='',diagnostic=None)
        self.assertEqual(candidate_errors(case,dict(code=0,out='',err=''),dict(code=0,out='',err='')),[])
if __name__=='__main__':unittest.main()
