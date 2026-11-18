#!/usr/bin/env python3
"""Strict, identity-bound runner. Observation never certifies negative diagnostics."""
from pathlib import Path
import argparse,base64,hashlib,json,os,subprocess,tempfile
from contracts import (require,sha,digest,HASH,VERSION,load_json,validate_manifest,
                       stage_errors,gnu_errors,version_errors)
ROOT=Path(__file__).resolve().parent
POLICY=('contracts.py','run_tests.py','test_contracts.py','test_hardening.py')
GNU_FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-ffree-line-length-none','-O0']

def file_identities(paths):return {str(Path(p).resolve()):sha(Path(p)) for p in paths}
def verify_identities(before):
    for p,h in before.items():require(Path(p).is_file() and sha(Path(p))==h,'Identity changed: '+p)

def new_output_path(path,root=ROOT):
    path=Path(path).absolute()
    require(all(not p.is_symlink() for p in [path,*path.parents]),'Output/ancestor symlink forbidden')
    require(not path.exists(),'Output must be new; prior evidence is immutable')
    path=path.resolve();root=Path(root).resolve()
    require(path!=root and root not in path.parents and path not in root.parents,'Output outside policy/source tree')
    return path

def call(argv,cwd):
    argv=list(map(str,argv));timeout=False
    try:
        p=subprocess.run(argv,cwd=cwd,stdin=subprocess.DEVNULL,capture_output=True,timeout=20,env={**os.environ,'LC_ALL':'C','LANG':'C','TZ':'UTC'})
        code=p.returncode;out=p.stdout;err=p.stderr
    except subprocess.TimeoutExpired as e:
        timeout=True;code=None;out=e.stdout or b'';err=e.stderr or b''
    valid=True
    try:o=out.decode('utf8');e=err.decode('utf8')
    except UnicodeDecodeError:valid=False;o=out.decode('utf8','replace');e=err.decode('utf8','replace')
    return {'command':argv,'returncode':code,'stdout':o,'stderr':e,'timeout':timeout,'valid_utf8':valid,'stdout_sha256':digest(out),'stderr_sha256':digest(err),'stdout_base64':base64.b64encode(out).decode(),'stderr_base64':base64.b64encode(err).decode()}

def version_identity(executable,expected_hash,output,**contract):
    require(isinstance(expected_hash,str) and HASH.fullmatch(expected_hash),'Explicit executable SHA-256 required')
    require(sha(executable)==expected_hash,'Executable hash mismatch')
    argv=[str(executable),'--version'];v=call(argv,output)
    require(not version_errors(v,command=argv,**contract),'Exact version process/banner contract')
    require(sha(executable)==expected_hash,'Executable changed during version query')
    return {'sha256':expected_hash,'version':v}

def recheck_version(executable,before,output,**contract):
    after=version_identity(executable,before['sha256'],output,**contract)
    require(after==before,'Executable/version identity changed')
    return after

