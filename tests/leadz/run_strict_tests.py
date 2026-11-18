#!/usr/bin/env python3
"""Strict LEADZ evidence: source identity, exact records, exact failure contracts."""
import argparse,hashlib,json,os,subprocess,tempfile,sys
from pathlib import Path
from contracts import output_matches,stage_errors,CRASH
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent))
from cli_version_contract import expected_version,version_errors

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def execute(args,cwd):
    try:
        r=subprocess.run(list(map(str,args)),capture_output=True,stdin=subprocess.DEVNULL,timeout=20,cwd=cwd,env={**os.environ,'LC_ALL':'C','LANG':'C','TZ':'UTC'})
        return {'command':list(map(str,args)),'returncode':r.returncode,'stdout':r.stdout.decode('utf8','strict'),'stderr':r.stderr.decode('utf8','strict'),'timeout':False}
    except subprocess.TimeoutExpired as e:
        return {'command':list(map(str,args)),'returncode':None,'stdout':(e.stdout or b'').decode('utf8','replace'),'stderr':(e.stderr or b'').decode('utf8','replace'),'timeout':True}

def main():
    p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path);p.add_argument('--expected-sha256');p.add_argument('--expected-version',type=expected_version);p.add_argument('--gfortran',type=Path);p.add_argument('--manifest',type=Path,default=ROOT/'manifest.json');p.add_argument('--result',type=Path,default=ROOT/'strict-results.json');a=p.parse_args()
    if not a.candidate and not a.gfortran:p.error('Specify candidate and/or gfortran')
    if a.candidate and not a.expected_sha256:p.error('--expected-sha256 required with candidate')
    if a.candidate and not a.expected_version:p.error('--expected-version required with candidate')
    identity=None
    if a.candidate:
        a.candidate=a.candidate.resolve();before=sha(a.candidate);assert before==a.expected_sha256
        version=execute([a.candidate,'--version'],ROOT);assert not version_errors(version,a.expected_version),version_errors(version,a.expected_version)
        identity={'path':str(a.candidate),'sha256_before':before,'expected_version':a.expected_version,'version':version}
    manifest=json.loads(a.manifest.read_text());rows=[]
    for case in manifest['cases']:
        source=(ROOT/case['source']).resolve();assert sha(source)==case['sha256'];r={'case':case,'errors':[]}
        if a.gfortran:
            with tempfile.TemporaryDirectory(prefix='leadz-strict-gnu-',dir=ROOT) as temp:
                exe=Path(temp)/'test';compiled=execute([a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-ffree-line-length-none','-O0',source,'-o',exe],temp);r['native_compile']=compiled
                want=1 if case['gnu']=='reject' else 0
                if compiled['returncode']!=want or compiled['timeout'] or compiled['stdout']!='' or (want and not compiled['stderr']) or CRASH.search(compiled['stderr']):r['errors'].append('GNU compile outcome')
                if case['gnu']=='execute' and compiled['returncode']==0:
                    ran=execute([exe],temp);r['native_run']=ran
                    oracle={**case,**case.get('gnu_record_contract',{})}
                    if ran['returncode']!=0 or ran['timeout'] or ran['stderr']!='' or not output_matches(oracle,ran['stdout']):r['errors'].append('GNU exact record oracle')
        if a.candidate:
            for phase in ['check','run']:
                record=execute([a.candidate]+(['--check'] if phase=='check' else [])+[source],ROOT);r[phase]=record;r['errors'] += [phase+': '+e for e in stage_errors(case,phase,record,source)]
        rows.append(r)
    if identity:
        identity['sha256_after']=sha(a.candidate);assert identity['sha256_after']==identity['sha256_before']
    result={'cases':len(rows),'failed':sum(bool(r['errors']) for r in rows),'identity':identity,'gnu_checked':bool(a.gfortran),'manifest_sha256':sha(a.manifest),'contracts_sha256':sha(ROOT/'contracts.py'),'runner_sha256':sha(Path(__file__)),'results':rows}
    a.result.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='results'},indent=2))
    for r in rows:
        if r['errors']:print(r['case']['name'],r['errors'])
    raise SystemExit(bool(result['failed']))
if __name__=='__main__':main()
