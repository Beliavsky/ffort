#!/usr/bin/env python3
"""Independent exact-record INQUIRE NAME/control/input composition checks."""
import argparse,hashlib,json,os,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0']
CRASH=('segmentation fault','sigsegv','sigabrt','backtrace','internal compiler error','program received signal','core dumped','traceback (most recent call last)','fortran runtime error')
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def require(ok,message):
    if not ok:raise ValueError(message)
def load_manifest(root=ROOT):
    rows=json.loads((root/'manifest.json').read_text());seen=set()
    for c in rows:
        require(re.fullmatch(r'[a-z][a-z0-9_]*',c['name']) is not None,'invalid case name')
        require(c['name'] not in seen,'duplicate case');seen.add(c['name'])
        require(c['mode'] in ('run','runtime','reject'),'invalid mode')
        require(c['gnu_mode'] in ('execute','compile-only','reject'),'invalid GNU mode')
        require(isinstance(c['stdout'],str),'invalid expected output')
        require(digest(root/'cases'/(c['name']+'.f90'))==c['source_sha256'],'source identity differs: '+c['name'])
        if c['mode']=='reject':require(c['stdout']=='','source rejection cannot emit stdout')
        if c['mode']!='run':
            d=c['diagnostic']
            if d is not None:
                require(isinstance(d,dict),'invalid diagnostic object')
                require(type(d['line']) is int and d['line']>0,'invalid diagnostic line')
                require(type(d['column']) is int and d['column']>0,'invalid diagnostic column')
                require(isinstance(d['message'],str) and bool(d['message']) and '\n' not in d['message'],'invalid diagnostic message')
    require({p.stem for p in (root/'cases').glob('*.f90')}==seen,'case inventory differs')
    load_inputs(root)
    return rows
def load_inputs(root=ROOT):
    rows=json.loads((root/'input-manifest.json').read_text())
    require(set(rows)=={'alpha input.dat','beta.dat'},'input inventory differs')
    require({p.name for p in (root/'inputs').iterdir()}==set(rows),'input files differ')
    seen=set()
    for name,row in rows.items():
        require(type(row['unit']) is int and row['unit']>0 and row['unit'] not in seen,'invalid input unit')
        seen.add(row['unit'])
        require(digest(root/'inputs'/name)==row['sha256'],'input bytes differ')
        require((root/'inputs'/name).stat().st_size==row['bytes'],'input length differs')
    return rows
def stage_inputs(work,root=ROOT):
    rows=load_inputs(root)
    for name in rows:(work/name).write_bytes((root/'inputs'/name).read_bytes())
    return rows
def check_inputs(work,root=ROOT):
    for name,row in load_inputs(root).items():require(digest(work/name)==row['sha256'],'registered input was changed')
def gnu_source(raw,inputs):
    marker=b'! GNU_REGISTER_INPUT'
    require(raw.count(marker)<=1,'multiple registration markers')
    setup='\n'.join("open(unit=%d,file='%s',status='old',action='read')"%(r['unit'],n) for n,r in inputs.items()).encode()
    return raw.replace(marker,setup)
def clean_result(r):
    require(type(r['returncode']) is int and r['returncode']>=0,'process signal/status')
    for key in ('stdout','stderr'):
        require(type(r[key]) is str,'invalid process stream type')
        require('\ufffd' not in r[key] and not any(0xD800<=ord(c)<=0xDFFF for c in r[key]),'corrupt process stream')
        require(not any(x in r[key].lower() for x in CRASH),'host crash/ICE marker')
    require(r.get('timeout',False) is False,'process timed out')
def expect_exact(r,code,out,err):
    clean_result(r);require(r['returncode']==code,'exit status differs')
    require(r['stdout']==out,'stdout bytes/records differ');require(r['stderr']==err,'stderr/diagnostic differs')
def diagnostic(c,source):
    d=c['diagnostic'];require(isinstance(d,dict),'candidate negative diagnostic not pinned');return f"{source}:{d['line']}:{d['column']}: {d['message']}\n"
def validate_candidate(c,source,check,run):
    if c['mode']=='reject':
        err=diagnostic(c,source);expect_exact(check,1,'',err);expect_exact(run,1,'',err)
    else:
        expect_exact(check,0,'','')
        if c['mode']=='run':expect_exact(run,0,c['stdout'],'')
        else:expect_exact(run,2,c['stdout'],diagnostic(c,source))
def validate_gnu(c,compiled,executed=None):
    clean_result(compiled)
    if c['gnu_mode']=='reject':
        require(compiled['returncode']==1 and not compiled['stdout'],'GNU rejection status/stdout')
        require(re.search(c['gnu_diagnostic'],compiled['stderr']) is not None,'GNU named rejection absent')
        require(re.search(r'oracle\.f90:[1-9][0-9]*:[1-9][0-9]*:',compiled['stderr']) is not None,'GNU source location absent')
        require(executed is None,'GNU invalid program was executed')
    else:
        expect_exact(compiled,0,'','')
        if c['gnu_mode']=='execute':
            require(executed is not None,'GNU run missing');expect_exact(executed,0,c['stdout'],'')
        else:require(executed is None,'GNU compile-only source was executed')
