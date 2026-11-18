#!/usr/bin/env python3
"""Adversarial harness tests; no candidate compiler or runtime is needed."""
from contextlib import redirect_stdout
from io import StringIO
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import generate_cases
import run_tests as r


def result(code=0,out='',err=''): return dict(code=code,out=out,err=err)
def case(category='success',**kw): return dict(category=category,compare_mode='lines',diagnostic='',**kw)

class ComparisonTests(unittest.TestCase):
    def test_empty_means_no_bytes(self):
        for mode in ['lines','tokens']:
            self.assertTrue(r.compare('','',mode))
            for leak in [' ','\t','\n','\r\n','\n \n']:
                self.assertFalse(r.compare(leak,'',mode))
    def test_exact_character_records(self):
        text='[abc   ]\n'
        self.assertTrue(r.compare(text,text))
        self.assertFalse(r.compare('[abc   ]\r\n',text))
        for wrong in ['[abc  ]\n','[abc   ]','[abc   ]\n\n','[abc\t]\n',' [abc   ]\n']:
            self.assertFalse(r.compare(wrong,text))
    def test_decimal_integer_precision(self):
        self.assertTrue(r.compare('9007199254740993','9007199254740993','tokens'))
        self.assertFalse(r.compare('9007199254740992','9007199254740993','tokens'))
        self.assertFalse(r.compare('1.0','1','tokens'))
    def test_decimal_real_precision(self):
        self.assertTrue(r.compare('1.000000000000000000000001D0','1.000000000000000000000001','tokens'))
        self.assertFalse(r.compare('1.000000000000000000000000','1.000000000000000000000001','tokens'))
        self.assertFalse(r.compare('1.0000000000001','1.0','tokens'))
        self.assertFalse(r.compare('1.00000000001','1.0','tokens'))
    def test_sign_zero(self):
        self.assertTrue(r.compare('-0.000D0','-0.0','tokens'))
        self.assertFalse(r.compare('0.0','-0.0','tokens'))
        self.assertFalse(r.compare('-0.0','0.0','tokens'))
    def test_nonfinite_and_token_count(self):
        for bad in ['NaN','Infinity','-inf','nan(0)','1 1','']:
            self.assertFalse(r.compare(bad,'1.0','tokens'))
        self.assertFalse(r.compare('F','T','tokens'))
    def test_integer_signed_zero(self):
        self.assertTrue(r.compare('-000','-0','tokens'))
        self.assertTrue(r.compare('+0','0','tokens'))
        self.assertFalse(r.compare('0','-0','tokens'))
        self.assertFalse(r.compare('-0','0','tokens'))
    def test_identical_nonfinite_text_rejected(self):
        for text in ['NaN','nan','-NaN','NaN(payload)','nan(0x123)','sNaN42','Inf','-inf','+Infinity','Inf(payload)','Infinity(0x1)']:
            with self.subTest(text=text):
                self.assertFalse(r.compare(text,text,'tokens'))
    def test_binary64_overflow_rejected_without_underflow(self):
        for text in ['1e309','-1D9999','1.7976931348623158e308','9'*400]:
            with self.subTest(text=text):
                self.assertFalse(r.compare(text,text,'tokens'))
        self.assertTrue(r.compare('1.7976931348623157e308','1.7976931348623157e308','tokens'))
        self.assertTrue(r.compare('1D-400','1e-400','tokens'))
        self.assertTrue(r.compare('-1e-400','-1e-400','tokens'))
        self.assertFalse(r.compare('0.0','1e-400','tokens'))
        self.assertFalse(r.compare('1e-400','0.0','tokens'))
        self.assertFalse(r.compare('2e-400','1e-400','tokens'))
    def test_numeric_record_boundaries_and_terminators(self):
        self.assertTrue(r.compare(' 1  2\n3\n','1 2\n3\n','tokens'))
        for actual,expected in [('1\n2\n','1 2\n'),('1\n\n','1\n'),('1','1\n'),
                                ('1\r\n','1\n'),('1\r','1\n'),('\n1\n','1\n'),
                                ('1\n \n','1\n'),('1\v2','1 2'),(' \n','\n'),('1\n ','1\n')]:
            with self.subTest(actual=actual,expected=expected):
                self.assertFalse(r.compare(actual,expected,'tokens'))
    def test_blank_character_records_are_exact(self):
        self.assertTrue(r.compare('\n','\n'))
        for wrong in ['', ' \n','\r\n','\n\n','\n ']:
            self.assertFalse(r.compare(wrong,'\n'))
    def test_invalid_bytes_are_distinct(self):
        for byte in range(256):
            text=bytes([byte]).decode('latin-1')
            self.assertEqual(text.encode('latin-1'),bytes([byte]))
        self.assertFalse(r.compare(b'\xff\n'.decode('latin-1'),b'\xfe\n'.decode('latin-1')))
        self.assertFalse(r.compare(b'\xff\n'.decode('latin-1'),'\ufffd\n'))
    def test_unknown_mode_rejects(self):
        with self.assertRaises(ValueError):r.compare('a','a','broken')

