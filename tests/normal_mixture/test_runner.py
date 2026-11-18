#!/usr/bin/env python3
"""Pure-Python harness checks; no compiler or candidate program is executed."""
import copy
import json
import math
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

import run_tests as suite


def output(weights=(.35,.65),means=(-2,3),sds=(.8,1.5),iterations=21,converged='T',ll=-2200):
    lines=['Observations: 1000',f'EM iterations: {iterations}',f'Converged: {converged}',
           f'Log likelihood: {ll:16.3f}',suite.HEADER]
    for j,(tw,w,tm,m,ts,s) in enumerate(zip([.35,.65],weights,[-2,3],means,[.8,1.5],sds),1):
        lines.append(f'{j:3d}'+''.join(f'{x:11.4f}' for x in [tw,w,tm,m,ts,s]))
    return '\n'.join(lines)+'\n'


def process(code=0,stdout='',stderr='',**extra):
    return dict(returncode=code,stdout=stdout,stderr=stderr,**extra)


def synthetic(case):
    ref=case['expected']
    lines=[f'{ref["iterations"]} '+('T' if ref['converged'] else 'F'),f'{ref["loglik"]:25.15f}']
    lines += [''.join(f'{v:25.15f}' for v in row) for row in zip(ref['weights'],ref['means'],ref['sds'])]
    return '\n'.join(lines)+'\n'


class TestFullOutput(unittest.TestCase):
    def test_valid_output(self):
        metrics=suite.full_output(output())
        self.assertEqual(metrics['iterations'],21)
        self.assertEqual(metrics['converged'],True)
        self.assertAlmostEqual(metrics['fitted_mean'],1.25)
        self.assertAlmostEqual(metrics['fitted_variance'],7.374)

    def test_component_label_permutation(self):
        suite.full_output(output(weights=(.65,.35),means=(3,-2),sds=(1.5,.8)))

    def test_widths(self):
        base=output().splitlines()
        for row in [3,5,6]:
            for delta in [-1,1]:
                changed=base[:]
                changed[row]=changed[row][1:] if delta==-1 else ' '+changed[row]
                with self.assertRaises(AssertionError,msg=(row,delta)):
                    suite.full_output('\n'.join(changed)+'\n')

    def test_shape_headers_and_true_parameters(self):
        base=output()
        invalid=[base+'extra\n',base.replace('Observations: 1000','Observations: 999'),
                 base.replace('True mean','True MEAN'),base.replace('0.3500','0.3400',1),
                 base.replace('  2','  3',1),'\n'.join(base.splitlines()[:-1])+'\n']
        for text in invalid:
            with self.assertRaises(AssertionError):
                suite.full_output(text)

    def test_finite_positive_normalized_and_statistical_checks(self):
        for text in [output(weights=(-.1,1.1)),output(weights=(.35,.60)),output(sds=(0,1.5)),
                     output(ll=float('nan')),output(ll=float('inf')),output(means=(10,20)),
                     output(iterations=0),output(iterations=501),output(converged='F')]:
            with self.assertRaises((AssertionError,ValueError)):
                suite.full_output(text)


