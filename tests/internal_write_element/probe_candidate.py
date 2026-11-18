#!/usr/bin/env python3
"""First-candidate observation, not final exact-negative regression certification."""
from pathlib import Path
import argparse,hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parent

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def run(argv):
 p=subprocess.run([str(x)for x in argv],stdin=subprocess.DEVNULL,capture_output=True,timeout=40)
 return dict(argv=[str(x)for x in argv],status=p.returncode,stdout=p.stdout.decode('latin1'),stderr=p.stderr.decode('latin1'))
def main():
 p=argparse.ArgumentParser();p.add_argument('--candidate',type=Path,required=True);p.add_argument('--expected-sha256',required=True);p.add_argument('--result',type=Path,required=True);a=p.parse_args();exe=a.candidate.resolve();before=sha(exe)
 if before!=a.expected_sha256:raise SystemExit('Candidate SHA-256 differs')
 m=json.loads((ROOT/'manifest.json').read_text());rows=[]
 for c in m['cases']:
  src=(ROOT/'cases'/f"{c['name']}.f90").resolve();check=run([exe,'--check',src]);execute=run([exe,src]);issues=[]
  if check['stdout']:issues.append('check wrote output')
  if c['category']=='success':
   if check['status']!=0 or check['stderr']:issues.append('check failed/noisy')
   if execute['status']!=0 or execute['stderr'] or execute['stdout']!=c['expected_stdout']:issues.append('exact success output mismatch')
  elif c['category']=='reject':
   if any(q['status']!=1 or q['stdout'] for q in [check,execute]):issues.append('unexpected source rejection phase')
  else:
   if check['status']!=0 or check['stderr']:issues.append('unexpected source rejection before runtime')
   if execute['status']!=2 or execute['stdout']!=c['expected_stdout']:issues.append('unexpected runtime rejection phase/output')
  diagnostics={}
  for label,q in [('check',check),('run',execute)]:
   if q['stderr']:
    d=re.fullmatch(re.escape(str(src))+r':(\d+):(\d+): (.*)\n',q['stderr'],re.DOTALL)
    diagnostics[label]=dict(line=int(d[1]),column=int(d[2]),message=d[3]) if d else None
  rows.append(dict(name=c['name'],source_sha256=sha(src),category=c['category'],check=check,run=execute,observed_diagnostics=diagnostics,provisional_issues=issues));print(('OBSERVED 'if not issues else'ISSUE ')+c['name'],flush=True)
 after=sha(exe);report=dict(status='first candidate observations; negative diagnostics not yet certified',candidate_sha256_before=before,candidate_sha256_after=after,candidate_version=run([exe,'--version']),runner_sha256=sha(Path(__file__)),manifest_sha256=sha(ROOT/'manifest.json'),cases=rows,provisional_failed=sum(bool(c['provisional_issues'])for c in rows))
 a.result.write_text(json.dumps(report,indent=2)+'\n');return after!=before or bool(report['provisional_failed'])
if __name__=='__main__':raise SystemExit(main())
