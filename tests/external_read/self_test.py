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
from unittest.mock import patch

ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('length_harness', ROOT/'run_tests.py')
harness=importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)

class HarnessTests(unittest.TestCase):
    def stage(self, code=0, out='', err=''):
        return dict(code=code, out=out, err=err)

    def case(self, category='success', expected='1\n', diagnostic=''):
        case=dict(category=category, expected_stdout=expected, diagnostic=diagnostic, source='file.f90')
        if category != 'success':
            case['expected_diagnostic']=dict(line=3,column=5,message=diagnostic or 'bad')
        return case

    def error_text(self, case):
        return harness.expected_error_text(case)

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
        self.assertEqual(harness.candidate_errors(case,self.stage(),self.stage(2,err=self.error_text(case))),[])
        self.assertTrue(harness.candidate_errors(case,self.stage(1,err='reject'),self.stage(1,err='length differs')))
        self.assertTrue(harness.candidate_errors(case,self.stage(),self.stage(0)))

    def test_rejection_stage_distinction(self):
        case=self.case('invalid','')
        self.assertEqual(harness.candidate_errors(case,self.stage(1,err=self.error_text(case)),self.stage(1,err=self.error_text(case))),[])
        self.assertTrue(harness.candidate_errors(case,self.stage(),self.stage(2,err='bad')))

    def test_diagnostic_required(self):
        errors=harness.candidate_errors(self.case('runtime','','length differs'),self.stage(),self.stage(2,err='other problem'))
        self.assertIn('run: source diagnostic mismatch', errors)
        errors=harness.candidate_errors(self.case('runtime',''),self.stage(),self.stage(2))
        self.assertIn('run: missing error diagnostic', errors)

    def test_runtime_stdout_not_ignored(self):
        errors=harness.candidate_errors(self.case('runtime',''),self.stage(),self.stage(2,out='999',err='bad'))
        self.assertIn('stdout mismatch/leak',errors)

    def test_timeout_is_failure(self):
        errors=harness.candidate_errors(self.case(),self.stage(),self.stage(None,err='TIMEOUT'))
        self.assertTrue(any('expected exit 0, got None' in error for error in errors))

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

    def test_success_cannot_allow_stderr_through_metadata(self):
        case=self.case()
        case['expected_stderr']='STOP\n'
        self.assertTrue(harness.candidate_errors(case,self.stage(),self.stage(out='1',err='STOP\n')))
        self.assertEqual(harness.candidate_errors(case,self.stage(),self.stage(out='1')),[])

    def test_both_negative_phases_require_exact_diagnostic(self):
        case=self.case('invalid','', 'rejected input')
        good=self.error_text(case)
        for suffix in ('\n', 'extra\n', ' ', '\r\n', 'Backtrace for this error:\n'):
            for phase in ('check','run'):
                stages={name:self.stage(1,err=good) for name in ('check','run')}
                stages[phase]['err']+=suffix
                self.assertIn(phase+': source diagnostic mismatch',harness.candidate_errors(case,**{
                    'check':stages['check'],'result':stages['run']}))

    def test_negative_diagnostic_path_location_message_and_newline(self):
        case=self.case('runtime','', 'expected failure')
        good=self.error_text(case)
        variants=[good.replace('file.f90','other.f90'),good.replace(':3:5:',':4:5:'),
                  good.replace(':3:5:',':3:6:'),good.replace(':3:5:',':0:0:'),
                  good.replace('expected failure','EXPECTED failure'),good.rstrip('\n'),
                  good.replace('\n','\r\n'),' '+good,good+' ',good+good]
        for text in variants:
            self.assertIn('run: source diagnostic mismatch',harness.candidate_errors(
                case,self.stage(),self.stage(2,err=text)))

    def test_missing_and_malformed_pins_fail_closed(self):
        for pin in (None,{}, {'line':0,'column':5,'message':'bad'},
                    {'line':3,'column':True,'message':'bad'},
                    {'line':3,'column':5,'message':'bad\nextra'},
                    {'line':3,'column':5,'message':''}):
            case=self.case('runtime','');case['expected_diagnostic']=pin
            self.assertIn('run: missing pinned diagnostic',harness.candidate_errors(
                case,self.stage(),self.stage(2,err='file.f90:3:5: bad\n')))

    def test_host_failure_markers_rejected_even_if_pinned(self):
        markers=['Fortran runtime error: bad', 'Fortran runtime warning: bad',
                 'Backtrace for this error:', 'Program received signal SIGSEGV',
                 'Segmentation fault', 'SIGABRT', 'SIGBUS', 'SIGFPE',
                 'signal 11', 'internal compiler error', 'ICE',
                 'AddressSanitizer', 'UndefinedBehaviorSanitizer',
                 'stack smashing detected', 'core dumped', 'fatal signal']
        for marker in markers:
            case=self.case('invalid','',marker);good=self.error_text(case)
            errors=harness.candidate_errors(case,self.stage(1,err=good),self.stage(1,err=good))
            self.assertIn('check: host failure marker',errors)
            self.assertIn('run: host failure marker',errors)

    def test_host_failure_marker_in_stdout_cannot_be_expected(self):
        case=self.case(expected='Program received signal SIGSEGV\n')
        errors=harness.candidate_errors(case,self.stage(),self.stage(out=case['expected_stdout']))
        self.assertIn('run: host failure marker',errors)

    def test_signal_and_timeout_statuses_are_host_termination(self):
        case=self.case('runtime','')
        for code in (-11,-6,128,139,3221225477,None):
            errors=harness.candidate_errors(case,self.stage(),self.stage(code,err=self.error_text(case)))
            self.assertIn('run: unexpected host termination',errors)

    def test_negative_check_stdout_must_be_truly_empty(self):
        case=self.case('invalid','');good=self.error_text(case)
        for leak in (' ','\n','\t','\r\n'):
            errors=harness.candidate_errors(case,self.stage(1,out=leak,err=good),self.stage(1,err=good))
            self.assertIn('check stdout leak',errors)

    def test_ledger_covers_all_negatives_and_source_hashes(self):
        cases=harness.load_cases()
        self.assertEqual(len(cases),50)
        self.assertEqual(sum('expected_diagnostic' in case for case in cases),22)
        for case in cases:
            if case['category']!='success':
                self.assertIsNotNone(harness.expected_error_text(case))

    def test_ledger_rejects_missing_extra_and_stale_entries(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);(root/'case.f90').write_text('program p\nend\n')
            case=self.case('invalid','');case.update(name='negative',source='case.f90')
            case.pop('expected_diagnostic')
            (root/'manifest.json').write_text(json.dumps({'cases':[case]}))
            entry=dict(source='case.f90',source_sha256=hashlib.sha256((root/'case.f90').read_bytes()).hexdigest(),
                       line=3,column=5,message='bad')
            variants=[{}, {'negative':entry,'extra':entry},
                      {'negative':dict(entry,source='other.f90')},
                      {'negative':dict(entry,source_sha256='0'*64)}]
            for entries in variants:
                (root/'diagnostics.json').write_text(json.dumps({'schema_version':1,'negative_cases':entries}))
                with patch.object(harness,'ROOT',root):
                    with self.assertRaises(ValueError):harness.load_cases()
            (root/'diagnostics.json').write_text(json.dumps({'schema_version':1,'negative_cases':{'negative':entry}}))
            with patch.object(harness,'ROOT',root):
                self.assertEqual(len(harness.load_cases()),1)
                (root/'case.f90').write_text('changed fixture')
                with self.assertRaises(ValueError):harness.load_cases()

    def test_exact_source_and_fixture_provenance(self):
        provenance=json.loads((ROOT/'provenance.json').read_text())
        original=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_bytes()
        self.assertEqual(hashlib.sha256(original).hexdigest(),provenance['source_sha256'])
        cases=json.loads((ROOT/'manifest.json').read_text())['cases']
        exact=[c for c in cases if c.get('original_body')]
        self.assertEqual(len(exact),5)
        for info in provenance['bodies']:
            body=b''.join(original.splitlines(keepends=True)[info['start_line']-1:info['end_line']])
            self.assertEqual(hashlib.sha256(body).hexdigest(),info['sha256'])
            self.assertEqual(body.count(b'\r\n'),34)
            self.assertNotEqual(hashlib.sha256(body.replace(b'\r\n',b'\n')).hexdigest(),info['sha256'])
            for case in exact:
                fixture=(ROOT/case['source']).read_bytes()
                self.assertEqual(fixture.count(body),1)
                self.assertNotIn(body,fixture.replace(b'\r\n',b'\n'))

if __name__=='__main__':
    unittest.main(verbosity=2)
