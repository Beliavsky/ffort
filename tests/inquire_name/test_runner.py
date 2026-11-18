#!/usr/bin/env python3
"""Pure synthetic validation controls. Does not invoke compiler or candidate."""
import argparse
import base64
import os
import subprocess
import tempfile
from unittest import mock
import run_tests
import copy
import hashlib
import json
from pathlib import Path
import unittest
from validate_results import validate, input_inventory, stage_errors

ROOT = Path(__file__).resolve().parent
MANIFEST = json.loads((ROOT / 'manifest.json').read_text())
SHA = '0' * 64
GNU_SHA = 'a' * 64
EXE, GNU, CWD = '/synthetic/fortfront', '/synthetic/gfortran', '/synthetic/work'

def stage(argv, status=0, stdout='', stderr=''):
    result=dict(argv=argv, cwd=CWD, status=status, stdout=stdout, stderr=stderr,
                timeout=False, valid_utf8=True, spawn_error=None)
    raw_fields(result)
    return result

def raw_fields(result):
    for key in ('stdout','stderr'):
        if type(result.get(key)) is str:
            raw=result[key].encode('utf-8',errors='surrogatepass')
            result[key+'_base64']=base64.b64encode(raw).decode('ascii')
            result[key+'_sha256']=hashlib.sha256(raw).hexdigest()

def control():
    result = dict(status='synthetic_control_not_execution', candidate_sha256_before=SHA,
                  candidate_sha256_after=SHA, manifest_sha256=hashlib.sha256((ROOT/'manifest.json').read_bytes()).hexdigest(),
                  version_before=stage([EXE, '--version'], stdout=MANIFEST['version_stdout']),
                  version_after=stage([EXE, '--version'], stdout=MANIFEST['version_stdout']),
                  gnu_version=stage([GNU, '--version'], stdout=MANIFEST['gnu_version_stdout']), records=[])
    result['execution_cwd']=CWD
    result['inputs_before']=input_inventory(ROOT,MANIFEST)
    result['inputs_after']=input_inventory(ROOT,MANIFEST)
    result['gnu_sha256_before']='a'*64
    result['gnu_sha256_after']='a'*64
    result['input_bytes_sha256_before']=hashlib.sha256(MANIFEST['input_data'].encode()).hexdigest()
    result['input_bytes_sha256_after']=result['input_bytes_sha256_before']
    for key in ('version_before','version_after','gnu_version'):
        result[key]['cwd']=str(ROOT)
    result['runner_sha256'] = hashlib.sha256((ROOT/'run_tests.py').read_bytes()).hexdigest()
    result['validator_sha256'] = hashlib.sha256((ROOT/'validate_results.py').read_bytes()).hexdigest()
    for case in MANIFEST['cases']:
        source = ROOT / case['source']
        row = {k: case[k] for k in ('name', 'source', 'sha256', 'gnu_mode')}
        for phase in ('check', 'run'):
            expected = dict(case[phase + '_contract'])
            expected['stderr'] = expected['stderr'].replace('{source}', str(source))
            row[phase] = stage([EXE] + (['--check'] if phase == 'check' else []) +
                               ['--input', '17=' + MANIFEST['registered_name'], str(source)], **expected)
        row['gnu_compile'] = stage([GNU, '-std=f2018', '-pedantic-errors', '-O0', '-fcheck=all',
                                    '-ffree-line-length-none', CWD + '/oracle.f90', '-o', CWD + '/oracle'],
                                   status=1 if case['gnu_mode'] == 'reject' else 0,
                                   stderr=case['gnu_reject_stderr'].replace('{oracle}',CWD+'/oracle.f90') if case['gnu_mode'] == 'reject' else '')
        row['gnu_run'] = stage([CWD+'/oracle'], stdout=case['expected_stdout']) if case['gnu_mode']=='execute' else None
        raw = source.read_bytes().replace(b'! GNU_REGISTER_INPUT',
            ("open(unit=iu,file='"+MANIFEST['registered_name']+"',status='old',action='read')").encode())
        row['oracle_source_latin1'] = raw.decode('latin1')
        row['oracle_sha256'] = hashlib.sha256(raw).hexdigest()
        result['records'].append(row)
    first = str(ROOT/MANIFEST['cases'][0]['source'])
    result['missing_input_check'] = stage([EXE,'--check','--input','17=missing-input-must-not-open.dat',first])
    result['missing_input_run'] = stage([EXE,'--input','17=missing-input-must-not-open.dat',first],status=1,
        stderr=first+':0:0: Cannot open explicit input file: missing-input-must-not-open.dat\n')
    return result

