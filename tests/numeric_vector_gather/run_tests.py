"""Exact numeric-vector test policy. Unobserved candidate negatives never pass."""
from pathlib import Path
import argparse,hashlib,json,re,subprocess,shutil,base64
R=Path(__file__).resolve().parent
FLAGS=['-std=f2018','-pedantic-errors','-fcheck=all','-O0']
CRASH=re.compile(r'backtrace|traceback|internal compiler error|fortran runtime error|segmentation|SIGSEGV|SIGABRT|TIMEOUT',re.I)
def require(ok,message):
 if not ok:raise ValueError(message)
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def process_record(code,out=b'',err=b'',termination='exit',error=None):
 if isinstance(out,str):out=out.encode('utf8')
 if isinstance(err,str):err=err.encode('utf8')
 utf8=True
 try:textout=out.decode('utf8');texterr=err.decode('utf8')
 except UnicodeDecodeError:utf8=False;textout=out.decode('utf8',errors='replace');texterr=err.decode('utf8',errors='replace')
 return dict(code=code,out=textout,err=texterr,stdout_b64=base64.b64encode(out).decode('ascii'),stderr_b64=base64.b64encode(err).decode('ascii'),stdout_sha256=hashlib.sha256(out).hexdigest(),stderr_sha256=hashlib.sha256(err).hexdigest(),utf8=utf8,termination=termination,error=error)
def valid_process(row):
 keys={'code','out','err','stdout_b64','stderr_b64','stdout_sha256','stderr_sha256','utf8','termination','error'}
 if not isinstance(row,dict) or set(row)!=keys:return False
 if type(row['code']) is not int or row['code']<0 or row['termination']!='exit' or row['error'] is not None or row['utf8'] is not True:return False
 if any(type(row[key]) is not str for key in ('out','err','stdout_b64','stderr_b64','stdout_sha256','stderr_sha256')):return False
 try:
  out=base64.b64decode(row['stdout_b64'],validate=True);err=base64.b64decode(row['stderr_b64'],validate=True)
  return out.decode('utf8')==row['out'] and err.decode('utf8')==row['err'] and hashlib.sha256(out).hexdigest()==row['stdout_sha256'] and hashlib.sha256(err).hexdigest()==row['stderr_sha256']
 except (ValueError,UnicodeDecodeError):return False
def streams(row):return {key:row[key] for key in ('code','out','err')}
def suite_identity(root=R):
 paths=[root/name for name in ('manifest.json','contracts.json','provenance.json','source/exact_closure.f90','source/dependency_closure.f90')]
 paths+=list(root.glob('*.py'))+list((root/'cases').glob('*.f90'))
 return {str(path.relative_to(root)):sha(path) for path in sorted(paths)}
def require_new_path(path,directory=False):
 absolute=path.absolute()
 require(not absolute.exists() and not absolute.is_symlink(),'output path already exists: '+str(path))
 for parent in absolute.parents:require(not parent.is_symlink(),'output parent is a symlink: '+str(parent))
 require(absolute.parent.is_dir(),'output parent is missing: '+str(absolute.parent))
 return absolute
def no_duplicate_keys(pairs):
 result={}
 for key,value in pairs:
  require(key not in result,'duplicate JSON key: '+key);result[key]=value
 return result
def read_json(path):return json.loads(path.read_text(),object_pairs_hook=no_duplicate_keys)
def load_cases(root=R):
 manifest=read_json(root/'manifest.json')
 require(isinstance(manifest,dict) and isinstance(manifest.get('cases'),list) and manifest['cases'],'manifest case list missing')
 names=set();paths=set();rows=manifest['cases']
 for case in rows:
  require(isinstance(case,dict),'case is not an object')
  required={'name','source','sha256','stage','gnu','expected','diagnostic','gnu_stderr','gnu_expected'}
  require(required<=set(case)<=required|{'note','gnu_flags','max_steps'},'case schema differs')
  name=case['name'];source=case['source']
  require(type(name) is str and re.fullmatch(r'[a-z][a-z0-9_]*',name) is not None,'invalid case name')
  require(name not in names,'duplicate case name');names.add(name)
  require(type(source) is str and source=='cases/'+name+'.f90','case/source identity differs')
  require(source not in paths,'duplicate source path');paths.add(source)
  path=root/source
  require(path.is_file() and not path.is_symlink() and path.resolve().parent==(root/'cases').resolve(),'source path is missing or escapes suite')
  require(type(case['sha256']) is str and re.fullmatch(r'[0-9a-f]{64}',case['sha256']) is not None,'invalid source hash')
  require(sha(path)==case['sha256'],'source hash differs: '+name)
  require(case['stage'] in ('success','runtime','compile') and case['gnu'] in ('run','compile','reject'),'unknown case mode')
  require(all(type(case[key]) is str for key in ('expected','gnu_stderr','gnu_expected')),'stream contract is not text')
  require(case['diagnostic'] is None or type(case['diagnostic']) is str,'diagnostic schema differs')
  require(case['stage']!='success' or case['diagnostic'] is None,'success has a stale diagnostic')
  if 'gnu_flags' in case:require(case['gnu_flags']==FLAGS,'unapproved GNU flags differ')
  if 'max_steps' in case:require(type(case['max_steps']) is int and 0<case['max_steps']<=100000000,'unapproved explicit execution budget')
 require(paths=={'cases/'+p.name for p in (root/'cases').glob('*.f90')},'manifest/source bijection differs')
 return rows
