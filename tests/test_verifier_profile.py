from pathlib import Path
import importlib.util
import unittest
from unittest.mock import patch
p = Path(__file__).resolve().parents[1] / 'scripts/verify.py'
spec = importlib.util.spec_from_file_location('release_verifier', p)
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)
class ProfileTests(unittest.TestCase):
    def test_default_is_unchanged(self):
        self.assertEqual(v.debug_profile_args(), ['--profile', 'debug'])
    def test_split_changes_only_debug_storage(self):
        with patch.object(v.sys, 'platform', 'linux'):
            self.assertEqual(v.debug_profile_args(True), ['--profile', 'debug', '--flag', '-gsplit-dwarf'])
    def test_windows_default(self):
        with patch.object(v.sys, 'platform', 'win32'):
            self.assertEqual(v.debug_profile_args(False), ['--profile', 'debug'])
    def test_split_rejects_unvalidated_platforms(self):
        for platform in ['win32', 'darwin']:
            with self.subTest(platform=platform), patch.object(v.sys, 'platform', platform):
                with self.assertRaises(ValueError): v.debug_profile_args(True)
p2 = Path(__file__).resolve().parents[1] / 'scripts/verify_native_shared.py'
spec2 = importlib.util.spec_from_file_location('shared_verifier', p2)
shared = importlib.util.module_from_spec(spec2)
spec2.loader.exec_module(shared)
class SharedPlanTests(unittest.TestCase):
    def sample(self):
        flags=['-g','-fPIC','-fcheck=bounds','-fcheck=array-temps','-fbacktrace']
        model={'target-os':'Linux','compiler':{'fc':'gfortran'},'fortran-flags':' '.join(flags),'packages':{'fortfront-interpreter':{'sources':{'s':{'unit-scope':'FPM_SCOPE_TEST','unit-type':'FPM_UNIT_PROGRAM','exe-name':'test_one','file-name':'test/test_one.f90'}}}}}
        commands=[{'file':'test/test_one.f90','arguments':['gfortran','-c','test/test_one.f90',*flags,'-fimplicit-none','-Werror=implicit-interface','-o','build/test_one.o']}]
        return model,commands
    def test_exact_command_retained(self):
        m,c=self.sample();flags,plans=shared.plan(m,c)
        self.assertEqual(plans[0]['compile'],c[0]['arguments'])
        self.assertEqual(plans[0]['object'],'build/test_one.o')
    def test_missing_runtime_check_rejected(self):
        m,c=self.sample();c[0]['arguments'].remove('-fcheck=bounds')
        with self.assertRaises(ValueError): shared.plan(m,c)
    def test_non_pic_rejected(self):
        m,c=self.sample();m['fortran-flags']=m['fortran-flags'].replace('-fPIC','')
        with self.assertRaises(ValueError): shared.plan(m,c)
    def test_duplicate_source_rejected(self):
        m,c=self.sample();c.append(c[0])
        with self.assertRaises(ValueError): shared.plan(m,c)
    def test_nonprogram_never_silently_skipped(self):
        m,c=self.sample();m['packages']['fortfront-interpreter']['sources']['s']['unit-type']='FPM_UNIT_MODULE'
        with self.assertRaises(ValueError): shared.plan(m,c)
    def test_missing_source_never_silently_skipped(self):
        m,c=self.sample()
        with self.assertRaises(KeyError): shared.plan(m,[])
    def test_wrong_platform_rejected(self):
        m,c=self.sample();m['target-os']='Windows'
        with self.assertRaises(ValueError): shared.plan(m,c)
    def test_wrong_compiler_rejected(self):
        m,c=self.sample();m['compiler']['fc']='other'
        with self.assertRaises(ValueError): shared.plan(m,c)
if __name__ == '__main__': unittest.main()
