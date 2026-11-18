#!/usr/bin/env python3
"""Standalone original-program, GNU-oracle and mathematical EM checks.

Own original work for this validation task; no third-party code imported.
The user's program is copied unchanged and embedded as an unchanged module in
explicitly labeled synthetic test drivers. RNG outputs are never compared.
"""
import argparse
import difflib
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parent
EXPECTED_SHA = 'bb96142295269f67e2e34a95ad708db957b75b96ab174219690d4da7814f1f4d'
DEFAULT_ORIGINAL = ROOT / 'input/xmix_dt.f90'
DEFAULT_GNU = 'gfortran'
GNU_FLAGS = ['-std=f2018', '-pedantic-errors', '-fcheck=all', '-fbacktrace', '-Wall', '-Wextra']
HEADER = 'Comp    True wt   Est wt     True mean  Est mean   True sd    Est sd'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def full_output(text):
    """Hard output contracts plus explicitly stochastic broad sanity checks."""
    lines = text.splitlines()
    assert len(lines) == 7, ('line_count', lines)
    assert lines[0] == 'Observations: 1000', ('observations', lines[0])
    hit = re.fullmatch(r'EM iterations: ([1-9][0-9]*)', lines[1])
    assert hit and 1 <= int(hit[1]) <= 500, ('iterations', lines[1])
    assert lines[2] in ['Converged: T', 'Converged: F'], ('logical_format', lines[2])
    assert re.fullmatch(r'Log likelihood: [ -][ 0-9-]*[0-9]\.[0-9]{3}', lines[3]), lines[3]
    assert len(lines[3]) == len('Log likelihood: ') + 16, ('f16.3_width', lines[3])
    ll = float(lines[3][len('Log likelihood: '):])
    assert math.isfinite(ll), ('finite_likelihood', ll)
    assert lines[4] == HEADER, ('header', lines[4])
    rows = []
    for j, line in enumerate(lines[5:], 1):
        assert len(line) == 69, ('i3_6f11.4_width', line)
        assert line[:3] == f'{j:3d}', ('row_index', line)
        cols = []
        for col in range(6):
            field = line[3+11*col:3+11*(col+1)]
            assert re.fullmatch(r' *-?[0-9]+\.[0-9]{4}', field), ('f11.4', field)
            cols.append(float(field))
        assert all(math.isfinite(v) for v in cols), ('finite_parameters', cols)
        assert cols[0] == [0.35, 0.65][j-1], ('true_weight', cols)
        assert cols[2] == [-2.0, 3.0][j-1], ('true_mean', cols)
        assert cols[4] == [0.8, 1.5][j-1], ('true_sd', cols)
        rows.append({'weight': cols[1], 'mean': cols[3], 'sd': cols[5]})
    assert all(0 < r['weight'] < 1 and r['sd'] > 0 for r in rows), rows
    assert abs(sum(r['weight'] for r in rows)-1) <= 1.01e-4, ('normalized', rows)
    # These are generous stochastic smoke thresholds, not deterministic equalities.
    ordered = sorted(rows, key=lambda r: r['mean'])
    assert lines[2] == 'Converged: T', ('stochastic_convergence', lines[2])
    assert -3500 < ll < -1500, ('stochastic_likelihood', ll)
    for row, w, m, sd in zip(ordered, [0.35, 0.65], [-2, 3], [0.8, 1.5]):
        assert abs(row['weight']-w) < .18, ('stochastic_weight', row)
        assert abs(row['mean']-m) < .85, ('stochastic_mean', row)
        assert abs(row['sd']-sd) < .7, ('stochastic_sd', row)
    fitted_mean = sum(r['weight']*r['mean'] for r in rows)
    fitted_var = sum(r['weight']*(r['sd']**2+(r['mean']-fitted_mean)**2) for r in rows)
    assert abs(fitted_mean-1.25) < .65, ('stochastic_moment_mean', fitted_mean)
    assert abs(fitted_var-7.374) < 3.0, ('stochastic_moment_variance', fitted_var)
    return {'iterations': int(hit[1]), 'converged': True, 'loglik': ll,
            'components': rows, 'fitted_mean': fitted_mean, 'fitted_variance': fitted_var}


