"""Synthetic only: no FPM, compiler, linker or candidate process is launched."""
from pathlib import Path
import hashlib
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
(ROOT/'synthetic-artifacts').mkdir(exist_ok=True)
spec = importlib.util.spec_from_file_location('hardened_shared', ROOT/'scripts/verify_native_shared.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)
FLAGS = ['-g', '-fPIC', '-fcheck=bounds', '-fcheck=array-temps', '-fbacktrace']


def fixture(root):
    out = root/'build/verification_shared_native'
    out.mkdir(parents=True)
    (root/'test').mkdir()
    sources, commands = {}, []
    for name in sorted(v.STATIC_COMPARISONS):
        source = 'test/'+name+'.f90'
        (root/source).write_text('! synthetic source only\n')
        sources[name] = {'unit-scope':'FPM_SCOPE_TEST', 'unit-type':'FPM_UNIT_PROGRAM',
                         'exe-name':name, 'file-name':source}
        args = ['gfortran','-c',source,*FLAGS,'-fimplicit-none',
                '-Werror=implicit-interface','-o','build/objects/'+name+'.o']
        commands.append({'file':source,'arguments':args})
    model = {'target-os':'Linux','compiler':{'fc':'gfortran'},
             'fortran-flags':' '.join(FLAGS),'link-flags':' ', 'link-libraries':[],
             'packages':{'fortfront-interpreter':{'sources':sources}}}
    (out/'fpm-model.json').write_text(json.dumps(model))
    (root/'build/compile_commands.json').write_text(json.dumps(commands))
    archive = root/'build/profile/fortfront-interpreter/libfortfront-interpreter.a'
    archive.parent.mkdir(parents=True)
    archive.write_bytes(b'synthetic unchanged archive')
    (out/'results.json').write_text('{"status":"passed"}')  # stale earlier run
    return out, archive, model, commands


class FlagsTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix='flags-', dir=ROOT/'synthetic-artifacts'))
        self.out, self.archive, self.model, self.commands = fixture(self.root)

    def test_known_disabling_overrides_rejected_in_model_and_commands(self):
        bad = ['-g0','-ggdb0','-fno-PIC','-fno-pic','-fno-PIE','-fpie','-fPIE',
               '-fno-backtrace','-fno-bounds-check','-Wno-implicit-interface','-fno-check=bounds','-fcheck=no-bounds',
               '-fcheck=all,no-array-temps','-fno-implicit-none',
               '-Wno-error','-Wno-error=implicit-interface','-w','-fcoarray=lib','@hidden.flags']
        for flag in bad:
            with self.subTest(flag=flag):
                self.commands[0]['arguments'].append(flag)
                with self.assertRaises(ValueError): v.plan(self.model,self.commands)
                self.commands[0]['arguments'].pop()
                self.model['fortran-flags'] += ' '+flag
                with self.assertRaises(ValueError): v.plan(self.model,self.commands)
                self.model['fortran-flags'] = ' '.join(FLAGS)

    def test_extra_link_inputs_rejected(self):
        for key,value in [('link-flags','-Wl,--as-needed'),('link-libraries',['foo'])]:
            with self.subTest(key=key):
                m = dict(self.model, **{key:value})
                with self.assertRaises(ValueError): v.plan(m,self.commands)

    def test_original_argv_unchanged(self):
        before = json.dumps(self.commands)
        flags, plans = v.plan(self.model,self.commands)
        self.assertEqual(json.dumps(self.commands),before)
        for row,c in zip(plans,self.commands):
            self.assertIs(row['compile'],c['arguments'])


