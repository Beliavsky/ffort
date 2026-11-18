"""Pure substring receipt validation; raw stage checks adapted from INQUIRE R5-exact."""
import base64,hashlib,re,json
from pathlib import Path
CRASH = ('segmentation fault', 'sigsegv', 'sigabrt', 'sigfpe', 'backtrace', 'core dumped', 'runtime error:', 'internal compiler error', 'please submit a full bug report', 'double free', 'malloc():', 'free():', 'addresssanitizer', 'undefinedbehaviorsanitizer', 'traceback (most recent call last)', 'program received signal', 'runtimeerror:', 'fatal python error')

def stage_errors(stage):
    if type(stage) is not dict:
        return ['stage must be an object']
    errors = []
    if type(stage.get('cwd')) is not str or not stage['cwd']:
        errors.append('cwd must be a present nonempty string')
    argv = stage.get('argv')
    if type(argv) is not list or not argv or any(type(arg) is not str or not arg for arg in argv):
        errors.append('argv must be a present nonempty string list')
    if type(stage.get('status')) is not int or stage['status'] < 0:
        errors.append('status must be a nonnegative integer, never bool')
    for key in ('stdout', 'stderr'):
        value = stage.get(key)
        if type(value) is not str:
            errors.append(key + ' must be present string')
        elif '\ufffd' in value or any(0xD800 <= ord(c) <= 0xDFFF for c in value):
            errors.append(key + ' decoding corruption')
        elif any(marker in value.lower() for marker in CRASH):
            errors.append(key + ' crash marker')
    for key in ('stdout', 'stderr'):
        try:
            encoded=stage[key+'_base64']
            if type(encoded) is not str:
                raise ValueError('raw payload must be string')
            raw=base64.b64decode(encoded,validate=True)
            if base64.b64encode(raw).decode('ascii') != encoded:
                raise ValueError('raw payload is noncanonical')
            if hashlib.sha256(raw).hexdigest()!=stage.get(key+'_sha256'):
                raise ValueError('raw hash differs')
            if raw.decode('utf-8')!=stage.get(key):
                raise ValueError('decoded stream differs')
        except (KeyError,ValueError,UnicodeError,TypeError) as exc:
            errors.append(key+' raw bytes invalid: '+str(exc))
    if 'timeout' in stage and stage['timeout'] is not False:
        errors.append('timeout must be absent or bool False')
    if 'valid_utf8' in stage and stage['valid_utf8'] is not True:
        errors.append('valid_utf8 must be absent or bool True')
    if stage.get('spawn_error') is not None:
        errors.append('stage process did not spawn cleanly')
    return errors

VERSION='fortfront-interpreter 0.56.0; FortFront 9a5896a + documented local patches\n'
MANIFEST_SHA='729500ded8989b8f8789513f5b50047b1e9459e1863bcc04ca957ebb7eee6255'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def inventory(root,manifest):
 names=['manifest.json','run_strict.py','validate_results.py','process_contract.py','test_strict.py','gnu-profile.json']+[x['source'] for x in manifest]
 result={}
 for n in names:
  p=Path(n)
  if p.is_absolute() or '..' in p.parts:raise ValueError('input path escapes suite')
  p=Path(root)/p
  if p.is_symlink()or not p.is_file():raise ValueError('input is not regular file')
  result[n]=sha(p)
 return result
