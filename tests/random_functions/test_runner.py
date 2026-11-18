#!/usr/bin/env python3
"""Self-check the RNG suite's status/output oracle, provenance, and replay."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('random_function_runner', ROOT/'run_tests.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

class RunnerChecks(unittest.TestCase):
    def test_original_bodies(self):
        proof = runner.check_original_bodies()
        self.assertEqual(len(proof['routines']), 6)
        self.assertEqual({x['name'] for x in proof['routines']},
            {'ran_uni_vec', 'runif_vec', 'random_matrix', 'random_logical_vec',
             'random_logical_matrix', 'random_logical_3d'})

    def test_status_and_output_guards(self):
        case = dict(category='success', expected_stdout='PASS')
        good = dict(code=0, out='', err='')
        ran = dict(code=0, out=' PASS\n', err='')
        self.assertEqual(runner.candidate_errors(case, good, ran), [])
        for stage in ('check', 'run'):
            for field, value in [('code',1), ('code',2), ('code',None), ('err','warning')]:
                check, result = copy.deepcopy(good), copy.deepcopy(ran)
                (check if stage=='check' else result)[field] = value
                with self.subTest(stage=stage, field=field, value=value):
                    self.assertTrue(runner.candidate_errors(case, check, result))
        for value in ('', 'PASS PASS', 'nan', '1.0', 'FAIL'):
            with self.subTest(output=value):
                self.assertTrue(runner.candidate_errors(case, good, dict(ran,out=value)))
        self.assertTrue(runner.candidate_errors(case, dict(good,out='leak'), ran))

    def test_rejection_guards(self):
        for category, rc in [('reject',1), ('runtime',2)]:
            case=dict(category=category,expected_stdout='',diagnostic='forbidden')
            check=dict(code=1 if category=='reject' else 0,out='',err='forbidden' if category=='reject' else '')
            ran=dict(code=rc,out='',err='path:1:2: forbidden action')
            self.assertEqual(runner.candidate_errors(case,check,ran),[])
            for field,value in [('code',0),('code',None),('out','leak'),('err',''),('err','wrong')]:
                with self.subTest(category=category,field=field,value=value):
                    self.assertTrue(runner.candidate_errors(case,check,dict(ran,**{field:value})))

    def test_generator_exact_replay(self):
        # Run the maintained generator in an isolated layout; never rewrite
        # checked-in inputs as part of verification.
        with tempfile.TemporaryDirectory(prefix='random-function-generator-') as folder:
            root=Path(folder);dest=root/'tests/random_functions';dest.mkdir(parents=True)
            original=root/'tests/utilities_slices/source';original.mkdir(parents=True)
            (original/'xutilities.f90').write_bytes((ROOT.parent/'utilities_slices/source/xutilities.f90').read_bytes())
            (dest/'generate_cases.py').write_bytes((ROOT/'generate_cases.py').read_bytes())
            result=subprocess.run([sys.executable,dest/'generate_cases.py'],capture_output=True,text=True,timeout=15)
            self.assertEqual(result.returncode,0,result.stderr)
            generated=[dest/'manifest.json',*sorted((dest/'cases').glob('*.f90'))]
            self.assertEqual(len(generated),41)
            for path in generated:
                self.assertEqual(path.read_bytes(),(ROOT/path.relative_to(dest)).read_bytes(),str(path))

if __name__=='__main__':
    unittest.main()
