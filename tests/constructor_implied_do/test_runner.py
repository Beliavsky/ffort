#!/usr/bin/env python3
import contextlib,io,json,sys,unittest
from pathlib import Path
from unittest.mock import patch
import run_tests
class HarnessTests(unittest.TestCase):
    def test_strict_comparator_and_process_contract(self):
        self.assertEqual(run_tests.self_test(),47)
    def test_upstream_bytes(self):run_tests.check_original_sources()
    def test_fixture_safety_policy(self):
        for c in json.loads((run_tests.ROOT/'manifest.json').read_text())['cases']:
            run_tests.validate_case(c)
            if c['category']!='success':self.assertNotEqual(c['baseline'],'run')
    def test_compile_only_never_executes_reference(self):
        calls=[]
        def fake(argv,cwd=None,timeout=45):
            calls.append([str(x) for x in argv])
            return dict(code=0,out='',err='')
        with patch.object(run_tests,'execute',side_effect=fake),patch.object(sys,'argv',['run_tests.py','--gfortran','fake-gnu','--only','^zero_dynamic_stride$','--result',str(run_tests.ROOT/'evidence/compile-only-self-test.json')]),contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(run_tests.main(),0)
        self.assertEqual(len(calls),2)
        self.assertEqual(calls[0],['fake-gnu','--version'])
        self.assertEqual(calls[1][-1],'-fsyntax-only')
        self.assertTrue(all(c[0]=='fake-gnu' for c in calls))
    def test_isolated_replay(self):
        import check_generator
        r=check_generator.check();self.assertEqual(r['errors'],[]);self.assertTrue(r['summary']['originals_unchanged'])
if __name__=='__main__':unittest.main()
