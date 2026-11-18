import base64,copy,json,unittest
from pathlib import Path
from contracts import *
ROOT=Path(__file__).resolve().parent
def bind(r):
 r['command']=['/candidate','fixture.f90']
 for stream in ['stdout','stderr']:
  raw=r[stream].encode();r[stream+'_base64']=base64.b64encode(raw).decode();r[stream+'_sha256']=digest(raw)
 return r
class Strict(unittest.TestCase):
 checks=0
 def ok(self,condition):
  type(self).checks+=1;self.assertTrue(condition)
 def test_integer_record_shape(self):
  good=' 0 -1 64 T F\n';want=[['0','-1','64','T','F']]
  self.ok(integer_records(good,want))
  for x in [' 0 -1 64 T F',' 0 -1 64 T F\n\n','0\n-1 64 T F\n','0 -1 64 T\n','0 -1 64.0 T F\n','0 -1 064 T F\n','0 -1 +64 T F\n','0 -1 64\tT F\n','0 -1 64 T F\r\n','0 -1 NaN T F\n','0 -1 Infinity T F\n','0 -1 64 T F extra\n']:
   self.ok(not integer_records(x,want))
 def test_original_mixed_records(self):
  c=next(x for x in json.loads((ROOT/'manifest-source-plan.json').read_text())['cases'] if x.get('original'));s=c['reference_stdout'];self.ok(output_matches(c,s))
  self.ok(output_matches(c,s.replace('is          32 bits','is 32 bits').replace('           5          13           4\n',' 5 13 4\n')))
  for old,new in [(' , trailz=',' ,trailz='),('value=  -1','value= -1'),('32 bits','64 bits'),('           5          13           4','           5          12           4'),('elemental and any integer kind:','elemental and any integer kind: '),('0000100000','0000100001')]:
   self.ok(old in s);self.ok(not output_matches(c,s.replace(old,new)))
  for x in [s[:-1],s+'\n',s.replace('\n','\r\n'),s.replace('is          32 bits','is\t32 bits')]:self.ok(not output_matches(c,x))
  m=copy.deepcopy(c);m['sha256']='0'*64;self.ok(not output_matches(m,s))
  m=copy.deepcopy(c);m['reference_stdout']=s.replace('32 bits','64 bits');self.ok(not output_matches(m,m['reference_stdout']))
 def test_phase_guards(self):
  c={'candidate_stage':'success','expected_records':[['1']]};src='/source.f90'
  r=bind({'returncode':0,'timeout':False,'valid_utf8':True,'stdout':' 1\n','stderr':''})
  self.ok(not stage_errors(c,'run',r,src))
  for key,value in [('returncode',False),('returncode',-11),('returncode',2),('timeout',True),('valid_utf8',False),('stdout','1'),('stderr','warning\n'),('stdout','Backtrace\n')]:
   m=dict(r);m[key]=value;self.ok(bool(stage_errors(c,'run',m,src)))
  c={'candidate_stage':'check','expected_records':[],'diagnostics':{'check':{'line':3,'column':7,'message':'wrong type'}}};r.update(returncode=1,stdout='',stderr='/source.f90:3:7: wrong type\n');bind(r)
  self.ok(not stage_errors(c,'check',r,src))
  for key,value in [('returncode',True),('returncode',2),('stderr','/source.f90:3:8: wrong type\n'),('stderr','/other:3:7: wrong type\n'),('stderr','/source.f90:3:7: wrong type\nBacktrace\n'),('stdout','x\n')]:
   m=dict(r);m[key]=value;self.ok(bool(stage_errors(c,'check',m,src)))
if __name__=='__main__':
 r=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(Strict));print(json.dumps({'checks':Strict.checks,'methods':r.testsRun,'failures':len(r.failures),'errors':len(r.errors)}));raise SystemExit(not r.wasSuccessful())
