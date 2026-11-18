"""Exact formatted READ element policy. Unobserved candidate negatives fail closed."""
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

def suite_identity(root=R):
 paths=[root/'manifest.json',root/'provenance.json',root/'source/original-bodies.f90']
 paths+=list(root.glob('*.py'))+list((root/'cases').glob('*.f90'))
 return {str(p.relative_to(root)):sha(p) for p in sorted(paths)}
def load_cases(root=R):
 manifest=read_json(root/'manifest.json');require(type(manifest) is dict,'manifest is not an object');rows=manifest.get('cases')
 require(type(rows) is list and rows,'manifest case list missing')
 names=set();paths=set()
 for c in rows:
  require(type(c) is dict and set(c)=={'name','source','sha256','inputs','gnu','diagnostic','note','stage','expected','gnu_expected','gnu_stderr'},'case schema differs')
  name=c['name'];source=c['source']
  require(type(name) is str and re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*',name) is not None,'invalid case name')
  require(name not in names,'duplicate case name');names.add(name)
  require(type(source) is str and source=='cases/'+name+'.f90' and source not in paths,'case/source identity differs');paths.add(source)
  p=root/source
  require(p.is_file() and not p.is_symlink() and p.resolve().parent==(root/'cases').resolve(),'source missing or outside suite')
  require(type(c['sha256']) is str and re.fullmatch('[0-9a-f]{64}',c['sha256']) is not None and sha(p)==c['sha256'],'source hash differs')
  require(c['stage'] in ('success','compile','runtime') and c['gnu'] in ('run','compile','reject'),'unknown stage')
  require(all(type(c[k]) is str for k in ('expected','gnu_expected','gnu_stderr','note')),'stream contract is not text')
  require(c['diagnostic'] is None or type(c['diagnostic']) is str,'diagnostic schema differs')
  require(c['stage']!='success' or c['diagnostic'] is None,'success has stale diagnostic')
  require(type(c['inputs']) is dict and len(c['inputs'])<=32,'bad input table')
  total=0
  for unit,data in c['inputs'].items():
   require(type(unit) is str and re.fullmatch('[1-9][0-9]*',unit) is not None and int(unit)<=2147483647,'bad virtual unit')
   require(type(data) is str,'input data is not text');n=len(data.encode('utf8'));require(n<=1048576,'input byte cap');total+=n
  require(total<=4194304,'aggregate input byte cap')
 require(paths=={'cases/'+p.name for p in (root/'cases').glob('*.f90')},'manifest/source bijection differs')
 return rows
def check_provenance(root=R):
 m=read_json(root/'provenance.json');b=(root/'source/original-bodies.f90').read_bytes();fixture=(root/'cases/original_read_comments_closure.f90').read_bytes()
 require(type(m) is dict and type(m.get('bodies')) is list and len(m['bodies'])==2,'provenance schema differs')
 require({v.get('name') for v in m['bodies']}=={'set_optional_logical','read_comments'},'original body inventory differs')
 for v in m['bodies']:
  pattern=rb'(?mi)^(?:(?:pure|recursive|elemental)\s+)*subroutine '+v['name'].encode()+rb'\b.*?^end subroutine '+v['name'].encode()+rb'[^\r\n]*\r?\n'
  found=re.search(pattern,b,re.S);require(found is not None,'missing original body')
  raw=found.group();require(len(raw)==v['bytes'] and hashlib.sha256(raw).hexdigest()==v['sha256'],'original body differs')
  require(raw in fixture,'original closure fixture differs')
 return True
def persist(path,value):
 with path.open('x',encoding='utf8') as f:f.write(json.dumps(value,indent=2)+'\n')
def raw_record(work,stem,record):
 for kind in ('stdout','stderr'):
  with (work/(stem+'.'+kind)).open('xb') as f:f.write(base64.b64decode(record[kind+'_b64']))
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',type=Path);ap.add_argument('--expected-candidate-sha256');ap.add_argument('--candidate-version',default='0.54.0');ap.add_argument('--gfortran');ap.add_argument('--result',type=Path,required=True);ap.add_argument('--evidence-dir',type=Path,required=True);a=ap.parse_args()
 require(bool(a.candidate or a.gfortran),'Supply candidate and/or GNU')
 cases=load_cases();check_provenance();before={'suite_identity':suite_identity()};rows=[];errors=[]
 if a.candidate:
  require(type(a.expected_candidate_sha256) is str and re.fullmatch('[0-9a-f]{64}',a.expected_candidate_sha256) is not None,'explicit expected candidate SHA256 is required')
  a.candidate=a.candidate.resolve();require(sha(a.candidate)==a.expected_candidate_sha256,'candidate differs from requested identity')
 result=require_new_path(a.result);evidence=require_new_path(a.evidence_dir);evidence.mkdir(exist_ok=False)
 if a.candidate:
  before['candidate_sha256']=sha(a.candidate);before['candidate_version']=run([a.candidate,'--version'],evidence);errors+=version_errors(before['candidate_version'],a.candidate_version)
 if a.gfortran:
  compiler=Path(shutil.which(a.gfortran) or a.gfortran).resolve();before['gnu_sha256']=sha(compiler);before['gnu_version']=run([compiler,'--version'],evidence);errors+=version_errors(before['gnu_version'])
 persist(evidence/'identity-before.json',before)
 if not errors:
  for c in cases:
   source=(R/c['source']).resolve();require(sha(source)==c['sha256'],'source changed before execution');work=evidence/c['name'];work.mkdir();row={'case':c,'errors':[]}
   candidate_dir=work/'candidate';candidate_dir.mkdir();gnu_dir=work/'gnu';gnu_dir.mkdir();bindings=[]
   for unit,data in c['inputs'].items():
    path=candidate_dir/('input-'+unit+'.dat');path.write_bytes(data.encode('utf8'));bindings+=['--input',unit+'='+str(path)]
    (gnu_dir/('fort.'+unit)).write_bytes(data.encode('utf8'))
   if a.gfortran:
    comp=run([compiler,*FLAGS,source,'-o',gnu_dir/'reference'],gnu_dir);reference=None;raw_record(work,'gnu-compile',comp)
    if valid_process(comp) and comp['code']==0 and c['gnu']=='run':reference=run([gnu_dir/'reference'],gnu_dir);raw_record(work,'gnu-run',reference)
    row.update(gnu_compile=comp,gnu_run=reference);row['errors']+=gnu_errors(c,source,comp,reference)
   if a.candidate:
    check=run([a.candidate,'--check',source],candidate_dir);ran=run([a.candidate,*bindings,source],candidate_dir)
    raw_record(work,'check',check);raw_record(work,'run',ran);row.update(check=check,run=ran);row['errors']+=candidate_errors(c,source,check,ran)
   require(sha(source)==c['sha256'],'source changed during execution');rows.append(row);persist(work/'result.json',row);print(c['name'],row['errors'] or 'PASS',flush=True)
 after={'suite_identity':suite_identity()}
 if a.candidate:
  after['candidate_sha256']=sha(a.candidate);after['candidate_version']=run([a.candidate,'--version'],evidence);errors+=version_errors(after['candidate_version'],a.candidate_version)
 if a.gfortran:
  after['gnu_sha256']=sha(compiler);after['gnu_version']=run([compiler,'--version'],evidence);errors+=version_errors(after['gnu_version'])
 if after!=before:errors.append('compiler or policy/source identity changed during run')
 persist(evidence/'identity-after.json',after)
 summary={'total':len(rows),'planned':len(cases),'failed':sum(bool(r['errors']) for r in rows),'gnu_executed':sum(r.get('gnu_run') is not None for r in rows),'global_errors':errors,'candidate_verified':bool(a.candidate) and not errors and len(rows)==len(cases) and not any(r['errors'] for r in rows)}
 persist(result,{'summary':summary,'identity_before':before,'identity_after':after,'records':rows});print(summary);return bool(errors or summary['failed'] or len(rows)!=len(cases))
if __name__=='__main__':raise SystemExit(main())
