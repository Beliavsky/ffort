#!/usr/bin/env python3
"""Prove output/status guards, full-source provenance and deterministic fixture replay."""
import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('cshift_runner', ROOT/'run_tests.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

class RunnerChecks(unittest.TestCase):
    def test_original_program(self):
        proof = runner.check_original()
        self.assertEqual(proof['bytes'], 857)
        self.assertEqual(proof['sha256'], '86868f08e1dc9d4b533e4b170734d02d6006642397486ce4160420b08eaf2fbd')
        self.assertFalse(proof['altered'])
        text = (ROOT/proof['local_file']).read_text()
        self.assertIn('program demo_cshift', text)
        self.assertIn('end program demo_cshift', text)
        self.assertIn('b = cshift(a, SHIFT=[1, 0, -1], DIM=2)', text)

    def test_status_and_output_guards(self):
        case = dict(category='success', expected_stdout='PASS')
        good = dict(code=0, out='', err='')
        ran = dict(code=0, out=' PASS\n', err='')
        self.assertEqual(runner.candidate_errors(case, good, ran), [])
        for stage in ('check', 'run'):
            for field, value in [('code',1), ('code',2), ('code',-11), ('code',None), ('err','warning')]:
                check, result = copy.deepcopy(good), copy.deepcopy(ran)
                (check if stage=='check' else result)[field] = value
                with self.subTest(stage=stage, field=field, value=value):
                    self.assertTrue(runner.candidate_errors(case, check, result))
        for value in ('', 'PASS PASS', 'nan', '1.0', 'FAIL'):
            with self.subTest(output=value):
                self.assertTrue(runner.candidate_errors(case, good, dict(ran,out=value)))
        for value in ('leak', ' ', '\n'):
            self.assertTrue(runner.candidate_errors(case, dict(good,out=value), ran))

    def test_rejection_guards(self):
        for category, rc in [('reject',1), ('runtime',2)]:
            case=dict(category=category,expected_stdout='',diagnostic='forbidden')
            check=dict(code=1 if category=='reject' else 0,out='',err='forbidden' if category=='reject' else '')
            ran=dict(code=rc,out='',err='path:1:2: forbidden action')
            self.assertEqual(runner.candidate_errors(case,check,ran),[])
            for field,value in [('code',0),('code',-11),('code',None),('out','leak'),('out',' '),('out','\n'),('err',''),('err','wrong')]:
                with self.subTest(category=category,field=field,value=value):
                    self.assertTrue(runner.candidate_errors(case,check,dict(ran,**{field:value})))
            for field,value in [('code',None),('out',' '),('err','' if category=='reject' else 'warning')]:
                self.assertTrue(runner.candidate_errors(case,dict(check,**{field:value}),ran))

    def test_preserved_completed_records(self):
        case = dict(category='runtime',baseline='compile',expected_stdout='',completed_stdout='BEFORE\n',diagnostic='DIM')
        check = dict(code=0,out='',err='')
        ran = dict(code=2,out='BEFORE\n',err='Invalid DIM')
        runner.validate_case(case | {'source':'cases/example.f90'})
        self.assertEqual(runner.candidate_errors(case,check,ran),[])
        for out in ('','BEFORE\npartial','BEFORE',' BEFORE\n'):
            self.assertTrue(runner.candidate_errors(case,check,dict(ran,out=out)))

    def test_comparison_guards(self):
        self.assertTrue(runner.compare('9223372036854775807','9223372036854775807'))
        self.assertFalse(runner.compare('9223372036854775806','9223372036854775807'))
        self.assertFalse(runner.compare('NaN','1.0'))
        self.assertFalse(runner.compare('inf','1.0'))
        self.assertFalse(runner.compare('1.0 2.0','1.0'))
        self.assertFalse(runner.compare('a\n','a ',mode='lines'))
        self.assertFalse(runner.compare('a\n','a',mode='exact'))
        self.assertTrue(runner.compare('1.25D+02','125.0'))

    def test_exact_numeric_comparison(self):
        # The former absolute tolerance accepted lost small values. Decimal
        # comparison also avoids host-float underflow and rounding collisions.
        for got, want in [('0.0','1e-9'), ('0.0','-1e-9'),
                          ('0.0','1.401298464324817e-45'),
                          ('0.0','4.9406564584124654e-324'), ('0.0','1e-9999'),
                          ('1.00000000000000001','1.00000000000000002'),
                          ('9223372036854775806.0','9223372036854775807.0'),
                          ('9223372036854775806','9223372036854775807'),
                          ('-9223372036854775808','-9223372036854775807'),
                          ('NaN','NaN'), ('Infinity','Infinity')]:
            with self.subTest(got=got,want=want):
                self.assertFalse(runner.compare(got,want))
                self.assertFalse(runner.compare(want,got))
        for got, want in [('1.25D+02','125.0'), ('-2.5d-3','-0.002500'),
                          ('+1.00E-9999','1d-9999'),
                          ('9223372036854775807.000','9.223372036854775807D18'),
                          ('+9223372036854775807','9223372036854775807')]:
            with self.subTest(got=got,want=want):
                self.assertTrue(runner.compare(got,want))
                self.assertTrue(runner.compare(want,got))

    def test_signed_zero_comparison(self):
        for got,want in [('0.0','-0.0'), ('-0d-99','0E+00'), ('0','-0.000'),
                         ('+0','-0'), ('0','-0')]:
            with self.subTest(got=got,want=want):
                self.assertFalse(runner.compare(got,want))
                self.assertFalse(runner.compare(want,got))
        for got,want in [('-0.000','-0D99'), ('+0.0','0e-99')]:
            with self.subTest(got=got,want=want):
                self.assertTrue(runner.compare(got,want))
                self.assertTrue(runner.compare(want,got))

    def test_text_comparison(self):
        self.assertTrue(runner.compare('  PASS\n cshift [1,2]','PASS cshift [1,2]'))
        for got,want in [('PASS','pass'), ('word1','word2'), ('1_8','1.0'),
                         ('one','1.0'), ('1.0','one'), ('x 1.0','x 1.0 extra')]:
            with self.subTest(got=got,want=want):
                self.assertFalse(runner.compare(got,want))
        case=dict(category='success',baseline='run',expected_stdout='PASS',source='cases/example.f90')
        for field in ('rel_tol','abs_tol'):
            with self.subTest(field=field),self.assertRaises(ValueError):
                runner.validate_case(case | {field: 0.0})

    def test_unsafe_gnu_mode_guard(self):
        case=dict(category='runtime',baseline='compile',expected_stdout='',source='cases/example.f90')
        runner.validate_case(case)
        for change in [dict(category='unknown'),dict(baseline='skip'),dict(baseline='run'),
                       dict(expected_stdout='PASS'),dict(source='/tmp/evil.f90'),dict(source='../evil.f90')]:
            with self.subTest(change=change),self.assertRaises(ValueError):
                runner.validate_case(case | change)
        for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
            runner.validate_case(case)

    def test_execute_failure_guards(self):
        with patch.object(runner.subprocess,'run',side_effect=FileNotFoundError('missing')):
            self.assertEqual(runner.execute(['not-an-executable']),dict(code=None,out='',err='missing'))
        with patch.object(runner.subprocess,'run',side_effect=subprocess.TimeoutExpired('x',15,b'part',b'err')):
            self.assertEqual(runner.execute(['x']),dict(code=None,out='part',err='TIMEOUT err'))

    def test_generator_exact_replay(self):
        with tempfile.TemporaryDirectory(prefix='cshift-generator-') as folder:
            dest = Path(folder)
            for name in ('generate_cases.py','demo_cshift.f90'):
                (dest/name).write_bytes((ROOT/name).read_bytes())
            result=subprocess.run([sys.executable,dest/'generate_cases.py'],capture_output=True,text=True,timeout=15)
            self.assertEqual(result.returncode,0,result.stderr)
            generated=[dest/'manifest.json',*sorted((dest/'cases').glob('*.f90'))]
            expected=[ROOT/'manifest.json',*sorted((ROOT/'cases').glob('*.f90'))]
            self.assertEqual(len(generated),len(expected))
            for path in generated:
                self.assertEqual(path.read_bytes(),(ROOT/path.relative_to(dest)).read_bytes(),str(path))

if __name__=='__main__':
    unittest.main()
