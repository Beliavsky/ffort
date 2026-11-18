#!/usr/bin/env python3
"""Checks that the source harness rejects incorrect outcomes and source drift."""
from pathlib import Path
import hashlib
import importlib.util
import json
import unittest
import tempfile
import subprocess
import sys
import shutil
import generate_cap_case as capgen

ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('length_harness', ROOT/'run_tests.py')
harness=importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)

class HarnessTests(unittest.TestCase):
    def stage(self, code=0, out='', err=''):
        return dict(code=code, out=out, err=err)

    def case(self, category='success', expected='1\n', diagnostic=''):
        return dict(category=category, expected_stdout=expected, diagnostic=diagnostic)

    def test_positive_stdout(self):
        self.assertTrue(harness.compare(' 1\n', '1\n'))
        self.assertEqual(harness.candidate_errors(self.case(), self.stage(), self.stage(out='1\n')), [])

    def test_wrong_value_and_extra_stdout(self):
        for value in ['2\n', '1 1\n', '', 'nan\n', 'inf\n']:
            self.assertFalse(harness.compare(value, '1\n'))
            self.assertIn('stdout mismatch/leak', harness.candidate_errors(self.case(), self.stage(), self.stage(out=value)))

    def test_check_stdout_leak(self):
        errors=harness.candidate_errors(self.case(), self.stage(out='leak'), self.stage(out='1'))
        self.assertIn('check stdout leak', errors)

    def test_success_stderr_leak(self):
        errors=harness.candidate_errors(self.case(), self.stage(err='bad'), self.stage(out='1',err='bad'))
        self.assertEqual(sum('unexpected success diagnostic' in error for error in errors),2)

    def test_runtime_stage_distinction(self):
        case=self.case('runtime','', 'length differs')
        self.assertEqual(harness.candidate_errors(case,self.stage(),self.stage(2,err='file.f90:3:5: length differs')),[])
        self.assertTrue(harness.candidate_errors(case,self.stage(1,err='reject'),self.stage(1,err='length differs')))
        self.assertTrue(harness.candidate_errors(case,self.stage(),self.stage(0)))

    def test_rejection_stage_distinction(self):
        case=self.case('reject','')
        self.assertEqual(harness.candidate_errors(case,self.stage(1,err='bad'),self.stage(1,err='bad')),[])
        self.assertTrue(harness.candidate_errors(case,self.stage(),self.stage(2,err='bad')))

    def test_diagnostic_required(self):
        errors=harness.candidate_errors(self.case('runtime','','length differs'),self.stage(),self.stage(2,err='other problem'))
        self.assertIn('missing diagnostic length differs', errors)
        errors=harness.candidate_errors(self.case('runtime',''),self.stage(),self.stage(2))
        self.assertIn('run: missing error diagnostic', errors)

    def test_runtime_stdout_not_ignored(self):
        errors=harness.candidate_errors(self.case('runtime',''),self.stage(),self.stage(2,out='999',err='bad'))
        self.assertIn('stdout mismatch/leak',errors)

    def test_timeout_is_failure(self):
        errors=harness.candidate_errors(self.case(),self.stage(),self.stage(None,err='TIMEOUT'))
        self.assertTrue(any('expected exit 0, got None' in error for error in errors))

    def temporary_cap_tree(self,folder,cap):
        repo=Path(folder)
        root=repo/'tests/allocatable_character_lengths'
        root.mkdir(parents=True)
        (root/'cases').mkdir()
        (repo/'src').mkdir()
        (repo/'src/fi_ir.f90').write_text(f'integer, parameter :: max_array_elements={cap}\n')
        for name in ('generate_cap_case.py','manifest.json','provenance.json'):
            shutil.copy2(ROOT/name,root/name)
        result=subprocess.run([sys.executable,str(root/'generate_cap_case.py')],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        return root

    def test_configured_cap_parsing(self):
        for cap in (131072,1000000,10000000):
            self.assertEqual(capgen.configured_cap(f' integer, PARAMETER :: max_array_elements = {cap} ! cap\n'),cap)

    def test_configured_cap_invalid(self):
        for source in ('', 'integer,parameter::max_array_elements=0',
                'integer,parameter::max_array_elements=2147483647',
                'integer,parameter::max_array_elements=1e6',
                'integer,parameter::max_array_elements=10\ninteger,parameter::max_array_elements=20'):
            with self.assertRaises(ValueError):capgen.configured_cap(source)

    def test_configured_cap_generation(self):
        original=json.loads((ROOT/'manifest.json').read_text())
        for cap in (131072,1000000,10000000):
            with tempfile.TemporaryDirectory(prefix='length-cap-generator-') as folder:
                root=self.temporary_cap_tree(folder,cap)
                self.assertEqual(capgen.check_generated(root)['requested_elements'],cap+1)
                generated=json.loads((root/'manifest.json').read_text())
                self.assertEqual([c for c in original['cases'] if c['name']!='element_cap_stat'],
                                 [c for c in generated['cases'] if c['name']!='element_cap_stat'])
                self.assertIn(f'allocate(a({cap+1}),stat=status)'.encode(),(root/capgen.CASE_SOURCE).read_bytes())
                before={n:(root/n).read_bytes() for n in (capgen.CASE_SOURCE,'manifest.json','provenance.json')}
                result=subprocess.run([sys.executable,str(root/'generate_cap_case.py')],capture_output=True,text=True)
                self.assertEqual(result.returncode,0,result.stderr)
                self.assertEqual(before,{n:(root/n).read_bytes() for n in before})

    def test_generated_cap_source_drift(self):
        with tempfile.TemporaryDirectory(prefix='length-cap-generator-') as folder:
            root=self.temporary_cap_tree(folder,1000000)
            (root/capgen.CASE_SOURCE).write_bytes(capgen.generated_source(131072))
            with self.assertRaises(ValueError):capgen.check_generated(root)

    def test_generated_cap_metadata_drift(self):
        with tempfile.TemporaryDirectory(prefix='length-cap-generator-') as folder:
            root=self.temporary_cap_tree(folder,1000000)
            provenance=json.loads((root/'provenance.json').read_text())
            provenance['synthetic_generated_cases']['element_cap_stat']['requested_elements']=1000000
            (root/'provenance.json').write_text(json.dumps(provenance))
            with self.assertRaises(ValueError):capgen.check_generated(root)

    def test_generated_cap_reconfiguration_detected(self):
        with tempfile.TemporaryDirectory(prefix='length-cap-generator-') as folder:
            root=self.temporary_cap_tree(folder,1000000)
            (root.parents[1]/'src/fi_ir.f90').write_text('integer,parameter::max_array_elements=10000000\n')
            with self.assertRaises(ValueError):capgen.check_generated(root)

    def test_tiny_values_are_not_zero(self):
        for tiny in ('1e-9','-1e-20','1e-300','1e-400'):
            self.assertFalse(harness.compare('0',tiny))
            self.assertFalse(harness.compare(tiny,'0'))
        self.assertFalse(harness.compare('1.0000000000000001','1'))

    def test_signed_zero_is_preserved(self):
        self.assertTrue(harness.compare('-0.0D+00','-0'))
        self.assertFalse(harness.compare('-0','0'))
        self.assertFalse(harness.compare('0.0','-0.0'))

    def test_adjacent_large_integers_are_distinct(self):
        self.assertFalse(harness.compare('9007199254740992','9007199254740993'))
        self.assertFalse(harness.compare('9223372036854775806','9223372036854775807'))
        self.assertTrue(harness.compare('9223372036854775807','9223372036854775807'))

    def test_decimal_exponent_notation(self):
        self.assertTrue(harness.compare('1.25D-300','0.125E-299'))
        self.assertTrue(harness.compare('1e400','10e399'))
        self.assertFalse(harness.compare('1.25D-300','1.2500000000000001E-300'))
        self.assertFalse(harness.compare('1e9999999999999999999','1e9999999999999999999'))

    def test_nonfinite_numeric_tokens_rejected(self):
        for value in ('NaN','nan','Infinity','-inf','sNaN'):
            self.assertFalse(harness.compare(value,value))
            self.assertFalse(harness.compare(value,'1'))

    def test_character_byte_exact_modes(self):
        for mode in ('bytes','lines'):
            self.assertTrue(harness.compare('a \r\n','a \r\n',mode))
            self.assertFalse(harness.compare('a \n','a\n',mode))
            self.assertFalse(harness.compare('a\r\n','a\n',mode))
            self.assertFalse(harness.compare('a\n\n','a\n',mode))
        self.assertTrue(harness.compare('alpha beta','alpha beta'))
        self.assertFalse(harness.compare('alpha beta','alpha Beta'))
        self.assertFalse(harness.compare('1','1','unknown'))

    def test_successful_stages_require_empty_streams(self):
        for leak in (' ','\n','\t','\r\n'):
            self.assertIn('check stdout leak',harness.candidate_errors(self.case(),self.stage(out=leak),self.stage(out='1')))
            for check,run in ((self.stage(err=leak),self.stage(out='1')),(self.stage(),self.stage(out='1',err=leak))):
                self.assertTrue(any('unexpected success diagnostic' in e for e in harness.candidate_errors(self.case(),check,run)))

    def test_no_output_requires_empty_bytes(self):
        for leak in (' ','\n','\t','\r\n'):
            self.assertFalse(harness.compare(leak,''))
            self.assertIn('stdout mismatch/leak',harness.candidate_errors(self.case('runtime',''),self.stage(),self.stage(2,out=leak,err='bad')))

    def test_capture_preserves_line_endings_and_invalid_bytes(self):
        result=harness.execute([sys.executable,'-c',"import sys; sys.stdout.buffer.write(bytes([120,32,13,10,255])); sys.stderr.buffer.write(b' ')"])
        self.assertEqual(result['code'],0)
        self.assertEqual(result['out'].encode('utf-8','surrogateescape'),bytes([120,32,13,10,255]))
        self.assertEqual(result['err'],' ')

    def test_exact_source_and_fixture_provenance(self):
        provenance=json.loads((ROOT/'provenance.json').read_text())
        original=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_bytes()
        self.assertEqual(hashlib.sha256(original).hexdigest(),provenance['source_sha256'])
        body=b''.join(original.splitlines(keepends=True)[provenance['start_line']-1:provenance['end_line']])
        self.assertEqual(hashlib.sha256(body).hexdigest(),provenance['body_sha256_with_terminal_crlf'])
        self.assertEqual(body.count(b'\r\n'),27)
        self.assertNotEqual(hashlib.sha256(body.replace(b'\r\n',b'\n')).hexdigest(),provenance['body_sha256_with_terminal_crlf'])
        cases=json.loads((ROOT/'manifest.json').read_text())['cases']
        exact=[case for case in cases if case.get('original_bodies')]
        self.assertEqual(len(exact),5)
        for case in exact:
            fixture=(ROOT/case['source']).read_bytes()
            self.assertEqual(fixture.count(body),1)
            self.assertNotIn(body,fixture.replace(b'\r\n',b'\n'))

if __name__=='__main__':
    unittest.main(verbosity=2)
