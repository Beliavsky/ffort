#!/usr/bin/env python3
"""Prebuild adversarial tests for exact records and fail-closed stage guards.
Synthetic diagnostics test the harness only, not candidate diagnostics.
"""
import copy,hashlib,json,re
from pathlib import Path
from contracts import output_matches,stage_errors
R=Path(__file__).resolve().parent
m=json.loads((R/'manifest.json').read_text());checks=0

def expect(x,label):
 global checks
 checks+=1
 assert x,label
for c in m['cases']:
 p=(R/c['source']).resolve();expect(hashlib.sha256(p.read_bytes()).hexdigest()==c['sha256'],c['name']+'/source')
 out=c.get('expected_stdout') if c.get('byte_exact') else ''.join(' '+' '.join(r)+'\n' for r in c['expected_records'])
 expect(output_matches(c,out),c['name']+'/baseline-records')
 for bad in [None,out+'\n','\n'+out,out+' 999\n',out+'\x00',out+'NaN\n',out+'Infinity\n']:
  expect(not output_matches(c,bad),c['name']+'/record-corruption')
 if out:
  for bad in [out[:-1],out.replace('\n','\r\n'),out.replace('\n',' ',1)]:expect(not output_matches(c,bad),c['name']+'/record-boundaries')
  if c.get('byte_exact'):
   expect(not output_matches(c,' '+out),c['name']+'/significant-padding')
  else:
   match=re.search(r'-?\d+|T|F',out);start,end=match.span()
   for bad in ['NaN','Infinity','1.0','1e0','+1','01','-0','1,2','1\t2','unknown']:
    expect(not output_matches(c,out[:start]+bad+out[end:]),c['name']+'/token-shape')
 synthetic={**c,'diagnostics':{'check':{'line':3,'column':7,'message':'expected check failure'},'run':{'line':4,'column':8,'message':'expected runtime failure'}}}
 for phase in ['check','run']:
  code=(1 if c['stage']=='check' else 0) if phase=='check' else {'check':1,'runtime':2,'success':0}[c['stage']]
  d=synthetic['diagnostics'][phase];err=f"{p}:{d['line']}:{d['column']}: {d['message']}\n" if code else ''
  r={'returncode':code,'timeout':False,'stdout':'' if phase=='check' else out,'stderr':err}
  expect(not stage_errors(synthetic,phase,r,p),c['name']+'/'+phase+'/synthetic-baseline')
  for key,val in [('returncode',-11),('returncode',None),('returncode',127),('timeout',True),('timeout',None),('stdout',None),('stderr',None)]:
   x=copy.deepcopy(r);x[key]=val;expect(bool(stage_errors(synthetic,phase,x,p)),c['name']+'/'+phase+'/bad-'+key)
  for text in [' ','\n','warning\n','SIGSEGV\n','Backtrace:\n','AddressSanitizer\n']:
   x=copy.deepcopy(r);x['stderr']+=text;expect(bool(stage_errors(synthetic,phase,x,p)),c['name']+'/'+phase+'/stderr')
  if code:
   for bad in [err.replace(str(p),str(p)+'-wrong'),err.replace(':3:7:',':3:8:').replace(':4:8:',':5:8:'),err.replace(d['message'],'other failure'),err[:-1]]:
    x=copy.deepcopy(r);x['stderr']=bad;expect(bool(stage_errors(synthetic,phase,x,p)),c['name']+'/'+phase+'/exact-diagnostic')
print(json.dumps({'checks':checks,'passed':checks,'failed':0,'candidate_executed':False,'synthetic_diagnostics_only':True}))