class StageTests(unittest.TestCase):
    def test_all_categories_and_mutated_exits(self):
        for category,cc,rc in [('success',0,0),('runtime',0,2),('reject',1,1)]:
            c=case(category)
            check=result(cc,err='bad' if cc else '')
            run=result(rc,err='bad' if rc else '')
            self.assertEqual(r.candidate_errors(c,check,run,''),[])
            for bad in [-11,None,99]:
                self.assertTrue(r.candidate_errors(c,{**check,'code':bad},run,''))
                self.assertTrue(r.candidate_errors(c,check,{**run,'code':bad},''))
    def test_every_stdout_leak(self):
        for category,cc,rc in [('success',0,0),('runtime',0,2),('reject',1,1)]:
            check=result(cc,err='bad' if cc else '')
            run=result(rc,err='bad' if rc else '')
            for leak in [' ','\t','\n','unexpected']:
                self.assertIn('check stdout leak',r.candidate_errors(case(category),{**check,'out':leak},run,''))
                self.assertIn('stdout mismatch/leak',r.candidate_errors(case(category),check,{**run,'out':leak},''))
    def test_success_stderr_leaks(self):
        for leak in [' ','\t','\n','warning']:
            self.assertIn('check: unexpected success diagnostic',r.candidate_errors(case(),result(err=leak),result(),''))
            self.assertIn('run: unexpected success diagnostic',r.candidate_errors(case(),result(),result(err=leak),''))
    def test_missing_failure_diagnostic(self):
        self.assertTrue(r.candidate_errors(case('runtime'),result(),result(2),''))
        self.assertTrue(r.candidate_errors(case('reject'),result(1),result(1),''))
    def test_filename_cannot_satisfy_diagnostic(self):
        c=case('runtime');c['diagnostic']='uninitialized'
        errors=r.candidate_errors(c,result(),result(2,err='/tmp/uninitialized.f90:1:1: wrong failure'),'')
        self.assertIn('missing diagnostic uninitialized',errors)
    def test_gnu_compile_rejection_not_crash(self):
        c=dict(baseline='reject')
        self.assertEqual(r.gnu_compile_errors(c,result(1,err='invalid source')),[])
        for code in [0,-11,None,2]:self.assertTrue(r.gnu_compile_errors(c,result(code,err='bad')))
        self.assertTrue(r.gnu_compile_errors(c,result(1)))
    def test_gnu_success_exact_output_and_stderr(self):
        for leak in [' ','\n','\t']:
            self.assertTrue(r.gnu_success_errors(case(),result(out=leak),''))
            self.assertTrue(r.gnu_success_errors(case(),result(err=leak),''))
            self.assertTrue(r.gnu_compile_errors(dict(baseline='run'),result(err=leak)))
            self.assertTrue(r.gnu_compile_errors(dict(baseline='run'),result(out=leak)))
        self.assertTrue(r.gnu_success_errors(case(),result(out='[a ]\n'),'[a  ]\n'))
    def test_timeout_and_os_error_fail_closed(self):
        with patch.object(r.subprocess,'run',side_effect=subprocess.TimeoutExpired('x',1,output=b'partial')):
            got=r.execute(['x']);self.assertIsNone(got['code']);self.assertEqual(got['out'],'partial')
        with patch.object(r.subprocess,'run',side_effect=OSError('missing')):
            self.assertIsNone(r.execute(['x'])['code'])
    def test_capture_decoding_preserves_all_bytes(self):
        raw=bytes(range(256))
        proc=subprocess.CompletedProcess([],0,raw,raw[::-1])
        with patch.object(r.subprocess,'run',return_value=proc):
            got=r.execute(['x'])
        self.assertEqual(got['out'].encode('latin-1'),raw)
        self.assertEqual(got['err'].encode('latin-1'),raw[::-1])
        self.assertFalse(r.compare(got['out'],raw.decode('utf-8',errors='replace')))
    def test_timeout_capture_decoding_preserves_invalid_bytes(self):
        with patch.object(r.subprocess,'run',side_effect=subprocess.TimeoutExpired('x',1,output=b'\xff',stderr=b'\xfe')):
            got=r.execute(['x'])
        self.assertEqual(got['out'].encode('latin-1'),b'\xff')
        self.assertEqual(got['err'].encode('latin-1'),b'TIMEOUT \xfe')
    def test_executable_override_preserves_logical_argv0(self):
        with patch.object(r.subprocess,'run',return_value=subprocess.CompletedProcess([],0,b'',b'')) as call:
            r.execute(['program.f90'],cwd='/tmp',executable='/tmp/reference')
            self.assertEqual(call.call_args.args[0],['program.f90'])
            self.assertEqual(call.call_args.kwargs['executable'],'/tmp/reference')
            self.assertNotIn('shell',call.call_args.kwargs)

