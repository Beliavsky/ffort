#!/usr/bin/env python3
"""Focused runner self-tests: literal oracles and clean failure boundaries."""
import unittest
import tempfile
from pathlib import Path
import hashlib
import json
from run_tests import candidate_errors, compare, output_errors, provenance_errors


def result(code=0, out='', err=''):
    return dict(code=code, out=out, err=err)


class RunnerTests(unittest.TestCase):
    def test_original_body_crlf_is_exact(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = b'header\r\nbody\r\nfooter\r\n'
            wrapper = b'helper\nbody\r\ndriver\n'
            (root / 'source.f90').write_bytes(source)
            (root / 'wrapper.f90').write_bytes(wrapper)
            data = dict(source='source.f90', wrapper='wrapper.f90',
                        source_sha256=hashlib.sha256(source).hexdigest(),
                        wrapper_sha256=hashlib.sha256(wrapper).hexdigest(),
                        bodies=[dict(name='body', first_line=2, last_line=2,
                                     wrapper_start_byte=7, wrapper_end_byte=13,
                                     byte_count=6, sha256=hashlib.sha256(b'body\r\n').hexdigest())])
            (root / 'provenance.json').write_text(json.dumps(data))
            self.assertEqual(provenance_errors(root), [])
            # A normalized wrapper is not byte-for-byte original evidence.
            (root / 'wrapper.f90').write_bytes(wrapper.replace(b'\r\n', b'\n'))
            self.assertTrue(provenance_errors(root))

    def test_missing_provenance_fails_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            self.assertTrue(provenance_errors(Path(folder)))

    def test_numeric_formatting(self):
        self.assertTrue(compare('2.0000000 9.0D+0 T', '2 9.0 T'))

    def test_integer_precision(self):
        self.assertFalse(compare('9007199254740993', '9007199254740992'))

    def test_nonfinite(self):
        for value in ('NaN', 'Infinity', '-Infinity'):
            self.assertFalse(compare(value, '1.0'))

    def test_wide_finite_real(self):
        self.assertFalse(compare('9e999', '1e999'))
        self.assertTrue(compare('1.0000001e999', '1e999'))

    def test_diagnostic_filename_does_not_count(self):
        case = dict(category='reject', expected_stdout='', diagnostic='unsupported')
        bad = result(1, err='/fixtures/unsupported.f90:3:9: another failure')
        self.assertTrue(candidate_errors(case, bad, bad))

    def test_output_leaks(self):
        self.assertFalse(compare('debug 1', '1'))
        self.assertFalse(compare('1 2', '1'))

    def test_character_padding(self):
        case = dict(expected_stdout='xy', formatted_lines={'0': 'xy  '})
        self.assertEqual(output_errors(case, 'xy  \n'), [])
        self.assertIn('formatted CHARACTER line mismatch', output_errors(case, 'xy\n'))

    def test_clean_success(self):
        case = dict(category='success', expected_stdout='1')
        self.assertEqual(candidate_errors(case, result(), result(out='1')), [])

    def test_success_stderr(self):
        case = dict(category='success', expected_stdout='1')
        self.assertTrue(candidate_errors(case, result(), result(out='1', err='warning')))

    def test_rejection_not_crash(self):
        case = dict(category='reject', expected_stdout='', diagnostic='unsupported')
        self.assertEqual(candidate_errors(case, result(1, err='unsupported'), result(1, err='unsupported')), [])
        self.assertTrue(candidate_errors(case, result(1, err='unsupported'), result(-11, err='unsupported')))

    def test_runtime_not_check_rejection(self):
        case = dict(category='runtime', expected_stdout='')
        self.assertEqual(candidate_errors(case, result(), result(2, err='unallocated')), [])
        self.assertTrue(candidate_errors(case, result(1, err='unallocated'), result(1, err='unallocated')))

    def test_missing_diagnostic(self):
        case = dict(category='reject', expected_stdout='', diagnostic='unsupported')
        self.assertTrue(candidate_errors(case, result(1), result(1)))

    def test_check_stdout(self):
        case = dict(category='success', expected_stdout='1')
        self.assertIn('check stdout leak', candidate_errors(case, result(out='debug'), result(out='1')))

    def test_failure_output_leak(self):
        case = dict(category='runtime', expected_stdout='')
        self.assertIn('stdout mismatch/leak', candidate_errors(case, result(), result(2, out='123', err='failure')))


if __name__ == '__main__':
    unittest.main()
