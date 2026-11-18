#!/usr/bin/env python3
"""One explicitly authorized source adaptation; preserve the original and report stages separately."""
from pathlib import Path
import argparse,hashlib,json,subprocess,tempfile
ROOT=Path(__file__).resolve().parent
ORIGINAL_SHA='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'
WORKING_SHA='69d8d20740044c26482ff0193adc6cd5ba85aa351d5c49f04359ebee2918f914'
OLD=b':: nmax = 10**8';NEW=b':: nmax = 10**5'
GATE_LINE=3084;GATE_COLUMN=47
GATE_MESSAGE='Internal READ requires a scalar CHARACTER variable, distinct whole local numeric or CHARACTER targets and optional INTEGER IOSTAT'
def expected_diagnostic(source):
    return f'{source}:{GATE_LINE}:{GATE_COLUMN}: {GATE_MESSAGE}\n'
def matches_source_gate(got,source):
    return got['status']==1 and got['stdout']=='' and got['stderr']==expected_diagnostic(source)
def sha(data):return hashlib.sha256(data).hexdigest()
def validate_bytes(original,working):
    if sha(original)!=ORIGINAL_SHA:raise ValueError('Original utility source identity differs')
    if original.count(OLD)!=1:raise ValueError('Expected exactly one original nmax declaration')
    if working!=original.replace(OLD,NEW):raise ValueError('Working copy contains changes beyond the authorized nmax value')
    if sha(working)!=WORKING_SHA:raise ValueError('Working copy identity differs')
    differences=[i for i,(a,b) in enumerate(zip(original,working)) if a!=b]
    if len(differences)!=1 or len(original)!=len(working):raise ValueError('Expected one byte change only')
    return dict(original_sha256=sha(original),working_sha256=sha(working),bytes=len(working),byte_offset_0based=differences[0],line=original[:differences[0]].count(b'\n')+1,changed_bytes=1,crlf_preserved=original.count(b'\r\n')==working.count(b'\r\n'))
def run(args,cwd,timeout=90):
    try:
        p=subprocess.run([str(x) for x in args],cwd=cwd,stdin=subprocess.DEVNULL,capture_output=True,timeout=timeout)
        return dict(status=p.returncode,stdout=p.stdout.decode('latin1'),stderr=p.stderr.decode('latin1'))
    except subprocess.TimeoutExpired as e:
        return dict(status=None,stdout=(e.stdout or b'').decode('latin1'),stderr='TIMEOUT '+(e.stderr or b'').decode('latin1'))
    except OSError as e:return dict(status=None,stdout='',stderr=str(e))
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--candidate',type=Path);ap.add_argument('--gfortran');ap.add_argument('--result',type=Path,default=ROOT/'results.json');a=ap.parse_args()
    original=ROOT.parent/'utilities_slices/source/xutilities.f90';source=(ROOT/'xutilities-nmax-100000.f90').resolve();original_bytes=original.read_bytes();source_bytes=source.read_bytes();proof=validate_bytes(original_bytes,source_bytes);errors=[];report=dict(source_proof=proof,fortfront_claim='Expected whole-program source rejection at3000:27 internal READ from a CHARACTER array element after bounded external READ-element support; no successful full-program FortFront execution claimed',gnu_note='GNU full compile/run is independent. Explicit GNU dialect is required by GETCWD; no fallback and no cross-processor random-stream equality claim.')
    if a.candidate:
        exe=a.candidate.resolve();before=sha(exe.read_bytes());stages={}
        for name,args in [('check',['--check']),('run',['--max-steps','100000000'])]:
            got=run([exe,*args,source],ROOT);stages[name]=got
            if not matches_source_gate(got,source):errors.append('Unexpected FortFront '+name+' stage or next diagnostic')
        if sha(exe.read_bytes())!=before:errors.append('Candidate identity changed during checks')
        report['candidate_sha256']=before;report['candidate_version']=run([exe,'--version'],ROOT);report['fortfront']=stages
    if a.gfortran:
        flags=['-std=gnu','-O0','-fcheck=all','-fbacktrace','-ffree-line-length-none'];report['gnu_flags']=flags;report['gnu_version']=run([a.gfortran,'--version'],ROOT)
        with tempfile.TemporaryDirectory(prefix='utilities-working-gnu-') as tmp:
            tmp=Path(tmp);exe=tmp/'xutilities-gnu';comp=run([a.gfortran,*flags,source,'-o',exe],tmp);report['gnu_compile']=comp
            if comp['status']!=0 or comp['stdout']!='' or comp['stderr']!='':errors.append('GNU compilation failed or emitted diagnostics')
            else:
                execution=run([exe],tmp,30);report['gnu_run']=execution
                if execution['status']!=0 or execution['stderr']!='':errors.append('GNU full execution failed or emitted diagnostics')
                if execution['stdout']=='':errors.append('GNU driver produced no evidence')
    if original.read_bytes()!=original_bytes or source.read_bytes()!=source_bytes:errors.append('Original or working source changed during verification')
    report['errors']=errors;report['summary']=dict(source_proof_passed=True,candidate_checked=bool(a.candidate),gnu_checked=bool(a.gfortran),failed=len(errors));a.result.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report['summary'],indent=2));return bool(errors)
if __name__=='__main__':raise SystemExit(main())