class ProvenanceTests(unittest.TestCase):
    def test_original_bytes_and_source_hashes(self):
        files=generate_cases.build()
        original=generate_cases.SOURCE.read_bytes()
        body=b''.join(original.splitlines(keepends=True)[548:557])
        self.assertIn(body,files['cases/original_exe_name.f90'])
        self.assertEqual(body.count(b'\n'),9)
        self.assertEqual(body.count(b'\r\n'),9)
        for c in json.loads(files['manifest.json'])['cases']:
            self.assertEqual(generate_cases.digest(files[c['source']]),c['source_sha256'])
    def test_generator_replay_and_mutation_rejection(self):
        files=generate_cases.build()
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)
            for name,data in files.items():
                path=root/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            with patch.object(r,'ROOT',root):
                self.assertEqual(len(r.verify_frozen()),len(json.loads(files['manifest.json'])['cases']))
                source=root/'cases/command_full.f90';source.write_bytes(source.read_bytes()+b'!mutation\n')
                with self.assertRaises(ValueError):r.verify_frozen()
                source.write_bytes(files['cases/command_full.f90'])
                (root/'manifest.json').write_bytes(b'{}')
                with self.assertRaises(ValueError):r.verify_frozen()
    def test_dynamic_expected_values(self):
        c=dict(expected_stdout=dict(type='original_exe_name',width=30),source_spelling='program.f90')
        self.assertEqual(r.expected_output(c,Path('/controlled')),'[/controlled\\program.f90       ]\n')
    def test_changed_candidate_is_failure(self):
        files=generate_cases.build()
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)
            for name,data in files.items():
                path=root/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            (root/'generate_cases.py').write_bytes(Path(generate_cases.__file__).read_bytes())
            fake=root/'fake';fake.write_bytes(b'initial')
            def changing(argv,*args,**kwargs):
                fake.write_bytes(fake.read_bytes()+b'changed')
                return result()
            argv=['runner','--candidate',str(fake),'--only','^command_number_only$','--result','mutant.json']
            with patch.object(r,'ROOT',root),patch.object(r,'execute',side_effect=changing),patch('sys.argv',argv),redirect_stdout(StringIO()):
                self.assertTrue(r.main())
            report=json.loads((root/'mutant.json').read_text())
            self.assertTrue(report['candidate_changed_during_run'])
            self.assertEqual(report['summary']['failed'],1)

if __name__=='__main__': unittest.main()
