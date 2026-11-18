"""Synthetic adversarial tests; no candidate/compiler execution."""
import base64,copy,json,shutil,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import contracts as c
import run_tests as runner
ROOT=Path(__file__).resolve().parent

def record(out='',err='',code=0,argv=None):
 r={'command':argv or ['/tool','input.f90'],'returncode':code,'timeout':False,'valid_utf8':True,'stdout':out,'stderr':err}
 for stream in ['stdout','stderr']:
  raw=r[stream].encode();r[stream+'_base64']=base64.b64encode(raw).decode();r[stream+'_sha256']=c.digest(raw)
 return r
class Hardened(unittest.TestCase):
 checks=0
 def ok(self,x):type(self).checks+=1;self.assertTrue(x)
 def reject(self,f,*args,**kw):
  type(self).checks+=1
  with self.assertRaises((ValueError,TypeError,UnicodeError,FileNotFoundError)):f(*args,**kw)
 def test_process_schema(self):
  r=record('1\n');self.ok(not c.process_errors(r,r['command']))
  for k in r:
   x=copy.deepcopy(r);del x[k];self.ok(bool(c.process_errors(x)))
  for key,val in [('extra',True),('returncode',True),('returncode',0.0),('returncode',-11),('returncode',None),('timeout',True),('timeout',0),('valid_utf8',False),('valid_utf8',1),('command',[]),('command','/tool'),('command',['']),('command',['/tool\0']),('stdout',False),('stderr',None),('stdout_sha256','0'*64),('stderr_sha256','0'*64),('stdout_base64','%%%'),('stderr_base64','===='),('stdout_base64','MQo=\n'),('stdout_base64','')]:
   x=copy.deepcopy(r);x[key]=val;self.ok(bool(c.process_errors(x)))
  x=record();x['stdout_base64']='/w==';x['stdout_sha256']=c.digest(b'\xff');x['stdout']='\ufffd';self.ok(bool(c.process_errors(x)))
  self.ok(bool(c.process_errors(r,['/different','input.f90'])))
  for msg in ['Traceback','Backtrace','internal compiler error','Fortran runtime error','Segmentation fault','SIGSEGV','AddressSanitizer','Program received signal','core dumped','floating-point exception','x\0']:
   for stream in ['stdout','stderr']:
    self.ok(bool(c.process_errors(record(**({'out':msg} if stream=='stdout' else {'err':msg})))))
 def test_candidate_all_stages(self):
  for stage in ['success','check','runtime']:
   case={'candidate_stage':stage,'expected_records':[],'diagnostics':{'check':{'line':2,'column':3,'message':'rejected'},'run':{'line':2,'column':3,'message':'rejected'}}}
   for phase in ['check','run']:
    code=(1 if stage=='check' else 0) if phase=='check' else {'success':0,'check':1,'runtime':2}[stage]
    err='/s.f90:2:3: rejected\n' if code else '';r=record(err=err,code=code)
    self.ok(not c.stage_errors(case,phase,r,'/s.f90'))
    for key,value in [('timeout',True),('returncode',True),('returncode',-6),('stderr_sha256','0'*64)]:
     x=copy.deepcopy(r);x[key]=value;self.ok(bool(c.stage_errors(case,phase,x,'/s.f90')))
    self.ok(bool(c.stage_errors(case,phase,record('x\n',err,code),'/s.f90')))
    if code:
     self.ok(not c.stage_errors(case,phase,r,'/s.f90',True))
     for bad in ['/s.f90:0:3: rejected\n','/other:2:3: rejected\n',err+'extra\n','/s.f90:2:3: Traceback\n']:
      self.ok(bool(c.stage_errors(case,phase,record(err=bad,code=code),'/s.f90',True)))
     x=copy.deepcopy(case);x.pop('diagnostics');self.ok(bool(c.stage_errors(x,phase,r,'/s.f90')))
    else:self.ok(bool(c.stage_errors(case,phase,record(err='warning\n'),'/s.f90')))
  self.ok(bool(c.stage_errors(case,'unknown',r,'/s.f90')))
 def test_gnu_modes(self):
  for mode in sorted(c.MODES):
   case={'gnu':mode,'expected_records':[['1']]};reject=mode.endswith('reject')
   r=record(err=(c.BACKEND_TEXT if mode=='backend_reject' else 'Error: invalid operand') if reject else '',code=1 if reject else 0)
   if mode=='processor_reject':
    case=next(x for x in c.load_json(ROOT/'manifest.json')['cases'] if x['name']=='model_consistency')
    argv=['/gnu',*runner.GNU_FLAGS,'/suite/cases/model_consistency.f90','-o','/tmp/oracle']
    r=record(err=c.PROCESSOR_DIAGNOSTICS['model_consistency'].format(source=argv[-3]),code=1,argv=argv)
   self.ok(not c.gnu_errors(case,'compile',r))
   for key,val in [('timeout',True),('returncode',True),('valid_utf8',False),('stdout_sha256','0'*64)]:
    x=copy.deepcopy(r);x[key]=val;self.ok(bool(c.gnu_errors(case,'compile',x)))
   self.ok(bool(c.gnu_errors(case,'compile',record('stray',r['stderr'],r['returncode']))))
   if reject:self.ok(bool(c.gnu_errors(case,'compile',record(code=1))))
   else:self.ok(not c.gnu_errors(case,'compile',record(err='Warning: preserved\n')))
   self.ok(bool(c.gnu_errors(case,'run',record('1\n')))==(mode!='execute'))
  self.ok(bool(c.gnu_errors({'gnu':'typo'},'compile',record())))
  self.ok(bool(c.gnu_errors({'gnu':'backend_reject'},'compile',record(err='Error: different',code=1))))
  case={'gnu':'execute','expected_records':[['1']]}
  for r in [record('1'),record('1\n',err='warning'),record('1\n',code=1),record('1.0\n'),record('1\n\n')]:self.ok(bool(c.gnu_errors(case,'run',r)))
 def test_exact_processor_rejections(self):
  m=c.load_json(ROOT/'manifest.json')
  for name,template in c.PROCESSOR_DIAGNOSTICS.items():
   case=next(x for x in m['cases'] if x['name']==name);source='/suite/cases/'+name+'.f90'
   argv=['/gnu',*runner.GNU_FLAGS,source,'-o','/tmp/oracle'];err=template.format(source=source)
   self.ok(not c.gnu_errors(case,'compile',record(err=err,code=1,argv=argv),command=argv))
   for bad in ['Error: syntax error\n','Fatal Error: cannot open module file\n',err+'Error: unrelated\n',err.replace(':4:',':5:'),err.replace(source,'/other/'+name+'.f90'),err.replace('not conformable','a different cause') if name=='model_consistency' else err.replace('(2 and 5)','(2 and 4)'),err[:-1]]:
    self.ok(bool(c.gnu_errors(case,'compile',record(err=bad,code=1,argv=argv),command=argv)))
   x=copy.deepcopy(case);x['sha256']='0'*64;self.ok(bool(c.gnu_errors(x,'compile',record(err=err,code=1,argv=argv))))
   x=list(argv);x[1]='-std=legacy';self.ok(bool(c.gnu_errors(case,'compile',record(err=err,code=1,argv=x))))
   x=list(argv);x[-3]='/other.f90';self.ok(bool(c.gnu_errors(case,'compile',record(err=err,code=1,argv=x))))
 def test_output_path_safety(self):
  with tempfile.TemporaryDirectory() as temp:
   base=Path(temp);root=base/'suite';root.mkdir();fresh=base/'fresh'
   self.ok(runner.new_output_path(fresh,root)==fresh)
   self.reject(runner.new_output_path,root,root)
   self.reject(runner.new_output_path,root/'new',root)
   self.reject(runner.new_output_path,base,root)
   dangling=base/'dangling';dangling.symlink_to(base/'not-created')
   self.reject(runner.new_output_path,dangling,root)
   self.reject(runner.new_output_path,dangling/'new',root)
   real=base/'real';real.mkdir();link=base/'link';link.symlink_to(real,target_is_directory=True)
   self.reject(runner.new_output_path,link/'new',root)
   self.reject(runner.new_output_path,link/'..'/'new',root)
 def test_version_contracts(self):
  text='fortfront-interpreter 0.53.0; FortFront abcdef0 + documented local patches\n';r=record(text,argv=['/tool','--version'])
  self.ok(not c.version_errors(r,expected_version='0.53.0',command=r['command']))
  for version in ['0.52.0','0.53','00.53.0','0.53.0\n',None]:self.ok(bool(c.version_errors(r,expected_version=version)))
  for key,val in [('timeout',True),('returncode',False),('returncode',1),('stderr','warning'),('valid_utf8',False),('stdout_sha256','0'*64)]:
   x=copy.deepcopy(r);x[key]=val;self.ok(bool(c.version_errors(x,expected_version='0.53.0')))
  for text2 in [text+'x\n',text[:-1],text.replace('abcdef0','xxxxxxx')]:self.ok(bool(c.version_errors(record(text2),expected_version='0.53.0')))
  g='GNU Fortran (test) 14.2.0\nCopyright\n';h=c.digest(g.encode());self.ok(not c.version_errors(record(g),gnu_stdout_sha256=h))
  self.ok(bool(c.version_errors(record(g),gnu_stdout_sha256='0'*64)))
  self.ok(bool(c.version_errors(record('wrong\n'),gnu_stdout_sha256=c.digest(b'wrong\n'))))
 def test_manifest_schema(self):
  m=c.load_json(ROOT/'manifest.json');self.ok(len(c.validate_manifest(m,ROOT))==72)
  self.ok(len(c.validate_manifest(m,ROOT,True))==72)
  missing=copy.deepcopy(m);next(x for x in missing['cases'] if x['candidate_stage']=='check').pop('diagnostics');self.reject(c.validate_manifest,missing,ROOT,True)
  def altered(change):
   x=copy.deepcopy(m);change(x);self.reject(c.validate_manifest,x,ROOT)
  for key,val in [('name','../escape'),('name','Bad'),('source','/tmp/x'),('source','cases/../cases/width_32.f90'),('source','cases/every_bit_32.f90'),('sha256','0'*64),('candidate_stage','typo'),('gnu','typo'),('gnu','backend_reject'),('expected_records',[['1.0']]),('expected_records',[[]]),('expected_records','1'),('processor_model',1),('original',1),('unknown',1),('diagnostics',{'wrong':{}}),('diagnostics',{'run':{'line':0,'column':1,'message':'x'}})]:altered(lambda x,k=key,v=val:x['cases'][0].__setitem__(k,v))
  altered(lambda x:x['cases'].append(copy.deepcopy(x['cases'][0])))
  altered(lambda x:x['cases'].pop())
  altered(lambda x:x.__setitem__('unknown',1))
  altered(lambda x:x.__setitem__('initial_manifest_sha256','x'))
  for name in c.SPECIAL_REJECTS:
   altered(lambda x,n=name:next(z for z in x['cases'] if z['name']==n).__setitem__('gnu','reject'))
  with tempfile.TemporaryDirectory() as temp:
   root=Path(temp)/'suite';root.mkdir();shutil.copytree(ROOT/'cases',root/'cases');self.ok(len(c.validate_manifest(m,root))==72)
   p=root/'cases/width_32.f90';saved=p.read_bytes();p.write_bytes(saved+b'!changed\n');self.reject(c.validate_manifest,m,root);p.write_bytes(saved)
   p.unlink();p.symlink_to(ROOT/'cases/width_32.f90');self.reject(c.validate_manifest,m,root);p.unlink();p.write_bytes(saved)
   extra=root/'cases/extra.f90';extra.write_text('');self.reject(c.validate_manifest,m,root);extra.unlink()
   d=root/'cases/sub';d.mkdir();self.reject(c.validate_manifest,m,root)
 def test_json_duplicate_and_nonfinite(self):
  with tempfile.TemporaryDirectory() as temp:
   p=Path(temp)/'x.json'
   for text in ['{"cases":[],"cases":[]}','{"a":{"x":1,"x":2}}','{"x":NaN}','{"x":Infinity}','{"x":-Infinity}']:
    p.write_text(text);self.reject(c.load_json,p)
   p.write_bytes(b'{"x":"\xff"}');self.reject(c.load_json,p)
 def test_before_after_identity(self):
  with tempfile.TemporaryDirectory() as temp:
   root=Path(temp);p=root/'tool';p.write_bytes(b'not executable');h=c.sha(p)
   banner='fortfront-interpreter 0.53.0; FortFront abcdef0 + documented local patches\n';r=record(banner,argv=[str(p),'--version'])
   ids=runner.file_identities([p]);runner.verify_identities(ids);self.ok(True)
   with patch.object(runner,'call',return_value=r) as mocked:
    ident=runner.version_identity(p,h,root,expected_version='0.53.0');self.ok(mocked.call_count==1)
    self.ok(runner.recheck_version(p,ident,root,expected_version='0.53.0')==ident)
   with patch.object(runner,'call',return_value=record(banner.replace('abcdef0','abcdef1'),argv=[str(p),'--version'])):
    self.reject(runner.recheck_version,p,ident,root,expected_version='0.53.0')
   def mutate(*args):p.write_bytes(b'changed');return r
   with patch.object(runner,'call',side_effect=mutate):self.reject(runner.version_identity,p,h,root,expected_version='0.53.0')
   self.reject(runner.verify_identities,ids)
   with patch.object(runner,'call',return_value=r) as mocked:
    self.reject(runner.version_identity,p,h,root,expected_version='0.53.0');self.ok(mocked.call_count==0)
   p.unlink();self.reject(runner.verify_identities,ids)
if __name__=='__main__':
 r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Hardened));print(json.dumps({'checks':Hardened.checks,'methods':r.testsRun,'failures':len(r.failures),'errors':len(r.errors)}));raise SystemExit(not r.wasSuccessful())
