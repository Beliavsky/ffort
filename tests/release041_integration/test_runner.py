#!/usr/bin/env python3
"""Adversarial tests for exact release041 checks; no candidate execution."""
import copy,json,os,shutil,subprocess,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import run_tests as r
class Checks(unittest.TestCase):
    def case(self):return dict(name='probe',source='cases/probe.f90',sha256='a'*64,category='success',gnu='run',expected='ok\n',diagnostic='',note='')
    def test_decimal_d_notation(self):self.assertTrue(r.exact_numeric('1d2 -0.0D0',['100','-0']))
    def test_no_binary64_integer_coercion(self):self.assertFalse(r.exact_numeric('9223372036854775806',['9223372036854775807']))
    def test_last_decimal_distinguishes(self):self.assertFalse(r.exact_numeric('1.0000000000000000000000001',['1.0000000000000000000000002']))
    def test_no_blanket_tolerance(self):self.assertFalse(r.exact_numeric('0.9999999999999999',['1']))
    def test_positive_negative_zero(self):self.assertFalse(r.exact_numeric('0',['-0']))
    def test_negative_positive_zero(self):self.assertFalse(r.exact_numeric('-0',['0']))
    def test_nonzero_cannot_collapse(self):self.assertFalse(r.exact_numeric('0',['4.9406564584124654e-324']))
    def test_nonfinite(self):
        for t in ['NaN','sNaN','Infinity','-Inf']:self.assertFalse(r.exact_numeric(t,[t]))
    def test_bad_numeric(self):
        for t in ['1_0','1.0foo','1e','D','[1]']:self.assertFalse(r.exact_numeric(t,['1']))
    def test_count_and_order(self):
        for s in ['1','1 2 3','2 1']:self.assertFalse(r.exact_numeric(s,['1','2']))
    def test_text_case(self):self.assertTrue(r.output_errors({'expected':'DENSE\n'},'dense\n'))
    def test_text_spaces(self):self.assertTrue(r.output_errors({'expected':'a  b\n'},'a b\n'))
    def test_text_newline(self):self.assertTrue(r.output_errors({'expected':'ok\n'},'ok'))
    def test_signal(self):self.assertTrue(r.crash(dict(code=-11,err='')))
    def test_timeout(self):self.assertTrue(r.crash(dict(code=None,err='timeout')))
    def test_backtrace(self):self.assertTrue(r.crash(dict(code=0,err='Backtrace:')))
    def failure(self):return dict(category='runtime',diagnostic='specific guard',expected='before\n')
    def results(self):return dict(code=0,err='',out=''),dict(code=2,err='specific guard',out='before\n')
    def test_good_failure(self):self.assertEqual(r.candidate_errors(self.failure(),*self.results()),[])
    def test_partial_atomic_output(self):
        a,b=self.results();b['out']+='partial';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_missing_diagnostic(self):
        a,b=self.results();b['err']='';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_path_not_diagnostic(self):
        a,b=self.results();b['err']='specific guard.f90:1:1: other';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_wrong_exit(self):
        a,b=self.results();b['code']=1;self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_check_output(self):
        a,b=self.results();a['out']='leak';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_check_warning(self):
        a,b=self.results();a['err']='warning';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_unsafe_gnu(self):
        c=self.case();c.update(category='runtime',diagnostic='guard')
        with self.assertRaises(ValueError):r.validate(c)
    def test_no_hidden_tolerance(self):
        for field in ['max_ulp','tolerance','amplitude_budget','gnu_expected']:
            c=self.case();c[field]=100
            with self.assertRaises(ValueError):r.validate(c)
    def test_compile_note(self):
        c=self.case();c['gnu']='compile'
        with self.assertRaises(ValueError):r.validate(c)
    def test_source_traversal(self):
        c=self.case();c['source']='../probe.f90'
        with self.assertRaises(ValueError):r.validate(c)
    def test_invalid_reference(self):
        c=self.case();c['numeric']=['NaN']
        with self.assertRaises(ValueError):r.validate(c)
    def test_snapshot_empty(self):
        with tempfile.TemporaryDirectory() as t:
            a=Path(t)/'a';b=Path(t)/'b';a.write_bytes(b'');a.chmod(0o700)
            with self.assertRaises(ValueError):r.snapshot(a,b)
    def test_snapshot_nonexecutable(self):
        with tempfile.TemporaryDirectory() as t:
            a=Path(t)/'a';b=Path(t)/'b';a.write_bytes(b'abc')
            with self.assertRaises(ValueError):r.snapshot(a,b)
    def test_snapshot_race(self):
        with tempfile.TemporaryDirectory() as t:
            a=Path(t)/'a';b=Path(t)/'b';a.write_bytes(b'#!/bin/sh\n');a.chmod(0o700);old=shutil.copy2
            def race(s,d):old(s,d);s.write_bytes(b'changed')
            with patch.object(r.shutil,'copy2',side_effect=race):
                with self.assertRaises(ValueError):r.snapshot(a,b)
    def test_missing_executable(self):
        with patch.object(r.subprocess,'run',side_effect=OSError('missing')):self.assertIsNone(r.execute(['x'],r.ROOT)['code'])
    def test_expired_process(self):
        with patch.object(r.subprocess,'run',side_effect=subprocess.TimeoutExpired(['x'],30)):self.assertIsNone(r.execute(['x'],r.ROOT)['code'])
    def test_provenance(self):self.assertEqual(len(r.provenance()),13)
    def tamper(self,forged=False):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t);shutil.copytree(r.ROOT/'cases',p/'cases');shutil.copy2(r.ROOT/'synthetic-manifest.json',p)
            m=json.loads((p/'synthetic-manifest.json').read_text());f=p/m['cases'][0]['source'];f.write_bytes(f.read_bytes()+b'! changed\n')
            if forged:m['cases'][0]['sha256']=r.digest(f);(p/'synthetic-manifest.json').write_text(json.dumps(m))
            with self.assertRaises(ValueError):r.provenance(p)
    def test_source_tamper(self):self.tamper()
    def test_forged_source_hash(self):
        if not r.MANIFEST_SHA256:self.skipTest('manifest awaiting final fixed pin')
        self.tamper(True)
    def test_generator_reproducible(self):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t);(p/'cases').mkdir();shutil.copy2(r.ROOT/'prepare_cases.py',p)
            x=subprocess.run(['python3',p/'prepare_cases.py'],capture_output=True)
            self.assertEqual(x.returncode,0,x.stderr)
            self.assertEqual((p/'synthetic-manifest.json').read_bytes(),(r.ROOT/'synthetic-manifest.json').read_bytes())
            self.assertEqual({f.name:f.read_bytes() for f in (p/'cases').glob('*.f90')},{f.name:f.read_bytes() for f in (r.ROOT/'cases').glob('*.f90')})
if __name__=='__main__':unittest.main(verbosity=2)
