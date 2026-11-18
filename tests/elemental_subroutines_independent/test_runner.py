#!/usr/bin/env python3
"""Self-test black-box runner correctness and deterministic corpus generation."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from run_tests import compare, candidate_errors

ROOT=Path(__file__).resolve().parent

class RunnerTests(unittest.TestCase):
    def test_reproducible_generation(self):
        with tempfile.TemporaryDirectory(prefix='elemental-fixtures-') as folder:
            temp=Path(folder)
            (temp/'generate_cases.py').write_bytes((ROOT/'generate_cases.py').read_bytes())
            ran=subprocess.run([sys.executable,temp/'generate_cases.py'],capture_output=True,text=True)
            self.assertEqual(ran.returncode,0,ran.stderr)
            self.assertEqual((temp/'manifest.json').read_bytes(),(ROOT/'manifest.json').read_bytes())
            for subdir in ('cases','pure_references'):
                self.assertEqual(sorted(p.name for p in (temp/subdir).glob('*.f90')),
                                 sorted(p.name for p in (ROOT/subdir).glob('*.f90')))
                for source in (temp/subdir).glob('*.f90'):
                    self.assertEqual(source.read_bytes(),(ROOT/subdir/source.name).read_bytes())

    def test_case_categories_are_separate(self):
        cases={c['name']:c for c in json.loads((ROOT/'manifest.json').read_text())['cases']}
        self.assertEqual(cases['unsupported_writable_impure_function']['category'],'unsupported')
        self.assertEqual(cases['invalid_conflict_pure_impure']['category'],'invalid')
        self.assertEqual(cases['invalid_only_in_array']['baseline'],'compile')
        self.assertEqual(cases['runtime_overlap_cross_elements']['baseline'],'skip')
        self.assertEqual(cases['invalid_array_dummy']['baseline'],'reject')

    def test_simple_reference_retains_elemental(self):
        source=(ROOT/'pure_references/simple_elemental_scalar.f90').read_text()
        self.assertIn('pure elemental subroutine',source)
        self.assertNotIn('pure pure',source)

    def test_success_requires_all_output(self):
        case=dict(category='success',expected_stdout='2 5 10')
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err=''),dict(code=0,out='2 5',err='')))

    def test_nonfinite_is_not_equal(self):
        for token in ('NaN','Inf','-Inf'):
            self.assertFalse(compare(token,'1.0'))

    def test_integer_expectations_exact(self):
        self.assertFalse(compare('8.000001','8'))
        self.assertTrue(compare('8','8'))

    def test_real64_tolerance(self):
        self.assertTrue(compare('0.75000000000001','0.75',rel_tol=1e-13,abs_tol=1e-14))
        self.assertFalse(compare('0.75000001','0.75',rel_tol=1e-13,abs_tol=1e-14))

    def test_fortran_exponents(self):
        self.assertTrue(compare('7.5D-1','0.75'))

    def test_static_errors_do_not_print(self):
        case=dict(category='invalid',expected_stdout='')
        self.assertTrue(candidate_errors(case,dict(code=1,out='',err='invalid'),dict(code=1,out='991',err='invalid')))

    def test_runtime_preserves_earlier_record(self):
        case=dict(category='runtime',expected_stdout='112',diagnostic='uninitialized')
        self.assertFalse(candidate_errors(case,dict(code=0,out='',err=''),dict(code=2,out='112',err='uninitialized result')))
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err=''),dict(code=2,out='112 1',err='uninitialized result')))

    def test_path_does_not_supply_required_diagnostic(self):
        case=dict(category='runtime',expected_stdout='',diagnostic='uninitialized')
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err=''),dict(code=2,out='',err='/tmp/uninitialized.f90:4:2: Other failure')))

    def test_failure_requires_diagnostic(self):
        case=dict(category='invalid',expected_stdout='')
        self.assertTrue(candidate_errors(case,dict(code=1,out='',err=''),dict(code=1,out='',err='')))

    def test_exit_status_is_not_inferred_from_output(self):
        case=dict(category='runtime',expected_stdout='112')
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err=''),dict(code=1,out='112',err='bad')))

    def test_success_disallows_stderr(self):
        case=dict(category='success',expected_stdout='1')
        self.assertTrue(candidate_errors(case,dict(code=0,out='',err='warning'),dict(code=0,out='1',err='')))

if __name__=='__main__':
    unittest.main()