def version_errors(row,expected=None):
 if not valid_process(row):return ['version process schema differs']
 if row['code']!=0 or row['err'] or not row['out']:return ['version status/streams differ']
 if expected is not None:
  m=re.fullmatch(r'fortfront-interpreter (\d+\.\d+\.\d+); FortFront [0-9a-f]+ \+ documented local patches\n',row['out'])
  if m is None or m.group(1)!=expected:return ['candidate version differs']
 return []
def run(args,cwd,timeout=60):
 try:
  p=subprocess.run(list(map(str,args)),cwd=cwd,capture_output=True,timeout=timeout,stdin=subprocess.DEVNULL)
  return process_record(p.returncode,p.stdout,p.stderr,termination='signal' if p.returncode<0 else 'exit')
 except subprocess.TimeoutExpired as error:
  return process_record(None,error.stdout or b'',error.stderr or b'',termination='timeout',error=str(error))
 except OSError as error:
  return process_record(None,termination='spawn-error',error=str(error))
def candidate_errors(case,source,check,ran):
 if not valid_process(check) or not valid_process(ran):return ['candidate process schema differs']
 if CRASH.search(check['out']+check['err']+ran['out']+ran['err']):return ['candidate crash marker']
 check=streams(check);ran=streams(ran)
 stage=case['stage'];errors=[]
 if stage not in ('success','runtime','compile'):return ['unknown candidate stage']
 diag=case.get('diagnostic')
 if stage!='success' and (not isinstance(diag,str) or not re.fullmatch(r'[1-9]\d*:[1-9]\d*: [^\r\n]+',diag)):
  return ['candidate diagnostic is not pinned']
 stderr=str(source)+':'+diag+'\n' if stage!='success' else ''
 expected_check=dict(code=1,out='',err=stderr) if stage=='compile' else dict(code=0,out='',err='')
 if check!=expected_check:errors.append('candidate check stage/path/streams differ')
 if ran!=dict(code={'success':0,'runtime':2,'compile':1}[stage],out=case['expected'],err=stderr):errors.append('candidate execution stage/path/streams differ')
 return errors
def gnu_errors(case,source,compiled,ran):
 if not valid_process(compiled) or (ran is not None and not valid_process(ran)):return ['GNU process schema differs']
 if CRASH.search(compiled['out']+compiled['err']+(ran['out']+ran['err'] if ran is not None else '')):return ['GNU crash marker']
 compiled=streams(compiled);ran=streams(ran) if ran is not None else None
 if 'gnu_stderr' not in case:return ['GNU diagnostic not pinned']
 stderr=case['gnu_stderr'].replace('{source}',str(source));stage=case['gnu']
 if stage not in ('run','compile','reject'):return ['unknown GNU stage']
 if compiled!=dict(code=1 if stage=='reject' else 0,out='',err=stderr):return ['GNU compilation stage/path/streams differ']
 if stage=='reject' and not stderr:return ['empty GNU constraint diagnostic']
 if stage=='run':
  if ran!=dict(code=0,out=case.get('gnu_expected',case['expected']),err=''):return ['GNU exact execution differs']
 elif ran is not None:return ['GNU compile-only case unexpectedly executed']
 return []
