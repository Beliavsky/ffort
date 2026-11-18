#!/usr/bin/env python3
"""Linux/GNU disk-bounded native verification, using FPM's exact object commands.

The normal portable verifier still uses fpm test. This opt-in profile compiles
all FPM-discovered test programs unchanged, links them to one shared copy of the
same PIC archive, and executes every program. It preserves all generated files.
"""
from pathlib import Path
import argparse, datetime, hashlib, json, os, shlex, subprocess, sys
ROOT = Path(__file__).resolve().parent.parent
STATIC_COMPARISONS = {
    'test_process_queries', 'test_external_read_metadata', 'test_external_read_runtime',
    'test_matrix_norm_intrinsics', 'test_position_formats',
    'test_pointer_runtime_metadata', 'test_lexical_comparisons',
}

def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def reject_overrides(args):
    """Fail closed for known disabling flags; never rewrite FPM's argv.

    Reject these even before an enabling flag rather than trying to emulate
    compiler option precedence. Response files could hide overrides as well.
    """
    for arg in args:
        lower = arg.lower()
        if (arg.startswith('@') or lower in {
                '-g0', '-ggdb0', '-fno-pic', '-fno-pie', '-fpie',
                '-fno-backtrace', '-fno-bounds-check', '-fno-implicit-none', '-w',
                '-wno-implicit-interface',
                '-wno-error', '-wno-error=implicit-interface'}
                or lower.startswith('-fno-check')
                or (lower.startswith('-fcheck=') and
                    any(x.startswith('no-') for x in lower.split('=', 1)[1].split(',')))
                or (lower.startswith('-fcoarray=') and lower != '-fcoarray=single')):
            raise ValueError('Unsupported override of debug/PIC checks: '+arg)

def plan(model, commands):
    if model.get('target-os') != 'Linux' or model['compiler']['fc'] != 'gfortran':
        raise ValueError('Shared native verification requires Linux/gfortran')
    if str(model.get('link-flags', '')).strip() or model.get('link-libraries', []):
        raise ValueError('Shared native verification cannot preserve extra link flags/libraries')
    flags = shlex.split(model['fortran-flags'])
    reject_overrides(flags)
    for flag in ['-g', '-fPIC', '-fcheck=bounds', '-fcheck=array-temps', '-fbacktrace']:
        if flag not in flags:
            raise ValueError('Missing standard debug flag: '+flag)
    sources = model['packages']['fortfront-interpreter']['sources'].values()
    tests = [s for s in sources if s.get('unit-scope') == 'FPM_SCOPE_TEST']
    if not tests or any(s['unit-type'] != 'FPM_UNIT_PROGRAM' for s in tests):
        raise ValueError('Every test source must be a separately discovered program')
    by_source = {}
    for c in commands:
        if c['file'] in by_source:
            raise ValueError('Duplicate compile source: '+c['file'])
        by_source[c['file']] = c
    result = []
    names = set()
    for s in sorted(tests, key=lambda s:s['exe-name']):
        name, source = s['exe-name'], s['file-name']
        if name in names or not name.replace('_','').isalnum():
            raise ValueError('Invalid or duplicate test name')
        names.add(name)
        c = by_source[source]; args = c['arguments']
        reject_overrides(args)
        if args[:3] != ['gfortran','-c',source] or '-o' not in args:
            raise ValueError('Unexpected FPM compile command')
        for flag in flags + ['-fimplicit-none', '-Werror=implicit-interface']:
            if flag not in args:
                raise ValueError('Native compile command lost '+flag)
        result.append({'name':name,'source':source,'compile':args,'object':args[args.index('-o')+1]})
    return flags, result

