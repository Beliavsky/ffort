#!/usr/bin/env python3
"""Section-oracle and fixture integrity self-tests."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import run_corpus as runner


class RunnerTests(unittest.TestCase):
    def test_passes_budget_to_both_stages(self):
        case=dict(candidate_args=['--max-steps','25'])
        with patch.object(runner,'original_assess_candidate',return_value='sentinel') as assess:
            self.assertEqual('sentinel',runner.assess_candidate(case,['candidate'],7))
            assess.assert_called_once_with(case,['candidate','--max-steps','25'],7)

    def test_command_not_mutated(self):
        command=['candidate']
        with patch.object(runner,'original_assess_candidate'):
            runner.assess_candidate(dict(candidate_args=['--max-steps','25']),command,7)
        self.assertEqual(command,['candidate'])

    def test_checked_runtime_rejects_clean_exit(self):
        case=dict(baseline='checked_runtime',source='stub.f90',baseline_diagnostic='stride')
        result=dict(returncode=0,stdout='',stderr='stride',timeout=False)
        with patch.object(runner.base,'execute',return_value=result):
            self.assertFalse(runner.assess_baseline(case,'gfortran',2)['passed'])

    def test_checked_runtime_requires_diagnostic(self):
        case=dict(baseline='checked_runtime',source='stub.f90',baseline_diagnostic='stride')
        compiled=dict(returncode=0,stdout='',stderr='',timeout=False)
        failed=dict(returncode=2,stdout='',stderr='other error',timeout=False)
        with patch.object(runner.base,'execute',side_effect=[compiled,failed]):
            self.assertFalse(runner.assess_baseline(case,'gfortran',2)['passed'])

    def test_checked_runtime_accepts_diagnostic_failure(self):
        case=dict(baseline='checked_runtime',source='stub.f90',baseline_diagnostic='stride')
        compiled=dict(returncode=0,stdout='',stderr='',timeout=False)
        failed=dict(returncode=2,stdout='',stderr='Fortran runtime error: Zero stride',timeout=False)
        with patch.object(runner.base,'execute',side_effect=[compiled,failed]):
            self.assertTrue(runner.assess_baseline(case,'gfortran',2)['passed'])

    def test_runtime_keyword_in_filename_does_not_count(self):
        case=dict(baseline='checked_runtime',source='zero_stride.f90',baseline_diagnostic='stride')
        compiled=dict(returncode=0,stdout='',stderr='',timeout=False)
        failed=dict(returncode=2,stdout='',stderr='At line 1 of zero_stride.f90\nFortran runtime error: other error',timeout=False)
        with patch.object(runner.base,'execute',side_effect=[compiled,failed]):
            self.assertFalse(runner.assess_baseline(case,'gfortran',2)['passed'])

    def test_candidate_keyword_in_filename_does_not_count(self):
        case=dict(diagnostic='stride')
        result=dict(passed=True,errors=[],run=dict(stderr='/tmp/zero_stride.f90:1:2: other error'))
        with patch.object(runner,'original_assess_candidate',return_value=result):
            self.assertFalse(runner.assess_candidate(case,['candidate'],2)['passed'])

    def test_fixture_integrity(self):
        cases=json.loads((runner.ROOT/'manifest.json').read_text())['cases']
        self.assertEqual(len(cases),len({c['name'] for c in cases}))
        self.assertEqual(len(cases),len({c['source'] for c in cases}))
        for case in cases:
            with self.subTest(case=case['name']):
                text=(runner.ROOT/case['source']).read_text()
                self.assertLessEqual(len(text.encode()),65536)
                self.assertTrue(all(len(line)<=132 for line in text.splitlines()))
                self.assertIn(case['baseline'],('run','compile','reject','skip','bounds_runtime','checked_runtime'))
                self.assertIn(case['category'],('success','invalid','unsupported','runtime'))
                if case['category']=='runtime':
                    self.assertIn('expected_stdout',case)
                    self.assertIn('diagnostic',case)

    def test_fixture_generator_reproducibility(self):
        with tempfile.TemporaryDirectory(prefix='section-fixture-test-') as folder:
            target=Path(folder)
            shutil.copyfile(runner.ROOT/'make_corpus.py',target/'make_corpus.py')
            subprocess.run([sys.executable,str(target/'make_corpus.py')],check=True,
                           capture_output=True,text=True)
            self.assertEqual((runner.ROOT/'manifest.json').read_bytes(),
                             (target/'manifest.json').read_bytes())
            cases=json.loads((target/'manifest.json').read_text())['cases']
            for case in cases:
                with self.subTest(case=case['name']):
                    self.assertEqual((runner.ROOT/case['source']).read_bytes(),
                                     (target/case['source']).read_bytes())


if __name__=='__main__': unittest.main()
