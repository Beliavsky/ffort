#!/usr/bin/env python3
"""Exact bytes and independently specified position expectations; no numeric folding."""
import argparse,hashlib,json,re,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent
CRASH=re.compile(r'backtrace|traceback|fortran runtime error|internal compiler error|segmentation fault|SIGSEGV|SIGABRT|core dumped|addresssanitizer|undefinedbehaviorsanitizer|\bICE\b',re.I)
def run(args,cwd):
 p=subprocess.run(list(map(str,args)),cwd=cwd,capture_output=True,timeout=60)
 return dict(code=p.returncode,out=p.stdout.decode(),err=p.stderr.decode())
def clean(r):return not CRASH.search(r['out']+'\n'+r['err'])
def success(r):return r==dict(code=0,out='',err='')
def diagnosed(r,case,source,code,prefix=''):
 pattern=re.escape(str(source))+r':[1-9][0-9]*:[1-9][0-9]*: '+re.escape(case['diagnostic'])+r'\n'
 return r['code']==code and r['out']==prefix and clean(r) and re.fullmatch(pattern,r['err']) is not None
def matches(case,source,check,actual,compiled,oracle):
 if not all(clean(x) for x in (check,actual,compiled)):return False
 if case['gnu']=='pass':
  if not success(compiled):return False
 else:
  if compiled['code']!=1 or compiled['out'] or not compiled['err']:return False
 if case['kind']=='pass':
  return success(check) and actual['code']==0 and not actual['err'] and oracle is not None and clean(oracle) and oracle['code']==0 and not oracle['err'] and (actual['out']==oracle['out'] if 'gnu_expected_stdout' not in case else oracle['out']==case['gnu_expected_stdout'] and actual['out']==case['expected_stdout']) and ('expected_stdout' not in case or actual['out']==case['expected_stdout'])
 if oracle is not None:return False
 if case['kind']=='reject':return diagnosed(check,case,source,1) and diagnosed(actual,case,source,1)
 return success(check) and diagnosed(actual,case,source,2,case.get('prefix',''))
def main():
 from check_provenance import check
 check()
 a=argparse.ArgumentParser();a.add_argument('--candidate',required=True,type=Path);a.add_argument('--gfortran',default='gfortran');a.add_argument('--result',type=Path,default=ROOT/'results.json');args=a.parse_args();exe=args.candidate.resolve();records=[]
 with tempfile.TemporaryDirectory(prefix='position-format-') as temp:
  temp=Path(temp)
  for case in json.loads((ROOT/'manifest.json').read_text())['cases']:
   source=(ROOT/case['source']).resolve();assert hashlib.sha256(source.read_bytes()).hexdigest()==case['sha256']
   check=run([exe,'--check',source],temp);actual=run([exe,source],temp)
   compiled=run([args.gfortran,*case.get('flags',['-std=f2018','-pedantic-errors']),'-fcheck=all','-ffpe-trap=invalid,zero,overflow',source,'-o',temp/'oracle'],temp)
   oracle=run([temp/'oracle'],temp) if case['kind']=='pass' and success(compiled) else None
   ok=matches(case,source,check,actual,compiled,oracle);records.append(dict(name=case['name'],passed=ok,check=check,actual=actual,compiled=compiled,oracle=oracle))
   print(('PASS ' if ok else 'FAIL ')+case['name'],flush=True)
   if not ok:print(repr(records[-1])[:1600],flush=True)
 report=dict(candidate_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(),total=len(records),failed=sum(not c['passed'] for c in records),records=records);args.result.write_text(json.dumps(report,indent=2)+'\n');print('Total',report['total'],'failed',report['failed']);return report['failed']!=0
if __name__=='__main__':raise SystemExit(main())