def validate(result,manifest,root,candidate_sha,gnu_sha):
 errors=[];root=Path(root).resolve()
 def bad(message):errors.append(message)
 def stage(label,value,argv,cwd,expected):
  es=stage_errors(value)
  if type(value)is dict:
   for key,wanted in [('timeout',False),('valid_utf8',True),('spawn_error',None)]:
    if key not in value or value[key] is not wanted:es.append('missing/noncanonical '+key)
  if es:errors.extend(label+': '+x for x in es);return
  if value['argv']!=argv or value['cwd']!=cwd:bad(label+': invocation differs')
  for k,v in expected.items():
   if value[k]!=v:bad(label+': exact '+k+' differs')
 if type(result)is not dict:return ['receipt must be object']
 allowed_top={'status','records','inputs_before','inputs_after','candidate','gnu','candidate_sha256_before','candidate_sha256_after','gnu_sha256_before','gnu_sha256_after','version_before','version_after','gnu_version_before','gnu_version_after','validation_errors','runner_exception'}
 if set(result)-allowed_top:bad('unexpected receipt stages')
 try:
  current=inventory(root,manifest);profile=json.loads((root/'gnu-profile.json').read_text())
 except Exception as e:return ['input inventory unavailable: '+str(e)]
 if sha(root/'manifest.json')!=MANIFEST_SHA or len(manifest)!=24:bad('frozen manifest differs')
 pinned=json.loads((root/'manifest.json').read_text())
 if json.dumps(manifest,sort_keys=True,separators=(',',':'))!=json.dumps(pinned,sort_keys=True,separators=(',',':')):bad('supplied manifest differs from pinned contract')
 for case in pinned:
  if sha(root/case['source'])!=case['sha256']:bad('fixture bytes differ from pinned source identity: '+case['name'])
 for key in ['inputs_before','inputs_after']:
  if result.get(key)!=current:bad(key+' differs')
 for tag,wanted in [('candidate',candidate_sha),('gnu',gnu_sha)]:
  if type(wanted)is not str or re.fullmatch('[0-9a-f]{64}',wanted)is None:bad(tag+' expected identity invalid')
  for when in ['before','after']:
   if result.get(tag+'_sha256_'+when)!=wanted:bad(tag+' identity '+when+' differs')
 if profile.get('sha256')!=gnu_sha:bad('GNU expected profile differs')
 if result.get('runner_exception')is not None:bad('runner exception')
 exe=result.get('candidate');gnu=result.get('gnu')
 if any(type(x)is not str or not Path(x).is_absolute() for x in [exe,gnu]):bad('executables missing');return errors
 for when in ['before','after']:
  stage('candidate version '+when,result.get('version_'+when),[exe,'--version'],str(root),{'status':0,'stdout':VERSION,'stderr':''})
  stage('GNU version '+when,result.get('gnu_version_'+when),[gnu,'--version'],str(root),{'status':0,'stdout':profile['stdout'],'stderr':''})
 rows=result.get('records')
 if type(rows)is not list:bad('records missing');return errors
 if len(rows)!=24:bad('record count differs')
 if any(type(x)is not dict for x in rows):bad('row not object');return errors
 names=[x.get('name') for x in rows]
 if len(set(map(str,names)))!=len(names)or set(map(str,names))!={x['name']for x in manifest}:bad('record name bijection differs');return errors
 table={x['name']:x for x in manifest}
 for row in rows:
  c=table[row['name']];name=c['name'];src=str((root/c['source']).resolve());cwd=row.get('cwd')
  if type(cwd)is not str or not Path(cwd).is_absolute():bad(name+': cwd missing');continue
  allowed={'name','source','sha256','gnu_run','cwd','check','run','gnu_compile','gnu_execution'}
  if set(row)!=allowed:bad(name+': row inventory differs')
  if any(row.get(k)!=c[k] for k in ['source','sha256'])or type(row.get('gnu_run'))is not bool or row.get('gnu_run')is not c['gnu_run']:bad(name+': source/mode identity differs')
  for phase,args in [('check',['--check']),('run',[])]:
   e={k:v.replace('{source}',src)if type(v)is str else v for k,v in c[phase].items()}
   stage(name+' '+phase,row.get(phase),[exe]+args+[src],cwd,e)
  binary=str(Path(cwd)/'oracle')
  stage(name+' GNUcompile',row.get('gnu_compile'),[gnu,'-std=f2018','-fcheck=all',src,'-o',binary],cwd,{'status':0,'stdout':'','stderr':''})
  if c['gnu_run']:stage(name+' GNUrun',row.get('gnu_execution'),[binary],cwd,{'status':0,'stdout':c['gnu_stdout'],'stderr':''})
  elif row.get('gnu_execution')is not None:bad(name+': forbidden GNU execution')
 return errors
