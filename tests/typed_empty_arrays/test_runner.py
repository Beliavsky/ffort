#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch
import run_tests as runner


def result(code=0, out='', err=''):
    return dict(code=code, out=out, err=err)


class Comparison(unittest.TestCase):
    def test_exact_numeric_values(self):
        self.assertTrue(runner.equivalent('9007199254740993 -0.0D0 1.5D0', '9007199254740993 -0.0 1.500'))
        for x, y in [('9007199254740993', '9007199254740992'), ('1.000000000001', '1.0'),
                     ('-0.0', '0.0'), ('wordE', 'wordD'), ('NaN', 'nan'), ('NaN', 'NaN'),
                     ('inf', 'inf'), ('1 text', '1 TEXT'), ('1 2', '1')]:
            with self.subTest(x=x, y=y):
                self.assertFalse(runner.equivalent(x, y))


class EngineAssessment(unittest.TestCase):
    success = dict(category='run', gnu='run', output='PASS')
    reject = dict(category='reject', gnu='reject', output='')

    def test_clean_success_and_rejection(self):
        self.assertFalse(runner.assess(self.success, result(), result(out='PASS'), result(), result(out='PASS')))
        self.assertFalse(runner.assess(self.reject, result(1, err='source invalid'), result(1, err='source invalid'), result(1, err='Error: invalid source'), None))

    def test_all_engines_reject_crashes_even_with_expected_exit_status(self):
        markers = ['internal compiler error: boom', 'Please submit a full bug report', 'Backtrace:',
                   'Fortran runtime error:', 'Segmentation fault', 'SIGSEGV', 'SIGABRT',
                   'SIGBUS', 'SIGILL', 'SIGFPE', 'SIGKILL', 'SIGTERM', 'terminated by signal',
                   'fatal signal', 'TIMEOUT', 'timed out', 'OSError: unavailable']
        for stage in range(4):
            for marker in markers:
                for stream in ['out', 'err']:
                    with self.subTest(stage=stage, marker=marker, stream=stream):
                        stages = [result(1, err='invalid'), result(1, err='invalid'), result(1, err='invalid'), result()]
                        stages[stage][stream] = marker
                        self.assertTrue(any('crash' in x for x in runner.assess(self.reject, *stages)))

    def test_all_engines_reject_signal_status_and_missing_status(self):
        for stage in range(4):
            for code in [-11, -6, -9, None]:
                with self.subTest(stage=stage, code=code):
                    stages = [result(), result(out='PASS'), result(), result(out='PASS')]
                    stages[stage]['code'] = code
                    self.assertTrue(runner.assess(self.success, *stages))

    def test_gnu_rejection_requires_exact_exit_one(self):
        for code in [-11, 0, 2, 127, 134, 139, None]:
            with self.subTest(code=code):
                self.assertTrue(runner.assess(self.reject, result(1, err='invalid'), result(1, err='invalid'), result(code, err='invalid'), None))

    def test_check_path_cannot_hide_crash_behind_valid_execution(self):
        self.assertTrue(runner.assess(self.reject, result(1, err='Backtrace:'), result(1, err='invalid'), result(1, err='invalid'), None))

    def test_compiler_must_succeed_before_oracle_is_accepted(self):
        self.assertTrue(runner.assess(self.success, result(), result(out='PASS'), result(1, err='invalid'), result(out='PASS')))

    def test_missing_oracle_and_output_leaks_fail(self):
        self.assertTrue(runner.assess(self.success, result(), result(out='PASS'), result(), None))
        self.assertTrue(runner.assess(self.reject, result(1, out='leak', err='invalid'), result(1, err='invalid'), result(1, err='invalid'), None))

    def test_timeout_and_oserror_are_recorded(self):
        with patch.object(runner.subprocess, 'run', side_effect=subprocess.TimeoutExpired('fake', 60, output=b'partial', stderr=b'stuck')):
            actual = runner.run(['fake'])
        self.assertEqual(actual, result(None, out='partial', err='TIMEOUT: stuck'))
        self.assertTrue(runner.crashed(actual))
        with patch.object(runner.subprocess, 'run', side_effect=OSError('not found')):
            self.assertTrue(runner.crashed(runner.run(['fake'])))

    def test_case_directories_isolate_module_files(self):
        case = json.loads((runner.ROOT / 'manifest.json').read_text())['cases'][0]
        directories = []
        def fake_run(args, cwd=None):
            cwd = Path(cwd)
            if args[0] == 'fake-gfortran':
                self.assertFalse((cwd / 'stale.mod').exists())
                (cwd / 'stale.mod').write_text('module from this compilation only')
                directories.append(cwd)
                return result()
            return result() if '--check' in args else result(out='PASS')
        with patch.object(runner, 'run', side_effect=fake_run):
            for _ in range(2):
                self.assertTrue(runner.evaluate_case(case, 'fake-candidate', 'fake-gfortran')['passed'])
        self.assertEqual(len(set(directories)), 2)
        self.assertTrue(all(not p.exists() for p in directories))

    def test_failed_compilation_does_not_run_stale_oracle(self):
        case = json.loads((runner.ROOT / 'manifest.json').read_text())['cases'][0]
        calls = []
        def fake_run(args, cwd=None):
            calls.append(args)
            if args[0] == 'fake-gfortran':
                return result(1, err='internal compiler error')
            return result() if '--check' in args else result(out='PASS')
        with patch.object(runner, 'run', side_effect=fake_run):
            self.assertFalse(runner.evaluate_case(case, 'fake-candidate', 'fake-gfortran')['passed'])
        self.assertEqual(len(calls), 3)


if __name__ == '__main__':
    unittest.main()
