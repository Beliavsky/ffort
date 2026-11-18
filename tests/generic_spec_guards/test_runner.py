#!/usr/bin/env python3
import unittest
from run_tests import clean_check, clean_rejection


class TestGate(unittest.TestCase):
    def test_clean_check(self):
        self.assertTrue(clean_check(dict(status=0, stdout='', stderr='')))
        for key, value in [('status', 1), ('stdout', ' '), ('stderr', '\n')]:
            result = dict(status=0, stdout='', stderr='')
            result[key] = value
            self.assertFalse(clean_check(result))

    def test_clean_rejection(self):
        diagnostic = 'Unresolved generic specific binding'
        good = dict(status=1, stdout='', stderr='p.f90:3:1: '+diagnostic+'\n')
        self.assertTrue(clean_rejection(good, diagnostic))
        for key, value in [('status', 0), ('status', 2), ('status', -11),
                           ('stdout', 'leak'), ('stderr', ''),
                           ('stderr', diagnostic+'\nBacktrace'),
                           ('stderr', diagnostic+'\nFortran runtime error')]:
            result = dict(good)
            result[key] = value
            self.assertFalse(clean_rejection(result, diagnostic))


if __name__ == '__main__':
    unittest.main()
