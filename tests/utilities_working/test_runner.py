#!/usr/bin/env python3
import unittest
from run_tests import ROOT,validate_bytes,OLD,NEW,expected_diagnostic,matches_source_gate
class PreservationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_bytes()
        cls.working=(ROOT/'xutilities-nmax-100000.f90').read_bytes()
    def test_exact_change(self):self.assertEqual(validate_bytes(self.original,self.working)['changed_bytes'],1)
    def test_unchanged_working_rejected(self):
        with self.assertRaises(ValueError):validate_bytes(self.original,self.original)
    def test_other_edits_rejected(self):
        with self.assertRaises(ValueError):validate_bytes(self.original,self.working+b'\n')
    def test_line_endings_rejected(self):
        with self.assertRaises(ValueError):validate_bytes(self.original,self.working.replace(b'\r\n',b'\n'))
    def test_original_change_rejected(self):
        with self.assertRaises(ValueError):validate_bytes(self.original.replace(OLD,NEW),self.working)
class GateTests(unittest.TestCase):
    def setUp(self):
        self.source='/tmp/exact-source.f90'
        self.got=dict(status=1,stdout='',stderr=expected_diagnostic(self.source))
    def test_exact_gate(self):
        self.assertEqual(self.got['stderr'],self.source+':3084:47: Internal READ requires a scalar CHARACTER variable, distinct whole local numeric or CHARACTER targets and optional INTEGER IOSTAT\n')
        self.assertTrue(matches_source_gate(self.got,self.source))
    def test_wrong_path(self):self.assertFalse(matches_source_gate(self.got,'/tmp/other-source.f90'))
    def test_wrong_line(self):self.assertFalse(matches_source_gate(dict(self.got,stderr=self.got['stderr'].replace(':3084:',':3000:')),self.source))
    def test_wrong_column(self):self.assertFalse(matches_source_gate(dict(self.got,stderr=self.got['stderr'].replace(':47:',':48:')),self.source))
    def test_wrong_message(self):self.assertFalse(matches_source_gate(dict(self.got,stderr=self.got['stderr'].replace('scalar CHARACTER','scalar LOGICAL')),self.source))
    def test_missing_newline(self):self.assertFalse(matches_source_gate(dict(self.got,stderr=self.got['stderr'].rstrip()),self.source))
    def test_extra_diagnostic(self):self.assertFalse(matches_source_gate(dict(self.got,stderr=self.got['stderr']+'extra\n'),self.source))
    def test_nonempty_stdout(self):self.assertFalse(matches_source_gate(dict(self.got,stdout='partial\n'),self.source))
    def test_wrong_phase_or_crash_status(self):
        for status in [0,2,-11,None]:self.assertFalse(matches_source_gate(dict(self.got,status=status),self.source))
    def test_preserved_previous_gate(self):
        import json
        old=json.loads((ROOT/'oracle-evidence/0.49-results.json').read_text())
        self.assertEqual(old['source_proof']['working_sha256'],'69d8d20740044c26482ff0193adc6cd5ba85aa351d5c49f04359ebee2918f914')
        for phase in ['check','run']:
            self.assertEqual(old['fortfront'][phase]['status'],1)
            self.assertEqual(old['fortfront'][phase]['stdout'],'')
            self.assertTrue(old['fortfront'][phase]['stderr'].endswith(':2376:11: Internal WRITE requires a writable scalar CHARACTER variable\n'))
    def test_preserved_051_gate(self):
        import json,hashlib
        raw=(ROOT/'oracle-evidence/0.51-results.json').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),'1ae21fc09cbf572fd8f8f2c4bf085809ace7fc4b01e05a2932eeca258d65d87c')
        old=json.loads(raw)
        self.assertEqual(old['source_proof']['original_sha256'],'c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883')
        self.assertEqual(old['source_proof']['working_sha256'],'69d8d20740044c26482ff0193adc6cd5ba85aa351d5c49f04359ebee2918f914')
        for phase in ['check','run']:
            self.assertEqual(old['fortfront'][phase]['status'],1)
            self.assertEqual(old['fortfront'][phase]['stdout'],'')
            self.assertTrue(old['fortfront'][phase]['stderr'].endswith(':2493:24: Vector subscripts support only rank-one INTEGER row indices of a matrix\n'))
    def test_preserved_052_gate(self):
        import json,hashlib
        raw=(ROOT/'oracle-evidence/0.52-results.json').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),'7d4289bee1ef76348329979336b224eb74b5beed5a7e055a7632131eeba1a841')
        old=json.loads(raw)
        self.assertEqual(old['source_proof']['working_sha256'],'69d8d20740044c26482ff0193adc6cd5ba85aa351d5c49f04359ebee2918f914')
        for phase in ['check','run']:
            self.assertEqual(old['fortfront'][phase]['status'],1)
            self.assertEqual(old['fortfront'][phase]['stdout'],'')
            self.assertTrue(old['fortfront'][phase]['stderr'].endswith(':2678:36: Vector subscripts support only rank-one INTEGER row indices of a matrix\n'))
    def test_preserved_053_gate(self):
        import json,hashlib
        raw=(ROOT/'oracle-evidence/0.53-results.json').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),'1a06560b5decfcc6dfd4d66b2e6e108ed3410c998cf4b6290a61766c7e98581e')
        old=json.loads(raw)
        self.assertEqual(old['source_proof']['original_sha256'],'c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883')
        self.assertEqual(old['source_proof']['working_sha256'],'69d8d20740044c26482ff0193adc6cd5ba85aa351d5c49f04359ebee2918f914')
        for phase in ['check','run']:
            self.assertEqual(old['fortfront'][phase]['status'],1)
            self.assertEqual(old['fortfront'][phase]['stdout'],'')
            self.assertTrue(old['fortfront'][phase]['stderr'].endswith(':2992:1: Undeclared variable or unsupported statement: inquire\n'))
if __name__=='__main__':unittest.main()