class TestSyntheticMath(unittest.TestCase):
    def test_all_success_fixtures(self):
        for case in suite.cases():
            if case['diagnostic'] is None:
                suite.synthetic_output(synthetic(case),case)

    def test_single_component_closed_form_and_cap_likelihood(self):
        for case in suite.cases():
            if case['name'].startswith('single'):
                ref=case['expected']
                self.assertEqual(ref['weights'],[1.0])
                self.assertEqual(ref['means'],[0.0])
                self.assertEqual(ref['sds'],[math.sqrt(2)])
                self.assertAlmostEqual(ref['loglik'],-2.5*(math.log(4*math.pi)+1),places=12)
                self.assertEqual(ref['converged'],case['name']=='single_default')
                if case['limit']:
                    self.assertEqual(ref['iterations'],case['limit'])

    def test_synthetic_shape_precision_values_and_convergence(self):
        case=next(c for c in suite.cases() if c['name']=='single_default')
        good=synthetic(case)
        rows=good.splitlines()
        invalid=[good+'extra\n',good.replace(' T',' F'),good.replace('3 T','2 T'),
                 '\n'.join(rows[:-1])+'\n','\n'.join(rows[:-1]+[rows[-1][1:]])+'\n',
                 good.replace('1.414213562373095','1.514213562373095')]
        for text in invalid:
            with self.assertRaises((AssertionError,ValueError)):
                suite.synthetic_output(text,case)

    def test_label_symmetry_normalization_and_variance_floor(self):
        cases={c['name']:c for c in suite.cases() if c['diagnostic'] is None}
        normal=cases['symmetric_default']['expected']
        renormalized=cases['symmetric_renormalize']['expected']
        swapped=cases['symmetric_swap']['expected']
        self.assertEqual(normal,renormalized)
        for key in ['weights','means','sds']:
            self.assertEqual(normal[key],list(reversed(swapped[key])))
        self.assertEqual(cases['variance_floor']['expected']['sds'],[.0001,.0001])

    def test_reference_objective_monotonicity(self):
        for case in suite.cases():
            if case['diagnostic'] is None:
                trace=case['expected']['likelihood_trace']
                self.assertTrue(all(b>=a-1e-10*(1+abs(a)) for a,b in zip(trace,trace[1:])))


class TestProvenance(unittest.TestCase):
    def test_release_sources_and_shape(self):
        original,cases,manifest=suite.prepare_sources()
        self.assertEqual(len(original),5553)
        self.assertEqual(suite.digest(original),suite.EXPECTED_SHA)
        self.assertEqual(len(cases),25)
        self.assertEqual(sum(c['diagnostic'] is None for c in cases),12)
        self.assertEqual(sum(c['diagnostic'] is not None for c in cases),13)
        self.assertEqual(len({c['name'] for c in cases}),25)
        self.assertEqual(manifest['original']['path'],'input/xmix_dt.f90')
        prefix=original[:original.index(b'end module normal_mixture')+len(b'end module normal_mixture')]+b'\n'
        for case in manifest['synthetic_fixtures']:
            self.assertFalse(Path(case['path']).is_absolute())
            raw=(suite.ROOT/case['path']).read_bytes()
            self.assertTrue(raw.startswith(prefix))
            self.assertEqual(suite.digest(raw),case['sha256'])
            self.assertLessEqual(max(map(len,raw.splitlines())),132)

    def test_acos_delta_only(self):
        original=(suite.ROOT/'input/xmix_dt.f90').read_bytes()
        variant=(suite.ROOT/'sources/xmix_dt_acos_variant.f90').read_bytes()
        changed=[(a,b) for a,b in zip(original.splitlines(),variant.splitlines()) if a!=b]
        self.assertEqual(len(original.splitlines()),len(variant.splitlines()))
        self.assertEqual(changed,[(b'!   real(dp), parameter :: pi = acos(-1.0_dp)',
                                   b'   real(dp), parameter :: pi = acos(-1.0_dp)'),
                                  (b'   real(dp), parameter :: pi = 3.141592653589793_dp',
                                   b'!   real(dp), parameter :: pi = 3.141592653589793_dp')])

    def test_modified_original_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);source=root/'changed.f90'
            source.write_bytes((suite.ROOT/'input/xmix_dt.f90').read_bytes()+b'\n')
            with self.assertRaisesRegex(AssertionError,'Original attachment changed'):
                suite.prepare_sources(source,root)

    def test_modified_fixture_never_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            suite.prepare_sources(suite.DEFAULT_ORIGINAL,root)
            target=root/'sources/single_default.f90'
            changed=target.read_bytes()+b'! modified\n'
            target.write_bytes(changed)
            with self.assertRaisesRegex(AssertionError,'Maintained fixture changed'):
                suite.prepare_sources(suite.DEFAULT_ORIGINAL,root)
            self.assertEqual(target.read_bytes(),changed)

    def test_modified_metadata_never_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)
            suite.prepare_sources(suite.DEFAULT_ORIGINAL,root)
            target=root/'source_manifest.json'
            changed=target.read_bytes()+b' '
            target.write_bytes(changed)
            with self.assertRaisesRegex(AssertionError,'Maintained fixture changed'):
                suite.prepare_sources(suite.DEFAULT_ORIGINAL,root)
            self.assertEqual(target.read_bytes(),changed)