def validate_version(r,version):
    clean_result(r);require(r['returncode']==0 and not r['stderr'],'version query failed')
    if version:require(re.fullmatch(r'fortfront-interpreter '+re.escape(version)+r'; FortFront [0-9a-f]+ \+ documented local patches\n',r['stdout']) is not None,'version banner differs')
def invoke(cmd,cwd):
    try:
        r=subprocess.run(cmd,cwd=cwd,capture_output=True,timeout=20,env=dict(os.environ,LC_ALL='C'))
        return dict(returncode=r.returncode,stdout=r.stdout.decode('utf-8'),stderr=r.stderr.decode('utf-8'),timeout=False)
    except subprocess.TimeoutExpired as e:
        return dict(returncode=None,stdout=(e.stdout or b'').decode('utf-8',errors='replace'),stderr=(e.stderr or b'').decode('utf-8',errors='replace'),timeout=True)
def main():
    p=argparse.ArgumentParser();p.add_argument('--candidate');p.add_argument('--gfortran',default='gfortran');p.add_argument('--expected-sha256');p.add_argument('--expected-version');p.add_argument('--output',default=str(ROOT/'results.json'));p.add_argument('--observe',action='store_true');p.add_argument('--optimize',action='store_true');args=p.parse_args()
    output=Path(args.output);require(not output.exists(),'refusing to overwrite prior evidence')
    exe=Path(args.candidate).resolve() if args.candidate else None
    before=digest(exe) if exe else None
    if exe:require(args.expected_sha256==before,'candidate identity differs or is unpinned')
    version_before=invoke([str(exe),'--version'],str(ROOT)) if exe else None
    if exe:validate_version(version_before,args.expected_version)
    flags=[x if x!='-O0' or not args.optimize else '-O2' for x in FLAGS]
    results=[];rows=load_manifest();inputs=load_inputs();first_manifest=digest(ROOT/'manifest.json')
    for c in rows:
        src=(ROOT/'cases'/(c['name']+'.f90')).resolve();r={'name':c['name'],'source_sha256':digest(src),'passed':False}
        try:
            if exe:
                with tempfile.TemporaryDirectory(prefix='ff054-candidate-')as td:
                    work=Path(td);stage_inputs(work)
                    bindings=[]
                    for name,row in inputs.items():bindings+=['--input',str(row['unit'])+'='+name]
                    r['check']=invoke([str(exe),'--check',*bindings,str(src)],td)
                    r['run']=invoke([str(exe),*bindings,str(src)],td)
                    check_inputs(work);require({x.name for x in work.iterdir()}==set(inputs),'unexpected candidate file output')
            with tempfile.TemporaryDirectory(prefix='ff054-gnu-')as td:
                work=Path(td);stage_inputs(work);adapted=gnu_source(src.read_bytes(),inputs)
                oracle=work/'oracle.f90';oracle.write_bytes(adapted)
                r['oracle_source']=adapted.decode();r['oracle_sha256']=digest(oracle)
                r['gnu_compile']=invoke([args.gfortran,*flags,str(oracle),'-o',str(work/'oracle')],td)
                if c['gnu_mode']=='execute' and r['gnu_compile']['returncode']==0:r['gnu_run']=invoke([str(work/'oracle')],td)
                check_inputs(work)
            validate_gnu(c,r['gnu_compile'],r.get('gnu_run'))
            if exe and not args.observe:validate_candidate(c,str(src),r['check'],r['run'])
            r['passed']=True
        except (ValueError,subprocess.TimeoutExpired,UnicodeError,KeyError,OSError)as e:r['error']=str(e)
        results.append(r)
    missing_check=None
    if exe:
        src=(ROOT/'cases'/(rows[0]['name']+'.f90')).resolve()
        with tempfile.TemporaryDirectory(prefix='ff054-no-open-')as td:
            missing_check=invoke([str(exe),'--check','--input','17=does-not-exist.dat',str(src)],td)
            require(not list(Path(td).iterdir()),'check created files')
            expect_exact(missing_check,0,'','')
    after=digest(exe) if exe else None
    require(after==before,'candidate changed during run');load_manifest()
    require(digest(ROOT/'manifest.json')==first_manifest,'manifest changed during run')
    version_after=invoke([str(exe),'--version'],str(ROOT)) if exe else None
    require(version_after==version_before,'candidate version output changed')
    result=dict(version_before=version_before,version_after=version_after,executable=str(exe) if exe else None,executable_sha256_before=before,executable_sha256_after=after,compiler=args.gfortran,compiler_version=invoke([args.gfortran,'--version'],str(ROOT)),compiler_flags=flags,manifest_sha256=first_manifest,input_manifest_sha256=digest(ROOT/'input-manifest.json'),candidate_validation=('observed_only' if args.observe else 'strict') if exe else 'not_run',cases=results,check_missing_input_without_open=missing_check,passed=all(r['passed']for r in results))
    output.write_text(json.dumps(result,indent=2)+'\n');require(result['passed'],'failed cases: '+', '.join(r['name']for r in results if not r['passed']))
    print(f'PASS {len(results)} GNU profiles; candidate validation: '+result['candidate_validation'])
if __name__=='__main__':main()
