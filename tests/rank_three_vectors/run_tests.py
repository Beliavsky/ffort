"""Byte-exact rank-three gather contract; pending diagnostics never silently pass."""
from pathlib import Path
import argparse,json,hashlib,re,subprocess,tempfile
R=Path(__file__).resolve().parent
CRASH=re.compile(r'backtrace|traceback|internal compiler error|fortran runtime error|segmentation|SIGSEGV|SIGABRT|TIMEOUT',re.I)
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0']
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def run(args,cwd):
 try:
  p=subprocess.run(list(map(str,args)),cwd=cwd,capture_output=True,timeout=40,stdin=subprocess.DEVNULL)
  return dict(code=p.returncode,out=p.stdout.decode('latin1'),err=p.stderr.decode('latin1'))
 except (OSError,subprocess.TimeoutExpired) as e:return dict(code=None,out='',err=str(e))
def candidate_errors(c,source,check,ran):
 stage=c['stage'];errors=[]
 if stage not in ('success','runtime','compile'):return ['unknown stage']
 diagnostic=c.get('diagnostic')
 if stage!='success' and (not isinstance(diagnostic,str) or not re.fullmatch(r'[1-9]\d*:[1-9]\d*: [^\r\n]+',diagnostic)):
  return ['candidate diagnostic is not pinned']
 stderr=str(source)+':'+diagnostic+'\n' if stage!='success' else ''
 expected_check=dict(code=1,out='',err=stderr) if stage=='compile' else dict(code=0,out='',err='')
 if check!=expected_check:errors.append('check stage/streams differ')
 expected=dict(code={'success':0,'runtime':2,'compile':1}[stage],out=c['expected'],err=stderr)
 if ran!=expected:errors.append('execution stage/streams differ')
 return errors
def gnu_errors(c,compiled,ran):
 if CRASH.search(compiled['err']+compiled['out']):return ['GNU crash marker']
 if c['gnu']=='reject':
  if compiled['code']!=1 or compiled['out'] or 'Non-variable expression in variable definition context' not in compiled['err'] or ran is not None:
   return ['GNU ordinary constraint rejection differs']
  return []
 if compiled!=dict(code=0,out='',err=''):return ['GNU compilation differs']
 if c['gnu']=='run':
  if ran!=dict(code=0,out=c.get('gnu_expected',c['expected']),err=''):return ['GNU exact execution differs']
 elif c['gnu']=='compile':
  if ran is not None:return ['compile-only case must not run']
 else:return ['unknown GNU stage']
 return []
def check_provenance():
 meta=json.loads((R/'provenance.json').read_text());raw=(R/'source/exact_closure.f90').read_bytes()
 for body in meta['bodies']:
  name=body['name'].encode();match=re.search(rb'(?mi)^(?:elemental )?subroutine '+name+rb'\b.*?^end subroutine '+name+rb'[^\r\n]*\r?\n',raw,re.S)
  assert match and len(match.group())==body['bytes'] and hashlib.sha256(match.group()).hexdigest()==body['sha256'],body['name']
 for p in (R/'cases').glob('original_*.f90'):assert p.read_bytes().startswith(raw),p
 return True
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',type=Path);ap.add_argument('--gfortran');ap.add_argument('--result',type=Path,default=R/'results.json');a=ap.parse_args()
 if not(a.candidate or a.gfortran):ap.error('Supply candidate and/or GNU')
 if a.candidate:a.candidate=a.candidate.resolve()
 check_provenance();identity=sha(a.candidate) if a.candidate else None;rows=[]
 with tempfile.TemporaryDirectory(prefix='rank-three-vectors-') as tmp:
  for c in json.loads((R/'manifest.json').read_text())['cases']:
   source=R/c['source'];assert sha(source)==c['sha256'];row=dict(case=c,errors=[])
   if a.gfortran:
    comp=run([a.gfortran,*c.get('gnu_flags',FLAGS),source,'-o',Path(tmp)/'reference'],tmp);reference=None
    if comp==dict(code=0,out='',err='') and c['gnu']=='run':reference=run([Path(tmp)/'reference'],tmp)
    row.update(gnu_compile=comp,gnu_run=reference);row['errors']+=gnu_errors(c,comp,reference)
   if a.candidate:
    check=run([a.candidate,'--check',source],tmp);ran=run([a.candidate,source],tmp)
    row.update(check=check,run=ran);row['errors']+=candidate_errors(c,source,check,ran)
   assert sha(source)==c['sha256'];rows.append(row);print(c['name'],row['errors'] or 'PASS',flush=True)
 if a.candidate:assert identity==sha(a.candidate)
 summary=dict(total=len(rows),failed=sum(bool(x['errors']) for x in rows),candidate_sha256=identity,gnu_executed=sum(x.get('gnu_run') is not None for x in rows));a.result.write_text(json.dumps(dict(summary=summary,records=rows),indent=2)+'\n');print(summary);return bool(summary['failed'])
if __name__=='__main__':raise SystemExit(main())