def likelihood(xs, weights, means, sds):
    total = 0.0
    for x in xs:
        exponents = [math.log(w)-math.log(s)-0.5*math.log(2*math.pi)-0.5*((x-m)/s)**2
                     for w, m, s in zip(weights, means, sds)]
        peak = max(exponents)
        total += peak + math.log(math.fsum(math.exp(v-peak) for v in exponents))
    return total


def reference_em(xs, initial_w, initial_mu, initial_sd, limit=500, tol=1e-8):
    """Independent host-language EM equations; also check objective monotonicity."""
    weights = [v/math.fsum(initial_w) for v in initial_w]
    means, sds = list(initial_mu), list(initial_sd)
    sample_mean = math.fsum(xs)/len(xs)
    floor = 1e-8*math.fsum((x-sample_mean)**2 for x in xs)/len(xs)
    previous = None
    trace = []
    for iteration in range(1, limit+1):
        ll = likelihood(xs, weights, means, sds)
        trace.append(ll)
        if previous is not None:
            assert ll >= previous-1e-10*(1+abs(previous)), ('reference_monotonicity', trace)
            if abs(ll-previous) <= tol*(1+abs(previous)):
                return dict(iterations=iteration, converged=True, loglik=ll,
                            weights=weights, means=means, sds=sds, likelihood_trace=trace)
        previous = ll
        responsibility = []
        for x in xs:
            ls = [math.log(w)-math.log(s)-.5*((x-m)/s)**2
                  for w, m, s in zip(weights, means, sds)]
            peak = max(ls)
            unnormalized = [math.exp(v-peak) for v in ls]
            den = math.fsum(unnormalized)
            responsibility.append([v/den for v in unnormalized])
        counts = [math.fsum(r[j] for r in responsibility) for j in range(len(weights))]
        means = [math.fsum(r[j]*x for r, x in zip(responsibility, xs))/counts[j]
                 for j in range(len(weights))]
        second = [math.fsum(r[j]*x*x for r, x in zip(responsibility, xs))/counts[j]
                  for j in range(len(weights))]
        sds = [math.sqrt(max(floor, q-m*m)) for q, m in zip(second, means)]
        weights = [v/len(xs) for v in counts]
    ll = likelihood(xs, weights, means, sds)
    trace.append(ll)
    assert ll >= previous-1e-10*(1+abs(previous)), ('reference_monotonicity', trace)
    return dict(iterations=limit, converged=False, loglik=ll,
                weights=weights, means=means, sds=sds, likelihood_trace=trace)


def literal(value):
    return f'{float(value):.17e}_dp'


def constructor(values):
    return '['+', '.join(literal(v) for v in values)+']'


def wrapped_assignment(name, values):
    # Keep every generated line within the standard 132-column limit.
    return name+' = [ &\n'+', &\n'.join('      '+literal(v) for v in values)+']\n'


def make_driver(module, name, xs, weights, means, sds, limit=None, tol=None, operation='fit'):
    text = (module+'\n! Synthetic validation driver, not the original program.\n'
            +'program '+name+'\n   use normal_mixture\n   implicit none\n'
            +f'   real(dp) :: x({len(xs)}), weight({len(weights)}), mu({len(means)}), sigma({len(sds)}), ll\n'
            +'   integer :: iterations, j\n   logical :: converged\n')
    for variable, values in [('x', xs), ('weight', weights), ('mu', means), ('sigma', sds)]:
        if values:
            text += '   '+wrapped_assignment(variable, values)
    if operation == 'simulate':
        text += '   call simulate_mixture(x, weight, mu, sigma)\n'
    else:
        text += '   call fit_mixture_em(x, weight, mu, sigma, iterations, ll, converged'
        if limit is not None:
            text += ', max_iter='+str(limit)
        if tol is not None:
            text += ', &\n      tol='+literal(tol)
        text += ')\n'
    text += "   print '(i0,1x,l1)', iterations, converged\n   print '(f25.15)', ll\n"
    text += "   do j = 1, size(weight)\n      print '(3f25.15)', weight(j), mu(j), sigma(j)\n   end do\n"
    text += 'end program '+name+'\n'
    assert max(map(len, text.splitlines())) <= 132, name
    return text


