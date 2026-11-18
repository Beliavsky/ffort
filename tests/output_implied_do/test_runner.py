#!/usr/bin/env python3
"""Run comparator, status, empty-stderr and atomic-output adversarial checks."""
import unittest
import run_tests

class ComparatorTests(unittest.TestCase):
    def test_adversarial_harness(self):
        self.assertEqual(run_tests.self_test(),45)
    def test_isolated_generator_replay(self):
        import check_generator
        report = check_generator.check()
        self.assertEqual(report['errors'], [])
        self.assertEqual(report['summary']['fixtures'], 101)
        self.assertEqual(report['summary']['exact_files'], 103)
        self.assertTrue(report['summary']['originals_unchanged'])
    def test_upstream_bytes(self):
        run_tests.check_original_sources()
    def test_no_unsafe_gnu_execution(self):
        import json
        for case in json.loads((run_tests.ROOT/'manifest.json').read_text())['cases']:
            run_tests.validate_case(case)

if __name__ == '__main__':
    unittest.main()