def check_provenance(root=R):
 meta=read_json(root/'provenance.json');closure=(root/'source/exact_closure.f90').read_bytes();dependency=(root/'source/dependency_closure.f90').read_bytes()
 require(isinstance(meta,dict) and isinstance(meta.get('bodies'),list),'provenance schema differs')
 require(len(meta['bodies'])==3 and {b.get('name') for b in meta['bodies']}=={'unique_vec_int','unique_int','set_alloc_int_vec'},'original body inventory differs')
 for body in meta['bodies']:
  pattern=rb'(?mi)^(?:(?:pure|recursive|elemental)\s+)*(?:subroutine|function) '+body['name'].encode()+rb'\b.*?^end (?:subroutine|function) '+body['name'].encode()+rb'[^\r\n]*\r?\n'
  found=re.search(pattern,closure,re.S)
  require(found is not None,'original body absent: '+body['name'])
  require(len(found.group())==body['bytes'] and hashlib.sha256(found.group()).hexdigest()==body['sha256'],'original body bytes differ: '+body['name'])
  if body['name']!='unique_vec_int':require(found.group() in dependency,'dependency body differs: '+body['name'])
 for p in (root/'cases').glob('original_*.f90'):
  raw=p.read_bytes();require(raw.startswith(closure) or raw.startswith(dependency),'original fixture closure differs: '+str(p))
 return True
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',type=Path);ap.add_argument('--expected-candidate-sha256');ap.add_argument('--candidate-version',default='0.53.0');ap.add_argument('--gfortran');ap.add_argument('--result',type=Path,default=R/'results.json');ap.add_argument('--evidence-dir',type=Path,required=True);args=ap.parse_args()
 if not(args.candidate or args.gfortran):ap.error('Supply candidate and/or GNU')
 if args.candidate:
  require(type(args.expected_candidate_sha256) is str and re.fullmatch(r'[0-9a-f]{64}',args.expected_candidate_sha256) is not None,'explicit expected candidate SHA256 is required')
  args.candidate=args.candidate.resolve()
 cases=load_cases();check_provenance();identity=sha(args.candidate) if args.candidate else None;rows=[]
 if args.expected_candidate_sha256:require(identity==args.expected_candidate_sha256,'candidate differs from requested immutable identity')
 result=require_new_path(args.result);evidence=require_new_path(args.evidence_dir,directory=True);evidence.mkdir(exist_ok=False)
 before={'suite_identity':suite_identity()};after={};global_errors=[]
 if args.candidate:
  before['candidate_sha256']=identity;before['candidate_version']=run([args.candidate,'--version'],evidence)
  global_errors+=version_errors(before['candidate_version'],args.candidate_version)
 if args.gfortran:
  compiler=Path(shutil.which(args.gfortran) or args.gfortran).resolve();args.gfortran=str(compiler)
  before['gnu_sha256']=sha(compiler);before['gnu_version']=run([compiler,'--version'],evidence)
  global_errors+=version_errors(before['gnu_version'])
 with (evidence/'identity-before.json').open('x') as output:output.write(json.dumps(before,indent=2)+'\n')
 if not global_errors:
  for c in cases:
   source=(R/c['source']).resolve();require(sha(source)==c['sha256'],'source changed before execution');row=dict(case=c,errors=[]);work=evidence/c['name'];work.mkdir()
   if args.gfortran:
    comp=run([args.gfortran,*c.get('gnu_flags',FLAGS),source,'-o',work/'reference'],work);reference=None
    if valid_process(comp) and comp['code']==0 and c['gnu']=='run':reference=run([work/'reference'],work)
    row.update(gnu_compile=comp,gnu_run=reference);row['errors']+=gnu_errors(c,source,comp,reference)
   if args.candidate:
    extra=['--max-steps',str(c['max_steps'])] if 'max_steps' in c else []
    check=run([args.candidate,'--check',source],work);ran=run([args.candidate,*extra,source],work)
    row.update(check=check,run=ran);row['errors']+=candidate_errors(c,source,check,ran)
   require(sha(source)==c['sha256'],'source changed during execution');rows.append(row)
   with (work/'result.json').open('x') as output:output.write(json.dumps(row,indent=2)+'\n')
   print(c['name'],row['errors'] or 'PASS',flush=True)
 if args.candidate:
  after['candidate_sha256']=sha(args.candidate);after['candidate_version']=run([args.candidate,'--version'],evidence)
  global_errors+=version_errors(after['candidate_version'],args.candidate_version)
 if args.gfortran:
  after['gnu_sha256']=sha(compiler);after['gnu_version']=run([compiler,'--version'],evidence)
  global_errors+=version_errors(after['gnu_version'])
 after['suite_identity']=suite_identity()
 if after!=before:global_errors.append('compiler or suite identity/version changed during suite')
 with (evidence/'identity-after.json').open('x') as output:output.write(json.dumps(after,indent=2)+'\n')
 summary=dict(total=len(rows),planned=len(cases),failed=sum(bool(x['errors']) for x in rows),candidate_sha256=identity,gnu_executed=sum(x.get('gnu_run') is not None for x in rows),global_errors=global_errors)
 with result.open('x') as output:output.write(json.dumps(dict(summary=summary,identity_before=before,identity_after=after,records=rows),indent=2)+'\n')
 print(summary);return bool(summary['failed'] or global_errors or len(rows)!=len(cases))
if __name__=='__main__':raise SystemExit(main())
