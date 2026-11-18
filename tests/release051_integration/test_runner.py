#!/usr/bin/env python3
import json,tempfile,unittest
from pathlib import Path
import generate_cases as gen
import run_tests as r
class Contracts(unittest.TestCase):
    def setUp(self):
        self.c=next(c for c in gen.MANIFEST if c['name']=='counted_outer_cycle_from_while')
        self.good=dict(returncode=0,stdout=self.c['stdout'],stderr='');self.silent=dict(returncode=0,stdout='',stderr='')
    def test_success(self):r.validate_candidate(self.c,'x',self.silent,self.good)
    def test_changed_values(self):
        with self.assertRaises(ValueError):r.validate_candidate(self.c,'x',self.silent,dict(self.good,stdout='9 7\n'))
    def test_text_case(self):
        c=next(c for c in gen.MANIFEST if c['name']=='false_metadata_undefined_body')
        with self.assertRaises(ValueError):r.validate_candidate(c,'x',self.silent,dict(self.good,stdout='false\n'))
    def test_record_and_padding_mutations(self):
        for out in ['9 6',' 9 6\n','9 6 \n','9\n6\n','9 6\n\n','9 6\r\n','9\t6\n']:
            with self.subTest(out=out),self.assertRaises(ValueError):r.validate_candidate(self.c,'x',self.silent,dict(self.good,stdout=out))
    def test_no_check_output(self):
        for key in ['stdout','stderr']:
            with self.subTest(key=key),self.assertRaises(ValueError):r.validate_candidate(self.c,'x',dict(self.silent,**{key:'noise'}),self.good)
    def test_wrong_success_status(self):
        for code in [-11,1,2]:
            with self.subTest(code=code),self.assertRaises(ValueError):r.validate_candidate(self.c,'x',self.silent,dict(self.good,returncode=code))
    def test_success_stderr(self):
        with self.assertRaises(ValueError):r.validate_candidate(self.c,'x',self.silent,dict(self.good,stderr='warning\n'))
    def test_rejection_and_diagnostic_mutations(self):
        c=next(c for c in gen.MANIFEST if c['mode']=='reject');err=r.diagnostic(c,'x');good=dict(returncode=1,stdout='',stderr=err)
        r.validate_candidate(c,'x',good,good)
        for m in [dict(good,returncode=0),dict(good,returncode=2),dict(good,stdout='x'),dict(good,stderr=''),dict(good,stderr=err.replace(':6:13:',':6:12:')),dict(good,stderr=err.replace('x:','y:',1)),dict(good,stderr=err+'Backtrace\n'),dict(good,stderr='other failure\n')]:
            with self.subTest(check=m),self.assertRaises(ValueError):r.validate_candidate(c,'x',m,good)
            with self.subTest(run=m),self.assertRaises(ValueError):r.validate_candidate(c,'x',good,m)
    def test_runtime_atomic_prefix(self):
        c=next(c for c in gen.MANIFEST if c['mode']=='runtime');good=dict(returncode=2,stdout='SAFE',stderr=r.diagnostic(c,'x'))
        r.validate_candidate(c,'x',self.silent,good)
        for m in [dict(good,stdout=''),dict(good,stdout='SAFE\n'),dict(good,stdout='SAFEjunk'),dict(good,returncode=1),dict(good,stderr='unrelated\n')]:
            with self.subTest(m=m),self.assertRaises(ValueError):r.validate_candidate(c,'x',self.silent,m)
    def test_crash_markers(self):
        for marker in r.CRASH:
            with self.subTest(marker=marker),self.assertRaises(ValueError):r.clean_result(dict(self.silent,stderr=marker.upper()))
    def test_gnu_controls(self):
        r.validate_gnu(self.c,self.silent,self.good)
        with self.assertRaises(ValueError):r.validate_gnu(self.c,self.silent,None)
        c=next(c for c in gen.MANIFEST if c['mode']=='runtime');r.validate_gnu(c,self.silent)
        with self.assertRaises(ValueError):r.validate_gnu(c,self.silent,self.good)
        c=next(c for c in gen.MANIFEST if c['mode']=='reject');r.validate_gnu(c,dict(returncode=1,stdout='',stderr="Error: Expected label 'outer' for END DO statement"))
        for m in [self.silent,dict(returncode=1,stdout='',stderr='Internal compiler error'),dict(returncode=1,stdout='',stderr='other')]:
            with self.subTest(m=m),self.assertRaises(ValueError):r.validate_gnu(c,m)
    def test_generator_exact_file_only(self):
        with tempfile.TemporaryDirectory()as d:
            root=Path(d);gen.generate(root);r.load_manifest(root)
            for p in [root/'manifest.json',*sorted((root/'cases').glob('*.f90'))]:self.assertEqual(p.read_bytes(),(r.ROOT/p.relative_to(root)).read_bytes())
            self.assertFalse((root/'inputs').exists())
    def test_source_mutation_rejected(self):
        with tempfile.TemporaryDirectory()as d:
            root=Path(d);gen.generate(root);p=root/'cases'/(self.c['name']+'.f90');p.write_bytes(p.read_bytes()+b'\n')
            with self.assertRaises(ValueError):r.load_manifest(root)
    def test_missing_source_rejected(self):
        with tempfile.TemporaryDirectory()as d:
            root=Path(d);gen.generate(root);(root/'cases'/(self.c['name']+'.f90')).unlink()
            with self.assertRaises((ValueError,FileNotFoundError)):r.load_manifest(root)
    def test_extra_source_rejected(self):
        with tempfile.TemporaryDirectory()as d:
            root=Path(d);gen.generate(root);(root/'cases'/'extra.f90').write_text('end\n')
            with self.assertRaises(ValueError):r.load_manifest(root)
    def test_duplicate_manifest_rejected(self):
        with tempfile.TemporaryDirectory()as d:
            root=Path(d);gen.generate(root);p=root/'manifest.json';rows=json.loads(p.read_text());rows.append(rows[0]);p.write_text(json.dumps(rows))
            with self.assertRaises(ValueError):r.load_manifest(root)
if __name__=='__main__':unittest.main()
