#!/usr/bin/env python3
"""Tests for the independent evaluator, not for the interpreter implementation."""
import sys
import tempfile
from pathlib import Path
import unittest
import run_corpus as runner

class OutputComparisonTests(unittest.TestCase):
    def test_whitespace_ignored(self): self.assertTrue(runner.compare_output(' 1\n2\tT\n', '1 2 T')[0])
    def test_integral_real_format(self): self.assertTrue(runner.compare_output('1.67772160E+07', '16777216')[0])
    def test_exact_integer_comparison(self): self.assertFalse(runner.compare_output('16777217', '16777216')[0])
    def test_integral_real_stays_exact(self): self.assertFalse(runner.compare_output('1.67772170E+07', '16777216')[0])
    def test_real_roundoff(self): self.assertTrue(runner.compare_output('0.100000001', '0.1')[0])
    def test_real_error(self): self.assertFalse(runner.compare_output('0.1001', '0.1')[0])
    def test_missing_output(self): self.assertFalse(runner.compare_output('1', '1 2')[0])
    def test_added_output(self): self.assertFalse(runner.compare_output('1 2', '1')[0])
    def test_string_exact(self): self.assertFalse(runner.compare_output('ABC', 'abc')[0])
    def test_logical_spelling(self): self.assertTrue(runner.compare_output('.true. F', 'T .false.')[0])

class StageContractTests(unittest.TestCase):
    def evaluate(self,script,category='success',expected='1',output_lines=None):
        case=dict(source='cases/integer_arithmetic.f90',category=category,expected_stdout=expected)
        if output_lines is not None: case['expected_stdout_lines']=output_lines
        with tempfile.TemporaryDirectory() as tmp:
            executable=Path(tmp)/'fake.py'
            executable.write_text('import sys\n'+script)
            return runner.assess_candidate(case,[sys.executable,str(executable)],2)
    def test_accepts_success(self):
        self.assertTrue(self.evaluate("if '--check' not in sys.argv: print('1')\n")['passed'])
    def test_requires_empty_print_line(self):
        self.assertFalse(self.evaluate('',expected='',output_lines=1)['passed'])
    def test_detects_silent_acceptance(self):
        self.assertFalse(self.evaluate('',category='syntax')['passed'])
    def test_detects_wrong_runtime_stage(self):
        self.assertFalse(self.evaluate("print('error',file=sys.stderr)\nraise SystemExit(1)\n",category='runtime')['passed'])
    def test_accepts_runtime_stage(self):
        self.assertTrue(self.evaluate("if '--check' not in sys.argv:\n print('error',file=sys.stderr)\n raise SystemExit(2)\n",category='runtime')['passed'])
    def test_detects_fail_closed_violation(self):
        result=self.evaluate("print('SHOULD_NOT_EXECUTE')\nprint('error',file=sys.stderr)\nraise SystemExit(1)\n",category='unsupported')
        self.assertFalse(result['passed'])
        self.assertTrue(any('fail-closed' in e for e in result['errors']))
    def test_requires_diagnostic(self):
        self.assertFalse(self.evaluate('raise SystemExit(1)\n',category='semantic')['passed'])
    def test_detects_timeout(self):
        result=runner.execute([sys.executable,'-c','import time; time.sleep(1)'],timeout=0.01)
        self.assertTrue(result['timeout'])

if __name__=='__main__': unittest.main()
