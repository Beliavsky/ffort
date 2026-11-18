#!/usr/bin/env python3
"""Adversarial validator tests on recorded bytes; never invokes a compiler/app."""
import copy,json,re,argparse,hashlib
from pathlib import Path
from contracts import stage_errors,output_matches
ROOT=Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--evidence',type=Path,default=ROOT/'corrected-final-results.json');p.add_argument('--result',type=Path,default=ROOT/'contract-test-results.json');a=p.parse_args()
data=json.loads(a.evidence.read_text());manifest=json.loads((ROOT/'manifest.json').read_text());cases={c['name']:c for c in manifest['cases']};checks=[]
def expect(value,label):
 checks.append({'label':label,'pass':bool(value)})
 if not value:raise AssertionError(label)
for row in data['results']:
 c=cases[row['case']['name']];name=c['name']
 expect(c==row['case'],name+'/manifest-contract-identity')
 expect(hashlib.sha256((ROOT/c['source']).read_bytes()).hexdigest()==c['sha256'],name+'/source-identity')
 source=Path(row['check']['command'][-1])
 expect(source.is_absolute() and source.parts[-len(Path(c['source']).parts):]==Path(c['source']).parts,name+'/recorded-source-mapping')
 expect(str(source)==row['run']['command'][-1],name+'/check-run-source-identity')
 for phase in ['check','run']:
  r=row[phase];expect(not stage_errors(c,phase,r,source),name+'/'+phase+'/baseline')
  for key,val in [('returncode',-11),('returncode',127),('returncode',None),('timeout',True),('timeout',None),('stdout',None),('stderr',None)]:
   m=copy.deepcopy(r);m[key]=val;expect(bool(stage_errors(c,phase,m,source)),name+'/'+phase+'/'+key+'/'+str(val))
  m=copy.deepcopy(r);m['returncode']={0:1,1:2,2:0}[r['returncode']];expect(bool(stage_errors(c,phase,m,source)),name+'/'+phase+'/wrong-stage-status')
  for marker in ['Backtrace:','SIGSEGV','SIGABRT','Segmentation fault','Program received signal','AddressSanitizer','core dumped','Floating point exception']:
   m=copy.deepcopy(r);m['stderr']+=marker+'\n';expect(bool(stage_errors(c,phase,m,source)),name+'/'+phase+'/crash/'+marker)
  for suffix in [' ','\n','\t','warning\n']:
   m=copy.deepcopy(r);m['stderr']+=suffix;expect(bool(stage_errors(c,phase,m,source)),name+'/'+phase+'/stderr/'+repr(suffix))
  if phase=='check' or c['stage']!='success':
   m=copy.deepcopy(r);m['stdout']=' ';expect(bool(stage_errors(c,phase,m,source)),name+'/'+phase+'/stdout-space')
  if r['returncode']!=0:
   d=c['diagnostics'][phase]
   for bad in [r['stderr'].replace(str(source),str(source)+'-wrong'),r['stderr'].replace(f":{d['line']}:{d['column']}:",f":{d['line']+1}:{d['column']}:",1),r['stderr'].replace(f":{d['line']}:{d['column']}:",f":{d['line']}:{d['column']+1}:",1),r['stderr'].replace(d['message'],'other diagnostic'),r['stderr'].rstrip('\n'),r['stderr']+'extra\n',r['stderr'].replace('\n','\r\n')]:
    m=copy.deepcopy(r);m['stderr']=bad;expect(bool(stage_errors(c,phase,m,source)),name+'/'+phase+'/exact-diagnostic')
 if c['stage']=='success':
  out=row['run']['stdout'];expect(output_matches(c,out),name+'/output/baseline')
  bads=[out[:-1],out+'\n',out.replace('\n','\r\n'),out+'garbage\n','\n'+out,out.replace('\n',' ',1),out.replace(' ','\t',1)]
  if c.get('byte_exact'):
   bads.extend([' '+out,out.replace('0','1',1)])
  else:
   match=re.search(r'-?[0-9]+|T|F',out);assert match
   start,end=match.span();token=match.group();suffixes=['NaN','Infinity','1.0','1e0','+1','01','-0','wrong','1,2']
   bads += [out[:start]+bad+out[end:] for bad in suffixes]
   bads += [out[:start]+out[end:],out[:end]+' 999'+out[end:]]
   # Horizontal processor-dependent spaces only are permitted.
   expect(output_matches(c,'\n'.join('   '+'  '.join(rec)+'   ' for rec in c['expected_records'])+'\n'),name+'/output/space-width-only')
  for idx,bad in enumerate(bads):
   expect(not output_matches(c,bad),name+'/output/mutation/'+str(idx))
result={'checks':len(checks),'passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'evidence':str(a.evidence),'checks_detail':checks};a.result.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='checks_detail'},indent=2))
