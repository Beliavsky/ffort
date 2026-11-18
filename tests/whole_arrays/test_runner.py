#!/usr/bin/env python3
"""Self-tests for whole-array fixture shape and per-case safety-budget handling."""
import json
import unittest
from unittest.mock import patch
import run_corpus as runner


class RunnerTests(unittest.TestCase):
    def test_passes_case_budget_to_both_execution_stages(self):
        case = dict(candidate_args=['--max-steps', '25'])
        with patch.object(runner, 'original_assess_candidate', return_value='sentinel') as assess:
            self.assertEqual('sentinel', runner.assess_candidate(case, ['candidate'], 7))
            assess.assert_called_once_with(case, ['candidate', '--max-steps', '25'], 7)

    def test_does_not_mutate_command(self):
        command = ['candidate']
        with patch.object(runner, 'original_assess_candidate'):
            runner.assess_candidate(dict(candidate_args=['--max-steps', '25']), command, 7)
        self.assertEqual(command, ['candidate'])

    def test_all_fixtures_unique_existing_and_source_limited(self):
        cases = json.loads((runner.ROOT/'manifest.json').read_text())['cases']
        self.assertEqual(len(cases), len({case['name'] for case in cases}))
        self.assertEqual(len(cases), len({case['source'] for case in cases}))
        for case in cases:
            with self.subTest(case=case['name']):
                source = (runner.ROOT/case['source']).read_text()
                self.assertLessEqual(len(source.encode()), 65536)
                self.assertTrue(all(len(line) <= 132 for line in source.splitlines()))
                self.assertIn(case['baseline'], ('run', 'compile', 'reject', 'skip', 'bounds_runtime'))
                self.assertIn(case['category'], ('success', 'invalid', 'unsupported', 'runtime'))
                if case['category'] == 'runtime':
                    self.assertIn('expected_stdout', case)
                    self.assertIn('diagnostic', case)


if __name__ == '__main__':
    unittest.main()