def cases():
    result = []
    def add(name, x, w, m, s, limit=None, tol=None, diagnostic=None, operation='fit'):
        case = dict(name=name, x=x, w=w, m=m, s=s, limit=limit, tol=tol,
                    diagnostic=diagnostic, operation=operation)
        if not diagnostic:
            case['expected'] = reference_em(x, w, m, s, limit or 500, tol or 1e-8)
        result.append(case)
    for limit in [None, 1, 2]:
        add('single_'+('default' if limit is None else 'cap'+str(limit)),
            [-2,-1,0,1,2], [7], [10], [9], limit=limit)
    add('symmetric_default', [-3,-2,-1,1,2,3], [.5,.5], [-2,2], [1,1])
    add('symmetric_renormalize', [-3,-2,-1,1,2,3], [7,7], [-2,2], [1,1])
    add('symmetric_swap', [-3,-2,-1,1,2,3], [.5,.5], [2,-2], [1,1])
    add('variance_floor', [-1,-1,1,1], [.5,.5], [-1,1], [.1,.1])
    x = [-3,-2.3,-1.8,-1.1,1.0,1.9,2.3,3.1,3.4,4.0]
    for limit in [None,1,2,5,10]:
        add('asymmetric_'+('default' if limit is None else 'cap'+str(limit)),
            x, [3,7], [-1,2], [2,2], limit=limit)
    add('fit_small_sample', [1], [.5,.5], [-2,2], [1,1], diagnostic='invalid sample or component count')
    add('fit_no_components', [-1,1], [], [], [], diagnostic='invalid sample or component count')
    add('fit_bad_sizes', [-1,1], [.5,.5], [0], [1,1], diagnostic='invalid parameter sizes')
    add('fit_zero_limit', [-1,1], [1], [0], [1], limit=0, diagnostic='invalid EM options')
    add('fit_zero_tolerance', [-1,1], [1], [0], [1], tol=0, diagnostic='invalid EM options')
    add('fit_constant_sample', [2,2,2], [1], [0], [1], diagnostic='constant sample')
    add('fit_zero_weight', [-1,1], [0,1], [-1,1], [1,1],
        diagnostic='positive starting weights and standard deviations required')
    add('fit_zero_sd', [-1,1], [1], [0], [0],
        diagnostic='positive starting weights and standard deviations required')
    add('fit_empty_component', [-1,0,1], [.5,.5], [0,1e6], [1,1], diagnostic='empty mixture component')
    add('simulate_bad_sizes', [0,0], [.5,.5], [0], [1,1], diagnostic='invalid parameter sizes', operation='simulate')
    add('simulate_negative_weight', [0,0], [-.1,1.1], [0,1], [1,1], diagnostic='invalid weights', operation='simulate')
    add('simulate_weight_sum', [0,0], [.3,.3], [0,1], [1,1], diagnostic='invalid weights', operation='simulate')
    add('simulate_zero_sd', [0,0], [1], [0], [0], diagnostic='invalid standard deviations', operation='simulate')
    return result


def synthetic_output(text, case):
    expected = case['expected']
    lines = text.splitlines()
    assert len(lines) == 2+len(case['w']), ('line_count', lines)
    assert re.fullmatch(r'[1-9][0-9]* [TF]', lines[0]), ('iteration_format', lines[0])
    assert len(lines[1]) == 25 and re.fullmatch(r' *-?[0-9]+\.[0-9]{15}', lines[1]), lines[1]
    first = lines[0].split()
    assert first == [str(expected['iterations']), 'T' if expected['converged'] else 'F'], (first, expected)
    actual = {'iterations': int(first[0]), 'converged': first[1]=='T', 'loglik': float(lines[1]),
              'weights': [], 'means': [], 'sds': []}
    for row in lines[2:]:
        assert len(row) == 75, ('synthetic_row_width', row)
        fields = [row[j:j+25] for j in range(0,75,25)]
        assert all(re.fullmatch(r' *-?[0-9]+\.[0-9]{15}', v) for v in fields), fields
        values = [float(v) for v in fields]
        assert len(values) == 3, row
        for key, value in zip(['weights','means','sds'], values):
            actual[key].append(value)
    for key in ['loglik','weights','means','sds']:
        ours = actual[key] if isinstance(actual[key], list) else [actual[key]]
        theirs = expected[key] if isinstance(expected[key], list) else [expected[key]]
        for a, b in zip(ours, theirs):
            assert math.isfinite(a), (key, a)
            assert math.isclose(a, b, rel_tol=2e-10, abs_tol=2e-10), (key, a, b)
    assert abs(sum(actual['weights'])-1) <= 2e-12, actual
    assert all(v > 0 for v in actual['weights']+actual['sds']), actual
    recomputed_ll = likelihood(case['x'], actual['weights'], actual['means'], actual['sds'])
    assert math.isclose(actual['loglik'], recomputed_ll, rel_tol=3e-10, abs_tol=3e-10), actual
    if case['name'].startswith('single'):
        assert actual['weights'] == [1.0] and actual['means'] == [0.0], actual
        assert math.isclose(actual['sds'][0], math.sqrt(2), abs_tol=1e-14), actual
        closed = -2.5*(math.log(4*math.pi)+1)
        assert math.isclose(actual['loglik'], closed, abs_tol=1e-12), actual
    if case['name'] == 'variance_floor':
        assert actual['sds'] == [0.0001,0.0001], actual
    return actual


