#!/usr/bin/env python3
"""Exact version contracts and mocked runner gates; no executable/compiler run."""
from pathlib import Path
import contextlib
import copy
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from unittest.mock import patch
from cli_version_contract import expected_version, read_project_version, version_errors
ROOT = Path(__file__).resolve().parents[1]

def good(version='0.50.0'):
    return {'returncode':0, 'timeout':False, 'stderr':'',
            'stdout':f'fortfront-interpreter {version}; FortFront 9a5896a + documented local patches\n'}

class VersionContractTests(unittest.TestCase):
    def test_explicit_past_current_future_versions(self):
        versions=['0.49.0','0.50.0','0.51.0','0.5.0','1.2.3']
        for wanted in versions:
            for actual in versions:
                with self.subTest(wanted=wanted,actual=actual):
                    self.assertEqual(not version_errors(good(actual),wanted),actual==wanted)
    def test_expected_version_is_not_prefix_or_pattern(self):
        for bad in [None,0,'','0.','0.50','0.50.0x','0.50.0;','0.50.0\n',' 0.50.0','0.50.0 ','00.50.0','0.050.0','0.50.00','.*','0.50.[0-9]','٠.٥٠.٠']:
            with self.subTest(value=bad), self.assertRaises(ValueError):expected_version(bad)
    def test_clean_status_required(self):
        for key,bad in [('returncode',1),('returncode',-11),('returncode',None),('returncode',False),('timeout',True),('timeout',None),('stderr',None),('stderr',' '),('stderr','\n'),('stderr','Backtrace:\n')]:
            r=good();r[key]=bad
            with self.subTest(key=key,value=bad):self.assertTrue(version_errors(r,'0.50.0'))
    def test_exact_single_banner(self):
        text=good()['stdout']
        for bad in [None,'',text[:-1],text+'\n',' '+text,text+'warning\n',text+text,text.replace('0.50.0','0.50.01'),text.replace('0.50.0','0.50.0-dev'),text.replace(';','x;'),text.replace('FortFront','Other'),text.replace('9a5896a','bad'),text.replace('9a5896a','z'*7),text.replace('9a5896a','a'*41),text.replace(' + ','\t+\t'),text.replace('patches','patches\x00'),text.replace('local patches','local patches\rBAD')]:
            r=good();r['stdout']=bad
            with self.subTest(value=bad):self.assertTrue(version_errors(r,'0.50.0'))
    def test_windows_line_ending_is_one_record(self):
        r=good();r['stdout']=r['stdout'].replace('\n','\r\n')
        self.assertEqual(version_errors(r,'0.50.0'),[])
    def test_project_version_is_not_derived_from_candidate(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'fpm.toml'
            for version in ['0.49.0','0.50.0','0.51.0']:
                p.write_text(f'name = "fortfront-interpreter"\nversion = "{version}" # release\n[dependencies]\nversion = "99.0.0"\n')
                self.assertEqual(read_project_version(p),version)
            for text in ['', '[dependencies]\nversion="0.50.0"\n','version="0.50.0"\nversion="0.51.0"\n','version="0.50"\n','version="0.50.0" trailing\n']:
                p.write_text(text)
                with self.subTest(text=text),self.assertRaises(ValueError):read_project_version(p)
    def test_verifier_passes_source_version_to_both_live_runners(self):
        source=(ROOT/'scripts/verify.py').read_text()
        self.assertIn('expected_version = read_project_version(ROOT / "fpm.toml")',source)
        for suite in ['leadz','integer_masks']:
            self.assertIn(f"'tests/{suite}/run_tests.py', '--candidate', exe, '--expected-version', expected_version, '--expected-sha256'",source)

class RunnerGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runners=[]
        for name,rel in [('leadz','tests/leadz/run_strict_tests.py'),('masks','tests/integer_masks/run_tests.py')]:
            p=ROOT/rel;sys.path.insert(0,str(p.parent))
            spec=importlib.util.spec_from_file_location('version_gate_'+name,p)
            module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
            cls.runners.append((name,module))
            sys.path.pop(0)
    def invoke(self,module,argv,record):
        with patch.object(sys,'argv',['runner',*argv]),patch.object(module,'sha',return_value='a'*64) as digest,patch.object(module,'execute',return_value=record) as execute,contextlib.redirect_stdout(io.StringIO()),contextlib.redirect_stderr(io.StringIO()):
            module.main()
        return digest,execute
    def test_missing_or_malformed_expected_version_precedes_execution(self):
        for name,m in self.runners:
            for value in [None,'0.','0.50.0\n']:
                args=['--candidate','not-executed','--expected-sha256','a'*64]
                if value is not None:args+=['--expected-version',value]
                with self.subTest(runner=name,value=value),patch.object(sys,'argv',['runner',*args]),patch.object(m,'sha') as digest,patch.object(m,'execute') as execute,contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as error:m.main()
                    self.assertEqual(error.exception.code,2);digest.assert_not_called();execute.assert_not_called()
    def test_matching_hash_cannot_override_wrong_version(self):
        for name,m in self.runners:
            for record in [good('0.49.0'),good('0.51.0'),{**good(),'stdout':good()['stdout']+'\n'},{**good(),'returncode':-11}]:
                args=['--candidate','not-executed','--expected-sha256','a'*64,'--expected-version','0.50.0','--manifest','MUST_NOT_BE_OPENED']
                with self.subTest(runner=name,record=record),self.assertRaises(AssertionError):self.invoke(m,args,record)
    def test_hash_gate_is_retained(self):
        for name,m in self.runners:
            with patch.object(sys,'argv',['runner','--candidate','not-executed','--expected-sha256','b'*64,'--expected-version','0.50.0']),patch.object(m,'sha',return_value='a'*64),patch.object(m,'execute') as execute,self.assertRaises(AssertionError):
                m.main()
            execute.assert_not_called()
    def test_explicit_versions_are_recorded_without_historical_constraint(self):
        for name,m in self.runners:
            for version in ['0.49.0','0.50.0','0.51.0']:
                with self.subTest(runner=name,version=version),tempfile.TemporaryDirectory() as d:
                    d=Path(d);manifest=d/'empty-contract-test.json';manifest.write_text('{"cases":[]}');result=d/'result.json'
                    args=['--candidate','not-executed','--expected-sha256','a'*64,'--expected-version',version,'--manifest',str(manifest),'--result',str(result)]
                    with self.assertRaises(SystemExit) as error:self.invoke(m,args,good(version))
                    self.assertEqual(error.exception.code,0)
                    identity=json.loads(result.read_text())['identity'];self.assertEqual(identity['expected_version'],version)
                    self.assertEqual(identity['sha256_before'],identity['sha256_after'])

if __name__=='__main__':unittest.main()
