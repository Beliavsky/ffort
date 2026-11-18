#!/usr/bin/env python3
"""Harness fail-closed checks independent of the candidate interpreter."""
import unittest
from pathlib import Path
import tempfile
import subprocess
import shutil
import sys
import run_tests as runner
class Contracts(unittest.TestCase):
    def test_integer_match(self):self.assertTrue(runner.compare(' 1 2\n','1 2'))
    def test_integer_mismatch(self):self.assertFalse(runner.compare('1 3','1 2'))
    def test_missing_output(self):self.assertFalse(runner.compare('','1'))
    def test_extra_output(self):self.assertFalse(runner.compare('1 2 3','1 2'))
    def test_char_mismatch(self):self.assertFalse(runner.compare('abc','ABC'))
    def test_nonfinite(self):self.assertFalse(runner.compare('NaN','1'))
    def test_success(self):
        c=dict(category='success',expected_stdout='1')
        self.assertEqual(runner.candidate_errors(c,dict(code=0,out='',err=''),dict(code=0,out='1',err='')),[])
    def test_crash(self):
        c=dict(category='reject',expected_stdout='')
        self.assertTrue(runner.candidate_errors(c,dict(code=-11,out='',err='crash'),dict(code=-11,out='',err='crash')))
    def test_reject(self):
        c=dict(category='reject',expected_stdout='')
        self.assertEqual(runner.candidate_errors(c,dict(code=1,out='',err='error'),dict(code=1,out='',err='error')),[])
    def test_missing_diagnostic(self):
        c=dict(category='reject',expected_stdout='')
        self.assertTrue(runner.candidate_errors(c,dict(code=1,out='',err=''),dict(code=1,out='',err='')))
    def test_output_leak(self):
        c=dict(category='reject',expected_stdout='')
        self.assertTrue(runner.candidate_errors(c,dict(code=1,out='leak',err='error'),dict(code=1,out='',err='error')))
    def test_exact_padding(self):
        c=dict(exact_stdout=True,expected_stdout='q  \n')
        self.assertEqual(runner.output_errors(c,'q  \n'),[])
        self.assertTrue(runner.output_errors(c,'q\n'))
    def test_runtime_status(self):
        c=dict(category='runtime',expected_stdout='')
        self.assertEqual(runner.candidate_errors(c,dict(code=0,out='',err=''),dict(code=2,out='',err='undefined')),[])
    def test_generator_reproduces(self):
        root=Path(__file__).resolve().parent
        with tempfile.TemporaryDirectory(prefix='select-generator-') as tmp:
            target=Path(tmp)/'tests'/'select_case'
            (target/'cases').mkdir(parents=True)
            (Path(tmp)/'examples').mkdir()
            shutil.copy2(root/'generate_cases.py',target/'generate_cases.py')
            shutil.copy2(root.parent.parent/'examples'/'select_case.f90',Path(tmp)/'examples'/'select_case.f90')
            subprocess.run([sys.executable,target/'generate_cases.py'],check=True,capture_output=True)
            self.assertEqual((target/'manifest.json').read_bytes(),(root/'manifest.json').read_bytes())
            self.assertEqual({p.name for p in (target/'cases').glob('*.f90')},
                             {p.name for p in (root/'cases').glob('*.f90')})
            for generated in (target/'cases').glob('*.f90'):
                self.assertEqual(generated.read_bytes(),(root/'cases'/generated.name).read_bytes())
    def test_false_accept(self):
        c=dict(category='reject',expected_stdout='')
        self.assertTrue(runner.candidate_errors(c,dict(code=0,out='',err=''),dict(code=0,out='',err='')))
if __name__=='__main__':unittest.main()