def write_or_verify(path, expected):
    """Create missing maintained files; never overwrite an edited fixture."""
    path = Path(path)
    if path.exists():
        assert path.read_bytes() == expected, 'Maintained fixture changed: '+str(path)
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(expected)


def prepare_sources(original_path=DEFAULT_ORIGINAL, root=ROOT):
    original = Path(original_path).read_bytes()
    assert len(original) == 5553 and digest(original) == EXPECTED_SHA, 'Original attachment changed'
    original.decode('ascii')
    write_or_verify(root/'input/xmix_dt.f90', original)
    write_or_verify(root/'sources/xmix_dt_original.f90', original)
    decoded = original.decode('ascii')
    old = '!   real(dp), parameter :: pi = acos(-1.0_dp)\n   real(dp), parameter :: pi = 3.141592653589793_dp\n'
    new = '   real(dp), parameter :: pi = acos(-1.0_dp)\n!   real(dp), parameter :: pi = 3.141592653589793_dp\n'
    assert decoded.count(old) == 1, 'Expected PI declaration pair changed'
    variant = decoded.replace(old,new).encode('ascii')
    write_or_verify(root/'sources/xmix_dt_acos_variant.f90', variant)
    delta = ''.join(difflib.unified_diff(decoded.splitlines(True), variant.decode('ascii').splitlines(True),
                                       fromfile='xmix_dt_original.f90', tofile='xmix_dt_acos_variant.f90'))
    write_or_verify(root/'acos_variant.diff', delta.encode('ascii'))
    module_end = decoded.index('end module normal_mixture')+len('end module normal_mixture')
    module = decoded[:module_end]+'\n'
    fixture_cases = cases()
    fixture_manifest = []
    for case in fixture_cases:
        content = make_driver(module, case['name'], case['x'], case['w'], case['m'], case['s'],
                              case['limit'],case['tol'],case['operation']).encode('ascii')
        relative = 'sources/'+case['name']+'.f90'
        write_or_verify(root/relative, content)
        fixture_manifest.append(dict(name=case['name'], path=relative, sha256=digest(content),
                                     bytes=len(content), module_prefix_sha256=digest(module.encode('ascii')),
                                     expected_error=case['diagnostic'], operation=case['operation'],
                                     x=case['x'], weight=case['w'], mu=case['m'], sigma=case['s'],
                                     max_iter=case['limit'], tol=case['tol']))
    manifest = dict(schema_version=1,
                    provenance='User-supplied source; unchanged original and clearly labeled generated variants.',
                    original=dict(path='input/xmix_dt.f90', bytes=len(original), sha256=digest(original)),
                    original_copy=dict(path='sources/xmix_dt_original.f90', bytes=len(original), sha256=digest(original)),
                    acos_variant=dict(path='sources/xmix_dt_acos_variant.f90', bytes=len(variant),
                                      sha256=digest(variant), exact_diff='acos_variant.diff'),
                    synthetic_module_prefix=dict(bytes=len(module), sha256=digest(module.encode('ascii'))),
                    synthetic_fixtures=fixture_manifest)
    write_or_verify(root/'source_manifest.json', (json.dumps(manifest,indent=2)+'\n').encode('ascii'))
    return original, fixture_cases, manifest