def paths(result):
    value=[(k,) for k in ('version_before','version_after','gnu_version','missing_input_check','missing_input_run')]
    for i,row in enumerate(result['records']):
        value += [('records',i,k) for k in ('check','run','gnu_compile')]
        if row['gnu_run'] is not None:value.append(('records',i,'gnu_run'))
    return value

def locate(result, path):
    for key in path:result=result[key]
    return result

class ValidationControls(unittest.TestCase):
    poison_controls = 0
    genuine_controls = 0
    def setUp(self):
        self.good=control()
    def reject(self, result, sync=True):
        if sync:
            for path in paths(result):
                value=locate(result,path)
                if type(value) is dict:
                    raw_fields(value)
        type(self).poison_controls += 1
        self.assertTrue(validate(result,MANIFEST,ROOT,SHA,GNU_SHA))
    def test_genuine_control(self):
        self.assertEqual(validate(self.good,MANIFEST,ROOT,SHA,GNU_SHA),[])
        type(self).genuine_controls += 1
    def test_each_stage_poison(self):
        poisons=[('status',False),('status',True),('status',0.0),('status',-1),('status',None),
                 ('stdout',None),('stdout',0),('stderr',None),('stderr',False),
                 ('timeout',True),('timeout','false'),('timeout',0),
                 ('valid_utf8',False),('valid_utf8','true'),('valid_utf8',1),
                 ('stdout','\ufffd'),('stderr','\ud800'),('stderr','core dumped'),
                 ('stderr','Backtrace:'),('stderr','SIGSEGV'),('stdout','runtime error:'),
                 ('spawn_error','failed'),('stderr','internal compiler error: synthetic poison\n'),
                 ('stderr','please submit a full bug report'),('cwd','/unrelated/place'),
                 ('stderr','Traceback (most recent call last):\nRuntimeError: compiler wrapper failed\n'),
                 ('stderr','Program received signal SIGBUS')]
        for path in paths(self.good):
            for key,value in poisons:
                with self.subTest(path=path,key=key,value=repr(value)):
                    bad=copy.deepcopy(self.good);locate(bad,path)[key]=value;self.reject(bad)
            for key in ('status','stdout','stderr','argv','cwd'):
                with self.subTest(path=path,missing=key):
                    bad=copy.deepcopy(self.good);locate(bad,path).pop(key);self.reject(bad)
            bad=copy.deepcopy(self.good);owner=locate(bad,path[:-1]);owner[path[-1]]=None;self.reject(bad)
            bad=copy.deepcopy(self.good);locate(bad,path)['argv']=['/wrong','--version'];self.reject(bad)
    def test_optional_schema_fields(self):
        for path in paths(self.good):
            good=copy.deepcopy(self.good);s=locate(good,path);s.pop('timeout');s.pop('valid_utf8')
            self.assertEqual(validate(good,MANIFEST,ROOT,SHA,GNU_SHA),[])
            type(self).genuine_controls += 1
    def test_gnu_reject_diagnostic_and_no_execution(self):
        for i,row in enumerate(self.good['records']):
            if row['gnu_mode']=='reject':
                for value in ('',' \n\t','Error: arbitrary wrapper failure\n',CWD+'/oracle.f90:1:1:\nError: wrong source message\n','unrelated nonempty failure\n'):
                    bad=copy.deepcopy(self.good);bad['records'][i]['gnu_compile']['stderr']=value;self.reject(bad)
            if row['gnu_mode']!='execute':
                bad=copy.deepcopy(self.good);bad['records'][i]['gnu_run']={};self.reject(bad)
    def test_exact_phase_and_diagnostics(self):
        for i,row in enumerate(self.good['records']):
            for phase in ('check','run'):
                for key in ('stdout','stderr'):
                    bad=copy.deepcopy(self.good);bad['records'][i][phase][key]+='changed';self.reject(bad)
                bad=copy.deepcopy(self.good);bad['records'][i][phase]['status']=99;self.reject(bad)
            bad=copy.deepcopy(self.good);bad['records'][i]['oracle_sha256']='1'*64;self.reject(bad)
            bad=copy.deepcopy(self.good);bad['records'][i]['source']='cases/wrong.f90';self.reject(bad)
        for key in ('candidate_sha256_before','candidate_sha256_after','manifest_sha256','runner_sha256','validator_sha256'):
            bad=copy.deepcopy(self.good);bad[key]='1'*64;self.reject(bad)
        bad=copy.deepcopy(self.good);bad['records']=bad['records'][:-1];self.reject(bad)
        bad=copy.deepcopy(self.good);bad['records'][1]=bad['records'][0];self.reject(bad)
        bad=copy.deepcopy(self.good);bad['records'].reverse();self.reject(bad)
    def test_provenance_and_raw_bytes(self):
        for key in ('inputs_before','inputs_after'):
            bad=copy.deepcopy(self.good);bad[key]={};self.reject(bad)
        for key in ('gnu_sha256_before','gnu_sha256_after','input_bytes_sha256_before','input_bytes_sha256_after'):
            for value in (None,False,'bad','b'*64):
                bad=copy.deepcopy(self.good);bad[key]=value;self.reject(bad)
        bad=copy.deepcopy(self.good);bad['gnu_sha256_before']='f'*64;bad['gnu_sha256_after']='f'*64;self.reject(bad)
        self.assertTrue(validate(self.good,MANIFEST,ROOT,SHA,'f'*64));type(self).poison_controls+=1
        bad=copy.deepcopy(self.good);bad['execution_cwd']='/wrong/common';self.reject(bad)
        for path in paths(self.good):
            for key,value in (('stdout_base64','%%%'),('stderr_base64','YQ=='),('stdout_sha256','0'*64),('stderr_sha256',None)):
                bad=copy.deepcopy(self.good);locate(bad,path)[key]=value;self.reject(bad,sync=False)
    def test_exclusive_output(self):
        with tempfile.TemporaryDirectory(prefix='inquire-output-control-') as td:
            root=Path(td);original=root/'existing.json';original.write_bytes(b'keep')
            with self.assertRaises(OSError):run_tests.reserve_output(original)
            self.assertEqual(original.read_bytes(),b'keep')
            target=root/'target';target.mkdir();link=root/'linked';link.symlink_to(target,target_is_directory=True)
            with self.assertRaises(OSError):run_tests.reserve_output(link/'out.json')
            dangling=root/'dangling.json';dangling.symlink_to(root/'absent.json')
            with self.assertRaises(OSError):run_tests.reserve_output(dangling)
            self.assertFalse((root/'absent.json').exists())
            live=root/'live.json';live.symlink_to(original)
            with self.assertRaises(OSError):run_tests.reserve_output(live)
            self.assertEqual(original.read_bytes(),b'keep')
            path,stream=run_tests.reserve_output(root/'new.json');stream.write('new');stream.close()
            self.assertEqual(path.read_text(),'new')
        type(self).genuine_controls+=7
    def test_spawn_timeout_raw_capture(self):
        with mock.patch.object(run_tests.subprocess,'run',side_effect=OSError('synthetic spawn denial')):
            value=run_tests.capture(['/not/executed'],ROOT)
        self.assertIsNone(value['status']);self.assertIn('OSError',value['spawn_error'])
        self.assertEqual(value['stdout_base64'],'');self.assertTrue(stage_errors(value))
        with mock.patch.object(run_tests.subprocess,'run',side_effect=subprocess.TimeoutExpired('synthetic',1,output=b'\xff',stderr=b'partial')):
            value=run_tests.capture(['/not/executed'],ROOT)
        self.assertTrue(value['timeout']);self.assertFalse(value['valid_utf8'])
        self.assertEqual(value['stdout_base64'],'/w==');self.assertEqual(value['stderr_base64'],'cGFydGlhbA==')
        self.assertTrue(stage_errors(value))
        type(self).genuine_controls+=9
    def test_first_failure_positive_not_reclassified(self):
        for name in ('dummy_target','original_inquire_statement'):
            i=next(i for i,c in enumerate(MANIFEST['cases'])if c['name']==name)
            bad=copy.deepcopy(self.good)
            for phase in ('check','run'):
                bad['records'][i][phase]['status']=1
                bad['records'][i][phase]['stdout']=''
                bad['records'][i][phase]['stderr']=str(ROOT/MANIFEST['cases'][i]['source'])+':6:0: FortFront adapter: missing statement\n'
            self.reject(bad)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--results',type=Path);args=parser.parse_args()
    result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(ValidationControls))
    receipt=dict(status='passed' if result.wasSuccessful()else'failed',mode='pure synthetic controls, no candidate/compiler',
                 test_methods=result.testsRun,poison_controls=ValidationControls.poison_controls,
                 genuine_controls=ValidationControls.genuine_controls,optimized=not __debug__)
    if args.results:
        if args.results.exists():raise SystemExit('Refusing to overwrite harness evidence')
        args.results.write_text(json.dumps(receipt,indent=2)+'\n')
    raise SystemExit(0 if result.wasSuccessful()else 1)
