"""Strict source24, separately pinned GNU/candidate, preserved failure evidence."""
import argparse,json,os,tempfile
from pathlib import Path
from process_contract import sha,reserve_output,capture
from validate_results import validate,inventory,MANIFEST_SHA,stage_errors,VERSION
ROOT=Path(__file__).resolve().parent
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',type=Path,required=True);ap.add_argument('--expected-sha',required=True);ap.add_argument('--gfortran',type=Path,required=True);ap.add_argument('--gnu-sha',required=True);ap.add_argument('--output',type=Path,required=True);a=ap.parse_args()
 output,stream=reserve_output(a.output);result={'status':'failed','records':[]}
 def save():stream.seek(0);json.dump(result,stream,indent=2);stream.write('\n');stream.truncate();stream.flush()
 try:
  m=json.loads((ROOT/'manifest.json').read_text());result['inputs_before']=inventory(ROOT,m)
  if sha(ROOT/'manifest.json')!=MANIFEST_SHA:raise ValueError('manifest identity differs')
  for c in m:
   if sha(ROOT/c['source'])!=c['sha256']:raise ValueError('source identity differs')
  exe=a.candidate.resolve();gnu=a.gfortran.resolve();result.update(candidate=str(exe),gnu=str(gnu),candidate_sha256_before=sha(exe),gnu_sha256_before=sha(gnu))
  profile=json.loads((ROOT/'gnu-profile.json').read_text())
  if sha(exe)!=a.expected_sha or sha(gnu)!=a.gnu_sha or profile['sha256']!=a.gnu_sha:raise ValueError('executable identity differs')
  result['version_before']=capture([exe,'--version'],ROOT);result['gnu_version_before']=capture([gnu,'--version'],ROOT);save()
  for key,wanted in [('version_before',VERSION),('gnu_version_before',profile['stdout'])]:
   v=result[key]
   if stage_errors(v)or v['status']!=0 or v['stdout']!=wanted or v['stderr']!='':raise ValueError(key+' exact version differs')
  for c in m:
   with tempfile.TemporaryDirectory(prefix='substring-strict-')as d:
    work=Path(d);src=(ROOT/c['source']).resolve();row={k:c[k]for k in ['name','source','sha256','gnu_run']};row.update(cwd=d,gnu_execution=None);result['records'].append(row);save()
    row['check']=capture([exe,'--check',src],work);save()
    row['run']=capture([exe,src],work);save()
    row['gnu_compile']=capture([gnu,'-std=f2018','-fcheck=all',src,'-o',work/'oracle'],work);save()
    v=row['gnu_compile']
    if c['gnu_run'] and v['status']==0 and not v['timeout'] and v['spawn_error']is None and v['valid_utf8']and v['stdout']==''and v['stderr']=='':row['gnu_execution']=capture([work/'oracle'],work);save()
  result['version_after']=capture([exe,'--version'],ROOT);result['gnu_version_after']=capture([gnu,'--version'],ROOT)
  result.update(candidate_sha256_after=sha(exe),gnu_sha256_after=sha(gnu),inputs_after=inventory(ROOT,m));result['validation_errors']=validate(result,m,ROOT,a.expected_sha,a.gnu_sha)
  if not result['validation_errors']:result['status']='passed'
 except Exception as e:result['runner_exception']=type(e).__name__+': '+str(e)
 finally:save();os.fsync(stream.fileno());stream.close()
 print(result['status'],len(result['records']),result.get('validation_errors',result.get('runner_exception')));return result['status']!='passed'
if __name__=='__main__':raise SystemExit(main())