def launch(command, cwd, timeout):
    start = time.monotonic()
    command = [str(a) for a in command]
    try:
        run = subprocess.run(command, cwd=cwd, text=True, capture_output=True, timeout=timeout)
        return dict(command=command, returncode=run.returncode, stdout=run.stdout, stderr=run.stderr,
                    elapsed_seconds=time.monotonic()-start)
    except subprocess.TimeoutExpired as exc:
        def decoded(value):
            return value.decode(errors='replace') if isinstance(value,bytes) else (value or '')
        return dict(command=command, returncode=None, stdout=decoded(exc.stdout), stderr=decoded(exc.stderr),
                    elapsed_seconds=time.monotonic()-start, timeout=True)
    except OSError as exc:
        return dict(command=command, returncode=None, stdout='', stderr=str(exc),
                    elapsed_seconds=time.monotonic()-start, launch_error=True)


def assert_process(result, status, no_stdout=False, no_stderr=False):
    assert not result.get('timeout') and not result.get('launch_error'), result
    assert result['returncode'] == status, result
    if no_stdout:
        assert result['stdout'] == '', result
    if no_stderr:
        assert result['stderr'] == '', result


def evaluate_execution(result, engine, case):
    record = {}
    try:
        if case is not None and case['diagnostic']:
            # GNU's ERROR STOP character reports status 1; FortFront uses its
            # checked-runtime status 2. Signals and unrelated exits are failures.
            assert_process(result, 1 if engine == 'gnu' else 2, no_stdout=True)
            assert result['stderr'].strip() and case['diagnostic'] in result['stderr'], result
            record['expected_error'] = case['diagnostic']
        else:
            assert_process(result, 0, no_stderr=True)
            record['metrics'] = full_output(result['stdout']) if case is None else synthetic_output(result['stdout'],case)
        record['passed'] = True
    except (AssertionError,ValueError) as exc:
        record['passed'] = False
        record['failure'] = str(exc)
    return record


def classify_default_budget(result):
    record = dict(process=result)
    try:
        if result['returncode'] == 0:
            checked = evaluate_execution(result, 'fortfront', None)
            assert checked['passed'], checked
            record.update(metrics=checked['metrics'], outcome='passed_with_default_budget', accepted_observation=True)
        else:
            assert_process(result, 2, no_stdout=True)
            assert result['stderr'].strip() and 'step limit' in result['stderr'].lower(), result
            record.update(outcome='default_step_budget_exhausted', accepted_observation=True)
    except (AssertionError,ValueError) as exc:
        record.update(outcome='unexpected_failure', accepted_observation=False, failure=str(exc))
    return record