class TestProcessContracts(unittest.TestCase):
    def test_success_wrong_status_signal_timeout_and_diagnostic(self):
        self.assertTrue(suite.evaluate_execution(process(stdout=output()),'fortfront',None)['passed'])
        for bad in [dict(returncode=1),dict(returncode=2),dict(returncode=-9),dict(returncode=None),
                    dict(timeout=True),dict(launch_error=True),dict(stderr='unexpected')]:
            p=process(stdout=output());p.update(bad)
            self.assertFalse(suite.evaluate_execution(p,'fortfront',None)['passed'],bad)

    def test_expected_errors_require_status_diagnostic_and_no_output(self):
        case=next(c for c in suite.cases() if c['name']=='fit_zero_limit')
        for engine,status in [('gnu',1),('fortfront',2)]:
            good=process(status,stderr='ERROR STOP '+case['diagnostic'])
            self.assertTrue(suite.evaluate_execution(good,engine,case)['passed'])
            for bad in [dict(returncode=0),dict(returncode=-9),dict(returncode=None),dict(returncode=7),
                        dict(stderr=''),dict(stderr='other error'),dict(stdout='123'),dict(stdout=' '),
                        dict(timeout=True),dict(launch_error=True)]:
                p=copy.deepcopy(good);p.update(bad)
                self.assertFalse(suite.evaluate_execution(p,engine,case)['passed'],(engine,bad))

    def test_default_budget_is_separate_observation(self):
        passed=suite.classify_default_budget(process(stdout=output()))
        exhausted=suite.classify_default_budget(process(2,stderr='Execution step limit exceeded'))
        self.assertEqual(passed['outcome'],'passed_with_default_budget')
        self.assertEqual(exhausted['outcome'],'default_step_budget_exhausted')
        self.assertTrue(exhausted['accepted_observation'])
        self.assertNotIn('metrics',exhausted)
        for p in [process(-9,stderr='step limit'),process(1,stderr='step limit'),
                  process(2,stdout='leak',stderr='step limit'),process(2,stderr='other failure'),
                  process(2,stderr='step limit',timeout=True),process(stdout=output(),stderr='warning')]:
            self.assertFalse(suite.classify_default_budget(p)['accepted_observation'])

    def test_compile_process_output_is_checked(self):
        for p in [process(stdout=' '),process(stderr='warning'),process(-9),process(timeout=True)]:
            with self.assertRaises(AssertionError):
                suite.assert_process(p,0,no_stdout=True,no_stderr=True)

    def test_timeout_and_launch_error_are_recorded_without_execution(self):
        with mock.patch.object(suite.subprocess,'run',side_effect=subprocess.TimeoutExpired(['dummy'],1,b'partial',b'error')):
            p=suite.launch(['dummy'],suite.ROOT,1)
        self.assertIsNone(p['returncode'])
        self.assertEqual(p['stdout'],'partial')
        self.assertEqual(p['stderr'],'error')
        self.assertTrue(p['timeout'])
        with mock.patch.object(suite.subprocess,'run',side_effect=FileNotFoundError('missing executable')):
            p=suite.launch(['dummy'],suite.ROOT,1)
        self.assertIsNone(p['returncode'])
        self.assertTrue(p['launch_error'])

    def test_gnu_lookup_uses_path_or_explicit_option(self):
        with mock.patch.object(suite.shutil,'which',return_value='/usr/bin/gfortran') as lookup:
            self.assertEqual(suite.resolve_compiler('gfortran'),Path('/usr/bin/gfortran').resolve())
            lookup.assert_called_once_with('gfortran')
        with mock.patch.object(suite.shutil,'which',return_value=None):
            with self.assertRaisesRegex(AssertionError,'GNU Fortran executable not found'):
                suite.resolve_compiler('missing-gfortran')


if __name__=='__main__':
    unittest.main()
