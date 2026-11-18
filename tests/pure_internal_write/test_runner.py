import copy
from pathlib import Path
import unittest
from run_tests import candidate_matches, oracle_matches, expected_diagnostic, clean_host

class DiagnosticTests(unittest.TestCase):
    def setUp(self):
        self.source = Path('/tmp/cases/target.f90')
        self.case = dict(kind='reject', gnu='fail', diagnostic=dict(
            line=9, column=7, message='Internal WRITE requires a writable scalar CHARACTER variable'))
        self.good = dict(code=1, out='', err=expected_diagnostic(self.case, self.source))

    def accepts(self, check=None, run=None):
        return candidate_matches(self.case, self.good if check is None else check,
                                 self.good if run is None else run, self.source)

    def test_exact_both_phases(self):
        self.assertTrue(self.accepts())

    def test_no_diagnostic(self):
        bad = dict(self.good, err='')
        self.assertFalse(self.accepts(check=bad))
        self.assertFalse(self.accepts(run=bad))

    def test_named_diagnostic(self):
        for text in ['some error\n', self.good['err'].replace('WRITE', 'READ'),
                     self.good['err'].replace('CHARACTER', 'INTEGER')]:
            self.assertFalse(self.accepts(check=dict(self.good, err=text)))
            self.assertFalse(self.accepts(run=dict(self.good, err=text)))

    def test_exact_source(self):
        for source in ['/tmp/cases/other.f90', 'target.f90', '/tmp/other/target.f90']:
            self.assertFalse(self.accepts(run=dict(self.good, err=self.good['err'].replace(str(self.source), source))))

    def test_location_required(self):
        for changed in [':9:8:', ':8:7:', ':0:0:', ':', ':line9:column7:']:
            self.assertFalse(self.accepts(run=dict(self.good, err=self.good['err'].replace(':9:7:', changed))))

    def test_explicit_zero_location(self):
        case = copy.deepcopy(self.case)
        case['diagnostic'].update(line=0, column=0, message='FortFront rejected the source:\n  - WRITE error')
        result = dict(code=1, out='', err=expected_diagnostic(case, self.source))
        self.assertTrue(candidate_matches(case, result, result, self.source))
        result['err'] = result['err'].replace(':0:0:', ':1:1:')
        self.assertFalse(candidate_matches(case, result, result, self.source))

    def test_stdout_must_be_empty(self):
        for text in [' ', '\n', 'partial']:
            self.assertFalse(self.accepts(check=dict(self.good, out=text)))
            self.assertFalse(self.accepts(run=dict(self.good, out=text)))

    def test_status_is_exact(self):
        for code in [0, 2, -11, None]:
            self.assertFalse(self.accepts(check=dict(self.good, code=code)))
            self.assertFalse(self.accepts(run=dict(self.good, code=code)))

    def test_no_extra_stderr(self):
        for changed in [self.good['err']+'\n', 'warning\n'+self.good['err'], self.good['err'].rstrip()]:
            self.assertFalse(self.accepts(run=dict(self.good, err=changed)))

    def test_crash_markers_even_with_matching_expectation(self):
        for marker in ['Backtrace', 'TRACEBACK', 'Fortran runtime error', 'Internal compiler error',
                       'Segmentation fault', 'SIGSEGV', 'SIGABRT', 'Program received signal',
                       'Core dumped', 'AddressSanitizer', 'UndefinedBehaviorSanitizer',
                       'Stack trace', 'ICE']:
            case = copy.deepcopy(self.case)
            case['diagnostic']['message'] = marker
            result = dict(code=1, out='', err=expected_diagnostic(case, self.source))
            self.assertFalse(candidate_matches(case, result, result, self.source), marker)
            self.assertFalse(clean_host(dict(code=1, out=marker, err='error')), marker)

    def test_success_is_exact(self):
        case = dict(kind='pass', gnu='pass', expected='07\n')
        check = dict(code=0, out='', err='')
        run = dict(code=0, out='07\n', err='')
        self.assertTrue(candidate_matches(case, check, run, self.source))
        for text in ['7\n', '07', ' 07\n', '07\n\n']:
            self.assertFalse(candidate_matches(case, check, dict(run, out=text), self.source))
        self.assertFalse(candidate_matches(case, dict(check, out=' '), run, self.source))
        self.assertFalse(candidate_matches(case, check, dict(run, err=' '), self.source))

    def test_gnu_compile_only_boundary(self):
        case = dict(self.case, gnu='pass')
        compiled = dict(code=0, out='', err='')
        self.assertTrue(oracle_matches(case, compiled, None))
        self.assertFalse(oracle_matches(case, compiled, dict(code=0, out='', err='')))
        self.assertFalse(oracle_matches(case, dict(compiled, code=1, err='error'), None))

    def test_gnu_rejection_is_not_a_crash(self):
        compiled = dict(code=1, out='', err='Error: invalid source\n')
        self.assertTrue(oracle_matches(self.case, compiled, None))
        for changed in [dict(compiled, code=0), dict(compiled, code=-11), dict(compiled, err=''),
                        dict(compiled, err='Internal compiler error'), dict(compiled, out='Backtrace')]:
            self.assertFalse(oracle_matches(self.case, changed, None))

    def test_gnu_success_matches_fixed_expectation(self):
        case = dict(kind='pass', gnu='pass', expected='07\n')
        compiled = dict(code=0, out='', err='')
        self.assertTrue(oracle_matches(case, compiled, dict(code=0, out='07\n', err='')))
        self.assertFalse(oracle_matches(case, compiled, dict(code=0, out='7\n', err='')))
        self.assertFalse(oracle_matches(case, compiled, None))

if __name__ == '__main__':
    unittest.main()