def resolve_compiler(value):
    found = shutil.which(str(value))
    assert found, 'GNU Fortran executable not found: '+str(value)+'; use --gfortran or add it to PATH'
    return Path(found).resolve()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--original', type=Path, default=DEFAULT_ORIGINAL)
    ap.add_argument('--gfortran', default=DEFAULT_GNU)
    ap.add_argument('--candidate', type=Path)
    ap.add_argument('--skip-gnu', action='store_true')
    ap.add_argument('--repeats', type=int, default=6)
    ap.add_argument('--timeout', type=int, default=180)
    ap.add_argument('--max-steps', type=int, default=100000000)
    ap.add_argument('--label', default='validation')
    ap.add_argument('--result', type=Path)
    ap.add_argument('--prepare-only', action='store_true', help='verify maintained sources/provenance without running any compiler')
    args = ap.parse_args()
    assert args.repeats > 0 and args.timeout > 0 and args.max_steps > 0
    original, fixture_cases, manifest = prepare_sources(args.original)
    if args.prepare_only:
        print('PASS: original, ACOS variant, 25 synthetic fixtures and self-contained provenance')
        return 0
    src = ROOT/'sources'
    out = ROOT/'evidence'/args.label
    out.mkdir(parents=True, exist_ok=True)
    report = {'source_manifest': manifest, 'gnu_flags':GNU_FLAGS, 'checks':[],
              'random_stream_comparison':False, 'candidate':None, 'default_budget_outcomes':[],
              'math_oracles':{c['name']:c['expected'] for c in fixture_cases if not c['diagnostic']}}
    engines = []
    if not args.skip_gnu:
        compiler = resolve_compiler(args.gfortran)
        version = launch([compiler,'--version'],out,10)
        assert_process(version,0)
        engines.append(('gnu',compiler))
        report['gnu_version'] = version['stdout']
    if args.candidate:
        candidate = args.candidate.resolve()
        version = launch([candidate,'--version'],out,10)
        assert_process(version,0,no_stderr=True)
        engines.append(('fortfront',candidate))
        report['candidate'] = {'path':str(candidate), 'sha256':digest(candidate.read_bytes()), 'version':version}
    assert engines, 'No compiler/interpreter selected'
    inputs = [('xmix_dt_original',None), ('xmix_dt_acos_variant',None)]
    inputs += [(c['name'],c) for c in fixture_cases]
    # Compiler executables and .mod files stay outside maintained evidence.
    with tempfile.TemporaryDirectory(prefix='normal-mixture-gnu-') as gnu_temp:
        for engine, exe in engines:
            work = out/engine
            work.mkdir(exist_ok=True)
            for name, case in inputs:
                source = src/(name+'.f90')
                if engine == 'gnu':
                    compiler_work = Path(gnu_temp)/name
                    compiler_work.mkdir(exist_ok=True)
                    program = compiler_work/name
                    check = launch([exe]+GNU_FLAGS+[source,'-o',program],compiler_work,args.timeout)
                else:
                    check = launch([exe,'--check',source],work,args.timeout)
                check_record = dict(engine=engine, name=name, phase='compile' if engine=='gnu' else 'check', process=check)
                try:
                    assert_process(check,0,no_stdout=True,no_stderr=engine=='fortfront')
                    check_record['passed'] = True
                except AssertionError as exc:
                    check_record.update(passed=False,failure=str(exc))
                report['checks'].append(check_record)
                (work/(name+'.check.json')).write_text(json.dumps(check_record,indent=2)+'\n')
                if not check_record['passed']:
                    print(f'FAIL {engine} {name} {check_record["phase"]}: {check["stderr"].strip()}',flush=True)
                    continue
                if engine == 'fortfront' and case is None:
                    default = launch([exe,source],work,args.timeout)
                    default_record = classify_default_budget(default)
                    default_record['name'] = name
                    report['default_budget_outcomes'].append(default_record)
                    (work/(name+'.default-budget.json')).write_text(json.dumps(default_record,indent=2)+'\n')
                for repeat in range(args.repeats if case is None else 1):
                    command = [program] if engine=='gnu' else [exe]+(
                        ['--max-steps',args.max_steps] if case is None else [])+[source]
                    execution_cwd = compiler_work if engine == 'gnu' else work
                    result = launch(command,execution_cwd,args.timeout)
                    record = dict(engine=engine,name=name,phase='execution',repeat=repeat+1,process=result)
                    record.update(evaluate_execution(result,engine,case))
                    report['checks'].append(record)
                    (work/(f'{name}.run{repeat+1}.json')).write_text(json.dumps(record,indent=2)+'\n')
                    (work/(f'{name}.run{repeat+1}.stdout')).write_text(result['stdout'])
                    (work/(f'{name}.run{repeat+1}.stderr')).write_text(result['stderr'])
                    print(('PASS' if record['passed'] else 'FAIL')+f' {engine} {name} run {repeat+1}'+
                          (': '+record['failure'] if not record['passed'] else ''),flush=True)
    # Recheck all maintained evidence, not merely the original input.
    prepare_sources(args.original)
    assert args.original.read_bytes() == original, 'Original source changed during execution'
    report['summary'] = {'passed':sum(c['passed'] for c in report['checks']),
                         'failed':sum(not c['passed'] for c in report['checks']),
                         'default_budget_unexpected_failures':sum(not c['accepted_observation'] for c in report['default_budget_outcomes']),
                         'full_programs':['unchanged_original','acos_only_variant'],
                         'full_program_step_budget':args.max_steps,
                         'full_random_repeats_per_engine_per_source':args.repeats,
                         'synthetic_success_cases':sum(not c['diagnostic'] for c in fixture_cases),
                         'synthetic_expected_error_cases':sum(bool(c['diagnostic']) for c in fixture_cases)}
    path = args.result.resolve() if args.result else out/'report.json'
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report['summary'],indent=2),flush=True)
    print(f'Report: {path}',flush=True)
    return 1 if report['summary']['failed'] or report['summary']['default_budget_unexpected_failures'] else 0


if __name__ == '__main__':
    sys.exit(main())
