#!/usr/bin/env python3
"""Record the isolated GNU optional-KIND rounding observation without relaxing tests."""
from pathlib import Path
import argparse,hashlib,json,subprocess,tempfile
ROOT=Path(__file__).resolve().parent

def execute(argv):
    p=subprocess.run(list(map(str,argv)),text=True,capture_output=True,timeout=30,stdin=subprocess.DEVNULL)
    return dict(argv=list(map(str,argv)),exit=p.returncode,stdout=p.stdout,stderr=p.stderr)

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--gfortran',required=True);ap.add_argument('--candidate',required=True)
    ap.add_argument('--result',default='gnu14-receipt.json');a=ap.parse_args()
    source=ROOT/'narrow_result.f90';candidate=Path(a.candidate).resolve()
    flags=['-std=f2018','-pedantic-errors','-fcheck=all']
    receipt=dict(source=source.name,sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                 GNU_version=execute([a.gfortran,'--version'])['stdout'],flags=flags,GNU=[])
    for optimization in ('-O0','-O2'):
        with tempfile.TemporaryDirectory(prefix='rounding-observation-') as td:
            exe=Path(td)/'reference';compiled=execute([a.gfortran,*flags,optimization,source,'-o',exe])
            if compiled['exit']:raise SystemExit('GNU probe compilation failed: '+compiled['stderr'])
            ran=execute([exe]);receipt['GNU'].append(dict(compile=compiled,run=ran))
            if ran['exit'] or ran['stderr'].strip():raise SystemExit('GNU probe execution failed')
    result=execute([candidate,source]);receipt['candidate']=result
    receipt['candidate_sha256']=hashlib.sha256(candidate.read_bytes()).hexdigest()
    expected=[0.,0.,1.,-1.,0.,0.,2.,-2.,1.,0.,0.,0.,1.,-1.,0.,0.,2.,-2.]
    if result['exit'] or result['stderr'].strip() or list(map(float,result['stdout'].split()))!=expected:
        raise SystemExit('Candidate differs from independent round-then-convert expectation')
    receipt['interpretation']='Runtime GNU optional-KIND results are retained as observation only. Independent candidate expectation rounds the input before result conversion; no generic comparator is changed.'
    (ROOT/a.result).write_text(json.dumps(receipt,indent=2)+'\n')
    print('Recorded -O0/-O2 GNU observation and verified independent candidate expectation')
if __name__=='__main__':main()
