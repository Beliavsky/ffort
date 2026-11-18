#!/usr/bin/env python3
"""Exact-record cross-control checks. Reconstructed runner; fresh execution required."""
import argparse,hashlib,json,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0']
CRASH=('segmentation fault','sigsegv','sigabrt','backtrace','internal compiler error','program received signal','core dumped')
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def require(ok,message):
    if not ok:raise ValueError(message)
def load_manifest(root=ROOT):
    rows=json.loads((root/'manifest.json').read_text());seen=set()
    for c in rows:
        require(re.fullmatch(r'[a-z][a-z0-9_]*',c['name']) is not None,'invalid case name')
        require(c['name'] not in seen,'duplicate case');seen.add(c['name'])
        require(c['mode'] in ('run','runtime','reject'),'invalid mode')
        require(digest(root/'cases'/(c['name']+'.f90'))==c['source_sha256'],'source identity differs: '+c['name'])
    require({p.stem for p in (root/'cases').glob('*.f90')}==seen,'case inventory differs')
    return rows
def clean_result(r):
    require(type(r['returncode']) is int and r['returncode']>=0,'process signal/status')
    require(not any(x in r['stderr'].lower()for x in CRASH),'host crash/ICE marker')
def expect_exact(r,code,out,err):
    clean_result(r);require(r['returncode']==code,'exit status differs')
    require(r['stdout']==out,'stdout bytes/records differ');require(r['stderr']==err,'stderr/diagnostic differs')
def diagnostic(c,source):
    d=c['diagnostic'];return f"{source}:{d['line']}:{d['column']}: {d['message']}\n"
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
        require(executed is None,'GNU invalid program was executed')
    else:
        expect_exact(compiled,0,'','')
        if c['gnu_mode']=='execute':
            require(executed is not None,'GNU run missing');expect_exact(executed,0,c['stdout'],'')
        else:require(executed is None,'GNU compile-only source was executed')
def invoke(cmd,cwd):
    r=subprocess.run(cmd,cwd=cwd,capture_output=True,timeout=20)
    return dict(returncode=r.returncode,stdout=r.stdout.decode('utf-8'),stderr=r.stderr.decode('utf-8'))
def main():
    p=argparse.ArgumentParser();p.add_argument('--candidate',required=True);p.add_argument('--gfortran',default='gfortran');p.add_argument('--expected-sha256');p.add_argument('--output',default=str(ROOT/'results.json'));args=p.parse_args()
    exe=Path(args.candidate).resolve();before=digest(exe)
    if args.expected_sha256:require(before==args.expected_sha256,'candidate identity differs')
    results=[]
    for c in load_manifest():
        src=(ROOT/'cases'/(c['name']+'.f90')).resolve();r={'name':c['name'],'source_sha256':digest(src),'passed':False}
        try:
            with tempfile.TemporaryDirectory(prefix='ff051-candidate-')as td:
                r['check']=invoke([str(exe),'--check',str(src)],td);r['run']=invoke([str(exe),'--max-steps','200',str(src)],td)
                require(not list(Path(td).iterdir()),'unexpected candidate file output')
            with tempfile.TemporaryDirectory(prefix='ff051-gnu-')as td:
                r['gnu_compile']=invoke([args.gfortran,*FLAGS,str(src),'-o',str(Path(td)/'oracle')],td)
                if c['gnu_mode']=='execute' and r['gnu_compile']['returncode']==0:r['gnu_run']=invoke([str(Path(td)/'oracle')],td)
            validate_gnu(c,r['gnu_compile'],r.get('gnu_run'));validate_candidate(c,str(src),r['check'],r['run']);r['passed']=True
        except (ValueError,subprocess.TimeoutExpired,UnicodeError)as e:r['error']=str(e)
        results.append(r)
    after=digest(exe);require(after==before,'candidate changed during run');load_manifest()
    result=dict(executable=str(exe),executable_sha256_before=before,executable_sha256_after=after,compiler=args.gfortran,compiler_flags=FLAGS,cases=results,passed=all(r['passed']for r in results))
    Path(args.output).write_text(json.dumps(result,indent=2)+'\n');require(result['passed'],'failed cases: '+', '.join(r['name']for r in results if not r['passed']))
    print(f'PASS {len(results)} release051 profiles: 8 GNU executions, 1 compile-only, 1 GNU rejection')
if __name__=='__main__':main()
