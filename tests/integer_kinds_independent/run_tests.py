#!/usr/bin/env python3
"""Portable exact INTEGER-kind differential and safety-policy checks."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0']
def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def execute(argv,cwd=None,timeout=20):
    try:
        p=subprocess.run([str(x) for x in argv],cwd=cwd or ROOT,capture_output=True,text=True,timeout=timeout,stdin=subprocess.DEVNULL)
        return dict(code=p.returncode,out=p.stdout,err=p.stderr)
    except subprocess.TimeoutExpired: return dict(code=None,out='',err='TIMEOUT')
    except OSError as e: return dict(code=None,out='',err=str(e))
def compare(actual,expected):
    # Never round integer output through binary floating point.
    return actual.split()==expected.split()
def candidate_errors(case,check,run):
    errors=[];category=case['category']
    codes=(0,0) if category=='success' else (0,2) if category=='runtime' else (1,1)
    for label,r,code in [('check',check,codes[0]),('run',run,codes[1])]:
        if r['code']!=code: errors.append(f'{label}: expected exit {code}, got {r["code"]}')
        if code and not r['err'].strip(): errors.append(label+': missing diagnostic')
        if not code and r['err'].strip(): errors.append(label+': unexpected diagnostic')
    if check['out'].strip(): errors.append('check stdout leak')
    if not compare(run['out'],case['expected_stdout']): errors.append('run stdout mismatch/leak')
    if case.get('diagnostic'):
        diagnostic='\n'.join(re.sub(r'^.*?:\d+:\d+:','',line) for line in run['err'].splitlines())
        if case['diagnostic'].lower() not in diagnostic.lower(): errors.append('missing expected diagnostic')
    return errors

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--candidate');ap.add_argument('--gfortran');ap.add_argument('--only',default='');ap.add_argument('--result',default='results.json');args=ap.parse_args()
    if not args.candidate and not args.gfortran: ap.error('Supply --candidate and/or --gfortran')
    records=[];tools={};candidate_hash=None
    with tempfile.TemporaryDirectory(prefix='integer-verification-') as temp:
        folder=Path(temp);candidate=None
        if args.candidate:
            original=Path(args.candidate).resolve();candidate=folder/original.name;shutil.copy2(original,candidate)
            candidate_hash=sha(candidate);tools['candidate']=dict(path=str(original),sha256=candidate_hash,version=execute([candidate,'--version']))
        if args.gfortran: tools['gfortran']=dict(path=args.gfortran,version=execute([args.gfortran,'--version']))
        for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
            if not re.search(args.only,case['name']):continue
            source=ROOT/case['source'];row=dict(case=case,errors=[],source_sha256=sha(source))
            if args.gfortran:
                if case['baseline']=='skip':row['gnu_skipped']=case['baseline_note']
                else:
                    binary=folder/('reference.exe' if __import__('os').name=='nt' else 'reference')
                    compiled=execute([args.gfortran,*FLAGS,source,'-o',binary],folder);row['gnu_compile']=compiled
                    if compiled['code']!=0:row['errors'].append('GNU compilation failed')
                    elif case['baseline']=='run':
                        run=execute([binary],folder);row['gnu_run']=run
                        if run['code']!=0 or run['err'].strip():row['errors'].append('GNU execution failed or diagnosed')
                        if not compare(run['out'],case.get('expected_gnu_stdout',case['expected_stdout'])):row['errors'].append('GNU stdout mismatch')
            if candidate:
                row['check']=execute([candidate,'--check',source]);row['run']=execute([candidate,source])
                row['errors']+=candidate_errors(case,row['check'],row['run'])
            print(case['name']+(': FAIL '+', '.join(row['errors']) if row['errors'] else ': PASS'),flush=True);records.append(row)
        if not records:ap.error('No cases selected')
        if candidate and sha(candidate)!=candidate_hash:raise RuntimeError('Candidate snapshot changed during verification')
    summary=dict(total=len(records),failed=sum(bool(r['errors']) for r in records),candidate_checked=len(records) if args.candidate else 0,gnu_executed=sum('gnu_run' in r for r in records),gnu_compiled=sum('gnu_compile' in r for r in records),gnu_skipped=sum('gnu_skipped' in r for r in records))
    report=dict(summary=summary,records=records,tools=tools,compiler_flags=FLAGS,candidate_sha256=candidate_hash,manifest_sha256=sha(ROOT/'manifest.json'),source_sha256={r['case']['source']:r['source_sha256'] for r in records},utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    (ROOT/args.result).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(summary));return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