def verify(a, out):
    profile=['--profile','debug']+(['--flag','-gsplit-dwarf'] if a.split_debug else [])
    modelpath=out/'fpm-model.json'
    cmd=['fpm','build',*profile,'--tests','--list','--dump',str(modelpath)]
    scan=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True)
    (out/'fpm-discovery.log').write_text(scan.stdout+scan.stderr)
    if scan.returncode: raise RuntimeError('FPM discovery failed')
    model=json.loads(modelpath.read_text())
    commands=json.loads((ROOT/'build/compile_commands.json').read_text())
    flags,tests=plan(model,commands)
    discovered={x['source'] for x in tests}
    if not STATIC_COMPARISONS.issubset({x['name'] for x in tests}):
        raise RuntimeError('A required static/shared comparison target is missing')
    present={p.relative_to(ROOT).as_posix() for p in (ROOT/'test').glob('*.f90')}
    if discovered != present: raise RuntimeError('FPM/native source inventory mismatch')
    libraries=list((ROOT/'build').glob('*/fortfront-interpreter/libfortfront-interpreter.a'))
    if len(libraries)!=1: raise RuntimeError('Expected exactly one selected app/library profile')
    library=libraries[0]; library_hash=digest(library)
    shared=out/'libfortfront_verify.so'
    rows=[];start=datetime.datetime.now(datetime.timezone.utc).isoformat()
    def run(command,log):
        p=subprocess.run(list(map(str,command)),cwd=ROOT,capture_output=True,timeout=240)
        (out/(log+'.stdout')).write_bytes(p.stdout);(out/(log+'.stderr')).write_bytes(p.stderr)
        return {'command':list(map(str,command)),'status':p.returncode,'stdout_sha256':hashlib.sha256(p.stdout).hexdigest(),'stderr_sha256':hashlib.sha256(p.stderr).hexdigest(),'stdout_bytes':len(p.stdout),'stderr_bytes':len(p.stderr)},p
    link=[model['compiler']['fc'],*flags,'-shared','-Wl,-z,defs','-Wl,-soname,libfortfront_verify.so','-Wl,--whole-archive',library,'-Wl,--no-whole-archive','-o',shared]
    shared_record,p=run(link,'shared-library-link')
    if p.returncode: raise RuntimeError('Shared library link failed')
    (out/'test').mkdir(exist_ok=True);(out/'static-comparison').mkdir(exist_ok=True)
    def receipt(finalized=False):
        obj={'status':'passed' if finalized and len(rows)==len(tests) and all(x.get('passed') for x in rows) else 'running',
             'archive_rechecked':finalized,
             'started_utc':start,'updated_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
             'profile':profile,'fpm_discovery_command':cmd,'native_total':len(tests),'executed':len(rows),
             'archive':str(library.relative_to(ROOT)),'archive_sha256':library_hash,
             'shared_library_sha256':digest(shared),'shared_library_link':shared_record,
             'compiler_flags':flags,'static_comparison_names':sorted(STATIC_COMPARISONS & {x['name'] for x in tests}),
             'test_records':rows,'same_binary_claimed':False}
        (out/'results.json').write_text(json.dumps(obj,indent=2)+'\n')
    for t in tests:
        row=dict(t,source_sha256=digest(ROOT/t['source']))
        obj=ROOT/t['object'];obj.parent.mkdir(parents=True,exist_ok=True)
        row['compile_record'],p=run(t['compile'],t['name']+'-compile')
        if p.returncode: rows.append(row);receipt();raise RuntimeError('Native compilation failed: '+t['name'])
        row['object_sha256']=digest(obj)
        exe=out/'test'/t['name']
        row['link_record'],p=run([model['compiler']['fc'],*flags,obj,'-L'+str(out),'-lfortfront_verify','-Wl,-rpath,$ORIGIN/..','-o',exe],t['name']+'-link')
        if p.returncode:rows.append(row);receipt();raise RuntimeError('Native link failed: '+t['name'])
        row['binary_sha256']=digest(exe);row['binary_bytes']=exe.stat().st_size
        row['execution'],run_result=run([exe],t['name']+'-run')
        row['passed']=run_result.returncode==0
        if t['name'] in STATIC_COMPARISONS:
            static=out/'static-comparison'/t['name']
            row['static_link'],p=run([model['compiler']['fc'],*flags,obj,library,'-o',static],t['name']+'-static-link')
            if p.returncode:row['passed']=False
            else:
                row['static_binary_sha256']=digest(static)
                row['static_execution'],p=run([static],t['name']+'-static-run')
                row['static_shared_behavior_equal']=(p.returncode,p.stdout,p.stderr)==(run_result.returncode,run_result.stdout,run_result.stderr)
                row['passed'] &= row['static_shared_behavior_equal']
        rows.append(row);receipt()
        print(t['name']+': '+('PASS' if row['passed'] else 'FAIL'),flush=True)
        if not row['passed']:raise RuntimeError('Native test or static/shared comparison failed: '+t['name'])
    if digest(library)!=library_hash:raise RuntimeError('Archive changed during verification')
    receipt(finalized=True);print('PASS all',len(tests),'FPM-discovered native programs; artifacts retained')

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--split-debug',action='store_true')
    a=ap.parse_args()
    if not sys.platform.startswith('linux'):
        ap.error('Shared native verification is validated only on Linux/GNU')
    out=ROOT/'build/verification_shared_native'; out.mkdir(parents=True,exist_ok=True)
    path=out/'results.json'
    # Invalidate a prior success before discovery, linking or any other work.
    path.write_text(json.dumps({'status':'running', 'archive_rechecked':False})+'\n')
    try:
        verify(a, out)
    except BaseException as exc:
        # Retain completed records, including for timeout/launch/hash failures.
        try:
            obj=json.loads(path.read_text())
        except (OSError, ValueError):
            obj={}
        obj.update(status='failed', archive_rechecked=False,
                   error_type=type(exc).__name__, error=str(exc))
        path.write_text(json.dumps(obj,indent=2)+'\n')
        raise

if __name__=='__main__':main()
