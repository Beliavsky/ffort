#!/usr/bin/env python3
"""Adversarial harness tests, never executes the candidate."""
import copy,hashlib,importlib.util,json,os,shutil,subprocess,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import run_tests as r
class Checks(unittest.TestCase):
    def setUp(self):self.case=json.loads((r.ROOT/'synthetic-manifest.json').read_text())['cases'][0]
    def test_finite_oracle_accepts(self):
        self.assertEqual(r.numeric_errors(' '.join(x['value'] for x in self.case['numeric']),self.case['numeric']),[])
    def test_zero_never_tail(self):
        c=next(c for c in json.loads((r.ROOT/'synthetic-manifest.json').read_text())['cases'] if c['name']=='erfc_extreme_composition')
        for i in [1,3]:self.assertTrue(r.numeric_errors('0',[c['numeric'][i]]))
    def test_nonfinite(self):
        for s in ['NaN','Inf','-Infinity']:self.assertTrue(r.numeric_errors(s,[self.case['numeric'][0]]))
    def test_missing_numeric(self):self.assertTrue(r.numeric_errors('',self.case['numeric']))
    def test_extra_numeric(self):self.assertTrue(r.numeric_errors('1 2',[self.case['numeric'][0]]))
    def test_order(self):self.assertTrue(r.numeric_errors(' '.join(x['value'] for x in self.case['numeric'][::-1]),self.case['numeric']))
    def test_bad_token(self):self.assertTrue(r.numeric_errors('garbage',[self.case['numeric'][0]]))
    def test_wrong_value(self):self.assertTrue(r.numeric_errors('1',[self.case['numeric'][0]]))
    def test_fixed_differential(self):
        r0=self.case['numeric'][0]
        self.assertTrue(r.numeric_differential(r0['value'],r0['value'],[r0]))
    def test_bad_differential(self):
        self.assertFalse(r.numeric_differential('1','0',self.case['numeric'][:1]))
    def test_nonfinite_differential(self):
        self.assertFalse(r.numeric_differential('NaN','NaN',self.case['numeric'][:1]))
    def test_differential_count(self):
        self.assertFalse(r.numeric_differential('1 2','1',self.case['numeric'][:1]))
    def test_exact_whitespace(self):self.assertTrue(r.output_errors(dict(expected='a  |\n'),'a |\n'))
    def test_exact_integer(self):self.assertTrue(r.output_errors(dict(expected='9223372036854775807\n'),'9223372036854775806\n'))
    def test_exact_newline(self):self.assertTrue(r.output_errors(dict(expected='ok\n'),'ok'))
    def test_signal(self):self.assertTrue(r.crash(dict(code=-11,err='')))
    def test_timeout(self):self.assertTrue(r.crash(dict(code=None,err='TimeoutExpired')))
    def test_hidden_backtrace(self):self.assertTrue(r.crash(dict(code=0,err='Backtrace:')))
    def failure(self):return dict(category='runtime',diagnostic='finite result range',expected='before\n')
    def results(self):return dict(code=0,err='',out=''),dict(code=2,err='finite result range',out='before\n')
    def test_valid_runtime_failure(self):self.assertEqual(r.candidate_errors(self.failure(),*self.results()),[])
    def test_partial_record(self):
        a,b=self.results();b['out']+='partial';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_missing_diagnostic(self):
        a,b=self.results();b['err']='';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_path_not_diagnostic(self):
        a,b=self.results();b['err']='finite result range.f90:1:1: other';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_wrong_exit(self):
        a,b=self.results();b['code']=1;self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_check_stdout(self):
        a,b=self.results();a['out']='leak';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_check_warning(self):
        a,b=self.results();a['err']='warning';self.assertTrue(r.candidate_errors(self.failure(),a,b))
    def test_unsafe_gnu_stage(self):
        c=copy.deepcopy(self.case);c.update(category='runtime',diagnostic='x',expected='');c.pop('numeric')
        with self.assertRaises(ValueError):r.validate(c)
    def test_relaxed_budget(self):
        c=copy.deepcopy(self.case);c['numeric'][0]['max_ulp']=400
        with self.assertRaises(ValueError):r.validate(c)
    def test_unknown_kind(self):
        c=copy.deepcopy(self.case);c['numeric'][0]['kind']=16
        with self.assertRaises(ValueError):r.validate(c)
    def test_compile_only_note(self):
        c=copy.deepcopy(self.case);c['gnu']='compile';c['note']=''
        with self.assertRaises(ValueError):r.validate(c)
    def test_provenance(self):self.assertEqual(len(r.provenance()['originals']),3)
    def tamper(self,which):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t);shutil.copytree(r.ROOT/'original',p/'original');shutil.copy2(r.ROOT/'original-source-map.json',p)
            m=json.loads((p/'original-source-map.json').read_text())
            if which=='bytes':
                f=p/m['originals'][0]['source'];f.write_bytes(f.read_bytes()+b'! substituted\n')
            if which=='forged':
                c=m['originals'][0];f=p/c['source'];f.write_bytes(f.read_bytes()+b'! substitute\n');c['bytes']=f.stat().st_size;c['sha256']=r.digest(f)
            if which=='missing':m['originals'].pop()
            if which=='extra':m['originals'].append(m['originals'][0])
            if which=='license':(p/'original/LICENSE').write_text('replaced')
            if which=='commit':m['originals'][0]['upstream_commit']='wrong'
            (p/'original-source-map.json').write_text(json.dumps(m))
            with self.assertRaises(ValueError):r.provenance(p)
    def test_changed_original(self):self.tamper('bytes')
    def test_forged_original_hash(self):self.tamper('forged')
    def test_missing_original(self):self.tamper('missing')
    def test_extra_original(self):self.tamper('extra')
    def test_changed_license(self):self.tamper('license')
    def test_changed_commit(self):self.tamper('commit')
    def test_snapshot_empty(self):
        with tempfile.TemporaryDirectory() as t:
            a=Path(t)/'a';b=Path(t)/'b';a.write_bytes(b'');a.chmod(0o700)
            with self.assertRaises(ValueError):r.snapshot(a,b)
    def test_snapshot_nonexecutable(self):
        with tempfile.TemporaryDirectory() as t:
            a=Path(t)/'a';b=Path(t)/'b';a.write_bytes(b'ab')
            with self.assertRaises(ValueError):r.snapshot(a,b)
    def test_snapshot_race(self):
        with tempfile.TemporaryDirectory() as t:
            a=Path(t)/'a';b=Path(t)/'b';a.write_bytes(b'#!/bin/sh\n');a.chmod(0o700)
            original=shutil.copy2
            def race(s,d):original(s,d);s.write_bytes(b'changed')
            with patch.object(r.shutil,'copy2',side_effect=race):
                with self.assertRaises(ValueError):r.snapshot(a,b)
    def test_execute_timeout(self):
        with patch.object(r.subprocess,'run',side_effect=subprocess.TimeoutExpired(['x'],30)):
            self.assertIsNone(r.execute(['x'],r.ROOT)['code'])
    def test_execute_missing(self):
        with patch.object(r.subprocess,'run',side_effect=OSError('missing')):
            self.assertIsNone(r.execute(['x'],r.ROOT)['code'])
    def test_generator_replay(self):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t);(p/'cases').mkdir();shutil.copy2(r.ROOT/'prepare_cases.py',p)
            x=subprocess.run([sys.executable,p/'prepare_cases.py'],capture_output=True)
            self.assertEqual(x.returncode,0,x.stderr)
            self.assertEqual((p/'synthetic-manifest.json').read_bytes(),(r.ROOT/'synthetic-manifest.json').read_bytes())
            originals={f.name:f.read_bytes() for f in (r.ROOT/'cases').glob('*.f90')}
            self.assertEqual({f.name:f.read_bytes() for f in (p/'cases').glob('*.f90')},originals)
if __name__=='__main__':unittest.main(verbosity=2)