def main():
    p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path);p.add_argument('--expected-sha256');p.add_argument('--expected-version')
    p.add_argument('--gfortran',type=Path);p.add_argument('--expected-gfortran-sha256');p.add_argument('--expected-gfortran-version-sha256')
    p.add_argument('--manifest',type=Path,default=ROOT/'manifest.json');p.add_argument('--expected-manifest-sha256',required=True)
    p.add_argument('--output',type=Path,required=True);p.add_argument('--observe-negative',action='store_true');a=p.parse_args()
    require(a.candidate is not None or a.gfortran is not None,'Choose explicit candidate and/or GNU')
    require(not a.observe_negative or a.candidate is not None,'Observation requires candidate')
    a.output=new_output_path(a.output)
    require(not a.manifest.is_symlink(),'Manifest symlink');a.manifest=a.manifest.resolve();require(a.manifest.parent==ROOT,'Manifest containment')
    require(isinstance(a.expected_manifest_sha256,str) and HASH.fullmatch(a.expected_manifest_sha256) and sha(a.manifest)==a.expected_manifest_sha256,'Explicit manifest identity')
    protected=file_identities([*(ROOT/x for x in POLICY),a.manifest])
    manifest=load_json(a.manifest);source_map=validate_manifest(manifest,ROOT,final=bool(a.candidate and not a.observe_negative))
    protected.update(file_identities(ROOT/s for s in source_map))
    if a.candidate:
        require(isinstance(a.expected_version,str) and VERSION.fullmatch(a.expected_version),'Exact candidate version required');a.candidate=a.candidate.resolve()
    if a.gfortran:
        require(isinstance(a.expected_gfortran_version_sha256,str) and HASH.fullmatch(a.expected_gfortran_version_sha256),'Explicit GNU banner SHA required');a.gfortran=a.gfortran.resolve()
    a.output.mkdir(parents=True)
    identity=version_identity(a.candidate,a.expected_sha256,a.output,expected_version=a.expected_version) if a.candidate else None
    compiler=version_identity(a.gfortran,a.expected_gfortran_sha256,a.output,gnu_stdout_sha256=a.expected_gfortran_version_sha256) if a.gfortran else None
    (a.output/'identities-before.json').write_text(json.dumps({'candidate':identity,'compiler':compiler,'protected':protected},indent=2)+'\n')
    rows=[]
    for c in manifest['cases']:
        verify_identities(protected)
        source=(ROOT/c['source']).resolve();r={'case':c,'errors':[]};work=a.output/c['name'];work.mkdir()
        if a.gfortran:
            require(sha(a.gfortran)==compiler['sha256'],'GNU changed before case')
            with tempfile.TemporaryDirectory(prefix='trailz-gnu-') as temp:
                exe=Path(temp)/'oracle';argv=[a.gfortran,*GNU_FLAGS,source,'-o',exe]
                comp=call(argv,temp);r['native_compile']=comp
                errors=gnu_errors(c,'compile',comp,command=argv);r['errors'] += ['GNU compile: '+e for e in errors]
                if c['gnu']=='execute' and not errors:
                    run=call([exe],temp);r['native_run']=run
                    r['errors'] += ['GNU run: '+e for e in gnu_errors(c,'run',run,command=[exe])]
            require(sha(a.gfortran)==compiler['sha256'],'GNU changed during case')
        if a.candidate:
            require(sha(a.candidate)==identity['sha256'],'CLI changed before case')
            for phase in ['check','run']:
                argv=[a.candidate,*(['--check'] if phase=='check' else ['--max-steps','10000000']),source]
                record=call(argv,work);r[phase]=record
                r['errors'] += [phase+': '+e for e in stage_errors(c,phase,record,source,a.observe_negative,command=argv)]
            require(sha(a.candidate)==identity['sha256'],'CLI changed during case')
        for phase in ['check','run','native_compile','native_run']:
            if phase not in r:continue
            for stream in ['stdout','stderr']:(work/(phase+'.'+stream)).write_bytes(base64.b64decode(r[phase][stream+'_base64'],validate=True))
        verify_identities(protected);rows.append(r)
        (a.output/'results.partial.json').write_text(json.dumps(rows,indent=2)+'\n')
    candidate_after=recheck_version(a.candidate,identity,a.output,expected_version=a.expected_version) if identity else None
    compiler_after=recheck_version(a.gfortran,compiler,a.output,gnu_stdout_sha256=a.expected_gfortran_version_sha256) if compiler else None
    require(validate_manifest(load_json(a.manifest),ROOT,final=bool(a.candidate and not a.observe_negative))==source_map,'Source inventory changed')
    verify_identities(protected)
    failed=sum(bool(r['errors']) for r in rows)
    result={'cases':len(rows),'failed':failed,'identity_before':identity,'identity_after':candidate_after,'compiler_before':compiler,'compiler_after':compiler_after,'protected_before':protected,'protected_after':file_identities(protected),'gnu_flags':GNU_FLAGS,'step_budget':10000000,'negative_diagnostics_observation_only':a.observe_negative,'final_diagnostic_certification':bool(a.candidate and not a.observe_negative and failed==0),'manifest_sha256':a.expected_manifest_sha256,'results':rows}
    (a.output/'results.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k not in {'results','protected_before','protected_after'}},indent=2))
    for r in rows:
        if r['errors']:print(r['case']['name'],r['errors'])
    raise SystemExit(bool(failed))
if __name__=='__main__':main()
