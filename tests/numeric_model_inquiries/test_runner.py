#!/usr/bin/env python3
"""Checks the inquiry suite's strict comparison and immutable input provenance."""
import hashlib, importlib.util, json, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('numeric_model_runner',ROOT/'run_tests.py')
runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)
class ComparisonTests(unittest.TestCase):
    def test_exponent_spelling(self):
        self.assertTrue(runner.equal('0.22250738585072014E-307','2.2250738585072014E-308'))
    def test_tiny_is_not_zero(self):
        self.assertFalse(runner.equal('0.0','2.2250738585072014E-308'))
    def test_wide_integer_exact(self):
        self.assertFalse(runner.equal('9223372036854775806','9223372036854775807'))
    def test_precision_loss(self):
        self.assertFalse(runner.equal('2.22044605E-16','2.2204460492503131E-16'))
    def test_scalar_cardinality(self):
        self.assertFalse(runner.equal('2 2','2'))
    def test_originals_and_license(self):
        data=json.loads((ROOT/'original-provenance.json').read_text())
        for item in data['files']:
            self.assertEqual(hashlib.sha256((ROOT/item['file']).read_bytes()).hexdigest(),item['sha256'])
        self.assertEqual(hashlib.sha256((ROOT/data['license']).read_bytes()).hexdigest(),data['license_sha256'])
if __name__=='__main__': unittest.main()
