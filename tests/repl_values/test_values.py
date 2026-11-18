#!/usr/bin/env python3
"""Targeted bare-value PARAMETER regression; no host compiler required."""
import argparse
import json
from pathlib import Path
import subprocess
import unittest

ap = argparse.ArgumentParser()
ap.add_argument('--candidate', required=True)
ap.add_argument('--report')
a = ap.parse_args()
candidate = str(Path(a.candidate).resolve())

class Values(unittest.TestCase):
    def run_repl(self, source):
        return subprocess.run([candidate, '--repl', '--nologo', '--prompt', ''],
                              input=source + '\n.quit!\n', text=True,
                              capture_output=True, timeout=20)
    def expect(self, source, expected):
        p = self.run_repl(source)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(p.stderr, '')
        self.assertEqual(p.stdout.split(), expected.split())
    def test_exact_parameter(self):
        self.expect('integer, parameter :: n = 5\nn', '5')
    def test_repeat_parameter(self):
        self.expect('integer, parameter :: n = 5\nn\nn\nn', '5 5 5')
    def test_mutable_scalar(self):
        self.expect('integer :: i\ni=3\ni\ni=i+1\ni\ni', '3 4 4')
    def test_array_element(self):
        self.expect('integer :: a(-2:2)\na=7\na(-1)=9\na(-1)\na(2)', '9 7')
    def test_parameter_dimension(self):
        self.expect('integer, parameter :: n=5\ninteger :: a(n)\na=6\nn\na(n)', '5 6')
    def test_growth_after_parameter_query(self):
        self.expect('integer, parameter :: n=5\nn\ninteger :: i\ni=n+2\ni\nn', '5 7 5')
    def test_pending_no_replay(self):
        self.expect('integer, parameter :: n=5\nprint *,"once"\nn\nn', 'once 5 5')
    def test_parameter_inspection(self):
        p = self.run_repl('integer, parameter :: n=5\nn\n.vars\n.info n')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertNotIn('<undefined>', p.stdout)
        self.assertGreaterEqual(p.stdout.count('5'), 3)
    def test_parameter_write_rejected(self):
        p = self.run_repl('integer, parameter :: n=5\nn\nn=8\nn')
        self.assertNotEqual(p.returncode, 0)
        self.assertEqual(p.stdout.split(), ['5'])
        self.assertTrue(p.stderr)

result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Values))
if a.report:
    Path(a.report).write_text(json.dumps({'status':'passed' if result.wasSuccessful() else 'failed',
        'tests':result.testsRun,'failures':len(result.failures),'errors':len(result.errors)},indent=2)+'\n')
raise SystemExit(0 if result.wasSuccessful() else 1)