class ReceiptTests(unittest.TestCase):
    def exercise(self, stage=None, failure=None, archive_failure=None):
        root = Path(tempfile.mkdtemp(prefix='receipt-', dir=ROOT/'synthetic-artifacts'))
        out,archive,model,commands = fixture(root)
        observations = []
        calls = []
        archive_reads = 0
        original_digest = v.digest
        def read_status():
            return json.loads((out/'results.json').read_text())['status']
        def digest(path):
            nonlocal archive_reads
            observations.append(read_status())
            if Path(path) == archive:
                archive_reads += 1
                if archive_reads == 2:
                    if archive_failure == 'changed': return 'changed'
                    if archive_failure == 'unreadable': raise OSError('synthetic hash read failure')
            return original_digest(path)
        def fake_run(command, **kwargs):
            command = list(map(str,command))
            if command[0] == 'fpm': current = 'discovery'
            elif '-shared' in command: current = 'shared-link'
            elif '-c' in command: current = 'compile'
            elif '-o' in command: current = 'static-link' if '/static-comparison/' in command[-1] else 'link'
            else: current = 'static-run' if '/static-comparison/' in command[0] else 'run'
            calls.append((current,command))
            observations.append(read_status())
            if current == stage:
                if failure == 'timeout': raise subprocess.TimeoutExpired(command,240,output=b'partial')
                if failure == 'launch': raise OSError('synthetic launch failure')
                code = 9
            else: code = 0
            if '-o' in command and code == 0:
                target = Path(command[command.index('-o')+1])
                if not target.is_absolute(): target = root/target
                target.parent.mkdir(parents=True,exist_ok=True)
                target.write_bytes(b'synthetic object or binary; never executed')
            text = kwargs.get('text',False)
            output = '' if text else b'exact synthetic output\n'
            if current == 'static-run' and failure == 'mismatch': output = b'different output\n'
            return subprocess.CompletedProcess(command,code,output,'' if text else b'')
        with patch.object(v,'ROOT',root), patch.object(v.sys,'argv',['verify_native_shared.py']), \
             patch.object(v.sys,'platform','linux'), patch.object(v.subprocess,'run',side_effect=fake_run), \
             patch.object(v,'digest',side_effect=digest), patch('builtins.print'):
            if stage or archive_failure or failure == 'mismatch':
                with self.assertRaises((RuntimeError,OSError,subprocess.TimeoutExpired)): v.main()
            else: v.main()
        result = json.loads((out/'results.json').read_text())
        self.assertNotIn('passed',observations, 'No intermediate receipt may claim success')
        self.assertEqual(result['status'],'failed' if stage or archive_failure or failure == 'mismatch' else 'passed')
        return result,calls,archive_reads

    def test_success_only_after_final_hash(self):
        result,calls,reads = self.exercise()
        self.assertEqual(reads,2)
        self.assertTrue(result['archive_rechecked'])
        self.assertEqual(result['executed'],7)
        self.assertEqual(sum(s=='static-run' for s,c in calls),7)
        self.assertTrue(all(r['static_shared_behavior_equal'] for r in result['test_records']))
        self.assertFalse(result['same_binary_claimed'])

    def test_every_subprocess_stage_failure_invalidates_stale_pass(self):
        for stage in ['discovery','shared-link','compile','link','run','static-link','static-run']:
            for failure in ['nonzero','timeout','launch']:
                with self.subTest(stage=stage,failure=failure):
                    result,_,_ = self.exercise(stage,failure)
                    self.assertFalse(result['archive_rechecked'])
                    self.assertIn('error_type',result)

    def test_final_archive_changed_or_unreadable_never_passes(self):
        for failure in ['changed','unreadable']:
            with self.subTest(failure=failure):
                result,_,reads = self.exercise(archive_failure=failure)
                self.assertEqual(reads,2)
                self.assertEqual(result['executed'],7)
                self.assertTrue(all(r['passed'] for r in result['test_records']))
                self.assertFalse(result['archive_rechecked'])

    def test_exact_output_mismatch_fails(self):
        self.exercise(failure='mismatch')


if __name__ == '__main__':
    (ROOT/'synthetic-artifacts').mkdir(exist_ok=True)
    unittest.main(verbosity=2)
